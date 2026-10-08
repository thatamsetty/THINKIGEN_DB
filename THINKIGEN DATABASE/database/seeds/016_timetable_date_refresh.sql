/*
================================================================================
SCRIPT:        016_timetable_date_refresh.sql
MODULE:        008_timetable.sql
PURPOSE:       Standalone UPDATE-only script to refresh dates on existing
               timetable-related rows WITHOUT deleting/reinserting data.

TABLES AFFECTED:
    1. management_schema.timetable          → created_at, updated_at
    2. management_schema.timetable_period   → period_date, created_at, updated_at
    3. student_schema.student_attendance    → attendance_date, recorded_at,
                                              created_at, updated_at

DATE LOGIC:
    - period_date     : From TODAY up to 2 weeks (12 school days, skip Sundays)
    - created_at      : Backdated 2–5 days before each period_date (realistic
                         "timetable was created a few days before the period")
    - updated_at      : Current UTC timestamp (SYSUTCDATETIME())

SAFETY:
    - Fully transactional with TRY/CATCH rollback
    - Zero INSERT/DELETE — UPDATE only on existing rows
    - Idempotent: safe to run multiple times
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'================================================================================';
PRINT N'Starting Timetable Date Refresh (UPDATE-only)...';
PRINT N'================================================================================';

BEGIN TRANSACTION;

BEGIN TRY

    /* ---------------------------------------------------------------------- */
    /* Step 0: Build a 2-week calendar from TODAY (skipping Sundays)           */
    /* ---------------------------------------------------------------------- */
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    CREATE TABLE #NewCal
    (
        day_index   INT  PRIMARY KEY,
        period_date DATE NOT NULL
    );

    ;WITH Numbers AS
    (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
        UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
        UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
        UNION ALL SELECT 20
    ),
    CandidateDates AS
    (
        SELECT DATEADD(DAY, n, @Today) AS cal_date FROM Numbers
    ),
    FilteredDays AS
    (
        SELECT cal_date,
               ROW_NUMBER() OVER (ORDER BY cal_date ASC) AS day_index
        FROM CandidateDates
        WHERE DATEPART(WEEKDAY, cal_date) <> 1   -- Skip Sundays (SQL default: 1 = Sunday)
    )
    INSERT INTO #NewCal (day_index, period_date)
    SELECT day_index, cal_date
    FROM FilteredDays
    WHERE day_index <= 12;

    DECLARE @MinDate DATE = (SELECT MIN(period_date) FROM #NewCal);
    DECLARE @MaxDate DATE = (SELECT MAX(period_date) FROM #NewCal);

    PRINT CONCAT(N'New 2-Week Date Range: ', CONVERT(VARCHAR(10), @MinDate, 120),
                 N' to ', CONVERT(VARCHAR(10), @MaxDate, 120),
                 N' (12 School Days from Today)');

    /* ---------------------------------------------------------------------- */
    /* Step 1: Map existing DISTINCT period_dates → new calendar dates         */
    /* ---------------------------------------------------------------------- */
    CREATE TABLE #DateMap
    (
        old_date DATE NOT NULL PRIMARY KEY,
        new_date DATE NOT NULL
    );

    ;WITH DistinctDates AS
    (
        SELECT DISTINCT period_date
        FROM management_schema.timetable_period
    ),
    RankedOldDates AS
    (
        SELECT period_date,
               ROW_NUMBER() OVER (ORDER BY period_date ASC) AS rn
        FROM DistinctDates
    )
    INSERT INTO #DateMap (old_date, new_date)
    SELECT r.period_date, c.period_date
    FROM RankedOldDates r
    JOIN #NewCal c ON c.day_index = ((r.rn - 1) % 12) + 1;

    DECLARE @MappedCount INT = (SELECT COUNT(*) FROM #DateMap);
    PRINT CONCAT(N'Date mappings created: ', @MappedCount, N' distinct old dates → new dates');

    /* ---------------------------------------------------------------------- */
    /* Step 2: UPDATE management_schema.timetable_period                      */
    /*         - period_date   → new mapped date                              */
    /*         - created_at    → backdated 2–5 days before new period_date    */
    /*         - updated_at    → current UTC timestamp                        */
    /* ---------------------------------------------------------------------- */
    UPDATE tp
    SET
        tp.period_date = dm.new_date,
        tp.created_at  = DATEADD(DAY,
                            -(2 + (tp.timetable_period_id % 4)),  -- 2 to 5 days before
                            CAST(dm.new_date AS DATETIME2(0))
                         ),
        tp.updated_at  = SYSUTCDATETIME()
    FROM management_schema.timetable_period tp
    JOIN #DateMap dm ON dm.old_date = tp.period_date;

    DECLARE @PeriodRowsUpdated INT = @@ROWCOUNT;
    PRINT CONCAT(N'  ✓ timetable_period rows updated: ', @PeriodRowsUpdated);

    /* ---------------------------------------------------------------------- */
    /* Step 3: UPDATE student_schema.student_attendance                       */
    /*         - attendance_date → match new timetable_period.period_date     */
    /*         - recorded_at     → period_date + start_time (realistic)       */
    /*         - created_at      → backdated 2–5 days before attendance_date  */
    /*         - updated_at      → current UTC timestamp                      */
    /* ---------------------------------------------------------------------- */
    UPDATE sa
    SET
        sa.attendance_date = tp.period_date,
        sa.recorded_at     = DATEADD(
                                SECOND,
                                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), tp.start_time),
                                CAST(tp.period_date AS DATETIME2)
                             ),
        sa.created_at      = DATEADD(DAY,
                                -(2 + (sa.student_attendance_id % 4)),
                                CAST(tp.period_date AS DATETIME2(0))
                             ),
        sa.updated_at      = SYSUTCDATETIME()
    FROM student_schema.student_attendance sa
    JOIN management_schema.timetable_period tp
        ON tp.timetable_period_id = sa.timetable_period_id;

    DECLARE @AttendanceRowsUpdated INT = @@ROWCOUNT;
    PRINT CONCAT(N'  ✓ student_attendance rows updated: ', @AttendanceRowsUpdated);

    /* ---------------------------------------------------------------------- */
    /* Step 4: UPDATE management_schema.timetable (header)                    */
    /*         - timetable_name → append new date range suffix                */
    /*         - created_at     → backdated 7 days before @MinDate           */
    /*         - updated_at     → current UTC timestamp                       */
    /* ---------------------------------------------------------------------- */
    UPDATE tt
    SET
        tt.timetable_name = CONCAT(
            -- Strip any existing date parenthetical suffix
            CASE
                WHEN CHARINDEX(N' (', tt.timetable_name) > 0
                THEN SUBSTRING(tt.timetable_name, 1, CHARINDEX(N' (', tt.timetable_name) - 1)
                ELSE tt.timetable_name
            END,
            N' (', CONVERT(VARCHAR(10), @MinDate, 120),
            N' to ', CONVERT(VARCHAR(10), @MaxDate, 120), N')'
        ),
        tt.created_at  = DATEADD(DAY, -7, CAST(@MinDate AS DATETIME2(0))),
        tt.updated_at  = SYSUTCDATETIME()
    FROM management_schema.timetable tt;

    DECLARE @TimetableRowsUpdated INT = @@ROWCOUNT;
    PRINT CONCAT(N'  ✓ timetable (header) rows updated: ', @TimetableRowsUpdated);

    /* ---------------------------------------------------------------------- */
    /* Cleanup temp tables                                                    */
    /* ---------------------------------------------------------------------- */
    DROP TABLE #DateMap;
    DROP TABLE #NewCal;

    COMMIT TRANSACTION;

    PRINT N'================================================================================';
    PRINT N'SUCCESS: All timetable dates refreshed from today to 2 weeks!';
    PRINT N'================================================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'tempdb..#DateMap')  IS NOT NULL DROP TABLE #DateMap;
    IF OBJECT_ID(N'tempdb..#NewCal')   IS NOT NULL DROP TABLE #NewCal;
    THROW;
END CATCH;
GO

/* ============================================================================ */
/* Verification Queries                                                         */
/* ============================================================================ */

-- 1. Timetable Headers Summary
PRINT N'';
PRINT N'--- Timetable Headers ---';
SELECT
    timetable_id,
    timetable_name,
    status,
    FORMAT(created_at, 'yyyy-MM-dd HH:mm:ss') AS created_at,
    FORMAT(updated_at, 'yyyy-MM-dd HH:mm:ss') AS updated_at
FROM management_schema.timetable
ORDER BY timetable_id;

-- 2. Period Date Distribution
PRINT N'';
PRINT N'--- Period Date Distribution (period_date, created_at, updated_at samples) ---';
SELECT
    period_date,
    COUNT(*) AS period_count,
    DATENAME(WEEKDAY, period_date) AS day_name,
    MIN(FORMAT(created_at, 'yyyy-MM-dd HH:mm:ss')) AS earliest_created_at,
    MAX(FORMAT(created_at, 'yyyy-MM-dd HH:mm:ss')) AS latest_created_at,
    MIN(FORMAT(updated_at, 'yyyy-MM-dd HH:mm:ss')) AS sample_updated_at
FROM management_schema.timetable_period
GROUP BY period_date
ORDER BY period_date;

-- 3. Attendance Date Distribution
PRINT N'';
PRINT N'--- Attendance Date Distribution ---';
SELECT
    attendance_date,
    COUNT(*) AS attendance_count,
    DATENAME(WEEKDAY, attendance_date) AS day_name,
    MIN(FORMAT(created_at, 'yyyy-MM-dd HH:mm:ss')) AS earliest_created_at,
    MIN(FORMAT(recorded_at, 'yyyy-MM-dd HH:mm:ss')) AS sample_recorded_at,
    MIN(FORMAT(updated_at, 'yyyy-MM-dd HH:mm:ss')) AS sample_updated_at
FROM student_schema.student_attendance
GROUP BY attendance_date
ORDER BY attendance_date;

-- 4. Sample timetable_period rows (first 10)
PRINT N'';
PRINT N'--- Sample timetable_period rows ---';
SELECT TOP 10
    timetable_period_id,
    timetable_id,
    period_date,
    period_number,
    period_name,
    period_type,
    FORMAT(created_at, 'yyyy-MM-dd HH:mm:ss') AS created_at,
    FORMAT(updated_at, 'yyyy-MM-dd HH:mm:ss') AS updated_at
FROM management_schema.timetable_period
ORDER BY period_date, timetable_id, period_number;
GO
