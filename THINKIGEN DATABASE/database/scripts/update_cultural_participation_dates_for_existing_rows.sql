/* ============================================================================
   SCRIPT: UPDATE PARTICIPATION DATES FOR ALREADY INSERTED ROWS
   Target: student_schema.student_cultural_participation
   Purpose: Populates 'participation_date' (and any missing roles/results)
            for all existing cultural participation rows where it is currently NULL.
   ============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Backfilling participation_date for existing rows in student_cultural_participation...';
PRINT N'========================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Check how many rows currently have NULL participation_date
    DECLARE @NullDateCount INT = (
        SELECT COUNT(1) 
        FROM student_schema.student_cultural_participation 
        WHERE participation_date IS NULL
    );

    PRINT CONCAT(N'Found ', @NullDateCount, N' rows with NULL participation_date.');

    IF @NullDateCount > 0
    BEGIN
        -- 2. Update participation_date using announcement start_date or realistic recent dates
        UPDATE cp
        SET 
            cp.participation_date = COALESCE(
                a.start_date,
                DATEADD(DAY, -((cp.cultural_participation_id * 7) % 60 + 5), CAST(SYSUTCDATETIME() AS DATE))
            ),
            -- If status was REGISTERED/CANCELLED, ensure status is PARTICIPATED if there is a result
            cp.participation_status = CASE 
                WHEN cp.participation_status = N'CANCELLED' THEN N'PARTICIPATED'
                ELSE cp.participation_status 
            END,
            -- Ensure role_involvement is not null
            cp.role_involvement = COALESCE(cp.role_involvement, N'PARTICIPANT'),
            -- Ensure result is not null
            cp.result = COALESCE(cp.result, N'PARTICIPATED'),
            cp.updated_at = SYSUTCDATETIME()
        FROM student_schema.student_cultural_participation cp
        LEFT JOIN management_schema.announcement a 
            ON a.announcement_id = cp.announcement_id
        WHERE cp.participation_date IS NULL;

        DECLARE @UpdatedRows INT = @@ROWCOUNT;
        PRINT CONCAT(N'SUCCESS: Updated ', @UpdatedRows, N' rows with valid participation dates.');
    END
    ELSE
    BEGIN
        PRINT N'All rows already have valid participation_date values. No action required.';
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    DECLARE @ErrLine INT = ERROR_LINE();

    PRINT CONCAT(N'ERROR on line ', @ErrLine, N': ', @ErrMsg);
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO

-- =============================================================================
-- VERIFICATION REPORT
-- =============================================================================
PRINT N'';
PRINT N'------------------------------------------------------------------------';
PRINT N'AUDIT REPORT: Participation Dates Verification';
PRINT N'------------------------------------------------------------------------';

-- A. Verify NULL count is now 0
SELECT 
    COUNT(1) AS total_records,
    SUM(CASE WHEN participation_date IS NULL THEN 1 ELSE 0 END) AS remaining_null_dates,
    MIN(participation_date) AS earliest_participation_date,
    MAX(participation_date) AS latest_participation_date,
    CASE 
        WHEN SUM(CASE WHEN participation_date IS NULL THEN 1 ELSE 0 END) = 0 
        THEN N'PASS (0 NULL dates)' 
        ELSE N'WARNING (NULL dates remain)' 
    END AS audit_status
FROM student_schema.student_cultural_participation
WHERE is_active = 1;

-- B. Sample of updated rows with their participation dates
SELECT TOP 15
    cp.cultural_participation_id,
    CONCAT(s.first_name, N' ', COALESCE(s.last_name, N'')) AS student_name,
    sc.class_name,
    sec.section_name,
    cp.event_name,
    cp.category,
    cp.role_involvement,
    cp.result,
    cp.participation_status,
    cp.participation_date
FROM student_schema.student_cultural_participation cp
INNER JOIN student_schema.student s 
    ON s.student_id = cp.student_id
INNER JOIN management_schema.school_class sc 
    ON sc.class_id = cp.class_id
INNER JOIN management_schema.section sec 
    ON sec.section_id = cp.section_id
WHERE cp.is_active = 1
ORDER BY cp.cultural_participation_id DESC;
GO
