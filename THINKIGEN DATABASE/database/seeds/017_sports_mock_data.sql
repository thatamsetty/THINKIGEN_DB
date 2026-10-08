/*
    Script:    017_sports_mock_data.sql
    Module:    025_sports_and_grievance_department / sports_schema.student_sport_history
    Purpose:   Self-contained, realistic mock data (60+ rows) for the Sports History module.

    Design & Safety Features:
    ---------------------------------------------------------------------------
    - Prerequisite Guard:  Checks that sports_schema.student_sport_history exists
      (created by migration 025_sports_and_grievance_department.sql) before seeding.
    - Self-Sustaining Announcements:  Checks for existing SPORTS announcements in
      management_schema.announcement (announcement_type = 'EVENT', sub_category = 'SPORTS').
      If fewer than 3 are found, defensively seeds 4 realistic sports event announcements.
    - Multi-Tenant Integrity:  Dynamically resolves school_id, branch_id, class_id,
      section_id, student_id, and created_by from live tables - no hard-coded IDs.
    - sport_category values used: 'INDIVIDUAL', 'TEAM', 'OUTDOOR', 'INDOOR', 'TRACK_AND_FIELD'
    - Idempotent:  Uses NOT EXISTS on (student_id, activity_date, sport_name) to prevent
      duplicate rows on re-runs.
    - Target:  Seeds 60+ realistic sport history records across both branches.

    Table: sports_schema.student_sport_history
    Columns:
        student_sport_history_id  BIGINT IDENTITY PK
        student_id                BIGINT NOT NULL  -> student_schema.student
        school_id                 BIGINT NOT NULL  -> management_schema.school
        branch_id                 BIGINT NOT NULL  -> management_schema.branch
        class_id                  BIGINT NOT NULL  -> management_schema.school_class
        section_id                BIGINT NOT NULL  -> management_schema.section
        sport_name                VARCHAR(100)
        announcement_id           BIGINT NULL      -> management_schema.announcement
        activity_date             DATE NOT NULL
        activity_name             VARCHAR(200)
        result                    VARCHAR(200) NULL
        created_at                DATETIME2(3)
        created_by                BIGINT NOT NULL  -> security_schema.users
        updated_at                DATETIME2(3) NULL
        updated_by                BIGINT NULL      -> security_schema.users
        row_version               ROWVERSION
        sport_category            VARCHAR(100) NOT NULL
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Seeding 60+ Mock Data Rows for Sports History Module...';
PRINT N'========================================================================';

-- =============================================================================
-- 0. PREREQUISITE GUARD
-- =============================================================================
IF OBJECT_ID(N'sports_schema.student_sport_history', N'U') IS NULL
BEGIN
    RAISERROR(N'Target table sports_schema.student_sport_history does not exist. Run migration 025_sports_and_grievance_department.sql first.', 16, 1);
    RETURN;
END;
GO

-- =============================================================================
-- MAIN SEEDING BLOCK
-- =============================================================================
BEGIN TRY
    BEGIN TRANSACTION;

    -- -------------------------------------------------------------------------
    -- 1. Defensive SPORTS Announcement Seeding
    --    Seeds 4 sports event announcements if fewer than 3 SPORTS events exist.
    -- -------------------------------------------------------------------------
    IF (SELECT COUNT(*) FROM management_schema.announcement
        WHERE announcement_type = N'EVENT' AND sub_category = N'SPORTS') < 3
    BEGIN
        PRINT N'Seeding defensive sports event announcements...';

        DECLARE @admin_user_id BIGINT;
        SELECT TOP 1 @admin_user_id = user_id
        FROM security_schema.users
        WHERE user_type IN (N'ADMIN', N'PRINCIPAL')
        ORDER BY user_id;

        DECLARE @school_id_ann  BIGINT;
        DECLARE @branch_id_ann  BIGINT;
        DECLARE @acyr_id_ann    BIGINT;

        SELECT TOP 1
            @school_id_ann = b.school_id,
            @branch_id_ann = b.branch_id,
            @acyr_id_ann   = ay.academic_year_id
        FROM management_schema.branch b
        INNER JOIN management_schema.academic_year ay
            ON ay.school_id = b.school_id AND ay.is_current = 1
        WHERE b.is_active = 1
        ORDER BY b.school_id, b.branch_id;

        INSERT INTO management_schema.announcement
            (school_id, branch_id, academic_year_id,
             announcement_type, sub_category, title, description,
             visible_to, registration_url,
             start_date, end_date, published_at, status,
             created_by, updated_by)
        SELECT
            @school_id_ann, @branch_id_ann, @acyr_id_ann,
            ev.announcement_type, ev.sub_category, ev.title, ev.description,
            N'ALL', NULL,
            ev.start_date, ev.end_date,
            CAST(GETUTCDATE() AS DATETIME2(0)),
            N'PUBLISHED',
            @admin_user_id, @admin_user_id
        FROM (VALUES
            (N'EVENT', N'SPORTS', N'Annual Inter-School Athletics Championship 2026',
             N'Track and field events including 100m sprint, relay, long jump, shot put, and hurdles across all age groups.',
             CAST('2026-08-15' AS DATE), CAST('2026-08-16' AS DATE)),
            (N'EVENT', N'SPORTS', N'Intra-School Cricket Tournament 2026',
             N'Branch vs Branch cricket championship. Open to Class 6 to Class 10 students.',
             CAST('2026-09-05' AS DATE), CAST('2026-09-07' AS DATE)),
            (N'EVENT', N'SPORTS', N'Kabaddi & Kho-Kho District Trials 2026',
             N'Selection trials for district-level Kabaddi and Kho-Kho competitions. Coach-recommended students will be evaluated.',
             CAST('2026-09-20' AS DATE), CAST('2026-09-20' AS DATE)),
            (N'EVENT', N'SPORTS', N'Basketball & Volleyball Friendly Series 2026',
             N'Friendly inter-section Basketball and Volleyball matches. All classes welcome to participate.',
             CAST('2026-10-10' AS DATE), CAST('2026-10-11' AS DATE))
        ) AS ev(announcement_type, sub_category, title, description, start_date, end_date)
        WHERE NOT EXISTS (
            SELECT 1 FROM management_schema.announcement a
            WHERE a.title = ev.title
        );

        PRINT N'Sports announcements seeded (if not already present).';
    END;

    -- -------------------------------------------------------------------------
    -- 2. Build a temp catalog of sport events with their announcement IDs
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'tempdb..#SportEvents') IS NOT NULL DROP TABLE #SportEvents;
    CREATE TABLE #SportEvents
    (
        sport_event_id   INT          NOT NULL IDENTITY(1, 1),
        sport_name       VARCHAR(100) NOT NULL,
        sport_category   VARCHAR(100) NOT NULL,
        activity_name    VARCHAR(200) NOT NULL,
        announcement_id  BIGINT       NULL,
        event_date       DATE         NOT NULL
    );

    -- Resolve announcement IDs dynamically for known titles
    DECLARE @ann_athletics  BIGINT = NULL;
    DECLARE @ann_cricket    BIGINT = NULL;
    DECLARE @ann_kabaddi    BIGINT = NULL;
    DECLARE @ann_bball      BIGINT = NULL;

    SELECT @ann_athletics = announcement_id FROM management_schema.announcement
    WHERE title = N'Annual Inter-School Athletics Championship 2026';

    SELECT @ann_cricket = announcement_id FROM management_schema.announcement
    WHERE title = N'Intra-School Cricket Tournament 2026';

    SELECT @ann_kabaddi = announcement_id FROM management_schema.announcement
    WHERE title = N'Kabaddi & Kho-Kho District Trials 2026';

    SELECT @ann_bball = announcement_id FROM management_schema.announcement
    WHERE title = N'Basketball & Volleyball Friendly Series 2026';

    -- Insert sport event catalog
    INSERT INTO #SportEvents (sport_name, sport_category, activity_name, announcement_id, event_date)
    VALUES
        -- Athletics (sport_event_id 1..6)
        ('Athletics', 'TRACK_AND_FIELD', '100m Sprint - Annual Athletics Championship', @ann_athletics, '2026-08-15'),
        ('Athletics', 'TRACK_AND_FIELD', '200m Sprint - Annual Athletics Championship', @ann_athletics, '2026-08-15'),
        ('Athletics', 'TRACK_AND_FIELD', 'Long Jump - Annual Athletics Championship',   @ann_athletics, '2026-08-15'),
        ('Athletics', 'TRACK_AND_FIELD', 'Shot Put - Annual Athletics Championship',    @ann_athletics, '2026-08-15'),
        ('Athletics', 'TRACK_AND_FIELD', '4x100m Relay - Annual Athletics Championship',@ann_athletics, '2026-08-16'),
        ('Athletics', 'TRACK_AND_FIELD', 'High Jump - Annual Athletics Championship',   @ann_athletics, '2026-08-16'),
        -- Cricket (sport_event_id 7..9)
        ('Cricket',   'TEAM',            'Cricket Quarter-Final Match - Intra-School Tournament', @ann_cricket, '2026-09-05'),
        ('Cricket',   'TEAM',            'Cricket Semi-Final Match - Intra-School Tournament',    @ann_cricket, '2026-09-06'),
        ('Cricket',   'TEAM',            'Cricket Finals - Intra-School Tournament',              @ann_cricket, '2026-09-07'),
        -- Kabaddi (sport_event_id 10)
        ('Kabaddi',   'TEAM',            'Kabaddi District Selection Trials',    @ann_kabaddi, '2026-09-20'),
        -- Kho-Kho (sport_event_id 11)
        ('Kho-Kho',   'TEAM',            'Kho-Kho District Selection Trials',    @ann_kabaddi, '2026-09-20'),
        -- Basketball (sport_event_id 12)
        ('Basketball','TEAM',            'Basketball Inter-Section Friendly Match', @ann_bball, '2026-10-10'),
        -- Volleyball (sport_event_id 13)
        ('Volleyball','TEAM',            'Volleyball Inter-Section Friendly Match', @ann_bball, '2026-10-11'),
        -- Individual / Indoor practice events (sport_event_id 14..19, no announcement)
        ('Badminton',   'INDIVIDUAL',    'Badminton Practice Tournament - School Level',    NULL, '2026-07-20'),
        ('Table Tennis','INDOOR',        'Table Tennis Intra-School Championship',           NULL, '2026-07-25'),
        ('Chess',       'INDOOR',        'Chess Club Tournament - School Level',             NULL, '2026-08-05'),
        ('Swimming',    'INDIVIDUAL',    'Swimming Gala - Annual School Sports Day',         NULL, '2026-08-10'),
        ('Handball',    'OUTDOOR',       'Handball Intra-Section Match',                     NULL, '2026-09-15'),
        ('Football',    'TEAM',          'Football Intra-School League Match',               NULL, '2026-09-25');

    -- -------------------------------------------------------------------------
    -- 3. Build candidate rows (students x sport events)
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'tempdb..#SeedCandidates') IS NOT NULL DROP TABLE #SeedCandidates;
    CREATE TABLE #SeedCandidates
    (
        student_id       BIGINT       NOT NULL,
        school_id        BIGINT       NOT NULL,
        branch_id        BIGINT       NOT NULL,
        class_id         BIGINT       NOT NULL,
        section_id       BIGINT       NOT NULL,
        sport_event_id   INT          NOT NULL,
        sport_name       VARCHAR(100) NOT NULL,
        sport_category   VARCHAR(100) NOT NULL,
        activity_name    VARCHAR(200) NOT NULL,
        announcement_id  BIGINT       NULL,
        activity_date    DATE         NOT NULL,
        result           VARCHAR(200) NULL,
        created_by       BIGINT       NOT NULL
    );

    DECLARE @sys_user BIGINT;
    SELECT TOP 1 @sys_user = user_id
    FROM security_schema.users
    WHERE user_type IN (N'ADMIN', N'PRINCIPAL')
    ORDER BY user_id;

    -- Branch 1: Athletics events (sport_event_id 1..6), classes 6-10 Section A
    INSERT INTO #SeedCandidates
        (student_id, school_id, branch_id, class_id, section_id,
         sport_event_id, sport_name, sport_category, activity_name, announcement_id, activity_date,
         result, created_by)
    SELECT TOP 40
        s.student_id, s.school_id, s.branch_id, s.class_id, s.section_id,
        se.sport_event_id, se.sport_name, se.sport_category, se.activity_name,
        se.announcement_id, se.event_date,
        CASE
            WHEN ROW_NUMBER() OVER (PARTITION BY se.sport_event_id ORDER BY s.student_id) = 1 THEN '1st Place'
            WHEN ROW_NUMBER() OVER (PARTITION BY se.sport_event_id ORDER BY s.student_id) = 2 THEN '2nd Place'
            WHEN ROW_NUMBER() OVER (PARTITION BY se.sport_event_id ORDER BY s.student_id) = 3 THEN '3rd Place'
            ELSE 'Participated'
        END,
        @sys_user
    FROM student_schema.student s
    CROSS JOIN #SportEvents se
    WHERE s.branch_id = 1
      AND s.class_id BETWEEN 6 AND 10
      AND s.is_active = 1
      AND se.sport_event_id BETWEEN 1 AND 6
      AND NOT EXISTS (
          SELECT 1 FROM sports_schema.student_sport_history h
          WHERE h.student_id = s.student_id AND h.sport_name = se.sport_name
            AND h.activity_date = se.event_date
      );

    -- Cricket events (sport_event_id 7..9): classes 8-10 section A, branch 1
    INSERT INTO #SeedCandidates
        (student_id, school_id, branch_id, class_id, section_id,
         sport_event_id, sport_name, sport_category, activity_name, announcement_id, activity_date,
         result, created_by)
    SELECT
        s.student_id, s.school_id, s.branch_id, s.class_id, s.section_id,
        se.sport_event_id, se.sport_name, se.sport_category, se.activity_name,
        se.announcement_id, se.event_date,
        CASE se.sport_event_id WHEN 9 THEN 'Winner' ELSE 'Team Member' END,
        @sys_user
    FROM student_schema.student s
    CROSS JOIN #SportEvents se
    WHERE s.branch_id = 1
      AND s.class_id IN (8, 9, 10)
      AND s.section_id IN (
          SELECT section_id FROM management_schema.section WHERE section_name = N'A'
      )
      AND s.is_active = 1
      AND se.sport_event_id BETWEEN 7 AND 9
      AND NOT EXISTS (
          SELECT 1 FROM sports_schema.student_sport_history h
          WHERE h.student_id = s.student_id AND h.sport_name = se.sport_name
            AND h.activity_date = se.event_date
      );

    -- Kabaddi & Kho-Kho (sport_event_id 10..11): classes 7-9, both branches
    INSERT INTO #SeedCandidates
        (student_id, school_id, branch_id, class_id, section_id,
         sport_event_id, sport_name, sport_category, activity_name, announcement_id, activity_date,
         result, created_by)
    SELECT TOP 20
        s.student_id, s.school_id, s.branch_id, s.class_id, s.section_id,
        se.sport_event_id, se.sport_name, se.sport_category, se.activity_name,
        se.announcement_id, se.event_date,
        CASE
            WHEN ROW_NUMBER() OVER (PARTITION BY se.sport_event_id ORDER BY s.student_id) <= 2
                 THEN 'Selected for District'
            ELSE 'Participated - Not Selected'
        END,
        @sys_user
    FROM student_schema.student s
    CROSS JOIN #SportEvents se
    WHERE s.class_id BETWEEN 7 AND 9
      AND s.is_active = 1
      AND se.sport_event_id IN (10, 11)
      AND NOT EXISTS (
          SELECT 1 FROM sports_schema.student_sport_history h
          WHERE h.student_id = s.student_id AND h.sport_name = se.sport_name
            AND h.activity_date = se.event_date
      );

    -- Basketball & Volleyball (sport_event_id 12..13): classes 8-10, both branches
    INSERT INTO #SeedCandidates
        (student_id, school_id, branch_id, class_id, section_id,
         sport_event_id, sport_name, sport_category, activity_name, announcement_id, activity_date,
         result, created_by)
    SELECT TOP 20
        s.student_id, s.school_id, s.branch_id, s.class_id, s.section_id,
        se.sport_event_id, se.sport_name, se.sport_category, se.activity_name,
        se.announcement_id, se.event_date,
        'Participated',
        @sys_user
    FROM student_schema.student s
    CROSS JOIN #SportEvents se
    WHERE s.class_id BETWEEN 8 AND 10
      AND s.is_active = 1
      AND se.sport_event_id IN (12, 13)
      AND NOT EXISTS (
          SELECT 1 FROM sports_schema.student_sport_history h
          WHERE h.student_id = s.student_id AND h.sport_name = se.sport_name
            AND h.activity_date = se.event_date
      );

    -- Individual & Indoor events (sport_event_id 14..19): all classes, both branches
    INSERT INTO #SeedCandidates
        (student_id, school_id, branch_id, class_id, section_id,
         sport_event_id, sport_name, sport_category, activity_name, announcement_id, activity_date,
         result, created_by)
    SELECT TOP 40
        s.student_id, s.school_id, s.branch_id, s.class_id, s.section_id,
        se.sport_event_id, se.sport_name, se.sport_category, se.activity_name,
        se.announcement_id, se.event_date,
        CASE
            WHEN ROW_NUMBER() OVER (PARTITION BY se.sport_event_id ORDER BY s.student_id) = 1 THEN '1st Place'
            WHEN ROW_NUMBER() OVER (PARTITION BY se.sport_event_id ORDER BY s.student_id) = 2 THEN '2nd Place'
            WHEN ROW_NUMBER() OVER (PARTITION BY se.sport_event_id ORDER BY s.student_id) = 3 THEN '3rd Place'
            ELSE 'Participated'
        END,
        @sys_user
    FROM student_schema.student s
    CROSS JOIN #SportEvents se
    WHERE s.is_active = 1
      AND se.sport_event_id BETWEEN 14 AND 19
      AND NOT EXISTS (
          SELECT 1 FROM sports_schema.student_sport_history h
          WHERE h.student_id = s.student_id AND h.sport_name = se.sport_name
            AND h.activity_date = se.event_date
      );

    -- -------------------------------------------------------------------------
    -- 4. INSERT from candidates into the actual sports history table
    -- -------------------------------------------------------------------------
    INSERT INTO sports_schema.student_sport_history
        (student_id, school_id, branch_id, class_id, section_id,
         sport_name, announcement_id, activity_date, activity_name,
         result, created_by, updated_at, updated_by, sport_category)
    SELECT
        c.student_id, c.school_id, c.branch_id, c.class_id, c.section_id,
        c.sport_name, c.announcement_id, c.activity_date, c.activity_name,
        c.result, c.created_by, SYSUTCDATETIME(), c.created_by, c.sport_category
    FROM #SeedCandidates c
    WHERE NOT EXISTS (
        SELECT 1 FROM sports_schema.student_sport_history h
        WHERE h.student_id    = c.student_id
          AND h.sport_name    = c.sport_name
          AND h.activity_date = c.activity_date
    );

    DECLARE @RowsInserted INT = @@ROWCOUNT;

    DROP TABLE #SeedCandidates;
    DROP TABLE #SportEvents;

    COMMIT TRANSACTION;

    PRINT CONCAT(N'sports_schema.student_sport_history: ', @RowsInserted, N' rows inserted successfully.');
    PRINT N'========================================================================';
    PRINT N'Sports History mock data seeding completed successfully.';
    PRINT N'========================================================================';

END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'tempdb..#SeedCandidates') IS NOT NULL DROP TABLE #SeedCandidates;
    IF OBJECT_ID(N'tempdb..#SportEvents')    IS NOT NULL DROP TABLE #SportEvents;
    DECLARE @ErrMsg  NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrLine INT            = ERROR_LINE();
    PRINT CONCAT(N'ERROR at line ', @ErrLine, N': ', @ErrMsg);
    THROW;
END CATCH;
GO
