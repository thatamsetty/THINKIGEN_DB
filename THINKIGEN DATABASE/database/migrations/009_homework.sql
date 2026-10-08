/* Module migration: 009_homework.sql */
/*
    Migration: 011_homework
    Purpose:   Section-scoped homework / learning tasks (no marks) with deadlines

    Design notes:
    - teachers_schema.homework = one homework for one academic scope (school/branch/year/class/section/subject)
    - student_schema.homework_status = per-student submission with academic scope
      (school_id, branch_id, academic_year_id, class_id, section_id) for ABAC filtering
    - homework_type: HOMEWORK, READING, OTHER
    - submission_timing on student_schema.homework_status: ON_TIME, LATE, NULL
      (determined by comparing submitted_at against homework.deadline_at)
    - Attachment metadata lives in MongoDB + Blob Storage, not SQL
    - Graded work remains in teachers_schema.assessment (006)

    Rollback:
    - See database/migrations/rollback/009_homework_rollback.sql
*/

/* -------------------------------------------------------------------------- */
/* 1. teachers_schema.homework                                                */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'teachers_schema.homework', N'U') IS NULL
BEGIN
    CREATE TABLE teachers_schema.homework
    (
        homework_id            BIGINT          NOT NULL IDENTITY(1, 1),
        school_id              BIGINT          NOT NULL,
        academic_year_id       BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        class_id               BIGINT          NOT NULL,
        section_id             BIGINT          NOT NULL,
        subject_id             BIGINT          NOT NULL,
        teacher_id             BIGINT          NOT NULL,
        homework_type          NVARCHAR(50)    NOT NULL,
        title                  NVARCHAR(200)   NOT NULL,
        description            NVARCHAR(MAX)   NULL,
        priority_level         NVARCHAR(20)    NOT NULL,
        assigned_at            DATETIME2(0)    NOT NULL CONSTRAINT DF_homework_assigned_at DEFAULT (SYSUTCDATETIME()),
        deadline_at            DATETIME2(0)    NOT NULL,
        status                 NVARCHAR(20)    NOT NULL,
        estimated_minutes      INT             NULL,
        published_at           DATETIME2(0)    NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_homework_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_homework_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_homework_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_homework PRIMARY KEY CLUSTERED (homework_id),
        CONSTRAINT CK_homework_type CHECK
            (homework_type IN (N'HOMEWORK', N'READING', N'OTHER')),
        CONSTRAINT CK_homework_priority CHECK (priority_level IN (N'HIGH', N'MEDIUM', N'LOW')),
        CONSTRAINT CK_homework_status CHECK (status IN (N'DRAFT', N'PUBLISHED', N'CLOSED', N'CANCELLED')),
        CONSTRAINT CK_homework_estimated_minutes CHECK (estimated_minutes IS NULL OR estimated_minutes >= 0),
        CONSTRAINT CK_homework_deadline CHECK (deadline_at >= assigned_at),
        CONSTRAINT CK_homework_published_at CHECK
            (status <> N'PUBLISHED' OR published_at IS NOT NULL),
        CONSTRAINT FK_homework_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_homework_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_homework_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_homework_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_homework_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_homework_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_homework_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_homework_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_homework_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

-- Idempotent modification for existing teachers_schema.homework table
IF OBJECT_ID(N'teachers_schema.homework', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    -- A. Remove allow_late_submission column and its constraints if present
    DECLARE @drop_df_homework NVARCHAR(MAX) = N'';
    SELECT @drop_df_homework = @drop_df_homework + N'ALTER TABLE teachers_schema.homework DROP CONSTRAINT ' + QUOTENAME(dc.name) + N';' + CHAR(13) + CHAR(10)
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c
        ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'teachers_schema.homework')
      AND c.name = N'allow_late_submission';

    IF @drop_df_homework <> N''
        EXEC sys.sp_executesql @drop_df_homework;

    DECLARE @drop_ck_homework NVARCHAR(MAX) = N'';
    SELECT @drop_ck_homework = @drop_ck_homework + N'ALTER TABLE teachers_schema.homework DROP CONSTRAINT ' + QUOTENAME(cc.name) + N';' + CHAR(13) + CHAR(10)
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = OBJECT_ID(N'teachers_schema.homework')
      AND cc.definition LIKE N'%allow_late_submission%';

    IF @drop_ck_homework <> N''
        EXEC sys.sp_executesql @drop_ck_homework;

    IF COL_LENGTH(N'teachers_schema.homework', N'allow_late_submission') IS NOT NULL
    BEGIN
        ALTER TABLE teachers_schema.homework
            DROP COLUMN allow_late_submission;
    END;

    -- B. Convert unsupported homework_type records to 'OTHER'
    UPDATE teachers_schema.homework
    SET homework_type = N'OTHER'
    WHERE homework_type NOT IN (N'HOMEWORK', N'READING', N'OTHER');

    -- C. Restrict CK_homework_type to HOMEWORK, READING, OTHER
    IF EXISTS (
        SELECT 1 FROM sys.check_constraints
        WHERE name = N'CK_homework_type'
          AND parent_object_id = OBJECT_ID(N'teachers_schema.homework')
    )
    BEGIN
        ALTER TABLE teachers_schema.homework
            DROP CONSTRAINT CK_homework_type;
    END;

    ALTER TABLE teachers_schema.homework
        ADD CONSTRAINT CK_homework_type
        CHECK (homework_type IN (N'HOMEWORK', N'READING', N'OTHER'));
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_homework_scope_status_deadline'
      AND object_id = OBJECT_ID(N'teachers_schema.homework')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_homework_scope_status_deadline
        ON teachers_schema.homework
        (school_id, branch_id, class_id, section_id, academic_year_id, status, deadline_at);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_homework_teacher_active'
      AND object_id = OBJECT_ID(N'teachers_schema.homework')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_homework_teacher_active
        ON teachers_schema.homework (teacher_id, status, is_active)
        INCLUDE (title, deadline_at, class_id, section_id, subject_id, homework_type);
END;
GO

/* -------------------------------------------------------------------------- */
/* 2. student_schema.homework_status                                          */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.homework_status', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.homework_status
    (
        homework_status_id     BIGINT          NOT NULL IDENTITY(1, 1),
        homework_id            BIGINT          NOT NULL,
        school_id              BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        academic_year_id       BIGINT          NOT NULL,
        class_id               BIGINT          NOT NULL,
        section_id             BIGINT          NOT NULL,
        student_id             BIGINT          NOT NULL,
        submission_status      NVARCHAR(20)    NOT NULL CONSTRAINT DF_homework_status_submission_status DEFAULT (N'NOT_SUBMITTED'),
        submitted_at           DATETIME2(0)    NULL,
        submission_timing      NVARCHAR(20)    NULL,
        remarks                NVARCHAR(500)   NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_homework_status_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_homework_status_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_homework_status_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_homework_status PRIMARY KEY CLUSTERED (homework_status_id),
        CONSTRAINT UQ_homework_status_homework_student UNIQUE NONCLUSTERED (homework_id, student_id),
        CONSTRAINT CK_homework_status_submission_status CHECK
            (submission_status IN (N'NOT_SUBMITTED', N'SUBMITTED')),
        CONSTRAINT CK_homework_status_submitted_at CHECK
            ((submission_status = N'SUBMITTED' AND submitted_at IS NOT NULL)
             OR (submission_status = N'NOT_SUBMITTED' AND submitted_at IS NULL)),
        CONSTRAINT CK_homework_status_submission_timing CHECK
            (submission_timing IS NULL OR submission_timing IN (N'ON_TIME', N'LATE')),
        CONSTRAINT FK_homework_status_homework FOREIGN KEY (homework_id) REFERENCES teachers_schema.homework (homework_id),
        CONSTRAINT FK_homework_status_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_homework_status_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_homework_status_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_homework_status_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_homework_status_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_homework_status_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_homework_status_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_homework_status_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

-- Idempotent modification for existing student_schema.homework_status table: Step 1 - Add column
IF OBJECT_ID(N'student_schema.homework_status', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    -- A. Add submission_timing column if missing
    IF COL_LENGTH(N'student_schema.homework_status', N'submission_timing') IS NULL
    BEGIN
        ALTER TABLE student_schema.homework_status
            ADD submission_timing NVARCHAR(20) NULL;
    END;
END;
GO

-- Idempotent modification for existing student_schema.homework_status table: Step 2 - Data Backfill & Constraint
IF OBJECT_ID(N'student_schema.homework_status', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    -- B. Data Backfill executed via sp_executesql to eliminate batch compilation errors (Msg 207)
    EXEC sys.sp_executesql N'
        UPDATE hs
        SET hs.submission_timing = NULL
        FROM student_schema.homework_status hs
        WHERE hs.submission_status = N''NOT_SUBMITTED'';

        UPDATE hs
        SET hs.submission_timing = CASE
            WHEN hs.submitted_at <= h.deadline_at THEN N''ON_TIME''
            ELSE N''LATE''
        END
        FROM student_schema.homework_status hs
        INNER JOIN teachers_schema.homework h
            ON h.homework_id = hs.homework_id
        WHERE hs.submission_status = N''SUBMITTED''
          AND hs.submitted_at IS NOT NULL
          AND h.deadline_at IS NOT NULL;
    ';

    -- C. Drop and recreate CK_homework_status_submission_timing
    IF EXISTS (
        SELECT 1 FROM sys.check_constraints
        WHERE name = N'CK_homework_status_submission_timing'
          AND parent_object_id = OBJECT_ID(N'student_schema.homework_status')
    )
    BEGIN
        ALTER TABLE student_schema.homework_status
            DROP CONSTRAINT CK_homework_status_submission_timing;
    END;

    EXEC sys.sp_executesql N'
        ALTER TABLE student_schema.homework_status
            ADD CONSTRAINT CK_homework_status_submission_timing
            CHECK (submission_timing IS NULL OR submission_timing IN (N''ON_TIME'', N''LATE''));
    ';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_homework_status_student_scope'
      AND object_id = OBJECT_ID(N'student_schema.homework_status')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_homework_status_student_scope
        ON student_schema.homework_status
        (school_id, branch_id, academic_year_id, class_id, section_id, student_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_homework_status_student_submission'
      AND object_id = OBJECT_ID(N'student_schema.homework_status')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_homework_status_student_submission
        ON student_schema.homework_status (student_id, submission_status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_homework_status_student_homework'
      AND object_id = OBJECT_ID(N'student_schema.homework_status')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_homework_status_student_homework
        ON student_schema.homework_status (student_id, homework_id)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_homework_status_homework_submission'
      AND object_id = OBJECT_ID(N'student_schema.homework_status')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_homework_status_homework_submission
        ON student_schema.homework_status (homework_id, submission_status)
        WHERE is_active = 1;
END;
GO
