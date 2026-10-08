/*
    Module: 006_assessment
    Purpose: Assessment master (project works, slip tests, quizzes - subject-wise) and per-student assessment marks

    Design notes:
    - teachers_schema.assessment = subject-wise assessments (project works, slip tests, quizzes) for one academic scope
    - student_schema.assessment_result = per-student marks storing table
    - No priority level
    - No estimated minutes/marks
    - No status/due_date/description/pass_marks on assessment
    - max_marks on assessment master; marks_obtained, grade, remarks, grading audit on assessment_result
    - No result_status/submission_status/submitted_at on assessment_result
    - Assessment attachment metadata: MongoDB + Blob Storage, not SQL

    Rollback:
    - DROP TABLE student_schema.assessment_result;
    - DROP TABLE teachers_schema.assessment;
*/

/* -------------------------------------------------------------------------- */
/* teachers_schema.assessment                                                 */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'teachers_schema.assessment', N'U') IS NULL
BEGIN
    CREATE TABLE teachers_schema.assessment
    (
        assessment_id          BIGINT          NOT NULL IDENTITY(1, 1),
        school_id              BIGINT          NOT NULL,
        academic_year_id       BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        class_id               BIGINT          NOT NULL,
        section_id             BIGINT          NOT NULL,
        subject_id             BIGINT          NOT NULL,
        teacher_id             BIGINT          NOT NULL,
        title                  NVARCHAR(200)   NOT NULL,
        assessment_type        NVARCHAR(50)    NOT NULL,
        assessment_date        DATE            NOT NULL CONSTRAINT DF_assessment_date DEFAULT (CAST(SYSUTCDATETIME() AS DATE)),
        max_marks              DECIMAL(6, 2)   NOT NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_assessment_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_assessment_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_assessment_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_assessment PRIMARY KEY CLUSTERED (assessment_id),
        CONSTRAINT CK_assessment_type CHECK
            (assessment_type IN (N'PROJECT_WORK', N'PROJECT', N'SLIP_TEST', N'QUIZ', N'OTHER')),
        CONSTRAINT CK_assessment_max_marks CHECK (max_marks > 0),
        CONSTRAINT FK_assessment_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_assessment_academic_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_assessment_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_assessment_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_assessment_section_scope FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_assessment_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_assessment_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_assessment_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_assessment_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_assessment_scope_date'
      AND object_id = OBJECT_ID(N'teachers_schema.assessment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_assessment_scope_date
        ON teachers_schema.assessment
        (school_id, branch_id, class_id, section_id, academic_year_id, assessment_date);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_assessment_teacher_active'
      AND object_id = OBJECT_ID(N'teachers_schema.assessment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_assessment_teacher_active
        ON teachers_schema.assessment (teacher_id, is_active)
        INCLUDE (title, assessment_date, class_id, section_id, subject_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_assessment_subject'
      AND object_id = OBJECT_ID(N'teachers_schema.assessment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_assessment_subject
        ON teachers_schema.assessment (subject_id, assessment_date)
        WHERE is_active = 1;
END;
GO

/* -------------------------------------------------------------------------- */
/* student_schema.assessment_result                                           */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.assessment_result', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.assessment_result
    (
        assessment_result_id   BIGINT          NOT NULL IDENTITY(1, 1),
        assessment_id          BIGINT          NOT NULL,
        school_id              BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        academic_year_id       BIGINT          NOT NULL,
        class_id               BIGINT          NOT NULL,
        section_id             BIGINT          NOT NULL,
        student_id             BIGINT          NOT NULL,
        marks_obtained         DECIMAL(6, 2)   NULL,
        grade                  NVARCHAR(10)    NULL,
        remarks                NVARCHAR(500)   NULL,
        graded_at              DATETIME2(0)    NULL,
        graded_by              BIGINT          NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_assessment_result_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_assessment_result_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_assessment_result_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_assessment_result PRIMARY KEY CLUSTERED (assessment_result_id),
        CONSTRAINT UQ_assessment_result_assessment_student UNIQUE NONCLUSTERED (assessment_id, student_id),
        CONSTRAINT CK_assessment_result_marks CHECK
            (marks_obtained IS NULL OR marks_obtained >= 0),
        CONSTRAINT CK_assessment_result_graded CHECK
            ((marks_obtained IS NULL AND graded_at IS NULL AND graded_by IS NULL)
             OR (marks_obtained IS NOT NULL AND graded_at IS NOT NULL AND graded_by IS NOT NULL)),
        CONSTRAINT FK_assessment_result_assessment FOREIGN KEY (assessment_id) REFERENCES teachers_schema.assessment (assessment_id),
        CONSTRAINT FK_assessment_result_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_assessment_result_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_assessment_result_academic_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_assessment_result_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_assessment_result_section_scope FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_assessment_result_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_assessment_result_graded_by FOREIGN KEY (graded_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_assessment_result_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_assessment_result_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_assessment_result_student_scope'
      AND object_id = OBJECT_ID(N'student_schema.assessment_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_assessment_result_student_scope
        ON student_schema.assessment_result
        (school_id, branch_id, academic_year_id, class_id, section_id, student_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_assessment_result_student_assessment'
      AND object_id = OBJECT_ID(N'student_schema.assessment_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_assessment_result_student_assessment
        ON student_schema.assessment_result (student_id, assessment_id)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_assessment_result_assessment'
      AND object_id = OBJECT_ID(N'student_schema.assessment_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_assessment_result_assessment
        ON student_schema.assessment_result (assessment_id, is_active)
        INCLUDE (student_id, marks_obtained, grade);
END;
GO
