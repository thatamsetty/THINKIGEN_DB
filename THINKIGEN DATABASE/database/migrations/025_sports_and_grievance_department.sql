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
