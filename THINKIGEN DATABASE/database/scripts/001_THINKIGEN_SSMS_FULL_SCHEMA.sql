/*
    THINKIGEN ERP - Full SQL Server Schema
    Paste this entire file into SSMS and execute it as one query.

    Includes all 25 schema migrations and creates all application tables across 9 schemas.
    This script is idempotent: existing tables and indexes are preserved.
    It does not create a database or insert seed data.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET NOCOUNT ON;
GO

/* BEGIN INLINE MIGRATION: 001_schemas.sql */
/*
    Module: 001_schemas
    Purpose: Create all Thinkigen SQL Server schemas (one Organization = one database)
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'security_schema')
    EXEC(N'CREATE SCHEMA security_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'management_schema')
    EXEC(N'CREATE SCHEMA management_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'student_schema')
    EXEC(N'CREATE SCHEMA student_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'teachers_schema')
    EXEC(N'CREATE SCHEMA teachers_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'finance_schema')
    EXEC(N'CREATE SCHEMA finance_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'library_schema')
    EXEC(N'CREATE SCHEMA library_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'transport_schema')
    EXEC(N'CREATE SCHEMA transport_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'alumni_schema')
    EXEC(N'CREATE SCHEMA alumni_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sports_schema')
    EXEC(N'CREATE SCHEMA sports_schema AUTHORIZATION dbo;');
GO

/* END INLINE MIGRATION: 001_schemas.sql */

/* BEGIN INLINE MIGRATION: 002_security.sql */
/*
    Module: 002_security
    Purpose: Identity + credentials (one users table), login audit, migration tracking

    Auth design (approved simplified model):
    - users = identity + password/lock fields; login key = email_address (NOT NULL, UNIQUE)
    - No username column
    - No separate user_credential table (merged into users)
    - No user_refresh_token in SQL â€” access + refresh tokens live in MongoDB
    - No RBAC tables (role / permission / role_permission / user_role_assignment)
      Authorization = user_type + domain placement (student / teacher assignment) in FastAPI
    - No user_scope table â€” scope derived in FastAPI from student/teacher/admin rules
    - user_login_attempt = append-only audit; user_id NOT NULL (only when user is known)
    - password_hash via FastAPI (bcrypt/argon2); password_plain_dev LOCAL only â€” remove before production
    - schema_version tracks applied SQL migrations
*/

/* -------------------------------------------------------------------------- */
/* security_schema.users                                                      */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.users', N'U') IS NULL
BEGIN
    CREATE TABLE security_schema.users
    (
        user_id                BIGINT          NOT NULL IDENTITY(1, 1),
        email_address          NVARCHAR(254)   NOT NULL,
        user_type              NVARCHAR(30)    NOT NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_users_is_active DEFAULT (1),
        password_hash          NVARCHAR(255)   NULL,
        password_plain_dev     NVARCHAR(255)   NULL,
        password_set_at        DATETIME2(0)    NULL,
        failed_login_count     INT             NOT NULL CONSTRAINT DF_users_failed_login DEFAULT (0),
        locked_until           DATETIME2(0)    NULL,
        last_login_at          DATETIME2(0)    NULL,
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_users_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_users_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_users PRIMARY KEY CLUSTERED (user_id),
        CONSTRAINT UQ_users_email_address UNIQUE NONCLUSTERED (email_address),
        CONSTRAINT CK_users_failed_login CHECK (failed_login_count >= 0)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_users_user_type_active' AND object_id = OBJECT_ID(N'security_schema.users')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_users_user_type_active
        ON security_schema.users (user_type, is_active);
END;
GO

/* -------------------------------------------------------------------------- */
/* security_schema.user_login_attempt                                         */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.user_login_attempt', N'U') IS NULL
BEGIN
    CREATE TABLE security_schema.user_login_attempt
    (
        login_attempt_id     BIGINT          NOT NULL IDENTITY(1, 1),
        user_id              BIGINT          NOT NULL,
        is_success           BIT             NOT NULL,
        failure_reason       NVARCHAR(50)    NULL,
        ip_address           NVARCHAR(45)    NULL,
        user_agent           NVARCHAR(500)   NULL,
        attempted_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_user_login_attempt_attempted_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_user_login_attempt PRIMARY KEY CLUSTERED (login_attempt_id),
        CONSTRAINT CK_user_login_attempt_result CHECK
            ((is_success = 1 AND failure_reason IS NULL)
             OR (is_success = 0 AND failure_reason IS NOT NULL)),
        CONSTRAINT CK_user_login_attempt_failure_reason CHECK
            (failure_reason IS NULL OR failure_reason IN (
                N'BAD_PASSWORD', N'USER_INACTIVE', N'ACCOUNT_LOCKED')),
        CONSTRAINT FK_user_login_attempt_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_user_login_attempt_user_time'
      AND object_id = OBJECT_ID(N'security_schema.user_login_attempt')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_user_login_attempt_user_time
        ON security_schema.user_login_attempt (user_id, attempted_at DESC);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_user_login_attempt_ip_time'
      AND object_id = OBJECT_ID(N'security_schema.user_login_attempt')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_user_login_attempt_ip_time
        ON security_schema.user_login_attempt (ip_address, attempted_at DESC)
        WHERE ip_address IS NOT NULL;
END;
GO

/* -------------------------------------------------------------------------- */
/* security_schema.schema_version                                             */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NULL
BEGIN
    CREATE TABLE security_schema.schema_version
    (
        schema_version_id  INT             NOT NULL IDENTITY(1, 1),
        migration_name     NVARCHAR(200)   NOT NULL,
        applied_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_schema_version_applied_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_schema_version PRIMARY KEY CLUSTERED (schema_version_id),
        CONSTRAINT UQ_schema_version_name UNIQUE NONCLUSTERED (migration_name)
    );
END;
GO

/* END INLINE MIGRATION: 002_security.sql */

/* BEGIN INLINE MIGRATION: 003_management.sql */
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


/* END INLINE MIGRATION: 003_management.sql */

/* BEGIN INLINE MIGRATION: 004_teacher.sql */
/* Module migration: 004_teacher.sql */
/*
    Migration: 005_teacher_master
    Purpose:   Teacher master identity within school/branch scope

    Note:      subject_id is optional primary-subject reference only.
               Authoritative teaching scope: teachers_schema.teacher_subject_assignment.
               Do not duplicate subject name on this table.
*/

IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NULL
BEGIN
    CREATE TABLE teachers_schema.teacher
    (
        teacher_id         BIGINT          NOT NULL IDENTITY(1, 1),
        user_id            BIGINT          NULL,
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        subject_id         BIGINT          NULL,
        designation        VARCHAR(100)    NOT NULL,
        employee_code      NVARCHAR(50)    NOT NULL,
        first_name         NVARCHAR(100)   NOT NULL,
        middle_name        NVARCHAR(100)   NULL,
        last_name          NVARCHAR(100)   NULL,
        mobile_number      NVARCHAR(20)    NULL,
        email_address      NVARCHAR(254)   NULL,
        status             NVARCHAR(20)    NOT NULL CONSTRAINT DF_teacher_status DEFAULT (N'ACTIVE'),
        is_active          BIT             NOT NULL CONSTRAINT DF_teacher_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_teacher PRIMARY KEY CLUSTERED (teacher_id),
        CONSTRAINT UQ_teacher_school_employee_code UNIQUE NONCLUSTERED (school_id, employee_code),
        CONSTRAINT UQ_teacher_user_id UNIQUE NONCLUSTERED (user_id),
        CONSTRAINT CK_teacher_status CHECK (status IN (N'ACTIVE', N'INACTIVE', N'ON_LEAVE')),
        CONSTRAINT FK_teacher_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_teacher_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_teacher_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_teacher_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_teacher_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_teacher_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_school_branch_active' AND object_id = OBJECT_ID(N'teachers_schema.teacher')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_school_branch_active
        ON teachers_schema.teacher (school_id, branch_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_subject_active' AND object_id = OBJECT_ID(N'teachers_schema.teacher')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_subject_active
        ON teachers_schema.teacher (subject_id, is_active)
        INCLUDE (school_id, branch_id, first_name, last_name);
END;
GO

/* -------------------------------------------------------------------------- */
/* Idempotent modification for existing teachers_schema.teacher table        */
/* -------------------------------------------------------------------------- */
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    -- A. Detect if designation column is missing; add as VARCHAR(100) NULL first
    IF COL_LENGTH(N'teachers_schema.teacher', N'designation') IS NULL
    BEGIN
        ALTER TABLE teachers_schema.teacher
            ADD designation VARCHAR(100) NULL;
    END;
END;
GO

IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    -- B. Populate designation by mapping each teacher's subject_id -> subject_name + ' Teacher'
    UPDATE t
    SET t.designation = CONCAT(s.subject_name, ' Teacher')
    FROM teachers_schema.teacher t
    INNER JOIN management_schema.subject s
        ON s.subject_id = t.subject_id
    WHERE t.designation IS NULL
       OR t.designation <> CONCAT(s.subject_name, ' Teacher');
END;
GO

IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    -- C. Enforce NOT NULL constraint once existing records are populated
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'teachers_schema.teacher')
          AND name = N'designation'
          AND is_nullable = 1
    )
    BEGIN
        IF EXISTS (SELECT 1 FROM teachers_schema.teacher WHERE designation IS NULL)
        BEGIN
            THROW 50001, N'Cannot alter designation to NOT NULL: unmapped teachers exist with NULL designation.', 1;
        END;

        ALTER TABLE teachers_schema.teacher
            ALTER COLUMN designation VARCHAR(100) NOT NULL;
    END;
END;
GO

IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    -- D. Validation: ensure every teacher has a non-NULL designation matching their subject_id mapping
    IF EXISTS (
        SELECT 1
        FROM teachers_schema.teacher t
        LEFT JOIN management_schema.subject s
            ON s.subject_id = t.subject_id
        WHERE t.designation IS NULL
           OR t.designation <> CONCAT(s.subject_name, ' Teacher')
    )
    BEGIN
        THROW 50002, N'Validation failed: One or more teachers have a NULL or mismatched designation.', 1;
    END;
END;
GO


/* -------------------------------------------------------------------------- */
/* teachers_schema.teacher_subject_assignment                                 */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'teachers_schema.teacher_subject_assignment', N'U') IS NULL
BEGIN
    CREATE TABLE teachers_schema.teacher_subject_assignment
    (
        teacher_subject_assignment_id  BIGINT          NOT NULL IDENTITY(1, 1),
        school_id                      BIGINT          NOT NULL,
        branch_id                      BIGINT          NOT NULL,
        academic_year_id               BIGINT          NOT NULL,
        class_id                       BIGINT          NOT NULL,
        section_id                     BIGINT          NOT NULL,
        class_subject_id               BIGINT          NOT NULL,
        subject_id                     BIGINT          NOT NULL,
        teacher_id                     BIGINT          NOT NULL,
        is_active                      BIT             NOT NULL CONSTRAINT DF_teacher_subject_assignment_is_active DEFAULT (1),
        created_at                     DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_subject_assignment_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                     BIGINT          NOT NULL,
        updated_at                     DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_subject_assignment_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                     BIGINT          NULL,
        row_version                    ROWVERSION      NOT NULL,
        CONSTRAINT PK_teacher_subject_assignment PRIMARY KEY CLUSTERED (teacher_subject_assignment_id),
        CONSTRAINT UQ_teacher_subject_assignment_scope UNIQUE NONCLUSTERED
            (school_id, branch_id, academic_year_id, class_id, section_id, subject_id),
        CONSTRAINT FK_teacher_subject_assignment_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_teacher_subject_assignment_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_teacher_subject_assignment_academic_year_scope FOREIGN KEY (school_id, academic_year_id) REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_teacher_subject_assignment_class_scope FOREIGN KEY (school_id, class_id) REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_teacher_subject_assignment_section_scope FOREIGN KEY (class_id, section_id) REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_teacher_subject_assignment_class_subject FOREIGN KEY (class_subject_id) REFERENCES management_schema.class_subject (class_subject_id),
        CONSTRAINT FK_teacher_subject_assignment_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_teacher_subject_assignment_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_teacher_subject_assignment_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_teacher_subject_assignment_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_subject_assignment_teacher_active'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher_subject_assignment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_subject_assignment_teacher_active
        ON teachers_schema.teacher_subject_assignment (teacher_id, is_active)
        INCLUDE (school_id, branch_id, academic_year_id, class_id, section_id, subject_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_subject_assignment_section_active'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher_subject_assignment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_subject_assignment_section_active
        ON teachers_schema.teacher_subject_assignment
        (school_id, branch_id, academic_year_id, class_id, section_id, is_active)
        INCLUDE (subject_id, teacher_id);
END;
GO


/* END INLINE MIGRATION: 004_teacher.sql */

/* BEGIN INLINE MIGRATION: 017_exam.sql */
/* Module: 017_exam (management domain â€” runs after teacher) */
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


/* END INLINE MIGRATION: 017_exam.sql */

/* BEGIN INLINE MIGRATION: 005_student.sql */
/* Module migration: 005_student.sql */
/*
    Migration: 004_student_master
    Purpose:   Student master identity, current academic placement, and guardians

    Design notes:
    - No student_enrollment table. When a security_schema.users row with user_type = STUDENT
      completes enrollment, one student_schema.student row is created with school/branch/
      academic_year/class/section placement. Class promotion/transfer updates this row.
    - No student_document SQL table. Document metadata lives in MongoDB; files in Blob Storage.
    - Student documents rule: .cursor/rules/24-student-documents-mongodb.mdc

    Rollback:
    - DROP TABLE student_schema.student_guardian;
    - DROP TABLE student_schema.student;
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student                                                     */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student
    (
        student_id             BIGINT          NOT NULL IDENTITY(1, 1),
        user_id                BIGINT          NULL,
        school_id              BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        academic_year_id       BIGINT          NOT NULL,
        class_id               BIGINT          NOT NULL,
        section_id             BIGINT          NOT NULL,
        admission_number       NVARCHAR(50)    NOT NULL,
        roll_number            NVARCHAR(30)    NULL,
        first_name             NVARCHAR(100)   NOT NULL,
        middle_name            NVARCHAR(100)   NULL,
        last_name              NVARCHAR(100)   NULL,
        date_of_birth          DATE            NOT NULL,
        gender                 NVARCHAR(30)    NOT NULL,
        blood_group            NVARCHAR(10)    NULL,
        nationality            NVARCHAR(100)   NULL,
        mother_tongue          NVARCHAR(100)   NULL,
        religion               NVARCHAR(100)   NULL,
        student_category       NVARCHAR(100)   NULL,
        admission_date         DATE            NOT NULL,
        student_status         NVARCHAR(30)    NOT NULL,
        status_effective_date  DATE            NULL,
        mobile_number          NVARCHAR(20)    NULL,
        email_address          NVARCHAR(254)   NULL,
        address_line_1         NVARCHAR(200)   NULL,
        address_line_2         NVARCHAR(200)   NULL,
        landmark               NVARCHAR(150)   NULL,
        city                   NVARCHAR(100)   NULL,
        district               NVARCHAR(100)   NULL,
        state                  NVARCHAR(100)   NULL,
        postal_code            NVARCHAR(20)    NULL,
        country                NVARCHAR(100)   NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_student_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_student_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_student_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        residency_type         NVARCHAR(20)    NOT NULL CONSTRAINT DF_student_residency_type DEFAULT (N'DAY_SCHOLAR'),
        CONSTRAINT PK_student PRIMARY KEY CLUSTERED (student_id),
        CONSTRAINT UQ_student_school_admission_number UNIQUE NONCLUSTERED (school_id, admission_number),
        CONSTRAINT UQ_student_user_id UNIQUE NONCLUSTERED (user_id),
        CONSTRAINT FK_student_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_student_academic_year_scope FOREIGN KEY (school_id, academic_year_id) REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_student_class_scope FOREIGN KEY (school_id, class_id) REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_student_section_scope FOREIGN KEY (class_id, section_id) REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_student_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_academic_scope' AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_academic_scope
        ON student_schema.student (school_id, branch_id, academic_year_id, class_id, section_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_branch_status' AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_branch_status
        ON student_schema.student (branch_id, student_status, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_name' AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_name
        ON student_schema.student (last_name, first_name)
        INCLUDE (school_id, branch_id, class_id, section_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_roll_number' AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_roll_number
        ON student_schema.student (school_id, academic_year_id, class_id, section_id, roll_number)
        WHERE roll_number IS NOT NULL;
END;
GO

/* -------------------------------------------------------------------------- */
/* student_schema.student_guardian                                              */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student_guardian', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_guardian
    (
        student_guardian_id     BIGINT          NOT NULL IDENTITY(1, 1),
        student_id              BIGINT          NOT NULL,
        guardian_name           NVARCHAR(200)   NOT NULL,
        relationship_type       NVARCHAR(50)    NOT NULL,
        mobile_number           NVARCHAR(20)    NULL,
        alternate_mobile_number NVARCHAR(20)    NULL,
        email_address           NVARCHAR(254)   NULL,
        occupation              NVARCHAR(150)   NULL,
        organization_name       NVARCHAR(200)   NULL,
        is_legal_guardian       BIT             NOT NULL CONSTRAINT DF_student_guardian_is_legal_guardian DEFAULT (0),
        is_primary_contact      BIT             NOT NULL CONSTRAINT DF_student_guardian_is_primary_contact DEFAULT (0),
        is_emergency_contact    BIT             NOT NULL CONSTRAINT DF_student_guardian_is_emergency_contact DEFAULT (0),
        is_pickup_authorized    BIT             NOT NULL CONSTRAINT DF_student_guardian_is_pickup_authorized DEFAULT (0),
        is_active               BIT             NOT NULL CONSTRAINT DF_student_guardian_is_active DEFAULT (1),
        created_at              DATETIME2(0)    NOT NULL CONSTRAINT DF_student_guardian_created_at DEFAULT (SYSUTCDATETIME()),
        created_by              BIGINT          NOT NULL,
        updated_at              DATETIME2(0)    NOT NULL CONSTRAINT DF_student_guardian_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by              BIGINT          NULL,
        row_version             ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_guardian PRIMARY KEY CLUSTERED (student_guardian_id),
        CONSTRAINT FK_student_guardian_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_guardian_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_guardian_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_guardian_student' AND object_id = OBJECT_ID(N'student_schema.student_guardian')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_guardian_student
        ON student_schema.student_guardian (student_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_guardian_relationship' AND object_id = OBJECT_ID(N'student_schema.student_guardian')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_guardian_relationship
        ON student_schema.student_guardian (student_id, relationship_type)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_student_guardian_primary_contact'
      AND object_id = OBJECT_ID(N'student_schema.student_guardian')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_student_guardian_primary_contact
        ON student_schema.student_guardian (student_id)
        WHERE is_primary_contact = 1 AND is_active = 1;
END;
GO

/* -------------------------------------------------------------------------- */
/* student_schema.exam_result                                                 */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.exam_result', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.exam_result
    (
        exam_result_id     BIGINT          NOT NULL IDENTITY(1, 1),
        exam_schedule_id   BIGINT          NOT NULL,
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        academic_year_id   BIGINT          NOT NULL,
        class_id           BIGINT          NOT NULL,
        section_id         BIGINT          NOT NULL,
        student_id         BIGINT          NOT NULL,
        marks_obtained     DECIMAL(6, 2)   NULL,
        result_status      NVARCHAR(20)    NOT NULL,
        grade              NVARCHAR(10)    NULL,
        rank_in_class      INT             NULL,
        remarks            NVARCHAR(500)   NULL,
        published_at       DATETIME2(0)    NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_exam_result_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_exam_result_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NOT NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_exam_result_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_exam_result PRIMARY KEY CLUSTERED (exam_result_id),
        CONSTRAINT UQ_exam_result_schedule_student UNIQUE NONCLUSTERED (exam_schedule_id, student_id),
        CONSTRAINT CK_exam_result_status CHECK
            (result_status IN (N'PASS', N'FAIL', N'ABSENT')),
        CONSTRAINT CK_exam_result_marks CHECK
            (marks_obtained IS NULL OR marks_obtained >= 0),
        CONSTRAINT CK_exam_result_absent_marks CHECK
            ((result_status = N'ABSENT' AND marks_obtained IS NULL)
             OR (result_status <> N'ABSENT')),
        CONSTRAINT CK_exam_result_rank CHECK
            (rank_in_class IS NULL OR rank_in_class > 0),
        CONSTRAINT FK_exam_result_exam_schedule FOREIGN KEY (exam_schedule_id) REFERENCES management_schema.exam_schedule (exam_schedule_id),
        CONSTRAINT FK_exam_result_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_exam_result_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_exam_result_academic_year_scope FOREIGN KEY (school_id, academic_year_id) REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_exam_result_class_scope FOREIGN KEY (school_id, class_id) REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_exam_result_section_scope FOREIGN KEY (class_id, section_id) REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_exam_result_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_exam_result_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_exam_result_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_result_student_scope'
      AND object_id = OBJECT_ID(N'student_schema.exam_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_result_student_scope
        ON student_schema.exam_result
        (school_id, branch_id, academic_year_id, class_id, section_id, student_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_result_schedule_status'
      AND object_id = OBJECT_ID(N'student_schema.exam_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_result_schedule_status
        ON student_schema.exam_result (exam_schedule_id, result_status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_result_student_published'
      AND object_id = OBJECT_ID(N'student_schema.exam_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_result_student_published
        ON student_schema.exam_result (student_id, published_at)
        WHERE published_at IS NOT NULL AND is_active = 1;
END;
GO

/* Scope composite unique keys (enable child composite FK enforcement across modules) */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_school_branch_student'
      AND object_id = OBJECT_ID(N'student_schema.student')
      AND (is_unique = 0 OR is_disabled = 1 OR has_filter = 1)
)
BEGIN
    DROP INDEX UQ_student_school_branch_student ON student_schema.student;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_school_branch_student'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_school_branch_student
        ON student_schema.student (school_id, branch_id, student_id);
END;
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_placement_scope'
      AND object_id = OBJECT_ID(N'student_schema.student')
      AND (is_unique = 0 OR is_disabled = 1 OR has_filter = 1)
)
BEGIN
    DROP INDEX UQ_student_placement_scope ON student_schema.student;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_placement_scope'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_placement_scope
        ON student_schema.student (school_id, branch_id, academic_year_id, class_id, section_id, student_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_id_placement_scope'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_id_placement_scope
        ON student_schema.student (student_id, school_id, branch_id, academic_year_id, class_id, section_id);
END;
GO



/* END INLINE MIGRATION: 005_student.sql */

/* BEGIN INLINE MIGRATION: 006_assessment.sql */
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

/* END INLINE MIGRATION: 006_assessment.sql */

/* BEGIN INLINE MIGRATION: 007_announcement.sql */
/* Module migration: 007_announcement.sql */
/*
    Migration: 008_announcement
    Purpose:   School/branch announcements for Student Overview (events, academic notices, general instructions)

    Design notes (THINKIGEN.docx):
    - One table only: management_schema.announcement
    - Scope: school_id + branch_id + academic_year_id (no class/section/student targeting)
    - Categories & Sub-categories mapping:
      * ACADEMIC  -> EXAMS, SYLLABUS, TIMETABLE
      * NOTICE    -> STUDENT_INSTRUCTIONS, OTHER
      * EVENT     -> SPORTS, CULTURAL, ALUMNI_EVENTS
    - Registration: optional HTTPS registration URL stored in this table only
    - Attachments: MongoDB + Blob Storage only (no SQL attachment table or blob_id)
    - No row_version on this table per approved design

    Rollback:
    - For this change only, run the rollback block at the end of this file.
    - Dropping the whole table is not a safe rollback for an existing environment.
*/
IF OBJECT_ID(N'management_schema.announcement', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.announcement
    (
        announcement_id    BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        academic_year_id   BIGINT          NOT NULL,
        announcement_type  NVARCHAR(20)    NOT NULL,
        sub_category       NVARCHAR(50)    NOT NULL CONSTRAINT DF_announcement_sub_category DEFAULT (N'STUDENT_INSTRUCTIONS'),
        title              NVARCHAR(200)   NOT NULL,
        description        NVARCHAR(MAX)   NULL,
        target_audience    NVARCHAR(100)   NOT NULL CONSTRAINT DF_announcement_target_audience DEFAULT (N'ALL'),
        registration_url   NVARCHAR(2048)  NULL,
        start_date         DATE            NULL,
        end_date           DATE            NULL,
        publish_at         DATETIME2(0)    NOT NULL,
        status             NVARCHAR(20)    NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_announcement_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_announcement_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NOT NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_announcement_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        CONSTRAINT PK_announcement PRIMARY KEY CLUSTERED (announcement_id),
        CONSTRAINT CK_announcement_type CHECK
            (announcement_type IN (N'EVENT', N'ACADEMIC', N'NOTICE')),
        CONSTRAINT CK_announcement_sub_category CHECK
            (
                (announcement_type = N'ACADEMIC' AND sub_category IN (N'EXAMS', N'SYLLABUS', N'TIMETABLE'))
                OR (announcement_type = N'NOTICE' AND sub_category IN (N'STUDENT_INSTRUCTIONS', N'OTHER'))
                OR (announcement_type = N'EVENT' AND sub_category IN (N'SPORTS', N'CULTURAL', N'ALUMNI_EVENTS'))
            ),
        CONSTRAINT CK_announcement_registration_url CHECK
            (registration_url IS NULL OR registration_url LIKE N'https://%'),
        CONSTRAINT CK_announcement_status CHECK
            (status IN (N'DRAFT', N'PUBLISHED', N'ARCHIVED')),
        CONSTRAINT CK_announcement_date_range CHECK
            (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),
        CONSTRAINT FK_announcement_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_announcement_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_announcement_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_announcement_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_announcement_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF OBJECT_ID(N'management_schema.announcement', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;
    IF COL_LENGTH(N'management_schema.announcement', N'target_audience') IS NULL
    BEGIN
        ALTER TABLE management_schema.announcement
            ADD target_audience NVARCHAR(100) NOT NULL CONSTRAINT DF_announcement_target_audience DEFAULT (N'ALL');
    END;
    IF COL_LENGTH(N'management_schema.announcement', N'sub_category') IS NULL
    BEGIN
        ALTER TABLE management_schema.announcement
            ADD sub_category NVARCHAR(50) NOT NULL CONSTRAINT DF_announcement_sub_category DEFAULT (N'STUDENT_INSTRUCTIONS');
    END;
    IF COL_LENGTH(N'management_schema.announcement', N'registration_url') IS NULL
    BEGIN
        ALTER TABLE management_schema.announcement
            ADD registration_url NVARCHAR(2048) NULL;
    END;
END;
GO

IF OBJECT_ID(N'management_schema.announcement', N'U') IS NOT NULL
BEGIN
    -- Normalize legacy announcement types if present
    UPDATE management_schema.announcement
    SET announcement_type = N'ACADEMIC'
    WHERE announcement_type = N'HOLIDAY';

    -- Normalize legacy sub categories
    UPDATE management_schema.announcement
    SET sub_category = N'CULTURAL'
    WHERE sub_category = N'CULTURAL_EVENTS';

    UPDATE management_schema.announcement
    SET sub_category = N'OTHER'
    WHERE sub_category = N'GENERAL';

    -- Ensure any invalid or mismatched combinations are aligned with valid defaults
    UPDATE management_schema.announcement
    SET sub_category = N'STUDENT_INSTRUCTIONS'
    WHERE announcement_type = N'NOTICE'
      AND sub_category NOT IN (N'STUDENT_INSTRUCTIONS', N'OTHER');

    UPDATE management_schema.announcement
    SET sub_category = N'EXAMS'
    WHERE announcement_type = N'ACADEMIC'
      AND sub_category NOT IN (N'EXAMS', N'SYLLABUS', N'TIMETABLE');

    UPDATE management_schema.announcement
    SET sub_category = N'SPORTS'
    WHERE announcement_type = N'EVENT'
      AND sub_category NOT IN (N'SPORTS', N'CULTURAL', N'ALUMNI_EVENTS');
END;
GO

IF OBJECT_ID(N'management_schema.announcement', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM management_schema.announcement
        WHERE registration_url IS NOT NULL
          AND registration_url NOT LIKE N'https://%'
    )
    BEGIN
        RAISERROR('Invalid registration_url data exists. Expected NULL or an https:// URL.', 16, 1);
        RETURN;
    END;
END;
GO

IF OBJECT_ID(N'management_schema.announcement', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_announcement_registration_url'
          AND parent_object_id = OBJECT_ID(N'management_schema.announcement')
    )
    BEGIN
        ALTER TABLE management_schema.announcement
            ADD CONSTRAINT CK_announcement_registration_url
            CHECK (registration_url IS NULL OR registration_url LIKE N'https://%');
    END;
END;
GO

IF OBJECT_ID(N'management_schema.announcement', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_announcement_type'
          AND parent_object_id = OBJECT_ID(N'management_schema.announcement')
    )
    BEGIN
        ALTER TABLE management_schema.announcement
            DROP CONSTRAINT CK_announcement_type;
    END;

    ALTER TABLE management_schema.announcement
        ADD CONSTRAINT CK_announcement_type
        CHECK (announcement_type IN (N'EVENT', N'ACADEMIC', N'NOTICE'));
END;
GO

IF OBJECT_ID(N'management_schema.announcement', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_announcement_sub_category'
          AND parent_object_id = OBJECT_ID(N'management_schema.announcement')
    )
    BEGIN
        ALTER TABLE management_schema.announcement
            DROP CONSTRAINT CK_announcement_sub_category;
    END;

    ALTER TABLE management_schema.announcement
        ADD CONSTRAINT CK_announcement_sub_category
        CHECK (
            (announcement_type = N'ACADEMIC' AND sub_category IN (N'EXAMS', N'SYLLABUS', N'TIMETABLE'))
            OR (announcement_type = N'NOTICE' AND sub_category IN (N'STUDENT_INSTRUCTIONS', N'OTHER'))
            OR (announcement_type = N'EVENT' AND sub_category IN (N'SPORTS', N'CULTURAL', N'ALUMNI_EVENTS'))
        );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_announcement_branch_status_publish'
      AND object_id = OBJECT_ID(N'management_schema.announcement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_announcement_branch_status_publish
        ON management_schema.announcement (school_id, branch_id, status, publish_at)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_announcement_branch_date'
      AND object_id = OBJECT_ID(N'management_schema.announcement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_announcement_branch_date
        ON management_schema.announcement (branch_id, start_date, end_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_announcement_type_date'
      AND object_id = OBJECT_ID(N'management_schema.announcement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_announcement_type_date
        ON management_schema.announcement (branch_id, announcement_type, start_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_announcement_academic_year'
      AND object_id = OBJECT_ID(N'management_schema.announcement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_announcement_academic_year
        ON management_schema.announcement (academic_year_id, branch_id, announcement_type)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_announcement_type_sub_category'
      AND object_id = OBJECT_ID(N'management_schema.announcement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_announcement_type_sub_category
        ON management_schema.announcement (branch_id, announcement_type, sub_category, publish_at)
        WHERE is_active = 1;
END;
GO

/* END INLINE MIGRATION: 007_announcement.sql */

/* BEGIN INLINE MIGRATION: 008_timetable.sql */
/* Module migration: 008_timetable.sql */
/*
    Migration: 009_timetable
    Purpose:   Section-wise academic timetable (master + dated period slots)

    Design notes:
    - Scope: school_id -> branch_id -> academic_year_id -> class_id -> section_id
    - One ACTIVE timetable per section scope; update periods in place after publish
    - timetable_period: one row per calendar date + period_number (no day_of_week)
    - teacher_id on each CLASS period for teacher "My Day" UI
    - room_name on period row (no room master table)
    - Audit timestamps: DATETIME2(0) UTC (SYSUTCDATETIME()); API datetime format YYYY-MM-DDTHH:mm:ss; display +05:30 in API

    Rollback:
    - DROP TABLE management_schema.timetable_period;
    - DROP TABLE management_schema.timetable;
*/

/* -------------------------------------------------------------------------- */
/* management_schema.timetable                                                */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'management_schema.timetable', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.timetable
    (
        timetable_id       BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        academic_year_id   BIGINT          NOT NULL,
        class_id           BIGINT          NOT NULL,
        section_id         BIGINT          NOT NULL,
        timetable_name     NVARCHAR(150)   NOT NULL,
        status             NVARCHAR(20)    NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_timetable_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_timetable_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NOT NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_timetable_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_timetable PRIMARY KEY CLUSTERED (timetable_id),
        CONSTRAINT CK_timetable_status CHECK
            (status IN (N'DRAFT', N'ACTIVE', N'INACTIVE')),
        CONSTRAINT FK_timetable_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_timetable_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_timetable_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_timetable_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_timetable_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_timetable_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_timetable_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_timetable_section_active'
      AND object_id = OBJECT_ID(N'management_schema.timetable')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_timetable_section_active
        ON management_schema.timetable
        (school_id, branch_id, academic_year_id, class_id, section_id)
        WHERE status = N'ACTIVE' AND is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_timetable_section_status'
      AND object_id = OBJECT_ID(N'management_schema.timetable')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_timetable_section_status
        ON management_schema.timetable
        (school_id, branch_id, academic_year_id, class_id, section_id, status, is_active);
END;
GO

/* -------------------------------------------------------------------------- */
/* management_schema.timetable_period                                         */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'management_schema.timetable_period', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.timetable_period
    (
        timetable_period_id BIGINT          NOT NULL IDENTITY(1, 1),
        timetable_id        BIGINT          NOT NULL,
        period_date         DATE            NOT NULL,
        period_number       TINYINT         NOT NULL,
        period_name         NVARCHAR(50)    NULL,
        start_time          TIME(0)         NOT NULL,
        end_time            TIME(0)         NOT NULL,
        period_type         NVARCHAR(30)    NOT NULL,
        subject_id          BIGINT          NULL,
        subject_topic       NVARCHAR(200)   NULL,
        teacher_id          BIGINT          NULL,
        room_name           NVARCHAR(150)   NULL,
        activity_name       NVARCHAR(150)   NULL,
        is_active           BIT             NOT NULL CONSTRAINT DF_timetable_period_is_active DEFAULT (1),
        created_at          DATETIME2(0)    NOT NULL CONSTRAINT DF_timetable_period_created_at DEFAULT (SYSUTCDATETIME()),
        created_by          BIGINT          NOT NULL,
        updated_at          DATETIME2(0)    NOT NULL CONSTRAINT DF_timetable_period_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by          BIGINT          NULL,
        row_version         ROWVERSION      NOT NULL,
        CONSTRAINT PK_timetable_period PRIMARY KEY CLUSTERED (timetable_period_id),
        CONSTRAINT UQ_timetable_period_slot UNIQUE NONCLUSTERED
            (timetable_id, period_date, period_number),
        CONSTRAINT CK_timetable_period_number CHECK (period_number > 0),
        CONSTRAINT CK_timetable_period_time CHECK (end_time > start_time),
        CONSTRAINT CK_timetable_period_type CHECK
            (period_type IN (N'CLASS', N'BREAK', N'LUNCH', N'ACTIVITY', N'FREE')),
        CONSTRAINT CK_timetable_period_class CHECK
            (period_type <> N'CLASS'
             OR (subject_id IS NOT NULL AND teacher_id IS NOT NULL)),
        CONSTRAINT FK_timetable_period_timetable FOREIGN KEY (timetable_id) REFERENCES management_schema.timetable (timetable_id),
        CONSTRAINT FK_timetable_period_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_timetable_period_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_timetable_period_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_timetable_period_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_timetable_period_my_day'
      AND object_id = OBJECT_ID(N'management_schema.timetable_period')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_timetable_period_my_day
        ON management_schema.timetable_period (timetable_id, period_date, period_number)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_timetable_period_teacher_day'
      AND object_id = OBJECT_ID(N'management_schema.timetable_period')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_timetable_period_teacher_day
        ON management_schema.timetable_period (teacher_id, period_date, start_time)
        INCLUDE (timetable_id, subject_id, period_number, room_name)
        WHERE is_active = 1 AND teacher_id IS NOT NULL;
END;
GO

/*
    Migration: 010_timetable_period_subject_topic
    Purpose:   Add lesson topic on CLASS timetable periods (subject name via subject_id JOIN)

    Design notes:
    - subject_name comes from management_schema.subject via subject_id
    - subject_topic stores the planned lesson/chapter topic for that period slot

    Rollback:
    - ALTER TABLE management_schema.timetable_period DROP COLUMN subject_topic;
*/

IF COL_LENGTH(N'management_schema.timetable_period', N'subject_topic') IS NULL
BEGIN
    ALTER TABLE management_schema.timetable_period
        ADD subject_topic NVARCHAR(200) NULL;
END;
GO


/* END INLINE MIGRATION: 008_timetable.sql */

/* BEGIN INLINE MIGRATION: 009_homework.sql */
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

/* END INLINE MIGRATION: 009_homework.sql */

/* BEGIN INLINE MIGRATION: 010_attendance.sql */
/* Module migration: 010_attendance.sql */
/*
    Migration: 013_student_attendance
    Purpose:   Period-wise student attendance linked to timetable

    Design notes:
    - One row per student + timetable_period + attendance_date
    - attendance_status: PRESENT / ABSENT only
    - Scope columns (school -> section) on each row for ABAC and reporting
    - subject_id, teacher_id, period_number, start_time, end_time snapshot from period at record time
    - recorded_at / recorded_by = when and who marked attendance (distinct from created_* audit)
    - No separate attendance-session table (THINKIGEN doc)
    - Application: create rows only for CLASS timetable periods unless business approves otherwise

    Rollback:
    - DROP TABLE student_schema.student_attendance;
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student_attendance                                            */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student_attendance', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_attendance
    (
        student_attendance_id BIGINT          NOT NULL IDENTITY(1, 1),
        school_id             BIGINT          NOT NULL,
        branch_id             BIGINT          NOT NULL,
        academic_year_id      BIGINT          NOT NULL,
        class_id              BIGINT          NOT NULL,
        section_id            BIGINT          NOT NULL,
        student_id            BIGINT          NOT NULL,
        timetable_id          BIGINT          NOT NULL,
        timetable_period_id   BIGINT          NOT NULL,
        attendance_date       DATE            NOT NULL,
        subject_id            BIGINT          NOT NULL,
        teacher_id            BIGINT          NOT NULL,
        period_number         TINYINT         NOT NULL,
        start_time            TIME(0)         NOT NULL,
        end_time              TIME(0)         NOT NULL,
        attendance_status     NVARCHAR(10)    NOT NULL,
        recorded_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_student_attendance_recorded_at DEFAULT (SYSUTCDATETIME()),
        recorded_by           BIGINT          NOT NULL,
        is_active             BIT             NOT NULL CONSTRAINT DF_student_attendance_is_active DEFAULT (1),
        created_at            DATETIME2(0)    NOT NULL CONSTRAINT DF_student_attendance_created_at DEFAULT (SYSUTCDATETIME()),
        created_by            BIGINT          NOT NULL,
        updated_at            DATETIME2(0)    NOT NULL CONSTRAINT DF_student_attendance_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by            BIGINT          NULL,
        row_version           ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_attendance PRIMARY KEY CLUSTERED (student_attendance_id),
        CONSTRAINT UQ_student_attendance_student_period_date UNIQUE NONCLUSTERED
            (student_id, timetable_period_id, attendance_date),
        CONSTRAINT CK_student_attendance_status CHECK
            (attendance_status IN (N'PRESENT', N'ABSENT')),
        CONSTRAINT CK_student_attendance_period_number CHECK (period_number > 0),
        CONSTRAINT CK_student_attendance_time CHECK (end_time > start_time),
        CONSTRAINT FK_student_attendance_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_attendance_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_attendance_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_attendance_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_attendance_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_attendance_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_attendance_timetable FOREIGN KEY (timetable_id) REFERENCES management_schema.timetable (timetable_id),
        CONSTRAINT FK_student_attendance_timetable_period FOREIGN KEY (timetable_period_id) REFERENCES management_schema.timetable_period (timetable_period_id),
        CONSTRAINT FK_student_attendance_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_student_attendance_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_student_attendance_recorded_by FOREIGN KEY (recorded_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_attendance_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_attendance_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_student_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_student_date
        ON student_schema.student_attendance (student_id, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_student_year_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_student_year_date
        ON student_schema.student_attendance (student_id, academic_year_id, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_section_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_section_date
        ON student_schema.student_attendance
        (school_id, branch_id, class_id, section_id, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_section_period_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_section_period_date
        ON student_schema.student_attendance (section_id, attendance_date, period_number)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_teacher_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_teacher_date
        ON student_schema.student_attendance (teacher_id, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_status_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_status_date
        ON student_schema.student_attendance (attendance_status, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_timetable_period_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_timetable_period_date
        ON student_schema.student_attendance (timetable_period_id, attendance_date)
        INCLUDE (student_id, attendance_status, section_id)
        WHERE is_active = 1;
END;
GO


/* END INLINE MIGRATION: 010_attendance.sql */

/* BEGIN INLINE MIGRATION: 011_leave.sql */
/* Module migration: 011_leave.sql */
/*
    Migration: 014_student_leave
    Purpose:   Student leave applications (students only Ã¢â‚¬â€ not teacher/staff leave)

    Design notes:
    - student_schema.student_leave = apply + approval workflow
    - No applied_by; applied_at + created_by audit capture submission timing/actor
    - leave_type: CASUAL, SICK, EDUCATIONAL, PERSONAL, HEALTH
    - duration_type: HALF_DAY, FULL_DAY, MULTIPLE_DAYS
    - status: PENDING, APPROVED, REJECTED, CANCELLED
    - Business: leave must be applied before the leave day (prior permission); no prior
      approved leave = unauthorized absence (ABSENT in attendance; no excuse/punishment in app)
    - FIRST_HALF = before lunch; SECOND_HALF = after lunch (no period numbers)
    - Overlapping APPROVED leaves: prevented in FastAPI before approval (see entity doc)
    - CANCELLED from APPROVED: rare; only status changes to CANCELLED; reviewed_* retained
    - Supporting documents (medical certificate, etc.): MongoDB + Blob Storage, not SQL

    Rollback:
    - DROP TABLE student_schema.student_leave;
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student_leave                                               */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_leave
    (
        student_leave_id     BIGINT          NOT NULL IDENTITY(1, 1),
        school_id            BIGINT          NOT NULL,
        branch_id            BIGINT          NOT NULL,
        academic_year_id     BIGINT          NOT NULL,
        class_id             BIGINT          NOT NULL,
        section_id           BIGINT          NOT NULL,
        student_id           BIGINT          NOT NULL,
        leave_type           NVARCHAR(30)    NOT NULL,
        duration_type        NVARCHAR(20)    NOT NULL,
        half_day_session     NVARCHAR(20)    NULL,
        start_date           DATE            NOT NULL,
        end_date             DATE            NOT NULL,
        reason               NVARCHAR(500)   NOT NULL,
        status               NVARCHAR(20)    NOT NULL,
        applied_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_student_leave_applied_at DEFAULT (SYSUTCDATETIME()),
        reviewed_at          DATETIME2(0)    NULL,
        reviewed_by          BIGINT          NULL,
        review_remarks       NVARCHAR(500)   NULL,
        is_active            BIT             NOT NULL CONSTRAINT DF_student_leave_is_active DEFAULT (1),
        created_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_student_leave_created_at DEFAULT (SYSUTCDATETIME()),
        created_by           BIGINT          NOT NULL,
        updated_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_student_leave_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by           BIGINT          NULL,
        row_version          ROWVERSION      NOT NULL,
        cancelled_at         DATETIME2(0)    NULL,
        cancelled_by         BIGINT          NULL,
        cancellation_remarks NVARCHAR(500)   NULL,
        duration             DECIMAL(4, 2)   NOT NULL CONSTRAINT DF_student_leave_duration DEFAULT ((1.00)),
        CONSTRAINT PK_student_leave PRIMARY KEY CLUSTERED (student_leave_id),
        CONSTRAINT CK_student_leave_type CHECK
            (leave_type IN (N'CASUAL', N'SICK', N'EDUCATIONAL', N'PERSONAL', N'HEALTH')),
        CONSTRAINT CK_student_leave_duration_type CHECK
            (duration_type IN (N'HALF_DAY', N'FULL_DAY', N'MULTIPLE_DAYS')),
        CONSTRAINT CK_student_leave_half_day_session CHECK
            ((duration_type = N'HALF_DAY'
              AND half_day_session IN (N'FIRST_HALF', N'SECOND_HALF'))
             OR (duration_type <> N'HALF_DAY' AND half_day_session IS NULL)),
        CONSTRAINT CK_student_leave_status CHECK
            (status IN (N'PENDING', N'APPROVED', N'REJECTED', N'CANCELLED')),
        CONSTRAINT CK_student_leave_date_range CHECK (end_date >= start_date),
        CONSTRAINT CK_student_leave_half_day CHECK
            (duration_type <> N'HALF_DAY'
             OR (start_date = end_date AND half_day_session IS NOT NULL)),
        CONSTRAINT CK_student_leave_full_day CHECK
            (duration_type <> N'FULL_DAY'
             OR (start_date = end_date AND half_day_session IS NULL)),
        CONSTRAINT CK_student_leave_multiple_days CHECK
            (duration_type <> N'MULTIPLE_DAYS' OR end_date > start_date),
        CONSTRAINT CK_student_leave_apply_before_leave_day CHECK
            (start_date > CAST(applied_at AS DATE)),
        CONSTRAINT CK_student_leave_reviewed CHECK
            ((status IN (N'APPROVED', N'REJECTED') AND reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL)
             OR (status IN (N'PENDING', N'CANCELLED'))),
        CONSTRAINT FK_student_leave_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_leave_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_leave_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_leave_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_leave_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_leave_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_leave_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_leave_cancelled_by FOREIGN KEY (cancelled_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_leave_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_leave_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

/* Scope composite foreign keys (enforce cross-entity branch/placement integrity) */
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_student_leave_academic_year_scope'
      AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT FK_student_leave_academic_year_scope
            FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_student_leave_branch_scope'
      AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT FK_student_leave_branch_scope
            FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_student_leave_class_scope'
      AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT FK_student_leave_class_scope
            FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_student_leave_section_scope'
      AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT FK_student_leave_section_scope
            FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_id_placement_scope'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_id_placement_scope
        ON student_schema.student (student_id, school_id, branch_id, academic_year_id, class_id, section_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_student_leave_student_scope'
      AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT FK_student_leave_student_scope
            FOREIGN KEY (student_id, school_id, branch_id, academic_year_id, class_id, section_id)
            REFERENCES student_schema.student (student_id, school_id, branch_id, academic_year_id, class_id, section_id);
END;
GO

/* -------------------------------------------------------------------------- */
/* Upgrade duration constraints for existing student_leave tables             */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND EXISTS (
       SELECT 1 FROM sys.check_constraints
       WHERE name = N'CK_student_leave_half_day_session'
         AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
   )
BEGIN
    ALTER TABLE student_schema.student_leave
        DROP CONSTRAINT CK_student_leave_half_day_session;
END;
GO

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.check_constraints
       WHERE name = N'CK_student_leave_half_day_session'
         AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
   )
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT CK_student_leave_half_day_session CHECK
            ((duration_type = N'HALF_DAY'
              AND half_day_session IN (N'FIRST_HALF', N'SECOND_HALF'))
             OR (duration_type <> N'HALF_DAY' AND half_day_session IS NULL));
END;
GO

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.check_constraints
       WHERE name = N'CK_student_leave_multiple_days'
         AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
   )
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT CK_student_leave_multiple_days CHECK
            (duration_type <> N'MULTIPLE_DAYS' OR end_date > start_date);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_leave_student_dates'
      AND object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_leave_student_dates
        ON student_schema.student_leave (student_id, start_date, end_date, status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_leave_section_status'
      AND object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_leave_section_status
        ON student_schema.student_leave
        (school_id, branch_id, class_id, section_id, status, start_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_leave_approved_student_dates'
      AND object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_leave_approved_student_dates
        ON student_schema.student_leave (student_id, start_date, end_date)
        INCLUDE (status, duration_type, half_day_session)
        WHERE is_active = 1 AND status = N'APPROVED';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_leave_pending'
      AND object_id = OBJECT_ID(N'student_schema.student_leave')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_leave_pending
        ON student_schema.student_leave (section_id, status, start_date)
        WHERE is_active = 1 AND status = N'PENDING';
END;
GO

/*
    Migration: 016_student_leave_business_rules
    Purpose:   Add advance-application constraint and overlap lookup index when 014
               was applied before business rules were added

    Rollback:
    - DROP INDEX IX_student_leave_approved_student_dates ON student_schema.student_leave;
    - ALTER TABLE student_schema.student_leave DROP CONSTRAINT CK_student_leave_apply_before_leave_day;
*/

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.check_constraints
       WHERE name = N'CK_student_leave_apply_before_leave_day'
         AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
   )
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT CK_student_leave_apply_before_leave_day CHECK
            (start_date > CAST(applied_at AS DATE));
END;
GO

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'IX_student_leave_approved_student_dates'
         AND object_id = OBJECT_ID(N'student_schema.student_leave')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_leave_approved_student_dates
        ON student_schema.student_leave (student_id, start_date, end_date)
        INCLUDE (status, duration_type, half_day_session)
        WHERE is_active = 1 AND status = N'APPROVED';
END;
GO


/* END INLINE MIGRATION: 011_leave.sql */

/* BEGIN INLINE MIGRATION: 012_holidays.sql */
/* Module migration: 012_holidays.sql */
/*
    Migration: 015_holiday
    Purpose:   School/branch holiday calendar master (academic calendar)

    Design notes:
    - management_schema.holiday = official non-working days per school + branch + academic year
    - Distinct from management_schema.announcement (type HOLIDAY) which is student-facing notices
    - holiday_type: NATIONAL, RELIGIOUS, FESTIVAL, VACATION, OPTIONAL, OTHER
    - App uses this to skip timetable period generation and attendance on holiday dates

    Rollback:
    - DROP TABLE management_schema.holiday;
*/

/* -------------------------------------------------------------------------- */
/* management_schema.holiday                                                  */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'management_schema.holiday', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.holiday
    (
        holiday_id         BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        academic_year_id   BIGINT          NOT NULL,
        holiday_type       NVARCHAR(30)    NOT NULL,
        holiday_name       NVARCHAR(150)   NOT NULL,
        description        NVARCHAR(MAX)   NULL,
        start_date         DATE            NOT NULL,
        end_date           DATE            NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_holiday_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_holiday_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NOT NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_holiday_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_holiday PRIMARY KEY CLUSTERED (holiday_id),
        CONSTRAINT CK_holiday_type CHECK
            (holiday_type IN (
                N'NATIONAL', N'RELIGIOUS', N'FESTIVAL', N'VACATION', N'OPTIONAL', N'OTHER')),
        CONSTRAINT CK_holiday_date_range CHECK (end_date >= start_date),
        CONSTRAINT FK_holiday_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_holiday_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_holiday_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_holiday_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_holiday_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_holiday_branch_year_dates'
      AND object_id = OBJECT_ID(N'management_schema.holiday')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_holiday_branch_year_dates
        ON management_schema.holiday
        (school_id, branch_id, academic_year_id, start_date, end_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_holiday_branch_type_date'
      AND object_id = OBJECT_ID(N'management_schema.holiday')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_holiday_branch_type_date
        ON management_schema.holiday (branch_id, holiday_type, start_date)
        WHERE is_active = 1;
END;
GO


/* END INLINE MIGRATION: 012_holidays.sql */

/* BEGIN INLINE MIGRATION: 013_grievance.sql */
/* Module migration: 013_grievance.sql */
/*
    ============================================================================
    THINKIGEN STUDENT GRIEVANCE MODULE â€” TWO-TABLE ARCHITECTURE
    ============================================================================

    Migration: 013_grievance
    Purpose:   Student grievance (complaint) and lifecycle tracking

    Tables:
      1. student_schema.grievance          â€” stores grievance details & CURRENT state
      2. student_schema.grievance_history  â€” 1:1 lifecycle tracking (one row per grievance)

    Business Workflow:
      SUBMITTED â†’ UNDER_REVIEW â†’ RESOLVED

    Rollback:
      See rollback/013_grievance_rollback.sql
    ============================================================================
*/

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* -------------------------------------------------------------------------- */
/* 0. SUPERSEDED OBJECT CLEANUP                                               */
/* -------------------------------------------------------------------------- */

/* Remove superseded single-table grievance if legacy columns exist */
IF COL_LENGTH(N'student_schema.grievance', N'assigned_at') IS NOT NULL
   OR COL_LENGTH(N'student_schema.grievance', N'assigned_by') IS NOT NULL
   OR COL_LENGTH(N'student_schema.grievance', N'investigation_started_at') IS NOT NULL
   OR COL_LENGTH(N'student_schema.grievance', N'review_started_at') IS NOT NULL
   OR COL_LENGTH(N'student_schema.grievance', N'rejection_reason') IS NOT NULL
BEGIN
    IF OBJECT_ID(N'student_schema.grievance_history', N'U') IS NOT NULL
        DROP TABLE student_schema.grievance_history;
    IF OBJECT_ID(N'student_schema.grievance', N'U') IS NOT NULL
        DROP TABLE student_schema.grievance;
END;
GO

/* Remove legacy check constraints if present on pre-existing table */
DECLARE @drop_legacy_ck NVARCHAR(MAX) = N'';
SELECT @drop_legacy_ck += N'ALTER TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' DROP CONSTRAINT ' + QUOTENAME(c.name) + N'; '
FROM sys.check_constraints c
JOIN sys.tables t ON c.parent_object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = N'student_schema' AND t.name = N'grievance'
  AND c.name IN (N'CK_grievance_assigned', N'CK_grievance_investigation', N'CK_grievance_review',
                 N'CK_grievance_resolved', N'CK_grievance_rejected', N'CK_grievance_cancelled');
IF LEN(@drop_legacy_ck) > 0
    EXEC sys.sp_executesql @drop_legacy_ck;

IF OBJECT_ID(N'student_schema.CK_grievance_assigned', N'C') IS NOT NULL
    ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_assigned;
IF OBJECT_ID(N'student_schema.CK_grievance_investigation', N'C') IS NOT NULL
    ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_investigation;
IF OBJECT_ID(N'student_schema.CK_grievance_review', N'C') IS NOT NULL
    ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_review;
IF OBJECT_ID(N'student_schema.CK_grievance_resolved', N'C') IS NOT NULL
    ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_resolved;
IF OBJECT_ID(N'student_schema.CK_grievance_rejected', N'C') IS NOT NULL
    ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_rejected;
IF OBJECT_ID(N'student_schema.CK_grievance_cancelled', N'C') IS NOT NULL
    ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_cancelled;
GO

/* -------------------------------------------------------------------------- */
/* 1. student_schema.grievance                                                */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.grievance', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.grievance
    (
        grievance_id               BIGINT          NOT NULL IDENTITY(1, 1),
        grievance_number           NVARCHAR(30)    NOT NULL,
        school_id                  BIGINT          NOT NULL,
        branch_id                  BIGINT          NOT NULL,
        academic_year_id           BIGINT          NOT NULL,
        class_id                   BIGINT          NOT NULL,
        section_id                 BIGINT          NOT NULL,
        student_id                 BIGINT          NOT NULL,
        department_id              BIGINT          NOT NULL,
        title                      NVARCHAR(200)   NOT NULL,
        category                   NVARCHAR(50)    NOT NULL,
        priority_level             NVARCHAR(20)    NOT NULL,
        incident_date              DATE            NOT NULL,
        location                   NVARCHAR(200)   NOT NULL,
        description                NVARCHAR(MAX)   NOT NULL,
        status                     NVARCHAR(30)    NOT NULL,
        submitted_at               DATETIME2(0)    NOT NULL CONSTRAINT DF_grievance_submitted_at DEFAULT (SYSUTCDATETIME()),
        assigned_to                BIGINT          NULL,
        is_active                  BIT             NOT NULL CONSTRAINT DF_grievance_is_active DEFAULT (1),
        created_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_grievance_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                 BIGINT          NOT NULL,
        updated_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_grievance_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                 BIGINT          NULL,
        row_version                ROWVERSION      NOT NULL,
        CONSTRAINT PK_grievance PRIMARY KEY CLUSTERED (grievance_id),
        CONSTRAINT UQ_grievance_number UNIQUE NONCLUSTERED (grievance_number),
        CONSTRAINT CK_grievance_category CHECK
            (category IN (
                N'ACADEMIC', N'TRANSPORT', N'HOSTEL', N'BULLYING', N'FACILITIES',
                N'FEE', N'STAFF_BEHAVIOR', N'OTHER')),
        CONSTRAINT CK_grievance_priority CHECK
            (priority_level IN (N'LOW', N'MEDIUM', N'HIGH')),
        CONSTRAINT CK_grievance_status CHECK
            (status IN (N'SUBMITTED', N'UNDER_REVIEW', N'RESOLVED')),
        CONSTRAINT CK_grievance_assigned_to_required CHECK
            (status = N'SUBMITTED' OR assigned_to IS NOT NULL),
        CONSTRAINT FK_grievance_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_grievance_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_grievance_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_grievance_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_grievance_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_grievance_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_grievance_assigned_to FOREIGN KEY (assigned_to) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_grievance_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_grievance_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

-- Ensure department_id exists if student_schema.grievance already existed
IF COL_LENGTH(N'student_schema.grievance', N'department_id') IS NULL
BEGIN
    ALTER TABLE student_schema.grievance ADD department_id BIGINT NOT NULL CONSTRAINT DF_grievance_department_id DEFAULT (1);
END;
GO

-- Ensure grievance_number is NVARCHAR(30) if student_schema.grievance already existed
IF EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID(N'student_schema.grievance')
      AND c.name = N'grievance_number'
      AND (t.name <> N'nvarchar' OR c.max_length < 60)
)
BEGIN
    ALTER TABLE student_schema.grievance ALTER COLUMN grievance_number NVARCHAR(30) NOT NULL;
END;
GO

/* -------------------------------------------------------------------------- */
/* 2. student_schema.grievance_history                                        */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.grievance_history', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.grievance_history
    (
        grievance_history_id       BIGINT          NOT NULL IDENTITY(1, 1),
        grievance_id               BIGINT          NOT NULL,
        submitted_by               BIGINT          NOT NULL,
        submitted_at               DATETIME2(0)    NOT NULL,
        assigned_to                BIGINT          NULL,
        reviewed_at                DATETIME2(0)    NULL,
        resolved_at                DATETIME2(0)    NULL,
        updated_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_grievance_history_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                 BIGINT          NULL,
        row_version                ROWVERSION      NOT NULL,
        CONSTRAINT PK_grievance_history PRIMARY KEY CLUSTERED (grievance_history_id),
        CONSTRAINT UQ_grievance_history_grievance_id UNIQUE NONCLUSTERED (grievance_id),
        CONSTRAINT CK_grievance_history_resolved_requires_reviewed CHECK
            (resolved_at IS NULL OR reviewed_at IS NOT NULL),
        CONSTRAINT CK_grievance_history_reviewed_requires_assigned CHECK
            (reviewed_at IS NULL OR assigned_to IS NOT NULL),
        CONSTRAINT FK_grievance_history_grievance FOREIGN KEY (grievance_id) REFERENCES student_schema.grievance (grievance_id),
        CONSTRAINT FK_grievance_history_submitted_by FOREIGN KEY (submitted_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_grievance_history_assigned_to FOREIGN KEY (assigned_to) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_grievance_history_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* 3. Indexes                                                                 */
/* -------------------------------------------------------------------------- */

-- Student's grievance list
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_grievance_student_status'
      AND object_id = OBJECT_ID(N'student_schema.grievance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_grievance_student_status
        ON student_schema.grievance (student_id, status, submitted_at)
        WHERE is_active = 1;
END;
GO

-- Management / department grievance queue
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_grievance_department_status'
      AND object_id = OBJECT_ID(N'student_schema.grievance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_grievance_department_status
        ON student_schema.grievance (school_id, branch_id, department_id, status, submitted_at)
        WHERE is_active = 1;
END;
GO

-- Assigned Department Head queue
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_grievance_assigned_to_status'
      AND object_id = OBJECT_ID(N'student_schema.grievance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_grievance_assigned_to_status
        ON student_schema.grievance (assigned_to, status, updated_at)
        WHERE is_active = 1 AND assigned_to IS NOT NULL;
END;
GO

-- Submitted grievance queue
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_grievance_submitted'
      AND object_id = OBJECT_ID(N'student_schema.grievance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_grievance_submitted
        ON student_schema.grievance (status, submitted_at)
        INCLUDE (branch_id, department_id, class_id, section_id, priority_level, category)
        WHERE is_active = 1 AND status = N'SUBMITTED';
END;
GO

-- Assigned user history queue
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_grievance_history_assigned_to'
      AND object_id = OBJECT_ID(N'student_schema.grievance_history')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_grievance_history_assigned_to
        ON student_schema.grievance_history (assigned_to, reviewed_at, resolved_at)
        WHERE assigned_to IS NOT NULL;
END;
GO

-- Submitter history lookup
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_grievance_history_submitted_by'
      AND object_id = OBJECT_ID(N'student_schema.grievance_history')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_grievance_history_submitted_by
        ON student_schema.grievance_history (submitted_by, submitted_at);
END;
GO

/* -------------------------------------------------------------------------- */
/* 4. Migration Tracking                                                      */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM security_schema.schema_version WHERE migration_name = N'013_grievance')
    BEGIN
        INSERT INTO security_schema.schema_version (migration_name, applied_at)
        VALUES (N'013_grievance', SYSUTCDATETIME());
    END;
END;
GO


/* END INLINE MIGRATION: 013_grievance.sql */

/* BEGIN INLINE MIGRATION: 014_library.sql */
/* Module migration: 014_library.sql */
/*
    ============================================================================
    THINKIGEN LIBRARY MODULE â€” FRESH 3-TABLE PRODUCTION SCHEMA
    ============================================================================

    Migration: 014_library
    Purpose:   Drops legacy library tables and recreates the final, clean 3-table
               production architecture with columns, constraints, and indexes.

    Tables:
      1. library_schema.library_book
      2. library_schema.library_book_copy
      3. library_schema.library_book_borrow

    Rollback:
      See rollback/014_library_rollback.sql
    ============================================================================
*/

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* -------------------------------------------------------------------------- */
/* 0. CLEANUP: DROP EXISTING TABLES IN REVERSE DEPENDENCY ORDER               */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'library_schema.library_book_borrow', N'U') IS NOT NULL
    DROP TABLE library_schema.library_book_borrow;
GO

IF OBJECT_ID(N'library_schema.library_book_copy', N'U') IS NOT NULL
    DROP TABLE library_schema.library_book_copy;
GO

IF OBJECT_ID(N'library_schema.library_book', N'U') IS NOT NULL
    DROP TABLE library_schema.library_book;
GO

/* -------------------------------------------------------------------------- */
/* 1. SCHEMA & PREREQUISITE COMPOSITE CANDIDATE KEYS                          */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'library_schema')
    EXEC(N'CREATE SCHEMA library_schema AUTHORIZATION dbo;');
GO

-- Ensure student candidate key exists for child composite FK reference
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_school_branch_student'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_school_branch_student
        ON student_schema.student (school_id, branch_id, student_id);
END;
GO

-- Ensure school_class candidate key exists for child composite FK reference
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_school_class_school_scope'
      AND object_id = OBJECT_ID(N'management_schema.school_class')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_school_class_school_scope
        ON management_schema.school_class (school_id, class_id);
END;
GO

-- Ensure section candidate key exists for child composite FK reference
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_section_class_scope'
      AND object_id = OBJECT_ID(N'management_schema.section')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_section_class_scope
        ON management_schema.section (class_id, section_id);
END;
GO

/* -------------------------------------------------------------------------- */
/* 2. TABLE: library_schema.library_book (Catalog Master)                     */
/* -------------------------------------------------------------------------- */

CREATE TABLE library_schema.library_book
(
    book_id                BIGINT          NOT NULL IDENTITY(1, 1),
    school_id              BIGINT          NOT NULL,
    branch_id              BIGINT          NOT NULL,
    title                  NVARCHAR(300)   NOT NULL,
    author                 NVARCHAR(200)   NOT NULL,
    subject                NVARCHAR(100)   NOT NULL,
    category               NVARCHAR(100)   NOT NULL,
    language               NVARCHAR(50)    NOT NULL,
    edition                NVARCHAR(50)    NULL,
    description            NVARCHAR(MAX)   NULL,
    total_copies           INT             NOT NULL CONSTRAINT DF_library_book_total_copies DEFAULT (0),
    available_copies       INT             NOT NULL CONSTRAINT DF_library_book_available_copies DEFAULT (0),
    is_active              BIT             NOT NULL CONSTRAINT DF_library_book_is_active DEFAULT (1),
    created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_created_at DEFAULT (SYSUTCDATETIME()),
    created_by             BIGINT          NOT NULL,
    updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_updated_at DEFAULT (SYSUTCDATETIME()),
    updated_by             BIGINT          NULL,
    row_version            ROWVERSION      NOT NULL,

    -- Primary & Scope Candidate Keys
    CONSTRAINT PK_library_book PRIMARY KEY CLUSTERED (book_id),
    CONSTRAINT UQ_library_book_scope UNIQUE NONCLUSTERED (school_id, branch_id, book_id),

    -- Validation Constraints
    CONSTRAINT CK_library_book_title CHECK (LEN(LTRIM(RTRIM(title))) > 0),
    CONSTRAINT CK_library_book_author CHECK (LEN(LTRIM(RTRIM(author))) > 0),
    CONSTRAINT CK_library_book_subject CHECK (LEN(LTRIM(RTRIM(subject))) > 0),
    CONSTRAINT CK_library_book_category CHECK (LEN(LTRIM(RTRIM(category))) > 0),
    CONSTRAINT CK_library_book_language CHECK (LEN(LTRIM(RTRIM(language))) > 0),
    CONSTRAINT CK_library_book_total_copies CHECK (total_copies >= 0),
    CONSTRAINT CK_library_book_available_copies CHECK (available_copies >= 0),
    CONSTRAINT CK_library_book_available_lte_total CHECK (available_copies <= total_copies),

    -- Foreign Keys
    CONSTRAINT FK_library_book_school FOREIGN KEY (school_id)
        REFERENCES management_schema.school (school_id),
    CONSTRAINT FK_library_book_branch FOREIGN KEY (school_id, branch_id)
        REFERENCES management_schema.branch (school_id, branch_id),
    CONSTRAINT FK_library_book_created_by FOREIGN KEY (created_by)
        REFERENCES security_schema.users (user_id),
    CONSTRAINT FK_library_book_updated_by FOREIGN KEY (updated_by)
        REFERENCES security_schema.users (user_id)
);
GO

-- Catalog search & browse index
CREATE NONCLUSTERED INDEX IX_library_book_branch_search
    ON library_schema.library_book (school_id, branch_id, subject, category, language, is_active)
    INCLUDE (title, author, total_copies, available_copies);
GO

/* -------------------------------------------------------------------------- */
/* 3. TABLE: library_schema.library_book_copy (Physical Inventory)            */
/* -------------------------------------------------------------------------- */

CREATE TABLE library_schema.library_book_copy
(
    book_copy_id           BIGINT          NOT NULL IDENTITY(1, 1),
    book_id                BIGINT          NOT NULL,
    school_id              BIGINT          NOT NULL,
    branch_id              BIGINT          NOT NULL,
    copy_number            INT             NOT NULL,
    barcode                NVARCHAR(50)    NULL,
    copy_status            NVARCHAR(20)    NOT NULL,
    is_active              BIT             NOT NULL CONSTRAINT DF_library_book_copy_is_active DEFAULT (1),
    created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_copy_created_at DEFAULT (SYSUTCDATETIME()),
    created_by             BIGINT          NOT NULL,
    updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_copy_updated_at DEFAULT (SYSUTCDATETIME()),
    updated_by             BIGINT          NULL,
    row_version            ROWVERSION      NOT NULL,

    -- Primary & Candidate Keys
    CONSTRAINT PK_library_book_copy PRIMARY KEY CLUSTERED (book_copy_id),
    CONSTRAINT UQ_library_book_copy_number UNIQUE NONCLUSTERED (school_id, branch_id, book_id, copy_number),
    CONSTRAINT UQ_library_book_copy_scope UNIQUE NONCLUSTERED (school_id, branch_id, book_id, book_copy_id),

    -- Validation Constraints
    CONSTRAINT CK_library_book_copy_number CHECK (copy_number > 0),
    CONSTRAINT CK_library_book_copy_status CHECK
        (copy_status IN (N'AVAILABLE', N'BORROWED', N'OVERDUE', N'LOST', N'DAMAGED', N'MAINTENANCE', N'RETIRED')),
    CONSTRAINT CK_library_book_copy_active_status CHECK
        ((copy_status NOT IN (N'AVAILABLE', N'BORROWED', N'OVERDUE')) OR (is_active = 1)),

    -- Foreign Keys
    CONSTRAINT FK_library_book_copy_book_scope FOREIGN KEY (school_id, branch_id, book_id)
        REFERENCES library_schema.library_book (school_id, branch_id, book_id),
    CONSTRAINT FK_library_book_copy_school FOREIGN KEY (school_id)
        REFERENCES management_schema.school (school_id),
    CONSTRAINT FK_library_book_copy_branch FOREIGN KEY (school_id, branch_id)
        REFERENCES management_schema.branch (school_id, branch_id),
    CONSTRAINT FK_library_book_copy_created_by FOREIGN KEY (created_by)
        REFERENCES security_schema.users (user_id),
    CONSTRAINT FK_library_book_copy_updated_by FOREIGN KEY (updated_by)
        REFERENCES security_schema.users (user_id)
);
GO

-- Barcode uniqueness for active copies within branch
CREATE UNIQUE NONCLUSTERED INDEX UQ_library_book_copy_branch_barcode
    ON library_schema.library_book_copy (school_id, branch_id, barcode)
    WHERE barcode IS NOT NULL AND is_active = 1;
GO

-- Copy status lookup per book
CREATE NONCLUSTERED INDEX IX_library_book_copy_book_status
    ON library_schema.library_book_copy (book_id, copy_status)
    WHERE is_active = 1;
GO

-- Branch-level inventory index
CREATE NONCLUSTERED INDEX IX_library_book_copy_branch_status
    ON library_schema.library_book_copy (school_id, branch_id, copy_status)
    INCLUDE (book_id, copy_number);
GO

-- Fast available copy lookup index
CREATE NONCLUSTERED INDEX IX_library_book_copy_available
    ON library_schema.library_book_copy (book_id, copy_number)
    WHERE is_active = 1 AND copy_status = N'AVAILABLE';
GO

/* -------------------------------------------------------------------------- */
/* 4. TABLE: library_schema.library_book_borrow (Circulation Ledger)          */
/* -------------------------------------------------------------------------- */

CREATE TABLE library_schema.library_book_borrow
(
    borrow_id              BIGINT          NOT NULL IDENTITY(1, 1),
    school_id              BIGINT          NOT NULL,
    branch_id              BIGINT          NOT NULL,
    academic_year_id       BIGINT          NOT NULL,
    student_id             BIGINT          NOT NULL,
    class_id               BIGINT          NOT NULL,
    section_id             BIGINT          NOT NULL,
    book_id                BIGINT          NOT NULL,
    book_copy_id           BIGINT          NOT NULL,
    borrow_status          NVARCHAR(20)    NOT NULL,
    borrowed_at            DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_borrow_borrowed_at DEFAULT (SYSUTCDATETIME()),
    due_date               DATE            NOT NULL,
    returned_at            DATETIME2(0)    NULL,
    returned_to            BIGINT          NULL,
    issued_by              BIGINT          NOT NULL,
    remarks                NVARCHAR(500)   NULL,
    is_active              BIT             NOT NULL CONSTRAINT DF_library_book_borrow_is_active DEFAULT (1),
    updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_borrow_updated_at DEFAULT (SYSUTCDATETIME()),
    updated_by             BIGINT          NULL,
    row_version            ROWVERSION      NOT NULL,

    -- Primary Key
    CONSTRAINT PK_library_book_borrow PRIMARY KEY CLUSTERED (borrow_id),

    -- Validation Constraints
    CONSTRAINT CK_library_book_borrow_status CHECK
        (borrow_status IN (N'ACTIVE', N'OVERDUE', N'RETURNED', N'LOST')),
    CONSTRAINT CK_library_book_borrow_due_date CHECK
        (due_date >= CAST(borrowed_at AS DATE)),
    CONSTRAINT CK_library_book_borrow_returned_status CHECK
    (
        (borrow_status = N'RETURNED' AND returned_at IS NOT NULL AND returned_to IS NOT NULL)
        OR
        (borrow_status IN (N'ACTIVE', N'OVERDUE', N'LOST') AND returned_at IS NULL AND returned_to IS NULL)
    ),

    -- Composite & Referential Foreign Keys
    CONSTRAINT FK_library_book_borrow_school FOREIGN KEY (school_id)
        REFERENCES management_schema.school (school_id),
    CONSTRAINT FK_library_book_borrow_branch FOREIGN KEY (school_id, branch_id)
        REFERENCES management_schema.branch (school_id, branch_id),
    CONSTRAINT FK_library_book_borrow_academic_year FOREIGN KEY (school_id, academic_year_id)
        REFERENCES management_schema.academic_year (school_id, academic_year_id),
    CONSTRAINT FK_library_book_borrow_student_scope FOREIGN KEY (school_id, branch_id, student_id)
        REFERENCES student_schema.student (school_id, branch_id, student_id),
    CONSTRAINT FK_library_book_borrow_class_scope FOREIGN KEY (school_id, class_id)
        REFERENCES management_schema.school_class (school_id, class_id),
    CONSTRAINT FK_library_book_borrow_section_scope FOREIGN KEY (class_id, section_id)
        REFERENCES management_schema.section (class_id, section_id),
    CONSTRAINT FK_library_book_borrow_copy_scope FOREIGN KEY (school_id, branch_id, book_id, book_copy_id)
        REFERENCES library_schema.library_book_copy (school_id, branch_id, book_id, book_copy_id),
    CONSTRAINT FK_library_book_borrow_issued_by FOREIGN KEY (issued_by)
        REFERENCES security_schema.users (user_id),
    CONSTRAINT FK_library_book_borrow_returned_to FOREIGN KEY (returned_to)
        REFERENCES security_schema.users (user_id),
    CONSTRAINT FK_library_book_borrow_updated_by FOREIGN KEY (updated_by)
        REFERENCES security_schema.users (user_id)
);
GO

-- Prevent multiple active checkouts of the same physical copy
CREATE UNIQUE NONCLUSTERED INDEX UX_library_book_borrow_active_copy
    ON library_schema.library_book_borrow (school_id, branch_id, book_copy_id)
    WHERE is_active = 1 AND borrow_status IN (N'ACTIVE', N'OVERDUE');
GO

-- Circulation index: Student borrowing history
CREATE NONCLUSTERED INDEX IX_library_book_borrow_student_history
    ON library_schema.library_book_borrow (student_id, borrow_status, due_date)
    WHERE is_active = 1;
GO

-- Circulation index: Student history by academic year
CREATE NONCLUSTERED INDEX IX_library_book_borrow_student_year
    ON library_schema.library_book_borrow (school_id, academic_year_id, student_id, borrow_status);
GO

-- Active loans index
CREATE NONCLUSTERED INDEX IX_library_book_borrow_active_loans
    ON library_schema.library_book_borrow (school_id, branch_id, due_date)
    INCLUDE (student_id, book_id, book_copy_id, borrowed_at)
    WHERE is_active = 1 AND borrow_status = N'ACTIVE';
GO

-- Overdue loans index
CREATE NONCLUSTERED INDEX IX_library_book_borrow_overdue_loans
    ON library_schema.library_book_borrow (school_id, branch_id, due_date)
    INCLUDE (student_id, book_id, book_copy_id, borrowed_at)
    WHERE is_active = 1 AND borrow_status = N'OVERDUE';
GO

-- Circulation audit by branch
CREATE NONCLUSTERED INDEX IX_library_book_borrow_branch_circulation
    ON library_schema.library_book_borrow (branch_id, borrowed_at)
    INCLUDE (book_id, student_id, borrow_status);
GO

-- Book-copy lifecycle history
CREATE NONCLUSTERED INDEX IX_library_book_borrow_copy_history
    ON library_schema.library_book_borrow (book_copy_id, borrowed_at)
    INCLUDE (student_id, borrow_status, returned_at);
GO

-- Staff checkout audit trail
CREATE NONCLUSTERED INDEX IX_library_book_borrow_issued_by
    ON library_schema.library_book_borrow (issued_by, borrowed_at);
GO

-- Lost book reporting
CREATE NONCLUSTERED INDEX IX_library_book_borrow_lost
    ON library_schema.library_book_borrow (school_id, branch_id, updated_at)
    INCLUDE (student_id, book_id, book_copy_id)
    WHERE borrow_status = N'LOST';
GO

/* -------------------------------------------------------------------------- */
/* 5. MIGRATION TRACKING                                                      */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM security_schema.schema_version WHERE migration_name = N'014_library')
    BEGIN
        INSERT INTO security_schema.schema_version (migration_name, applied_at)
        VALUES (N'014_library', SYSUTCDATETIME());
    END;
END;
GO

/* END INLINE MIGRATION: 014_library.sql */

/* BEGIN INLINE MIGRATION: 015_transport.sql */
/* Module migration: 015_transport.sql */
/*
    Migration: 015_transport
    Purpose:   Bus tracking â€” vehicles, staff, routes, route stops, trips, trip stops,
               speed measurements, student transport assignments, and change requests.

    Hardened Architecture:
    - transport_schema:
        1. vehicle
        2. staff
        3. vehicle_route
        4. vehicle_route_stop
        5. trip
        6. trip_stop
        7. speed_measurement
    - student_schema:
        8. transport_assignment
        9. transport_change_request

    Design & Hardening Highlights:
    - Strict cross-entity hierarchy: School -> Branch -> Vehicle -> Route -> Stop -> Trip -> Trip Stop
    - Student academic placement hierarchy: School -> Branch -> Academic Year -> Class -> Section -> Student
    - Composite candidate keys and foreign keys prevent cross-branch mismatch anomalies
    - Trip route-vehicle consistency: trip.vehicle_id = route.vehicle_id and trip.trip_type = route.route_type
    - Trip stop route consistency: trip_stop.route_stop_id belongs to trip.vehicle_route_id and matches stop_sequence
    - Trip driver role enforcement: driver_id must reference staff with staff_type = 'DRIVER'
    - Telemetry integrity: speed_measurement references (trip_id, vehicle_id) matching the trip's vehicle
    - Change request all-or-none requested stop validation and permanent vs temporary return date integrity
    - Concurrency & Capacity: Stored procedure transport_schema.usp_assign_student_transport with UPDLOCK/HOLDLOCK
    - Dynamic date-dependent CHECK constraints eliminated in favor of deterministic validation
    - Idempotent and compatible with SQL Server / Azure SQL

    Rollback:
    - DROP PROCEDURE IF EXISTS transport_schema.usp_assign_student_transport;
    - DROP TABLE IF EXISTS student_schema.transport_change_request;
    - DROP TABLE IF EXISTS student_schema.transport_assignment;
    - DROP TABLE IF EXISTS transport_schema.speed_measurement;
    - DROP TABLE IF EXISTS transport_schema.trip_stop;
    - DROP TABLE IF EXISTS transport_schema.trip;
    - DROP TABLE IF EXISTS transport_schema.vehicle_route_stop;
    - DROP TABLE IF EXISTS transport_schema.vehicle_route;
    - DROP TABLE IF EXISTS transport_schema.staff;
    - DROP TABLE IF EXISTS transport_schema.vehicle;
*/

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* -------------------------------------------------------------------------- */
/* 0. SCHEMAS & SUPPORTING PARENT CANDIDATE KEYS                              */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'transport_schema')
    EXEC(N'CREATE SCHEMA transport_schema AUTHORIZATION dbo;');
GO

-- Ensure parent candidate key exists on management_schema.branch (school_id, branch_id)
IF OBJECT_ID(N'management_schema.branch', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_branch_school_scope'
         AND object_id = OBJECT_ID(N'management_schema.branch')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_branch_school_scope
        ON management_schema.branch (school_id, branch_id);
END;
GO

-- Ensure parent candidate key exists on student_schema.student (school_id, branch_id, student_id)
IF OBJECT_ID(N'student_schema.student', N'U') IS NOT NULL
   AND EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_student_school_branch_student'
         AND object_id = OBJECT_ID(N'student_schema.student')
         AND (is_unique = 0 OR is_disabled = 1 OR has_filter = 1)
   )
BEGIN
    DROP INDEX UQ_student_school_branch_student ON student_schema.student;
END;
GO

IF OBJECT_ID(N'student_schema.student', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_student_school_branch_student'
         AND object_id = OBJECT_ID(N'student_schema.student')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_school_branch_student
        ON student_schema.student (school_id, branch_id, student_id);
END;
GO

-- Ensure parent candidate key exists on student_schema.student for full academic placement hierarchy
IF OBJECT_ID(N'student_schema.student', N'U') IS NOT NULL
   AND EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_student_placement_scope'
         AND object_id = OBJECT_ID(N'student_schema.student')
         AND (is_unique = 0 OR is_disabled = 1 OR has_filter = 1)
   )
BEGIN
    DROP INDEX UQ_student_placement_scope ON student_schema.student;
END;
GO

IF OBJECT_ID(N'student_schema.student', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_student_placement_scope'
         AND object_id = OBJECT_ID(N'student_schema.student')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_placement_scope
        ON student_schema.student (school_id, branch_id, academic_year_id, class_id, section_id, student_id);
END;
GO

-- Ensure parent candidate key exists on management_schema.academic_year (school_id, academic_year_id)
IF OBJECT_ID(N'management_schema.academic_year', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_academic_year_school_scope'
         AND object_id = OBJECT_ID(N'management_schema.academic_year')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_academic_year_school_scope
        ON management_schema.academic_year (school_id, academic_year_id);
END;
GO

-- Ensure parent candidate key exists on management_schema.school_class (school_id, class_id)
IF OBJECT_ID(N'management_schema.school_class', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_school_class_school_scope'
         AND object_id = OBJECT_ID(N'management_schema.school_class')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_school_class_school_scope
        ON management_schema.school_class (school_id, class_id);
END;
GO

-- Ensure parent candidate key exists on management_schema.section (class_id, section_id)
IF OBJECT_ID(N'management_schema.section', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_section_class_scope'
         AND object_id = OBJECT_ID(N'management_schema.section')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_section_class_scope
        ON management_schema.section (class_id, section_id);
END;
GO

/* ============================================================================= */
/* 0B. LEGACY SCHEMA DETECTION & UPGRADE                                         */
/* ============================================================================= */

-- If vehicle_route exists with old un-normalized route_stop_id column,
-- OR vehicle exists without UQ_transport_vehicle_scope,
-- OR staff exists without UQ_transport_staff_role,
-- drop all legacy transport tables and rebuild cleanly to the hardened architecture.
IF (OBJECT_ID(N'transport_schema.vehicle_route', N'U') IS NOT NULL AND COL_LENGTH(N'transport_schema.vehicle_route', N'route_stop_id') IS NOT NULL)
   OR (OBJECT_ID(N'transport_schema.vehicle', N'U') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_transport_vehicle_scope' AND object_id = OBJECT_ID(N'transport_schema.vehicle')))
   OR (OBJECT_ID(N'transport_schema.staff', N'U') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_transport_staff_role' AND object_id = OBJECT_ID(N'transport_schema.staff')))
BEGIN
    PRINT N'Detected legacy transport schema. Upgrading all transport tables to hardened architecture...';
    DROP PROCEDURE IF EXISTS transport_schema.usp_assign_student_transport;
    DROP TABLE IF EXISTS student_schema.transport_change_request;
    DROP TABLE IF EXISTS student_schema.transport_assignment;
    DROP TABLE IF EXISTS transport_schema.speed_measurement;
    DROP TABLE IF EXISTS transport_schema.trip_stop;
    DROP TABLE IF EXISTS transport_schema.trip;
    DROP TABLE IF EXISTS transport_schema.vehicle_route_stop;
    DROP TABLE IF EXISTS transport_schema.vehicle_route;
    DROP TABLE IF EXISTS transport_schema.staff;
    DROP TABLE IF EXISTS transport_schema.vehicle;
END;
GO

-- Ensure candidate keys exist on transport_schema.vehicle if table already existed
IF OBJECT_ID(N'transport_schema.vehicle', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_transport_vehicle_scope'
         AND object_id = OBJECT_ID(N'transport_schema.vehicle')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_transport_vehicle_scope
        ON transport_schema.vehicle (school_id, branch_id, vehicle_id);
END;
GO

-- Ensure candidate keys exist on transport_schema.staff if table already existed
IF OBJECT_ID(N'transport_schema.staff', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_transport_staff_role'
         AND object_id = OBJECT_ID(N'transport_schema.staff')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_transport_staff_role
        ON transport_schema.staff (staff_id, staff_type);
END;
GO

IF OBJECT_ID(N'transport_schema.staff', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes
       WHERE name = N'UQ_transport_staff_scope'
         AND object_id = OBJECT_ID(N'transport_schema.staff')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_transport_staff_scope
        ON transport_schema.staff (school_id, branch_id, staff_id);
END;
GO

/* -------------------------------------------------------------------------- */

/* ============================================================================= */
/* 1. TRANSPORT MODULE MASTER & DETAIL TABLES (UPDATED SSMS SCHEMA)            */
/* ============================================================================= */

/****** Object:  Table [student_schema].[transport_assignment]    Script Date: 23-09-2026 04:06:59 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[student_schema].[transport_assignment]', N'U') IS NULL
BEGIN
CREATE TABLE [student_schema].[transport_assignment](

	[transport_assignment_id] [bigint] IDENTITY(1,1) NOT NULL,

	[school_id] [bigint] NOT NULL,

	[branch_id] [bigint] NOT NULL,

	[academic_year_id] [bigint] NOT NULL,

	[class_id] [bigint] NOT NULL,

	[section_id] [bigint] NOT NULL,

	[student_id] [bigint] NOT NULL,

	[vehicle_route_id] [bigint] NOT NULL,

	[pickup_route_stop_id] [bigint] NOT NULL,

	[drop_route_stop_id] [bigint] NOT NULL,

	[estimated_pickup_time] [time](0) NOT NULL,

	[estimated_drop_time] [time](0) NOT NULL,

	[effective_from] [date] NOT NULL,

	[effective_to] [date] NULL,

	[status] [nvarchar](20) NOT NULL,

	[is_active] [bit] NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

	[created_by] [bigint] NOT NULL,

	[updated_at] [datetime2](0) NOT NULL,

	[updated_by] [bigint] NULL,

	[row_version] [timestamp] NOT NULL,

 CONSTRAINT [PK_transport_assignment] PRIMARY KEY CLUSTERED 

(

	[transport_assignment_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_transport_assignment_scope] UNIQUE NONCLUSTERED 

(

	[school_id] ASC,

	[branch_id] ASC,

	[student_id] ASC,

	[transport_assignment_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
/****** Object:  Table [student_schema].[transport_change_request]    Script Date: 23-09-2026 04:07:00 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[student_schema].[transport_change_request]', N'U') IS NULL
BEGIN
CREATE TABLE [student_schema].[transport_change_request](

	[transport_change_request_id] [bigint] IDENTITY(1,1) NOT NULL,

	[transport_assignment_id] [bigint] NULL,

	[school_id] [bigint] NOT NULL,

	[branch_id] [bigint] NOT NULL,

	[student_id] [bigint] NOT NULL,

	[request_type] [nvarchar](20) NOT NULL,

	[current_vehicle_route_id] [bigint] NOT NULL,

	[requested_vehicle_route_id] [bigint] NULL,

	[current_pickup_stop_id] [bigint] NOT NULL,

	[requested_pickup_stop_id] [bigint] NULL,

	[current_drop_stop_id] [bigint] NOT NULL,

	[requested_drop_stop_id] [bigint] NULL,

	[effective_date] [date] NOT NULL,

	[return_date] [date] NULL,

	[reason] [nvarchar](500) NOT NULL,

	[status] [nvarchar](20) NOT NULL,

	[reviewed_by] [bigint] NULL,

	[reviewed_at] [datetime2](0) NULL,

	[is_active] [bit] NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

	[created_by] [bigint] NOT NULL,

	[updated_at] [datetime2](0) NOT NULL,

	[updated_by] [bigint] NULL,

	[row_version] [timestamp] NOT NULL,

 CONSTRAINT [PK_transport_change_request] PRIMARY KEY CLUSTERED 

(

	[transport_change_request_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
/****** Object:  Table [transport_schema].[speed_measurement]    Script Date: 23-09-2026 04:07:00 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[transport_schema].[speed_measurement]', N'U') IS NULL
BEGIN
CREATE TABLE [transport_schema].[speed_measurement](

	[speed_measurement_id] [bigint] IDENTITY(1,1) NOT NULL,

	[trip_id] [bigint] NOT NULL,

	[vehicle_id] [bigint] NOT NULL,

	[recorded_at] [datetime2](0) NOT NULL,

	[speed_kmh] [decimal](6, 2) NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

 CONSTRAINT [PK_speed_measurement] PRIMARY KEY CLUSTERED 

(

	[speed_measurement_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
/****** Object:  Table [transport_schema].[staff]    Script Date: 23-09-2026 04:07:00 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[transport_schema].[staff]', N'U') IS NULL
BEGIN
CREATE TABLE [transport_schema].[staff](

	[staff_id] [bigint] IDENTITY(1,1) NOT NULL,

	[school_id] [bigint] NOT NULL,

	[branch_id] [bigint] NOT NULL,

	[user_id] [bigint] NULL,

	[staff_name] [nvarchar](150) NOT NULL,

	[staff_type] [nvarchar](30) NOT NULL,

	[experience] [int] NOT NULL,

	[mobile_number] [nvarchar](20) NULL,

	[license_number] [nvarchar](50) NULL,

	[license_expiry_date] [date] NULL,

	[status] [nvarchar](20) NOT NULL,

	[is_active] [bit] NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

	[created_by] [bigint] NOT NULL,

	[updated_at] [datetime2](0) NOT NULL,

	[updated_by] [bigint] NULL,

	[row_version] [timestamp] NOT NULL,

 CONSTRAINT [PK_transport_staff] PRIMARY KEY CLUSTERED 

(

	[staff_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_transport_staff_role] UNIQUE NONCLUSTERED 

(

	[staff_id] ASC,

	[staff_type] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_transport_staff_scope] UNIQUE NONCLUSTERED 

(

	[school_id] ASC,

	[branch_id] ASC,

	[staff_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
/****** Object:  Table [transport_schema].[trip]    Script Date: 23-09-2026 04:07:00 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[transport_schema].[trip]', N'U') IS NULL
BEGIN
CREATE TABLE [transport_schema].[trip](

	[trip_id] [bigint] IDENTITY(1,1) NOT NULL,

	[school_id] [bigint] NOT NULL,

	[branch_id] [bigint] NOT NULL,

	[vehicle_id] [bigint] NOT NULL,

	[vehicle_route_id] [bigint] NOT NULL,

	[driver_id] [bigint] NOT NULL,

	[driver_type_enforcer] [nvarchar](30) NOT NULL,

	[trip_date] [date] NOT NULL,

	[trip_type] [nvarchar](20) NOT NULL,

	[planned_start_time] [time](0) NOT NULL,

	[actual_start_at] [datetime2](0) NULL,

	[planned_destination_time] [time](0) NOT NULL,

	[actual_destination_at] [datetime2](0) NULL,

	[delay_minutes] [smallint] NULL,

	[status] [nvarchar](20) NOT NULL,

	[is_active] [bit] NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

	[created_by] [bigint] NOT NULL,

	[updated_at] [datetime2](0) NOT NULL,

	[updated_by] [bigint] NULL,

	[row_version] [timestamp] NOT NULL,

 CONSTRAINT [PK_trip] PRIMARY KEY CLUSTERED 

(

	[trip_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_trip_route] UNIQUE NONCLUSTERED 

(

	[trip_id] ASC,

	[vehicle_route_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_trip_vehicle] UNIQUE NONCLUSTERED 

(

	[trip_id] ASC,

	[vehicle_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
/****** Object:  Table [transport_schema].[trip_stop]    Script Date: 23-09-2026 04:07:00 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[transport_schema].[trip_stop]', N'U') IS NULL
BEGIN
CREATE TABLE [transport_schema].[trip_stop](

	[trip_stop_id] [bigint] IDENTITY(1,1) NOT NULL,

	[trip_id] [bigint] NOT NULL,

	[vehicle_route_id] [bigint] NOT NULL,

	[route_stop_id] [bigint] NOT NULL,

	[stop_sequence] [smallint] NOT NULL,

	[planned_arrival_at] [datetime2](0) NOT NULL,

	[actual_arrival_at] [datetime2](0) NULL,

	[actual_departure_at] [datetime2](0) NULL,

	[delay_minutes] [smallint] NULL,

	[status] [nvarchar](20) NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

	[row_version] [timestamp] NOT NULL,

 CONSTRAINT [PK_trip_stop] PRIMARY KEY CLUSTERED 

(

	[trip_stop_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_trip_stop_trip_route_stop] UNIQUE NONCLUSTERED 

(

	[trip_id] ASC,

	[route_stop_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_trip_stop_trip_sequence] UNIQUE NONCLUSTERED 

(

	[trip_id] ASC,

	[stop_sequence] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
/****** Object:  Table [transport_schema].[vehicle]    Script Date: 23-09-2026 04:07:00 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[transport_schema].[vehicle]', N'U') IS NULL
BEGIN
CREATE TABLE [transport_schema].[vehicle](

	[vehicle_id] [bigint] IDENTITY(1,1) NOT NULL,

	[school_id] [bigint] NOT NULL,

	[branch_id] [bigint] NOT NULL,

	[vehicle_number] [nvarchar](30) NOT NULL,

	[vehicle_name] [nvarchar](100) NULL,

	[capacity] [int] NOT NULL,

	[status] [nvarchar](20) NOT NULL,

	[vehicle_health] [nvarchar](30) NOT NULL,

	[is_active] [bit] NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

	[created_by] [bigint] NOT NULL,

	[updated_at] [datetime2](0) NOT NULL,

	[updated_by] [bigint] NULL,

	[row_version] [timestamp] NOT NULL,

 CONSTRAINT [PK_transport_vehicle] PRIMARY KEY CLUSTERED 

(

	[vehicle_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_transport_vehicle_number] UNIQUE NONCLUSTERED 

(

	[vehicle_number] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_transport_vehicle_scope] UNIQUE NONCLUSTERED 

(

	[school_id] ASC,

	[branch_id] ASC,

	[vehicle_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[transport_schema].[vehicle]', N'U') IS NOT NULL
   AND COL_LENGTH(N'transport_schema.vehicle', N'vehicle_health') IS NULL
BEGIN
    ALTER TABLE [transport_schema].[vehicle]
        ADD [vehicle_health] [nvarchar](30) NOT NULL CONSTRAINT [DF_transport_vehicle_health] DEFAULT (N'GOOD') WITH VALUES;
END
GO
IF OBJECT_ID(N'[transport_schema].[staff]', N'U') IS NOT NULL
   AND COL_LENGTH(N'transport_schema.staff', N'experience') IS NULL
BEGIN
    ALTER TABLE [transport_schema].[staff]
        ADD [experience] [int] NOT NULL CONSTRAINT [DF_transport_staff_experience] DEFAULT ((0)) WITH VALUES;
END
GO
/****** Object:  Table [transport_schema].[vehicle_route]    Script Date: 23-09-2026 04:07:00 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[transport_schema].[vehicle_route]', N'U') IS NULL
BEGIN
CREATE TABLE [transport_schema].[vehicle_route](

	[vehicle_route_id] [bigint] IDENTITY(1,1) NOT NULL,

	[school_id] [bigint] NOT NULL,

	[branch_id] [bigint] NOT NULL,

	[vehicle_id] [bigint] NOT NULL,

	[route_code] [nvarchar](30) NOT NULL,

	[route_name] [nvarchar](150) NOT NULL,

	[route_type] [nvarchar](20) NOT NULL,

	[status] [nvarchar](20) NOT NULL,

	[effective_from] [date] NOT NULL,

	[effective_to] [date] NULL,

	[is_active] [bit] NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

	[created_by] [bigint] NOT NULL,

	[updated_at] [datetime2](0) NOT NULL,

	[updated_by] [bigint] NULL,

	[row_version] [timestamp] NOT NULL,

 CONSTRAINT [PK_vehicle_route] PRIMARY KEY CLUSTERED 

(

	[vehicle_route_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_vehicle_route_branch_scope] UNIQUE NONCLUSTERED 

(

	[school_id] ASC,

	[branch_id] ASC,

	[vehicle_route_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_vehicle_route_code] UNIQUE NONCLUSTERED 

(

	[vehicle_id] ASC,

	[route_code] ASC,

	[route_type] ASC,

	[effective_from] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_vehicle_route_vehicle_type] UNIQUE NONCLUSTERED 

(

	[vehicle_route_id] ASC,

	[vehicle_id] ASC,

	[route_type] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
/****** Object:  Table [transport_schema].[vehicle_route_stop]    Script Date: 23-09-2026 04:07:00 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[transport_schema].[vehicle_route_stop]', N'U') IS NULL
BEGIN
CREATE TABLE [transport_schema].[vehicle_route_stop](

	[route_stop_id] [bigint] IDENTITY(1,1) NOT NULL,

	[vehicle_route_id] [bigint] NOT NULL,

	[stop_sequence] [smallint] NOT NULL,

	[stop_name] [nvarchar](150) NOT NULL,

	[stop_address] [nvarchar](300) NULL,

	[planned_arrival_time] [time](0) NOT NULL,

	[planned_departure_time] [time](0) NULL,

	[is_active] [bit] NOT NULL,

	[created_at] [datetime2](0) NOT NULL,

	[created_by] [bigint] NOT NULL,

	[updated_at] [datetime2](0) NOT NULL,

	[updated_by] [bigint] NULL,

	[row_version] [timestamp] NOT NULL,

 CONSTRAINT [PK_route_stop] PRIMARY KEY CLUSTERED 

(

	[route_stop_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_route_stop_composite] UNIQUE NONCLUSTERED 

(

	[vehicle_route_id] ASC,

	[route_stop_id] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_route_stop_sequence] UNIQUE NONCLUSTERED 

(

	[vehicle_route_id] ASC,

	[stop_sequence] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_route_stop_sequence_composite] UNIQUE NONCLUSTERED 

(

	[vehicle_route_id] ASC,

	[route_stop_id] ASC,

	[stop_sequence] ASC

)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_assignment_is_active')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] ADD  CONSTRAINT [DF_transport_assignment_is_active]  DEFAULT ((1)) FOR [is_active]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_assignment_created_at')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] ADD  CONSTRAINT [DF_transport_assignment_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_assignment_updated_at')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] ADD  CONSTRAINT [DF_transport_assignment_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_change_request_is_active')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] ADD  CONSTRAINT [DF_transport_change_request_is_active]  DEFAULT ((1)) FOR [is_active]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_change_request_created_at')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] ADD  CONSTRAINT [DF_transport_change_request_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_change_request_updated_at')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] ADD  CONSTRAINT [DF_transport_change_request_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_speed_measurement_created_at')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement] ADD  CONSTRAINT [DF_speed_measurement_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_staff_is_active')
BEGIN
    ALTER TABLE [transport_schema].[staff] ADD  CONSTRAINT [DF_transport_staff_is_active]  DEFAULT ((1)) FOR [is_active]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_staff_created_at')
BEGIN
    ALTER TABLE [transport_schema].[staff] ADD  CONSTRAINT [DF_transport_staff_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_staff_updated_at')
BEGIN
    ALTER TABLE [transport_schema].[staff] ADD  CONSTRAINT [DF_transport_staff_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_staff_experience')
BEGIN
    ALTER TABLE [transport_schema].[staff] ADD  CONSTRAINT [DF_transport_staff_experience]  DEFAULT ((0)) FOR [experience]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_trip_driver_type')
BEGIN
    ALTER TABLE [transport_schema].[trip] ADD  CONSTRAINT [DF_trip_driver_type]  DEFAULT (N'DRIVER') FOR [driver_type_enforcer]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_trip_is_active')
BEGIN
    ALTER TABLE [transport_schema].[trip] ADD  CONSTRAINT [DF_trip_is_active]  DEFAULT ((1)) FOR [is_active]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_trip_created_at')
BEGIN
    ALTER TABLE [transport_schema].[trip] ADD  CONSTRAINT [DF_trip_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_trip_updated_at')
BEGIN
    ALTER TABLE [transport_schema].[trip] ADD  CONSTRAINT [DF_trip_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_trip_stop_created_at')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop] ADD  CONSTRAINT [DF_trip_stop_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_vehicle_is_active')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] ADD  CONSTRAINT [DF_transport_vehicle_is_active]  DEFAULT ((1)) FOR [is_active]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_vehicle_health')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] ADD  CONSTRAINT [DF_transport_vehicle_health]  DEFAULT (N'GOOD') FOR [vehicle_health]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_vehicle_created_at')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] ADD  CONSTRAINT [DF_transport_vehicle_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_transport_vehicle_updated_at')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] ADD  CONSTRAINT [DF_transport_vehicle_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_vehicle_route_is_active')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] ADD  CONSTRAINT [DF_vehicle_route_is_active]  DEFAULT ((1)) FOR [is_active]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_vehicle_route_created_at')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] ADD  CONSTRAINT [DF_vehicle_route_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_vehicle_route_updated_at')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] ADD  CONSTRAINT [DF_vehicle_route_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_route_stop_is_active')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] ADD  CONSTRAINT [DF_route_stop_is_active]  DEFAULT ((1)) FOR [is_active]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_route_stop_created_at')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] ADD  CONSTRAINT [DF_route_stop_created_at]  DEFAULT (sysutcdatetime()) FOR [created_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_route_stop_updated_at')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] ADD  CONSTRAINT [DF_route_stop_updated_at]  DEFAULT (sysutcdatetime()) FOR [updated_at]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_academic_year')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_academic_year] FOREIGN KEY([academic_year_id])

REFERENCES [management_schema].[academic_year] ([academic_year_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_academic_year')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_academic_year]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_academic_year_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_academic_year_scope] FOREIGN KEY([school_id], [academic_year_id])

REFERENCES [management_schema].[academic_year] ([school_id], [academic_year_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_academic_year_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_academic_year_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_branch')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_branch] FOREIGN KEY([branch_id])

REFERENCES [management_schema].[branch] ([branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_branch')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_branch]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_branch_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_branch_scope] FOREIGN KEY([school_id], [branch_id])

REFERENCES [management_schema].[branch] ([school_id], [branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_branch_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_branch_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_class')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_class] FOREIGN KEY([class_id])

REFERENCES [management_schema].[school_class] ([class_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_class')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_class]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_class_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_class_scope] FOREIGN KEY([school_id], [class_id])

REFERENCES [management_schema].[school_class] ([school_id], [class_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_class_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_class_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_created_by')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_created_by] FOREIGN KEY([created_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_created_by')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_created_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_drop_stop')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_drop_stop] FOREIGN KEY([vehicle_route_id], [drop_route_stop_id])

REFERENCES [transport_schema].[vehicle_route_stop] ([vehicle_route_id], [route_stop_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_drop_stop')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_drop_stop]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_pickup_stop')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_pickup_stop] FOREIGN KEY([vehicle_route_id], [pickup_route_stop_id])

REFERENCES [transport_schema].[vehicle_route_stop] ([vehicle_route_id], [route_stop_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_pickup_stop')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_pickup_stop]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_route_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_route_scope] FOREIGN KEY([school_id], [branch_id], [vehicle_route_id])

REFERENCES [transport_schema].[vehicle_route] ([school_id], [branch_id], [vehicle_route_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_route_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_route_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_school')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_school] FOREIGN KEY([school_id])

REFERENCES [management_schema].[school] ([school_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_school')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_school]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_section')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_section] FOREIGN KEY([section_id])

REFERENCES [management_schema].[section] ([section_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_section')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_section]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_section_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_section_scope] FOREIGN KEY([class_id], [section_id])

REFERENCES [management_schema].[section] ([class_id], [section_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_section_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_section_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_student')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_student] FOREIGN KEY([student_id])

REFERENCES [student_schema].[student] ([student_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_student')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_student]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_student_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_student_scope] FOREIGN KEY([school_id], [branch_id], [student_id])

REFERENCES [student_schema].[student] ([school_id], [branch_id], [student_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_student_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_student_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_updated_by')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_updated_by] FOREIGN KEY([updated_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_updated_by')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_updated_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_assignment_vehicle_route')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [FK_transport_assignment_vehicle_route] FOREIGN KEY([vehicle_route_id])

REFERENCES [transport_schema].[vehicle_route] ([vehicle_route_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_assignment_vehicle_route')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [FK_transport_assignment_vehicle_route]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_assignment')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_assignment] FOREIGN KEY([transport_assignment_id])

REFERENCES [student_schema].[transport_assignment] ([transport_assignment_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_assignment')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_assignment]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_branch')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_branch] FOREIGN KEY([branch_id])

REFERENCES [management_schema].[branch] ([branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_branch')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_branch]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_branch_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_branch_scope] FOREIGN KEY([school_id], [branch_id])

REFERENCES [management_schema].[branch] ([school_id], [branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_branch_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_branch_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_created_by')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_created_by] FOREIGN KEY([created_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_created_by')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_created_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_current_drop')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_current_drop] FOREIGN KEY([current_vehicle_route_id], [current_drop_stop_id])

REFERENCES [transport_schema].[vehicle_route_stop] ([vehicle_route_id], [route_stop_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_current_drop')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_current_drop]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_current_pickup')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_current_pickup] FOREIGN KEY([current_vehicle_route_id], [current_pickup_stop_id])

REFERENCES [transport_schema].[vehicle_route_stop] ([vehicle_route_id], [route_stop_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_current_pickup')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_current_pickup]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_current_route')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_current_route] FOREIGN KEY([current_vehicle_route_id])

REFERENCES [transport_schema].[vehicle_route] ([vehicle_route_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_current_route')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_current_route]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_current_route_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_current_route_scope] FOREIGN KEY([school_id], [branch_id], [current_vehicle_route_id])

REFERENCES [transport_schema].[vehicle_route] ([school_id], [branch_id], [vehicle_route_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_current_route_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_current_route_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_requested_drop')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_requested_drop] FOREIGN KEY([requested_vehicle_route_id], [requested_drop_stop_id])

REFERENCES [transport_schema].[vehicle_route_stop] ([vehicle_route_id], [route_stop_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_requested_drop')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_requested_drop]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_requested_pickup')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_requested_pickup] FOREIGN KEY([requested_vehicle_route_id], [requested_pickup_stop_id])

REFERENCES [transport_schema].[vehicle_route_stop] ([vehicle_route_id], [route_stop_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_requested_pickup')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_requested_pickup]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_requested_route')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_requested_route] FOREIGN KEY([requested_vehicle_route_id])

REFERENCES [transport_schema].[vehicle_route] ([vehicle_route_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_requested_route')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_requested_route]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_reviewed_by')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_reviewed_by] FOREIGN KEY([reviewed_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_reviewed_by')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_reviewed_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_school')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_school] FOREIGN KEY([school_id])

REFERENCES [management_schema].[school] ([school_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_school')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_school]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_student')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_student] FOREIGN KEY([student_id])

REFERENCES [student_schema].[student] ([student_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_student')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_student]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_student_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_student_scope] FOREIGN KEY([school_id], [branch_id], [student_id])

REFERENCES [student_schema].[student] ([school_id], [branch_id], [student_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_student_scope')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_student_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_change_request_updated_by')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [FK_transport_change_request_updated_by] FOREIGN KEY([updated_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_change_request_updated_by')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [FK_transport_change_request_updated_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_speed_measurement_trip')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement]  WITH CHECK ADD  CONSTRAINT [FK_speed_measurement_trip] FOREIGN KEY([trip_id])

REFERENCES [transport_schema].[trip] ([trip_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_speed_measurement_trip')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement] CHECK CONSTRAINT [FK_speed_measurement_trip]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_speed_measurement_trip_vehicle')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement]  WITH CHECK ADD  CONSTRAINT [FK_speed_measurement_trip_vehicle] FOREIGN KEY([trip_id], [vehicle_id])

REFERENCES [transport_schema].[trip] ([trip_id], [vehicle_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_speed_measurement_trip_vehicle')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement] CHECK CONSTRAINT [FK_speed_measurement_trip_vehicle]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_speed_measurement_vehicle')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement]  WITH CHECK ADD  CONSTRAINT [FK_speed_measurement_vehicle] FOREIGN KEY([vehicle_id])

REFERENCES [transport_schema].[vehicle] ([vehicle_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_speed_measurement_vehicle')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement] CHECK CONSTRAINT [FK_speed_measurement_vehicle]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_staff_branch')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [FK_transport_staff_branch] FOREIGN KEY([branch_id])

REFERENCES [management_schema].[branch] ([branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_staff_branch')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [FK_transport_staff_branch]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_staff_branch_scope')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [FK_transport_staff_branch_scope] FOREIGN KEY([school_id], [branch_id])

REFERENCES [management_schema].[branch] ([school_id], [branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_staff_branch_scope')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [FK_transport_staff_branch_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_staff_created_by')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [FK_transport_staff_created_by] FOREIGN KEY([created_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_staff_created_by')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [FK_transport_staff_created_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_staff_school')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [FK_transport_staff_school] FOREIGN KEY([school_id])

REFERENCES [management_schema].[school] ([school_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_staff_school')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [FK_transport_staff_school]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_staff_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [FK_transport_staff_updated_by] FOREIGN KEY([updated_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_staff_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [FK_transport_staff_updated_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_staff_user')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [FK_transport_staff_user] FOREIGN KEY([user_id])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_staff_user')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [FK_transport_staff_user]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_branch')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_branch] FOREIGN KEY([branch_id])

REFERENCES [management_schema].[branch] ([branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_branch')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_branch]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_branch_scope')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_branch_scope] FOREIGN KEY([school_id], [branch_id])

REFERENCES [management_schema].[branch] ([school_id], [branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_branch_scope')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_branch_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_created_by')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_created_by] FOREIGN KEY([created_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_created_by')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_created_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_driver')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_driver] FOREIGN KEY([driver_id], [driver_type_enforcer])

REFERENCES [transport_schema].[staff] ([staff_id], [staff_type])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_driver')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_driver]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_route_vehicle_type')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_route_vehicle_type] FOREIGN KEY([vehicle_route_id], [vehicle_id], [trip_type])

REFERENCES [transport_schema].[vehicle_route] ([vehicle_route_id], [vehicle_id], [route_type])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_route_vehicle_type')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_route_vehicle_type]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_school')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_school] FOREIGN KEY([school_id])

REFERENCES [management_schema].[school] ([school_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_school')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_school]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_updated_by] FOREIGN KEY([updated_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_updated_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_vehicle')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_vehicle] FOREIGN KEY([vehicle_id])

REFERENCES [transport_schema].[vehicle] ([vehicle_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_vehicle')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_vehicle]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_vehicle_scope')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [FK_trip_vehicle_scope] FOREIGN KEY([school_id], [branch_id], [vehicle_id])

REFERENCES [transport_schema].[vehicle] ([school_id], [branch_id], [vehicle_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_vehicle_scope')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [FK_trip_vehicle_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_stop_route_stop_sequence')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop]  WITH CHECK ADD  CONSTRAINT [FK_trip_stop_route_stop_sequence] FOREIGN KEY([vehicle_route_id], [route_stop_id], [stop_sequence])

REFERENCES [transport_schema].[vehicle_route_stop] ([vehicle_route_id], [route_stop_id], [stop_sequence])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_stop_route_stop_sequence')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop] CHECK CONSTRAINT [FK_trip_stop_route_stop_sequence]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_stop_trip')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop]  WITH CHECK ADD  CONSTRAINT [FK_trip_stop_trip] FOREIGN KEY([trip_id])

REFERENCES [transport_schema].[trip] ([trip_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_stop_trip')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop] CHECK CONSTRAINT [FK_trip_stop_trip]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_trip_stop_trip_route')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop]  WITH CHECK ADD  CONSTRAINT [FK_trip_stop_trip_route] FOREIGN KEY([trip_id], [vehicle_route_id])

REFERENCES [transport_schema].[trip] ([trip_id], [vehicle_route_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_trip_stop_trip_route')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop] CHECK CONSTRAINT [FK_trip_stop_trip_route]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_vehicle_branch')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [FK_transport_vehicle_branch] FOREIGN KEY([branch_id])

REFERENCES [management_schema].[branch] ([branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_vehicle_branch')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [FK_transport_vehicle_branch]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_vehicle_branch_scope')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [FK_transport_vehicle_branch_scope] FOREIGN KEY([school_id], [branch_id])

REFERENCES [management_schema].[branch] ([school_id], [branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_vehicle_branch_scope')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [FK_transport_vehicle_branch_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_vehicle_created_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [FK_transport_vehicle_created_by] FOREIGN KEY([created_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_vehicle_created_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [FK_transport_vehicle_created_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_vehicle_school')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [FK_transport_vehicle_school] FOREIGN KEY([school_id])

REFERENCES [management_schema].[school] ([school_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_vehicle_school')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [FK_transport_vehicle_school]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_transport_vehicle_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [FK_transport_vehicle_updated_by] FOREIGN KEY([updated_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_transport_vehicle_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [FK_transport_vehicle_updated_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_vehicle_route_branch')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [FK_vehicle_route_branch] FOREIGN KEY([branch_id])

REFERENCES [management_schema].[branch] ([branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_vehicle_route_branch')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [FK_vehicle_route_branch]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_vehicle_route_branch_scope')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [FK_vehicle_route_branch_scope] FOREIGN KEY([school_id], [branch_id])

REFERENCES [management_schema].[branch] ([school_id], [branch_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_vehicle_route_branch_scope')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [FK_vehicle_route_branch_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_vehicle_route_created_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [FK_vehicle_route_created_by] FOREIGN KEY([created_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_vehicle_route_created_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [FK_vehicle_route_created_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_vehicle_route_school')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [FK_vehicle_route_school] FOREIGN KEY([school_id])

REFERENCES [management_schema].[school] ([school_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_vehicle_route_school')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [FK_vehicle_route_school]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_vehicle_route_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [FK_vehicle_route_updated_by] FOREIGN KEY([updated_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_vehicle_route_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [FK_vehicle_route_updated_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_vehicle_route_vehicle')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [FK_vehicle_route_vehicle] FOREIGN KEY([vehicle_id])

REFERENCES [transport_schema].[vehicle] ([vehicle_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_vehicle_route_vehicle')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [FK_vehicle_route_vehicle]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_vehicle_route_vehicle_scope')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [FK_vehicle_route_vehicle_scope] FOREIGN KEY([school_id], [branch_id], [vehicle_id])

REFERENCES [transport_schema].[vehicle] ([school_id], [branch_id], [vehicle_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_vehicle_route_vehicle_scope')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [FK_vehicle_route_vehicle_scope]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_route_stop_created_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop]  WITH CHECK ADD  CONSTRAINT [FK_route_stop_created_by] FOREIGN KEY([created_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_route_stop_created_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] CHECK CONSTRAINT [FK_route_stop_created_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_route_stop_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop]  WITH CHECK ADD  CONSTRAINT [FK_route_stop_updated_by] FOREIGN KEY([updated_by])

REFERENCES [security_schema].[users] ([user_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_route_stop_updated_by')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] CHECK CONSTRAINT [FK_route_stop_updated_by]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_route_stop_vehicle_route')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop]  WITH CHECK ADD  CONSTRAINT [FK_route_stop_vehicle_route] FOREIGN KEY([vehicle_route_id])

REFERENCES [transport_schema].[vehicle_route] ([vehicle_route_id])
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_route_stop_vehicle_route')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] CHECK CONSTRAINT [FK_route_stop_vehicle_route]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_assignment_dates')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [CK_transport_assignment_dates] CHECK  (([effective_to] IS NULL OR [effective_to]>=[effective_from]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_assignment_dates')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [CK_transport_assignment_dates]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_assignment_status')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [CK_transport_assignment_status] CHECK  (([status]=N'INACTIVE' OR [status]=N'ACTIVE'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_assignment_status')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [CK_transport_assignment_status]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_assignment_stop_pair')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [CK_transport_assignment_stop_pair] CHECK  (([pickup_route_stop_id]<>[drop_route_stop_id]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_assignment_stop_pair')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [CK_transport_assignment_stop_pair]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_assignment_times')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment]  WITH CHECK ADD  CONSTRAINT [CK_transport_assignment_times] CHECK  (([estimated_drop_time]>=[estimated_pickup_time]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_assignment_times')
BEGIN
    ALTER TABLE [student_schema].[transport_assignment] CHECK CONSTRAINT [CK_transport_assignment_times]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_current_stop_pair')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_current_stop_pair] CHECK  (([current_pickup_stop_id]<>[current_drop_stop_id]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_current_stop_pair')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_current_stop_pair]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_date_rules')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_date_rules] CHECK  (([request_type]=N'TEMPORARY' AND [return_date] IS NOT NULL AND [return_date]>=[effective_date] OR [request_type]=N'PERMANENT' AND [return_date] IS NULL))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_date_rules')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_date_rules]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_effective_date')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_effective_date] CHECK  (([effective_date]>='1900-01-01'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_effective_date')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_effective_date]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_reason')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_reason] CHECK  ((len(ltrim(rtrim([reason])))>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_reason')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_reason]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_requested_all_or_none')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_requested_all_or_none] CHECK  (([requested_vehicle_route_id] IS NULL AND [requested_pickup_stop_id] IS NULL AND [requested_drop_stop_id] IS NULL OR [requested_vehicle_route_id] IS NOT NULL AND [requested_pickup_stop_id] IS NOT NULL AND [requested_drop_stop_id] IS NOT NULL))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_requested_all_or_none')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_requested_all_or_none]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_requested_stop_pair')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_requested_stop_pair] CHECK  (([requested_pickup_stop_id] IS NULL OR [requested_pickup_stop_id]<>[requested_drop_stop_id]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_requested_stop_pair')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_requested_stop_pair]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_review_state')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_review_state] CHECK  (([reviewed_by] IS NULL AND [reviewed_at] IS NULL OR [reviewed_by] IS NOT NULL AND [reviewed_at] IS NOT NULL))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_review_state')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_review_state]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_status')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_status] CHECK  (([status]=N'COMPLETED' OR [status]=N'CANCELLED' OR [status]=N'REJECTED' OR [status]=N'APPROVED' OR [status]=N'PENDING'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_status')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_status]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_change_request_type')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request]  WITH CHECK ADD  CONSTRAINT [CK_transport_change_request_type] CHECK  (([request_type]=N'TEMPORARY' OR [request_type]=N'PERMANENT'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_change_request_type')
BEGIN
    ALTER TABLE [student_schema].[transport_change_request] CHECK CONSTRAINT [CK_transport_change_request_type]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_speed_measurement_speed')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement]  WITH CHECK ADD  CONSTRAINT [CK_speed_measurement_speed] CHECK  (([speed_kmh]>=(0.00) AND [speed_kmh]<=(200.00)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_speed_measurement_speed')
BEGIN
    ALTER TABLE [transport_schema].[speed_measurement] CHECK CONSTRAINT [CK_speed_measurement_speed]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_staff_license_date')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [CK_transport_staff_license_date] CHECK  (([license_expiry_date] IS NULL OR [license_expiry_date]>='1900-01-01'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_staff_license_date')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [CK_transport_staff_license_date]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_staff_name')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [CK_transport_staff_name] CHECK  ((len(ltrim(rtrim([staff_name])))>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_staff_name')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [CK_transport_staff_name]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_staff_status')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [CK_transport_staff_status] CHECK  (([status]=N'INACTIVE' OR [status]=N'ACTIVE'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_staff_status')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [CK_transport_staff_status]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_staff_type')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [CK_transport_staff_type] CHECK  (([staff_type]=N'OTHER' OR [staff_type]=N'COORDINATOR' OR [staff_type]=N'ATTENDANT' OR [staff_type]=N'DRIVER'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_staff_type')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [CK_transport_staff_type]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_staff_experience')
BEGIN
    ALTER TABLE [transport_schema].[staff]  WITH CHECK ADD  CONSTRAINT [CK_transport_staff_experience] CHECK  (([experience]>=(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_staff_experience')
BEGIN
    ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [CK_transport_staff_experience]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_delay')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [CK_trip_delay] CHECK  (([delay_minutes] IS NULL OR [delay_minutes]>=(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_delay')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [CK_trip_delay]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_driver_type')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [CK_trip_driver_type] CHECK  (([driver_type_enforcer]=N'DRIVER'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_driver_type')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [CK_trip_driver_type]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_planned_times')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [CK_trip_planned_times] CHECK  (([planned_destination_time]>=[planned_start_time]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_planned_times')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [CK_trip_planned_times]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_status')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [CK_trip_status] CHECK  (([status]=N'CANCELLED' OR [status]=N'COMPLETED' OR [status]=N'IN_TRANSIT' OR [status]=N'SCHEDULED'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_status')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [CK_trip_status]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_time_window')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [CK_trip_time_window] CHECK  (([actual_start_at] IS NULL OR [actual_destination_at] IS NULL OR [actual_destination_at]>=[actual_start_at]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_time_window')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [CK_trip_time_window]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_type')
BEGIN
    ALTER TABLE [transport_schema].[trip]  WITH CHECK ADD  CONSTRAINT [CK_trip_type] CHECK  (([trip_type]=N'DROP' OR [trip_type]=N'PICKUP'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_type')
BEGIN
    ALTER TABLE [transport_schema].[trip] CHECK CONSTRAINT [CK_trip_type]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_stop_actual_time')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop]  WITH CHECK ADD  CONSTRAINT [CK_trip_stop_actual_time] CHECK  (([actual_arrival_at] IS NULL OR [actual_departure_at] IS NULL OR [actual_departure_at]>=[actual_arrival_at]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_stop_actual_time')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop] CHECK CONSTRAINT [CK_trip_stop_actual_time]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_stop_delay')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop]  WITH CHECK ADD  CONSTRAINT [CK_trip_stop_delay] CHECK  (([delay_minutes] IS NULL OR [delay_minutes]>=(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_stop_delay')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop] CHECK CONSTRAINT [CK_trip_stop_delay]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_stop_sequence')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop]  WITH CHECK ADD  CONSTRAINT [CK_trip_stop_sequence] CHECK  (([stop_sequence]>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_stop_sequence')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop] CHECK CONSTRAINT [CK_trip_stop_sequence]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_trip_stop_status')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop]  WITH CHECK ADD  CONSTRAINT [CK_trip_stop_status] CHECK  (([status]=N'SKIPPED' OR [status]=N'DEPARTED' OR [status]=N'ARRIVED' OR [status]=N'PENDING'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_trip_stop_status')
BEGIN
    ALTER TABLE [transport_schema].[trip_stop] CHECK CONSTRAINT [CK_trip_stop_status]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_vehicle_capacity')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [CK_transport_vehicle_capacity] CHECK  (([capacity]>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_vehicle_capacity')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [CK_transport_vehicle_capacity]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_vehicle_number')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [CK_transport_vehicle_number] CHECK  ((len(ltrim(rtrim([vehicle_number])))>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_vehicle_number')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [CK_transport_vehicle_number]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_vehicle_status')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [CK_transport_vehicle_status] CHECK  (([status]=N'INACTIVE' OR [status]=N'MAINTENANCE' OR [status]=N'ACTIVE'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_vehicle_status')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [CK_transport_vehicle_status]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_transport_vehicle_health')
BEGIN
    ALTER TABLE [transport_schema].[vehicle]  WITH CHECK ADD  CONSTRAINT [CK_transport_vehicle_health] CHECK  (([vehicle_health]=N'CRITICAL' OR [vehicle_health]=N'NEEDS_SERVICE' OR [vehicle_health]=N'FAIR' OR [vehicle_health]=N'GOOD' OR [vehicle_health]=N'EXCELLENT'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_transport_vehicle_health')
BEGIN
    ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [CK_transport_vehicle_health]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_vehicle_route_code')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [CK_vehicle_route_code] CHECK  ((len(ltrim(rtrim([route_code])))>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_vehicle_route_code')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [CK_vehicle_route_code]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_vehicle_route_dates')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [CK_vehicle_route_dates] CHECK  (([effective_to] IS NULL OR [effective_to]>=[effective_from]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_vehicle_route_dates')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [CK_vehicle_route_dates]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_vehicle_route_name')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [CK_vehicle_route_name] CHECK  ((len(ltrim(rtrim([route_name])))>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_vehicle_route_name')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [CK_vehicle_route_name]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_vehicle_route_status')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [CK_vehicle_route_status] CHECK  (([status]=N'INACTIVE' OR [status]=N'ACTIVE'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_vehicle_route_status')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [CK_vehicle_route_status]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_vehicle_route_type')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route]  WITH CHECK ADD  CONSTRAINT [CK_vehicle_route_type] CHECK  (([route_type]=N'DROP' OR [route_type]=N'PICKUP'))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_vehicle_route_type')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route] CHECK CONSTRAINT [CK_vehicle_route_type]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_route_stop_name')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop]  WITH CHECK ADD  CONSTRAINT [CK_route_stop_name] CHECK  ((len(ltrim(rtrim([stop_name])))>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_route_stop_name')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] CHECK CONSTRAINT [CK_route_stop_name]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_route_stop_planned_times')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop]  WITH CHECK ADD  CONSTRAINT [CK_route_stop_planned_times] CHECK  (([planned_departure_time] IS NULL OR [planned_departure_time]>=[planned_arrival_time]))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_route_stop_planned_times')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] CHECK CONSTRAINT [CK_route_stop_planned_times]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_route_stop_sequence')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop]  WITH CHECK ADD  CONSTRAINT [CK_route_stop_sequence] CHECK  (([stop_sequence]>(0)))
END
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_route_stop_sequence')
BEGIN
    ALTER TABLE [transport_schema].[vehicle_route_stop] CHECK CONSTRAINT [CK_route_stop_sequence]
END
GO

/* ============================================================================= */
/* 2. OPERATIONAL & FILTERED PERFORMANCE INDEXES                                */
/* ============================================================================= */

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_vehicle_branch_status'
      AND object_id = OBJECT_ID(N'transport_schema.vehicle')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_vehicle_branch_status
        ON transport_schema.vehicle (school_id, branch_id, status, is_active)
        INCLUDE (vehicle_number, vehicle_name);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_transport_staff_mobile'
      AND object_id = OBJECT_ID(N'transport_schema.staff')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_transport_staff_mobile
        ON transport_schema.staff (branch_id, mobile_number)
        WHERE mobile_number IS NOT NULL AND is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_transport_staff_branch_status'
      AND object_id = OBJECT_ID(N'transport_schema.staff')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_transport_staff_branch_status
        ON transport_schema.staff (school_id, branch_id, staff_type, status, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_vehicle_route_active_open'
      AND object_id = OBJECT_ID(N'transport_schema.vehicle_route')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_vehicle_route_active_open
        ON transport_schema.vehicle_route (vehicle_id, route_code, route_type)
        WHERE effective_to IS NULL AND is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_vehicle_route_vehicle_status'
      AND object_id = OBJECT_ID(N'transport_schema.vehicle_route')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_vehicle_route_vehicle_status
        ON transport_schema.vehicle_route (vehicle_id, status, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_vehicle_route_branch_status'
      AND object_id = OBJECT_ID(N'transport_schema.vehicle_route')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_vehicle_route_branch_status
        ON transport_schema.vehicle_route (school_id, branch_id, status, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_trip_operational_schedule'
      AND object_id = OBJECT_ID(N'transport_schema.trip')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_trip_operational_schedule
        ON transport_schema.trip (vehicle_route_id, trip_date, trip_type, planned_start_time)
        WHERE is_active = 1 AND status <> N'CANCELLED';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_trip_route_date'
      AND object_id = OBJECT_ID(N'transport_schema.trip')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_trip_route_date
        ON transport_schema.trip (vehicle_route_id, trip_date, status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_trip_driver_date'
      AND object_id = OBJECT_ID(N'transport_schema.trip')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_trip_driver_date
        ON transport_schema.trip (driver_id, trip_date, status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_trip_vehicle_date'
      AND object_id = OBJECT_ID(N'transport_schema.trip')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_trip_vehicle_date
        ON transport_schema.trip (vehicle_id, trip_date, status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_trip_stop_trip_status'
      AND object_id = OBJECT_ID(N'transport_schema.trip_stop')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_trip_stop_trip_status
        ON transport_schema.trip_stop (trip_id, status);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_speed_measurement_trip_recorded'
      AND object_id = OBJECT_ID(N'transport_schema.speed_measurement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_speed_measurement_trip_recorded
        ON transport_schema.speed_measurement (trip_id, recorded_at);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_speed_measurement_vehicle_recorded'
      AND object_id = OBJECT_ID(N'transport_schema.speed_measurement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_speed_measurement_vehicle_recorded
        ON transport_schema.speed_measurement (vehicle_id, recorded_at);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_transport_assignment_active_student'
      AND object_id = OBJECT_ID(N'student_schema.transport_assignment')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_transport_assignment_active_student
        ON student_schema.transport_assignment (school_id, branch_id, student_id)
        WHERE is_active = 1 AND status = N'ACTIVE';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_transport_assignment_student_status'
      AND object_id = OBJECT_ID(N'student_schema.transport_assignment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_transport_assignment_student_status
        ON student_schema.transport_assignment (student_id, status, effective_from)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_transport_assignment_vehicle_route'
      AND object_id = OBJECT_ID(N'student_schema.transport_assignment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_transport_assignment_vehicle_route
        ON student_schema.transport_assignment (vehicle_route_id, status)
        INCLUDE (student_id, pickup_route_stop_id, drop_route_stop_id)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_transport_assignment_branch_student'
      AND object_id = OBJECT_ID(N'student_schema.transport_assignment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_transport_assignment_branch_student
        ON student_schema.transport_assignment (school_id, branch_id, student_id, status, effective_from)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_transport_change_request_student_status'
      AND object_id = OBJECT_ID(N'student_schema.transport_change_request')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_transport_change_request_student_status
        ON student_schema.transport_change_request (student_id, status, effective_date)
        INCLUDE (request_type, current_vehicle_route_id, requested_vehicle_route_id)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_transport_change_request_pending_branch'
      AND object_id = OBJECT_ID(N'student_schema.transport_change_request')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_transport_change_request_pending_branch
        ON student_schema.transport_change_request (branch_id, status, effective_date)
        WHERE is_active = 1 AND status = N'PENDING';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_transport_change_request_assignment'
      AND object_id = OBJECT_ID(N'student_schema.transport_change_request')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_transport_change_request_assignment
        ON student_schema.transport_change_request (transport_assignment_id)
        WHERE transport_assignment_id IS NOT NULL;
END;
GO

/* ============================================================================= */
/* 3. STORED PROCEDURE: transport_schema.usp_assign_student_transport          */
/* ============================================================================= */

/* 10. TRANSACTIONALLY SAFE VEHICLE CAPACITY ENFORCEMENT OPERATION            */
/* -------------------------------------------------------------------------- */

/*
    Procedure: transport_schema.usp_assign_student_transport
    Purpose:   Transactionally safe student transport assignment with optimistic/pessimistic
               locking on vehicle capacity and placement verification.

    Capacity Semantics:
    - If vehicle.capacity IS NULL, capacity is treated as unconstrained / open.
    - If vehicle.capacity IS NOT NULL (> 0), active overlapping student assignments are counted
      under UPDLOCK, HOLDLOCK to completely prevent race conditions and overbooking.
*/

CREATE OR ALTER PROCEDURE transport_schema.usp_assign_student_transport
    @school_id                   BIGINT,
    @branch_id                   BIGINT,
    @academic_year_id            BIGINT,
    @class_id                    BIGINT,
    @section_id                  BIGINT,
    @student_id                  BIGINT,
    @vehicle_route_id            BIGINT,
    @pickup_route_stop_id        BIGINT,
    @drop_route_stop_id          BIGINT,
    @estimated_pickup_time       TIME(0),
    @estimated_drop_time         TIME(0),
    @effective_from              DATE,
    @effective_to                DATE            = NULL,
    @user_id                     BIGINT,
    @new_transport_assignment_id  BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    -- 1. Identify vehicle and verify active route ownership under serialized locking
    DECLARE @vehicle_id BIGINT;
    DECLARE @vehicle_capacity INT;

    SELECT
        @vehicle_id        = vr.vehicle_id,
        @vehicle_capacity  = v.capacity
    FROM transport_schema.vehicle_route AS vr WITH (UPDLOCK, HOLDLOCK)
    INNER JOIN transport_schema.vehicle AS v WITH (UPDLOCK, HOLDLOCK)
        ON v.vehicle_id = vr.vehicle_id
       AND v.school_id = vr.school_id
       AND v.branch_id = vr.branch_id
    WHERE vr.vehicle_route_id = @vehicle_route_id
      AND vr.school_id = @school_id
      AND vr.branch_id = @branch_id
      AND vr.is_active = 1
      AND vr.status = N'ACTIVE'
      AND v.is_active = 1
      AND v.status = N'ACTIVE';

    IF @vehicle_id IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 52001, N'Active vehicle route not found or vehicle is inactive for the given school and branch.', 1;
    END;

    -- 2. Verify student placement in academic hierarchy
    IF NOT EXISTS (
        SELECT 1
        FROM student_schema.student WITH (HOLDLOCK)
        WHERE school_id = @school_id
          AND branch_id = @branch_id
          AND academic_year_id = @academic_year_id
          AND class_id = @class_id
          AND section_id = @section_id
          AND student_id = @student_id
          AND is_active = 1
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 52002, N'Student placement context does not match registered academic placement.', 1;
    END;

    -- 3. Verify route stops belong to route
    IF NOT EXISTS (
        SELECT 1 FROM transport_schema.vehicle_route_stop
        WHERE vehicle_route_id = @vehicle_route_id AND route_stop_id = @pickup_route_stop_id AND is_active = 1
    ) OR NOT EXISTS (
        SELECT 1 FROM transport_schema.vehicle_route_stop
        WHERE vehicle_route_id = @vehicle_route_id AND route_stop_id = @drop_route_stop_id AND is_active = 1
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 52003, N'Pickup or drop route stop does not belong to the selected vehicle route.', 1;
    END;

    -- 4. Capacity Enforcement (Section 15)
    -- If vehicle capacity is specified (> 0), count all concurrent active assignments on all routes of this vehicle.
    IF @vehicle_capacity IS NOT NULL
    BEGIN
        DECLARE @active_assignments_count INT;

        SELECT @active_assignments_count = COUNT(*)
        FROM student_schema.transport_assignment AS ta WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN transport_schema.vehicle_route AS vr
            ON vr.vehicle_route_id = ta.vehicle_route_id
        WHERE vr.vehicle_id = @vehicle_id
          AND ta.is_active = 1
          AND ta.status = N'ACTIVE'
          AND ta.student_id <> @student_id
          AND ta.effective_from <= ISNULL(@effective_to, '9999-12-31')
          AND (ta.effective_to IS NULL OR ta.effective_to >= @effective_from);

        IF @active_assignments_count >= @vehicle_capacity
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 52004, N'Vehicle capacity exceeded. No seats available on the vehicle for this route schedule.', 1;
        END;
    END;

    -- 5. Deactivate any existing active transport assignment for this student
    UPDATE student_schema.transport_assignment
    SET status = N'INACTIVE',
        is_active = 0,
        effective_to = DATEADD(DAY, -1, @effective_from),
        updated_at = SYSUTCDATETIME(),
        updated_by = @user_id
    WHERE school_id = @school_id
      AND branch_id = @branch_id
      AND student_id = @student_id
      AND status = N'ACTIVE'
      AND is_active = 1;

    -- 6. Insert new transport assignment
    INSERT INTO student_schema.transport_assignment
    (
        school_id,
        branch_id,
        academic_year_id,
        class_id,
        section_id,
        student_id,
        vehicle_route_id,
        pickup_route_stop_id,
        drop_route_stop_id,
        estimated_pickup_time,
        estimated_drop_time,
        effective_from,
        effective_to,
        status,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    VALUES
    (
        @school_id,
        @branch_id,
        @academic_year_id,
        @class_id,
        @section_id,
        @student_id,
        @vehicle_route_id,
        @pickup_route_stop_id,
        @drop_route_stop_id,
        @estimated_pickup_time,
        @estimated_drop_time,
        @effective_from,
        @effective_to,
        N'ACTIVE',
        1,
        SYSUTCDATETIME(),
        @user_id,
        SYSUTCDATETIME(),
        @user_id
    );

    SET @new_transport_assignment_id = SCOPE_IDENTITY();

    COMMIT TRANSACTION;
END;
GO

/* END INLINE MIGRATION: 015_transport.sql */

/* BEGIN INLINE MIGRATION: 016_finance.sql */
/* Module migration: 016_finance.sql */
/*
    ================================================================================
    THINKIGEN FINANCE DATABASE â€” MASTER SCHEMA
    ================================================================================

    MIGRATION STRATEGY:
    - Target Environment: SQL Server 2022+ / Azure SQL Database.
    - Scope: Institutional Finance Module (3-table authoritative architecture).
    - Data-Safety Strategy:
        1. Safely cleans up the deprecated 6-table / category-based finance models.
        2. Drops superseded draft objects containing legacy columns (e.g., net_amount, student_type).
        3. Deploys tables, constraints, composite scope keys, and operational indexes
           in dependency-safe order (Master -> Student Record -> Transactions).
        4. Completely idempotent for subsequent safe executions.

    APPROVED ARCHITECTURE (EXACTLY THREE TABLES):
      1. finance_schema.fee_structure_term       Class-level annual fee master & term due dates
      2. finance_schema.student_fee_record       Frozen annual financial state per student
      3. finance_schema.fee_payment_transaction  Unified immutable payment & refund transaction history

    CRITICAL BUSINESS RULES IMPLEMENTED:
      - Unified Residency: term1/2/3 residency_* fields snapshot hostel charges for HOSTELLER,
        transport charges for DAY_SCHOLAR with active transport, or 0 for DAY_SCHOLAR without transport.
      - Single Scholarship: Exactly one scholarship_amount column; subtracted from overall total_fee_amount.
      - Zero Net Amount: No column containing net_amount anywhere in the schema.
      - Transaction Types: PAYMENT and REFUND only (NO scholarship transaction type).
      - Controlled Statuses: PENDING / PARTIAL / PAID (+ NOT_APPLICABLE for non-applicable components).
      - Composite Scope Enforcement: Prevents cross-school, cross-branch, cross-year, or cross-class data drift.
      - Refund Lineage: Refund transactions must reference a valid parent payment.
      - Concurrency & Audit: Full rowversion and auditable created/updated fields on all tables.

    Rollback Order:
      DROP TABLE IF EXISTS finance_schema.fee_payment_transaction;
      DROP TABLE IF EXISTS finance_schema.student_fee_record;
      DROP TABLE IF EXISTS finance_schema.fee_structure_term;
    ================================================================================
*/

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* -------------------------------------------------------------------------- */
/* 1. SCHEMA CREATION                                                         */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'finance_schema')
    EXEC(N'CREATE SCHEMA finance_schema AUTHORIZATION dbo;');
GO

/* -------------------------------------------------------------------------- */
/* 2. SUPERSEDED OBJECT CLEANUP                                               */
/* -------------------------------------------------------------------------- */

/* Remove legacy six-table architecture objects if they exist */
IF OBJECT_ID(N'finance_schema.other_fee_payment_transaction', N'U') IS NOT NULL DROP TABLE finance_schema.other_fee_payment_transaction;
IF OBJECT_ID(N'finance_schema.term_fee_payment_transaction', N'U') IS NOT NULL DROP TABLE finance_schema.term_fee_payment_transaction;
IF OBJECT_ID(N'finance_schema.student_other_fee_record', N'U') IS NOT NULL DROP TABLE finance_schema.student_other_fee_record;
IF OBJECT_ID(N'finance_schema.student_term_fee_record', N'U') IS NOT NULL DROP TABLE finance_schema.student_term_fee_record;
IF OBJECT_ID(N'finance_schema.fee_structure_other', N'U') IS NOT NULL DROP TABLE finance_schema.fee_structure_other;

/* Remove superseded fee_structure_term if legacy category column exists */
IF COL_LENGTH(N'finance_schema.fee_structure_term', N'fee_category_code') IS NOT NULL
    DROP TABLE finance_schema.fee_structure_term;

/* Remove superseded student_fee_record and transactions if legacy forbidden columns exist */
IF COL_LENGTH(N'finance_schema.student_fee_record', N'total_net_amount') IS NOT NULL
    OR COL_LENGTH(N'finance_schema.student_fee_record', N'student_type') IS NOT NULL
BEGIN
    IF OBJECT_ID(N'finance_schema.fee_payment_transaction', N'U') IS NOT NULL
        DROP TABLE finance_schema.fee_payment_transaction;
    DROP TABLE finance_schema.student_fee_record;
END;

/* Align fee_payment_transaction column name to 'status' if previously deployed with 'transaction_status' */
IF COL_LENGTH(N'finance_schema.fee_payment_transaction', N'transaction_status') IS NOT NULL
   AND COL_LENGTH(N'finance_schema.fee_payment_transaction', N'status') IS NULL
BEGIN
    -- 1. Drop CHECK constraint that references transaction_status
    IF OBJECT_ID(N'finance_schema.CK_fee_payment_transaction_status', N'C') IS NOT NULL
        ALTER TABLE finance_schema.fee_payment_transaction DROP CONSTRAINT CK_fee_payment_transaction_status;

    -- 2. Drop DEFAULT constraint that references transaction_status if present
    DECLARE @df_sql NVARCHAR(500);
    SELECT @df_sql = N'ALTER TABLE finance_schema.fee_payment_transaction DROP CONSTRAINT ' + QUOTENAME(d.name) + N';'
    FROM sys.default_constraints d 
    JOIN sys.columns c ON c.object_id = d.parent_object_id AND c.column_id = d.parent_column_id
    WHERE d.parent_object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
      AND c.name = N'transaction_status';

    IF @df_sql IS NOT NULL
        EXEC sp_executesql @df_sql;

    -- 3. Rename the column to 'status'
    EXEC sp_rename N'finance_schema.fee_payment_transaction.transaction_status', N'status', N'COLUMN';

    -- 4. Re-create DEFAULT and CHECK constraints on 'status' via dynamic SQL (avoids compile-time binding error Msg 207)
    EXEC(N'ALTER TABLE finance_schema.fee_payment_transaction ADD CONSTRAINT DF_fee_payment_transaction_status DEFAULT (N''SUCCESS'') FOR status;');
    EXEC(N'ALTER TABLE finance_schema.fee_payment_transaction ADD CONSTRAINT CK_fee_payment_transaction_status CHECK (status IN (N''PENDING'', N''SUCCESS'', N''FAILED'', N''CANCELLED''));');
END;
GO

/* -------------------------------------------------------------------------- */
/* 3. TABLE 1: finance_schema.fee_structure_term                              */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'finance_schema.fee_structure_term', N'U') IS NULL
BEGIN
    CREATE TABLE finance_schema.fee_structure_term
    (
        fee_structure_term_id BIGINT IDENTITY(1,1) NOT NULL,
        school_id             BIGINT NOT NULL,
        branch_id             BIGINT NOT NULL,
        academic_year_id      BIGINT NOT NULL,
        class_id              BIGINT NOT NULL,
        total_amount          DECIMAL(12,2) NOT NULL,
        term1_amount          DECIMAL(12,2) NOT NULL,
        term1_due_date        DATE NOT NULL,
        term2_amount          DECIMAL(12,2) NOT NULL,
        term2_due_date        DATE NOT NULL,
        term3_amount          DECIMAL(12,2) NOT NULL,
        term3_due_date        DATE NOT NULL,
        status                NVARCHAR(20) NOT NULL CONSTRAINT DF_fee_structure_term_status DEFAULT (N'DRAFT'),
        is_active             BIT NOT NULL CONSTRAINT DF_fee_structure_term_is_active DEFAULT (1),
        created_at            DATETIME2(0) NOT NULL CONSTRAINT DF_fee_structure_term_created_at DEFAULT (SYSUTCDATETIME()),
        created_by            BIGINT NOT NULL,
        updated_at            DATETIME2(0) NULL,
        updated_by            BIGINT NULL,
        row_version           ROWVERSION NOT NULL,

        CONSTRAINT PK_fee_structure_term PRIMARY KEY CLUSTERED (fee_structure_term_id),
        CONSTRAINT UQ_fee_structure_term_scope UNIQUE NONCLUSTERED (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id),

        /* Financial value integrity */
        CONSTRAINT CK_fee_structure_term_amounts CHECK (
            total_amount >= 0 AND term1_amount >= 0 AND term2_amount >= 0 AND term3_amount >= 0
            AND total_amount = term1_amount + term2_amount + term3_amount
        ),
        CONSTRAINT CK_fee_structure_term_status CHECK (status IN (N'DRAFT', N'ACTIVE', N'INACTIVE')),
        CONSTRAINT CK_fee_structure_term_due_dates CHECK (term2_due_date >= term1_due_date AND term3_due_date >= term2_due_date),

        /* Institutional Master Relationships */
        CONSTRAINT FK_fee_structure_term_school FOREIGN KEY (school_id)
            REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_fee_structure_term_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_fee_structure_term_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_fee_structure_term_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_fee_structure_term_created_by FOREIGN KEY (created_by)
            REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_fee_structure_term_updated_by FOREIGN KEY (updated_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* 4. TABLE 2: finance_schema.student_fee_record                              */
/* -------------------------------------------------------------------------- */

/* 4A. MIGRATION OF EXISTING student_fee_record TO UNIFIED RESIDENCY FIELDS */
IF OBJECT_ID(N'finance_schema.student_fee_record', N'U') IS NOT NULL
   AND COL_LENGTH(N'finance_schema.student_fee_record', N'term1_hostel_amount') IS NOT NULL
BEGIN
    BEGIN TRANSACTION;

    -- 1. Drop obsolete check constraints referencing hostel/transport/totals before modifying data
    IF OBJECT_ID(N'finance_schema.CK_student_fee_record_hostel_residency', N'C') IS NOT NULL
        ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT CK_student_fee_record_hostel_residency;
    IF OBJECT_ID(N'finance_schema.CK_student_fee_record_transport', N'C') IS NOT NULL
        ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT CK_student_fee_record_transport;
    IF OBJECT_ID(N'finance_schema.CK_student_fee_record_term_totals', N'C') IS NOT NULL
        ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT CK_student_fee_record_term_totals;
    IF OBJECT_ID(N'finance_schema.CK_student_fee_record_overall_totals', N'C') IS NOT NULL
        ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT CK_student_fee_record_overall_totals;

    -- 2. Add new unified residency columns if not present
    IF COL_LENGTH(N'finance_schema.student_fee_record', N'term1_residency_amount') IS NULL
    BEGIN
        ALTER TABLE finance_schema.student_fee_record ADD
            term1_residency_amount  DECIMAL(12,2) NULL,
            term1_residency_paid    DECIMAL(12,2) NULL,
            term1_residency_balance DECIMAL(12,2) NULL,
            term1_residency_status  NVARCHAR(20) NULL,
            term2_residency_amount  DECIMAL(12,2) NULL,
            term2_residency_paid    DECIMAL(12,2) NULL,
            term2_residency_balance DECIMAL(12,2) NULL,
            term2_residency_status  NVARCHAR(20) NULL,
            term3_residency_amount  DECIMAL(12,2) NULL,
            term3_residency_paid    DECIMAL(12,2) NULL,
            term3_residency_balance DECIMAL(12,2) NULL,
            term3_residency_status  NVARCHAR(20) NULL;
    END;

    -- 2. Migrate existing values based on residency_type:
    --    HOSTELLER: residency_* <- hostel_*
    --    DAY_SCHOLAR: residency_* <- transport_* when applicable, otherwise 0
    EXEC(N'
    UPDATE finance_schema.student_fee_record
    SET
        term1_residency_amount = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term1_hostel_amount, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term1_transport_amount, 0)
            ELSE 0 END,
        term1_residency_paid = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term1_hostel_paid, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term1_transport_paid, 0)
            ELSE 0 END,
        term2_residency_amount = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term2_hostel_amount, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term2_transport_amount, 0)
            ELSE 0 END,
        term2_residency_paid = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term2_hostel_paid, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term2_transport_paid, 0)
            ELSE 0 END,
        term3_residency_amount = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term3_hostel_amount, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term3_transport_amount, 0)
            ELSE 0 END,
        term3_residency_paid = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term3_hostel_paid, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term3_transport_paid, 0)
            ELSE 0 END;
    ');

    -- 3. Recalculate residency balances & status
    EXEC(N'
    UPDATE finance_schema.student_fee_record
    SET
        term1_residency_balance = term1_residency_amount - term1_residency_paid,
        term1_residency_status = CASE 
            WHEN term1_residency_amount = 0 AND term1_residency_paid = 0 THEN N''NOT_APPLICABLE''
            WHEN term1_residency_amount > 0 AND term1_residency_paid = 0 THEN N''PENDING''
            WHEN term1_residency_paid > 0 AND term1_residency_paid < term1_residency_amount THEN N''PARTIAL''
            ELSE N''PAID'' END,
        term2_residency_balance = term2_residency_amount - term2_residency_paid,
        term2_residency_status = CASE 
            WHEN term2_residency_amount = 0 AND term2_residency_paid = 0 THEN N''NOT_APPLICABLE''
            WHEN term2_residency_amount > 0 AND term2_residency_paid = 0 THEN N''PENDING''
            WHEN term2_residency_paid > 0 AND term2_residency_paid < term2_residency_amount THEN N''PARTIAL''
            ELSE N''PAID'' END,
        term3_residency_balance = term3_residency_amount - term3_residency_paid,
        term3_residency_status = CASE 
            WHEN term3_residency_amount = 0 AND term3_residency_paid = 0 THEN N''NOT_APPLICABLE''
            WHEN term3_residency_amount > 0 AND term3_residency_paid = 0 THEN N''PENDING''
            WHEN term3_residency_paid > 0 AND term3_residency_paid < term3_residency_amount THEN N''PARTIAL''
            ELSE N''PAID'' END;
    ');

    -- 4. Recalculate term totals
    EXEC(N'
    UPDATE finance_schema.student_fee_record
    SET
        term1_total_amount = term1_tuition_amount + term1_residency_amount,
        term1_total_paid = term1_tuition_paid + term1_residency_paid,
        term1_total_balance = (term1_tuition_amount + term1_residency_amount) - (term1_tuition_paid + term1_residency_paid),
        term1_status = CASE 
            WHEN (term1_tuition_paid + term1_residency_paid) = 0 AND (term1_tuition_amount + term1_residency_amount) > 0 THEN N''PENDING''
            WHEN (term1_tuition_paid + term1_residency_paid) > 0 AND (term1_tuition_paid + term1_residency_paid) < (term1_tuition_amount + term1_residency_amount) THEN N''PARTIAL''
            ELSE N''PAID'' END,
        term2_total_amount = term2_tuition_amount + term2_residency_amount,
        term2_total_paid = term2_tuition_paid + term2_residency_paid,
        term2_total_balance = (term2_tuition_amount + term2_residency_amount) - (term2_tuition_paid + term2_residency_paid),
        term2_status = CASE 
            WHEN (term2_tuition_paid + term2_residency_paid) = 0 AND (term2_tuition_amount + term2_residency_amount) > 0 THEN N''PENDING''
            WHEN (term2_tuition_paid + term2_residency_paid) > 0 AND (term2_tuition_paid + term2_residency_paid) < (term2_tuition_amount + term2_residency_amount) THEN N''PARTIAL''
            ELSE N''PAID'' END,
        term3_total_amount = term3_tuition_amount + term3_residency_amount,
        term3_total_paid = term3_tuition_paid + term3_residency_paid,
        term3_total_balance = (term3_tuition_amount + term3_residency_amount) - (term3_tuition_paid + term3_residency_paid),
        term3_status = CASE 
            WHEN (term3_tuition_paid + term3_residency_paid) = 0 AND (term3_tuition_amount + term3_residency_amount) > 0 THEN N''PENDING''
            WHEN (term3_tuition_paid + term3_residency_paid) > 0 AND (term3_tuition_paid + term3_residency_paid) < (term3_tuition_amount + term3_residency_amount) THEN N''PARTIAL''
            ELSE N''PAID'' END;
    ');

    -- 5. Recalculate overall totals
    EXEC(N'
    UPDATE finance_schema.student_fee_record
    SET
        total_fee_amount = (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount,
        total_paid_amount = term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid,
        total_balance_amount = ((term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount) - (term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid),
        overall_status = CASE 
            WHEN (term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid) = 0 AND ((term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount) > 0 THEN N''PENDING''
            WHEN (term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid) > 0 AND (term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid) < ((term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount) THEN N''PARTIAL''
            ELSE N''PAID'' END;
    ');

    -- 6. Enforce NOT NULL on residency columns
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term1_residency_amount DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term1_residency_paid DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term1_residency_balance DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term1_residency_status NVARCHAR(20) NOT NULL;

    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term2_residency_amount DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term2_residency_paid DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term2_residency_balance DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term2_residency_status NVARCHAR(20) NOT NULL;

    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term3_residency_amount DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term3_residency_paid DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term3_residency_balance DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term3_residency_status NVARCHAR(20) NOT NULL;

    -- Add default constraints on residency columns if not present
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term1_residency_amount', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term1_residency_amount DEFAULT (0) FOR term1_residency_amount;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term1_residency_paid', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term1_residency_paid DEFAULT (0) FOR term1_residency_paid;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term1_residency_balance', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term1_residency_balance DEFAULT (0) FOR term1_residency_balance;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term1_residency_status', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term1_residency_status DEFAULT (N'NOT_APPLICABLE') FOR term1_residency_status;

    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term2_residency_amount', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term2_residency_amount DEFAULT (0) FOR term2_residency_amount;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term2_residency_paid', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term2_residency_paid DEFAULT (0) FOR term2_residency_paid;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term2_residency_balance', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term2_residency_balance DEFAULT (0) FOR term2_residency_balance;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term2_residency_status', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term2_residency_status DEFAULT (N'NOT_APPLICABLE') FOR term2_residency_status;

    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term3_residency_amount', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term3_residency_amount DEFAULT (0) FOR term3_residency_amount;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term3_residency_paid', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term3_residency_paid DEFAULT (0) FOR term3_residency_paid;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term3_residency_balance', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term3_residency_balance DEFAULT (0) FOR term3_residency_balance;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term3_residency_status', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term3_residency_status DEFAULT (N'NOT_APPLICABLE') FOR term3_residency_status;

    -- 7. Drop default constraints on old columns
    DECLARE @drop_df NVARCHAR(MAX) = N'';
    SELECT @drop_df = @drop_df + N'ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT ' + QUOTENAME(d.name) + N';' + CHAR(13)
    FROM sys.default_constraints d
    JOIN sys.columns c ON c.object_id = d.parent_object_id AND c.column_id = d.parent_column_id
    WHERE d.parent_object_id = OBJECT_ID(N'finance_schema.student_fee_record')
      AND c.name IN (
        N'term1_hostel_amount', N'term1_hostel_paid', N'term1_hostel_balance', N'term1_hostel_status',
        N'term1_transport_amount', N'term1_transport_paid', N'term1_transport_balance', N'term1_transport_status',
        N'term2_hostel_amount', N'term2_hostel_paid', N'term2_hostel_balance', N'term2_hostel_status',
        N'term2_transport_amount', N'term2_transport_paid', N'term2_transport_balance', N'term2_transport_status',
        N'term3_hostel_amount', N'term3_hostel_paid', N'term3_hostel_balance', N'term3_hostel_status',
        N'term3_transport_amount', N'term3_transport_paid', N'term3_transport_balance', N'term3_transport_status'
      );
    IF @drop_df <> N'' EXEC sp_executesql @drop_df;

    -- 8. Drop the 24 obsolete hostel/transport columns
    ALTER TABLE finance_schema.student_fee_record DROP COLUMN
        term1_hostel_amount, term1_hostel_paid, term1_hostel_balance, term1_hostel_status,
        term1_transport_amount, term1_transport_paid, term1_transport_balance, term1_transport_status,
        term2_hostel_amount, term2_hostel_paid, term2_hostel_balance, term2_hostel_status,
        term2_transport_amount, term2_transport_paid, term2_transport_balance, term2_transport_status,
        term3_hostel_amount, term3_hostel_paid, term3_hostel_balance, term3_hostel_status,
        term3_transport_amount, term3_transport_paid, term3_transport_balance, term3_transport_status;

    -- 9. Recreate updated check constraints via dynamic SQL
    EXEC(N'
    ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT CK_student_fee_record_residency CHECK (
        term1_residency_amount >= 0 AND term1_residency_paid >= 0 AND term1_residency_balance >= 0
        AND term1_residency_paid <= term1_residency_amount
        AND term1_residency_balance = term1_residency_amount - term1_residency_paid
        AND term1_residency_status IN (N''NOT_APPLICABLE'', N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term1_residency_amount = 0 AND term1_residency_paid = 0 AND term1_residency_status = N''NOT_APPLICABLE'')
            OR (term1_residency_amount > 0 AND term1_residency_paid = 0 AND term1_residency_status = N''PENDING'')
            OR (term1_residency_paid > 0 AND term1_residency_paid < term1_residency_amount AND term1_residency_status = N''PARTIAL'')
            OR (term1_residency_paid = term1_residency_amount AND term1_residency_amount > 0 AND term1_residency_status = N''PAID'')
        )
        AND term2_residency_amount >= 0 AND term2_residency_paid >= 0 AND term2_residency_balance >= 0
        AND term2_residency_paid <= term2_residency_amount
        AND term2_residency_balance = term2_residency_amount - term2_residency_paid
        AND term2_residency_status IN (N''NOT_APPLICABLE'', N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term2_residency_amount = 0 AND term2_residency_paid = 0 AND term2_residency_status = N''NOT_APPLICABLE'')
            OR (term2_residency_amount > 0 AND term2_residency_paid = 0 AND term2_residency_status = N''PENDING'')
            OR (term2_residency_paid > 0 AND term2_residency_paid < term2_residency_amount AND term2_residency_status = N''PARTIAL'')
            OR (term2_residency_paid = term2_residency_amount AND term2_residency_amount > 0 AND term2_residency_status = N''PAID'')
        )
        AND term3_residency_amount >= 0 AND term3_residency_paid >= 0 AND term3_residency_balance >= 0
        AND term3_residency_paid <= term3_residency_amount
        AND term3_residency_balance = term3_residency_amount - term3_residency_paid
        AND term3_residency_status IN (N''NOT_APPLICABLE'', N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term3_residency_amount = 0 AND term3_residency_paid = 0 AND term3_residency_status = N''NOT_APPLICABLE'')
            OR (term3_residency_amount > 0 AND term3_residency_paid = 0 AND term3_residency_status = N''PENDING'')
            OR (term3_residency_paid > 0 AND term3_residency_paid < term3_residency_amount AND term3_residency_status = N''PARTIAL'')
            OR (term3_residency_paid = term3_residency_amount AND term3_residency_amount > 0 AND term3_residency_status = N''PAID'')
        )
    );
    ');

    EXEC(N'
    ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT CK_student_fee_record_term_totals CHECK (
        term1_total_amount = term1_tuition_amount + term1_residency_amount
        AND term1_total_paid = term1_tuition_paid + term1_residency_paid
        AND term1_total_balance = term1_total_amount - term1_total_paid
        AND term1_total_amount >= 0 AND term1_total_paid >= 0 AND term1_total_balance >= 0
        AND term1_total_paid <= term1_total_amount
        AND term1_status IN (N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term1_status = N''PENDING'' AND term1_total_paid = 0 AND term1_total_amount > 0)
            OR (term1_status = N''PARTIAL'' AND term1_total_paid > 0 AND term1_total_paid < term1_total_amount)
            OR (term1_status = N''PAID'' AND term1_total_paid = term1_total_amount)
        )
        AND term2_total_amount = term2_tuition_amount + term2_residency_amount
        AND term2_total_paid = term2_tuition_paid + term2_residency_paid
        AND term2_total_balance = term2_total_amount - term2_total_paid
        AND term2_total_amount >= 0 AND term2_total_paid >= 0 AND term2_total_balance >= 0
        AND term2_total_paid <= term2_total_amount
        AND term2_status IN (N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term2_status = N''PENDING'' AND term2_total_paid = 0 AND term2_total_amount > 0)
            OR (term2_status = N''PARTIAL'' AND term2_total_paid > 0 AND term2_total_paid < term2_total_amount)
            OR (term2_status = N''PAID'' AND term2_total_paid = term2_total_amount)
        )
        AND term3_total_amount = term3_tuition_amount + term3_residency_amount
        AND term3_total_paid = term3_tuition_paid + term3_residency_paid
        AND term3_total_balance = term3_total_amount - term3_total_paid
        AND term3_total_amount >= 0 AND term3_total_paid >= 0 AND term3_total_balance >= 0
        AND term3_total_paid <= term3_total_amount
        AND term3_status IN (N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term3_status = N''PENDING'' AND term3_total_paid = 0 AND term3_total_amount > 0)
            OR (term3_status = N''PARTIAL'' AND term3_total_paid > 0 AND term3_total_paid < term3_total_amount)
            OR (term3_status = N''PAID'' AND term3_total_paid = term3_total_amount)
        )
    );
    ');

    EXEC(N'
    ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT CK_student_fee_record_overall_totals CHECK (
        total_fee_amount = (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount
        AND total_paid_amount = term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid
        AND scholarship_amount >= 0
        AND scholarship_amount <= (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount)
        AND total_paid_amount <= total_fee_amount
        AND total_balance_amount = total_fee_amount - total_paid_amount
        AND total_fee_amount >= 0 AND total_paid_amount >= 0 AND total_balance_amount >= 0
        AND overall_status IN (N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (overall_status = N''PENDING'' AND total_paid_amount = 0 AND total_fee_amount > 0)
            OR (overall_status = N''PARTIAL'' AND total_paid_amount > 0 AND total_paid_amount < total_fee_amount)
            OR (overall_status = N''PAID'' AND total_paid_amount = total_fee_amount)
        )
    );
    ');

    COMMIT TRANSACTION;
END;
GO

/* 4B. CREATE TABLE IF NOT EXISTS */
IF OBJECT_ID(N'finance_schema.student_fee_record', N'U') IS NULL
BEGIN
    CREATE TABLE finance_schema.student_fee_record
    (
        student_fee_record_id   BIGINT IDENTITY(1,1) NOT NULL,
        fee_structure_term_id   BIGINT NOT NULL,
        school_id               BIGINT NOT NULL,
        branch_id               BIGINT NOT NULL,
        academic_year_id        BIGINT NOT NULL,
        class_id                BIGINT NOT NULL,
        section_id              BIGINT NOT NULL,
        student_id              BIGINT NOT NULL,
        residency_type          NVARCHAR(20) NOT NULL,

        /* Term 1 Financial State */
        term1_tuition_amount    DECIMAL(12,2) NOT NULL,
        term1_tuition_paid      DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_tuition_paid DEFAULT (0),
        term1_tuition_balance   DECIMAL(12,2) NOT NULL,
        term1_tuition_status    NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term1_tuition_status DEFAULT (N'PENDING'),
        term1_residency_amount  DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_residency_amount DEFAULT (0),
        term1_residency_paid    DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_residency_paid DEFAULT (0),
        term1_residency_balance DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_residency_balance DEFAULT (0),
        term1_residency_status  NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term1_residency_status DEFAULT (N'NOT_APPLICABLE'),
        term1_total_amount      DECIMAL(12,2) NOT NULL,
        term1_total_paid        DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_total_paid DEFAULT (0),
        term1_total_balance     DECIMAL(12,2) NOT NULL,
        term1_status            NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term1_status DEFAULT (N'PENDING'),

        /* Term 2 Financial State */
        term2_tuition_amount    DECIMAL(12,2) NOT NULL,
        term2_tuition_paid      DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_tuition_paid DEFAULT (0),
        term2_tuition_balance   DECIMAL(12,2) NOT NULL,
        term2_tuition_status    NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term2_tuition_status DEFAULT (N'PENDING'),
        term2_residency_amount  DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_residency_amount DEFAULT (0),
        term2_residency_paid    DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_residency_paid DEFAULT (0),
        term2_residency_balance DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_residency_balance DEFAULT (0),
        term2_residency_status  NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term2_residency_status DEFAULT (N'NOT_APPLICABLE'),
        term2_total_amount      DECIMAL(12,2) NOT NULL,
        term2_total_paid        DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_total_paid DEFAULT (0),
        term2_total_balance     DECIMAL(12,2) NOT NULL,
        term2_status            NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term2_status DEFAULT (N'PENDING'),

        /* Term 3 Financial State */
        term3_tuition_amount    DECIMAL(12,2) NOT NULL,
        term3_tuition_paid      DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_tuition_paid DEFAULT (0),
        term3_tuition_balance   DECIMAL(12,2) NOT NULL,
        term3_tuition_status    NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term3_tuition_status DEFAULT (N'PENDING'),
        term3_residency_amount  DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_residency_amount DEFAULT (0),
        term3_residency_paid    DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_residency_paid DEFAULT (0),
        term3_residency_balance DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_residency_balance DEFAULT (0),
        term3_residency_status  NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term3_residency_status DEFAULT (N'NOT_APPLICABLE'),
        term3_total_amount      DECIMAL(12,2) NOT NULL,
        term3_total_paid        DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_total_paid DEFAULT (0),
        term3_total_balance     DECIMAL(12,2) NOT NULL,
        term3_status            NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term3_status DEFAULT (N'PENDING'),

        /* Other Fee Financial State */
        other_fee_amount        DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_other_amount DEFAULT (0),
        other_fee_paid          DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_other_paid DEFAULT (0),
        other_fee_balance       DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_other_balance DEFAULT (0),
        other_fee_status        NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_other_status DEFAULT (N'NOT_APPLICABLE'),

        /* Overall Financial Totals & Single Scholarship Column */
        scholarship_amount      DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_scholarship_amount DEFAULT (0),
        total_fee_amount        DECIMAL(12,2) NOT NULL,
        total_paid_amount       DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_total_paid_amount DEFAULT (0),
        total_balance_amount    DECIMAL(12,2) NOT NULL,
        overall_status          NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_overall_status DEFAULT (N'PENDING'),

        /* Concurrency & Audit */
        is_active               BIT NOT NULL CONSTRAINT DF_student_fee_record_is_active DEFAULT (1),
        created_at              DATETIME2(0) NOT NULL CONSTRAINT DF_student_fee_record_created_at DEFAULT (SYSUTCDATETIME()),
        created_by              BIGINT NOT NULL,
        updated_at              DATETIME2(0) NULL,
        updated_by              BIGINT NULL,
        row_version             ROWVERSION NOT NULL,

        /* Primary & Unique Scope Constraints */
        CONSTRAINT PK_student_fee_record PRIMARY KEY CLUSTERED (student_fee_record_id),
        CONSTRAINT UQ_student_fee_record_scope UNIQUE NONCLUSTERED (school_id, branch_id, academic_year_id, student_id),
        CONSTRAINT UQ_student_fee_record_hierarchy UNIQUE NONCLUSTERED (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id),

        /* Residency Type Validation */
        CONSTRAINT CK_student_fee_record_residency_type CHECK (residency_type IN (N'DAY_SCHOLAR', N'HOSTELLER')),

        /* Residency Component Integrity */
        CONSTRAINT CK_student_fee_record_residency CHECK (
            term1_residency_amount >= 0 AND term1_residency_paid >= 0 AND term1_residency_balance >= 0
            AND term1_residency_paid <= term1_residency_amount
            AND term1_residency_balance = term1_residency_amount - term1_residency_paid
            AND term1_residency_status IN (N'NOT_APPLICABLE', N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term1_residency_amount = 0 AND term1_residency_paid = 0 AND term1_residency_status = N'NOT_APPLICABLE')
                OR (term1_residency_amount > 0 AND term1_residency_paid = 0 AND term1_residency_status = N'PENDING')
                OR (term1_residency_paid > 0 AND term1_residency_paid < term1_residency_amount AND term1_residency_status = N'PARTIAL')
                OR (term1_residency_paid = term1_residency_amount AND term1_residency_amount > 0 AND term1_residency_status = N'PAID')
            )
            AND term2_residency_amount >= 0 AND term2_residency_paid >= 0 AND term2_residency_balance >= 0
            AND term2_residency_paid <= term2_residency_amount
            AND term2_residency_balance = term2_residency_amount - term2_residency_paid
            AND term2_residency_status IN (N'NOT_APPLICABLE', N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term2_residency_amount = 0 AND term2_residency_paid = 0 AND term2_residency_status = N'NOT_APPLICABLE')
                OR (term2_residency_amount > 0 AND term2_residency_paid = 0 AND term2_residency_status = N'PENDING')
                OR (term2_residency_paid > 0 AND term2_residency_paid < term2_residency_amount AND term2_residency_status = N'PARTIAL')
                OR (term2_residency_paid = term2_residency_amount AND term2_residency_amount > 0 AND term2_residency_status = N'PAID')
            )
            AND term3_residency_amount >= 0 AND term3_residency_paid >= 0 AND term3_residency_balance >= 0
            AND term3_residency_paid <= term3_residency_amount
            AND term3_residency_balance = term3_residency_amount - term3_residency_paid
            AND term3_residency_status IN (N'NOT_APPLICABLE', N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term3_residency_amount = 0 AND term3_residency_paid = 0 AND term3_residency_status = N'NOT_APPLICABLE')
                OR (term3_residency_amount > 0 AND term3_residency_paid = 0 AND term3_residency_status = N'PENDING')
                OR (term3_residency_paid > 0 AND term3_residency_paid < term3_residency_amount AND term3_residency_status = N'PARTIAL')
                OR (term3_residency_paid = term3_residency_amount AND term3_residency_amount > 0 AND term3_residency_status = N'PAID')
            )
        ),

        /* Tuition Component Integrity */
        CONSTRAINT CK_student_fee_record_tuition CHECK (
            term1_tuition_amount >= 0 AND term1_tuition_paid >= 0 AND term1_tuition_balance >= 0
            AND term1_tuition_paid <= term1_tuition_amount
            AND term1_tuition_balance = term1_tuition_amount - term1_tuition_paid
            AND term1_tuition_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term1_tuition_status = N'PENDING' AND term1_tuition_paid = 0 AND term1_tuition_amount > 0)
                OR (term1_tuition_status = N'PARTIAL' AND term1_tuition_paid > 0 AND term1_tuition_paid < term1_tuition_amount)
                OR (term1_tuition_status = N'PAID' AND term1_tuition_paid = term1_tuition_amount)
            )
            AND term2_tuition_amount >= 0 AND term2_tuition_paid >= 0 AND term2_tuition_balance >= 0
            AND term2_tuition_paid <= term2_tuition_amount
            AND term2_tuition_balance = term2_tuition_amount - term2_tuition_paid
            AND term2_tuition_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term2_tuition_status = N'PENDING' AND term2_tuition_paid = 0 AND term2_tuition_amount > 0)
                OR (term2_tuition_status = N'PARTIAL' AND term2_tuition_paid > 0 AND term2_tuition_paid < term2_tuition_amount)
                OR (term2_tuition_status = N'PAID' AND term2_tuition_paid = term2_tuition_amount)
            )
            AND term3_tuition_amount >= 0 AND term3_tuition_paid >= 0 AND term3_tuition_balance >= 0
            AND term3_tuition_paid <= term3_tuition_amount
            AND term3_tuition_balance = term3_tuition_amount - term3_tuition_paid
            AND term3_tuition_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term3_tuition_status = N'PENDING' AND term3_tuition_paid = 0 AND term3_tuition_amount > 0)
                OR (term3_tuition_status = N'PARTIAL' AND term3_tuition_paid > 0 AND term3_tuition_paid < term3_tuition_amount)
                OR (term3_tuition_status = N'PAID' AND term3_tuition_paid = term3_tuition_amount)
            )
        ),

        /* Other Fee Component Integrity */
        CONSTRAINT CK_student_fee_record_other_fee CHECK (
            other_fee_amount >= 0 AND other_fee_paid >= 0 AND other_fee_balance >= 0
            AND other_fee_paid <= other_fee_amount
            AND other_fee_balance = other_fee_amount - other_fee_paid
            AND (
                (other_fee_status = N'NOT_APPLICABLE' AND other_fee_amount = 0 AND other_fee_paid = 0 AND other_fee_balance = 0)
                OR (other_fee_status = N'PENDING' AND other_fee_paid = 0 AND other_fee_amount > 0)
                OR (other_fee_status = N'PARTIAL' AND other_fee_paid > 0 AND other_fee_paid < other_fee_amount)
                OR (other_fee_status = N'PAID' AND other_fee_paid = other_fee_amount)
            )
        ),

        /* Term Totals Reconciliation */
        CONSTRAINT CK_student_fee_record_term_totals CHECK (
            term1_total_amount = term1_tuition_amount + term1_residency_amount
            AND term1_total_paid = term1_tuition_paid + term1_residency_paid
            AND term1_total_balance = term1_total_amount - term1_total_paid
            AND term1_total_amount >= 0 AND term1_total_paid >= 0 AND term1_total_balance >= 0
            AND term1_total_paid <= term1_total_amount
            AND term1_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term1_status = N'PENDING' AND term1_total_paid = 0 AND term1_total_amount > 0)
                OR (term1_status = N'PARTIAL' AND term1_total_paid > 0 AND term1_total_paid < term1_total_amount)
                OR (term1_status = N'PAID' AND term1_total_paid = term1_total_amount)
            )
            AND term2_total_amount = term2_tuition_amount + term2_residency_amount
            AND term2_total_paid = term2_tuition_paid + term2_residency_paid
            AND term2_total_balance = term2_total_amount - term2_total_paid
            AND term2_total_amount >= 0 AND term2_total_paid >= 0 AND term2_total_balance >= 0
            AND term2_total_paid <= term2_total_amount
            AND term2_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term2_status = N'PENDING' AND term2_total_paid = 0 AND term2_total_amount > 0)
                OR (term2_status = N'PARTIAL' AND term2_total_paid > 0 AND term2_total_paid < term2_total_amount)
                OR (term2_status = N'PAID' AND term2_total_paid = term2_total_amount)
            )
            AND term3_total_amount = term3_tuition_amount + term3_residency_amount
            AND term3_total_paid = term3_tuition_paid + term3_residency_paid
            AND term3_total_balance = term3_total_amount - term3_total_paid
            AND term3_total_amount >= 0 AND term3_total_paid >= 0 AND term3_total_balance >= 0
            AND term3_total_paid <= term3_total_amount
            AND term3_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term3_status = N'PENDING' AND term3_total_paid = 0 AND term3_total_amount > 0)
                OR (term3_status = N'PARTIAL' AND term3_total_paid > 0 AND term3_total_paid < term3_total_amount)
                OR (term3_status = N'PAID' AND term3_total_paid = term3_total_amount)
            )
        ),

        /* Overall Financial Totals Reconciliation */
        CONSTRAINT CK_student_fee_record_overall_totals CHECK (
            total_fee_amount = (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount
            AND total_paid_amount = term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid
            AND scholarship_amount >= 0
            AND scholarship_amount <= (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount)
            AND total_paid_amount <= total_fee_amount
            AND total_balance_amount = total_fee_amount - total_paid_amount
            AND total_fee_amount >= 0 AND total_paid_amount >= 0 AND total_balance_amount >= 0
            AND overall_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (overall_status = N'PENDING' AND total_paid_amount = 0 AND total_fee_amount > 0)
                OR (overall_status = N'PARTIAL' AND total_paid_amount > 0 AND total_paid_amount < total_fee_amount)
                OR (overall_status = N'PAID' AND total_paid_amount = total_fee_amount)
            )
        ),

        /* Composite Scope FK to Fee Structure Term */
        CONSTRAINT FK_student_fee_record_structure FOREIGN KEY (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id)
            REFERENCES finance_schema.fee_structure_term (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id),

        /* Institutional Master Relationships */
        CONSTRAINT FK_student_fee_record_school FOREIGN KEY (school_id)
            REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_fee_record_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_student_fee_record_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_student_fee_record_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_student_fee_record_section_scope FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_student_fee_record_student FOREIGN KEY (student_id)
            REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_fee_record_created_by FOREIGN KEY (created_by)
            REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_fee_record_updated_by FOREIGN KEY (updated_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* 5. TABLE 3: finance_schema.fee_payment_transaction                         */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'finance_schema.fee_payment_transaction', N'U') IS NULL
BEGIN
    CREATE TABLE finance_schema.fee_payment_transaction
    (
        fee_payment_transaction_id BIGINT IDENTITY(1,1) NOT NULL,
        student_fee_record_id      BIGINT NOT NULL,
        school_id                  BIGINT NOT NULL,
        branch_id                  BIGINT NOT NULL,
        academic_year_id           BIGINT NOT NULL,
        student_id                 BIGINT NOT NULL,
        class_id                   BIGINT NOT NULL,
        section_id                 BIGINT NOT NULL,
        fee_type                   NVARCHAR(20) NOT NULL,
        term_number                TINYINT NULL,
        transaction_type           NVARCHAR(20) NOT NULL CONSTRAINT DF_fee_payment_transaction_type DEFAULT (N'PAYMENT'),
        status                     NVARCHAR(20) NOT NULL CONSTRAINT DF_fee_payment_transaction_status DEFAULT (N'SUCCESS'),
        amount                     DECIMAL(12,2) NOT NULL,
        receipt_number             NVARCHAR(20) NOT NULL,
        payment_method             NVARCHAR(20) NOT NULL,
        payment_gateway            NVARCHAR(50) NULL,
        gateway_transaction_id     NVARCHAR(100) NULL,
        transaction_reference      NVARCHAR(100) NULL,
        parent_transaction_id      BIGINT NULL,
        remarks                    NVARCHAR(500) NULL,
        paid_at                    DATETIME2(0) NOT NULL CONSTRAINT DF_fee_payment_transaction_paid_at DEFAULT (SYSUTCDATETIME()),
        created_at                 DATETIME2(0) NOT NULL CONSTRAINT DF_fee_payment_transaction_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                 BIGINT NOT NULL,
        updated_at                 DATETIME2(0) NULL,
        updated_by                 BIGINT NULL,
        row_version                ROWVERSION NOT NULL,

        CONSTRAINT PK_fee_payment_transaction PRIMARY KEY CLUSTERED (fee_payment_transaction_id),

        /* Transaction Values and Types */
        CONSTRAINT CK_fee_payment_transaction_amount CHECK (amount > 0),
        CONSTRAINT CK_fee_payment_transaction_fee_type CHECK (fee_type IN (N'TUITION', N'HOSTEL', N'TRANSPORT', N'OTHER')),
        CONSTRAINT CK_fee_payment_transaction_term CHECK (
            (fee_type IN (N'TUITION', N'HOSTEL', N'TRANSPORT') AND term_number IN (1, 2, 3))
            OR (fee_type = N'OTHER' AND term_number IS NULL)
        ),
        CONSTRAINT CK_fee_payment_transaction_type CHECK (transaction_type IN (N'PAYMENT', N'REFUND')),
        CONSTRAINT CK_fee_payment_transaction_status CHECK (status IN (N'PENDING', N'SUCCESS', N'FAILED', N'CANCELLED')),
        CONSTRAINT CK_fee_payment_transaction_method CHECK (payment_method IN (N'CASH', N'CARD', N'UPI', N'BANK_TRANSFER', N'CHEQUE', N'ONLINE')),

        /* Receipt Format: FEE-YYYY-NNNNNN for PAYMENT; REF-YYYY-NNNNNN for REFUND */
        CONSTRAINT CK_fee_payment_transaction_receipt CHECK (
            (transaction_type = N'PAYMENT' AND receipt_number LIKE N'FEE-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
            OR (transaction_type = N'REFUND' AND receipt_number LIKE N'REF-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
        ),

        /* Refund Parent Relationship: REFUND MUST have parent_transaction_id; PAYMENT must NOT */
        CONSTRAINT CK_fee_payment_transaction_refund_parent CHECK (
            (transaction_type = N'REFUND' AND parent_transaction_id IS NOT NULL)
            OR (transaction_type = N'PAYMENT' AND parent_transaction_id IS NULL)
        ),

        /* Parent Transaction Self-Reference */
        CONSTRAINT FK_fee_payment_transaction_parent FOREIGN KEY (parent_transaction_id)
            REFERENCES finance_schema.fee_payment_transaction (fee_payment_transaction_id),

        /* Composite Scope FK to Student Fee Record Hierarchy */
        CONSTRAINT FK_fee_payment_transaction_record FOREIGN KEY (
            student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id
        ) REFERENCES finance_schema.student_fee_record (
            student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id
        ),

        /* Institutional Master Relationships */
        CONSTRAINT FK_fee_payment_transaction_school FOREIGN KEY (school_id)
            REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_fee_payment_transaction_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_fee_payment_transaction_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_fee_payment_transaction_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_fee_payment_transaction_section_scope FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_fee_payment_transaction_student FOREIGN KEY (student_id)
            REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_fee_payment_transaction_created_by FOREIGN KEY (created_by)
            REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_fee_payment_transaction_updated_by FOREIGN KEY (updated_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* 6. OPERATIONAL INDEXES                                                     */
/* -------------------------------------------------------------------------- */

/* Fee Structure: Single active structure per class per academic year within branch scope */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_fee_structure_term_active_scope'
      AND object_id = OBJECT_ID(N'finance_schema.fee_structure_term')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_fee_structure_term_active_scope
        ON finance_schema.fee_structure_term (school_id, branch_id, academic_year_id, class_id)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_structure_term_active_lookup'
      AND object_id = OBJECT_ID(N'finance_schema.fee_structure_term')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_structure_term_active_lookup
        ON finance_schema.fee_structure_term (school_id, branch_id, academic_year_id, is_active, class_id);
END;
GO

/* Student Fee Record: Student + Academic Year lookup */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_fee_record_student_year'
      AND object_id = OBJECT_ID(N'finance_schema.student_fee_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_fee_record_student_year
        ON finance_schema.student_fee_record (student_id, academic_year_id);
END;
GO

/* Student Fee Record: Class/Section scope batch lookup */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_fee_record_scope'
      AND object_id = OBJECT_ID(N'finance_schema.student_fee_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_fee_record_scope
        ON finance_schema.student_fee_record (school_id, branch_id, academic_year_id, class_id, section_id);
END;
GO

/* Student Fee Record: Outstanding balance / collection tracking */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_fee_record_outstanding'
      AND object_id = OBJECT_ID(N'finance_schema.student_fee_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_fee_record_outstanding
        ON finance_schema.student_fee_record (school_id, branch_id, academic_year_id, overall_status)
        INCLUDE (total_balance_amount);
END;
GO

/* Fee Payment Transaction: School/Year receipt uniqueness */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_fee_payment_transaction_receipt'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_fee_payment_transaction_receipt
        ON finance_schema.fee_payment_transaction (school_id, academic_year_id, receipt_number);
END;
GO

/* Fee Payment Transaction: Student transaction ledger access */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_student_created'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_student_created
        ON finance_schema.fee_payment_transaction (student_id, academic_year_id, created_at DESC);
END;
GO

/* Fee Payment Transaction: Student Fee Record ledger access */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_record_created'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_record_created
        ON finance_schema.fee_payment_transaction (student_fee_record_id, created_at DESC);
END;
GO

/* Fee Payment Transaction: Fee type & term slice queries */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_type'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_type
        ON finance_schema.fee_payment_transaction (school_id, branch_id, academic_year_id, fee_type, term_number);
END;
GO

/* Fee Payment Transaction: Payment gateway reconciliation (Filtered) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_gateway'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_gateway
        ON finance_schema.fee_payment_transaction (gateway_transaction_id)
        WHERE gateway_transaction_id IS NOT NULL;
END;
GO

/* Fee Payment Transaction: Parent transaction refund audit trail (Filtered) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_parent'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_parent
        ON finance_schema.fee_payment_transaction (parent_transaction_id)
        WHERE parent_transaction_id IS NOT NULL;
END;
GO
/* END INLINE MIGRATION: 016_finance.sql */

/* BEGIN INLINE MIGRATION: 018_student_achievements.sql */
/* Module migration: 018_student_achievements.sql */
/*
    Migration: 018_student_achievements
    Purpose:   Student achievements catalog and tracking

    Design notes:
    - student_schema.student_achievement = achievement records for students
    - Scope: school_id + branch_id + student_id for branch-wise tracking
    - Achievements are created by management for individual students
    - Supports multiple categories, levels (National, State, District), and ranking (1st, 2nd, etc.)
    - Audit trail: created_by, updated_by with timestamps

    Rollback:
    - DROP TABLE student_schema.student_achievement;
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student_achievement                                        */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student_achievement', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_achievement
    (
        achievement_id         BIGINT          NOT NULL IDENTITY(1, 1),
        school_id              BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        student_id             BIGINT          NOT NULL,
        achievement_title      NVARCHAR(200)   NOT NULL,
        category               NVARCHAR(100)   NOT NULL,
        description            NVARCHAR(MAX)   NULL,
        achievement_place      NVARCHAR(50)    NOT NULL,
        achievement_level      NVARCHAR(50)    NOT NULL,
        date_issued            DATE            NOT NULL,
        certificate_url        NVARCHAR(500)   NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_student_achievement_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_student_achievement_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_student_achievement_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_achievement PRIMARY KEY CLUSTERED (achievement_id),
        CONSTRAINT CK_student_achievement_title CHECK (LEN(LTRIM(RTRIM(achievement_title))) > 0),
        CONSTRAINT CK_student_achievement_category CHECK (LEN(LTRIM(RTRIM(category))) > 0),
        CONSTRAINT CK_student_achievement_place CHECK (LEN(LTRIM(RTRIM(achievement_place))) > 0),
        CONSTRAINT CK_student_achievement_level CHECK
            (achievement_level IN (N'NATIONAL', N'STATE', N'DISTRICT', N'SCHOOL', N'BRANCH', N'CLASS')),
        CONSTRAINT FK_student_achievement_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_achievement_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_achievement_student_scope FOREIGN KEY (school_id, branch_id, student_id)
            REFERENCES student_schema.student (school_id, branch_id, student_id),
        CONSTRAINT FK_student_achievement_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_achievement_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* Indexes for student_schema.student_achievement                            */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_achievement_student_branch'
      AND object_id = OBJECT_ID(N'student_schema.student_achievement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_achievement_student_branch
        ON student_schema.student_achievement (school_id, branch_id, student_id, is_active)
        INCLUDE (achievement_title, category, achievement_level, date_issued)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_achievement_branch_date'
      AND object_id = OBJECT_ID(N'student_schema.student_achievement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_achievement_branch_date
        ON student_schema.student_achievement (school_id, branch_id, date_issued DESC)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_achievement_category_level'
      AND object_id = OBJECT_ID(N'student_schema.student_achievement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_achievement_category_level
        ON student_schema.student_achievement (school_id, branch_id, category, achievement_level, is_active)
        WHERE is_active = 1;
END;
GO

/* END INLINE MIGRATION: 018_student_achievements.sql */

/* BEGIN INLINE MIGRATION: 019_student_residency_and_section_class_teacher.sql */
/* Module migration: 019_student_residency_and_section_class_teacher.sql */
/*
    Purpose:
    - Classify each student as a hosteller or day scholar.
    - Store the class teacher assigned to each section for an academic year.

    Notes:
    - residency_type describes accommodation, not academic placement.
    - Existing students are initialized as DAY_SCHOLAR and should be corrected
      where applicable after deployment.
    - A section can have only one active class-teacher assignment per academic year.
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student.residency_type                                      */
/* -------------------------------------------------------------------------- */

IF COL_LENGTH(N'student_schema.student', N'residency_type') IS NULL
BEGIN
    ALTER TABLE student_schema.student
        ADD residency_type NVARCHAR(20) NOT NULL
            CONSTRAINT DF_student_residency_type DEFAULT (N'DAY_SCHOLAR') WITH VALUES;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_student_residency_type'
      AND parent_object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    ALTER TABLE student_schema.student
        ADD CONSTRAINT CK_student_residency_type
            CHECK (residency_type IN (N'HOSTELLER', N'DAY_SCHOLAR'));
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_student_residency_type_active'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_residency_type_active
        ON student_schema.student (school_id, branch_id, residency_type, is_active)
        INCLUDE (student_id, first_name, last_name, admission_number);
END;
GO

/* -------------------------------------------------------------------------- */
/* teachers_schema.section_class_teacher_assignment                           */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UQ_teacher_school_branch_scope'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_teacher_school_branch_scope
        ON teachers_schema.teacher (school_id, branch_id, teacher_id);
END;
GO

IF OBJECT_ID(N'teachers_schema.section_class_teacher_assignment', N'U') IS NULL
BEGIN
    CREATE TABLE teachers_schema.section_class_teacher_assignment
    (
        section_class_teacher_assignment_id BIGINT       NOT NULL IDENTITY(1, 1),
        school_id                           BIGINT       NOT NULL,
        branch_id                           BIGINT       NOT NULL,
        academic_year_id                    BIGINT       NOT NULL,
        class_id                            BIGINT       NOT NULL,
        section_id                          BIGINT       NOT NULL,
        teacher_id                          BIGINT       NOT NULL,
        is_active                           BIT          NOT NULL CONSTRAINT DF_section_class_teacher_assignment_is_active DEFAULT (1),
        created_at                          DATETIME2(0) NOT NULL CONSTRAINT DF_section_class_teacher_assignment_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                          BIGINT       NOT NULL,
        updated_at                          DATETIME2(0) NOT NULL CONSTRAINT DF_section_class_teacher_assignment_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                          BIGINT       NULL,
        row_version                         ROWVERSION   NOT NULL,
        CONSTRAINT PK_section_class_teacher_assignment PRIMARY KEY CLUSTERED (section_class_teacher_assignment_id),
        CONSTRAINT FK_section_class_teacher_assignment_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_section_class_teacher_assignment_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_section_class_teacher_assignment_academic_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_section_class_teacher_assignment_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_section_class_teacher_assignment_section_scope FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_section_class_teacher_assignment_teacher_scope FOREIGN KEY (school_id, branch_id, teacher_id)
            REFERENCES teachers_schema.teacher (school_id, branch_id, teacher_id),
        CONSTRAINT FK_section_class_teacher_assignment_created_by FOREIGN KEY (created_by)
            REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_section_class_teacher_assignment_updated_by FOREIGN KEY (updated_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_section_class_teacher_assignment_active_scope'
      AND object_id = OBJECT_ID(N'teachers_schema.section_class_teacher_assignment')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_section_class_teacher_assignment_active_scope
        ON teachers_schema.section_class_teacher_assignment
            (school_id, branch_id, academic_year_id, class_id, section_id)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_section_class_teacher_assignment_teacher_active'
      AND object_id = OBJECT_ID(N'teachers_schema.section_class_teacher_assignment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_section_class_teacher_assignment_teacher_active
        ON teachers_schema.section_class_teacher_assignment (teacher_id, is_active)
        INCLUDE (school_id, branch_id, academic_year_id, class_id, section_id);
END;
GO

/* END INLINE MIGRATION: 019_student_residency_and_section_class_teacher.sql */

/* BEGIN INLINE MIGRATION: 020_alumni.sql */
/* ============================================================
   Migration: 020_alumni.sql
   Purpose:   Alumni Management Module (SSMS)
              - Alumni Profiles & Job Verification Workflow
              - Alumni Success Stories (Verified Alumni Only)
              - Note: Alumni Events are stored in management_schema.announcement
                with announcement_type = 'EVENT' and sub_category = 'ALUMNI_EVENTS'

   Design Notes:
   - Scope: school_id -> branch_id -> academic_year_id -> class_id -> section_id -> student_id
   - Students upgraded to alumni upon graduation (verification_status: PENDING/VERIFIED/REJECTED)
   - Stories pull photo & current role directly from alumni_profile JOIN

   Rollback:
   - DROP TABLE IF EXISTS alumni_schema.alumni_story;
   - DROP TABLE IF EXISTS alumni_schema.alumni_profile;
   - DROP SCHEMA IF EXISTS alumni_schema;
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'alumni_schema')
BEGIN
    EXEC(N'CREATE SCHEMA alumni_schema;');
END;
GO

/* ========================================================================== */
/* Clean up alumni_event if it exists in an existing database                 */
/* ========================================================================== */

IF OBJECT_ID(N'alumni_schema.alumni_event', N'U') IS NOT NULL
BEGIN
    DROP TABLE alumni_schema.alumni_event;
END;
GO

/* ========================================================================== */
/* 1. alumni_schema.alumni_profile                                           */
/* ========================================================================== */

IF OBJECT_ID(N'alumni_schema.alumni_profile', N'U') IS NULL
BEGIN
    CREATE TABLE alumni_schema.alumni_profile
    (
        alumni_id             BIGINT IDENTITY(1, 1) NOT NULL,
        school_id             BIGINT                NOT NULL,
        branch_id             BIGINT                NOT NULL,
        academic_year_id      BIGINT                NOT NULL,
        class_id              BIGINT                NOT NULL,
        section_id            BIGINT                NOT NULL,
        student_id            BIGINT                NOT NULL,
        passout_batch_year    INT                   NOT NULL,
        current_role          NVARCHAR(150)         NULL,
        organisation_name     NVARCHAR(150)         NULL,
        industry_name         NVARCHAR(100)         NULL,
        location_city         NVARCHAR(100)         NULL,
        location_country      NVARCHAR(100)         NULL,
        linkedin_profile_url  NVARCHAR(500)         NULL,
        verification_status   NVARCHAR(20)          NOT NULL CONSTRAINT DF_alumni_profile_status DEFAULT (N'PENDING'),
        verified_at           DATETIME2(0)          NULL,
        verified_by           BIGINT                NULL,
        profile_photo_url     NVARCHAR(500)         NULL,
        is_active             BIT                   NOT NULL CONSTRAINT DF_alumni_profile_is_active DEFAULT (1),
        created_at            DATETIME2(0)          NOT NULL CONSTRAINT DF_alumni_profile_created_at DEFAULT (SYSUTCDATETIME()),
        created_by            BIGINT                NOT NULL,
        updated_at            DATETIME2(0)          NOT NULL CONSTRAINT DF_alumni_profile_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by            BIGINT                NULL,
        row_version           ROWVERSION            NOT NULL,
        CONSTRAINT PK_alumni_profile PRIMARY KEY CLUSTERED (alumni_id),
        CONSTRAINT UQ_alumni_profile_student UNIQUE NONCLUSTERED (student_id),
        CONSTRAINT CK_alumni_profile_status CHECK (verification_status IN (N'PENDING', N'VERIFIED', N'REJECTED')),
        CONSTRAINT CK_alumni_profile_batch CHECK (passout_batch_year BETWEEN 1950 AND 2100),
        CONSTRAINT FK_alumni_profile_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_alumni_profile_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_alumni_profile_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_alumni_profile_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_alumni_profile_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_alumni_profile_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_alumni_profile_verified_by FOREIGN KEY (verified_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_alumni_profile_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_alumni_profile_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

/* Idempotent upgrade for existing databases */
IF OBJECT_ID(N'alumni_schema.alumni_profile', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    IF COL_LENGTH(N'alumni_schema.alumni_profile', N'academic_year_id') IS NULL
    BEGIN
        ALTER TABLE alumni_schema.alumni_profile
            ADD academic_year_id BIGINT NULL;

        EXEC(N'UPDATE ap
              SET ap.academic_year_id = s.academic_year_id
              FROM alumni_schema.alumni_profile ap
              INNER JOIN student_schema.student s ON s.student_id = ap.student_id
              WHERE ap.academic_year_id IS NULL;');

        -- If table had rows without matching student, fallback to academic_year from branch/school
        EXEC(N'UPDATE ap
              SET ap.academic_year_id = (SELECT TOP 1 ay.academic_year_id FROM management_schema.academic_year ay WHERE ay.school_id = ap.school_id ORDER BY ay.is_current DESC, ay.academic_year_id DESC)
              FROM alumni_schema.alumni_profile ap
              WHERE ap.academic_year_id IS NULL;');

        ALTER TABLE alumni_schema.alumni_profile
            ALTER COLUMN academic_year_id BIGINT NOT NULL;

        IF NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys
            WHERE name = N'FK_alumni_profile_academic_year'
              AND parent_object_id = OBJECT_ID(N'alumni_schema.alumni_profile')
        )
        BEGIN
            ALTER TABLE alumni_schema.alumni_profile
                ADD CONSTRAINT FK_alumni_profile_academic_year
                FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id);
        END;
    END;

    IF COL_LENGTH(N'alumni_schema.alumni_profile', N'class_id') IS NULL
    BEGIN
        ALTER TABLE alumni_schema.alumni_profile
            ADD class_id BIGINT NULL;

        EXEC(N'UPDATE ap
              SET ap.class_id = s.class_id
              FROM alumni_schema.alumni_profile ap
              INNER JOIN student_schema.student s ON s.student_id = ap.student_id
              WHERE ap.class_id IS NULL;');

        EXEC(N'UPDATE ap
              SET ap.class_id = (SELECT TOP 1 c.class_id FROM management_schema.school_class c WHERE c.school_id = ap.school_id ORDER BY c.display_order DESC, c.class_id DESC)
              FROM alumni_schema.alumni_profile ap
              WHERE ap.class_id IS NULL;');

        ALTER TABLE alumni_schema.alumni_profile
            ALTER COLUMN class_id BIGINT NOT NULL;

        IF NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys
            WHERE name = N'FK_alumni_profile_class'
              AND parent_object_id = OBJECT_ID(N'alumni_schema.alumni_profile')
        )
        BEGIN
            ALTER TABLE alumni_schema.alumni_profile
                ADD CONSTRAINT FK_alumni_profile_class
                FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id);
        END;
    END;

    IF COL_LENGTH(N'alumni_schema.alumni_profile', N'section_id') IS NULL
    BEGIN
        ALTER TABLE alumni_schema.alumni_profile
            ADD section_id BIGINT NULL;

        EXEC(N'UPDATE ap
              SET ap.section_id = s.section_id
              FROM alumni_schema.alumni_profile ap
              INNER JOIN student_schema.student s ON s.student_id = ap.student_id
              WHERE ap.section_id IS NULL;');

        EXEC(N'UPDATE ap
              SET ap.section_id = (SELECT TOP 1 sec.section_id FROM management_schema.section sec WHERE sec.class_id = ap.class_id)
              FROM alumni_schema.alumni_profile ap
              WHERE ap.section_id IS NULL;');

        ALTER TABLE alumni_schema.alumni_profile
            ALTER COLUMN section_id BIGINT NOT NULL;

        IF NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys
            WHERE name = N'FK_alumni_profile_section'
              AND parent_object_id = OBJECT_ID(N'alumni_schema.alumni_profile')
        )
        BEGIN
            ALTER TABLE alumni_schema.alumni_profile
                ADD CONSTRAINT FK_alumni_profile_section
                FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id);
        END;
    END;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_alumni_profile_school_status'
      AND object_id = OBJECT_ID(N'alumni_schema.alumni_profile')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_alumni_profile_school_status
        ON alumni_schema.alumni_profile (school_id, branch_id, verification_status)
        INCLUDE (alumni_id, student_id, current_role, organisation_name, industry_name, location_city, location_country)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_alumni_profile_batch'
      AND object_id = OBJECT_ID(N'alumni_schema.alumni_profile')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_alumni_profile_batch
        ON alumni_schema.alumni_profile (school_id, passout_batch_year, verification_status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_alumni_profile_scope'
      AND object_id = OBJECT_ID(N'alumni_schema.alumni_profile')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_alumni_profile_scope
        ON alumni_schema.alumni_profile (school_id, branch_id, academic_year_id, class_id, section_id)
        WHERE is_active = 1;
END;
GO

/* ========================================================================== */
/* 2. alumni_schema.alumni_story                                             */
/* ========================================================================== */

IF OBJECT_ID(N'alumni_schema.alumni_story', N'U') IS NULL
BEGIN
    CREATE TABLE alumni_schema.alumni_story
    (
        alumni_story_id     BIGINT IDENTITY(1, 1) NOT NULL,
        school_id           BIGINT                NOT NULL,
        branch_id           BIGINT                NOT NULL,
        alumni_id           BIGINT                NOT NULL,
        story_title         NVARCHAR(200)         NOT NULL,
        story_content       NVARCHAR(MAX)         NOT NULL,
        is_published        BIT                   NOT NULL CONSTRAINT DF_alumni_story_is_published DEFAULT (1),
        created_at          DATETIME2(0)          NOT NULL CONSTRAINT DF_alumni_story_created_at DEFAULT (SYSUTCDATETIME()),
        created_by          BIGINT                NOT NULL,
        updated_at          DATETIME2(0)          NOT NULL CONSTRAINT DF_alumni_story_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by          BIGINT                NULL,
        row_version         ROWVERSION            NOT NULL,
        CONSTRAINT PK_alumni_story PRIMARY KEY CLUSTERED (alumni_story_id),
        CONSTRAINT FK_alumni_story_alumni FOREIGN KEY (alumni_id) REFERENCES alumni_schema.alumni_profile (alumni_id),
        CONSTRAINT FK_alumni_story_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_alumni_story_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_alumni_story_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_alumni_story_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

/* Idempotent upgrade for alumni_story */
IF OBJECT_ID(N'alumni_schema.alumni_story', N'U') IS NOT NULL
BEGIN
    SET XACT_ABORT ON;

    IF COL_LENGTH(N'alumni_schema.alumni_story', N'branch_id') IS NULL
    BEGIN
        ALTER TABLE alumni_schema.alumni_story
            ADD branch_id BIGINT NULL;

        EXEC(N'UPDATE ast
              SET ast.branch_id = ap.branch_id
              FROM alumni_schema.alumni_story ast
              INNER JOIN alumni_schema.alumni_profile ap ON ap.alumni_id = ast.alumni_id
              WHERE ast.branch_id IS NULL;');

        EXEC(N'UPDATE ast
              SET ast.branch_id = (SELECT TOP 1 b.branch_id FROM management_schema.branch b WHERE b.school_id = ast.school_id)
              FROM alumni_schema.alumni_story ast
              WHERE ast.branch_id IS NULL;');

        ALTER TABLE alumni_schema.alumni_story
            ALTER COLUMN branch_id BIGINT NOT NULL;

        IF NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys
            WHERE name = N'FK_alumni_story_branch'
              AND parent_object_id = OBJECT_ID(N'alumni_schema.alumni_story')
        )
        BEGIN
            ALTER TABLE alumni_schema.alumni_story
                ADD CONSTRAINT FK_alumni_story_branch
                FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id);
        END;
    END;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_alumni_story_school_pub'
      AND object_id = OBJECT_ID(N'alumni_schema.alumni_story')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_alumni_story_school_pub
        ON alumni_schema.alumni_story (school_id, branch_id, is_published)
        INCLUDE (alumni_story_id, alumni_id, story_title);
END;
GO

/* END INLINE MIGRATION: 020_alumni.sql */

/* BEGIN INLINE MIGRATION: 021_student_exam_performance.sql */
/*
    Migration: 021_student_exam_performance.sql
    Module:    student_schema.student_exam_performance
    Purpose:   Store backend-generated exam performance summary metrics for each student
               per academic scope (academic_year, class, section).

    Architectural Constraints & Design Rules:
    ---------------------------------------------------------------------------
    - All attendance and exam performance calculations are handled EXCLUSIVELY in the backend application layer.
    - The database does NOT contain:
      * Calculated formulas
      * Computed columns
      * Triggers for percentage calculation
      * Stored procedures for percentage calculation
    - Existing table student_schema.exam_result is UNCHANGED.
    - Only stores the backend-generated summary values:
      * student_exam_performance_id (PK IDENTITY)
      * student_id (FK -> student_schema.student)
      * academic_year_id (FK -> management_schema.academic_year)
      * class_id (FK -> management_schema.school_class)
      * section_id (FK -> management_schema.section)
      * total_exams_count (INT >= 0)
      * overall_percentage (DECIMAL(5, 2) BETWEEN 0.00 AND 100.00)
      * created_at (DATETIME2(0))
      * updated_at (DATETIME2(0))
      * row_version (ROWVERSION for optimistic concurrency)

    Rollback:
    - DROP TABLE IF EXISTS student_schema.student_exam_performance;
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Creating student_schema.student_exam_performance table...';
PRINT N'========================================================================';

IF OBJECT_ID(N'student_schema.student_exam_performance', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_exam_performance
    (
        student_exam_performance_id BIGINT          NOT NULL IDENTITY(1, 1),
        student_id                  BIGINT          NOT NULL,
        academic_year_id            BIGINT          NOT NULL,
        class_id                    BIGINT          NOT NULL,
        section_id                  BIGINT          NOT NULL,
        total_exams_count           INT             NOT NULL CONSTRAINT DF_student_exam_performance_total_exams DEFAULT (0),
        overall_percentage          DECIMAL(5, 2)   NOT NULL,
        created_at                  DATETIME2(0)    NOT NULL CONSTRAINT DF_student_exam_performance_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at                  DATETIME2(0)    NOT NULL CONSTRAINT DF_student_exam_performance_updated_at DEFAULT (SYSUTCDATETIME()),
        row_version                 ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_exam_performance PRIMARY KEY CLUSTERED (student_exam_performance_id),
        CONSTRAINT UQ_student_exam_performance_student_scope UNIQUE NONCLUSTERED
            (student_id, academic_year_id, class_id, section_id),
        CONSTRAINT CK_student_exam_performance_total_exams CHECK
            (total_exams_count >= 0),
        CONSTRAINT CK_student_exam_performance_overall_percentage CHECK
            (overall_percentage >= 0.00 AND overall_percentage <= 100.00),
        CONSTRAINT FK_student_exam_performance_student FOREIGN KEY (student_id)
            REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_exam_performance_academic_year FOREIGN KEY (academic_year_id)
            REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_exam_performance_class FOREIGN KEY (class_id)
            REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_exam_performance_section FOREIGN KEY (section_id)
            REFERENCES management_schema.section (section_id)
    );

    PRINT N'Created table student_schema.student_exam_performance successfully.';
END
ELSE
BEGIN
    PRINT N'Table student_schema.student_exam_performance already exists. Skipping creation.';
END;
GO

-- Index for querying exam performance summary across a section / class
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_exam_performance_scope'
      AND object_id = OBJECT_ID(N'student_schema.student_exam_performance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_exam_performance_scope
        ON student_schema.student_exam_performance (academic_year_id, class_id, section_id)
        INCLUDE (student_id, total_exams_count, overall_percentage);

    PRINT N'Created index IX_student_exam_performance_scope.';
END;
GO

-- Index for rapid single-student lookup
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_exam_performance_student'
      AND object_id = OBJECT_ID(N'student_schema.student_exam_performance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_exam_performance_student
        ON student_schema.student_exam_performance (student_id)
        INCLUDE (academic_year_id, total_exams_count, overall_percentage);

    PRINT N'Created index IX_student_exam_performance_student.';
END;
GO

PRINT N'========================================================================';
PRINT N'student_schema.student_exam_performance setup completed.';
PRINT N'========================================================================';
GO

/* END INLINE MIGRATION: 021_student_exam_performance.sql */

/* BEGIN INLINE MIGRATION: 022_personal_development.sql */
/*
    Migration: 022_personal_development.sql
    Module:    Personal Development (student_schema)
    Purpose:   Store official student personality development ratings maintained by
               Class Teachers, and subject-based qualitative reviews written by teachers.

    Design Notes:
    - student_schema.student_personality_development:
      * Maintained by student's Class Teacher.
      * Ratings: leadership, communication, collaboration, responsibility, overall (0.00 to 5.00 scale).
      * Unique per (student_id, academic_year_id).
    - student_schema.student_personality_development_review:
      * Subject-based qualitative evaluations written by respective subject teachers.
      * Supports multiple reviews across subjects and review dates.
      * No separate development area or review master catalog tables.
      * Zero percentage or calculation logic in the database (handled in backend).

    Rollback:
    - DROP TABLE IF EXISTS student_schema.student_personality_development_review;
    - DROP TABLE IF EXISTS student_schema.student_personality_development;
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Creating Personal Development Module Tables in student_schema...';
PRINT N'========================================================================';

-- =============================================================================
-- 1. TABLE: student_schema.student_personality_development
-- =============================================================================
IF OBJECT_ID(N'student_schema.student_personality_development', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_personality_development
    (
        personality_development_id BIGINT          NOT NULL IDENTITY(1, 1),
        school_id                  BIGINT          NOT NULL,
        branch_id                  BIGINT          NOT NULL,
        academic_year_id           BIGINT          NOT NULL,
        class_id                   BIGINT          NOT NULL,
        section_id                 BIGINT          NOT NULL,
        student_id                 BIGINT          NOT NULL,
        class_teacher_id           BIGINT          NOT NULL,

        leadership_rating          DECIMAL(3, 2)   NULL,
        communication_rating       DECIMAL(3, 2)   NULL,
        collaboration_rating       DECIMAL(3, 2)   NULL,
        responsibility_rating      DECIMAL(3, 2)   NULL,
        overall_rating             DECIMAL(3, 2)   NULL,

        is_active                  BIT             NOT NULL CONSTRAINT DF_student_personality_dev_is_active DEFAULT (1),
        created_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_student_personality_dev_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                 BIGINT          NOT NULL,
        updated_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_student_personality_dev_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                 BIGINT          NULL,
        row_version                ROWVERSION      NOT NULL,

        CONSTRAINT PK_student_personality_development PRIMARY KEY CLUSTERED (personality_development_id),
        CONSTRAINT UQ_student_personality_dev_student_year UNIQUE NONCLUSTERED (student_id, academic_year_id),

        CONSTRAINT CK_student_personality_dev_leadership
            CHECK (leadership_rating IS NULL OR (leadership_rating >= 0.00 AND leadership_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_communication
            CHECK (communication_rating IS NULL OR (communication_rating >= 0.00 AND communication_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_collaboration
            CHECK (collaboration_rating IS NULL OR (collaboration_rating >= 0.00 AND collaboration_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_responsibility
            CHECK (responsibility_rating IS NULL OR (responsibility_rating >= 0.00 AND responsibility_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_overall
            CHECK (overall_rating IS NULL OR (overall_rating >= 0.00 AND overall_rating <= 5.00)),

        CONSTRAINT FK_student_personality_dev_school
            FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_personality_dev_branch
            FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_personality_dev_academic_year
            FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_personality_dev_class
            FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_personality_dev_section
            FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_personality_dev_student
            FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_personality_dev_class_teacher
            FOREIGN KEY (class_teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_student_personality_dev_created_by
            FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_personality_dev_updated_by
            FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );

    PRINT N'Created table student_schema.student_personality_development successfully.';
END
ELSE
BEGIN
    PRINT N'Table student_schema.student_personality_development already exists. Skipping creation.';
END;
GO

-- Indexes for student_personality_development
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_student_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_personality_dev_student_year
        ON student_schema.student_personality_development (student_id, academic_year_id)
        INCLUDE (class_teacher_id, overall_rating)
        WHERE is_active = 1;
    PRINT N'Created index IX_student_personality_dev_student_year.';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_scope'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_personality_dev_scope
        ON student_schema.student_personality_development (school_id, branch_id, academic_year_id, class_id, section_id)
        WHERE is_active = 1;
    PRINT N'Created index IX_student_personality_dev_scope.';
END;
GO


-- =============================================================================
-- 2. TABLE: student_schema.student_personality_development_review
-- =============================================================================
IF OBJECT_ID(N'student_schema.student_personality_development_review', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_personality_development_review
    (
        personality_review_id      BIGINT          NOT NULL IDENTITY(1, 1),
        school_id                  BIGINT          NOT NULL,
        branch_id                  BIGINT          NOT NULL,
        academic_year_id           BIGINT          NOT NULL,
        class_id                   BIGINT          NOT NULL,
        section_id                 BIGINT          NOT NULL,
        student_id                 BIGINT          NOT NULL,

        teacher_id                 BIGINT          NOT NULL,
        subject_id                 BIGINT          NOT NULL,

        category_type              NVARCHAR(50)    NOT NULL,
        rating                     INT             NOT NULL,
        review                     NVARCHAR(MAX)   NOT NULL,
        review_date                DATE            NOT NULL,

        is_active                  BIT             NOT NULL CONSTRAINT DF_student_personality_dev_rev_is_active DEFAULT (1),
        created_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_student_personality_dev_rev_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                 BIGINT          NOT NULL,
        updated_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_student_personality_dev_rev_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                 BIGINT          NULL,
        row_version                ROWVERSION      NOT NULL,

        CONSTRAINT PK_student_personality_development_review PRIMARY KEY CLUSTERED (personality_review_id),
        CONSTRAINT UQ_student_personality_dev_rev_session UNIQUE NONCLUSTERED
            (student_id, subject_id, teacher_id, category_type, review_date),

        CONSTRAINT CK_student_personality_dev_rev_text
            CHECK (LEN(LTRIM(RTRIM(review))) > 0),

        CONSTRAINT CK_student_personality_dev_rev_category
            CHECK (category_type IN (
                N'LEADERSHIP_RATING', N'COMMUNICATION_RATING', N'COLLABORATION_RATING', N'RESPONSIBILITY_RATING',
                N'LEADERSHIP', N'COMMUNICATION', N'COLLABORATION', N'RESPONSIBILITY'
            )),

        CONSTRAINT CK_student_personality_dev_rev_rating
            CHECK (rating >= 1 AND rating <= 5),

        CONSTRAINT FK_student_personality_dev_rev_school
            FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_personality_dev_rev_branch
            FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_personality_dev_rev_academic_year
            FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_personality_dev_rev_class
            FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_personality_dev_rev_section
            FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_personality_dev_rev_student
            FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_personality_dev_rev_teacher
            FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_student_personality_dev_rev_subject
            FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_student_personality_dev_rev_created_by
            FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_personality_dev_rev_updated_by
            FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );

    PRINT N'Created table student_schema.student_personality_development_review successfully.';
END
ELSE
BEGIN
    PRINT N'Table student_schema.student_personality_development_review already exists.';

    -- Idempotent check: Add category_type if missing
    IF COL_LENGTH(N'student_schema.student_personality_development_review', N'category_type') IS NULL
    BEGIN
        PRINT N'Adding category_type column to student_personality_development_review...';
        EXEC sp_executesql N'
            ALTER TABLE student_schema.student_personality_development_review
                ADD category_type NVARCHAR(50) NOT NULL
                    CONSTRAINT DF_student_personality_dev_rev_category DEFAULT (N''COMMUNICATION_RATING'') WITH VALUES;

            ALTER TABLE student_schema.student_personality_development_review
                ADD CONSTRAINT CK_student_personality_dev_rev_category
                    CHECK (category_type IN (
                        N''LEADERSHIP_RATING'', N''COMMUNICATION_RATING'', N''COLLABORATION_RATING'', N''RESPONSIBILITY_RATING'',
                        N''LEADERSHIP'', N''COMMUNICATION'', N''COLLABORATION'', N''RESPONSIBILITY''
                    ));
        ';
        PRINT N'Added category_type column and check constraint.';
    END;

    -- Idempotent check: Add rating if missing
    IF COL_LENGTH(N'student_schema.student_personality_development_review', N'rating') IS NULL
    BEGIN
        PRINT N'Adding rating column to student_personality_development_review...';
        EXEC sp_executesql N'
            ALTER TABLE student_schema.student_personality_development_review
                ADD rating INT NOT NULL
                    CONSTRAINT DF_student_personality_dev_rev_rating DEFAULT (4) WITH VALUES;

            ALTER TABLE student_schema.student_personality_development_review
                ADD CONSTRAINT CK_student_personality_dev_rev_rating
                    CHECK (rating >= 1 AND rating <= 5);
        ';
        PRINT N'Added rating column and check constraint.';
    END;

    -- Idempotent check: Upgrade UQ_student_personality_dev_rev_session to include category_type
    IF EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'UQ_student_personality_dev_rev_session'
          AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
    )
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM sys.index_columns ic
            INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
              AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'UQ_student_personality_dev_rev_session', 'IndexId')
              AND c.name = N'category_type'
        )
        BEGIN
            PRINT N'Upgrading unique constraint UQ_student_personality_dev_rev_session to include category_type...';
            EXEC sp_executesql N'
                ALTER TABLE student_schema.student_personality_development_review
                    DROP CONSTRAINT UQ_student_personality_dev_rev_session;

                ALTER TABLE student_schema.student_personality_development_review
                    ADD CONSTRAINT UQ_student_personality_dev_rev_session UNIQUE NONCLUSTERED
                        (student_id, subject_id, teacher_id, category_type, review_date);
            ';
            PRINT N'Upgraded unique constraint UQ_student_personality_dev_rev_session.';
        END;
    END;
END;
GO

-- Indexes for student_personality_development_review
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
          AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'IX_student_personality_dev_rev_student_year', 'IndexId')
          AND c.name = N'category_type'
    )
    BEGIN
        DROP INDEX IX_student_personality_dev_rev_student_year 
            ON student_schema.student_personality_development_review;
    END;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    EXEC sp_executesql N'
        CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_student_year
            ON student_schema.student_personality_development_review (student_id, academic_year_id)
            INCLUDE (subject_id, teacher_id, category_type, rating, review_date)
            WHERE is_active = 1;
    ';
    PRINT N'Created index IX_student_personality_dev_rev_student_year.';
END;
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_subject_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
          AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'IX_student_personality_dev_rev_student_subject_year', 'IndexId')
          AND c.name = N'category_type'
    )
    BEGIN
        DROP INDEX IX_student_personality_dev_rev_student_subject_year 
            ON student_schema.student_personality_development_review;
    END;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_subject_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    EXEC sp_executesql N'
        CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_student_subject_year
            ON student_schema.student_personality_development_review (student_id, subject_id, academic_year_id)
            INCLUDE (teacher_id, category_type, rating, review_date)
            WHERE is_active = 1;
    ';
    PRINT N'Created index IX_student_personality_dev_rev_student_subject_year.';
END;
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_teacher_subject'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
          AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'IX_student_personality_dev_rev_teacher_subject', 'IndexId')
          AND c.name = N'category_type'
    )
    BEGIN
        DROP INDEX IX_student_personality_dev_rev_teacher_subject 
            ON student_schema.student_personality_development_review;
    END;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_teacher_subject'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    EXEC sp_executesql N'
        CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_teacher_subject
            ON student_schema.student_personality_development_review (teacher_id, subject_id, review_date)
            INCLUDE (student_id, category_type, rating)
            WHERE is_active = 1;
    ';
    PRINT N'Created index IX_student_personality_dev_rev_teacher_subject.';
END;
GO

PRINT N'========================================================================';
PRINT N'Personal Development Module setup completed successfully.';
PRINT N'========================================================================';
GO

/* END INLINE MIGRATION: 022_personal_development.sql */

/* BEGIN INLINE MIGRATION: 023_cultural_participation.sql */
/*
    Migration: 023_cultural_participation.sql
    Module:    Cultural Performance / Cultural Participation (student_schema)
    Purpose:   Store student-wise, event-wise cultural participation and performance details
               referencing existing cultural announcements (management_schema.announcement).

    Design Notes:
    - Exactly ONE table created: student_schema.student_cultural_participation.
    - Cultural events are sourced from management_schema.announcement (announcement_type = 'EVENT', sub_category = 'CULTURAL').
      No duplicate event or review tables are created.
    - teacher_id identifies the Class Teacher authorized to manage cultural participation records for their section.
    - Application/backend layer enforces authorization:
        teacher_id == Class Teacher assigned to (school_id, branch_id, academic_year_id, class_id, section_id)
        in teachers_schema.section_class_teacher_assignment.
    - One active record per student per announcement: UNIQUE(student_id, announcement_id) WHERE is_active = 1.
    - Full historical support across academic years and events.
    - Audit: created_at, updated_at, row_version (no created_by/updated_by or remarks).

    Rollback:
    - DROP TABLE IF EXISTS student_schema.student_cultural_participation;
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Creating student_schema.student_cultural_participation table...';
PRINT N'========================================================================';

-- =============================================================================
-- 1. TABLE: student_schema.student_cultural_participation
-- =============================================================================
IF OBJECT_ID(N'student_schema.student_cultural_participation', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_cultural_participation
    (
        cultural_participation_id BIGINT          NOT NULL IDENTITY(1, 1),
        student_id                BIGINT          NOT NULL,
        school_id                 BIGINT          NOT NULL,
        branch_id                 BIGINT          NOT NULL,
        academic_year_id          BIGINT          NOT NULL,
        class_id                  BIGINT          NOT NULL,
        section_id                BIGINT          NOT NULL,
        announcement_id           BIGINT          NOT NULL,
        event_name                NVARCHAR(200)   NOT NULL,
        teacher_id                BIGINT          NOT NULL,

        category                  NVARCHAR(100)   NOT NULL,
        role_involvement          NVARCHAR(100)   NULL,
        result                    NVARCHAR(100)   NULL,
        participation_status      NVARCHAR(30)    NOT NULL,
        participation_date        DATE            NULL,

        is_active                 BIT             NOT NULL CONSTRAINT DF_student_cultural_part_is_active DEFAULT (1),
        created_at                DATETIME2(0)    NOT NULL CONSTRAINT DF_student_cultural_part_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at                DATETIME2(0)    NOT NULL CONSTRAINT DF_student_cultural_part_updated_at DEFAULT (SYSUTCDATETIME()),
        row_version               ROWVERSION      NOT NULL,

        CONSTRAINT PK_student_cultural_participation
            PRIMARY KEY CLUSTERED (cultural_participation_id),

        CONSTRAINT CK_student_cultural_part_status
            CHECK (participation_status IN (N'REGISTERED', N'PARTICIPATED', N'CANCELLED')),

        CONSTRAINT CK_student_cultural_part_category
            CHECK (category IN (N'VISUAL_ARTS', N'PERFORMING_ARTS', N'MUSIC', N'CULTURAL_ACTIVITIES', N'OTHER')),

        CONSTRAINT CK_student_cultural_part_role
            CHECK (role_involvement IS NULL OR role_involvement IN (
                N'PARTICIPANT', N'EXHIBITOR', N'VOCALIST', N'INSTRUMENTALIST',
                N'ACTOR', N'DANCER', N'ORGANIZER', N'OTHER'
            )),

        CONSTRAINT CK_student_cultural_part_result
            CHECK (result IS NULL OR result IN (
                N'PARTICIPATED', N'PERFORMED', N'COMPLETED',
                N'FIRST_PLACE', N'SECOND_PLACE', N'THIRD_PLACE',
                N'RUNNER_UP', N'SPECIAL_MENTION', N'NO_RESULT'
            )),

        CONSTRAINT FK_student_cultural_part_student
            FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),

        CONSTRAINT FK_student_cultural_part_school
            FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),

        CONSTRAINT FK_student_cultural_part_branch
            FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),

        CONSTRAINT FK_student_cultural_part_academic_year
            FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),

        CONSTRAINT FK_student_cultural_part_class
            FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),

        CONSTRAINT FK_student_cultural_part_section
            FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),

        CONSTRAINT FK_student_cultural_part_announcement
            FOREIGN KEY (announcement_id) REFERENCES management_schema.announcement (announcement_id),

        CONSTRAINT FK_student_cultural_part_teacher
            FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id)
    );

    PRINT N'Created table student_schema.student_cultural_participation successfully.';
END
ELSE
BEGIN
    PRINT N'Table student_schema.student_cultural_participation already exists.';

    -- Idempotent column check: add event_name if missing
    IF COL_LENGTH(N'student_schema.student_cultural_participation', N'event_name') IS NULL
    BEGIN
        PRINT N'Adding missing column event_name to student_schema.student_cultural_participation...';
        ALTER TABLE student_schema.student_cultural_participation
            ADD event_name NVARCHAR(200) NOT NULL
                CONSTRAINT DF_student_cultural_part_event_name DEFAULT (N'') WITH VALUES;

        -- Backfill event_name from announcement title if announcement table exists
        IF OBJECT_ID(N'management_schema.announcement', N'U') IS NOT NULL
        BEGIN
            UPDATE cp
            SET cp.event_name = a.title
            FROM student_schema.student_cultural_participation cp
            INNER JOIN management_schema.announcement a
                ON a.announcement_id = cp.announcement_id
            WHERE cp.event_name = N'';
        END;

        PRINT N'Column event_name added and backfilled successfully.';
    END;
END;
GO

-- =============================================================================
-- 2. INDEXES
-- =============================================================================

-- Filtered Unique Index: Enforce 1 active participation record per student per announcement
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_student_cultural_part_student_announcement_active'
      AND object_id = OBJECT_ID(N'student_schema.student_cultural_participation')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_student_cultural_part_student_announcement_active
        ON student_schema.student_cultural_participation (student_id, announcement_id)
        WHERE is_active = 1;
    PRINT N'Created unique index UX_student_cultural_part_student_announcement_active.';
END;
GO

-- Query Pattern 1 & 5: Student cultural profile & historical participation across years
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_cultural_part_student_history'
      AND object_id = OBJECT_ID(N'student_schema.student_cultural_participation')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_cultural_part_student_history
        ON student_schema.student_cultural_participation (student_id, academic_year_id, is_active)
        INCLUDE (announcement_id, event_name, category, role_involvement, result, participation_status, participation_date);
    PRINT N'Created index IX_student_cultural_part_student_history.';
END;
GO

-- Query Pattern 2: Event-wise participants list
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_cultural_part_announcement_active'
      AND object_id = OBJECT_ID(N'student_schema.student_cultural_participation')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_cultural_part_announcement_active
        ON student_schema.student_cultural_participation (announcement_id, is_active)
        INCLUDE (event_name, student_id, category, role_involvement, result, participation_status, participation_date);
    PRINT N'Created index IX_student_cultural_part_announcement_active.';
END;
GO

-- Query Pattern 3: Section-wise / class-wise participation records
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_cultural_part_section_year'
      AND object_id = OBJECT_ID(N'student_schema.student_cultural_participation')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_cultural_part_section_year
        ON student_schema.student_cultural_participation (section_id, academic_year_id, is_active)
        INCLUDE (student_id, announcement_id, event_name, class_id, category, participation_status);
    PRINT N'Created index IX_student_cultural_part_section_year.';
END;
GO

-- Query Pattern 4: Records managed by a specific Class Teacher
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_cultural_part_teacher_active'
      AND object_id = OBJECT_ID(N'student_schema.student_cultural_participation')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_cultural_part_teacher_active
        ON student_schema.student_cultural_participation (teacher_id, is_active)
        INCLUDE (student_id, announcement_id, event_name, section_id, participation_status);
    PRINT N'Created index IX_student_cultural_part_teacher_active.';
END;
GO

-- Query Pattern 6: School/Branch/Year aggregated reporting
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_cultural_part_school_branch_year'
      AND object_id = OBJECT_ID(N'student_schema.student_cultural_participation')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_cultural_part_school_branch_year
        ON student_schema.student_cultural_participation (school_id, branch_id, academic_year_id, is_active)
        INCLUDE (announcement_id, event_name, student_id, category, participation_status);
    PRINT N'Created index IX_student_cultural_part_school_branch_year.';
END;
GO

PRINT N'Migration 023_cultural_participation.sql completed successfully.';
GO

/* END INLINE MIGRATION: 023_cultural_participation.sql */

/* BEGIN INLINE MIGRATION: 024_teacher_designation.sql */
/* Module migration: 024_teacher_designation.sql */
/*
    Migration: 024_teacher_designation
    Purpose:   Add designation VARCHAR(100) NOT NULL column to teachers_schema.teacher,
               populated by mapping each teacher's subject_id to the authoritative
               management_schema.subject.subject_name and generating designation
               as '<subject_name> Teacher'.

    Design notes:
    - Authoritative source for subject mapping: management_schema.subject (subject_id -> subject_name).
    - No separate designation master table created.
    - Preserves all existing data, PKs, FKs, constraints, indexes, and relationships.
    - Separated by GO batches to guarantee clean compilation in SSMS and sqlcmd.
    - Validates that every teacher has a non-NULL designation matching <subject_name> Teacher.

    Rollback:
    - See database/migrations/rollback/024_teacher_designation_rollback.sql
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Applying Migration 024: Add designation to teachers_schema.teacher...';
PRINT N'========================================================================';

-- -----------------------------------------------------------------------------
-- Step 1: Detect and add column as VARCHAR(100) NULL if missing
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'teachers_schema.teacher', N'designation') IS NULL
    BEGIN
        PRINT N'1. Adding column designation VARCHAR(100) NULL...';
        ALTER TABLE teachers_schema.teacher
            ADD designation VARCHAR(100) NULL;
        PRINT N'   âœ” Column designation added.';
    END
    ELSE
    BEGIN
        PRINT N'1. Column designation already exists.';
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- Step 2: Populate designation mapping subject_id -> subject_name + ' Teacher'
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    PRINT N'2. Populating designation from authoritative subject master...';
    UPDATE t
    SET t.designation = CONCAT(s.subject_name, ' Teacher')
    FROM teachers_schema.teacher t
    INNER JOIN management_schema.subject s
        ON s.subject_id = t.subject_id
    WHERE t.designation IS NULL
       OR t.designation <> CONCAT(s.subject_name, ' Teacher');
    PRINT N'   âœ” Populated teacher records.';
END;
GO

-- -----------------------------------------------------------------------------
-- Step 3: Enforce NOT NULL constraint once existing records are populated
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'teachers_schema.teacher')
          AND name = N'designation'
          AND is_nullable = 1
    )
    BEGIN
        IF EXISTS (SELECT 1 FROM teachers_schema.teacher WHERE designation IS NULL)
        BEGIN
            THROW 50001, N'Cannot alter designation to NOT NULL: unmapped teachers exist with NULL designation.', 1;
        END;

        PRINT N'3. Enforcing NOT NULL constraint on column designation...';
        ALTER TABLE teachers_schema.teacher
            ALTER COLUMN designation VARCHAR(100) NOT NULL;
        PRINT N'   âœ” Column designation is now VARCHAR(100) NOT NULL.';
    END
    ELSE
    BEGIN
        PRINT N'3. Column designation is already NOT NULL.';
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- Step 4: Strict validation: verify every single teacher has valid designation
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    PRINT N'4. Validating teacher designations...';
    IF EXISTS (
        SELECT 1
        FROM teachers_schema.teacher t
        LEFT JOIN management_schema.subject s
            ON s.subject_id = t.subject_id
        WHERE t.designation IS NULL
           OR t.designation <> CONCAT(s.subject_name, ' Teacher')
    )
    BEGIN
        THROW 50002, N'Validation failed: Found teacher records where designation is NULL or does not match <subject_name> Teacher.', 1;
    END;
    PRINT N'   âœ” Validation passed: All teachers verified with non-NULL designation matching authoritative subject master.';
END;
GO

PRINT N'========================================================================';
PRINT N'Migration 024: Completed successfully.';
PRINT N'========================================================================';
GO

/* END INLINE MIGRATION: 024_teacher_designation.sql */

/* BEGIN INLINE MIGRATION: 025_sports_and_grievance_department.sql */
/*
    Migration: 025_sports_and_grievance_department.sql
    Module:    SSMS Server Table Sync (sports_schema, management_schema, student_schema, finance_schema)
    Purpose:   Synchronize missing application tables, schemas, and columns from SSMS server:
               1. sports_schema.student_sport_history
               2. management_schema.grievance_department
               3. student_schema.student_leave_status_history
               4. finance_schema.fee_payment_transaction.status column
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Applying Migration 025: SSMS Server Tables and Schema Sync...';
PRINT N'========================================================================';

-- -----------------------------------------------------------------------------
-- 1. Ensure sports_schema exists
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sports_schema')
BEGIN
    PRINT N'Creating schema sports_schema...';
    EXEC(N'CREATE SCHEMA sports_schema AUTHORIZATION dbo;');
END;
GO

-- -----------------------------------------------------------------------------
-- 2. TABLE: management_schema.grievance_department
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'management_schema.grievance_department', N'U') IS NULL
BEGIN
    PRINT N'Creating table management_schema.grievance_department...';
    CREATE TABLE management_schema.grievance_department
    (
        department_id       BIGINT          NOT NULL IDENTITY(1, 1),
        school_id           BIGINT          NOT NULL,
        branch_id           BIGINT          NULL,
        responsible_user_id BIGINT          NOT NULL,
        is_active           BIT             NOT NULL CONSTRAINT DF_grievance_department_is_active DEFAULT (1),
        created_at          DATETIME2(0)    NOT NULL CONSTRAINT DF_grievance_department_created_at DEFAULT (SYSUTCDATETIME()),
        created_by          BIGINT          NULL,
        updated_at          DATETIME2(0)    NOT NULL CONSTRAINT DF_grievance_department_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by          BIGINT          NULL,
        row_version         ROWVERSION      NOT NULL,
        CONSTRAINT PK_grievance_department PRIMARY KEY CLUSTERED (department_id),
        CONSTRAINT UQ_grievance_department_school_branch UNIQUE NONCLUSTERED (school_id, branch_id),
        CONSTRAINT FK_grievance_department_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_grievance_department_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_grievance_department_responsible_user FOREIGN KEY (responsible_user_id) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_grievance_department_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_grievance_department_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 3. TABLE: student_schema.student_leave_status_history
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'student_schema.student_leave_status_history', N'U') IS NULL
BEGIN
    PRINT N'Creating table student_schema.student_leave_status_history...';
    CREATE TABLE student_schema.student_leave_status_history
    (
        student_leave_status_history_id BIGINT          NOT NULL IDENTITY(1, 1),
        student_leave_id                BIGINT          NOT NULL,
        old_status                      NVARCHAR(20)    NULL,
        new_status                      NVARCHAR(20)    NOT NULL,
        changed_by                      BIGINT          NOT NULL,
        changed_at                      DATETIME2(0)    NOT NULL CONSTRAINT DF_student_leave_status_history_changed_at DEFAULT (SYSUTCDATETIME()),
        remarks                         NVARCHAR(500)   NULL,
        row_version                     ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_leave_status_history PRIMARY KEY CLUSTERED (student_leave_status_history_id),
        CONSTRAINT FK_student_leave_status_history_leave FOREIGN KEY (student_leave_id)
            REFERENCES student_schema.student_leave (student_leave_id) ON DELETE CASCADE,
        CONSTRAINT FK_student_leave_status_history_changed_by FOREIGN KEY (changed_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 4. TABLE: sports_schema.student_sport_history
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'sports_schema.student_sport_history', N'U') IS NULL
BEGIN
    PRINT N'Creating table sports_schema.student_sport_history...';
    CREATE TABLE sports_schema.student_sport_history
    (
        student_sport_history_id BIGINT          NOT NULL IDENTITY(1, 1),
        student_id               BIGINT          NOT NULL,
        school_id                BIGINT          NOT NULL,
        branch_id                BIGINT          NOT NULL,
        class_id                 BIGINT          NOT NULL,
        section_id               BIGINT          NOT NULL,
        sport_name               VARCHAR(100)    NOT NULL,
        announcement_id          BIGINT          NULL,
        activity_date            DATE            NOT NULL,
        activity_name            VARCHAR(200)    NOT NULL,
        result                   VARCHAR(200)    NULL,
        created_at               DATETIME2(3)    NOT NULL CONSTRAINT DF_student_sport_history_created_at DEFAULT (SYSUTCDATETIME()),
        created_by               BIGINT          NOT NULL,
        updated_at               DATETIME2(3)    NULL,
        updated_by               BIGINT          NULL,
        row_version              ROWVERSION      NOT NULL,
        sport_category           VARCHAR(100)    NOT NULL,
        CONSTRAINT PK_student_sport_history PRIMARY KEY CLUSTERED (student_sport_history_id),
        CONSTRAINT FK_student_sport_history_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_sport_history_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_sport_history_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_sport_history_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_sport_history_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_sport_history_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_sport_history_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 5. COLUMN: finance_schema.fee_payment_transaction.status
-- -----------------------------------------------------------------------------
IF COL_LENGTH(N'finance_schema.fee_payment_transaction', N'status') IS NULL
BEGIN
    PRINT N'Adding column status to finance_schema.fee_payment_transaction...';
    ALTER TABLE finance_schema.fee_payment_transaction
        ADD [status] VARCHAR(50) NULL CONSTRAINT DF_fee_payment_transaction_status DEFAULT ('PENDING');
END;
GO

-- -----------------------------------------------------------------------------
-- 5B. COLUMNS: student_schema.student_leave (cancellation and duration)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND COL_LENGTH(N'student_schema.student_leave', N'cancelled_at') IS NULL
BEGIN
    PRINT N'Adding column cancelled_at to student_schema.student_leave...';
    ALTER TABLE student_schema.student_leave ADD cancelled_at DATETIME2(0) NULL;
END;
GO

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND COL_LENGTH(N'student_schema.student_leave', N'cancelled_by') IS NULL
BEGIN
    PRINT N'Adding column cancelled_by to student_schema.student_leave...';
    ALTER TABLE student_schema.student_leave ADD cancelled_by BIGINT NULL;
END;
GO

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND COL_LENGTH(N'student_schema.student_leave', N'cancellation_remarks') IS NULL
BEGIN
    PRINT N'Adding column cancellation_remarks to student_schema.student_leave...';
    ALTER TABLE student_schema.student_leave ADD cancellation_remarks NVARCHAR(500) NULL;
END;
GO

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND COL_LENGTH(N'student_schema.student_leave', N'duration') IS NULL
BEGIN
    PRINT N'Adding column duration to student_schema.student_leave...';
    ALTER TABLE student_schema.student_leave
        ADD duration DECIMAL(4, 2) NOT NULL CONSTRAINT DF_student_leave_duration DEFAULT ((1.00)) WITH VALUES;
END;
GO

IF OBJECT_ID(N'student_schema.student_leave', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.foreign_keys
       WHERE name = N'FK_student_leave_cancelled_by'
         AND parent_object_id = OBJECT_ID(N'student_schema.student_leave')
   )
BEGIN
    ALTER TABLE student_schema.student_leave
        ADD CONSTRAINT FK_student_leave_cancelled_by FOREIGN KEY (cancelled_by)
            REFERENCES security_schema.users (user_id);
END;
GO

-- -----------------------------------------------------------------------------
-- 6. Indexes
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_sport_history_student'
      AND object_id = OBJECT_ID(N'sports_schema.student_sport_history')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_sport_history_student
        ON sports_schema.student_sport_history (school_id, branch_id, student_id, activity_date DESC)
        INCLUDE (sport_name, sport_category, result);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_leave_status_history_leave'
      AND object_id = OBJECT_ID(N'student_schema.student_leave_status_history')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_leave_status_history_leave
        ON student_schema.student_leave_status_history (student_leave_id, changed_at DESC);
END;
GO

/* END INLINE MIGRATION: 025_sports_and_grievance_department.sql */


PRINT N'THINKIGEN ERP schema execution complete.';
SELECT
    s.name AS schema_name,
    COUNT(*) AS table_count
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name IN (
    N'security_schema', N'management_schema', N'student_schema',
    N'teachers_schema', N'finance_schema', N'library_schema',
    N'transport_schema', N'alumni_schema', N'sports_schema'
)
GROUP BY s.name
ORDER BY s.name;

DECLARE @ThinkigenTableCount INT = (
    SELECT COUNT(*)
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name IN (
        N'security_schema', N'management_schema', N'student_schema',
        N'teachers_schema', N'finance_schema', N'library_schema',
        N'transport_schema', N'alumni_schema', N'sports_schema'
    )
);

PRINT CONCAT(N'Thinkigen schema validation passed: ', @ThinkigenTableCount, N' application tables across 9 schemas.');
GO
