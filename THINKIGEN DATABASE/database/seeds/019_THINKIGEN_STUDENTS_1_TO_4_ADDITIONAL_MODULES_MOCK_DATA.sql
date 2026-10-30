/*
================================================================================
THINKIGEN ERP - CENTRAL CAMPUS (SCHOOL 1, BRANCH 1) COMPREHENSIVE MOCK DATA SEED
================================================================================
Script:        019_THINKIGEN_STUDENTS_1_TO_4_ADDITIONAL_MODULES_MOCK_DATA.sql
Target Server: Microsoft SQL Server 2019+ / Azure SQL Database / SSMS
Scope:         school_id = 1, branch_id = 1 (Central Campus)
               All Classes: Class 1 to Class 10 (class_id 1..10)
               All Sections: Section A and Section B (section_id 1..20)
               All Active Students (student_id 1..200)

INTEGRATED MODULES & RELATIONAL COVERAGE:
1. [SPORTS PARTICIPATION] (sports_schema.student_sport_history)
   - Directly linked to official SPORTS announcements (management_schema.announcement).
   - activity_name = announcement.title, activity_date = announcement.start_date.
   - Covers TRACK_AND_FIELD, TEAM, INDOOR, OUTDOOR, and INDIVIDUAL sport categories.
   - Realistic placements (1st Place, 2nd Place, 3rd Place, Semi-Finalist, Participated).

2. [PERSONALITY DEVELOPMENT - CLASS TEACHER EVALUATION] (student_schema.student_personality_development)
   - Evaluated by designated Class Teachers (teachers_schema.section_class_teacher_assignment).
   - Ratings across Leadership, Communication, Collaboration, and Responsibility (0.00 to 5.00).
   - Strict 1:1 compliance with UQ_student_personality_dev_student_year.

3. [PERSONALITY DEVELOPMENT REVIEWS - SUBJECT TEACHERS] (student_schema.student_personality_development_review)
   - Subject-specific qualitative evaluations from real assigned faculty (teachers_schema.teacher_subject_assignment).
   - Covers English, Mathematics, Science, Social Science, and Computer Science.
   - Strict compliance with UQ_student_personality_dev_rev_session.

4. [CULTURAL PARTICIPATION] (student_schema.student_cultural_participation)
   - Directly linked to official CULTURAL announcements (management_schema.announcement).
   - event_name = announcement.title, participation_date = announcement.start_date.
   - Covers PERFORMING_ARTS (Dance/Drama), MUSIC (Vocals/Bands), VISUAL_ARTS, and CULTURAL_ACTIVITIES.
   - Enforces unique active participation constraint (UX_student_cultural_part_student_announcement_active).

5. [STUDENT EXAM PERFORMANCE] (student_schema.student_exam_performance)
   - Dynamically aggregates results from student_schema.exam_result & assessment_result.
   - Ensures 100% of students across all 20 sections possess valid total_exams_count and overall_percentage.
   - Idempotent upsert via MERGE adhering to UQ_student_exam_performance_student_scope.
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================================';
PRINT N'STARTING EXECUTION: 019_THINKIGEN_STUDENTS_1_TO_4_ADDITIONAL_MODULES_MOCK_DATA.sql';
PRINT N'Target Database: Thinkigen School ERP';
PRINT N'Scope: school_id = 1, branch_id = 1 (All Classes 1..10, Sections 1..20)';
PRINT N'Modules: Sports, Personal Development, Cultural, Exam Performance';
PRINT N'================================================================================';
GO

-- =============================================================================
-- 0. PREREQUISITE TABLE GUARDS
-- =============================================================================
IF OBJECT_ID(N'sports_schema.student_sport_history', N'U') IS NULL
BEGIN
    RAISERROR(N'CRITICAL: sports_schema.student_sport_history does not exist. Run migration 025_sports_and_grievance_department.sql first.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'student_schema.student_personality_development', N'U') IS NULL
   OR OBJECT_ID(N'student_schema.student_personality_development_review', N'U') IS NULL
BEGIN
    RAISERROR(N'CRITICAL: Personal development tables missing. Run migration 022_personal_development.sql first.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'student_schema.student_cultural_participation', N'U') IS NULL
BEGIN
    RAISERROR(N'CRITICAL: student_schema.student_cultural_participation missing. Run migration 023_cultural_participation.sql first.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'student_schema.student_exam_performance', N'U') IS NULL
BEGIN
    RAISERROR(N'CRITICAL: student_schema.student_exam_performance missing. Run migration 021_student_exam_performance.sql first.', 16, 1);
    RETURN;
END;
GO

-- =============================================================================
-- MAIN TRANSACTION BLOCK
-- =============================================================================
BEGIN TRANSACTION;

BEGIN TRY
    -- -------------------------------------------------------------------------
    -- CONTEXT CONSTANTS & RESOLUTION
    -- -------------------------------------------------------------------------
    DECLARE @SchoolId BIGINT = 1;
    DECLARE @BranchId BIGINT = 1; -- Central Campus
    DECLARE @AcademicYearId BIGINT = 1; -- 2026-2027

    DECLARE @AdminUserId BIGINT = (
        SELECT TOP 1 user_id 
        FROM security_schema.users 
        WHERE user_type IN (N'ADMIN', N'PRINCIPAL') AND is_active = 1 
        ORDER BY user_id ASC
    );
    IF @AdminUserId IS NULL SET @AdminUserId = 1;

    DECLARE @DefaultRegUrl NVARCHAR(2048) = N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0';

    -- Verify Central Campus active students count
    DECLARE @TotalCentralStudents INT = (
        SELECT COUNT(*) 
        FROM student_schema.student 
        WHERE school_id = @SchoolId 
          AND branch_id = @BranchId 
          AND is_active = 1
    );

    PRINT CONCAT(N'✔ Found ', @TotalCentralStudents, N' active students in school_id = ', @SchoolId, N', branch_id = ', @BranchId);

    IF @TotalCentralStudents = 0
    BEGIN
        RAISERROR(N'No active students found for school_id=1, branch_id=1. Seed students first via 002_THINKIGEN_REALISTIC_MOCK_DATA_V22.sql.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- =========================================================================
    -- STEP 1: DEFENSIVE ANNOUNCEMENTS ENRICHMENT (SPORTS & CULTURAL EVENTS)
    -- =========================================================================
    PRINT N'Step 1: Synchronizing prerequisite SPORTS & CULTURAL announcements for Central Campus...';

    IF OBJECT_ID(N'tempdb..#StagingAnnouncements') IS NOT NULL DROP TABLE #StagingAnnouncements;
    CREATE TABLE #StagingAnnouncements (
        announcement_type NVARCHAR(20) NOT NULL,
        sub_category      NVARCHAR(50) NOT NULL,
        title             NVARCHAR(200) NOT NULL,
        description       NVARCHAR(MAX) NOT NULL,
        target_audience   NVARCHAR(100) NOT NULL,
        registration_url  NVARCHAR(2048) NULL,
        start_date        DATE NOT NULL,
        end_date          DATE NOT NULL,
        publish_at        DATETIME2(0) NOT NULL,
        status            NVARCHAR(20) NOT NULL
    );

    INSERT INTO #StagingAnnouncements VALUES
    -- SPORTS EVENTS
    (N'EVENT', N'SPORTS',
     N'Annual Inter-House Track & Field Athletic Championship 2026',
     N'Two days of track and field showdown: 100m sprint, 4x100m relay, long jump, shot put, and hurdles on Central Campus stadium.',
     N'ALL', @DefaultRegUrl, '2026-11-12', '2026-11-14', '2026-10-26T08:00:00', N'PUBLISHED'),

    (N'EVENT', N'SPORTS',
     N'Central Campus Regional 7-a-Side Invitational Football Tournament',
     N'Inter-class and inter-school floodlit football championship hosted at the Central synthetic turf pitch.',
     N'STUDENTS', @DefaultRegUrl, '2026-11-26', '2026-11-28', '2026-11-05T09:00:00', N'PUBLISHED'),

    (N'EVENT', N'SPORTS',
     N'Winter Indoor Badminton & Table Tennis Knockout Trophy',
     N'Singles, doubles, and mixed matches across all class levels inside the indoor sports complex.',
     N'STUDENTS', @DefaultRegUrl, '2026-12-03', '2026-12-05', '2026-11-12T10:00:00', N'PUBLISHED'),

    (N'EVENT', N'SPORTS',
     N'Inter-House Kho-Kho & Kabaddi Traditional Games Fiesta',
     N'Reviving traditional Indian sports with intense matches on standardized clay courts.',
     N'STUDENTS', @DefaultRegUrl, '2026-12-08', '2026-12-09', '2026-11-20T10:00:00', N'PUBLISHED'),

    (N'EVENT', N'SPORTS',
     N'Taekwondo & Martial Arts Belt Progression Grading Camp',
     N'Technical sparring, kata forms, and tile breaking evaluations certified by Grandmaster federation.',
     N'STUDENTS', @DefaultRegUrl, '2027-01-30', '2027-01-30', '2027-01-10T09:00:00', N'PUBLISHED'),

    (N'EVENT', N'SPORTS',
     N'Annual Swimming Gala: Freestyle, Butterfly & Medley Relays',
     N'Freestyle, backstroke, and medley relays in our temperature-controlled aquatic centre.',
     N'ALL', @DefaultRegUrl, '2026-10-20', '2026-10-21', '2026-10-01T08:30:00', N'PUBLISHED'),

    -- CULTURAL EVENTS
    (N'EVENT', N'CULTURAL',
     N'Nritya Tarang 2026: Inter-House Classical & Contemporary Dance Festival',
     N'Celebration of Bharatanatyam, Kathak, Odissi, and contemporary fusion choreography in the main auditorium.',
     N'ALL', @DefaultRegUrl, '2026-10-23', '2026-10-24', '2026-10-01T09:00:00', N'PUBLISHED'),

    (N'EVENT', N'CULTURAL',
     N'Symphony Annual Arts, Classical Dance & Music Gala 2026',
     N'Orchestral choral harmonies, vocal solos, Indian classical ragas, and live violin and keyboard ensembles.',
     N'ALL', @DefaultRegUrl, '2026-12-10', '2026-12-11', '2026-11-20T10:00:00', N'PUBLISHED'),

    (N'EVENT', N'CULTURAL',
     N'Inter-School Shakespearean Theatrical Monologue & Debate Conclave',
     N'Dramatic one-act plays, Shakespearean scenes, and high-stakes parliamentary debate competition.',
     N'ALL', @DefaultRegUrl, '2026-12-17', '2026-12-18', '2026-12-01T09:00:00', N'PUBLISHED'),

    (N'EVENT', N'CULTURAL',
     N'Canvas & Soul: Annual Fine Arts & Sculpture Gallery Exhibition',
     N'Curated gallery of student oil paintings, watercolor landscapes, terracotta pottery, and digital design.',
     N'ALL', @DefaultRegUrl, '2026-11-05', '2026-11-07', '2026-10-18T09:30:00', N'PUBLISHED'),

    (N'EVENT', N'CULTURAL',
     N'Young Authors Creative Anthologies & Poetry Book Launch Showcase',
     N'Exhibition of student-authored anthologies, illustrated novellas, and verse recitations.',
     N'ALL', NULL, '2026-12-08', '2026-12-09', '2026-11-25T11:00:00', N'PUBLISHED');

    INSERT INTO management_schema.announcement
        (school_id, branch_id, academic_year_id, announcement_type, sub_category,
         title, description, target_audience, registration_url,
         start_date, end_date, publish_at, status, is_active, created_by)
    SELECT
        @SchoolId, @BranchId, @AcademicYearId,
        sa.announcement_type, sa.sub_category,
        sa.title, sa.description, sa.target_audience, sa.registration_url,
        sa.start_date, sa.end_date, sa.publish_at, sa.status, 1, @AdminUserId
    FROM #StagingAnnouncements sa
    WHERE NOT EXISTS (
        SELECT 1 FROM management_schema.announcement ex
        WHERE ex.school_id = @SchoolId 
          AND (ex.branch_id = @BranchId OR ex.branch_id IS NULL)
          AND ex.title = sa.title
    );

    DECLARE @TotalCentralAnn INT = (
        SELECT COUNT(*) 
        FROM management_schema.announcement 
        WHERE school_id = @SchoolId 
          AND (branch_id = @BranchId OR branch_id IS NULL) 
          AND is_active = 1
    );
    PRINT CONCAT(N'   ✔ Prerequisite announcements synchronized. Total active Central announcements: ', @TotalCentralAnn);

    -- =========================================================================
    -- STEP 2: SPORTS PARTICIPATION (sports_schema.student_sport_history)
    -- =========================================================================
    PRINT N'Step 2: Populating Student Sports Participation linked directly to Sports Announcements...';

    -- Map all active SPORTS announcements available to Central Campus
    IF OBJECT_ID(N'tempdb..#SportsAnnMap') IS NOT NULL DROP TABLE #SportsAnnMap;
    CREATE TABLE #SportsAnnMap (
        ann_rank        INT PRIMARY KEY,
        announcement_id BIGINT NOT NULL,
        title           NVARCHAR(200) NOT NULL,
        start_date      DATE NOT NULL,
        sport_name      VARCHAR(100) NOT NULL,
        sport_category  VARCHAR(100) NOT NULL
    );

    INSERT INTO #SportsAnnMap (ann_rank, announcement_id, title, start_date, sport_name, sport_category)
    SELECT
        ROW_NUMBER() OVER (ORDER BY announcement_id ASC) AS ann_rank,
        announcement_id,
        title,
        start_date,
        CASE
            WHEN title LIKE N'%Track%' OR title LIKE N'%Athletic%' THEN 'Athletics'
            WHEN title LIKE N'%Football%' THEN 'Football'
            WHEN title LIKE N'%Badminton%' THEN 'Badminton'
            WHEN title LIKE N'%Table Tennis%' THEN 'Table Tennis'
            WHEN title LIKE N'%Tennis%' THEN 'Table Tennis'
            WHEN title LIKE N'%Kho%' OR title LIKE N'%Kabaddi%' THEN 'Kho-Kho & Kabaddi'
            WHEN title LIKE N'%Taekwondo%' OR title LIKE N'%Martial%' THEN 'Taekwondo'
            WHEN title LIKE N'%Swim%' THEN 'Swimming'
            WHEN title LIKE N'%Cricket%' THEN 'Cricket'
            WHEN title LIKE N'%Basketball%' THEN 'Basketball'
            ELSE 'Athletics'
        END AS sport_name,
        CASE
            WHEN title LIKE N'%Track%' OR title LIKE N'%Athletic%' THEN 'TRACK_AND_FIELD'
            WHEN title LIKE N'%Football%' OR title LIKE N'%Cricket%' OR title LIKE N'%Basketball%' OR title LIKE N'%Kho%' OR title LIKE N'%Kabaddi%' THEN 'TEAM'
            WHEN title LIKE N'%Badminton%' OR title LIKE N'%Table Tennis%' OR title LIKE N'%Chess%' THEN 'INDOOR'
            WHEN title LIKE N'%Taekwondo%' OR title LIKE N'%Swim%' THEN 'INDIVIDUAL'
            ELSE 'OUTDOOR'
        END AS sport_category
    FROM management_schema.announcement
    WHERE school_id = @SchoolId 
      AND (branch_id = @BranchId OR branch_id IS NULL)
      AND sub_category = N'SPORTS'
      AND is_active = 1;

    DECLARE @TotalSportsAnn INT = (SELECT COUNT(*) FROM #SportsAnnMap);
    PRINT CONCAT(N'   Found ', @TotalSportsAnn, N' active sports announcements to map student participation.');

    -- Generate candidate sports participation for each Central student (2 announcements per student)
    IF OBJECT_ID(N'tempdb..#SportsInsertStaging') IS NOT NULL DROP TABLE #SportsInsertStaging;
    CREATE TABLE #SportsInsertStaging (
        student_id      BIGINT NOT NULL,
        school_id       BIGINT NOT NULL,
        branch_id       BIGINT NOT NULL,
        class_id        BIGINT NOT NULL,
        section_id      BIGINT NOT NULL,
        sport_name      VARCHAR(100) NOT NULL,
        announcement_id BIGINT NOT NULL,
        activity_date   DATE NOT NULL,
        activity_name   VARCHAR(200) NOT NULL,
        result          VARCHAR(200) NULL,
        sport_category  VARCHAR(100) NOT NULL,
        created_by      BIGINT NOT NULL
    );

    INSERT INTO #SportsInsertStaging
        (student_id, school_id, branch_id, class_id, section_id,
         sport_name, announcement_id, activity_date, activity_name,
         result, sport_category, created_by)
    SELECT
        st.student_id,
        st.school_id,
        st.branch_id,
        st.class_id,
        st.section_id,
        sam.sport_name,
        sam.announcement_id,
        sam.start_date AS activity_date,
        sam.title AS activity_name,
        CASE 
            WHEN sam.start_date > CAST(GETUTCDATE() AS DATE) THEN 'Registered'
            ELSE
                CASE ((st.student_id * 7 + sam.ann_rank * 3) % 8)
                    WHEN 0 THEN '1st Place (Gold Medal)'
                    WHEN 1 THEN '2nd Place (Silver Medal)'
                    WHEN 2 THEN '3rd Place (Bronze Medal)'
                    WHEN 3 THEN 'Finalist - Merit Certificate'
                    WHEN 4 THEN 'Semi-Finalist'
                    WHEN 5 THEN 'Quarter-Finalist'
                    WHEN 6 THEN 'Winner'
                    ELSE 'Participated'
                END
        END AS result,
        sam.sport_category,
        @AdminUserId
    FROM student_schema.student st
    CROSS JOIN (VALUES (0), (1)) AS slot(offset_val)
    INNER JOIN #SportsAnnMap sam 
        ON sam.ann_rank = (((st.student_id + offset_val * 2 - 1) % NULLIF(@TotalSportsAnn, 0)) + 1)
    WHERE st.school_id = @SchoolId 
      AND st.branch_id = @BranchId 
      AND st.is_active = 1;

    INSERT INTO sports_schema.student_sport_history
        (student_id, school_id, branch_id, class_id, section_id,
         sport_name, announcement_id, activity_date, activity_name,
         result, created_at, created_by, updated_at, updated_by, sport_category)
    SELECT
        sis.student_id, sis.school_id, sis.branch_id, sis.class_id, sis.section_id,
        sis.sport_name, sis.announcement_id, sis.activity_date, sis.activity_name,
        sis.result, SYSUTCDATETIME(), sis.created_by, SYSUTCDATETIME(), sis.created_by,
        sis.sport_category
    FROM #SportsInsertStaging sis
    WHERE NOT EXISTS (
        SELECT 1 FROM sports_schema.student_sport_history ex
        WHERE ex.student_id = sis.student_id
          AND ex.announcement_id = sis.announcement_id
    );

    DECLARE @SportsRowsInserted INT = @@ROWCOUNT;
    PRINT CONCAT(N'   ✔ Student sports history records processed. Rows inserted: ', @SportsRowsInserted);

    -- =========================================================================
    -- STEP 3: PERSONALITY DEVELOPMENT (Class Teacher Ratings)
    -- =========================================================================
    PRINT N'Step 3: Populating Student Personality Development (Class Teacher ratings)...';

    -- Resolve class teacher assignment for every section of Central Campus
    IF OBJECT_ID(N'tempdb..#ClassTeacherMap') IS NOT NULL DROP TABLE #ClassTeacherMap;
    CREATE TABLE #ClassTeacherMap (
        section_id        BIGINT PRIMARY KEY,
        class_teacher_id  BIGINT NOT NULL,
        teacher_user_id   BIGINT NOT NULL
    );

    INSERT INTO #ClassTeacherMap (section_id, class_teacher_id, teacher_user_id)
    SELECT
        sec.section_id,
        COALESCE(scta.teacher_id, def_t.teacher_id, 1) AS class_teacher_id,
        COALESCE(t.user_id, def_t.user_id, @AdminUserId) AS teacher_user_id
    FROM management_schema.section sec
    JOIN management_schema.school_class sc ON sc.class_id = sec.class_id
    OUTER APPLY (
        SELECT TOP 1 teacher_id 
        FROM teachers_schema.section_class_teacher_assignment a
        WHERE a.section_id = sec.section_id 
          AND a.school_id = @SchoolId 
          AND a.branch_id = @BranchId
          AND a.is_active = 1
        ORDER BY a.section_class_teacher_assignment_id DESC
    ) scta
    LEFT JOIN teachers_schema.teacher t ON t.teacher_id = scta.teacher_id
    OUTER APPLY (
        SELECT TOP 1 t2.teacher_id, t2.user_id 
        FROM teachers_schema.teacher t2
        WHERE t2.branch_id = @BranchId AND t2.school_id = @SchoolId AND t2.is_active = 1
        ORDER BY t2.teacher_id ASC
    ) def_t
    WHERE sc.school_id = @SchoolId 
      AND sc.class_id BETWEEN 1 AND 10;

    -- Upsert personality development for each student (UQ on student_id, academic_year_id)
    ;WITH StagedPersonalDev AS (
        SELECT
            st.school_id,
            st.branch_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            st.student_id,
            ctm.class_teacher_id,
            ctm.teacher_user_id,
            CAST(3.30 + ((st.student_id * 11) % 16) * 0.10 AS DECIMAL(3, 2)) AS leadership_rating,
            CAST(3.40 + ((st.student_id * 7)  % 15) * 0.10 AS DECIMAL(3, 2)) AS communication_rating,
            CAST(3.20 + ((st.student_id * 13) % 17) * 0.10 AS DECIMAL(3, 2)) AS collaboration_rating,
            CAST(3.50 + ((st.student_id * 19) % 14) * 0.10 AS DECIMAL(3, 2)) AS responsibility_rating,
            CAST(ROUND((
                (3.30 + ((st.student_id * 11) % 16) * 0.10) +
                (3.40 + ((st.student_id * 7)  % 15) * 0.10) +
                (3.20 + ((st.student_id * 13) % 17) * 0.10) +
                (3.50 + ((st.student_id * 19) % 14) * 0.10)
            ) / 4.0, 2) AS DECIMAL(3, 2)) AS overall_rating
        FROM student_schema.student st
        INNER JOIN #ClassTeacherMap ctm ON ctm.section_id = st.section_id
        WHERE st.school_id = @SchoolId 
          AND st.branch_id = @BranchId 
          AND st.is_active = 1
    )
    MERGE INTO student_schema.student_personality_development AS tgt
    USING StagedPersonalDev AS src
    ON (tgt.student_id = src.student_id AND tgt.academic_year_id = src.academic_year_id)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.class_teacher_id      = src.class_teacher_id,
            tgt.leadership_rating     = src.leadership_rating,
            tgt.communication_rating  = src.communication_rating,
            tgt.collaboration_rating  = src.collaboration_rating,
            tgt.responsibility_rating = src.responsibility_rating,
            tgt.overall_rating        = src.overall_rating,
            tgt.updated_at            = SYSUTCDATETIME(),
            tgt.updated_by            = src.teacher_user_id
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            school_id, branch_id, academic_year_id, class_id, section_id,
            student_id, class_teacher_id,
            leadership_rating, communication_rating, collaboration_rating,
            responsibility_rating, overall_rating,
            is_active, created_at, created_by, updated_at, updated_by
        )
        VALUES (
            src.school_id, src.branch_id, src.academic_year_id, src.class_id, src.section_id,
            src.student_id, src.class_teacher_id,
            src.leadership_rating, src.communication_rating, src.collaboration_rating,
            src.responsibility_rating, src.overall_rating,
            1, SYSUTCDATETIME(), src.teacher_user_id, SYSUTCDATETIME(), src.teacher_user_id
        );

    DECLARE @PersonalDevRowsUpserted INT = @@ROWCOUNT;
    PRINT CONCAT(N'   ✔ Student personality development ratings upserted: ', @PersonalDevRowsUpserted);

    -- =========================================================================
    -- STEP 4: PERSONALITY DEVELOPMENT REVIEWS (Subject Teachers)
    -- =========================================================================
    PRINT N'Step 4: Populating Subject Teacher Personality Reviews across all subjects...';

    -- Template rubrics directly referencing school events and academic performance
    IF OBJECT_ID(N'tempdb..#ReviewRubric') IS NOT NULL DROP TABLE #ReviewRubric;
    CREATE TABLE #ReviewRubric (
        rubric_id       INT PRIMARY KEY,
        category_type   NVARCHAR(50) NOT NULL,
        subject_name    NVARCHAR(100) NOT NULL,
        rating_score    INT NOT NULL,
        review_text     NVARCHAR(MAX) NOT NULL,
        review_day_diff INT NOT NULL
    );

    INSERT INTO #ReviewRubric VALUES
    (1, N'COMMUNICATION_RATING', N'English', 5,
     N'Exemplary articulation in class presentations, debate sessions, and creative writing. Actively participates in literary elocution events.', -20),

    (2, N'RESPONSIBILITY_RATING', N'Mathematics', 5,
     N'Consistently submits analytical problem sets well ahead of deadlines; demonstrates rigorous logical reasoning and discipline.', -15),

    (3, N'COLLABORATION_RATING', N'Science', 4,
     N'Outstanding team player in experimental laboratory modules; actively shares apparatus responsibilities and observes lab safety protocols.', -28),

    (4, N'LEADERSHIP_RATING', N'Social Science', 5,
     N'Takes initiative during group civic seminars and historical research projects; articulates complex socio-economic ideas with poise.', -10),

    (5, N'RESPONSIBILITY_RATING', N'Computer Science', 5,
     N'Demonstrates exceptional focus in software lab tasks, python scripting exercises, and algorithmic logic assignments.', -5),

    (6, N'COMMUNICATION_RATING', N'Social Science', 4,
     N'Expresses reasoned perspectives during class debates on constitution, geography, and world affairs with clarity and respect for peers.', -25);

    -- Staged review records ensuring resolution of subject teacher
    IF OBJECT_ID(N'tempdb..#StagedReviews') IS NOT NULL DROP TABLE #StagedReviews;
    CREATE TABLE #StagedReviews (
        student_id       BIGINT NOT NULL,
        school_id        BIGINT NOT NULL,
        branch_id        BIGINT NOT NULL,
        academic_year_id BIGINT NOT NULL,
        class_id         BIGINT NOT NULL,
        section_id       BIGINT NOT NULL,
        teacher_id       BIGINT NOT NULL,
        subject_id       BIGINT NOT NULL,
        category_type    NVARCHAR(50) NOT NULL,
        rating           INT NOT NULL,
        review           NVARCHAR(MAX) NOT NULL,
        review_date      DATE NOT NULL,
        teacher_user_id  BIGINT NOT NULL
    );

    INSERT INTO #StagedReviews
        (student_id, school_id, branch_id, academic_year_id, class_id, section_id,
         teacher_id, subject_id, category_type, rating, review, review_date, teacher_user_id)
    SELECT
        st.student_id,
        st.school_id,
        st.branch_id,
        st.academic_year_id,
        st.class_id,
        st.section_id,
        COALESCE(tsa.teacher_id, sub_teacher.teacher_id, 1) AS teacher_id,
        sub.subject_id,
        rr.category_type,
        CASE 
            WHEN ((st.student_id + rr.rubric_id) % 5 = 0) THEN 4 
            ELSE rr.rating_score 
        END AS rating,
        rr.review_text,
        COALESCE(valid_tp.period_date, CAST('2026-10-20' AS DATE)) AS review_date,
        COALESCE(t.user_id, sub_teacher.user_id, @AdminUserId) AS teacher_user_id
    FROM student_schema.student st
    CROSS JOIN #ReviewRubric rr
    INNER JOIN management_schema.subject sub 
        ON sub.subject_name = rr.subject_name AND sub.is_active = 1
    LEFT JOIN teachers_schema.teacher_subject_assignment tsa
        ON tsa.section_id = st.section_id
       AND tsa.subject_id = sub.subject_id
       AND tsa.school_id = @SchoolId
       AND tsa.branch_id = @BranchId
       AND tsa.is_active = 1
    LEFT JOIN teachers_schema.teacher t ON t.teacher_id = tsa.teacher_id
    OUTER APPLY (
        SELECT TOP 1 t2.teacher_id, t2.user_id 
        FROM teachers_schema.teacher t2
        WHERE t2.subject_id = sub.subject_id 
          AND t2.branch_id = @BranchId 
          AND t2.school_id = @SchoolId 
          AND t2.is_active = 1
        ORDER BY t2.teacher_id ASC
    ) sub_teacher
    OUTER APPLY (
        SELECT TOP 1 tp.period_date
        FROM management_schema.timetable_period tp
        WHERE tp.timetable_id = st.section_id
          AND tp.subject_id = sub.subject_id
          AND tp.period_type = N'CLASS'
          AND (DATEDIFF(DAY, '1900-01-07', tp.period_date) % 7) <> 0
        ORDER BY tp.period_date ASC
    ) valid_tp
    WHERE st.school_id = @SchoolId 
      AND st.branch_id = @BranchId 
      AND st.is_active = 1;

    -- Insert deduplicated by (student_id, subject_id, teacher_id, category_type, review_date)
    ;WITH DeduplicatedReviews AS (
        SELECT
            sr.*,
            ROW_NUMBER() OVER (
                PARTITION BY sr.student_id, sr.subject_id, sr.teacher_id, sr.category_type, sr.review_date
                ORDER BY sr.student_id
            ) AS rn
        FROM #StagedReviews sr
    )
    INSERT INTO student_schema.student_personality_development_review
        (school_id, branch_id, academic_year_id, class_id, section_id,
         student_id, teacher_id, subject_id, category_type,
         rating, review, review_date, is_active,
         created_at, created_by, updated_at, updated_by)
    SELECT
        dr.school_id, dr.branch_id, dr.academic_year_id, dr.class_id, dr.section_id,
        dr.student_id, dr.teacher_id, dr.subject_id, dr.category_type,
        dr.rating, dr.review, dr.review_date, 1,
        SYSUTCDATETIME(), dr.teacher_user_id, SYSUTCDATETIME(), dr.teacher_user_id
    FROM DeduplicatedReviews dr
    WHERE dr.rn = 1
      AND NOT EXISTS (
          SELECT 1 FROM student_schema.student_personality_development_review ex
          WHERE ex.student_id = dr.student_id
            AND ex.subject_id = dr.subject_id
            AND ex.teacher_id = dr.teacher_id
            AND ex.category_type = dr.category_type
            AND ex.review_date = dr.review_date
      );

    DECLARE @ReviewRowsInserted INT = @@ROWCOUNT;
    PRINT CONCAT(N'   ✔ Student subject personality reviews inserted: ', @ReviewRowsInserted);

    -- =========================================================================
    -- STEP 5: CULTURAL PARTICIPATION (student_schema.student_cultural_participation)
    -- =========================================================================
    PRINT N'Step 5: Populating Cultural Participation linked directly to Cultural Announcements...';

    -- Map all active CULTURAL announcements available to Central Campus
    IF OBJECT_ID(N'tempdb..#CulturalAnnMap') IS NOT NULL DROP TABLE #CulturalAnnMap;
    CREATE TABLE #CulturalAnnMap (
        ann_rank        INT PRIMARY KEY,
        announcement_id BIGINT NOT NULL,
        event_name      NVARCHAR(200) NOT NULL,
        start_date      DATE NOT NULL,
        category        NVARCHAR(100) NOT NULL,
        role_default    NVARCHAR(100) NOT NULL
    );

    INSERT INTO #CulturalAnnMap (ann_rank, announcement_id, event_name, start_date, category, role_default)
    SELECT
        ROW_NUMBER() OVER (ORDER BY announcement_id ASC) AS ann_rank,
        announcement_id,
        title,
        start_date,
        CASE
            WHEN title LIKE N'%Dance%' THEN N'PERFORMING_ARTS'
            WHEN title LIKE N'%Music%' OR title LIKE N'%Band%' OR title LIKE N'%Symphony%' THEN N'MUSIC'
            WHEN title LIKE N'%Arts%' OR title LIKE N'%Canvas%' OR title LIKE N'%Sculpture%' THEN N'VISUAL_ARTS'
            WHEN title LIKE N'%Theat%' OR title LIKE N'%Drama%' OR title LIKE N'%Shakespeare%' THEN N'PERFORMING_ARTS'
            ELSE N'CULTURAL_ACTIVITIES'
        END AS category,
        CASE
            WHEN title LIKE N'%Dance%' THEN N'DANCER'
            WHEN title LIKE N'%Music%' OR title LIKE N'%Band%' OR title LIKE N'%Symphony%' THEN N'VOCALIST'
            WHEN title LIKE N'%Arts%' OR title LIKE N'%Canvas%' THEN N'EXHIBITOR'
            WHEN title LIKE N'%Theat%' OR title LIKE N'%Drama%' OR title LIKE N'%Shakespeare%' THEN N'ACTOR'
            ELSE N'ORGANIZER'
        END AS role_default
    FROM management_schema.announcement
    WHERE school_id = @SchoolId 
      AND (branch_id = @BranchId OR branch_id IS NULL)
      AND sub_category = N'CULTURAL'
      AND is_active = 1;

    DECLARE @TotalCulturalAnn INT = (SELECT COUNT(*) FROM #CulturalAnnMap);
    PRINT CONCAT(N'   Found ', @TotalCulturalAnn, N' active cultural announcements to map student participation.');

    -- Staging cultural candidate rows (1 participation per student per announcement)
    IF OBJECT_ID(N'tempdb..#CulturalInsertStaging') IS NOT NULL DROP TABLE #CulturalInsertStaging;
    CREATE TABLE #CulturalInsertStaging (
        student_id           BIGINT NOT NULL,
        school_id            BIGINT NOT NULL,
        branch_id            BIGINT NOT NULL,
        academic_year_id     BIGINT NOT NULL,
        class_id             BIGINT NOT NULL,
        section_id           BIGINT NOT NULL,
        announcement_id      BIGINT NOT NULL,
        event_name           NVARCHAR(200) NOT NULL,
        teacher_id           BIGINT NOT NULL,
        category             NVARCHAR(100) NOT NULL,
        role_involvement     NVARCHAR(100) NULL,
        result               NVARCHAR(100) NULL,
        participation_status NVARCHAR(30) NOT NULL,
        participation_date   DATE NULL
    );

    INSERT INTO #CulturalInsertStaging
        (student_id, school_id, branch_id, academic_year_id, class_id, section_id,
         announcement_id, event_name, teacher_id, category, role_involvement,
         result, participation_status, participation_date)
    SELECT
        st.student_id,
        st.school_id,
        st.branch_id,
        st.academic_year_id,
        st.class_id,
        st.section_id,
        cam.announcement_id,
        cam.event_name,
        ctm.class_teacher_id,
        cam.category,
        CASE ((st.student_id * 5) % 3)
            WHEN 0 THEN cam.role_default
            WHEN 1 THEN N'ORGANIZER'
            ELSE cam.role_default
        END AS role_involvement,
        CASE 
            WHEN cam.start_date > CAST(GETUTCDATE() AS DATE) THEN NULL
            ELSE
                CASE ((st.student_id * 13) % 7)
                    WHEN 0 THEN N'FIRST_PLACE'
                    WHEN 1 THEN N'SECOND_PLACE'
                    WHEN 2 THEN N'THIRD_PLACE'
                    WHEN 3 THEN N'SPECIAL_MENTION'
                    WHEN 4 THEN N'RUNNER_UP'
                    WHEN 5 THEN N'PERFORMED'
                    ELSE N'PARTICIPATED'
                END
        END AS result,
        CASE 
            WHEN cam.start_date > CAST(GETUTCDATE() AS DATE) THEN N'REGISTERED'
            ELSE N'PARTICIPATED'
        END AS participation_status,
        cam.start_date AS participation_date
    FROM student_schema.student st
    INNER JOIN #ClassTeacherMap ctm ON ctm.section_id = st.section_id
    CROSS APPLY (
        SELECT TOP 1 *
        FROM #CulturalAnnMap cam2
        WHERE cam2.ann_rank = (((st.student_id - 1) % NULLIF(@TotalCulturalAnn, 0)) + 1)
    ) cam
    WHERE st.school_id = @SchoolId 
      AND st.branch_id = @BranchId 
      AND st.is_active = 1;

    INSERT INTO student_schema.student_cultural_participation
        (student_id, school_id, branch_id, academic_year_id, class_id, section_id,
         announcement_id, event_name, teacher_id, category, role_involvement,
         result, participation_status, participation_date, is_active,
         created_at, updated_at)
    SELECT
        cis.student_id, cis.school_id, cis.branch_id, cis.academic_year_id, cis.class_id, cis.section_id,
        cis.announcement_id, cis.event_name, cis.teacher_id, cis.category, cis.role_involvement,
        cis.result, cis.participation_status, cis.participation_date, 
        1,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    FROM #CulturalInsertStaging cis
    WHERE NOT EXISTS (
        SELECT 1 FROM student_schema.student_cultural_participation ex
        WHERE ex.student_id = cis.student_id
          AND ex.announcement_id = cis.announcement_id
          AND ex.is_active = 1
    );

    DECLARE @CulturalRowsInserted INT = @@ROWCOUNT;
    PRINT CONCAT(N'   ✔ Student cultural participation records inserted: ', @CulturalRowsInserted);

    -- =========================================================================
    -- STEP 6: STUDENT EXAM PERFORMANCE (student_schema.student_exam_performance)
    -- =========================================================================
    PRINT N'Step 6: Calculating and synchronizing Student Exam Performance summaries...';

    -- Source 1: Aggregation from student_schema.exam_result
    IF OBJECT_ID(N'tempdb..#ExamResultAggregates') IS NOT NULL DROP TABLE #ExamResultAggregates;
    CREATE TABLE #ExamResultAggregates (
        student_id         BIGINT PRIMARY KEY,
        academic_year_id   BIGINT NOT NULL,
        class_id           BIGINT NOT NULL,
        section_id         BIGINT NOT NULL,
        total_exams_count  INT NOT NULL,
        overall_percentage DECIMAL(5, 2) NOT NULL
    );

    INSERT INTO #ExamResultAggregates
        (student_id, academic_year_id, class_id, section_id, total_exams_count, overall_percentage)
    SELECT
        er.student_id,
        st.academic_year_id,
        st.class_id,
        st.section_id,
        COUNT(DISTINCT es.exam_id) AS total_exams_count,
        CAST(ROUND(AVG(
            CAST(er.marks_obtained * 100.0 / NULLIF(es.max_marks, 0) AS DECIMAL(7, 4))
        ), 2) AS DECIMAL(5, 2)) AS overall_percentage
    FROM student_schema.exam_result er
    INNER JOIN student_schema.student st ON st.student_id = er.student_id
    INNER JOIN management_schema.exam_schedule es ON es.exam_schedule_id = er.exam_schedule_id
    WHERE st.school_id = @SchoolId 
      AND st.branch_id = @BranchId 
      AND er.is_active = 1
      AND er.result_status <> N'ABSENT'
      AND er.marks_obtained IS NOT NULL
      AND es.max_marks > 0
    GROUP BY er.student_id, st.academic_year_id, st.class_id, st.section_id;

    -- Source 2: Fallback deterministic calculation for any student without recorded exam results
    IF OBJECT_ID(N'tempdb..#CombinedExamPerformance') IS NOT NULL DROP TABLE #CombinedExamPerformance;
    CREATE TABLE #CombinedExamPerformance (
        student_id         BIGINT PRIMARY KEY,
        academic_year_id   BIGINT NOT NULL,
        class_id           BIGINT NOT NULL,
        section_id         BIGINT NOT NULL,
        total_exams_count  INT NOT NULL,
        overall_percentage DECIMAL(5, 2) NOT NULL
    );

    INSERT INTO #CombinedExamPerformance
    SELECT * FROM #ExamResultAggregates;

    -- Fill missing active Central students with realistic academic metrics (70% - 96%)
    INSERT INTO #CombinedExamPerformance
        (student_id, academic_year_id, class_id, section_id, total_exams_count, overall_percentage)
    SELECT
        st.student_id,
        st.academic_year_id,
        st.class_id,
        st.section_id,
        2 AS total_exams_count,
        CAST(ROUND(72.50 + ((st.student_id * 17 + st.class_id * 3) % 23) + ((st.student_id * 5) % 9) * 0.10, 2) AS DECIMAL(5, 2)) AS overall_percentage
    FROM student_schema.student st
    WHERE st.school_id = @SchoolId 
      AND st.branch_id = @BranchId 
      AND st.is_active = 1
      AND st.student_id NOT IN (SELECT student_id FROM #CombinedExamPerformance);

    -- Upsert into student_schema.student_exam_performance
    MERGE INTO student_schema.student_exam_performance AS tgt
    USING #CombinedExamPerformance AS src
    ON (tgt.student_id = src.student_id 
        AND tgt.academic_year_id = src.academic_year_id 
        AND tgt.class_id = src.class_id 
        AND tgt.section_id = src.section_id)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.total_exams_count  = src.total_exams_count,
            tgt.overall_percentage = src.overall_percentage,
            tgt.updated_at         = SYSUTCDATETIME()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            student_id, academic_year_id, class_id, section_id,
            total_exams_count, overall_percentage, created_at, updated_at
        )
        VALUES (
            src.student_id, src.academic_year_id, src.class_id, src.section_id,
            src.total_exams_count, src.overall_percentage, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

    DECLARE @ExamPerfRowsUpserted INT = @@ROWCOUNT;
    PRINT CONCAT(N'   ✔ Student exam performance summaries upserted: ', @ExamPerfRowsUpserted);

    -- -------------------------------------------------------------------------
    -- CLEANUP TEMPORARY TABLES
    -- -------------------------------------------------------------------------
    DROP TABLE IF EXISTS #StagingAnnouncements;
    DROP TABLE IF EXISTS #SportsAnnMap;
    DROP TABLE IF EXISTS #SportsInsertStaging;
    DROP TABLE IF EXISTS #ClassTeacherMap;
    DROP TABLE IF EXISTS #ReviewRubric;
    DROP TABLE IF EXISTS #StagedReviews;
    DROP TABLE IF EXISTS #CulturalAnnMap;
    DROP TABLE IF EXISTS #CulturalInsertStaging;
    DROP TABLE IF EXISTS #ExamResultAggregates;
    DROP TABLE IF EXISTS #CombinedExamPerformance;

    COMMIT TRANSACTION;
    PRINT N'================================================================================';
    PRINT N'SUCCESS: 019_THINKIGEN_STUDENTS_1_TO_4_ADDITIONAL_MODULES_MOCK_DATA.sql APPLIED!';
    PRINT N'================================================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'********************************************************************************';
    PRINT N'ERROR ENCOUNTERED DURING SEED SCRIPT EXECUTION:';
    PRINT CONCAT(N'Message: ', ERROR_MESSAGE());
    PRINT CONCAT(N'Line: ', ERROR_LINE());
    PRINT CONCAT(N'Procedure: ', ISNULL(ERROR_PROCEDURE(), N'Main Block'));
    PRINT N'********************************************************************************';

    -- Clean up staging tables
    DROP TABLE IF EXISTS #StagingAnnouncements;
    DROP TABLE IF EXISTS #SportsAnnMap;
    DROP TABLE IF EXISTS #SportsInsertStaging;
    DROP TABLE IF EXISTS #ClassTeacherMap;
    DROP TABLE IF EXISTS #ReviewRubric;
    DROP TABLE IF EXISTS #StagedReviews;
    DROP TABLE IF EXISTS #CulturalAnnMap;
    DROP TABLE IF EXISTS #CulturalInsertStaging;
    DROP TABLE IF EXISTS #ExamResultAggregates;
    DROP TABLE IF EXISTS #CombinedExamPerformance;

    THROW;
END CATCH;
GO

-- =============================================================================
-- SSMS VERIFICATION & AUDIT QUERIES
-- =============================================================================
PRINT N'';
PRINT N'--- AUDIT REPORT: Central Campus (School 1, Branch 1) Additional Modules Summary ---';

SELECT
    sc.class_id,
    sc.class_name,
    sec.section_id,
    sec.section_name,
    COUNT(DISTINCT st.student_id) AS total_active_students,
    COUNT(DISTINCT ssh.student_sport_history_id) AS sports_records_count,
    COUNT(DISTINCT spd.personality_development_id) AS personality_dev_count,
    COUNT(DISTINCT spdr.personality_review_id) AS personality_reviews_count,
    COUNT(DISTINCT scp.cultural_participation_id) AS cultural_participations_count,
    COUNT(DISTINCT sep.student_exam_performance_id) AS exam_performance_count,
    CAST(AVG(sep.overall_percentage) AS DECIMAL(5, 2)) AS class_avg_exam_pct
FROM management_schema.school_class sc
INNER JOIN management_schema.section sec 
    ON sec.class_id = sc.class_id
INNER JOIN student_schema.student st 
    ON st.section_id = sec.section_id AND st.is_active = 1
LEFT JOIN sports_schema.student_sport_history ssh 
    ON ssh.student_id = st.student_id
LEFT JOIN student_schema.student_personality_development spd 
    ON spd.student_id = st.student_id
LEFT JOIN student_schema.student_personality_development_review spdr 
    ON spdr.student_id = st.student_id
LEFT JOIN student_schema.student_cultural_participation scp 
    ON scp.student_id = st.student_id
LEFT JOIN student_schema.student_exam_performance sep 
    ON sep.student_id = st.student_id
WHERE sc.school_id = 1 
  AND sc.class_id BETWEEN 1 AND 10
GROUP BY sc.class_id, sc.class_name, sec.section_id, sec.section_name
ORDER BY sc.class_id, sec.section_id;

PRINT N'--- SPORTS MODULE: Announcement Linking Verification ---';
SELECT
    a.announcement_id,
    a.title AS sports_announcement_title,
    a.sub_category,
    COUNT(ssh.student_sport_history_id) AS total_students_participated,
    COUNT(DISTINCT ssh.class_id) AS total_classes_represented,
    COUNT(DISTINCT ssh.section_id) AS total_sections_represented
FROM management_schema.announcement a
INNER JOIN sports_schema.student_sport_history ssh 
    ON ssh.announcement_id = a.announcement_id
WHERE ssh.school_id = 1 AND ssh.branch_id = 1
GROUP BY a.announcement_id, a.title, a.sub_category
ORDER BY a.announcement_id ASC;

PRINT N'--- CULTURAL MODULE: Announcement Linking Verification ---';
SELECT
    a.announcement_id,
    a.title AS cultural_announcement_title,
    a.sub_category,
    COUNT(scp.cultural_participation_id) AS total_students_participated,
    COUNT(DISTINCT scp.class_id) AS total_classes_represented,
    COUNT(DISTINCT scp.section_id) AS total_sections_represented
FROM management_schema.announcement a
INNER JOIN student_schema.student_cultural_participation scp 
    ON scp.announcement_id = a.announcement_id
WHERE scp.school_id = 1 AND scp.branch_id = 1
GROUP BY a.announcement_id, a.title, a.sub_category
ORDER BY a.announcement_id ASC;
GO
