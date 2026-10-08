/* Module migration: 003_management.sql */
/*
    Migration: 003_management_masters
    Purpose:   Institutional master data required by student_schema.student foreign keys
*/

IF OBJECT_ID(N'management_schema.school', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.school
    (
        school_id          BIGINT          NOT NULL IDENTITY(1, 1),
        school_code        NVARCHAR(50)    NOT NULL,
        school_name        NVARCHAR(150)   NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_school_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_school_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_school_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_school PRIMARY KEY CLUSTERED (school_id),
        CONSTRAINT UQ_school_code UNIQUE NONCLUSTERED (school_code),
        CONSTRAINT FK_school_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_school_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF OBJECT_ID(N'management_schema.branch', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.branch
    (
        branch_id          BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        branch_code        NVARCHAR(50)    NOT NULL,
        branch_name        NVARCHAR(150)   NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_branch_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_branch_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_branch_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_branch PRIMARY KEY CLUSTERED (branch_id),
        CONSTRAINT UQ_branch_school_code UNIQUE NONCLUSTERED (school_id, branch_code),
        CONSTRAINT FK_branch_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_branch_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_branch_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF OBJECT_ID(N'management_schema.academic_year', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.academic_year
    (
        academic_year_id   BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        year_name          NVARCHAR(50)    NOT NULL,
        start_date         DATE            NOT NULL,
        end_date           DATE            NOT NULL,
        is_current         BIT             NOT NULL CONSTRAINT DF_academic_year_is_current DEFAULT (0),
        is_active          BIT             NOT NULL CONSTRAINT DF_academic_year_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_academic_year_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_academic_year_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_academic_year PRIMARY KEY CLUSTERED (academic_year_id),
        CONSTRAINT UQ_academic_year_school_name UNIQUE NONCLUSTERED (school_id, year_name),
        CONSTRAINT CK_academic_year_dates CHECK (end_date >= start_date),
        CONSTRAINT FK_academic_year_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_academic_year_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_academic_year_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF OBJECT_ID(N'management_schema.school_class', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.school_class
    (
        class_id           BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        class_name         NVARCHAR(150)   NOT NULL,
        display_order      INT             NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_school_class_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_school_class_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_school_class_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_school_class PRIMARY KEY CLUSTERED (class_id),
        CONSTRAINT UQ_school_class_school_name UNIQUE NONCLUSTERED (school_id, class_name),
        CONSTRAINT FK_school_class_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_school_class_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_school_class_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF OBJECT_ID(N'management_schema.section', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.section
    (
        section_id         BIGINT          NOT NULL IDENTITY(1, 1),
        class_id           BIGINT          NOT NULL,
        section_name       NVARCHAR(50)    NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_section_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_section_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_section_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_section PRIMARY KEY CLUSTERED (section_id),
        CONSTRAINT UQ_section_class_name UNIQUE NONCLUSTERED (class_id, section_name),
        CONSTRAINT FK_section_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_section_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_section_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF OBJECT_ID(N'management_schema.subject', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.subject
    (
        subject_id         BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        subject_code       NVARCHAR(50)    NOT NULL,
        subject_name       NVARCHAR(150)   NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_subject_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_subject_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_subject_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_subject PRIMARY KEY CLUSTERED (subject_id),
        CONSTRAINT UQ_subject_school_code UNIQUE NONCLUSTERED (school_id, subject_code),
        CONSTRAINT FK_subject_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_subject_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_subject_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

/*
    Migration: 020_class_subject_teacher_assignment
    Purpose:   Class-wise subject curriculum and section-level teacher assignment

    Design notes:
    - management_schema.class_subject = which subjects a class offers (school/branch/year/class)
    - teachers_schema.teacher_subject_assignment = which teacher teaches each subject per section
    - UI assigns master subjects (management_schema.subject) to classes, then assigns teachers per section
    - Students inherit subjects from class/section scope (student.class_id + student.section_id)
    - Course completion % is NOT stored here â€” syllabus in MongoDB; progress via timetable + API

    Rollback:
    - DROP TABLE teachers_schema.teacher_subject_assignment;
    - DROP TABLE management_schema.class_subject;
*/

/* -------------------------------------------------------------------------- */
/* management_schema.class_subject                                            */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'management_schema.class_subject', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.class_subject
    (
        class_subject_id       BIGINT          NOT NULL IDENTITY(1, 1),
        school_id              BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        academic_year_id       BIGINT          NOT NULL,
        class_id               BIGINT          NOT NULL,
        subject_id             BIGINT          NOT NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_class_subject_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_class_subject_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_class_subject_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_class_subject PRIMARY KEY CLUSTERED (class_subject_id),
        CONSTRAINT UQ_class_subject_scope UNIQUE NONCLUSTERED
            (school_id, branch_id, academic_year_id, class_id, subject_id),
        CONSTRAINT FK_class_subject_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_class_subject_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_class_subject_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_class_subject_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_class_subject_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_class_subject_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_class_subject_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_class_subject_class_active'
      AND object_id = OBJECT_ID(N'management_schema.class_subject')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_class_subject_class_active
        ON management_schema.class_subject
        (school_id, branch_id, academic_year_id, class_id, is_active)
        INCLUDE (subject_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_class_subject_subject_active'
      AND object_id = OBJECT_ID(N'management_schema.class_subject')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_class_subject_subject_active
        ON management_schema.class_subject (subject_id, is_active)
        INCLUDE (school_id, branch_id, academic_year_id, class_id);
END;
GO

/* Scope composite unique keys (enable child composite FK enforcement) */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_branch_school_scope' AND object_id = OBJECT_ID(N'management_schema.branch'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_branch_school_scope ON management_schema.branch (school_id, branch_id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_academic_year_school_scope' AND object_id = OBJECT_ID(N'management_schema.academic_year'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_academic_year_school_scope ON management_schema.academic_year (school_id, academic_year_id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_school_class_school_scope' AND object_id = OBJECT_ID(N'management_schema.school_class'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_school_class_school_scope ON management_schema.school_class (school_id, class_id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_section_class_scope' AND object_id = OBJECT_ID(N'management_schema.section'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_section_class_scope ON management_schema.section (class_id, section_id);
GO

