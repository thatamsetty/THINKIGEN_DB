/*
    Migration: 026_teacher_leave_and_grievance.sql
    Module:    Teacher Portal Management (teachers_schema)
    Purpose:   Complete DDL schema for Teacher Leave Management and Teacher Grievance modules:
               1. teachers_schema.teacher_leave_allowance       (Leave type quotas, used, and remaining balance)
               2. teachers_schema.teacher_leave                 (Teacher leave applications)
               3. teachers_schema.teacher_leave_status_history  (Status change audit log for teacher leaves)
               4. teachers_schema.teacher_grievance             (Teacher grievances with evidence upload)
               5. teachers_schema.teacher_grievance_history     (Status change audit log for teacher grievances)
               6. teachers_schema.vw_class_teacher_student_leave_approvals (Class Teacher scoped student leave approval)
               7. teachers_schema.vw_class_teacher_academic_grievances     (Class Teacher scoped academic student grievances)
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Applying Migration 026: Teacher Leave & Grievance Management...';
PRINT N'========================================================================';

-- -----------------------------------------------------------------------------
-- 1. TABLE: teachers_schema.teacher_leave_allowance (Leave Balances & Quotas)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher_leave_allowance', N'U') IS NULL
BEGIN
    PRINT N'Creating table teachers_schema.teacher_leave_allowance...';
    CREATE TABLE teachers_schema.teacher_leave_allowance
    (
        teacher_leave_allowance_id BIGINT          NOT NULL IDENTITY(1, 1),
        school_id                  BIGINT          NOT NULL,
        branch_id                  BIGINT          NOT NULL,
        academic_year_id           BIGINT          NOT NULL,
        teacher_id                 BIGINT          NOT NULL,
        leave_type                 VARCHAR(30)     NOT NULL,
        total_allowed_days         DECIMAL(4, 1)   NOT NULL,
        used_days                  DECIMAL(4, 1)   NOT NULL CONSTRAINT DF_teacher_leave_allowance_used DEFAULT (0.0),
        pending_days               DECIMAL(4, 1)   NOT NULL CONSTRAINT DF_teacher_leave_allowance_pending DEFAULT (0.0),
        remaining_days             AS (total_allowed_days - used_days),
        is_active                  BIT             NOT NULL CONSTRAINT DF_teacher_leave_allowance_is_active DEFAULT (1),
        created_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_allowance_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                 BIGINT          NULL,
        updated_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_allowance_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                 BIGINT          NULL,
        row_version                ROWVERSION      NOT NULL,
        CONSTRAINT PK_teacher_leave_allowance PRIMARY KEY CLUSTERED (teacher_leave_allowance_id),
        CONSTRAINT UQ_teacher_leave_allowance UNIQUE NONCLUSTERED (school_id, branch_id, academic_year_id, teacher_id, leave_type),
        CONSTRAINT CK_teacher_leave_allowance_type CHECK
            (leave_type IN (N'CASUAL', N'SICK', N'EARNED', N'MATERNITY', N'PATERNITY', N'DUTY', N'COMPENSATORY', N'OTHER')),
        CONSTRAINT CK_teacher_leave_allowance_days CHECK
            (total_allowed_days >= 0.0 AND used_days >= 0.0 AND pending_days >= 0.0),
        CONSTRAINT FK_teacher_leave_allowance_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_teacher_leave_allowance_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_teacher_leave_allowance_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_teacher_leave_allowance_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_teacher_leave_allowance_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_teacher_leave_allowance_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_leave_allowance_lookup'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher_leave_allowance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_leave_allowance_lookup
        ON teachers_schema.teacher_leave_allowance (teacher_id, academic_year_id, is_active)
        INCLUDE (leave_type, total_allowed_days, used_days);
END;
GO

-- -----------------------------------------------------------------------------
-- 2. TABLE: teachers_schema.teacher_leave (Leave Application)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher_leave', N'U') IS NULL
BEGIN
    PRINT N'Creating table teachers_schema.teacher_leave...';
    CREATE TABLE teachers_schema.teacher_leave
    (
        teacher_leave_id     BIGINT          NOT NULL IDENTITY(1, 1),
        school_id            BIGINT          NOT NULL,
        branch_id            BIGINT          NOT NULL,
        academic_year_id     BIGINT          NOT NULL,
        teacher_id           BIGINT          NOT NULL,
        leave_type           NVARCHAR(30)    NOT NULL,
        duration_type        NVARCHAR(20)    NOT NULL,
        half_day_session     NVARCHAR(20)    NULL,
        days_count           DECIMAL(4, 2)   NOT NULL CONSTRAINT DF_teacher_leave_days_count DEFAULT (1.00),
        start_date           DATE            NOT NULL,
        end_date             DATE            NOT NULL,
        reason               NVARCHAR(500)   NOT NULL,
        attachment_doc_url   NVARCHAR(1000)  NULL,
        status               NVARCHAR(20)    NOT NULL CONSTRAINT DF_teacher_leave_status DEFAULT (N'PENDING'),
        applied_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_applied_at DEFAULT (SYSUTCDATETIME()),
        reviewed_at          DATETIME2(0)    NULL,
        reviewed_by          BIGINT          NULL,
        review_remarks       NVARCHAR(500)   NULL,
        is_active            BIT             NOT NULL CONSTRAINT DF_teacher_leave_is_active DEFAULT (1),
        created_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_created_at DEFAULT (SYSUTCDATETIME()),
        created_by           BIGINT          NOT NULL,
        updated_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by           BIGINT          NULL,
        row_version          ROWVERSION      NOT NULL,
        CONSTRAINT PK_teacher_leave PRIMARY KEY CLUSTERED (teacher_leave_id),
        CONSTRAINT CK_teacher_leave_type CHECK
            (leave_type IN (N'CASUAL', N'SICK', N'EARNED', N'MATERNITY', N'PATERNITY', N'DUTY', N'COMPENSATORY', N'OTHER')),
        CONSTRAINT CK_teacher_leave_duration_type CHECK
            (duration_type IN (N'HALF_DAY', N'FULL_DAY', N'MULTIPLE_DAYS')),
        CONSTRAINT CK_teacher_leave_half_day_session CHECK
            ((duration_type = N'HALF_DAY' AND half_day_session IN (N'FIRST_HALF', N'SECOND_HALF'))
             OR (duration_type <> N'HALF_DAY' AND half_day_session IS NULL)),
        CONSTRAINT CK_teacher_leave_status CHECK
            (status IN (N'PENDING', N'APPROVED', N'REJECTED', N'CANCELLED')),
        CONSTRAINT CK_teacher_leave_date_range CHECK (end_date >= start_date),
        CONSTRAINT CK_teacher_leave_half_day CHECK
            (duration_type <> N'HALF_DAY' OR (start_date = end_date AND days_count = 0.50)),
        CONSTRAINT CK_teacher_leave_full_day CHECK
            (duration_type <> N'FULL_DAY' OR (start_date = end_date AND days_count = 1.00)),
        CONSTRAINT CK_teacher_leave_reviewed CHECK
            ((status IN (N'APPROVED', N'REJECTED') AND reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL)
             OR (status IN (N'PENDING', N'CANCELLED'))),
        CONSTRAINT FK_teacher_leave_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_teacher_leave_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_teacher_leave_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_teacher_leave_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_teacher_leave_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_teacher_leave_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_teacher_leave_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_leave_teacher_status'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher_leave')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_leave_teacher_status
        ON teachers_schema.teacher_leave (teacher_id, status, start_date DESC)
        INCLUDE (leave_type, days_count, is_active);
END;
GO

-- -----------------------------------------------------------------------------
-- 3. TABLE: teachers_schema.teacher_leave_status_history (Leave Status Audit Log)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher_leave_status_history', N'U') IS NULL
BEGIN
    PRINT N'Creating table teachers_schema.teacher_leave_status_history...';
    CREATE TABLE teachers_schema.teacher_leave_status_history
    (
        teacher_leave_status_history_id BIGINT          NOT NULL IDENTITY(1, 1),
        teacher_leave_id                BIGINT          NOT NULL,
        changed_from_status             NVARCHAR(20)    NULL,
        changed_to_status               NVARCHAR(20)    NOT NULL,
        changed_by                      BIGINT          NOT NULL,
        changed_at                      DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_leave_status_history_changed_at DEFAULT (SYSUTCDATETIME()),
        remarks                         NVARCHAR(500)   NULL,
        row_version                     ROWVERSION      NOT NULL,
        CONSTRAINT PK_teacher_leave_status_history PRIMARY KEY CLUSTERED (teacher_leave_status_history_id),
        CONSTRAINT CK_teacher_leave_status_history_status CHECK
            (changed_to_status IN (N'PENDING', N'APPROVED', N'REJECTED', N'CANCELLED')),
        CONSTRAINT FK_teacher_leave_status_history_leave FOREIGN KEY (teacher_leave_id)
            REFERENCES teachers_schema.teacher_leave (teacher_leave_id) ON DELETE CASCADE,
        CONSTRAINT FK_teacher_leave_status_history_changed_by FOREIGN KEY (changed_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_leave_status_history_leave'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher_leave_status_history')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_leave_status_history_leave
        ON teachers_schema.teacher_leave_status_history (teacher_leave_id, changed_at DESC);
END;
GO

-- -----------------------------------------------------------------------------
-- 4. TABLE: teachers_schema.teacher_grievance (Teacher Grievances)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher_grievance', N'U') IS NULL
BEGIN
    PRINT N'Creating table teachers_schema.teacher_grievance...';
    CREATE TABLE teachers_schema.teacher_grievance
    (
        teacher_grievance_id BIGINT          NOT NULL IDENTITY(1, 1),
        grievance_number     NVARCHAR(30)    NOT NULL,
        school_id            BIGINT          NOT NULL,
        branch_id            BIGINT          NOT NULL,
        academic_year_id     BIGINT          NOT NULL,
        teacher_id           BIGINT          NOT NULL,
        department_id        BIGINT          NOT NULL CONSTRAINT DF_teacher_grievance_dept DEFAULT (1),
        title                NVARCHAR(200)   NOT NULL,
        category             NVARCHAR(50)    NOT NULL,
        priority_level       NVARCHAR(20)    NOT NULL,
        incident_date        DATE            NOT NULL,
        location             NVARCHAR(200)   NOT NULL,
        description          NVARCHAR(MAX)   NOT NULL,
        evidence_doc_url     NVARCHAR(1000)  NULL,
        status               NVARCHAR(30)    NOT NULL CONSTRAINT DF_teacher_grievance_status DEFAULT (N'SUBMITTED'),
        submitted_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_grievance_submitted_at DEFAULT (SYSUTCDATETIME()),
        assigned_to          BIGINT          NULL,
        resolved_at          DATETIME2(0)    NULL,
        resolution_remarks   NVARCHAR(MAX)   NULL,
        is_active            BIT             NOT NULL CONSTRAINT DF_teacher_grievance_is_active DEFAULT (1),
        created_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_grievance_created_at DEFAULT (SYSUTCDATETIME()),
        created_by           BIGINT          NOT NULL,
        updated_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_grievance_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by           BIGINT          NULL,
        row_version          ROWVERSION      NOT NULL,
        CONSTRAINT PK_teacher_grievance PRIMARY KEY CLUSTERED (teacher_grievance_id),
        CONSTRAINT UQ_teacher_grievance_number UNIQUE NONCLUSTERED (grievance_number),
        CONSTRAINT CK_teacher_grievance_category CHECK
            (category IN (
                N'ACADEMIC', N'ADMINISTRATIVE', N'FACILITIES', N'SALARY_BENEFITS',
                N'WORKLOAD', N'STUDENT_BEHAVIOR', N'STAFF_BEHAVIOR', N'OTHER')),
        CONSTRAINT CK_teacher_grievance_priority CHECK
            (priority_level IN (N'LOW', N'MEDIUM', N'HIGH')),
        CONSTRAINT CK_teacher_grievance_status CHECK
            (status IN (N'SUBMITTED', N'UNDER_REVIEW', N'RESOLVED', N'REJECTED')),
        CONSTRAINT CK_teacher_grievance_assigned CHECK
            (status = N'SUBMITTED' OR assigned_to IS NOT NULL),
        CONSTRAINT CK_teacher_grievance_resolved CHECK
            ((status = N'RESOLVED' AND resolved_at IS NOT NULL AND resolution_remarks IS NOT NULL)
             OR (status <> N'RESOLVED')),
        CONSTRAINT FK_teacher_grievance_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_teacher_grievance_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_teacher_grievance_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_teacher_grievance_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_teacher_grievance_department FOREIGN KEY (department_id) REFERENCES management_schema.grievance_department (department_id),
        CONSTRAINT FK_teacher_grievance_assigned_to FOREIGN KEY (assigned_to) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_teacher_grievance_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_teacher_grievance_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_grievance_teacher_status'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher_grievance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_grievance_teacher_status
        ON teachers_schema.teacher_grievance (teacher_id, status, submitted_at DESC)
        INCLUDE (title, category, priority_level, is_active);
END;
GO

-- -----------------------------------------------------------------------------
-- 5. TABLE: teachers_schema.teacher_grievance_history (Grievance Audit Log)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher_grievance_history', N'U') IS NULL
BEGIN
    PRINT N'Creating table teachers_schema.teacher_grievance_history...';
    CREATE TABLE teachers_schema.teacher_grievance_history
    (
        teacher_grievance_history_id BIGINT          NOT NULL IDENTITY(1, 1),
        teacher_grievance_id         BIGINT          NOT NULL,
        from_status                  NVARCHAR(30)    NULL,
        to_status                    NVARCHAR(30)    NOT NULL,
        action_by                    BIGINT          NOT NULL,
        action_at                    DATETIME2(0)    NOT NULL CONSTRAINT DF_teacher_grievance_history_action_at DEFAULT (SYSUTCDATETIME()),
        action_notes                 NVARCHAR(MAX)   NULL,
        row_version                  ROWVERSION      NOT NULL,
        CONSTRAINT PK_teacher_grievance_history PRIMARY KEY CLUSTERED (teacher_grievance_history_id),
        CONSTRAINT CK_teacher_grievance_history_status CHECK
            (to_status IN (N'SUBMITTED', N'UNDER_REVIEW', N'RESOLVED', N'REJECTED')),
        CONSTRAINT FK_teacher_grievance_history_grievance FOREIGN KEY (teacher_grievance_id)
            REFERENCES teachers_schema.teacher_grievance (teacher_grievance_id) ON DELETE CASCADE,
        CONSTRAINT FK_teacher_grievance_history_action_by FOREIGN KEY (action_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_teacher_grievance_history_grievance'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher_grievance_history')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_teacher_grievance_history_grievance
        ON teachers_schema.teacher_grievance_history (teacher_grievance_id, action_at DESC);
END;
GO

-- -----------------------------------------------------------------------------
-- 6. VIEW: Class Teacher Scoped Student Leave Approval
-- Requirement: Class teacher only has access permission to approve leaves for their section students
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.vw_class_teacher_student_leave_approvals', N'V') IS NOT NULL
    DROP VIEW teachers_schema.vw_class_teacher_student_leave_approvals;
GO

PRINT N'Creating view teachers_schema.vw_class_teacher_student_leave_approvals...';
GO
CREATE VIEW teachers_schema.vw_class_teacher_student_leave_approvals
AS
SELECT 
    cta.teacher_id               AS class_teacher_id,
    cta.school_id                AS assigned_school_id,
    cta.branch_id                AS assigned_branch_id,
    cta.class_id                 AS assigned_class_id,
    cta.section_id               AS assigned_section_id,
    sl.student_leave_id,
    sl.student_id,
    st.admission_number,
    CONCAT(st.first_name, N' ', COALESCE(st.last_name, N'')) AS student_full_name,
    sl.leave_type,
    sl.duration_type,
    sl.half_day_session,
    sl.duration,
    sl.start_date,
    sl.end_date,
    sl.reason,
    sl.status                    AS leave_status,
    sl.applied_at,
    sl.reviewed_at,
    sl.reviewed_by,
    sl.review_remarks,
    sl.is_active
FROM student_schema.student_leave sl
INNER JOIN student_schema.student st
    ON st.student_id = sl.student_id
INNER JOIN teachers_schema.section_class_teacher_assignment cta
    ON cta.section_id       = sl.section_id
   AND cta.class_id         = sl.class_id
   AND cta.school_id        = sl.school_id
   AND cta.academic_year_id = sl.academic_year_id
   AND cta.is_active        = 1
WHERE sl.is_active = 1;
GO

-- -----------------------------------------------------------------------------
-- 7. VIEW: Class Teacher Scoped Academic Student Grievance Resolution
-- Requirement: Class teacher only can check all academic-related grievances to resolve
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.vw_class_teacher_academic_grievances', N'V') IS NOT NULL
    DROP VIEW teachers_schema.vw_class_teacher_academic_grievances;
GO

PRINT N'Creating view teachers_schema.vw_class_teacher_academic_grievances...';
GO
CREATE VIEW teachers_schema.vw_class_teacher_academic_grievances
AS
SELECT 
    cta.teacher_id               AS class_teacher_id,
    cta.school_id                AS assigned_school_id,
    cta.branch_id                AS assigned_branch_id,
    cta.class_id                 AS assigned_class_id,
    cta.section_id               AS assigned_section_id,
    g.grievance_id,
    g.grievance_number,
    g.student_id,
    st.admission_number,
    CONCAT(st.first_name, N' ', COALESCE(st.last_name, N'')) AS student_full_name,
    g.department_id,
    g.title,
    g.category,
    g.priority_level,
    g.incident_date,
    g.location,
    g.description,
    g.status                     AS grievance_status,
    g.submitted_at,
    g.assigned_to,
    g.is_active
FROM student_schema.grievance g
INNER JOIN student_schema.student st
    ON st.student_id = g.student_id
INNER JOIN teachers_schema.section_class_teacher_assignment cta
    ON cta.section_id       = g.section_id
   AND cta.class_id         = g.class_id
   AND cta.school_id        = g.school_id
   AND cta.academic_year_id = g.academic_year_id
   AND cta.is_active        = 1
WHERE g.category = N'ACADEMIC'
  AND g.is_active = 1;
GO

PRINT N'Migration 026 completed successfully.';
GO
