/*
    Script:    011_student_exam_performance_mock_data.sql
    Module:    021_student_exam_performance / student_schema.student_exam_performance
    Purpose:   Populates student_exam_performance by reading existing data from
               student_schema.exam_result, management_schema.exam_schedule, and management_schema.exam.

    Simulation of Backend Calculation Logic:
    ---------------------------------------------------------------------------
    1. Read student results from existing exam_result joined with exam_schedule and exam.
    2. Calculate each individual exam's percentage:
       exam_percentage = (SUM(marks_obtained) / SUM(max_marks)) * 100
    3. Determine total_exams_count:
       COUNT(DISTINCT exam_id)
    4. Calculate the student's overall average percentage:
       AVG(exam_percentage)
    5. Save / update summary values into student_schema.student_exam_performance:
       - student_id
       - academic_year_id
       - class_id
       - section_id
       - total_exams_count
       - overall_percentage

    Zero Database Calculations:
    - student_exam_performance table remains a clean, uncomputed relational table.
    - Idempotent: checks for existing records or updates them safely.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Populating student_exam_performance from Existing Exam Records...';
PRINT N'========================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    -- =========================================================================
    -- 1. VERIFY TARGET TABLE EXISTS
    -- =========================================================================
    IF OBJECT_ID(N'student_schema.student_exam_performance', N'U') IS NULL
    BEGIN
        RAISERROR(N'Target table student_schema.student_exam_performance does not exist. Run migration 021_student_exam_performance.sql first.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- =========================================================================
    -- 2. COMPUTE BACKEND SUMMARY METRICS FROM EXISTING EXAM RESULTS
    -- =========================================================================
    -- Step 1 & 2: Calculate percentage per exam for each student
    ;WITH ExamLevelSummary AS (
        SELECT
            er.student_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            es.exam_id,
            SUM(er.marks_obtained) AS exam_marks_obtained,
            SUM(es.max_marks) AS exam_total_max_marks,
            CAST(
                SUM(er.marks_obtained) * 100.0 / NULLIF(SUM(es.max_marks), 0)
                AS DECIMAL(5, 2)
            ) AS exam_percentage
        FROM student_schema.exam_result er
        INNER JOIN student_schema.student st
            ON st.student_id = er.student_id
        INNER JOIN management_schema.exam_schedule es
            ON es.exam_schedule_id = er.exam_schedule_id
        WHERE er.is_active = 1
          AND er.result_status <> N'ABSENT'
          AND er.marks_obtained IS NOT NULL
          AND es.max_marks > 0
        GROUP BY
            er.student_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            es.exam_id
    ),
    -- Step 3 & 4: Overall student performance summary across exams
    StudentExamAggregates AS (
        SELECT
            els.student_id,
            els.academic_year_id,
            els.class_id,
            els.section_id,
            COUNT(DISTINCT els.exam_id) AS total_exams_count,
            CAST(AVG(els.exam_percentage) AS DECIMAL(5, 2)) AS overall_percentage
        FROM ExamLevelSummary els
        GROUP BY
            els.student_id,
            els.academic_year_id,
            els.class_id,
            els.section_id
    ),
    -- Secondary source: for students with assessment records (from 006 assessment module) if exam_result is absent
    AssessmentAggregates AS (
        SELECT
            ar.student_id,
            ar.academic_year_id,
            ar.class_id,
            ar.section_id,
            COUNT(DISTINCT a.assessment_id) AS total_exams_count,
            CAST(
                AVG(ar.marks_obtained * 100.0 / NULLIF(a.max_marks, 0))
                AS DECIMAL(5, 2)
            ) AS overall_percentage
        FROM student_schema.assessment_result ar
        INNER JOIN teachers_schema.assessment a
            ON a.assessment_id = ar.assessment_id
        WHERE ar.marks_obtained IS NOT NULL
          AND a.max_marks > 0
          AND ar.student_id NOT IN (SELECT student_id FROM StudentExamAggregates)
        GROUP BY
            ar.student_id,
            ar.academic_year_id,
            ar.class_id,
            ar.section_id
    ),
    CombinedPerformanceSource AS (
        SELECT * FROM StudentExamAggregates
        UNION ALL
        SELECT * FROM AssessmentAggregates
    )
    -- =========================================================================
    -- 3. UPSERT INTO student_schema.student_exam_performance
    -- =========================================================================
    MERGE INTO student_schema.student_exam_performance AS target
    USING CombinedPerformanceSource AS src
    ON (
        target.student_id = src.student_id
        AND target.academic_year_id = src.academic_year_id
        AND target.class_id = src.class_id
        AND target.section_id = src.section_id
    )
    WHEN MATCHED THEN
        UPDATE SET
            target.total_exams_count = src.total_exams_count,
            target.overall_percentage = src.overall_percentage,
            target.updated_at = SYSUTCDATETIME()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT
        (
            student_id,
            academic_year_id,
            class_id,
            section_id,
            total_exams_count,
            overall_percentage,
            created_at,
            updated_at
        )
        VALUES
        (
            src.student_id,
            src.academic_year_id,
            src.class_id,
            src.section_id,
            src.total_exams_count,
            src.overall_percentage,
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        );

    DECLARE @RowsAffected INT = @@ROWCOUNT;
    PRINT CONCAT(N'Processed student exam performance records. Total rows inserted / updated: ', @RowsAffected);

    -- =========================================================================
    -- 4. SSMS VERIFICATION SUMMARIES
    -- =========================================================================
    -- Summary 1: Detailed student performance roster
    SELECT
        sep.student_exam_performance_id,
        sep.student_id,
        CONCAT(st.first_name, N' ', COALESCE(st.last_name, N'')) AS student_name,
        st.admission_number,
        sc.class_name,
        sec.section_name,
        ay.year_name AS academic_year,
        sep.total_exams_count,
        sep.overall_percentage,
        CASE
            WHEN sep.overall_percentage >= 85.00 THEN N'Distinction / Exemplary'
            WHEN sep.overall_percentage >= 70.00 THEN N'First Class'
            WHEN sep.overall_percentage >= 50.00 THEN N'Second Class'
            WHEN sep.overall_percentage >= 40.00 THEN N'Pass'
            ELSE N'Needs Remedial Support'
        END AS performance_bracket
    FROM student_schema.student_exam_performance sep
    INNER JOIN student_schema.student st
        ON st.student_id = sep.student_id
    INNER JOIN management_schema.school_class sc
        ON sc.class_id = sep.class_id
    INNER JOIN management_schema.section sec
        ON sec.section_id = sep.section_id
    INNER JOIN management_schema.academic_year ay
        ON ay.academic_year_id = sep.academic_year_id
    ORDER BY sep.class_id, sep.section_id, sep.overall_percentage DESC;

    -- Summary 2: Class-wise Performance Metrics
    SELECT
        sc.class_name,
        sec.section_name,
        COUNT(*) AS total_students_evaluated,
        SUM(sep.total_exams_count) AS aggregate_exams_evaluated,
        CAST(AVG(sep.overall_percentage) AS DECIMAL(5, 2)) AS class_average_percentage,
        MIN(sep.overall_percentage) AS min_class_percentage,
        MAX(sep.overall_percentage) AS max_class_percentage
    FROM student_schema.student_exam_performance sep
    INNER JOIN management_schema.school_class sc
        ON sc.class_id = sep.class_id
    INNER JOIN management_schema.section sec
        ON sec.section_id = sep.section_id
    GROUP BY sc.class_name, sec.section_name
    ORDER BY sc.class_name, sec.section_name;

    COMMIT TRANSACTION;
    PRINT N'========================================================================';
    PRINT N'student_exam_performance data seeding committed successfully.';
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
