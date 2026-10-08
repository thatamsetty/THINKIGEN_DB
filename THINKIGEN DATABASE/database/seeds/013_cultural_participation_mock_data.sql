/*
    Script:    013_cultural_participation_mock_data.sql
    Module:    023_cultural_participation / student_schema.student_cultural_participation
    Purpose:   Self-contained, bulletproof mock data (50+ rows) for the Cultural Participation module.

    Design & Safety Features:
    ---------------------------------------------------------------------------
    - Defensive DDL: Automatically creates student_schema.student_cultural_participation 
      (with event_name) and indexes if migration 023 has not been run yet.
    - Self-Sustaining Announcements: Checks for existing cultural events in 
      management_schema.announcement (announcement_type = 'EVENT', sub_category = 'CULTURAL').
      If none are found, safely seeds 12 realistic cultural events.
    - Class Teacher Binding: Queries teachers_schema.section_class_teacher_assignment 
      for the designated class teacher of each student's section, falling back to 
      teachers_schema.teacher.
    - Constraint Compliant:
      * category: VISUAL_ARTS, PERFORMING_ARTS, MUSIC, CULTURAL_ACTIVITIES
      * role_involvement: PARTICIPANT, EXHIBITOR, VOCALIST, INSTRUMENTALIST, ACTOR, DANCER, ORGANIZER
      * result: PARTICIPATED, PERFORMED, COMPLETED, FIRST_PLACE, SECOND_PLACE, THIRD_PLACE, RUNNER_UP, SPECIAL_MENTION, NO_RESULT
      * participation_status: REGISTERED, PARTICIPATED, CANCELLED
    - Uniqueness & Idempotency: Uses windowed deduplication and NOT EXISTS checks on
      (student_id, announcement_id) to safely allow repeated execution without duplicate errors.
    - Target: Generates 50+ rich, realistic cultural participation records.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Seeding 50+ Mock Data Rows for Cultural Participation Module...';
PRINT N'========================================================================';

-- =============================================================================
-- 0. DEFENSIVE DDL: ENSURE TABLE & EVENT_NAME EXIST
-- =============================================================================
IF OBJECT_ID(N'student_schema.student_cultural_participation', N'U') IS NULL
BEGIN
    PRINT N'Creating student_schema.student_cultural_participation table...';
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
    IF COL_LENGTH(N'student_schema.student_cultural_participation', N'event_name') IS NULL
    BEGIN
        PRINT N'Adding missing column event_name to student_schema.student_cultural_participation...';
        ALTER TABLE student_schema.student_cultural_participation
            ADD event_name NVARCHAR(200) NOT NULL
                CONSTRAINT DF_student_cultural_part_event_name DEFAULT (N'') WITH VALUES;
        PRINT N'Column event_name added.';
    END;
END;
GO

-- Ensure unique filtered index exists
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_student_cultural_part_student_announcement_active'
      AND object_id = OBJECT_ID(N'student_schema.student_cultural_participation')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_student_cultural_part_student_announcement_active
        ON student_schema.student_cultural_participation (student_id, announcement_id)
        WHERE is_active = 1;
END;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- =========================================================================
    -- 1. RESOLVE BASE SCOPES & USERS
    -- =========================================================================
    DECLARE @DefaultSchoolId BIGINT = (SELECT TOP 1 school_id FROM management_schema.school WHERE is_active = 1 ORDER BY school_id ASC);
    DECLARE @DefaultBranchId BIGINT = (SELECT TOP 1 branch_id FROM management_schema.branch WHERE is_active = 1 ORDER BY branch_id ASC);
    DECLARE @DefaultAcademicYearId BIGINT = (SELECT TOP 1 academic_year_id FROM management_schema.academic_year WHERE is_active = 1 ORDER BY is_current DESC, academic_year_id DESC);
    DECLARE @AdminUserId BIGINT = (SELECT TOP 1 user_id FROM security_schema.users WHERE user_type = N'ADMIN' ORDER BY user_id ASC);

    IF @AdminUserId IS NULL
        SET @AdminUserId = (SELECT TOP 1 user_id FROM security_schema.users ORDER BY user_id ASC);

    IF @DefaultSchoolId IS NULL OR @DefaultBranchId IS NULL OR @DefaultAcademicYearId IS NULL
    BEGIN
        RAISERROR(N'Missing basic school/branch/academic_year configuration. Seed master data first.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- =========================================================================
    -- 2. ENSURE CULTURAL ANNOUNCEMENTS EXIST
    -- =========================================================================
    DECLARE @CulturalAnnouncementCount INT = (
        SELECT COUNT(1)
        FROM management_schema.announcement
        WHERE announcement_type = N'EVENT'
          AND sub_category = N'CULTURAL'
          AND is_active = 1
    );

    IF @CulturalAnnouncementCount < 10
    BEGIN
        PRINT N'Seeding foundational cultural event announcements into management_schema.announcement...';

        DECLARE @SeedEvents TABLE
        (
            title            NVARCHAR(200),
            description      NVARCHAR(MAX),
            start_date       DATE,
            end_date         DATE,
            category_hint    NVARCHAR(50)
        );

        INSERT INTO @SeedEvents (title, description, start_date, end_date, category_hint)
        VALUES
        (N'Nritya Tarang 2026: Annual Classical & Folk Dance Festival',
         N'Grand inter-house and inter-school dance contest featuring Bharatanatyam, Kathak, Odissi, and folk dances.',
         '2026-10-23', '2026-10-24', N'PERFORMING_ARTS'),

        (N'Rhythm & Blues: Annual Battle of the Student Bands',
         N'Electric rock, pop, and acoustic vocal harmonies competition across high school music ensembles.',
         '2026-11-20', '2026-11-20', N'MUSIC'),

        (N'National Theatre Conclave: Inter-School One-Act Drama Fest',
         N'Dramatic theatrical showcase addressing historic events, literature adaptations, and contemporary social themes.',
         '2026-12-10', '2026-12-11', N'PERFORMING_ARTS'),

        (N'Canvas & Soul: Annual Fine Arts, Painting & Sculpture Expo',
         N'Exhibition of student oil canvas paintings, watercolor landscapes, charcoal sketches, and clay sculptures.',
         '2026-11-05', '2026-11-07', N'VISUAL_ARTS'),

        (N'Symphony of Voices: Interschool Choral & Classical Vocal Meet',
         N'Classical Hindustani, Carnatic, and Western choir choral contest evaluating pitch, harmony, and expression.',
         '2026-12-18', '2026-12-18', N'MUSIC'),

        (N'Diwali Cultural Carnival: Rangoli & Traditional Arts Fest',
         N'Celebration of traditional Indian visual arts, intricate floral rangoli designs, and folk performances.',
         '2026-11-01', '2026-11-01', N'CULTURAL_ACTIVITIES'),

        (N'FilmCraft 2026: Student Short Film & Documentary Screening Gala',
         N'Screening of original student documentary films, cinematography showcases, and digital video productions.',
         '2027-01-22', '2027-01-22', N'VISUAL_ARTS'),

        (N'Classical Instrumental Jugalbandi: Sitar, Flute, Violin & Tabla',
         N'Mesmerizing evening of classical instrumental performances celebrating rhythm and Indian melodic ragas.',
         '2027-02-12', '2027-02-12', N'MUSIC'),

        (N'Folk Heritage of India: Traditional Attire & Regional Song Showcase',
         N'Colorful showcase of India''s diverse regional cultural traditions, folk costumes, and harvest celebration songs.',
         '2026-09-25', '2026-09-25', N'CULTURAL_ACTIVITIES'),

        (N'Stand-up Comedy & Theatrical Mime Evening',
         N'Lively performance arts night featuring satirical comedy sketches, mime acts, and improvisational theater.',
         '2027-02-05', '2027-02-05', N'PERFORMING_ARTS'),

        (N'Kavi Sammelan & Poetry Slam: Verse in Motion',
         N'Multilingual poetic recitation contest covering Hindi, English, and regional verses by student writers.',
         '2026-10-09', '2026-10-09', N'CULTURAL_ACTIVITIES'),

        (N'Winter Wonderland Cultural Mela & Acoustic Gala',
         N'Campus winter carnival with live student musical busking, handicraft stalls, and street theatre performances.',
         '2026-12-23', '2026-12-24', N'CULTURAL_ACTIVITIES');

        INSERT INTO management_schema.announcement
        (
            school_id,
            branch_id,
            academic_year_id,
            announcement_type,
            sub_category,
            title,
            description,
            target_audience,
            registration_url,
            start_date,
            end_date,
            publish_at,
            status,
            is_active,
            created_at,
            created_by,
            updated_at,
            updated_by
        )
        SELECT 
            @DefaultSchoolId,
            @DefaultBranchId,
            @DefaultAcademicYearId,
            N'EVENT',
            N'CULTURAL',
            se.title,
            se.description,
            N'ALL',
            N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0',
            se.start_date,
            se.end_date,
            SYSUTCDATETIME(),
            N'PUBLISHED',
            1,
            SYSUTCDATETIME(),
            @AdminUserId,
            SYSUTCDATETIME(),
            @AdminUserId
        FROM @SeedEvents se
        WHERE NOT EXISTS (
            SELECT 1 
            FROM management_schema.announcement a 
            WHERE a.title = se.title
        );

        PRINT N'Foundation cultural announcements verified/created.';
    END;

    -- =========================================================================
    -- 3. RESOLVE ELIGIBLE STUDENTS & ASSIGNED CLASS TEACHERS
    -- =========================================================================
    ;WITH StudentTeacherMapping AS (
        SELECT 
            s.student_id,
            s.school_id,
            s.branch_id,
            s.academic_year_id,
            s.class_id,
            s.section_id,
            s.first_name,
            s.last_name,
            COALESCE(
                cta.teacher_id,
                (SELECT TOP 1 teacher_id FROM teachers_schema.teacher WHERE school_id = s.school_id AND branch_id = s.branch_id ORDER BY teacher_id ASC),
                (SELECT TOP 1 teacher_id FROM teachers_schema.teacher ORDER BY teacher_id ASC)
            ) AS teacher_id,
            ROW_NUMBER() OVER (ORDER BY s.student_id ASC) AS student_row_num
        FROM student_schema.student s
        OUTER APPLY (
            SELECT TOP 1 scta.teacher_id
            FROM teachers_schema.section_class_teacher_assignment scta
            WHERE scta.school_id = s.school_id
              AND scta.branch_id = s.branch_id
              AND scta.academic_year_id = s.academic_year_id
              AND scta.class_id = s.class_id
              AND scta.section_id = s.section_id
              AND scta.is_active = 1
            ORDER BY scta.section_class_teacher_assignment_id DESC
        ) cta
        WHERE s.is_active = 1
    ),
    CulturalEventsIndexed AS (
        SELECT 
            a.announcement_id,
            a.title AS event_name,
            a.start_date AS event_date,
            CASE 
                WHEN a.title LIKE N'%Dance%' THEN N'PERFORMING_ARTS'
                WHEN a.title LIKE N'%Band%' OR a.title LIKE N'%Vocal%' OR a.title LIKE N'%Instrumental%' OR a.title LIKE N'%Symphony%' THEN N'MUSIC'
                WHEN a.title LIKE N'%Painting%' OR a.title LIKE N'%Sculpture%' OR a.title LIKE N'%Fine Arts%' OR a.title LIKE N'%Film%' THEN N'VISUAL_ARTS'
                WHEN a.title LIKE N'%Drama%' OR a.title LIKE N'%Theatre%' OR a.title LIKE N'%Comedy%' THEN N'PERFORMING_ARTS'
                ELSE N'CULTURAL_ACTIVITIES'
            END AS event_category,
            ROW_NUMBER() OVER (ORDER BY a.announcement_id ASC) AS event_row_num,
            COUNT(1) OVER () AS total_events
        FROM management_schema.announcement a
        WHERE a.announcement_type = N'EVENT'
          AND a.sub_category = N'CULTURAL'
          AND a.is_active = 1
    ),
    -- Produce diverse event assignments for each student (2 to 4 events per student)
    StudentEventCandidates AS (
        SELECT 
            stm.student_id,
            stm.school_id,
            stm.branch_id,
            stm.academic_year_id,
            stm.class_id,
            stm.section_id,
            stm.teacher_id,
            cei.announcement_id,
            cei.event_name,
            cei.event_category,
            cei.event_date,
            stm.student_row_num,
            slot.slot_id
        FROM StudentTeacherMapping stm
        CROSS JOIN (VALUES (0), (1), (2), (3)) AS slot(slot_id)
        CROSS APPLY (
            -- Distribute students deterministically across available cultural events
            SELECT TOP 1 *
            FROM CulturalEventsIndexed c
            WHERE c.event_row_num = (((stm.student_row_num * 3 + slot.slot_id) % c.total_events) + 1)
        ) cei
    ),
    EnrichedParticipation AS (
        SELECT 
            sec.student_id,
            sec.school_id,
            sec.branch_id,
            sec.academic_year_id,
            sec.class_id,
            sec.section_id,
            sec.announcement_id,
            sec.event_name,
            sec.teacher_id,
            sec.event_category AS category,

            -- Deterministic, realistic role matching the activity category
            CASE 
                WHEN sec.event_category = N'PERFORMING_ARTS' AND sec.event_name LIKE N'%Dance%' THEN N'DANCER'
                WHEN sec.event_category = N'PERFORMING_ARTS' THEN CASE (sec.student_row_num + sec.slot_id) % 2 WHEN 0 THEN N'ACTOR' ELSE N'PARTICIPANT' END
                WHEN sec.event_category = N'MUSIC' THEN CASE (sec.student_row_num + sec.slot_id) % 3 WHEN 0 THEN N'VOCALIST' WHEN 1 THEN N'INSTRUMENTALIST' ELSE N'PARTICIPANT' END
                WHEN sec.event_category = N'VISUAL_ARTS' THEN CASE (sec.student_row_num + sec.slot_id) % 2 WHEN 0 THEN N'EXHIBITOR' ELSE N'PARTICIPANT' END
                ELSE CASE (sec.student_row_num + sec.slot_id) % 3 WHEN 0 THEN N'ORGANIZER' WHEN 1 THEN N'PARTICIPANT' ELSE N'OTHER' END
            END AS role_involvement,

            -- Realistic competition results distribution (Winners, Mentions, Participated)
            CASE (sec.student_row_num * 7 + sec.slot_id * 11) % 15
                WHEN 0 THEN N'FIRST_PLACE'
                WHEN 1 THEN N'SECOND_PLACE'
                WHEN 2 THEN N'THIRD_PLACE'
                WHEN 3 THEN N'RUNNER_UP'
                WHEN 4 THEN N'SPECIAL_MENTION'
                WHEN 5 THEN N'PERFORMED'
                WHEN 6 THEN N'COMPLETED'
                WHEN 7 THEN N'NO_RESULT'
                ELSE N'PARTICIPATED'
            END AS result,

            -- Participation status distribution (~85% PARTICIPATED, ~15% REGISTERED)
            CASE 
                WHEN ((sec.student_row_num + sec.slot_id) % 8 = 0) THEN N'REGISTERED'
                ELSE N'PARTICIPATED'
            END AS participation_status,

            -- Participation date: Always populated with event_date or realistic recent date
            COALESCE(
                sec.event_date,
                DATEADD(DAY, -((sec.student_row_num * 5 + sec.slot_id * 7) % 60 + 5), CAST(SYSUTCDATETIME() AS DATE))
            ) AS participation_date,

            -- Strict windowed deduplication on (student_id, announcement_id)
            ROW_NUMBER() OVER (
                PARTITION BY sec.student_id, sec.announcement_id 
                ORDER BY sec.slot_id ASC
            ) AS deduplication_rank
        FROM StudentEventCandidates sec
    )
    -- =========================================================================
    -- 4. INSERT INTO student_schema.student_cultural_participation
    -- =========================================================================
    INSERT INTO student_schema.student_cultural_participation
    (
        student_id,
        school_id,
        branch_id,
        academic_year_id,
        class_id,
        section_id,
        announcement_id,
        event_name,
        teacher_id,
        category,
        role_involvement,
        result,
        participation_status,
        participation_date,
        is_active,
        created_at,
        updated_at
    )
    SELECT 
        ep.student_id,
        ep.school_id,
        ep.branch_id,
        ep.academic_year_id,
        ep.class_id,
        ep.section_id,
        ep.announcement_id,
        ep.event_name,
        ep.teacher_id,
        ep.category,
        ep.role_involvement,
        ep.result,
        ep.participation_status,
        ep.participation_date,
        1 AS is_active,
        SYSUTCDATETIME() AS created_at,
        SYSUTCDATETIME() AS updated_at
    FROM EnrichedParticipation ep
    WHERE ep.deduplication_rank = 1
      AND NOT EXISTS (
          SELECT 1 
          FROM student_schema.student_cultural_participation cp
          WHERE cp.student_id = ep.student_id
            AND cp.announcement_id = ep.announcement_id
            AND cp.is_active = 1
      );

    DECLARE @RowsInserted INT = @@ROWCOUNT;
    COMMIT TRANSACTION;

    PRINT N'========================================================================';
    PRINT CONCAT(N'SUCCESS: Inserted ', @RowsInserted, N' new cultural participation records.');
    PRINT N'========================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorLine INT = ERROR_LINE();

    PRINT CONCAT(N'ERROR on line ', @ErrorLine, N': ', @ErrorMessage);
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO

-- =============================================================================
-- 5. VALIDATION & VERIFICATION AUDIT QUERIES
-- =============================================================================
PRINT N'';
PRINT N'------------------------------------------------------------------------';
PRINT N'AUDIT REPORT: Cultural Participation Records Summary';
PRINT N'------------------------------------------------------------------------';

-- A. Total row count verification
SELECT 
    COUNT(1) AS total_cultural_records,
    COUNT(DISTINCT student_id) AS unique_students_participated,
    COUNT(DISTINCT announcement_id) AS distinct_cultural_events,
    COUNT(DISTINCT teacher_id) AS distinct_authorizing_class_teachers,
    CASE WHEN COUNT(1) >= 50 THEN N'PASS (>= 50 rows)' ELSE N'WARNING (< 50 rows)' END AS target_status
FROM student_schema.student_cultural_participation
WHERE is_active = 1;

-- B. Breakdown by Category
SELECT 
    category,
    COUNT(1) AS total_entries,
    COUNT(DISTINCT student_id) AS distinct_students
FROM student_schema.student_cultural_participation
WHERE is_active = 1
GROUP BY category
ORDER BY total_entries DESC;

-- C. Breakdown by Participation Status
SELECT 
    participation_status,
    COUNT(1) AS total_entries
FROM student_schema.student_cultural_participation
WHERE is_active = 1
GROUP BY participation_status
ORDER BY total_entries DESC;

-- D. Breakdown by Result
SELECT 
    COALESCE(result, N'(NULL)') AS result,
    COUNT(1) AS total_entries
FROM student_schema.student_cultural_participation
WHERE is_active = 1
GROUP BY result
ORDER BY total_entries DESC;

-- E. Sample Top 10 Preview
SELECT TOP 10
    cp.cultural_participation_id,
    cp.student_id,
    CONCAT(s.first_name, N' ', COALESCE(s.last_name, N'')) AS student_name,
    sc.class_name,
    sec.section_name,
    cp.event_name,
    cp.category,
    cp.role_involvement,
    cp.result,
    cp.participation_status,
    cp.participation_date,
    CONCAT(t.first_name, N' ', t.last_name) AS class_teacher
FROM student_schema.student_cultural_participation cp
INNER JOIN student_schema.student s 
    ON s.student_id = cp.student_id
INNER JOIN management_schema.school_class sc 
    ON sc.class_id = cp.class_id
INNER JOIN management_schema.section sec 
    ON sec.section_id = cp.section_id
INNER JOIN teachers_schema.teacher t 
    ON t.teacher_id = cp.teacher_id
WHERE cp.is_active = 1
ORDER BY cp.cultural_participation_id DESC;
GO
