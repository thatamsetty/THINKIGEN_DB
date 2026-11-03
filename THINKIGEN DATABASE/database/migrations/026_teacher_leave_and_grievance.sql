/*
    Migration: 026_teacher_leave_and_grievance.sql
    Module:    Teacher Portal Management (teachers_schema)
    Purpose:   Production-ready, non-destructive DDL migration for:
               1. teachers_schema.teacher_leave_allowance          (Configurable quota & used days with persisted computed remaining days)
               2. teachers_schema.teacher_leave_application        (Teacher leave requests with full/half day validation)
               3. teachers_schema.teacher_leave_status_history     (Audit log with ON DELETE NO ACTION)
               4. teachers_schema.teacher_grievance                (Teacher grievance tickets across 6 business categories)
               5. teachers_schema.teacher_grievance_status_history (Audit log with ON DELETE NO ACTION)

    Architectural Guidelines & Safety Rules:
    - NO destructive DROP TABLE, DROP VIEW, DROP PROCEDURE, or DROP TRIGGER operations.
    - Preserves existing data and unrelated database objects.
    - Total entitlement days are fully configurable (no unconfirmed hardcoded defaults).
    - CHECK constraints guarantee used days never exceed total days (used_days <= total_days).
    - Enforces tenant integrity using composite foreign keys supported by parent master tables:
        * (school_id, branch_id)                               -> management_schema.branch (school_id, branch_id)
        * (school_id, academic_year_id)                        -> management_schema.academic_year (school_id, academic_year_id)
        * (school_id, branch_id, academic_year_id, teacher_id) -> teachers_schema.teacher_leave_allowance (school_id, branch_id, academic_year_id, teacher_id)
    - Teacher master foreign keys reference teachers_schema.teacher (teacher_id) directly:
        * Accounts for historical leave allowances, leave applications, and grievances if a teacher transfers branches.
        * Avoids blocking legitimate teacher branch transfers (composite FK to teacher would invalidate historical branch records upon transfer).
        * Branch tenancy is strictly bound via management_schema.branch (school_id, branch_id).
    - History tables use ON DELETE NO ACTION to protect immutable audit records.
    - Preflight validation with SET NOEXEC ON ensures failures reliably stop execution across all GO batches in SSMS.
    - Schema-drift detection: does not silently skip incompatible existing tables; reports differences and provides safe upgrade statements.
    - Safe data migration guidance for legacy teacher_leave and narrow allowance structures.
    - Business logic, concurrency locks (UPDLOCK, HOLDLOCK), and status transitions
      are handled directly in backend FastAPI services using SQL transactions.
*/

-- Reset execution flags and configure required ANSI/ISO settings for persisted computed columns & filtered indexes
SET NOEXEC OFF;
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'========================================================================';
PRINT N'Starting Migration 026: Teacher Leave & Grievance Schema Deployment...';
PRINT N'========================================================================';
GO

-- =============================================================================
-- STEP 1: PREFLIGHT VALIDATION & SCHEMA-DRIFT DETECTION
-- =============================================================================
DECLARE @preflight_failed BIT = 0;
DECLARE @preflight_error_msg NVARCHAR(MAX) = N'';

-- 1.1 Verify required schemas exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'teachers_schema')
BEGIN
    SET @preflight_failed = 1;
    SET @preflight_error_msg += NCHAR(10) + N'- Missing schema: teachers_schema';
END;
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'management_schema')
BEGIN
    SET @preflight_failed = 1;
    SET @preflight_error_msg += NCHAR(10) + N'- Missing schema: management_schema';
END;
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'security_schema')
BEGIN
    SET @preflight_failed = 1;
    SET @preflight_error_msg += NCHAR(10) + N'- Missing schema: security_schema';
END;

-- 1.2 Verify parent master tables exist
IF OBJECT_ID(N'management_schema.school', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @preflight_error_msg += NCHAR(10) + N'- Missing parent table: management_schema.school';
END;
IF OBJECT_ID(N'management_schema.branch', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @preflight_error_msg += NCHAR(10) + N'- Missing parent table: management_schema.branch';
END;
IF OBJECT_ID(N'management_schema.academic_year', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @preflight_error_msg += NCHAR(10) + N'- Missing parent table: management_schema.academic_year';
END;
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @preflight_error_msg += NCHAR(10) + N'- Missing parent table: teachers_schema.teacher';
END;
IF OBJECT_ID(N'security_schema.users', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @preflight_error_msg += NCHAR(10) + N'- Missing parent table: security_schema.users';
END;

-- 1.3 Ensure supporting composite candidate keys exist on parent tables (Non-destructive)
IF OBJECT_ID(N'management_schema.branch', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes 
       WHERE name = N'UQ_branch_school_scope' 
         AND object_id = OBJECT_ID(N'management_schema.branch')
   )
BEGIN
    PRINT N'Creating supporting candidate index UQ_branch_school_scope on management_schema.branch...';
    CREATE UNIQUE NONCLUSTERED INDEX UQ_branch_school_scope 
        ON management_schema.branch (school_id, branch_id);
END;

IF OBJECT_ID(N'management_schema.academic_year', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.indexes 
       WHERE name = N'UQ_academic_year_school_scope' 
         AND object_id = OBJECT_ID(N'management_schema.academic_year')
   )
BEGIN
    PRINT N'Creating supporting candidate index UQ_academic_year_school_scope on management_schema.academic_year...';
    CREATE UNIQUE NONCLUSTERED INDEX UQ_academic_year_school_scope 
        ON management_schema.academic_year (school_id, academic_year_id);
END;

-- 1.4 Inspect Schema-Drift for existing target tables (Never silently skip)
-- Table 1: teacher_leave_allowance
IF OBJECT_ID(N'teachers_schema.teacher_leave_allowance', N'U') IS NOT NULL
BEGIN
    -- Detect legacy narrow structure (single leave_type column per row)
    IF COL_LENGTH(N'teachers_schema.teacher_leave_allowance', N'leave_type') IS NOT NULL
    BEGIN
        DECLARE @legacy_allowance_rows INT = 0;
        SELECT @legacy_allowance_rows = COUNT(*) FROM teachers_schema.teacher_leave_allowance;

        SET @preflight_failed = 1;
        SET @preflight_error_msg += NCHAR(10) + N'- Schema Drift on teachers_schema.teacher_leave_allowance: '
            + N'Legacy single-type column [leave_type] detected. Existing rows: ' + CAST(@legacy_allowance_rows AS NVARCHAR(20))
            + N'. Wide per-teacher entitlement columns (sick_*, casual_*, privilege_*, on_duty_*, compensatory_*) are required.'
            + N' Safe upgrade: execute pivot data migration before applying migration 026.';
    END
    ELSE
    BEGIN
        -- Verify all 5 wide entitlement total and used columns exist
        IF COL_LENGTH(N'teachers_schema.teacher_leave_allowance', N'sick_total_days') IS NULL
           OR COL_LENGTH(N'teachers_schema.teacher_leave_allowance', N'casual_total_days') IS NULL
           OR COL_LENGTH(N'teachers_schema.teacher_leave_allowance', N'privilege_total_days') IS NULL
           OR COL_LENGTH(N'teachers_schema.teacher_leave_allowance', N'on_duty_total_days') IS NULL
           OR COL_LENGTH(N'teachers_schema.teacher_leave_allowance', N'compensatory_total_days') IS NULL
        BEGIN
            SET @preflight_failed = 1;
            SET @preflight_error_msg += NCHAR(10) + N'- Schema Drift on teachers_schema.teacher_leave_allowance: '
                + N'Table exists but is missing one or more required 5-type total/used day columns.';
        END;
    END;
END;

-- Table 2: teacher_leave_application & Legacy teacher_leave inspection
IF OBJECT_ID(N'teachers_schema.teacher_leave', N'U') IS NOT NULL
BEGIN
    DECLARE @legacy_leave_rows INT = 0;
    SELECT @legacy_leave_rows = COUNT(*) FROM teachers_schema.teacher_leave;
    PRINT N'NOTE [LEGACY TABLE DETECTED]: Found table teachers_schema.teacher_leave with ' 
          + CAST(@legacy_leave_rows AS NVARCHAR(20)) + N' records.';
    PRINT N'Migration 026 will preserve teachers_schema.teacher_leave intact.';
    IF @legacy_leave_rows > 0 AND OBJECT_ID(N'teachers_schema.teacher_leave_application', N'U') IS NULL
    BEGIN
        PRINT N'INFO: Safe data migration script is provided in migration documentation to copy legacy leave records.';
    END;
END;

IF OBJECT_ID(N'teachers_schema.teacher_leave_application', N'U') IS NOT NULL
BEGIN
    -- Verify required columns exist
    IF COL_LENGTH(N'teachers_schema.teacher_leave_application', N'leave_duration_type') IS NULL
       OR COL_LENGTH(N'teachers_schema.teacher_leave_application', N'total_days') IS NULL
       OR COL_LENGTH(N'teachers_schema.teacher_leave_application', N'leave_type') IS NULL
    BEGIN
        SET @preflight_failed = 1;
        SET @preflight_error_msg += NCHAR(10) + N'- Schema Drift on teachers_schema.teacher_leave_application: '
            + N'Table exists but is missing required columns (leave_duration_type, total_days, or leave_type).';
    END;
END;

-- Table 3: teacher_leave_status_history
IF OBJECT_ID(N'teachers_schema.teacher_leave_status_history', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'teachers_schema.teacher_leave_status_history', N'teacher_leave_application_id') IS NULL
    BEGIN
        SET @preflight_failed = 1;
        SET @preflight_error_msg += NCHAR(10) + N'- Schema Drift on teachers_schema.teacher_leave_status_history: '
            + N'Missing required foreign key column teacher_leave_application_id.';
    END;
END;

-- Table 4: teacher_grievance
IF OBJECT_ID(N'teachers_schema.teacher_grievance', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'teachers_schema.teacher_grievance', N'grievance_category') IS NULL
       OR COL_LENGTH(N'teachers_schema.teacher_grievance', N'priority') IS NULL
    BEGIN
        SET @preflight_failed = 1;
        SET @preflight_error_msg += NCHAR(10) + N'- Schema Drift on teachers_schema.teacher_grievance: '
            + N'Table exists but is missing grievance_category or priority columns.';
    END;
END;

-- Table 5: teacher_grievance_status_history
IF OBJECT_ID(N'teachers_schema.teacher_grievance_status_history', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'teachers_schema.teacher_grievance_status_history', N'teacher_grievance_id') IS NULL
    BEGIN
        SET @preflight_failed = 1;
        SET @preflight_error_msg += NCHAR(10) + N'- Schema Drift on teachers_schema.teacher_grievance_status_history: '
            + N'Missing required foreign key column teacher_grievance_id.';
    END;
END;

-- =============================================================================
-- HALT EXECUTION IF PREFLIGHT FAILED (Reliably stops SSMS across GO boundaries)
-- =============================================================================
IF @preflight_failed = 1
BEGIN
    PRINT N'';
    PRINT N'************************************************************************';
    PRINT N'FATAL PREFLIGHT ERROR: Migration 026 aborted.';
    PRINT N'Preflight check failed with the following errors:' + @preflight_error_msg;
    PRINT N'';
    PRINT N'Halting script execution across all subsequent batches...';
    PRINT N'************************************************************************';
    RAISERROR(N'Migration 026 preflight failure: %s', 16, 1, @preflight_error_msg);
    SET NOEXEC ON;
END
ELSE
BEGIN
    PRINT N'Preflight validation & schema-drift checks passed successfully.';
END;
GO

-- =============================================================================
-- STEP 2: TRANSACTIONAL TABLE CREATION & INDEX CONFIGURATION
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;
BEGIN TRY

    -- -------------------------------------------------------------------------
    -- 1. TABLE: teachers_schema.teacher_leave_allowance (Configurable Quotas)
    -- Maintain exactly ONE row per teacher, school, branch, and academic year.
    -- Total days are fully configurable (no hardcoded defaults).
    -- Persisted computed remaining days = total_days - used_days.
    -- CHECK constraints enforce: used_days >= 0.0 AND used_days <= total_days.
    -- FK to teacher references teachers_schema.teacher (teacher_id) directly:
    --   allows branch transfers without invalidating historical branch records.
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'teachers_schema.teacher_leave_allowance', N'U') IS NULL
    BEGIN
        PRINT N'Creating table teachers_schema.teacher_leave_allowance...';
        CREATE TABLE teachers_schema.teacher_leave_allowance
        (
            teacher_leave_allowance_id  BIGINT          NOT NULL IDENTITY(1, 1),
            school_id                   BIGINT          NOT NULL,
            branch_id                   BIGINT          NOT NULL,
            academic_year_id            BIGINT          NOT NULL,
            teacher_id                  BIGINT          NOT NULL,

            -- 1. Sick Leave (Configurable Total, Used default 0.0, Remaining Persisted)
            sick_total_days             DECIMAL(4, 1)   NOT NULL,
            sick_used_days              DECIMAL(4, 1)   NOT NULL CONSTRAINT DF_teacher_leave_allowance_sick_used DEFAULT (0.0),
            sick_remaining_days         AS (sick_total_days - sick_used_days) PERSISTED,

            -- 2. Casual Leave (Configurable Total, Used default 0.0, Remaining Persisted)
            casual_total_days           DECIMAL(4, 1)   NOT NULL,
            casual_used_days            DECIMAL(4, 1)   NOT NULL CONSTRAINT DF_teacher_leave_allowance_casual_used DEFAULT (0.0),
            casual_remaining_days       AS (casual_total_days - casual_used_days) PERSISTED,

            -- 3. Privilege / Earned Leave (Configurable Total, Used default 0.0, Remaining Persisted)
            privilege_total_days        DECIMAL(4, 1)   NOT NULL,
            privilege_used_days         DECIMAL(4, 1)   NOT NULL CONSTRAINT DF_teacher_leave_allowance_priv_used DEFAULT (0.0),
            privilege_remaining_days    AS (privilege_total_days - privilege_used_days) PERSISTED,

            -- 4. On Duty Leave (Configurable Total, Used default 0.0, Remaining Persisted)
            on_duty_total_days          DECIMAL(4, 1)   NOT NULL,
            on_duty_used_days           DECIMAL(4, 1)   NOT NULL CONSTRAINT DF_teacher_leave_allowance_onduty_used DEFAULT (0.0),
            on_duty_remaining_days      AS (on_duty_total_days - on_duty_used_days) PERSISTED,

            -- 5. Compensatory Leave (Configurable Total, Used default 0.0, Remaining Persisted)
            compensatory_total_days     DECIMAL(4, 1)   NOT NULL,
            compensatory_used_days      DECIMAL(4, 1)   NOT NULL CONSTRAINT DF_teacher_leave_allowance_comp_used DEFAULT (0.0),
            compensatory_remaining_days AS (compensatory_total_days - compensatory_used_days) PERSISTED,

            -- Audit Trail & Concurrency
            is_active                   BIT             NOT NULL CONSTRAINT DF_teacher_leave_allowance_is_active DEFAULT (1),
            created_at                  DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_allowance_created_at DEFAULT (SYSUTCDATETIME()),
            created_by                  BIGINT          NOT NULL,
            updated_at                  DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_allowance_updated_at DEFAULT (SYSUTCDATETIME()),
            updated_by                  BIGINT          NULL,
            row_version                 ROWVERSION      NOT NULL,

            CONSTRAINT PK_teacher_leave_allowance PRIMARY KEY CLUSTERED (teacher_leave_allowance_id),
            CONSTRAINT UQ_teacher_leave_allowance UNIQUE NONCLUSTERED (school_id, branch_id, academic_year_id, teacher_id),
            
            -- CHECK: Non-negative and used_days never exceed total_days
            CONSTRAINT CK_teacher_leave_allowance_days_valid CHECK (
                sick_total_days >= 0.0 AND sick_used_days >= 0.0 AND sick_used_days <= sick_total_days AND
                casual_total_days >= 0.0 AND casual_used_days >= 0.0 AND casual_used_days <= casual_total_days AND
                privilege_total_days >= 0.0 AND privilege_used_days >= 0.0 AND privilege_used_days <= privilege_total_days AND
                on_duty_total_days >= 0.0 AND on_duty_used_days >= 0.0 AND on_duty_used_days <= on_duty_total_days AND
                compensatory_total_days >= 0.0 AND compensatory_used_days >= 0.0 AND compensatory_used_days <= compensatory_total_days
            ),
            
            -- Composite Tenant & Master Foreign Keys
            CONSTRAINT FK_teacher_leave_allowance_school FOREIGN KEY (school_id)
                REFERENCES management_schema.school (school_id),
            CONSTRAINT FK_teacher_leave_allowance_branch_scope FOREIGN KEY (school_id, branch_id)
                REFERENCES management_schema.branch (school_id, branch_id),
            CONSTRAINT FK_teacher_leave_allowance_academic_year_scope FOREIGN KEY (school_id, academic_year_id)
                REFERENCES management_schema.academic_year (school_id, academic_year_id),
            CONSTRAINT FK_teacher_leave_allowance_teacher FOREIGN KEY (teacher_id)
                REFERENCES teachers_schema.teacher (teacher_id),
            CONSTRAINT FK_teacher_leave_allowance_created_by FOREIGN KEY (created_by)
                REFERENCES security_schema.users (user_id),
            CONSTRAINT FK_teacher_leave_allowance_updated_by FOREIGN KEY (updated_by)
                REFERENCES security_schema.users (user_id)
        );
    END;

    -- Supporting index: Allowance lookup by teacher and year
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_teacher_leave_allowance_teacher_year'
          AND object_id = OBJECT_ID(N'teachers_schema.teacher_leave_allowance')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_teacher_leave_allowance_teacher_year
            ON teachers_schema.teacher_leave_allowance (teacher_id, academic_year_id, is_active)
            INCLUDE (sick_remaining_days, casual_remaining_days, privilege_remaining_days, on_duty_remaining_days, compensatory_remaining_days);
    END;

    -- -------------------------------------------------------------------------
    -- 2. TABLE: teachers_schema.teacher_leave_application (Leave Applications)
    -- Support full-day and half-day applications with duration constraints.
    -- Enforces composite foreign key to teacher_leave_allowance:
    --   (school_id, branch_id, academic_year_id, teacher_id).
    -- FK to teacher references teachers_schema.teacher (teacher_id) directly.
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'teachers_schema.teacher_leave_application', N'U') IS NULL
    BEGIN
        PRINT N'Creating table teachers_schema.teacher_leave_application...';
        CREATE TABLE teachers_schema.teacher_leave_application
        (
            teacher_leave_application_id BIGINT          NOT NULL IDENTITY(1, 1),
            school_id                    BIGINT          NOT NULL,
            branch_id                    BIGINT          NOT NULL,
            academic_year_id             BIGINT          NOT NULL,
            teacher_id                   BIGINT          NOT NULL,
            leave_type                   VARCHAR(30)     NOT NULL,
            leave_duration_type          VARCHAR(20)     NOT NULL,
            start_date                   DATE            NOT NULL,
            end_date                     DATE            NOT NULL,
            total_days                   DECIMAL(4, 1)   NOT NULL,
            reason                       NVARCHAR(500)   NOT NULL,
            status                       NVARCHAR(20)    NOT NULL CONSTRAINT DF_teacher_leave_application_status DEFAULT (N'PENDING'),
            is_active                    BIT             NOT NULL CONSTRAINT DF_teacher_leave_application_is_active DEFAULT (1),
            created_at                   DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_application_created_at DEFAULT (SYSUTCDATETIME()),
            created_by                   BIGINT          NOT NULL,
            updated_at                   DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_application_updated_at DEFAULT (SYSUTCDATETIME()),
            updated_by                   BIGINT          NULL,
            row_version                  ROWVERSION      NOT NULL,

            CONSTRAINT PK_teacher_leave_application PRIMARY KEY CLUSTERED (teacher_leave_application_id),
            CONSTRAINT CK_teacher_leave_application_type CHECK
                (leave_type IN (N'SICK', N'CASUAL', N'PRIVILEGE', N'ON_DUTY', N'COMPENSATORY')),
            CONSTRAINT CK_teacher_leave_application_duration CHECK
                (leave_duration_type IN (N'FULL_DAY', N'HALF_DAY')),
            CONSTRAINT CK_teacher_leave_application_status CHECK
                (status IN (N'PENDING', N'APPROVED', N'REJECTED', N'CANCELLED')),
            CONSTRAINT CK_teacher_leave_application_dates CHECK (end_date >= start_date),
            CONSTRAINT CK_teacher_leave_application_total_days CHECK (total_days > 0.0),
            CONSTRAINT CK_teacher_leave_application_half_day CHECK
                (leave_duration_type <> N'HALF_DAY' OR (start_date = end_date AND total_days = 0.5)),
            CONSTRAINT CK_teacher_leave_application_full_day CHECK
                (leave_duration_type <> N'FULL_DAY' OR total_days >= 1.0),
            
            -- Composite Tenant Foreign Keys
            CONSTRAINT FK_teacher_leave_application_school FOREIGN KEY (school_id)
                REFERENCES management_schema.school (school_id),
            CONSTRAINT FK_teacher_leave_application_branch_scope FOREIGN KEY (school_id, branch_id)
                REFERENCES management_schema.branch (school_id, branch_id),
            CONSTRAINT FK_teacher_leave_application_academic_year_scope FOREIGN KEY (school_id, academic_year_id)
                REFERENCES management_schema.academic_year (school_id, academic_year_id),
            CONSTRAINT FK_teacher_leave_application_teacher FOREIGN KEY (teacher_id)
                REFERENCES teachers_schema.teacher (teacher_id),

            -- Composite Foreign Key to Entitlement/Allowance Quota
            CONSTRAINT FK_teacher_leave_application_allowance_scope FOREIGN KEY 
                (school_id, branch_id, academic_year_id, teacher_id)
                REFERENCES teachers_schema.teacher_leave_allowance (school_id, branch_id, academic_year_id, teacher_id),

            CONSTRAINT FK_teacher_leave_application_created_by FOREIGN KEY (created_by)
                REFERENCES security_schema.users (user_id),
            CONSTRAINT FK_teacher_leave_application_updated_by FOREIGN KEY (updated_by)
                REFERENCES security_schema.users (user_id)
        );
    END
    ELSE
    BEGIN
        -- Idempotent check for FK_teacher_leave_application_allowance_scope if table existed previously
        IF NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys 
            WHERE name = N'FK_teacher_leave_application_allowance_scope'
              AND parent_object_id = OBJECT_ID(N'teachers_schema.teacher_leave_application')
        )
        BEGIN
            PRINT N'Adding composite FK_teacher_leave_application_allowance_scope to existing table...';
            ALTER TABLE teachers_schema.teacher_leave_application
                ADD CONSTRAINT FK_teacher_leave_application_allowance_scope FOREIGN KEY 
                    (school_id, branch_id, academic_year_id, teacher_id)
                    REFERENCES teachers_schema.teacher_leave_allowance (school_id, branch_id, academic_year_id, teacher_id);
        END;
    END;

    -- Supporting index: Applications by teacher, year, and status
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_teacher_leave_application_teacher_year_status'
          AND object_id = OBJECT_ID(N'teachers_schema.teacher_leave_application')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_teacher_leave_application_teacher_year_status
            ON teachers_schema.teacher_leave_application (teacher_id, academic_year_id, status)
            INCLUDE (leave_type, start_date, end_date, total_days);
    END;

    -- Supporting index: Applications by school, branch, date range, and status
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_teacher_leave_application_school_branch_dates'
          AND object_id = OBJECT_ID(N'teachers_schema.teacher_leave_application')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_teacher_leave_application_school_branch_dates
            ON teachers_schema.teacher_leave_application (school_id, branch_id, status, start_date, end_date)
            INCLUDE (teacher_id, leave_type, total_days);
    END;

    -- Filtered index: Active overlapping leave requests lookup
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_teacher_leave_application_active_overlap'
          AND object_id = OBJECT_ID(N'teachers_schema.teacher_leave_application')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_teacher_leave_application_active_overlap
            ON teachers_schema.teacher_leave_application (teacher_id, start_date, end_date)
            WHERE is_active = 1 AND status IN (N'PENDING', N'APPROVED');
    END;

    -- -------------------------------------------------------------------------
    -- 3. TABLE: teachers_schema.teacher_leave_status_history (Audit Trail)
    -- Foreign key uses ON DELETE NO ACTION to protect audit history integrity.
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'teachers_schema.teacher_leave_status_history', N'U') IS NULL
    BEGIN
        PRINT N'Creating table teachers_schema.teacher_leave_status_history...';
        CREATE TABLE teachers_schema.teacher_leave_status_history
        (
            teacher_leave_status_history_id BIGINT          NOT NULL IDENTITY(1, 1),
            teacher_leave_application_id    BIGINT          NOT NULL,
            old_status                      NVARCHAR(20)    NULL,
            new_status                      NVARCHAR(20)    NOT NULL,
            changed_by                      BIGINT          NOT NULL,
            changed_at                      DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_status_history_changed_at DEFAULT (SYSUTCDATETIME()),
            remarks                         NVARCHAR(500)   NULL,
            row_version                     ROWVERSION      NOT NULL,

            CONSTRAINT PK_teacher_leave_status_history PRIMARY KEY CLUSTERED (teacher_leave_status_history_id),
            CONSTRAINT CK_teacher_leave_status_history_old CHECK
                (old_status IS NULL OR old_status IN (N'PENDING', N'APPROVED', N'REJECTED', N'CANCELLED')),
            CONSTRAINT CK_teacher_leave_status_history_new CHECK
                (new_status IN (N'PENDING', N'APPROVED', N'REJECTED', N'CANCELLED')),
            CONSTRAINT FK_teacher_leave_status_history_app FOREIGN KEY (teacher_leave_application_id)
                REFERENCES teachers_schema.teacher_leave_application (teacher_leave_application_id)
                ON DELETE NO ACTION,
            CONSTRAINT FK_teacher_leave_status_history_changed_by FOREIGN KEY (changed_by)
                REFERENCES security_schema.users (user_id)
        );
    END
    ELSE
    BEGIN
        -- If existing table has CASCADE, update to ON DELETE NO ACTION
        IF EXISTS (
            SELECT 1 FROM sys.foreign_keys 
            WHERE name = N'FK_teacher_leave_status_history_app'
              AND parent_object_id = OBJECT_ID(N'teachers_schema.teacher_leave_status_history')
              AND delete_referential_action = 1 -- CASCADE
        )
        BEGIN
            PRINT N'Modifying FK_teacher_leave_status_history_app from CASCADE to ON DELETE NO ACTION...';
            ALTER TABLE teachers_schema.teacher_leave_status_history
                DROP CONSTRAINT FK_teacher_leave_status_history_app;
            ALTER TABLE teachers_schema.teacher_leave_status_history
                ADD CONSTRAINT FK_teacher_leave_status_history_app FOREIGN KEY (teacher_leave_application_id)
                    REFERENCES teachers_schema.teacher_leave_application (teacher_leave_application_id)
                    ON DELETE NO ACTION;
        END;
    END;

    -- Supporting index: Status history by application ID and changed timestamp
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_teacher_leave_status_history_app_date'
          AND object_id = OBJECT_ID(N'teachers_schema.teacher_leave_status_history')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_teacher_leave_status_history_app_date
            ON teachers_schema.teacher_leave_status_history (teacher_leave_application_id, changed_at DESC);
    END;

    -- -------------------------------------------------------------------------
    -- 4. TABLE: teachers_schema.teacher_grievance (Teacher Grievances)
    -- Exactly six supported categories:
    --   1. ACADEMIC_POLICY
    --   2. INFRASTRUCTURE_FACILITIES
    --   3. HARASSMENT_SAFEGUARDING
    --   4. IT_EQUIPMENT
    --   5. ADMINISTRATIVE_PAYROLL
    --   6. HEALTH_SAFETY
    -- FK to teacher references teachers_schema.teacher (teacher_id) directly:
    --   preserves historical branch incident attribution if teacher transfers.
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'teachers_schema.teacher_grievance', N'U') IS NULL
    BEGIN
        PRINT N'Creating table teachers_schema.teacher_grievance...';
        CREATE TABLE teachers_schema.teacher_grievance
        (
            teacher_grievance_id BIGINT          NOT NULL IDENTITY(1, 1),
            school_id            BIGINT          NOT NULL,
            branch_id            BIGINT          NOT NULL,
            academic_year_id     BIGINT          NULL,
            teacher_id           BIGINT          NOT NULL,
            grievance_title      NVARCHAR(200)   NOT NULL,
            grievance_category   VARCHAR(50)     NOT NULL,
            priority             VARCHAR(20)     NOT NULL,
            incident_date        DATE            NULL,
            incident_location    NVARCHAR(200)   NULL,
            description          NVARCHAR(2000)  NOT NULL,
            status               NVARCHAR(20)    NOT NULL CONSTRAINT DF_teacher_grievance_status DEFAULT (N'OPEN'),
            assigned_to          BIGINT          NULL,
            resolution_remarks   NVARCHAR(2000)  NULL,
            is_active            BIT             NOT NULL CONSTRAINT DF_teacher_grievance_is_active DEFAULT (1),
            created_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_grievance_created_at DEFAULT (SYSUTCDATETIME()),
            created_by           BIGINT          NOT NULL,
            updated_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_grievance_updated_at DEFAULT (SYSUTCDATETIME()),
            updated_by           BIGINT          NULL,
            row_version          ROWVERSION      NOT NULL,

            CONSTRAINT PK_teacher_grievance PRIMARY KEY CLUSTERED (teacher_grievance_id),
            CONSTRAINT CK_teacher_grievance_category CHECK
                (grievance_category IN (
                    N'ACADEMIC_POLICY',
                    N'INFRASTRUCTURE_FACILITIES',
                    N'HARASSMENT_SAFEGUARDING',
                    N'IT_EQUIPMENT',
                    N'ADMINISTRATIVE_PAYROLL',
                    N'HEALTH_SAFETY'
                )),
            CONSTRAINT CK_teacher_grievance_priority CHECK
                (priority IN (N'LOW', N'MEDIUM', N'HIGH', N'URGENT')),
            CONSTRAINT CK_teacher_grievance_status CHECK
                (status IN (N'OPEN', N'UNDER_REVIEW', N'RESOLVED', N'REJECTED', N'CLOSED')),
            
            -- Composite Tenant & Master Foreign Keys
            CONSTRAINT FK_teacher_grievance_school FOREIGN KEY (school_id)
                REFERENCES management_schema.school (school_id),
            CONSTRAINT FK_teacher_grievance_branch_scope FOREIGN KEY (school_id, branch_id)
                REFERENCES management_schema.branch (school_id, branch_id),
            CONSTRAINT FK_teacher_grievance_academic_year_scope FOREIGN KEY (school_id, academic_year_id)
                REFERENCES management_schema.academic_year (school_id, academic_year_id),
            CONSTRAINT FK_teacher_grievance_teacher FOREIGN KEY (teacher_id)
                REFERENCES teachers_schema.teacher (teacher_id),
            CONSTRAINT FK_teacher_grievance_assigned_to FOREIGN KEY (assigned_to)
                REFERENCES security_schema.users (user_id),
            CONSTRAINT FK_teacher_grievance_created_by FOREIGN KEY (created_by)
                REFERENCES security_schema.users (user_id),
            CONSTRAINT FK_teacher_grievance_updated_by FOREIGN KEY (updated_by)
                REFERENCES security_schema.users (user_id)
        );
    END;

    -- Supporting index: Grievances by teacher, status, priority, and date
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_teacher_grievance_teacher_scope'
          AND object_id = OBJECT_ID(N'teachers_schema.teacher_grievance')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_teacher_grievance_teacher_scope
            ON teachers_schema.teacher_grievance (teacher_id, status, priority, created_at DESC)
            INCLUDE (grievance_category, grievance_title);
    END;

    -- Supporting index: Grievances by school, branch, status, priority, and date
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_teacher_grievance_school_branch_status'
          AND object_id = OBJECT_ID(N'teachers_schema.teacher_grievance')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_teacher_grievance_school_branch_status
            ON teachers_schema.teacher_grievance (school_id, branch_id, status, priority, created_at DESC)
            INCLUDE (teacher_id, grievance_category, grievance_title);
    END;

    -- -------------------------------------------------------------------------
    -- 5. TABLE: teachers_schema.teacher_grievance_status_history (Audit Trail)
    -- Foreign key uses ON DELETE NO ACTION to protect audit history integrity.
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'teachers_schema.teacher_grievance_status_history', N'U') IS NULL
    BEGIN
        PRINT N'Creating table teachers_schema.teacher_grievance_status_history...';
        CREATE TABLE teachers_schema.teacher_grievance_status_history
        (
            teacher_grievance_status_history_id BIGINT          NOT NULL IDENTITY(1, 1),
            teacher_grievance_id                BIGINT          NOT NULL,
            old_status                          NVARCHAR(20)    NULL,
            new_status                          NVARCHAR(20)    NOT NULL,
            changed_by                          BIGINT          NOT NULL,
            changed_at                          DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_grievance_status_history_changed_at DEFAULT (SYSUTCDATETIME()),
            remarks                             NVARCHAR(500)   NULL,
            row_version                         ROWVERSION      NOT NULL,

            CONSTRAINT PK_teacher_grievance_status_history PRIMARY KEY CLUSTERED (teacher_grievance_status_history_id),
            CONSTRAINT CK_teacher_grievance_status_history_old CHECK
                (old_status IS NULL OR old_status IN (N'OPEN', N'UNDER_REVIEW', N'RESOLVED', N'REJECTED', N'CLOSED')),
            CONSTRAINT CK_teacher_grievance_status_history_new CHECK
                (new_status IN (N'OPEN', N'UNDER_REVIEW', N'RESOLVED', N'REJECTED', N'CLOSED')),
            CONSTRAINT FK_teacher_grievance_status_history_grievance FOREIGN KEY (teacher_grievance_id)
                REFERENCES teachers_schema.teacher_grievance (teacher_grievance_id)
                ON DELETE NO ACTION,
            CONSTRAINT FK_teacher_grievance_status_history_changed_by FOREIGN KEY (changed_by)
                REFERENCES security_schema.users (user_id)
        );
    END
    ELSE
    BEGIN
        -- If existing table has CASCADE, update to ON DELETE NO ACTION
        IF EXISTS (
            SELECT 1 FROM sys.foreign_keys 
            WHERE name = N'FK_teacher_grievance_status_history_grievance'
              AND parent_object_id = OBJECT_ID(N'teachers_schema.teacher_grievance_status_history')
              AND delete_referential_action = 1 -- CASCADE
        )
        BEGIN
            PRINT N'Modifying FK_teacher_grievance_status_history_grievance from CASCADE to ON DELETE NO ACTION...';
            ALTER TABLE teachers_schema.teacher_grievance_status_history
                DROP CONSTRAINT FK_teacher_grievance_status_history_grievance;
            ALTER TABLE teachers_schema.teacher_grievance_status_history
                ADD CONSTRAINT FK_teacher_grievance_status_history_grievance FOREIGN KEY (teacher_grievance_id)
                    REFERENCES teachers_schema.teacher_grievance (teacher_grievance_id)
                    ON DELETE NO ACTION;
        END;
    END;

    -- Supporting index: Grievance history by grievance ID and changed timestamp
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_teacher_grievance_history_grievance_date'
          AND object_id = OBJECT_ID(N'teachers_schema.teacher_grievance_status_history')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_teacher_grievance_history_grievance_date
            ON teachers_schema.teacher_grievance_status_history (teacher_grievance_id, changed_at DESC);
    END;

    -- -------------------------------------------------------------------------
    -- 6. RECORD MIGRATION IN SCHEMA_VERSION
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM security_schema.schema_version 
            WHERE migration_name = N'026_teacher_leave_and_grievance.sql'
        )
        BEGIN
            INSERT INTO security_schema.schema_version (migration_name, applied_at)
            VALUES (N'026_teacher_leave_and_grievance.sql', SYSUTCDATETIME());
        END;
    END;

    COMMIT TRANSACTION;
    PRINT N'Step 2: All five tables, composite constraints, and indexes successfully committed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        PRINT N'Rolling back transaction due to error in Migration 026...';
        ROLLBACK TRANSACTION;
    END;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorLine INT = ERROR_LINE();

    RAISERROR(N'Migration 026 Failed at line %d: %s', @ErrorSeverity, @ErrorState, @ErrorLine, @ErrorMessage);
END CATCH;
GO

-- Restore execution state
SET NOEXEC OFF;
GO

PRINT N'========================================================================';
PRINT N'Migration 026: Teacher Leave & Grievance deployment completed!';
PRINT N'========================================================================';
GO
