/* Module: 017_exam (management domain — runs after teacher) */
/*
    Migration: 007_exam
    Purpose:   Exam master, subject schedule, and per-student results

    Hierarchy on every table:
    school_id -> branch_id -> academic_year_id -> class_id -> section_id -> student_id (exam_result only)

    Design notes:
    - No term column on exams (terms are fee-only).
    - exam_category: ANNUAL, HALF_YEARLY, QUARTERLY, UNIT_TEST, etc.
    - percentage is computed in application/queries, not stored.
    - marks_obtained <= exam_schedule.max_marks enforced in application layer.

    Rollback:
    - DROP TABLE student_schema.exam_result;
    - DROP TABLE management_schema.exam_schedule;
    - DROP TABLE management_schema.exam;
*/

/* -------------------------------------------------------------------------- */
/* management_schema.exam                                                     */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'management_schema.exam', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.exam
    (
        exam_id            BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        academic_year_id   BIGINT          NOT NULL,
        class_id           BIGINT          NOT NULL,
        section_id         BIGINT          NOT NULL,
        exam_name          NVARCHAR(150)   NOT NULL,
        exam_category      NVARCHAR(50)    NOT NULL,
        start_date         DATE            NOT NULL,
        end_date           DATE            NOT NULL,
        status             NVARCHAR(20)    NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_exam_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_exam_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NOT NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_exam_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_exam PRIMARY KEY CLUSTERED (exam_id),
        CONSTRAINT UQ_exam_section_name UNIQUE NONCLUSTERED
            (school_id, branch_id, academic_year_id, class_id, section_id, exam_name),
        CONSTRAINT CK_exam_date_range CHECK (end_date >= start_date),
        CONSTRAINT CK_exam_status CHECK
            (status IN (N'DRAFT', N'PUBLISHED', N'COMPLETED', N'CANCELLED')),
        CONSTRAINT FK_exam_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_exam_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_exam_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_exam_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_exam_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_exam_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_exam_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_academic_scope_status'
      AND object_id = OBJECT_ID(N'management_schema.exam')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_academic_scope_status
        ON management_schema.exam
        (school_id, branch_id, academic_year_id, class_id, section_id, status, start_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_category_scope'
      AND object_id = OBJECT_ID(N'management_schema.exam')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_category_scope
        ON management_schema.exam
        (school_id, branch_id, academic_year_id, exam_category, start_date)
        WHERE is_active = 1;
END;
GO

/* -------------------------------------------------------------------------- */
/* management_schema.exam_schedule                                            */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'management_schema.exam_schedule', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.exam_schedule
    (
        exam_schedule_id   BIGINT          NOT NULL IDENTITY(1, 1),
        exam_id            BIGINT          NOT NULL,
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        academic_year_id   BIGINT          NOT NULL,
        class_id           BIGINT          NOT NULL,
        section_id         BIGINT          NOT NULL,
        subject_id         BIGINT          NOT NULL,
        teacher_id         BIGINT          NOT NULL,
        exam_date          DATE            NOT NULL,
        start_time         TIME(0)         NOT NULL,
        end_time           TIME(0)         NOT NULL,
        max_marks          DECIMAL(6, 2)   NOT NULL,
        pass_marks         DECIMAL(6, 2)   NULL,
        status             NVARCHAR(20)    NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_exam_schedule_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_exam_schedule_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NOT NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_exam_schedule_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_exam_schedule PRIMARY KEY CLUSTERED (exam_schedule_id),
        CONSTRAINT UQ_exam_schedule_exam_subject UNIQUE NONCLUSTERED (exam_id, subject_id),
        CONSTRAINT CK_exam_schedule_time CHECK (end_time > start_time),
        CONSTRAINT CK_exam_schedule_max_marks CHECK (max_marks > 0),
        CONSTRAINT CK_exam_schedule_pass_marks CHECK
            (pass_marks IS NULL OR (pass_marks >= 0 AND pass_marks <= max_marks)),
        CONSTRAINT CK_exam_schedule_status CHECK
            (status IN (N'SCHEDULED', N'COMPLETED', N'CANCELLED')),
        CONSTRAINT FK_exam_schedule_exam FOREIGN KEY (exam_id) REFERENCES management_schema.exam (exam_id),
        CONSTRAINT FK_exam_schedule_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_exam_schedule_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_exam_schedule_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_exam_schedule_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_exam_schedule_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_exam_schedule_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_exam_schedule_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_exam_schedule_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_exam_schedule_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_schedule_academic_scope'
      AND object_id = OBJECT_ID(N'management_schema.exam_schedule')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_schedule_academic_scope
        ON management_schema.exam_schedule
        (school_id, branch_id, academic_year_id, class_id, section_id, exam_date, status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_schedule_teacher_date'
      AND object_id = OBJECT_ID(N'management_schema.exam_schedule')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_schedule_teacher_date
        ON management_schema.exam_schedule (teacher_id, exam_date, start_time)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_schedule_exam_date'
      AND object_id = OBJECT_ID(N'management_schema.exam_schedule')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_schedule_exam_date
        ON management_schema.exam_schedule (exam_id, exam_date, start_time)
        WHERE is_active = 1;
END;
GO

