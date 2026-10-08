/* Module migration: 011_leave.sql */
/*
    Migration: 014_student_leave
    Purpose:   Student leave applications (students only â€” not teacher/staff leave)

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

