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
