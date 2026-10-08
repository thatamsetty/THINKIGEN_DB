/* =============================================================================
    THINKIGEN ERP — Utility Migration Script
    Purpose:   Modify dates for Exams, Assessments, and Homeworks
               - Exams & Assessments: From today up to 2 weeks
               - Homeworks:           From yesterday up to 2 weeks
    Platform:  Microsoft SQL Server Management Studio (SSMS) / Azure SQL
   ============================================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Starting Date Adjustments for Exams, Assessments, and Homeworks...';
PRINT N'========================================================================';
GO

BEGIN TRANSACTION;
BEGIN TRY

    /* -------------------------------------------------------------------------- */
    /* 0. DEFINE BASELINE DATE ANCHORS                                            */
    /* -------------------------------------------------------------------------- */
    -- Anchored to CAST(GETDATE() AS DATE), which defaults to the system clock (2026-09-23)
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Yesterday DATE = DATEADD(DAY, -1, @Today);
    DECLARE @TwoWeeksAhead DATE = DATEADD(DAY, 14, @Today);

    PRINT N'Baseline Date Reference:';
    PRINT N'  Yesterday:       ' + CONVERT(NVARCHAR(30), @Yesterday, 120);
    PRINT N'  Today:           ' + CONVERT(NVARCHAR(30), @Today, 120);
    PRINT N'  Two Weeks Ahead: ' + CONVERT(NVARCHAR(30), @TwoWeeksAhead, 120);

    /* ========================================================================== */
    /* 1. EXAMS & EXAM SCHEDULES (From Today up to 2 Weeks)                       */
    /* ========================================================================== */
    PRINT N'------------------------------------------------------------------------';
    PRINT N'1. Updating management_schema.exam and exam_schedule dates...';

    -- A. Update Exam Masters (start_date between @Today and @Today+3, end_date within 2 weeks)
    UPDATE e
    SET 
        start_date = DATEADD(DAY, (e.exam_id % 4), @Today),
        end_date   = DATEADD(DAY, (e.exam_id % 4) + 8, @Today),
        status     = N'PUBLISHED',
        updated_at = SYSUTCDATETIME()
    FROM management_schema.exam e;

    PRINT N'   ✔ Updated ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' exam master records.';

    -- B. Update Exam Schedules (dates distributed across the exam window)
    ;WITH ScheduleSeq AS (
        SELECT 
            exam_schedule_id,
            exam_id,
            ROW_NUMBER() OVER (PARTITION BY exam_id ORDER BY subject_id) - 1 AS subject_offset
        FROM management_schema.exam_schedule
    )
    UPDATE es
    SET 
        exam_date  = DATEADD(DAY, seq.subject_offset, e.start_date),
        status     = CASE 
                       WHEN DATEADD(DAY, seq.subject_offset, e.start_date) < @Today THEN N'COMPLETED'
                       ELSE N'SCHEDULED'
                     END,
        updated_at = SYSUTCDATETIME()
    FROM management_schema.exam_schedule es
    INNER JOIN ScheduleSeq seq ON seq.exam_schedule_id = es.exam_schedule_id
    INNER JOIN management_schema.exam e ON e.exam_id = es.exam_id;

    PRINT N'   ✔ Updated ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' exam schedule records.';

    -- C. Sync published_at on exam results
    UPDATE er
    SET 
        published_at = DATEADD(DAY, 1, CAST(es.exam_date AS DATETIME2(0))),
        updated_at   = SYSUTCDATETIME()
    FROM student_schema.exam_result er
    INNER JOIN management_schema.exam_schedule es ON es.exam_schedule_id = er.exam_schedule_id
    WHERE er.published_at IS NOT NULL;

    PRINT N'   ✔ Synchronized published_at on ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' exam results.';


    /* ========================================================================== */
    /* 2. ASSESSMENTS (From Today up to 2 Weeks)                                  */
    /* ========================================================================== */
    PRINT N'------------------------------------------------------------------------';
    PRINT N'2. Updating teachers_schema.assessment and assessment_result dates...';

    -- A. Update Assessment dates (staggered across Days 0, 3, 6, 9, 13 from @Today)
    ;WITH AssessmentSeq AS (
        SELECT 
            assessment_id,
            (ROW_NUMBER() OVER (PARTITION BY section_id, subject_id ORDER BY assessment_id) - 1) AS seq_num
        FROM teachers_schema.assessment
    )
    UPDATE a
    SET 
        assessment_date = DATEADD(DAY, 
            CASE (seq.seq_num % 5)
                WHEN 0 THEN 0   -- Today (Day 0)
                WHEN 1 THEN 3   -- Day 3
                WHEN 2 THEN 6   -- Day 6
                WHEN 3 THEN 9   -- Day 9
                WHEN 4 THEN 13  -- Day 13 (within 2 weeks)
            END, 
            @Today
        ),
        updated_at = SYSUTCDATETIME()
    FROM teachers_schema.assessment a
    INNER JOIN AssessmentSeq seq ON seq.assessment_id = a.assessment_id;

    PRINT N'   ✔ Updated ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' assessment master records.';

    -- B. Sync graded_at on assessment results (respecting CK_assessment_result_graded)
    UPDATE ar
    SET 
        graded_at  = DATEADD(HOUR, 14, DATEADD(DAY, 1, CAST(a.assessment_date AS DATETIME2(0)))),
        updated_at = SYSUTCDATETIME()
    FROM student_schema.assessment_result ar
    INNER JOIN teachers_schema.assessment a ON a.assessment_id = ar.assessment_id
    WHERE ar.marks_obtained IS NOT NULL;

    PRINT N'   ✔ Synchronized graded_at on ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' assessment results.';


    /* ========================================================================== */
    /* 3. HOMEWORKS (From Yesterday up to 2 Weeks)                                */
    /* ========================================================================== */
    PRINT N'------------------------------------------------------------------------';
    PRINT N'3. Updating teachers_schema.homework and homework_status dates...';

    -- A. Update Homework assigned_at, deadline_at, and published_at
    ;WITH HwSeq AS (
        SELECT 
            homework_id,
            (ROW_NUMBER() OVER (PARTITION BY section_id, subject_id ORDER BY homework_id) - 1) AS seq_num
        FROM teachers_schema.homework
    )
    UPDATE h
    SET 
        assigned_at = DATEADD(HOUR, 8, CAST(
            DATEADD(DAY, 
                CASE (seq.seq_num % 5)
                    WHEN 0 THEN -1  -- Yesterday
                    WHEN 1 THEN -1  -- Yesterday
                    WHEN 2 THEN  0  -- Today
                    WHEN 3 THEN  2  -- Day 2
                    WHEN 4 THEN  4  -- Day 4
                END, 
                @Today
            ) AS DATETIME2(0)
        )),
        deadline_at = DATEADD(HOUR, 18, CAST(
            DATEADD(DAY, 
                CASE (seq.seq_num % 5)
                    WHEN 0 THEN  1  -- Tomorrow (Day 1)
                    WHEN 1 THEN  3  -- Day 3
                    WHEN 2 THEN  6  -- Day 6
                    WHEN 3 THEN  9  -- Day 9
                    WHEN 4 THEN 14  -- Day 14 (upto 2 weeks)
                END, 
                @Today
            ) AS DATETIME2(0)
        )),
        published_at = DATEADD(HOUR, 8, CAST(
            DATEADD(DAY, 
                CASE (seq.seq_num % 5)
                    WHEN 0 THEN -1
                    WHEN 1 THEN -1
                    WHEN 2 THEN  0
                    WHEN 3 THEN  2
                    WHEN 4 THEN  4
                END, 
                @Today
            ) AS DATETIME2(0)
        )),
        status = N'PUBLISHED',
        updated_at = SYSUTCDATETIME()
    FROM teachers_schema.homework h
    INNER JOIN HwSeq seq ON seq.homework_id = h.homework_id;

    PRINT N'   ✔ Updated ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' homework records.';

    -- B. Update student_schema.homework_status submitted_at
    UPDATE hs
    SET 
        submitted_at = CASE 
            WHEN hs.submission_status = N'NOT_SUBMITTED' THEN NULL
            WHEN hs.submission_timing = N'LATE' THEN DATEADD(HOUR, 2, h.deadline_at)
            ELSE DATEADD(HOUR, 6, h.assigned_at) -- ON_TIME
        END,
        updated_at = SYSUTCDATETIME()
    FROM student_schema.homework_status hs
    INNER JOIN teachers_schema.homework h ON h.homework_id = hs.homework_id;

    PRINT N'   ✔ Synchronized submitted_at on ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' homework status records.';

    COMMIT TRANSACTION;
    PRINT N'========================================================================';
    PRINT N'✔ All dates updated and committed successfully!';
    PRINT N'========================================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO

/* ============================================================================= */
/* 4. VERIFICATION QUERIES                                                       */
/* ============================================================================= */

PRINT N'';
PRINT N'--- 1. EXAM DATE RANGE SUMMARY ---';
SELECT 
    exam_category,
    status,
    MIN(start_date) AS earliest_exam_start,
    MAX(end_date)   AS latest_exam_end,
    COUNT(*)        AS total_exams
FROM management_schema.exam
GROUP BY exam_category, status;

PRINT N'--- 2. EXAM SCHEDULE DATES ---';
SELECT 
    MIN(exam_date) AS earliest_schedule,
    MAX(exam_date) AS latest_schedule,
    COUNT(*)       AS scheduled_subjects
FROM management_schema.exam_schedule;

PRINT N'--- 3. ASSESSMENT DATES SUMMARY ---';
SELECT 
    assessment_type,
    MIN(assessment_date) AS earliest_assessment,
    MAX(assessment_date) AS latest_assessment,
    COUNT(*)             AS total_assessments
FROM teachers_schema.assessment
GROUP BY assessment_type;

PRINT N'--- 4. HOMEWORK DATES SUMMARY ---';
SELECT 
    homework_type,
    priority_level,
    status,
    MIN(assigned_at) AS earliest_assigned,
    MAX(deadline_at) AS latest_deadline,
    COUNT(*)         AS total_homeworks
FROM teachers_schema.homework
GROUP BY homework_type, priority_level, status;
GO
