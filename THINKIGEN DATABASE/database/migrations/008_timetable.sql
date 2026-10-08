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

