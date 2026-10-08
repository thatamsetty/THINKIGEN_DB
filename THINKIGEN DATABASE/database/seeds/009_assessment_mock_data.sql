/*
    Script:    009_assessment_mock_data.sql
    Module:    006_assessment / teachers_schema.assessment & student_schema.assessment_result
    Purpose:   Comprehensive mock data for subject-wise assessments (project works,
               slip tests, quizzes) and per-student assessment marks / grading results.

    Schema Compliance:
    - teachers_schema.assessment:
      * assessment_type IN ('PROJECT_WORK', 'PROJECT', 'SLIP_TEST', 'QUIZ', 'OTHER')
      * max_marks > 0
      * Dynamic academic scope (school_id, branch_id, academic_year_id, class_id, section_id, subject_id, teacher_id)
    - student_schema.assessment_result:
      * UQ_assessment_result_assessment_student (assessment_id, student_id)
      * CK_assessment_result_marks (marks_obtained IS NULL OR marks_obtained >= 0)
      * CK_assessment_result_graded ((marks IS NULL AND graded_at IS NULL AND graded_by IS NULL)
                                  OR (marks IS NOT NULL AND graded_at IS NOT NULL AND graded_by IS NOT NULL))
    - Idempotent: checks for existing assessments and student results before inserting.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Seeding Mock Data for Assessment Master & Student Assessment Results...';
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
        RAISERROR(N'No user records found in security_schema.users. Seed user foundation first.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- =========================================================================
    -- 2. SEED SUBJECT-WISE ASSESSMENTS (teachers_schema.assessment)
    -- =========================================================================
    -- Create curriculum assessments for each active section and subject
    -- Covers SLIP_TEST (25 marks), QUIZ (20 marks), PROJECT_WORK (50 marks), PROJECT (50 marks), OTHER (15 marks)
    ;WITH AssessmentSource AS (
        SELECT
            sc.school_id,
            b.branch_id,
            ay.academic_year_id,
            sec.class_id,
            sec.section_id,
            s.subject_id,
            COALESCE(tsa.teacher_id, (SELECT TOP 1 teacher_id FROM teachers_schema.teacher WHERE school_id = sc.school_id ORDER BY teacher_id)) AS teacher_id,
            t.assessment_type,
            t.title_template,
            t.max_marks,
            t.assessment_date
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
        CROSS JOIN (
            VALUES
                (N'SLIP_TEST',    N'Slip Test 1: Chapter Foundations & Definitions', 25.00, CAST('2026-08-18' AS DATE)),
                (N'QUIZ',         N'Diagnostic Quiz 1: Speed & Numerical Accuracy',  20.00, CAST('2026-08-25' AS DATE)),
                (N'PROJECT_WORK', N'Experiential Project Work: Application Study',   50.00, CAST('2026-09-05' AS DATE)),
                (N'SLIP_TEST',    N'Slip Test 2: Analytical & Problem Solving',     25.00, CAST('2026-09-18' AS DATE)),
                (N'OTHER',        N'Oral Viva & Practical Lab Book Assessment',      15.00, CAST('2026-09-28' AS DATE))
        ) AS t(assessment_type, title_template, max_marks, assessment_date)
        WHERE sec.is_active = 1
          AND s.is_active = 1
    )
    INSERT INTO teachers_schema.assessment
    (
        school_id,
        academic_year_id,
        branch_id,
        class_id,
        section_id,
        subject_id,
        teacher_id,
        title,
        assessment_type,
        assessment_date,
        max_marks,
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
        CONCAT(s.subject_name, N' - ', src.title_template) AS title,
        src.assessment_type,
        src.assessment_date,
        src.max_marks,
        1 AS is_active,
        CAST(src.assessment_date AS DATETIME2(0)) AS created_at,
        COALESCE(t.user_id, @DefaultAdminUserId) AS created_by,
        CAST(src.assessment_date AS DATETIME2(0)) AS updated_at,
        COALESCE(t.user_id, @DefaultAdminUserId) AS updated_by
    FROM AssessmentSource src
    INNER JOIN management_schema.subject s
        ON s.subject_id = src.subject_id
    LEFT JOIN teachers_schema.teacher t
        ON t.teacher_id = src.teacher_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM teachers_schema.assessment existing
        WHERE existing.section_id = src.section_id
          AND existing.subject_id = src.subject_id
          AND existing.title = CONCAT(s.subject_name, N' - ', src.title_template)
    );

    DECLARE @AssessmentCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'Seeded assessments into teachers_schema.assessment. New rows inserted: ', @AssessmentCount);

    -- =========================================================================
    -- 3. SEED PER-STUDENT ASSESSMENT MARKS (student_schema.assessment_result)
    -- =========================================================================
    -- Inserts evaluation marks, letter grade, evaluation timestamp, and teacher remarks.
    -- Preserves rule: 1 absent/re-test student per ~10 students where marks are NULL and graded fields are NULL.
    INSERT INTO student_schema.assessment_result
    (
        assessment_id,
        school_id,
        branch_id,
        academic_year_id,
        class_id,
        section_id,
        student_id,
        marks_obtained,
        grade,
        remarks,
        graded_at,
        graded_by,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    SELECT
        a.assessment_id,
        a.school_id,
        a.branch_id,
        a.academic_year_id,
        a.class_id,
        a.section_id,
        st.student_id,
        calc.marks_obtained,
        calc.grade,
        calc.remarks,
        calc.graded_at,
        calc.graded_by,
        1 AS is_active,
        DATEADD(DAY, 2, CAST(a.assessment_date AS DATETIME2(0))) AS created_at,
        COALESCE(calc.graded_by, @DefaultAdminUserId) AS created_by,
        DATEADD(DAY, 2, CAST(a.assessment_date AS DATETIME2(0))) AS updated_at,
        COALESCE(calc.graded_by, @DefaultAdminUserId) AS updated_by
    FROM teachers_schema.assessment a
    INNER JOIN student_schema.student st
        ON st.section_id = a.section_id
       AND st.is_active = 1
    LEFT JOIN teachers_schema.teacher t
        ON t.teacher_id = a.teacher_id
    CROSS APPLY (
        SELECT
            -- 1 out of every 12 submissions is an absent student with NULL marks
            CASE
                WHEN (st.student_id + a.assessment_id) % 12 = 0 THEN NULL
                ELSE CAST(
                    ROUND(
                        (a.max_marks * 0.60) +
                        (((st.student_id * 7 + a.assessment_id * 13) % 41) / 100.0) * (a.max_marks * 0.40),
                        2
                    ) AS DECIMAL(6, 2)
                )
            END AS marks_obtained
    ) m
    CROSS APPLY (
        SELECT
            m.marks_obtained,
            CASE
                WHEN m.marks_obtained IS NULL THEN NULL
                WHEN m.marks_obtained >= (a.max_marks * 0.90) THEN N'A+'
                WHEN m.marks_obtained >= (a.max_marks * 0.80) THEN N'A'
                WHEN m.marks_obtained >= (a.max_marks * 0.70) THEN N'B+'
                WHEN m.marks_obtained >= (a.max_marks * 0.60) THEN N'B'
                WHEN m.marks_obtained >= (a.max_marks * 0.40) THEN N'C'
                ELSE N'D'
            END AS grade,
            CASE
                WHEN m.marks_obtained IS NULL THEN N'Absent for assessment - re-test scheduled'
                WHEN m.marks_obtained >= (a.max_marks * 0.90) THEN N'Exceptional mastery, clear conceptual exposition, and thorough presentation.'
                WHEN m.marks_obtained >= (a.max_marks * 0.80) THEN N'Good performance with accurate answers; minor calculation improvements needed.'
                WHEN m.marks_obtained >= (a.max_marks * 0.70) THEN N'Satisfactory demonstration of syllabus concepts; revise textbook problems.'
                ELSE N'Needs targeted revision and additional practice sessions.'
            END AS remarks,
            CASE
                WHEN m.marks_obtained IS NULL THEN NULL
                ELSE DATEADD(HOUR, 14, DATEADD(DAY, 2, CAST(a.assessment_date AS DATETIME2(0))))
            END AS graded_at,
            CASE
                WHEN m.marks_obtained IS NULL THEN NULL
                ELSE COALESCE(t.user_id, @DefaultAdminUserId)
            END AS graded_by
    ) calc
    WHERE NOT EXISTS (
        SELECT 1
        FROM student_schema.assessment_result existing
        WHERE existing.assessment_id = a.assessment_id
          AND existing.student_id = st.student_id
    );

    DECLARE @ResultCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'Seeded student assessment marks into student_schema.assessment_result. New rows inserted: ', @ResultCount);

    -- =========================================================================
    -- 4. VERIFICATION SUMMARIES (SSMS RESULTS)
    -- =========================================================================
    -- Summary 1: Assessments by Type and Max Marks
    SELECT
        assessment_type,
        max_marks,
        COUNT(*) AS total_assessments,
        MIN(assessment_date) AS earliest_assessment,
        MAX(assessment_date) AS latest_assessment
    FROM teachers_schema.assessment
    GROUP BY assessment_type, max_marks
    ORDER BY assessment_type, max_marks;

    -- Summary 2: Grade Distribution on Assessment Results
    SELECT
        COALESCE(grade, N'ABSENT/UNGRADED') AS grade_category,
        COUNT(*) AS total_results,
        CAST(AVG(marks_obtained) AS DECIMAL(6, 2)) AS avg_marks_obtained,
        MIN(marks_obtained) AS min_marks,
        MAX(marks_obtained) AS max_marks
    FROM student_schema.assessment_result
    GROUP BY grade
    ORDER BY total_results DESC;

    -- Summary 3: Constraint Compliance Sanity Check (Expected: 0 invalid rows)
    SELECT
        ar.assessment_result_id,
        ar.marks_obtained,
        ar.graded_at,
        ar.graded_by,
        CASE
            WHEN ar.marks_obtained IS NOT NULL AND (ar.graded_at IS NULL OR ar.graded_by IS NULL)
                THEN N'FAIL: marks present but graded_at/graded_by missing'
            WHEN ar.marks_obtained IS NULL AND (ar.graded_at IS NOT NULL OR ar.graded_by IS NOT NULL)
                THEN N'FAIL: marks null but graded fields populated'
            ELSE N'PASS'
        END AS constraint_status
    FROM student_schema.assessment_result ar
    WHERE (ar.marks_obtained IS NOT NULL AND (ar.graded_at IS NULL OR ar.graded_by IS NULL))
       OR (ar.marks_obtained IS NULL AND (ar.graded_at IS NOT NULL OR ar.graded_by IS NOT NULL));

    COMMIT TRANSACTION;
    PRINT N'========================================================================';
    PRINT N'Assessment mock data transaction committed successfully.';
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
