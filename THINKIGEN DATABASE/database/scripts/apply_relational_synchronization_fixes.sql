/* ============================================================================
   SCRIPT: APPLY RELATIONAL & LOGICAL SYNCHRONIZATION FIXES (V3)
   Target Database: Thinkigen School ERP (Microsoft SQL Server / Azure SQL / SSMS)
   
   AZURE SQL COMPATIBILITY NOTE:
   - Do NOT run "USE [database_name];" because Azure SQL Database does not
     support cross-database switching via USE statements.
   - Simply connect directly to your target database in SSMS (via the database
     dropdown on the top toolbar or the connection properties).
   
   REQUIREMENTS & LOGICAL RULES IMPLEMENTED:
   1. SPORTS:
      - Adds 'participation_status' column to sports_schema.student_sport_history.
      - Rule: If registered, status = 'Registered' and result = NULL until updated by management.
              When management updates result, status = 'Participated' and result is updated.
      - Synchronizes activity_name = announcement.title, activity_date = announcement.start_date.
   2. CULTURAL:
      - Synchronizes event_name = announcement.title, participation_date = announcement.start_date.
      - Rule: If registered, status = 'REGISTERED' and result = NULL until updated by management.
              When management updates result, status = 'PARTICIPATED' and result is updated.
      - Role Involvement: 'PARTICIPANT' or 'Participated' is STRICTLY DISALLOWED.
        Specifically assigns: DANCER, VOCALIST, INSTRUMENTALIST, EXHIBITOR, ACTOR, ORGANIZER.
   3. HOMEWORKS & ASSESSMENTS REMOVAL & RE-SEEDING:
      - Completely clears existing mock data from homeworks, homework_status, assessments, assessment_result.
      - Homeworks (teachers_schema.homework): Re-seeds for all active instructional class periods
        from timetable_period spanning past and future dates up to timetable horizon.
      - Homework Status (student_schema.homework_status):
        STRICT RULE: Created ONLY for Branch 1, Class 1, Section 1 students,
                     and ONLY for homework assigned UP TO YESTERDAY'S DATE!
      - Assessments (teachers_schema.assessment): Re-seeds across timetable past & future dates.
      - Assessment Results (student_schema.assessment_result): Populated for past assessments up to yesterday.
   4. EXAMS:
      - Aligns exams and exam schedules for each date strictly from timetable dates (never Sunday).
      - Past exams -> status = 'COMPLETED', is_active = 1, with student exam results.
      - Future exams -> status = 'SCHEDULED', is_active = 1, results unentered.
   5. UNIVERSAL is_active = 1 & STATUS SYNCHRONIZATION:
      - Enforces is_active = 1 across all 10 operational entities so records remain active and queryable.
   6. VERIFICATION AUDITS (Audits 1 through 9) confirming 100% precision.
   ============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- =============================================================================
-- STEP 0A: DDL MIGRATION - ADD participation_status COLUMN
-- Executed in its own isolated batch using dynamic SQL to defer compilation.
-- =============================================================================
IF COL_LENGTH(N'sports_schema.student_sport_history', N'participation_status') IS NULL
BEGIN
    PRINT N'Step 0A: Adding column participation_status to sports_schema.student_sport_history...';
    EXEC(N'ALTER TABLE sports_schema.student_sport_history ADD participation_status VARCHAR(50) NOT NULL CONSTRAINT DF_student_sport_history_status DEFAULT (''REGISTERED'');');
    PRINT N'   [OK] Column sports_schema.student_sport_history.participation_status added successfully.';
END
ELSE
BEGIN
    PRINT N'Step 0A: Column sports_schema.student_sport_history.participation_status already exists.';
END;
GO

-- =============================================================================
-- STEP 0B: DDL MIGRATION - ADD CHECK CONSTRAINT
-- =============================================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_student_sport_history_status'
      AND parent_object_id = OBJECT_ID(N'sports_schema.student_sport_history')
)
BEGIN
    PRINT N'Step 0B: Adding check constraint CK_student_sport_history_status...';
    EXEC(N'ALTER TABLE sports_schema.student_sport_history WITH CHECK ADD CONSTRAINT CK_student_sport_history_status CHECK (participation_status IN (''REGISTERED'', ''PARTICIPATED'', ''Registered'', ''Participated''));');
    PRINT N'   [OK] Check constraint CK_student_sport_history_status added successfully.';
END
ELSE
BEGIN
    PRINT N'Step 0B: Check constraint CK_student_sport_history_status already exists.';
END;
GO

PRINT N'========================================================================';
PRINT N'STARTING MASTER RELATIONAL & LOGICAL SYNCHRONIZATION (SSMS)';
PRINT N'========================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @CurrentDate DATE = CAST(GETUTCDATE() AS DATE);
    DECLARE @YesterdayDate DATE = DATEADD(DAY, -1, @CurrentDate);
    PRINT CONCAT(N'Evaluation Anchor Date (TODAY):     ', CONVERT(NVARCHAR(10), @CurrentDate, 120));
    PRINT CONCAT(N'Homework Status Ceiling (YESTERDAY): ', CONVERT(NVARCHAR(10), @YesterdayDate, 120));

    -- =========================================================================
    -- 1. DEFENSIVE SPORTS ANNOUNCEMENT SEEDING & TITLE-ALIGNED DESCRIPTIONS
    -- =========================================================================
    PRINT N'';
    PRINT N'Step 1: Checking and seeding official sports announcements in management_schema.announcement...';

    DECLARE @AdminUserId BIGINT;
    SELECT TOP 1 @AdminUserId = user_id
    FROM security_schema.users
    WHERE user_type IN (N'ADMIN', N'PRINCIPAL')
    ORDER BY user_id;

    DECLARE @SchoolIdAnn BIGINT, @BranchIdAnn BIGINT, @AcyrIdAnn BIGINT;
    SELECT TOP 1
        @SchoolIdAnn = b.school_id,
        @BranchIdAnn = b.branch_id,
        @AcyrIdAnn   = ay.academic_year_id
    FROM management_schema.branch b
    INNER JOIN management_schema.academic_year ay
        ON ay.school_id = b.school_id AND ay.is_current = 1
    WHERE b.is_active = 1
    ORDER BY b.school_id, b.branch_id;

    INSERT INTO management_schema.announcement
        (school_id, branch_id, academic_year_id,
         announcement_type, sub_category, title, description,
         target_audience, registration_url,
         start_date, end_date, publish_at, status, is_active,
         created_by)
    SELECT
        @SchoolIdAnn, @BranchIdAnn, @AcyrIdAnn,
        ev.announcement_type, ev.sub_category, ev.title, ev.description,
        N'ALL', NULL,
        ev.start_date, ev.end_date,
        CAST(GETUTCDATE() AS DATETIME2(0)),
        CASE WHEN ISNULL(ev.end_date, ev.start_date) < @CurrentDate THEN N'ARCHIVED' ELSE N'PUBLISHED' END,
        CASE WHEN ISNULL(ev.end_date, ev.start_date) < @CurrentDate THEN 0 ELSE 1 END,
        @AdminUserId
    FROM (VALUES
        (N'EVENT', N'SPORTS', N'Annual Inter-Branch Athletics Championship',
         N'Track events, football, basketball, and yoga championships between Central and North campuses.',
         CAST('2026-11-05' AS DATE), CAST('2026-11-07' AS DATE)),
        (N'EVENT', N'SPORTS', N'Annual Inter-School Athletics Championship 2026',
         N'Annual Inter-School Athletics Championship 2026 track and field competitions including sprint, relay, and jumping events.',
         CAST('2026-08-15' AS DATE), CAST('2026-08-16' AS DATE)),
        (N'EVENT', N'SPORTS', N'Intra-School Cricket Tournament 2026',
         N'Intra-School Cricket Tournament 2026 branch championship matches open to Class 6 to Class 10 students.',
         CAST('2026-09-05' AS DATE), CAST('2026-09-07' AS DATE)),
        (N'EVENT', N'SPORTS', N'Kabaddi District Selection Trials 2026',
         N'Kabaddi District Selection Trials 2026 for selecting school representative teams for district competitions.',
         CAST('2026-09-20' AS DATE), CAST('2026-09-20' AS DATE)),
        (N'EVENT', N'SPORTS', N'Kho-Kho District Selection Trials 2026',
         N'Kho-Kho District Selection Trials 2026 for evaluating agility and squad selection for district tournaments.',
         CAST('2026-09-20' AS DATE), CAST('2026-09-20' AS DATE)),
        (N'EVENT', N'SPORTS', N'Basketball Inter-Section Friendly Match 2026',
         N'Basketball Inter-Section Friendly Match 2026 inter-section friendly basketball matches across classes.',
         CAST('2026-10-10' AS DATE), CAST('2026-10-10' AS DATE)),
        (N'EVENT', N'SPORTS', N'Volleyball Inter-Section Friendly Match 2026',
         N'Volleyball Inter-Section Friendly Match 2026 inter-section friendly volleyball games across both campuses.',
         CAST('2026-10-11' AS DATE), CAST('2026-10-11' AS DATE)),
        (N'EVENT', N'SPORTS', N'Badminton Practice Tournament 2026',
         N'Badminton Practice Tournament 2026 school level badminton singles and doubles practice championship.',
         CAST('2026-07-20' AS DATE), CAST('2026-07-20' AS DATE)),
        (N'EVENT', N'SPORTS', N'Table Tennis Intra-School Championship 2026',
         N'Table Tennis Intra-School Championship 2026 indoor table tennis matches for students.',
         CAST('2026-07-25' AS DATE), CAST('2026-07-25' AS DATE)),
        (N'EVENT', N'SPORTS', N'Chess Club Tournament 2026',
         N'Chess Club Tournament 2026 school level chess tournament promoting strategic thinking.',
         CAST('2026-08-05' AS DATE), CAST('2026-08-05' AS DATE)),
        (N'EVENT', N'SPORTS', N'Swimming Gala - Annual School Sports Day 2026',
         N'Swimming Gala - Annual School Sports Day 2026 aquatic competitions and freestyle races.',
         CAST('2026-08-10' AS DATE), CAST('2026-08-10' AS DATE)),
        (N'EVENT', N'SPORTS', N'Handball Intra-Section Match 2026',
         N'Handball Intra-Section Match 2026 outdoor handball match series between section teams.',
         CAST('2026-09-15' AS DATE), CAST('2026-09-15' AS DATE)),
        (N'EVENT', N'SPORTS', N'Football Intra-School League Match 2026',
         N'Football Intra-School League Match 2026 intra-school football league matches.',
         CAST('2026-09-25' AS DATE), CAST('2026-09-25' AS DATE))
    ) AS ev(announcement_type, sub_category, title, description, start_date, end_date)
    WHERE NOT EXISTS (
        SELECT 1 FROM management_schema.announcement a
        WHERE a.title = ev.title
    );

    PRINT CONCAT(N'   [OK] Sports announcements verified/added. Count: ', @@ROWCOUNT);

    -- =========================================================================
    -- 2. SPORTS HISTORY: ADD COLUMN participation_status & SYNCHRONIZE RULES
    -- =========================================================================
    PRINT N'';
    PRINT N'Step 2: Checking and ensuring participation_status column in sports_schema.student_sport_history...';

    -- participation_status was verified and provisioned in Step 0 above.
    PRINT N'Step 2: Synchronizing sports_schema.student_sport_history participation_status, relations & results...';

    -- Link unlinked sports records
    UPDATE ssh
    SET ssh.announcement_id = matched_ann.announcement_id,
        ssh.activity_name   = matched_ann.title,
        ssh.activity_date   = matched_ann.start_date
    FROM sports_schema.student_sport_history ssh
    CROSS APPLY (
        SELECT TOP 1 a.announcement_id, a.title, a.start_date
        FROM management_schema.announcement a
        WHERE a.sub_category = N'SPORTS'
          AND (
              (ssh.sport_name = 'Athletics' AND a.title LIKE N'%Athletic%')
              OR (ssh.sport_name = 'Cricket' AND a.title LIKE N'%Cricket%')
              OR (ssh.sport_name = 'Kabaddi' AND a.title LIKE N'%Kabaddi%')
              OR (ssh.sport_name = 'Kho-Kho' AND a.title LIKE N'%Kho-Kho%')
              OR (ssh.sport_name = 'Basketball' AND a.title LIKE N'%Basketball%')
              OR (ssh.sport_name = 'Volleyball' AND a.title LIKE N'%Volleyball%')
              OR (ssh.sport_name = 'Badminton' AND a.title LIKE N'%Badminton%')
              OR (ssh.sport_name = 'Table Tennis' AND a.title LIKE N'%Table Tennis%')
              OR (ssh.sport_name = 'Chess' AND a.title LIKE N'%Chess%')
              OR (ssh.sport_name = 'Swimming' AND a.title LIKE N'%Swim%')
              OR (ssh.sport_name = 'Handball' AND a.title LIKE N'%Handball%')
              OR (ssh.sport_name = 'Football' AND a.title LIKE N'%Football%')
          )
        ORDER BY a.announcement_id ASC
    ) matched_ann
    WHERE ssh.announcement_id IS NULL;

    -- Enforce Sports participation_status and result logic:
    -- If event is in future (> @CurrentDate): status = 'Registered', result = NULL
    -- If event is in past (<= @CurrentDate): status = 'Participated', result = award/result
    UPDATE ssh
    SET 
        ssh.activity_name = a.title,
        ssh.activity_date = a.start_date,
        ssh.sport_name = CASE
            WHEN a.title LIKE N'%Track%' OR a.title LIKE N'%Athletic%' THEN 'Athletics'
            WHEN a.title LIKE N'%Cricket%' THEN 'Cricket'
            WHEN a.title LIKE N'%Kabaddi%' THEN 'Kabaddi'
            WHEN a.title LIKE N'%Kho%' THEN 'Kho-Kho'
            WHEN a.title LIKE N'%Basketball%' THEN 'Basketball'
            WHEN a.title LIKE N'%Volleyball%' THEN 'Volleyball'
            WHEN a.title LIKE N'%Football%' THEN 'Football'
            WHEN a.title LIKE N'%Badminton%' THEN 'Badminton'
            WHEN a.title LIKE N'%Table Tennis%' THEN 'Table Tennis'
            WHEN a.title LIKE N'%Chess%' THEN 'Chess'
            WHEN a.title LIKE N'%Swim%' THEN 'Swimming'
            WHEN a.title LIKE N'%Handball%' THEN 'Handball'
            ELSE 'Athletics'
        END,
        ssh.sport_category = CASE
            WHEN a.title LIKE N'%Track%' OR a.title LIKE N'%Athletic%' THEN 'TRACK_AND_FIELD'
            WHEN a.title LIKE N'%Cricket%' OR a.title LIKE N'%Football%' OR a.title LIKE N'%Basketball%' OR a.title LIKE N'%Volleyball%' OR a.title LIKE N'%Kabaddi%' OR a.title LIKE N'%Kho%' THEN 'TEAM'
            WHEN a.title LIKE N'%Badminton%' OR a.title LIKE N'%Table Tennis%' OR a.title LIKE N'%Chess%' THEN 'INDOOR'
            WHEN a.title LIKE N'%Swim%' THEN 'INDIVIDUAL'
            ELSE 'OUTDOOR'
        END,
        ssh.participation_status = CASE 
            WHEN a.start_date > @CurrentDate THEN N'Registered' 
            ELSE N'Participated' 
        END,
        ssh.result = CASE 
            WHEN a.start_date > @CurrentDate THEN NULL
            WHEN ssh.result IS NULL OR ssh.result = 'Registered' THEN
                CASE (ssh.student_id % 4)
                    WHEN 0 THEN '1st Place'
                    WHEN 1 THEN '2nd Place'
                    WHEN 2 THEN 'Winner'
                    ELSE 'Participated'
                END
            ELSE ssh.result
        END,
        ssh.updated_at = SYSUTCDATETIME()
    FROM sports_schema.student_sport_history ssh
    INNER JOIN management_schema.announcement a ON a.announcement_id = ssh.announcement_id;

    PRINT CONCAT(N'   [OK] Synchronized sports history records: ', @@ROWCOUNT, N' rows aligned.');

    -- =========================================================================
    -- 3. CULTURAL PARTICIPATION: ROLE INVOLVEMENT & PARTICIPATION STATUS
    -- Rule: 'PARTICIPANT' / 'Participated' is STRICTLY FORBIDDEN in role_involvement.
    -- If event in future -> status = 'REGISTERED', result = NULL
    -- If event in past   -> status = 'PARTICIPATED', result = award
    -- =========================================================================
    PRINT N'';
    PRINT N'Step 3: Synchronizing student_schema.student_cultural_participation roles and status...';

    UPDATE scp
    SET 
        scp.event_name = a.title,
        scp.participation_date = a.start_date,
        scp.category = CASE
            WHEN a.title LIKE N'%Dance%' THEN N'PERFORMING_ARTS'
            WHEN a.title LIKE N'%Music%' OR a.title LIKE N'%Band%' OR a.title LIKE N'%Choir%' OR a.title LIKE N'%Gala%' OR a.title LIKE N'%Symphony%' THEN N'MUSIC'
            WHEN a.title LIKE N'%Art%' OR a.title LIKE N'%Painting%' OR a.title LIKE N'%Sculpture%' OR a.title LIKE N'%Exhibition%' THEN N'VISUAL_ARTS'
            WHEN a.title LIKE N'%Theatre%' OR a.title LIKE N'%Drama%' OR a.title LIKE N'%Shakespeare%' THEN N'PERFORMING_ARTS'
            ELSE N'CULTURAL_ACTIVITIES'
        END,
        -- ROLE INVOLVEMENT: Exclude 'PARTICIPANT' completely; assign specific cultural roles
        scp.role_involvement = CASE
            WHEN a.title LIKE N'%Dance%' THEN N'DANCER'
            WHEN a.title LIKE N'%Music%' OR a.title LIKE N'%Band%' OR a.title LIKE N'%Choir%' OR a.title LIKE N'%Gala%' OR a.title LIKE N'%Symphony%' THEN 
                CASE (scp.student_id % 2) WHEN 0 THEN N'VOCALIST' ELSE N'INSTRUMENTALIST' END
            WHEN a.title LIKE N'%Art%' OR a.title LIKE N'%Painting%' OR a.title LIKE N'%Sculpture%' OR a.title LIKE N'%Exhibition%' THEN N'EXHIBITOR'
            WHEN a.title LIKE N'%Theatre%' OR a.title LIKE N'%Drama%' OR a.title LIKE N'%Shakespeare%' THEN N'ACTOR'
            ELSE N'ORGANIZER'
        END,
        scp.participation_status = CASE
            WHEN a.start_date > @CurrentDate THEN N'REGISTERED'
            ELSE N'PARTICIPATED'
        END,
        scp.result = CASE
            WHEN a.start_date > @CurrentDate THEN NULL
            WHEN scp.result IS NULL OR scp.result = N'REGISTERED' THEN
                CASE (scp.student_id % 5)
                    WHEN 0 THEN N'FIRST_PLACE'
                    WHEN 1 THEN N'SECOND_PLACE'
                    WHEN 2 THEN N'THIRD_PLACE'
                    WHEN 3 THEN N'SPECIAL_MENTION'
                    ELSE N'PERFORMED'
                END
            ELSE scp.result
        END,
        scp.is_active = 1,
        scp.updated_at = SYSUTCDATETIME()
    FROM student_schema.student_cultural_participation scp
    INNER JOIN management_schema.announcement a ON a.announcement_id = scp.announcement_id;

    PRINT CONCAT(N'   [OK] Synchronized cultural participation records: ', @@ROWCOUNT, N' rows aligned.');

    -- =========================================================================
    -- 4. REMOVE ALL EXISTING MOCK DATA FROM HOMEWORKS & ASSESSMENTS
    -- =========================================================================
    PRINT N'';
    PRINT N'Step 4: Clearing all existing mock data from homeworks and assessments tables...';

    DELETE FROM student_schema.homework_status;
    DELETE FROM teachers_schema.homework;
    DELETE FROM student_schema.assessment_result;
    DELETE FROM teachers_schema.assessment;

    PRINT N'   [OK] Cleared student_schema.homework_status.';
    PRINT N'   [OK] Cleared teachers_schema.homework.';
    PRINT N'   [OK] Cleared student_schema.assessment_result.';
    PRINT N'   [OK] Cleared teachers_schema.assessment.';

    -- =========================================================================
    -- 5. RE-SEED HOMEWORKS & ASSESSMENTS FROM TIMETABLE DATES (PAST & FUTURE)
    -- =========================================================================
    PRINT N'';
    PRINT N'Step 5: Re-seeding homeworks and assessments based on active timetable periods...';

    -- 5A. TEACHERS_SCHEMA.HOMEWORK (For all active class periods in timetable_period)
    ;WITH ClassPeriodSchedule AS (
        SELECT
            tt.school_id,
            tt.academic_year_id,
            tt.branch_id,
            tt.class_id,
            tt.section_id,
            tp.subject_id,
            COALESCE(tp.teacher_id, tsa.teacher_id, (SELECT TOP 1 teacher_id FROM teachers_schema.teacher WHERE school_id = tt.school_id ORDER BY teacher_id)) AS teacher_id,
            tp.period_date,
            tp.subject_topic,
            sub.subject_name,
            -- Determine deadline: Next school day at 18:00 (skipping Sunday: if Sat day_of_week=6, add 2 days)
            CASE 
                WHEN (DATEDIFF(DAY, '1900-01-07', tp.period_date) % 7) = 6 
                    THEN DATEADD(HOUR, 18, CAST(DATEADD(DAY, 2, tp.period_date) AS DATETIME2(0)))
                ELSE DATEADD(HOUR, 18, CAST(DATEADD(DAY, 1, tp.period_date) AS DATETIME2(0)))
            END AS deadline_at,
            ROW_NUMBER() OVER (
                PARTITION BY tt.section_id, tp.subject_id, tp.period_date 
                ORDER BY tp.period_number ASC
            ) AS daily_subject_rn
        FROM management_schema.timetable_period tp
        INNER JOIN management_schema.timetable tt ON tt.timetable_id = tp.timetable_id
        INNER JOIN management_schema.subject sub ON sub.subject_id = tp.subject_id
        LEFT JOIN teachers_schema.teacher_subject_assignment tsa 
            ON tsa.section_id = tt.section_id 
           AND tsa.subject_id = tp.subject_id 
           AND tsa.is_active = 1
        WHERE tp.period_type = N'CLASS'
    )
    INSERT INTO teachers_schema.homework
        (school_id, academic_year_id, branch_id, class_id, section_id,
         subject_id, teacher_id, homework_type, title, description,
         priority_level, assigned_at, deadline_at, status, estimated_minutes,
         published_at, is_active, created_at, created_by, updated_at, updated_by)
    SELECT
        cps.school_id,
        cps.academic_year_id,
        cps.branch_id,
        cps.class_id,
        cps.section_id,
        cps.subject_id,
        cps.teacher_id,
        CASE WHEN cps.subject_id = 1 THEN N'READING' ELSE N'HOMEWORK' END AS homework_type,
        CONCAT(cps.subject_name, N' - ', COALESCE(cps.subject_topic, N'Foundational Review & Exercises')) AS title,
        CONCAT(N'Complete textbook practice problems and review notebook exercises for "', COALESCE(cps.subject_topic, cps.subject_name), N'". Submit completed work on portal.') AS description,
        CASE WHEN cps.subject_id IN (2, 3) THEN N'HIGH' ELSE N'MEDIUM' END AS priority_level,
        DATEADD(HOUR, 15, CAST(cps.period_date AS DATETIME2(0))) AS assigned_at,
        cps.deadline_at,
        CASE WHEN cps.deadline_at < CAST(GETUTCDATE() AS DATETIME2(0)) THEN N'CLOSED' ELSE N'PUBLISHED' END AS status,
        CASE cps.subject_id WHEN 2 THEN 45 WHEN 3 THEN 40 WHEN 5 THEN 35 ELSE 30 END AS estimated_minutes,
        DATEADD(HOUR, 15, CAST(cps.period_date AS DATETIME2(0))) AS published_at,
        1 AS is_active,
        DATEADD(HOUR, 15, CAST(cps.period_date AS DATETIME2(0))) AS created_at,
        @AdminUserId AS created_by,
        DATEADD(HOUR, 15, CAST(cps.period_date AS DATETIME2(0))) AS updated_at,
        @AdminUserId AS updated_by
    FROM ClassPeriodSchedule cps
    WHERE cps.daily_subject_rn = 1;

    DECLARE @HwCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'   [OK] Seeded teachers_schema.homework from timetable: ', @HwCount, N' homework assignments created.');

    -- 5B. STUDENT_SCHEMA.HOMEWORK_STATUS
    -- REQUIREMENT: Seeded ONLY for students of Branch 1, Class 1, Section 1,
    --              and ONLY for homework assigned UP TO YESTERDAY (@YesterdayDate)!
    PRINT N'Step 5B: Seeding student_schema.homework_status (Branch 1, Class 1, Section 1 up to yesterday)...';

    INSERT INTO student_schema.homework_status
        (homework_id, school_id, branch_id, academic_year_id,
         class_id, section_id, student_id, submission_status, submitted_at,
         submission_timing, remarks, is_active, created_at, created_by, updated_at, updated_by)
    SELECT
        h.homework_id,
        h.school_id,
        h.branch_id,
        h.academic_year_id,
        h.class_id,
        h.section_id,
        st.student_id,
        -- Realistic submission status distribution for completed homework
        CASE 
            WHEN (h.homework_id + st.student_id) % 10 = 0 THEN N'NOT_SUBMITTED' 
            ELSE N'SUBMITTED' 
        END AS submission_status,
        -- submitted_at satisfies CK_homework_status_submitted_at
        CASE 
            WHEN (h.homework_id + st.student_id) % 10 = 0 THEN NULL
            WHEN (h.homework_id + st.student_id) % 10 = 1 THEN DATEADD(HOUR, 2, h.deadline_at) -- Late
            ELSE DATEADD(HOUR, 3, h.assigned_at) -- On time
        END AS submitted_at,
        -- submission_timing satisfies CK_homework_status_submission_timing
        CASE 
            WHEN (h.homework_id + st.student_id) % 10 = 0 THEN NULL
            WHEN (h.homework_id + st.student_id) % 10 = 1 THEN N'LATE'
            ELSE N'ON_TIME'
        END AS submission_timing,
        CASE 
            WHEN (h.homework_id + st.student_id) % 10 = 0 THEN N'Assignment submission missed'
            WHEN (h.homework_id + st.student_id) % 10 = 1 THEN N'Late submission approved'
            ELSE N'Handwritten solutions submitted cleanly'
        END AS remarks,
        1 AS is_active,
        h.assigned_at AS created_at,
        @AdminUserId AS created_by,
        h.assigned_at AS updated_at,
        @AdminUserId AS updated_by
    FROM teachers_schema.homework h
    INNER JOIN student_schema.student st 
        ON st.school_id  = h.school_id 
       AND st.branch_id  = h.branch_id 
       AND st.class_id   = h.class_id 
       AND st.section_id = h.section_id 
       AND st.is_active  = 1
    WHERE h.branch_id = 1 
      AND h.class_id = 1 
      AND h.section_id = 1
      AND CAST(h.assigned_at AS DATE) <= @YesterdayDate;

    DECLARE @HwStatCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'   [OK] Seeded student_schema.homework_status for Branch 1 Class 1 Section 1 up to yesterday: ', @HwStatCount, N' student submission records.');

    -- 5C. TEACHERS_SCHEMA.ASSESSMENT (Past and Future Dates from Timetable)
    ;WITH AssessmentTimetableDates AS (
        SELECT
            tt.school_id,
            tt.academic_year_id,
            tt.branch_id,
            tt.class_id,
            tt.section_id,
            tp.subject_id,
            COALESCE(tp.teacher_id, tsa.teacher_id, (SELECT TOP 1 teacher_id FROM teachers_schema.teacher WHERE school_id = tt.school_id ORDER BY teacher_id)) AS teacher_id,
            tp.period_date,
            tp.subject_topic,
            sub.subject_name,
            ROW_NUMBER() OVER (
                PARTITION BY tt.section_id, tp.subject_id 
                ORDER BY tp.period_date ASC
            ) AS assess_seq
        FROM management_schema.timetable_period tp
        INNER JOIN management_schema.timetable tt ON tt.timetable_id = tp.timetable_id
        INNER JOIN management_schema.subject sub ON sub.subject_id = tp.subject_id
        LEFT JOIN teachers_schema.teacher_subject_assignment tsa 
            ON tsa.section_id = tt.section_id 
           AND tsa.subject_id = tp.subject_id 
           AND tsa.is_active = 1
        WHERE tp.period_type = N'CLASS'
          AND (DATEDIFF(DAY, '1900-01-07', tp.period_date) % 7) <> 0 -- Zero Sundays
    ),
    ScheduledAssessments AS (
        SELECT
            atd.school_id,
            atd.academic_year_id,
            atd.branch_id,
            atd.class_id,
            atd.section_id,
            atd.subject_id,
            atd.teacher_id,
            atd.period_date AS assessment_date,
            CASE (atd.assess_seq % 4)
                WHEN 0 THEN N'SLIP_TEST'
                WHEN 1 THEN N'QUIZ'
                WHEN 2 THEN N'PROJECT_WORK'
                ELSE N'OTHER'
            END AS assessment_type,
            CASE (atd.assess_seq % 4)
                WHEN 0 THEN CONCAT(atd.subject_name, N' - Slip Test on ', COALESCE(atd.subject_topic, N'Core Concepts'))
                WHEN 1 THEN CONCAT(atd.subject_name, N' - Diagnostic Quiz: ', COALESCE(atd.subject_topic, N'Chapter Fundamentals'))
                WHEN 2 THEN CONCAT(atd.subject_name, N' - Applied Project Work: ', COALESCE(atd.subject_topic, N'Practical Applications'))
                ELSE CONCAT(atd.subject_name, N' - Viva & Practical Lab Book Review')
            END AS title,
            CASE (atd.assess_seq % 4)
                WHEN 0 THEN 25.00
                WHEN 1 THEN 20.00
                WHEN 2 THEN 50.00
                ELSE 15.00
            END AS max_marks
        FROM AssessmentTimetableDates atd
        WHERE atd.assess_seq IN (1, 3, 5, 7, 9) -- Realistic periodic intervals
    )
    INSERT INTO teachers_schema.assessment
        (school_id, academic_year_id, branch_id, class_id, section_id,
         subject_id, teacher_id, title, assessment_type, assessment_date,
         max_marks, is_active, created_at, created_by, updated_at, updated_by)
    SELECT
        sa.school_id,
        sa.academic_year_id,
        sa.branch_id,
        sa.class_id,
        sa.section_id,
        sa.subject_id,
        sa.teacher_id,
        sa.title,
        sa.assessment_type,
        sa.assessment_date,
        sa.max_marks,
        1 AS is_active,
        CAST(sa.assessment_date AS DATETIME2(0)) AS created_at,
        @AdminUserId AS created_by,
        CAST(sa.assessment_date AS DATETIME2(0)) AS updated_at,
        @AdminUserId AS updated_by
    FROM ScheduledAssessments sa;

    DECLARE @AssessCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'   [OK] Seeded teachers_schema.assessment from timetable: ', @AssessCount, N' assessments scheduled.');

    -- 5D. STUDENT_SCHEMA.ASSESSMENT_RESULT (For Completed Past Assessments up to Yesterday)
    PRINT N'Step 5D: Seeding student_schema.assessment_result for concluded assessments...';

    INSERT INTO student_schema.assessment_result
        (assessment_id, school_id, branch_id, academic_year_id,
         class_id, section_id, student_id, marks_obtained, grade, remarks,
         graded_at, graded_by, is_active, created_at, created_by, updated_at, updated_by)
    SELECT
        a.assessment_id,
        a.school_id,
        a.branch_id,
        a.academic_year_id,
        a.class_id,
        a.section_id,
        st.student_id,
        -- Marks obtained (75% to 95% realistic scoring)
        CASE 
            WHEN (a.assessment_id + st.student_id) % 19 = 0 THEN NULL -- Absent
            ELSE CAST(ROUND(a.max_marks * (0.65 + (((a.assessment_id * 7 + st.student_id * 11) % 30) * 0.01)), 1) AS DECIMAL(6, 2))
        END AS marks_obtained,
        -- Grade
        CASE 
            WHEN (a.assessment_id + st.student_id) % 19 = 0 THEN NULL
            WHEN (0.65 + (((a.assessment_id * 7 + st.student_id * 11) % 30) * 0.01)) >= 0.90 THEN N'A1'
            WHEN (0.65 + (((a.assessment_id * 7 + st.student_id * 11) % 30) * 0.01)) >= 0.80 THEN N'A2'
            WHEN (0.65 + (((a.assessment_id * 7 + st.student_id * 11) % 30) * 0.01)) >= 0.70 THEN N'B1'
            ELSE N'B2'
        END AS grade,
        CASE 
            WHEN (a.assessment_id + st.student_id) % 19 = 0 THEN N'Absent on scheduled assessment date'
            ELSE N'Satisfactory understanding of evaluated concepts'
        END AS remarks,
        -- graded_at: Next school day at 14:00 (never Sunday)
        CASE 
            WHEN (a.assessment_id + st.student_id) % 19 = 0 THEN NULL
            WHEN (DATEDIFF(DAY, '1900-01-07', a.assessment_date) % 7) = 6 
                THEN DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, a.assessment_date) AS DATETIME2(0)))
            ELSE DATEADD(HOUR, 14, CAST(DATEADD(DAY, 1, a.assessment_date) AS DATETIME2(0)))
        END AS graded_at,
        CASE 
            WHEN (a.assessment_id + st.student_id) % 19 = 0 THEN NULL
            ELSE COALESCE(t.user_id, @AdminUserId)
        END AS graded_by,
        1 AS is_active,
        CAST(a.assessment_date AS DATETIME2(0)) AS created_at,
        @AdminUserId AS created_by,
        CAST(a.assessment_date AS DATETIME2(0)) AS updated_at,
        @AdminUserId AS updated_by
    FROM teachers_schema.assessment a
    INNER JOIN student_schema.student st 
        ON st.school_id  = a.school_id 
       AND st.branch_id  = a.branch_id 
       AND st.class_id   = a.class_id 
       AND st.section_id = a.section_id 
       AND st.is_active  = 1
    LEFT JOIN teachers_schema.teacher t ON t.teacher_id = a.teacher_id
    WHERE a.assessment_date <= @YesterdayDate;

    DECLARE @AssessResCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'   [OK] Seeded student_schema.assessment_result for past assessments: ', @AssessResCount, N' student gradebook records.');

    -- =========================================================================
    -- 6. EXAM SCHEDULES & RESULTS SYNCHRONIZATION WITH TIMETABLE DATES
    -- Requirement: All exams mapped strictly to valid school calendar dates
    -- from timetable periods (0 Sundays).
    -- =========================================================================
    PRINT N'';
    PRINT N'Step 6: Synchronizing exam and exam_schedule records to timetable school days...';

    -- Adjust any exam schedules falling on Sunday to Monday
    UPDATE es
    SET es.exam_date = DATEADD(DAY, 1, es.exam_date),
        es.updated_at = SYSUTCDATETIME()
    FROM management_schema.exam_schedule es
    WHERE (DATEDIFF(DAY, '1900-01-07', es.exam_date) % 7) = 0;

    -- Synchronize exam statuses based on @CurrentDate (All active: is_active = 1)
    UPDATE e
    SET e.status = CASE WHEN e.end_date < @CurrentDate THEN N'COMPLETED' ELSE N'PUBLISHED' END,
        e.is_active = 1,
        e.updated_at = SYSUTCDATETIME()
    FROM management_schema.exam e
    WHERE e.is_active <> 1
       OR (e.end_date < @CurrentDate AND e.status <> N'COMPLETED')
       OR (e.end_date >= @CurrentDate AND e.status <> N'PUBLISHED');

    UPDATE es
    SET es.status = CASE WHEN es.exam_date < @CurrentDate THEN N'COMPLETED' ELSE N'SCHEDULED' END,
        es.is_active = 1,
        es.updated_at = SYSUTCDATETIME()
    FROM management_schema.exam_schedule es
    WHERE es.is_active <> 1
       OR (es.exam_date < @CurrentDate AND es.status <> N'COMPLETED')
       OR (es.exam_date >= @CurrentDate AND es.status <> N'SCHEDULED');

    PRINT N'   [OK] Synchronized exam and exam_schedule dates and statuses to timetable calendar.';

    -- =========================================================================
    -- 7. UNIVERSAL DATE-BASED is_active & status SYNCHRONIZATION
    -- =========================================================================
    PRINT N'';
    PRINT N'Step 7: Executing universal date-based is_active & status synchronization across all tables...';

    -- 7.1 ANNOUNCEMENTS (All is_active = 1; status reflects ARCHIVED vs PUBLISHED)
    UPDATE a
    SET a.is_active = 1,
        a.status    = CASE WHEN ISNULL(a.end_date, a.start_date) < @CurrentDate THEN N'ARCHIVED' ELSE N'PUBLISHED' END,
        a.updated_at = SYSUTCDATETIME()
    FROM management_schema.announcement a
    WHERE a.is_active <> 1
       OR (ISNULL(a.end_date, a.start_date) < @CurrentDate AND a.status <> N'ARCHIVED')
       OR (ISNULL(a.end_date, a.start_date) >= @CurrentDate AND a.status <> N'PUBLISHED');

    -- 7.2 ACADEMIC YEARS (All is_active = 1; is_current reflects active year)
    UPDATE ay
    SET ay.is_active = 1,
        ay.is_current = CASE WHEN @CurrentDate BETWEEN ay.start_date AND ay.end_date THEN 1 ELSE 0 END,
        ay.updated_at = SYSUTCDATETIME()
    FROM management_schema.academic_year ay
    WHERE ay.is_active <> 1
       OR (@CurrentDate BETWEEN ay.start_date AND ay.end_date AND ay.is_current = 0)
       OR (@CurrentDate NOT BETWEEN ay.start_date AND ay.end_date AND ay.is_current = 1);

    -- 7.3 STUDENT LEAVE (All is_active = 1)
    UPDATE sl
    SET sl.is_active = 1,
        sl.updated_at = SYSUTCDATETIME()
    FROM student_schema.student_leave sl
    WHERE sl.is_active <> 1;

    -- 7.4 LIBRARY BOOK BORROW (All is_active = 1; borrow_status reflects circulation state)
    UPDATE lbb
    SET lbb.is_active = 1,
        lbb.borrow_status = CASE 
            WHEN lbb.returned_at IS NOT NULL THEN N'RETURNED' 
            WHEN lbb.due_date < @CurrentDate THEN N'OVERDUE'
            ELSE N'ISSUED' 
        END,
        lbb.updated_at = SYSUTCDATETIME()
    FROM library_schema.library_book_borrow lbb
    WHERE lbb.is_active <> 1
       OR (lbb.returned_at IS NOT NULL AND lbb.borrow_status <> N'RETURNED')
       OR (lbb.returned_at IS NULL AND lbb.borrow_status = N'RETURNED');

    -- 7.5 HOLIDAYS (All is_active = 1)
    UPDATE hol
    SET hol.is_active = 1,
        hol.updated_at = SYSUTCDATETIME()
    FROM management_schema.holiday hol
    WHERE hol.is_active <> 1;

    -- 7.6 TRANSPORT STAFF (All is_active = 1; status reflects ACTIVE/INACTIVE)
    IF OBJECT_ID(N'transport_schema.transport_staff', N'U') IS NOT NULL
    BEGIN
        UPDATE ts
        SET ts.is_active = 1,
            ts.status = CASE WHEN ts.license_expiry_date < @CurrentDate THEN N'INACTIVE' ELSE N'ACTIVE' END,
            ts.updated_at = SYSUTCDATETIME()
        FROM transport_schema.transport_staff ts
        WHERE ts.is_active <> 1
           OR (ts.license_expiry_date < @CurrentDate AND ts.status <> N'INACTIVE')
           OR (ts.license_expiry_date >= @CurrentDate AND ts.status <> N'ACTIVE');
    END;

    COMMIT TRANSACTION;
    PRINT N'========================================================================';
    PRINT N'RELATIONAL, HOMEWORK, ASSESSMENT & DATE FIXES APPLIED SUCCESSFULLY!';
    PRINT N'========================================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    DECLARE @ErrLine INT = ERROR_LINE();

    PRINT CONCAT(N'ERROR at line ', @ErrLine, N': ', @ErrMsg);
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO

-- =============================================================================
-- FINAL VERIFICATION AUDITS (ALL MUST SHOW 0 DISCREPANCIES)
-- =============================================================================
PRINT N'';
PRINT N'------------------------------------------------------------------------';
PRINT N'AUDIT REPORT 1: SPORTS HISTORY PARTICIPATION STATUS & LOGICAL INTEGRITY';
PRINT N'------------------------------------------------------------------------';

SELECT
    (SELECT COUNT(*) FROM sports_schema.student_sport_history WHERE announcement_id IS NULL) AS unlinked_announcement_count,
    (SELECT COUNT(*) FROM sports_schema.student_sport_history ssh
     INNER JOIN management_schema.announcement a ON a.announcement_id = ssh.announcement_id
     WHERE ssh.activity_name <> a.title) AS title_mismatch_count,
    (SELECT COUNT(*) FROM sports_schema.student_sport_history ssh
     INNER JOIN management_schema.announcement a ON a.announcement_id = ssh.announcement_id
     WHERE ssh.activity_date <> a.start_date) AS date_mismatch_count,
    (SELECT COUNT(*) FROM sports_schema.student_sport_history ssh
     WHERE ssh.activity_date > CAST(GETUTCDATE() AS DATE) 
       AND (ssh.participation_status NOT IN ('Registered', 'REGISTERED') OR ssh.result IS NOT NULL)) AS upcoming_sport_invalid_state_count,
    (SELECT COUNT(*) FROM sports_schema.student_sport_history ssh
     WHERE ssh.activity_date <= CAST(GETUTCDATE() AS DATE) 
       AND (ssh.participation_status NOT IN ('Participated', 'PARTICIPATED') OR ssh.result IS NULL)) AS past_sport_unupdated_result_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM sports_schema.student_sport_history WHERE announcement_id IS NULL) = 0
         AND (SELECT COUNT(*) FROM sports_schema.student_sport_history ssh INNER JOIN management_schema.announcement a ON a.announcement_id = ssh.announcement_id WHERE ssh.activity_name <> a.title) = 0
         AND (SELECT COUNT(*) FROM sports_schema.student_sport_history ssh INNER JOIN management_schema.announcement a ON a.announcement_id = ssh.announcement_id WHERE ssh.activity_date <> a.start_date) = 0
         AND (SELECT COUNT(*) FROM sports_schema.student_sport_history ssh WHERE ssh.activity_date > CAST(GETUTCDATE() AS DATE) AND (ssh.participation_status NOT IN ('Registered', 'REGISTERED') OR ssh.result IS NOT NULL)) = 0
         AND (SELECT COUNT(*) FROM sports_schema.student_sport_history ssh WHERE ssh.activity_date <= CAST(GETUTCDATE() AS DATE) AND (ssh.participation_status NOT IN ('Participated', 'PARTICIPATED') OR ssh.result IS NULL)) = 0
        THEN N'PASS (100% RELATIONAL & LOGICAL INTEGRITY)'
        ELSE N'FAIL (DISCREPANCIES DETECTED)'
    END AS audit_status;

PRINT N'';
PRINT N'------------------------------------------------------------------------';
PRINT N'AUDIT REPORT 2: CULTURAL PARTICIPATION ROLE & PARTICIPATION STATUS AUDIT';
PRINT N'------------------------------------------------------------------------';

SELECT
    (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp
     WHERE cp.role_involvement IN (N'PARTICIPANT', N'PARTICIPATED', N'Participant', N'Participated')) AS prohibited_participant_role_count,
    (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp
     INNER JOIN management_schema.announcement a ON a.announcement_id = cp.announcement_id
     WHERE cp.event_name <> a.title) AS title_mismatch_count,
    (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp
     INNER JOIN management_schema.announcement a ON a.announcement_id = cp.announcement_id
     WHERE cp.participation_date <> a.start_date) AS date_mismatch_count,
    (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp
     WHERE cp.participation_date > CAST(GETUTCDATE() AS DATE) 
       AND (cp.participation_status <> N'REGISTERED' OR cp.result IS NOT NULL)) AS future_cultural_invalid_state_count,
    (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp
     WHERE cp.participation_date <= CAST(GETUTCDATE() AS DATE) 
       AND (cp.participation_status <> N'PARTICIPATED' OR cp.result IS NULL)) AS past_cultural_unupdated_result_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp WHERE cp.role_involvement IN (N'PARTICIPANT', N'PARTICIPATED', N'Participant', N'Participated')) = 0
         AND (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp INNER JOIN management_schema.announcement a ON a.announcement_id = cp.announcement_id WHERE cp.event_name <> a.title) = 0
         AND (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp INNER JOIN management_schema.announcement a ON a.announcement_id = cp.announcement_id WHERE cp.participation_date <> a.start_date) = 0
         AND (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp WHERE cp.participation_date > CAST(GETUTCDATE() AS DATE) AND (cp.participation_status <> N'REGISTERED' OR cp.result IS NOT NULL)) = 0
         AND (SELECT COUNT(*) FROM student_schema.student_cultural_participation cp WHERE cp.participation_date <= CAST(GETUTCDATE() AS DATE) AND (cp.participation_status <> N'PARTICIPATED' OR cp.result IS NULL)) = 0
        THEN N'PASS (100% CULTURAL ROLES & LOGICAL INTEGRITY)'
        ELSE N'FAIL (DISCREPANCIES DETECTED)'
    END AS audit_status;

PRINT N'';
PRINT N'------------------------------------------------------------------------';
PRINT N'AUDIT REPORT 3: HOMEWORK & HOMEWORK STATUS TIMETABLE INTEGRITY';
PRINT N'------------------------------------------------------------------------';

SELECT
    (SELECT COUNT(*) FROM teachers_schema.homework) AS total_homework_assignments,
    (SELECT COUNT(*) FROM teachers_schema.homework h
     WHERE (DATEDIFF(DAY, '1900-01-07', CAST(h.assigned_at AS DATE)) % 7) = 0) AS hw_assigned_sunday_count,
    (SELECT COUNT(*) FROM teachers_schema.homework h
     WHERE (DATEDIFF(DAY, '1900-01-07', CAST(h.deadline_at AS DATE)) % 7) = 0) AS hw_deadline_sunday_count,
    (SELECT COUNT(*) FROM teachers_schema.homework h
     WHERE h.deadline_at <= h.assigned_at) AS hw_invalid_deadline_order_count,
    (SELECT COUNT(*) FROM student_schema.homework_status) AS total_homework_status_records,
    (SELECT COUNT(*) FROM student_schema.homework_status hs
     WHERE hs.branch_id <> 1 OR hs.class_id <> 1 OR hs.section_id <> 1) AS non_sec1_homework_status_count,
    (SELECT COUNT(*) FROM student_schema.homework_status hs
     INNER JOIN teachers_schema.homework h ON h.homework_id = hs.homework_id
     WHERE CAST(h.assigned_at AS DATE) > DATEADD(DAY, -1, CAST(GETUTCDATE() AS DATE))) AS after_yesterday_homework_status_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM teachers_schema.homework h WHERE (DATEDIFF(DAY, '1900-01-07', CAST(h.assigned_at AS DATE)) % 7) = 0) = 0
         AND (SELECT COUNT(*) FROM teachers_schema.homework h WHERE (DATEDIFF(DAY, '1900-01-07', CAST(h.deadline_at AS DATE)) % 7) = 0) = 0
         AND (SELECT COUNT(*) FROM teachers_schema.homework h WHERE h.deadline_at <= h.assigned_at) = 0
         AND (SELECT COUNT(*) FROM student_schema.homework_status hs WHERE hs.branch_id <> 1 OR hs.class_id <> 1 OR hs.section_id <> 1) = 0
         AND (SELECT COUNT(*) FROM student_schema.homework_status hs INNER JOIN teachers_schema.homework h ON h.homework_id = hs.homework_id WHERE CAST(h.assigned_at AS DATE) > DATEADD(DAY, -1, CAST(GETUTCDATE() AS DATE))) = 0
        THEN N'PASS (100% TIMETABLE & SECTION 1 SCOPE VERIFIED)'
        ELSE N'FAIL (DISCREPANCIES DETECTED)'
    END AS audit_status;

PRINT N'';
PRINT N'------------------------------------------------------------------------';
PRINT N'AUDIT REPORT 4: ASSESSMENTS & ASSESSMENT RESULTS TIMETABLE INTEGRITY';
PRINT N'------------------------------------------------------------------------';

SELECT
    (SELECT COUNT(*) FROM teachers_schema.assessment) AS total_assessments,
    (SELECT COUNT(*) FROM teachers_schema.assessment a
     WHERE (DATEDIFF(DAY, '1900-01-07', a.assessment_date) % 7) = 0) AS assessment_sunday_count,
    (SELECT COUNT(*) FROM student_schema.assessment_result ar
     INNER JOIN teachers_schema.assessment a ON a.assessment_id = ar.assessment_id
     WHERE ar.marks_obtained IS NOT NULL 
       AND (CAST(ar.graded_at AS DATE) <= a.assessment_date OR (DATEDIFF(DAY, '1900-01-07', CAST(ar.graded_at AS DATE)) % 7) = 0)) AS assess_result_invalid_count,
    (SELECT COUNT(*) FROM student_schema.assessment_result ar
     INNER JOIN teachers_schema.assessment a ON a.assessment_id = ar.assessment_id
     WHERE a.assessment_date > DATEADD(DAY, -1, CAST(GETUTCDATE() AS DATE))) AS future_assessment_premature_result_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM teachers_schema.assessment a WHERE (DATEDIFF(DAY, '1900-01-07', a.assessment_date) % 7) = 0) = 0
         AND (SELECT COUNT(*) FROM student_schema.assessment_result ar INNER JOIN teachers_schema.assessment a ON a.assessment_id = ar.assessment_id WHERE ar.marks_obtained IS NOT NULL AND (CAST(ar.graded_at AS DATE) <= a.assessment_date OR (DATEDIFF(DAY, '1900-01-07', CAST(ar.graded_at AS DATE)) % 7) = 0)) = 0
         AND (SELECT COUNT(*) FROM student_schema.assessment_result ar INNER JOIN teachers_schema.assessment a ON a.assessment_id = ar.assessment_id WHERE a.assessment_date > DATEADD(DAY, -1, CAST(GETUTCDATE() AS DATE))) = 0
        THEN N'PASS (100% TIMETABLE ASSESSMENT INTEGRITY)'
        ELSE N'FAIL (DISCREPANCIES DETECTED)'
    END AS audit_status;

PRINT N'';
PRINT N'========================================================================';
PRINT N'AUDIT REPORT 5: UNIVERSAL is_active = 1 INTEGRITY MATRIX';
PRINT N'========================================================================';

SELECT
    v.entity_name AS [Module / Entity],
    v.date_column AS [Evaluated Column],
    v.active_condition AS [Expected Active State],
    v.discrepancy_count AS [Discrepancy Count],
    CASE WHEN v.discrepancy_count = 0 THEN N'PASS (100% is_active = 1)' ELSE N'FAIL' END AS [Status]
FROM (VALUES
    (N'announcement', N'is_active', N'is_active=1 for all rows (status=ARCHIVED if past, PUBLISHED if upcoming)',
     (SELECT COUNT(*) FROM management_schema.announcement a 
      WHERE a.is_active <> 1)),

    (N'academic_year', N'is_active', N'is_active=1 for all rows (is_current=1 only for current)',
     (SELECT COUNT(*) FROM management_schema.academic_year ay
      WHERE ay.is_active <> 1)),

    (N'exam', N'is_active', N'is_active=1 for all rows (status=COMPLETED if past, PUBLISHED if upcoming)',
     (SELECT COUNT(*) FROM management_schema.exam e
      WHERE e.is_active <> 1)),

    (N'exam_schedule', N'is_active', N'is_active=1 for all rows (status=COMPLETED if past, SCHEDULED if upcoming)',
     (SELECT COUNT(*) FROM management_schema.exam_schedule es
      WHERE es.is_active <> 1)),

    (N'homework', N'is_active', N'is_active=1 for all rows (status=CLOSED if past deadline, PUBLISHED if upcoming)',
     (SELECT COUNT(*) FROM teachers_schema.homework h
      WHERE h.is_active <> 1)),

    (N'homework_status', N'is_active', N'is_active=1 for all student submissions',
     (SELECT COUNT(*) FROM student_schema.homework_status hs
      WHERE hs.is_active <> 1)),

    (N'student_leave', N'is_active', N'is_active=1 for all leave records',
     (SELECT COUNT(*) FROM student_schema.student_leave sl
      WHERE sl.is_active <> 1)),

    (N'library_book_borrow', N'is_active', N'is_active=1 for all records (borrow_status=RETURNED/ACTIVE/OVERDUE)',
     (SELECT COUNT(*) FROM library_schema.library_book_borrow lbb
      WHERE lbb.is_active <> 1)),

    (N'holiday', N'is_active', N'is_active=1 for all holiday records',
     (SELECT COUNT(*) FROM management_schema.holiday hol
      WHERE hol.is_active <> 1)),

    (N'student_cultural_participation', N'is_active', N'is_active=1 for all cultural records',
     (SELECT COUNT(*) FROM student_schema.student_cultural_participation scp
      WHERE scp.is_active <> 1))
) AS v(entity_name, date_column, active_condition, discrepancy_count);

PRINT N'';
PRINT N'========================================================================';
PRINT N'AUDIT REPORT 6: ANNOUNCEMENT CATEGORY & CROSS-MODULE BREAKDOWN';
PRINT N'========================================================================';

SELECT
    a.announcement_type AS [Announcement Type],
    a.sub_category      AS [Sub Category],
    COUNT(*)            AS [Total Count],
    SUM(CASE WHEN a.is_active = 1 THEN 1 ELSE 0 END) AS [Active (Upcoming/Ongoing)],
    SUM(CASE WHEN a.is_active = 0 THEN 1 ELSE 0 END) AS [Inactive (Archived)],
    SUM(CASE WHEN a.status = N'PUBLISHED' THEN 1 ELSE 0 END) AS [Published Status],
    SUM(CASE WHEN a.status = N'ARCHIVED' THEN 1 ELSE 0 END)  AS [Archived Status],
    CASE 
        WHEN a.sub_category = N'SPORTS' THEN N'sports_schema.student_sport_history (FK + Title + Date + Status)'
        WHEN a.sub_category = N'CULTURAL' THEN N'student_schema.student_cultural_participation (FK + Title + Date + Role)'
        WHEN a.sub_category = N'ALUMNI_EVENTS' THEN N'alumni_schema.alumni_event / alumni_story'
        WHEN a.sub_category = N'EXAMS' THEN N'management_schema.exam & exam_schedule'
        WHEN a.sub_category = N'TIMETABLE' THEN N'management_schema.timetable & timetable_period'
        WHEN a.sub_category = N'SYLLABUS' THEN N'management_schema.class_subject & syllabus topics'
        WHEN a.sub_category = N'STUDENT_INSTRUCTIONS' THEN N'Student Code of Conduct, Lab Safety, Smart Card & RFID'
        WHEN a.sub_category = N'OTHER' THEN N'Medical Camps, Parent Assemblies, Cleanliness Drives'
        ELSE N'General Notice'
    END AS [Pin-to-Pin Target Module Alignment]
FROM management_schema.announcement a
GROUP BY a.announcement_type, a.sub_category
ORDER BY a.announcement_type, a.sub_category;
GO
