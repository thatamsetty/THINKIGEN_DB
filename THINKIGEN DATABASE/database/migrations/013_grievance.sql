/* Module migration: 013_grievance.sql */
/*
    ============================================================================
    THINKIGEN STUDENT GRIEVANCE MODULE — TWO-TABLE ARCHITECTURE
    ============================================================================

    Migration: 013_grievance
    Purpose:   Student grievance (complaint) and lifecycle tracking

    Tables:
      1. student_schema.grievance          — stores grievance details & CURRENT state
      2. student_schema.grievance_history  — 1:1 lifecycle tracking (one row per grievance)

    Business Workflow:
      SUBMITTED → UNDER_REVIEW → RESOLVED

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

