/*
    Script:    010_homework_mock_data.sql
    Module:    009_homework / teachers_schema.homework & student_schema.homework_status
    Purpose:   Comprehensive mock data for the updated Homework module:
               - teachers_schema.homework (HOMEWORK, READING, OTHER; NO allow_late_submission)
               - student_schema.homework_status with submission_timing (ON_TIME, LATE, NULL)
                 and strict compliance with CK_homework_status_submitted_at & CK_homework_status_submission_timing.

    Coverage & Rules Enforced:
    ---------------------------------------------------------------------------
    - teachers_schema.homework:
      * homework_type IN ('HOMEWORK', 'READING', 'OTHER')
      * priority_level IN ('HIGH', 'MEDIUM', 'LOW')
      * status IN ('PUBLISHED', 'CLOSED', 'DRAFT')
      * deadline_at >= assigned_at
      * published_at populated when status = 'PUBLISHED'
      * No allow_late_submission column
    - student_schema.homework_status:
      * submission_status IN ('NOT_SUBMITTED', 'SUBMITTED')
      * submission_timing: ON_TIME (submitted_at <= deadline_at), LATE (submitted_at > deadline_at), or NULL (when NOT_SUBMITTED)
      * submitted_at: NOT NULL when SUBMITTED, NULL when NOT_SUBMITTED
      * Unique per (homework_id, student_id)
    - Idempotent: checks existing records before inserting to allow safe re-runs.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Seeding Comprehensive Mock Data for Updated Homework Module...';
PRINT N'========================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    -- =========================================================================
    -- 1. RESOLVE EVALUATING TEACHER & ADMIN USERS
    -- =========================================================================
    DECLARE @DefaultAdminUserId BIGINT = (SELECT TOP 1 user_id FROM security_schema.users WHERE user_type = N'ADMIN' ORDER BY user_id ASC);
    IF @DefaultAdminUserId IS NULL
        SET @DefaultAdminUserId = (SELECT TOP 1 user_id FROM security_schema.users ORDER BY user_id ASC);

    IF @DefaultAdminUserId IS NULL
    BEGIN
        RAISERROR(N'No user records found in security_schema.users. Seed users first.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- =========================================================================
    -- 2. SEED HOMEWORK ASSIGNMENTS (teachers_schema.homework)
    -- =========================================================================
    -- Generates realistic homework tasks across active sections, subjects, and teachers
    ;WITH HomeworkTemplates AS (
        SELECT *
        FROM (VALUES
            (N'HOMEWORK', N'HIGH',   N'Problem Set 1: Chapter Review & Numerical Problems', N'Complete all exercise questions from textbook chapter. Submit handwritten solutions.', 45, -7, -2, N'CLOSED'),
            (N'READING',  N'MEDIUM', N'Supplementary Reading: Scientific Articles & Case Study', N'Read assigned research excerpt and highlight 5 key scientific takeaways.', 30, -5, -1, N'CLOSED'),
            (N'HOMEWORK', N'MEDIUM', N'Practice Worksheet 2: Grammar, Vocabulary & Comprehension', N'Solve the multi-choice worksheet and compose a short 200-word paragraph.', 40, -2, 3, N'PUBLISHED'),
            (N'OTHER',    N'LOW',    N'Practical Lab Prep: Apparatus Setup & Safety Notes', N'Review the lab diagram and write down experimental apparatus procedure in journal.', 25, -1, 4, N'PUBLISHED'),
            (N'HOMEWORK', N'HIGH',   N'Weekly Analytical Assignment: Core Concepts & Proofs', N'Derive core formulas and solve sample board examination problems 1 through 10.', 60, 0, 5, N'PUBLISHED')
        ) AS t(homework_type, priority_level, title_suffix, description_text, estimated_minutes, assigned_day_offset, deadline_day_offset, target_status)
    ),
    SectionSubjectScope AS (
        SELECT
            sc.school_id,
            b.branch_id,
            ay.academic_year_id,
            sec.class_id,
            sec.section_id,
            s.subject_id,
            s.subject_name,
            COALESCE(tsa.teacher_id, (SELECT TOP 1 teacher_id FROM teachers_schema.teacher WHERE school_id = sc.school_id ORDER BY teacher_id)) AS teacher_id,
            tpl.homework_type,
            tpl.priority_level,
            CONCAT(s.subject_name, N' - ', tpl.title_suffix) AS title,
            tpl.description_text,
            tpl.estimated_minutes,
            tpl.target_status,
            DATEADD(DAY, tpl.assigned_day_offset, CAST('2026-09-10T09:00:00' AS DATETIME2(0))) AS assigned_at,
            DATEADD(DAY, tpl.deadline_day_offset, CAST('2026-09-10T18:00:00' AS DATETIME2(0))) AS deadline_at,
            CASE
                WHEN tpl.target_status IN (N'PUBLISHED', N'CLOSED')
                    THEN DATEADD(DAY, tpl.assigned_day_offset, CAST('2026-09-10T09:00:00' AS DATETIME2(0)))
                ELSE NULL
            END AS published_at
        FROM management_schema.section sec
        INNER JOIN management_schema.school_class sc
            ON sc.class_id = sec.class_id
        INNER JOIN management_schema.branch b
            ON b.school_id = sc.school_id
           AND b.branch_id = CASE sc.class_id
               WHEN 1 THEN 1 WHEN 2 THEN 1 WHEN 3 THEN 2 WHEN 4 THEN 2
               WHEN 5 THEN 3 WHEN 6 THEN 3 WHEN 7 THEN 4 ELSE 4 END
        INNER JOIN management_schema.academic_year ay
            ON ay.school_id = sc.school_id
           AND ay.is_current = 1
        INNER JOIN management_schema.subject s
            ON s.school_id = sc.school_id
        LEFT JOIN teachers_schema.teacher_subject_assignment tsa
            ON tsa.school_id = sc.school_id
           AND tsa.branch_id = b.branch_id
           AND tsa.academic_year_id = ay.academic_year_id
           AND tsa.class_id = sec.class_id
           AND tsa.section_id = sec.section_id
           AND tsa.subject_id = s.subject_id
           AND tsa.is_active = 1
        CROSS JOIN HomeworkTemplates tpl
        WHERE sec.is_active = 1
          AND s.is_active = 1
    )
    INSERT INTO teachers_schema.homework
    (
        school_id,
        academic_year_id,
        branch_id,
        class_id,
        section_id,
        subject_id,
        teacher_id,
        homework_type,
        title,
        description,
        priority_level,
        assigned_at,
        deadline_at,
        status,
        estimated_minutes,
        published_at,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    SELECT
        src.school_id,
        src.academic_year_id,
        src.branch_id,
        src.class_id,
        src.section_id,
        src.subject_id,
        src.teacher_id,
        src.homework_type,
        src.title,
        src.description_text,
        src.priority_level,
        src.assigned_at,
        src.deadline_at,
        src.target_status,
        src.estimated_minutes,
        src.published_at,
        1 AS is_active,
        src.assigned_at AS created_at,
        COALESCE(t.user_id, @DefaultAdminUserId) AS created_by,
        src.assigned_at AS updated_at,
        COALESCE(t.user_id, @DefaultAdminUserId) AS updated_by
    FROM SectionSubjectScope src
    LEFT JOIN teachers_schema.teacher t
        ON t.teacher_id = src.teacher_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM teachers_schema.homework existing
        WHERE existing.section_id = src.section_id
          AND existing.subject_id = src.subject_id
          AND existing.title = src.title
    );

    DECLARE @HomeworkInserted INT = @@ROWCOUNT;
    PRINT CONCAT(N'Seeded homework records into teachers_schema.homework. New rows: ', @HomeworkInserted);

    -- =========================================================================
    -- 3. SEED PER-STUDENT SUBMISSION STATUS (student_schema.homework_status)
    -- =========================================================================
    -- Generates ON_TIME (70%), LATE (15%), and NOT_SUBMITTED (15%) realistic submissions
    INSERT INTO student_schema.homework_status
    (
        homework_id,
        school_id,
        branch_id,
        academic_year_id,
        class_id,
        section_id,
        student_id,
        submission_status,
        submitted_at,
        submission_timing,
        remarks,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    SELECT
        h.homework_id,
        h.school_id,
        h.branch_id,
        h.academic_year_id,
        h.class_id,
        h.section_id,
        st.student_id,
        calc.submission_status,
        calc.submitted_at,
        calc.submission_timing,
        calc.remarks,
        1 AS is_active,
        COALESCE(calc.submitted_at, h.assigned_at) AS created_at,
        COALESCE(t.user_id, @DefaultAdminUserId) AS created_by,
        COALESCE(calc.submitted_at, h.assigned_at) AS updated_at,
        COALESCE(t.user_id, @DefaultAdminUserId) AS updated_by
    FROM teachers_schema.homework h
    INNER JOIN student_schema.student st
        ON st.section_id = h.section_id
       AND st.is_active = 1
    LEFT JOIN teachers_schema.teacher t
        ON t.teacher_id = h.teacher_id
    CROSS APPLY (
        SELECT (st.student_id * 17 + h.homework_id * 31) % 100 AS rand_seed
    ) s
    CROSS APPLY (
        SELECT
            -- 15% not submitted, 15% late, 70% on time
            CASE
                WHEN s.rand_seed < 15 THEN N'NOT_SUBMITTED'
                ELSE N'SUBMITTED'
            END AS submission_status,
            CASE
                WHEN s.rand_seed < 15 THEN NULL
                WHEN s.rand_seed < 30
                    THEN DATEADD(HOUR, 4 + (s.rand_seed % 24), h.deadline_at) -- LATE (submitted after deadline)
                ELSE
                    DATEADD(HOUR, -((s.rand_seed % 36) + 2), h.deadline_at)   -- ON_TIME (submitted before deadline)
            END AS submitted_at,
            CASE
                WHEN s.rand_seed < 15 THEN NULL
                WHEN s.rand_seed < 30 THEN N'LATE'
                ELSE N'ON_TIME'
            END AS submission_timing,
            CASE
                WHEN s.rand_seed < 15 THEN N'Pending student submission'
                WHEN s.rand_seed < 30 THEN N'Submitted after deadline with medical / personal reason note.'
                WHEN s.rand_seed > 80 THEN N'Thoroughly completed with neat presentation and complete references.'
                ELSE N'Satisfactorily completed and verified.'
            END AS remarks
    ) calc
    WHERE NOT EXISTS (
        SELECT 1
        FROM student_schema.homework_status existing
        WHERE existing.homework_id = h.homework_id
          AND existing.student_id = st.student_id
    );

    DECLARE @StatusInserted INT = @@ROWCOUNT;
    PRINT CONCAT(N'Seeded student submission records into student_schema.homework_status. New rows: ', @StatusInserted);

    -- =========================================================================
    -- 4. VERIFICATION SUMMARIES (SSMS OUTPUT)
    -- =========================================================================
    -- Summary 1: Homework breakdown by type, priority, and status
    SELECT
        homework_type,
        priority_level,
        status,
        COUNT(*) AS total_homework_items,
        MIN(assigned_at) AS earliest_assigned,
        MAX(deadline_at) AS latest_deadline
    FROM teachers_schema.homework
    GROUP BY homework_type, priority_level, status
    ORDER BY homework_type, priority_level, status;

    -- Summary 2: Submission timing distribution (ON_TIME vs LATE vs NOT_SUBMITTED)
    SELECT
        submission_status,
        COALESCE(submission_timing, N'NULL (PENDING)') AS submission_timing,
        COUNT(*) AS total_submissions,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5, 2)) AS percentage
    FROM student_schema.homework_status
    GROUP BY submission_status, submission_timing
    ORDER BY submission_status, submission_timing;

    -- Summary 3: Constraint Compliance Verification (Expected: 0 invalid rows)
    SELECT
        hs.homework_status_id,
        hs.submission_status,
        hs.submitted_at,
        hs.submission_timing,
        h.deadline_at,
        CASE
            WHEN hs.submission_status = N'SUBMITTED' AND hs.submitted_at IS NULL
                THEN N'FAIL: SUBMITTED but submitted_at is NULL'
            WHEN hs.submission_status = N'NOT_SUBMITTED' AND hs.submitted_at IS NOT NULL
                THEN N'FAIL: NOT_SUBMITTED but submitted_at is populated'
            WHEN hs.submission_status = N'NOT_SUBMITTED' AND hs.submission_timing IS NOT NULL
                THEN N'FAIL: NOT_SUBMITTED but submission_timing is NOT NULL'
            WHEN hs.submission_status = N'SUBMITTED' AND hs.submitted_at <= h.deadline_at AND hs.submission_timing <> N'ON_TIME'
                THEN N'FAIL: submitted <= deadline but timing <> ON_TIME'
            WHEN hs.submission_status = N'SUBMITTED' AND hs.submitted_at > h.deadline_at AND hs.submission_timing <> N'LATE'
                THEN N'FAIL: submitted > deadline but timing <> LATE'
            ELSE N'PASS'
        END AS integrity_status
    FROM student_schema.homework_status hs
    INNER JOIN teachers_schema.homework h
        ON h.homework_id = hs.homework_id
    WHERE (hs.submission_status = N'SUBMITTED' AND hs.submitted_at IS NULL)
       OR (hs.submission_status = N'NOT_SUBMITTED' AND hs.submitted_at IS NOT NULL)
       OR (hs.submission_status = N'NOT_SUBMITTED' AND hs.submission_timing IS NOT NULL)
       OR (hs.submission_status = N'SUBMITTED' AND hs.submitted_at <= h.deadline_at AND hs.submission_timing <> N'ON_TIME')
       OR (hs.submission_status = N'SUBMITTED' AND hs.submitted_at > h.deadline_at AND hs.submission_timing <> N'LATE');

    COMMIT TRANSACTION;
    PRINT N'========================================================================';
    PRINT N'Homework mock data seeding transaction committed successfully.';
    PRINT N'========================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO
