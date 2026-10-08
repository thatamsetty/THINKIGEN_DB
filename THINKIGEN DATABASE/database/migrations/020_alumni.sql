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
