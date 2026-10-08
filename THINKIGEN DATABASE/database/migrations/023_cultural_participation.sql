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
