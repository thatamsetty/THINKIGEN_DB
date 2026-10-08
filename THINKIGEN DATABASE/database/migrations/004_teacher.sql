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

