/*
    ================================================================================
    THINKIGEN ERP - Master Timetable Extension & Synchronization Script
    File: database/scripts/add_two_months_timetable_data.sql
    
    Requirements:
    1. Update management_schema.timetable created_at = '2026-10-13 08:00:00' (13-10-2026) 
       for school_id = 1.
    2. Add / synchronize 2 months of dates in management_schema.timetable_period table 
       starting from 2026-10-17 up to 2 months (2026-10-19 to 2026-12-19):
       - Exactly 9 instructional weeks = 54 school days (Mon through Sat, skipping Sundays).
       - All 40 timetables (Sections 1..40 across Central & North Campuses) for school_id = 1.
       - 10 periods per day per section = 21,600 period slots.
       - Strict 1-teacher-per-subject specialization maintained 100%.
       - Rich, progressive CBSE/ICSE curriculum topic sequence for every subject.
    3. Synchronize all timetable-related mock tables:
       - student_schema.student_attendance (Period 1 daily attendance for all 400 active students)
       - teachers_schema.homework (Assignments for instructional class periods)
       - student_schema.homework_status (Student submission records with realistic timings)
    4. 100% accuracy, transactional integrity, and idempotency guaranteed.
    ================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================================';
PRINT N'STARTING 2-MONTH TIMETABLE EXTENSION & SYNCHRONIZATION';
PRINT N'Target: school_id = 1 | Start Date: 2026-10-19 | End Date: 2026-12-19 (54 Days)';
PRINT N'================================================================================';
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- -------------------------------------------------------------------------
    -- 1. UPDATE MANAGEMENT_SCHEMA.TIMETABLE (created_at = 13-10-2026 for school_id = 1)
    -- -------------------------------------------------------------------------
    PRINT N'Step 1: Updating created_at on management_schema.timetable for school_id = 1...';
    
    UPDATE management_schema.timetable
    SET created_at = CAST('2026-10-13 08:00:00' AS DATETIME2(0)),
        updated_at = CAST('2026-10-13 08:00:00' AS DATETIME2(0))
    WHERE school_id = 1;

    PRINT CONCAT(N'Updated management_schema.timetable rows: ', @@ROWCOUNT);

    -- -------------------------------------------------------------------------
    -- 2. DEFINE 54 INSTRUCTIONAL DATES (Mon-Sat, skipping Sundays)
    -- -------------------------------------------------------------------------
    PRINT N'Step 2: Preparing 54 instructional calendar dates (2026-10-19 to 2026-12-19)...';

    IF OBJECT_ID(N'tempdb..#CalendarDays') IS NOT NULL DROP TABLE #CalendarDays;
    CREATE TABLE #CalendarDays (
        day_index INT PRIMARY KEY,
        period_date DATE NOT NULL,
        week_number INT NOT NULL,
        day_of_week_name NVARCHAR(20) NOT NULL
    );

    ;WITH Numbers AS (
        SELECT TOP (65) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
        FROM sys.all_objects
    ),
    RawDates AS (
        SELECT 
            DATEADD(DAY, n, CAST('2026-10-19' AS DATE)) AS period_date
        FROM Numbers
        WHERE DATEADD(DAY, n, CAST('2026-10-19' AS DATE)) <= CAST('2026-12-19' AS DATE)
    ),
    FilteredSchoolDays AS (
        SELECT 
            period_date,
            -- Determine deterministic Sunday exclusion (1900-01-07 was Sunday)
            (DATEDIFF(DAY, '1900-01-07', period_date) % 7) AS day_of_week_calc
        FROM RawDates
        WHERE (DATEDIFF(DAY, '1900-01-07', period_date) % 7) <> 0 -- Exclude Sunday
    )
    INSERT INTO #CalendarDays (day_index, period_date, week_number, day_of_week_name)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY period_date) - 1 AS day_index,
        period_date,
        ((ROW_NUMBER() OVER (ORDER BY period_date) - 1) / 6) + 1 AS week_number,
        DATENAME(WEEKDAY, period_date) AS day_of_week_name
    FROM FilteredSchoolDays;

    DECLARE @InstructionalDaysCount INT;
    SELECT @InstructionalDaysCount = COUNT(*) FROM #CalendarDays;
    PRINT CONCAT(N'Generated instructional school days count: ', @InstructionalDaysCount);

    -- -------------------------------------------------------------------------
    -- 3. DEFINE DAILY 10-PERIOD SCHEDULE TEMPLATE
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'tempdb..#PeriodSlots') IS NOT NULL DROP TABLE #PeriodSlots;
    CREATE TABLE #PeriodSlots (
        period_number INT PRIMARY KEY,
        period_name NVARCHAR(50) NOT NULL,
        start_time TIME(0) NOT NULL,
        end_time TIME(0) NOT NULL,
        period_type NVARCHAR(20) NOT NULL,
        default_subject_id BIGINT NULL
    );

    INSERT INTO #PeriodSlots (period_number, period_name, start_time, end_time, period_type, default_subject_id)
    VALUES
        (1,  N'Period 1',        '08:30', '09:15', N'CLASS', 1),
        (2,  N'Period 2',        '09:15', '10:00', N'CLASS', 2),
        (3,  N'Morning Break',   '10:00', '10:15', N'BREAK', NULL),
        (4,  N'Period 3',        '10:15', '11:00', N'CLASS', 3),
        (5,  N'Period 4',        '11:00', '11:45', N'CLASS', 4),
        (6,  N'Lunch Break',     '11:45', '12:30', N'LUNCH', NULL),
        (7,  N'Period 5',        '12:30', '13:15', N'CLASS', 5),
        (8,  N'Period 6',        '13:15', '14:00', N'CLASS', 6),
        (9,  N'Afternoon Break', '14:00', '14:15', N'BREAK', NULL),
        (10, N'Period 7',        '14:15', '15:00', N'CLASS', 1);

    -- -------------------------------------------------------------------------
    -- 4. DEFINE CURRICULUM TOPICS (Dynamic 9-Week Rotation for All Subjects)
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'tempdb..#SubjectTopics') IS NOT NULL DROP TABLE #SubjectTopics;
    CREATE TABLE #SubjectTopics (
        subject_id BIGINT NOT NULL,
        topic_index INT NOT NULL,
        topic_name NVARCHAR(200) NOT NULL,
        PRIMARY KEY (subject_id, topic_index)
    );

    -- English (Subject 1)
    INSERT INTO #SubjectTopics (subject_id, topic_index, topic_name) VALUES
    (1, 0, N'English: Reading Comprehension & Prose Analysis'),
    (1, 1, N'English: Grammar - Advanced Tenses & Passive Voice'),
    (1, 2, N'English: Descriptive Essay & Creative Composition'),
    (1, 3, N'English: Shakespearean Drama & Monologue Analysis'),
    (1, 4, N'English: Formal Letter Writing & Editorial Reports'),
    (1, 5, N'English: Romantic Poetry & Poetic Device Analysis'),
    (1, 6, N'English: Argumentative Writing & Debate Preparation'),
    (1, 7, N'English: Vocabulary Mastery, Idioms & Phrasal Verbs'),
    (1, 8, N'English: Speech Crafting & Public Elocution');

    -- Mathematics (Subject 2)
    INSERT INTO #SubjectTopics (subject_id, topic_index, topic_name) VALUES
    (2, 0, N'Mathematics: Linear Equations in Two Variables'),
    (2, 1, N'Mathematics: Polynomials & Factorization Techniques'),
    (2, 2, N'Mathematics: Coordinate Geometry & Cartesian Planes'),
    (2, 3, N'Mathematics: Euclidean Geometry - Triangles & Congruence'),
    (2, 4, N'Mathematics: Quadrilaterals & Parallelogram Theorems'),
    (2, 5, N'Mathematics: Circles - Chords, Arcs & Cyclic Quadrilaterals'),
    (2, 6, N'Mathematics: Mensuration - Surface Areas & Volumes of Solids'),
    (2, 7, N'Mathematics: Statistics - Mean, Median & Frequency Distribution'),
    (2, 8, N'Mathematics: Probability - Theoretical & Experimental Trials');

    -- Science (Subject 3)
    INSERT INTO #SubjectTopics (subject_id, topic_index, topic_name) VALUES
    (3, 0, N'Science: Cell Biology - Organelles & Membrane Transport'),
    (3, 1, N'Science: Plant & Animal Tissues - Histology & Functions'),
    (3, 2, N'Science: Chemical Reactions, Atoms & Molecular Formulae'),
    (3, 3, N'Science: Periodic Classification & Chemical Bonding Trends'),
    (3, 4, N'Science: Kinematics, Dynamics & Newton Laws of Motion'),
    (3, 5, N'Science: Universal Gravitation, Pressure & Floatation'),
    (3, 6, N'Science: Work, Mechanical Energy & Law of Conservation'),
    (3, 7, N'Science: Acoustics - Sound Wave Propagation & Echo Principles'),
    (3, 8, N'Science: Ecological Systems, Nutrient Cycles & Environment');

    -- Social Science (Subject 4)
    INSERT INTO #SubjectTopics (subject_id, topic_index, topic_name) VALUES
    (4, 0, N'Social Science: The French Revolution & Rise of Liberty'),
    (4, 1, N'Social Science: Physical Features of India - Landforms & Relief'),
    (4, 2, N'Social Science: Drainage Systems - River Basins & Water Bodies'),
    (4, 3, N'Social Science: Constitutional Design & Democratic Values'),
    (4, 4, N'Social Science: Climate, Monsoons & Atmospheric Influences'),
    (4, 5, N'Social Science: Pastoralists & Forest Communities in History'),
    (4, 6, N'Social Science: Poverty Dynamics & Socio-Economic Challenges'),
    (4, 7, N'Social Science: Parliamentary Democracy & Executive Structure'),
    (4, 8, N'Social Science: Food Security Systems & Public Distribution');

    -- Computer Science (Subject 5)
    INSERT INTO #SubjectTopics (subject_id, topic_index, topic_name) VALUES
    (5, 0, N'Computer Science: Python Syntax, Variables & Conditional Logic'),
    (5, 1, N'Computer Science: Iterative Control - While Loops & For Ranges'),
    (5, 2, N'Computer Science: Functions, Parameter Passing & Scope in Python'),
    (5, 3, N'Computer Science: Sequence Data Structures - Lists & Tuples'),
    (5, 4, N'Computer Science: Key-Value Mapping - Python Dictionaries & Sets'),
    (5, 5, N'Computer Science: File Handling - Text Files & CSV Manipulation'),
    (5, 6, N'Computer Science: Relational Database Architecture & SQL DDL'),
    (5, 7, N'Computer Science: SQL DML Queries, Aggregation & Grouping Clauses'),
    (5, 8, N'Computer Science: Cyber Ethics, Information Security & Digital Safety');

    -- Physical Education (Subject 6)
    INSERT INTO #SubjectTopics (subject_id, topic_index, topic_name) VALUES
    (6, 0, N'Physical Education: Track Athletics - Sprint Mechanics & Relays'),
    (6, 1, N'Physical Education: Football - Dribbling Skills & Team Tactics'),
    (6, 2, N'Physical Education: Cricket - Batting Form, Bowling & Fielding'),
    (6, 3, N'Physical Education: Basketball - Passing Drills & Free Throws'),
    (6, 4, N'Physical Education: Badminton - Racquet Grip, Footwork & Smashing'),
    (6, 5, N'Physical Education: Classical Yoga - Surya Namaskar & Pranayama'),
    (6, 6, N'Physical Education: Kabaddi - Raiding Strategies & Anti-Raiding'),
    (6, 7, N'Physical Education: Table Tennis - Forehand Spin & Counterplay'),
    (6, 8, N'Physical Education: Physical Fitness Testing, Core Endurance & Agility');

    -- -------------------------------------------------------------------------
    -- 5. UPSERT MANAGEMENT_SCHEMA.TIMETABLE_PERIOD (2026-10-19 to 2026-12-19)
    -- -------------------------------------------------------------------------
    PRINT N'Step 3: Populating / synchronizing management_schema.timetable_period...';

    ;WITH PeriodGridSource AS (
        SELECT
            -- Deterministic ID sequence beginning at 4801:
            -- 4800 base periods + ((cd.day_index) * 400) + ((tt.timetable_id - 1) * 10) + ps.period_number
            4800 + (cd.day_index * 400) + ((tt.timetable_id - 1) * 10) + ps.period_number AS target_period_id,
            tt.timetable_id,
            tt.school_id,
            tt.branch_id,
            tt.class_id,
            tt.section_id,
            cd.day_index,
            cd.period_date,
            cd.week_number,
            ps.period_number,
            ps.period_name,
            ps.start_time,
            ps.end_time,
            ps.period_type,
            CASE WHEN ps.period_type = N'CLASS' THEN ps.default_subject_id ELSE NULL END AS effective_subject_id,
            CASE 
                WHEN ps.period_type = N'CLASS' THEN
                    CONCAT(N'Room-', RIGHT(N'00' + CAST(tt.section_id AS NVARCHAR(2)), 2))
                ELSE NULL 
            END AS room_name,
            CASE 
                WHEN ps.period_type IN (N'BREAK', N'LUNCH') THEN ps.period_name
                ELSE NULL 
            END AS activity_name,
            -- Determine rich curriculum topic
            CASE 
                WHEN ps.period_type = N'CLASS' THEN
                    COALESCE(st.topic_name, N'Curriculum Instruction & Class Discussion')
                ELSE NULL 
            END AS subject_topic
        FROM management_schema.timetable tt
        CROSS JOIN #CalendarDays cd
        CROSS JOIN #PeriodSlots ps
        LEFT JOIN #SubjectTopics st 
            ON st.subject_id = ps.default_subject_id 
           AND st.topic_index = (cd.week_number - 1) % 9
        WHERE tt.school_id = 1
    )
    SELECT
        pgs.target_period_id,
        pgs.timetable_id,
        pgs.period_date,
        pgs.period_number,
        pgs.period_name,
        pgs.start_time,
        pgs.end_time,
        pgs.period_type,
        pgs.effective_subject_id,
        pgs.subject_topic,
        CASE WHEN pgs.period_type = N'CLASS' THEN tsa.teacher_id ELSE NULL END AS teacher_id,
        pgs.room_name,
        pgs.activity_name,
        1 AS is_active,
        1 AS created_by
    INTO #StagedPeriods
    FROM PeriodGridSource pgs
    LEFT JOIN teachers_schema.teacher_subject_assignment tsa
        ON tsa.section_id = pgs.section_id
       AND tsa.subject_id = pgs.effective_subject_id
       AND tsa.is_active = 1;

    -- Check if target period records already exist in management_schema.timetable_period
    DECLARE @ExistingPeriodCount INT;
    SELECT @ExistingPeriodCount = COUNT(*) 
    FROM management_schema.timetable_period 
    WHERE period_date BETWEEN '2026-10-19' AND '2026-12-19';

    IF @ExistingPeriodCount = 21600
    BEGIN
        PRINT N'Timetable periods already exist. Synchronizing subject, topic, teacher, and metadata attributes...';
        
        UPDATE tp
        SET tp.subject_id    = sp.effective_subject_id,
            tp.subject_topic = sp.subject_topic,
            tp.teacher_id    = sp.teacher_id,
            tp.room_name     = sp.room_name,
            tp.activity_name = sp.activity_name,
            tp.updated_at    = SYSUTCDATETIME()
        FROM management_schema.timetable_period tp
        JOIN #StagedPeriods sp 
          ON sp.timetable_id   = tp.timetable_id
         AND sp.period_date    = tp.period_date
         AND sp.period_number  = tp.period_number;

        PRINT CONCAT(N'Synchronized timetable_period rows: ', @@ROWCOUNT);
    END
    ELSE
    BEGIN
        PRINT N'Inserting 21,600 new timetable periods for the 2-month extension...';
        
        SET IDENTITY_INSERT management_schema.timetable_period ON;
        
        INSERT INTO management_schema.timetable_period
            (timetable_period_id, timetable_id, period_date, period_number, period_name,
             start_time, end_time, period_type, subject_id, subject_topic, teacher_id,
             room_name, activity_name, is_active, created_by)
        SELECT
            sp.target_period_id, sp.timetable_id, sp.period_date, sp.period_number, sp.period_name,
            sp.start_time, sp.end_time, sp.period_type, sp.effective_subject_id, sp.subject_topic,
            sp.teacher_id, sp.room_name, sp.activity_name, sp.is_active, sp.created_by
        FROM #StagedPeriods sp
        WHERE NOT EXISTS (
            SELECT 1 FROM management_schema.timetable_period existing
            WHERE existing.timetable_id = sp.timetable_id
              AND existing.period_date = sp.period_date
              AND existing.period_number = sp.period_number
        );

        PRINT CONCAT(N'Inserted into management_schema.timetable_period: ', @@ROWCOUNT);
        SET IDENTITY_INSERT management_schema.timetable_period OFF;
    END;

    -- -------------------------------------------------------------------------
    -- 6. SYNCHRONIZE STUDENT_SCHEMA.STUDENT_ATTENDANCE (Period 1 Daily Attendance)
    -- -------------------------------------------------------------------------
    PRINT N'Step 4: Synchronizing student_schema.student_attendance for the new dates...';

    DECLARE @ExistingAttendanceCount INT;
    SELECT @ExistingAttendanceCount = COUNT(*)
    FROM student_schema.student_attendance
    WHERE attendance_date BETWEEN '2026-10-19' AND '2026-12-19';

    IF @ExistingAttendanceCount < 21600
    BEGIN
        PRINT N'Generating Period 1 daily attendance records for all 400 active students across 54 days...';

        -- Target: Period 1 CLASS for each section on each instructional date
        ;WITH AttendanceTarget AS (
            SELECT
                st.student_id,
                st.school_id,
                st.branch_id,
                st.academic_year_id,
                st.class_id,
                st.section_id,
                tp.timetable_id,
                tp.timetable_period_id,
                tp.period_date,
                tp.subject_id,
                tp.teacher_id,
                tp.period_number,
                tp.start_time,
                tp.end_time,
                CASE 
                    WHEN (st.student_id + DATEDIFF(DAY, '2026-10-19', tp.period_date)) % 19 = 0 
                        THEN N'ABSENT' 
                    ELSE N'PRESENT' 
                END AS attendance_status,
                DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), tp.start_time) + 900, CAST(tp.period_date AS DATETIME2(0))) AS recorded_at
            FROM student_schema.student st
            JOIN management_schema.timetable_period tp
                ON tp.timetable_id = st.section_id
               AND tp.period_number = 1
               AND tp.period_type = N'CLASS'
               AND tp.period_date BETWEEN '2026-10-19' AND '2026-12-19'
            WHERE st.student_status = N'ACTIVE'
              AND st.school_id = 1
        )
        INSERT INTO student_schema.student_attendance
            (school_id, branch_id, academic_year_id, class_id, section_id, student_id,
             timetable_id, timetable_period_id, attendance_date, subject_id, teacher_id,
             period_number, start_time, end_time, attendance_status, recorded_at, recorded_by,
             is_active, created_by)
        SELECT
            att.school_id, att.branch_id, att.academic_year_id, att.class_id, att.section_id, att.student_id,
            att.timetable_id, att.timetable_period_id, att.period_date, att.subject_id, att.teacher_id,
            att.period_number, att.start_time, att.end_time, att.attendance_status, att.recorded_at, 1,
            1, 1
        FROM AttendanceTarget att
        WHERE NOT EXISTS (
            SELECT 1 FROM student_schema.student_attendance existing
            WHERE existing.student_id = att.student_id
              AND existing.timetable_period_id = att.timetable_period_id
              AND existing.attendance_date = att.period_date
        );

        PRINT CONCAT(N'Inserted into student_schema.student_attendance: ', @@ROWCOUNT);
    END
    ELSE
    BEGIN
        PRINT N'Student attendance records for the 2-month period are already fully populated.';
    END;

    -- -------------------------------------------------------------------------
    -- 7. SYNCHRONIZE TEACHERS_SCHEMA.HOMEWORK (Instructional Class Assignments)
    -- -------------------------------------------------------------------------
    PRINT N'Step 5: Synchronizing teachers_schema.homework for instructional periods...';

    DECLARE @ExistingHomeworkCount INT;
    SELECT @ExistingHomeworkCount = COUNT(*)
    FROM teachers_schema.homework
    WHERE assigned_at >= '2026-10-19';

    IF @ExistingHomeworkCount = 0
    BEGIN
        PRINT N'Creating curriculum-linked homework assignments for instructional class periods (Periods 1, 2, 4, 5, 7)...';

        ;WITH HomeworkSource AS (
            SELECT
                tt.school_id,
                tt.academic_year_id,
                tt.branch_id,
                tt.class_id,
                tt.section_id,
                tp.subject_id,
                tp.teacher_id,
                CASE WHEN tp.subject_id = 1 THEN N'READING' ELSE N'HOMEWORK' END AS homework_type,
                CONCAT(sub.subject_name, N' - ', tp.subject_topic, N' Assignment') AS title,
                CONCAT(N'Study the concepts covered in "', tp.subject_topic, N'". Complete textbook review exercises and notebook practice questions.') AS description,
                CASE WHEN tp.subject_id IN (2, 3) THEN N'HIGH' ELSE N'MEDIUM' END AS priority_level,
                DATEADD(HOUR, 15, CAST(tp.period_date AS DATETIME2(0))) AS assigned_at,
                -- Deadline: Next school day at 18:00 (if Saturday, deadline is Monday at 18:00)
                CASE 
                    WHEN (DATEDIFF(DAY, '1900-01-07', tp.period_date) % 7) = 6 -- Saturday
                        THEN DATEADD(HOUR, 18, CAST(DATEADD(DAY, 2, tp.period_date) AS DATETIME2(0)))
                    ELSE DATEADD(HOUR, 18, CAST(DATEADD(DAY, 1, tp.period_date) AS DATETIME2(0)))
                END AS deadline_at,
                CASE 
                    WHEN DATEADD(HOUR, 18, CAST(DATEADD(DAY, 1, tp.period_date) AS DATETIME2(0))) < SYSUTCDATETIME() 
                        THEN N'CLOSED' 
                    ELSE N'PUBLISHED' 
                END AS status,
                CASE tp.subject_id WHEN 2 THEN 45 WHEN 3 THEN 40 WHEN 5 THEN 35 ELSE 30 END AS estimated_minutes,
                DATEADD(HOUR, 15, CAST(tp.period_date AS DATETIME2(0))) AS published_at
            FROM management_schema.timetable_period tp
            JOIN management_schema.timetable tt ON tt.timetable_id = tp.timetable_id
            JOIN management_schema.subject sub ON sub.subject_id = tp.subject_id
            WHERE tp.period_type = N'CLASS'
              AND tp.period_number IN (1, 2, 4, 5, 7)
              AND tp.period_date BETWEEN '2026-10-19' AND '2026-12-19'
              AND tt.school_id = 1
        )
        INSERT INTO teachers_schema.homework
            (school_id, academic_year_id, branch_id, class_id, section_id,
             subject_id, teacher_id, homework_type, title, description, priority_level,
             assigned_at, deadline_at, status, estimated_minutes, published_at,
             is_active, created_at, created_by, updated_at, updated_by)
        SELECT
            hs.school_id, hs.academic_year_id, hs.branch_id, hs.class_id, hs.section_id,
            hs.subject_id, hs.teacher_id, hs.homework_type, hs.title, hs.description, hs.priority_level,
            hs.assigned_at, hs.deadline_at, hs.status, hs.estimated_minutes, hs.published_at,
            1, hs.assigned_at, 1, hs.assigned_at, 1
        FROM HomeworkSource hs;

        PRINT CONCAT(N'Inserted into teachers_schema.homework: ', @@ROWCOUNT);
    END
    ELSE
    BEGIN
        PRINT N'Homework assignments for the 2-month period are already populated.';
    END;

    -- -------------------------------------------------------------------------
    -- 8. SYNCHRONIZE STUDENT_SCHEMA.HOMEWORK_STATUS (Submissions for Active Students)
    -- -------------------------------------------------------------------------
    PRINT N'Step 6: Synchronizing student_schema.homework_status for new homework...';

    DECLARE @Now DATETIME2(0) = SYSUTCDATETIME();

    ;WITH MissingSubmissions AS (
        SELECT
            h.homework_id,
            h.school_id,
            h.branch_id,
            h.academic_year_id,
            h.class_id,
            h.section_id,
            st.student_id,
            CASE 
                WHEN h.deadline_at < @Now THEN
                    CASE WHEN (h.homework_id + st.student_id) % 10 = 0 THEN N'NOT_SUBMITTED' ELSE N'SUBMITTED' END
                WHEN h.assigned_at <= @Now AND h.deadline_at >= @Now THEN
                    CASE WHEN (h.homework_id + st.student_id) % 3 = 0 THEN N'SUBMITTED' ELSE N'NOT_SUBMITTED' END
                ELSE N'NOT_SUBMITTED'
            END AS submission_status,
            CASE 
                WHEN h.deadline_at < @Now THEN
                    CASE 
                        WHEN (h.homework_id + st.student_id) % 10 = 0 THEN NULL
                        WHEN (h.homework_id + st.student_id) % 10 = 1 THEN DATEADD(HOUR, 2, h.deadline_at)
                        ELSE DATEADD(HOUR, 4, h.assigned_at)
                    END
                WHEN h.assigned_at <= @Now AND h.deadline_at >= @Now THEN
                    CASE 
                        WHEN (h.homework_id + st.student_id) % 3 = 0 THEN DATEADD(MINUTE, 90, h.assigned_at)
                        ELSE NULL
                    END
                ELSE NULL
            END AS submitted_at,
            CASE 
                WHEN h.deadline_at < @Now THEN
                    CASE 
                        WHEN (h.homework_id + st.student_id) % 10 = 0 THEN NULL
                        WHEN (h.homework_id + st.student_id) % 10 = 1 THEN N'LATE'
                        ELSE N'ON_TIME'
                    END
                WHEN h.assigned_at <= @Now AND h.deadline_at >= @Now THEN
                    CASE 
                        WHEN (h.homework_id + st.student_id) % 3 = 0 THEN N'ON_TIME'
                        ELSE NULL
                    END
                ELSE NULL
            END AS submission_timing,
            CASE 
                WHEN h.deadline_at < @Now THEN
                    CASE 
                        WHEN (h.homework_id + st.student_id) % 10 = 0 THEN N'Pending student submission'
                        WHEN (h.homework_id + st.student_id) % 10 = 1 THEN N'Late submission approved by teacher'
                        ELSE N'Complete and neatly submitted'
                    END
                WHEN h.assigned_at <= @Now AND h.deadline_at >= @Now THEN
                    CASE 
                        WHEN (h.homework_id + st.student_id) % 3 = 0 THEN N'Submitted on time'
                        ELSE N'Work in progress'
                    END
                ELSE N'Scheduled assignment'
            END AS remarks,
            h.assigned_at
        FROM teachers_schema.homework h
        JOIN student_schema.student st 
            ON st.section_id = h.section_id 
           AND st.student_status = N'ACTIVE'
        WHERE h.assigned_at >= '2026-10-19'
          AND NOT EXISTS (
              SELECT 1 FROM student_schema.homework_status hs
              WHERE hs.homework_id = h.homework_id
                AND hs.student_id = st.student_id
          )
    )
    INSERT INTO student_schema.homework_status
        (homework_id, school_id, branch_id, academic_year_id, class_id, section_id,
         student_id, submission_status, submitted_at, submission_timing, remarks,
         is_active, created_at, created_by, updated_at, updated_by)
    SELECT
        ms.homework_id, ms.school_id, ms.branch_id, ms.academic_year_id, ms.class_id, ms.section_id,
        ms.student_id, ms.submission_status, ms.submitted_at, ms.submission_timing, ms.remarks,
        1, ms.assigned_at, 1, ms.assigned_at, 1
    FROM MissingSubmissions ms;

    PRINT CONCAT(N'Inserted into student_schema.homework_status: ', @@ROWCOUNT);

    -- -------------------------------------------------------------------------
    -- 9. VALIDATION AND INTEGRITY CHECKS
    -- -------------------------------------------------------------------------
    PRINT N'Step 7: Executing 100% accuracy validation checks...';

    -- Check A: Timetable created_at matches 2026-10-13 for all school_id = 1
    DECLARE @InvalidTimetableCreatedAt INT;
    SELECT @InvalidTimetableCreatedAt = COUNT(*)
    FROM management_schema.timetable
    WHERE school_id = 1 AND CAST(created_at AS DATE) <> '2026-10-13';

    IF @InvalidTimetableCreatedAt > 0
        THROW 52001, N'Validation failed: Not all timetables have created_at set to 13-10-2026.', 1;

    -- Check B: 1-Teacher-Per-Subject Specialization across all newly populated timetable periods
    DECLARE @TeacherViolations INT;
    SELECT @TeacherViolations = COUNT(*)
    FROM (
        SELECT tp.teacher_id, COUNT(DISTINCT tp.subject_id) AS distinct_subs
        FROM management_schema.timetable_period tp
        WHERE tp.period_type = N'CLASS'
          AND tp.period_date BETWEEN '2026-10-19' AND '2026-12-19'
          AND tp.teacher_id IS NOT NULL
        GROUP BY tp.teacher_id
        HAVING COUNT(DISTINCT tp.subject_id) > 1
    ) v;

    IF @TeacherViolations > 0
        THROW 52002, N'Validation failed: One or more teachers are assigned to multiple subjects in timetable_period.', 1;

    -- Check C: Sunday Exclusion Check
    DECLARE @SundayPeriodsCount INT;
    SELECT @SundayPeriodsCount = COUNT(*)
    FROM management_schema.timetable_period
    WHERE period_date BETWEEN '2026-10-19' AND '2026-12-19'
      AND (DATEDIFF(DAY, '1900-01-07', period_date) % 7) = 0;

    IF @SundayPeriodsCount > 0
        THROW 52003, N'Validation failed: Sunday periods were detected in timetable_period.', 1;

    -- Clean up temporary tables
    IF OBJECT_ID(N'tempdb..#CalendarDays') IS NOT NULL DROP TABLE #CalendarDays;
    IF OBJECT_ID(N'tempdb..#PeriodSlots') IS NOT NULL DROP TABLE #PeriodSlots;
    IF OBJECT_ID(N'tempdb..#SubjectTopics') IS NOT NULL DROP TABLE #SubjectTopics;
    IF OBJECT_ID(N'tempdb..#StagedPeriods') IS NOT NULL DROP TABLE #StagedPeriods;

    COMMIT TRANSACTION;
    PRINT N'================================================================================';
    PRINT N'SUCCESS: 2-MONTH TIMETABLE EXTENSION AND ALL RELATED MOCK DATA SYNCHRONIZED!';
    PRINT N'================================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'tempdb..#CalendarDays') IS NOT NULL DROP TABLE #CalendarDays;
    IF OBJECT_ID(N'tempdb..#PeriodSlots') IS NOT NULL DROP TABLE #PeriodSlots;
    IF OBJECT_ID(N'tempdb..#SubjectTopics') IS NOT NULL DROP TABLE #SubjectTopics;
    IF OBJECT_ID(N'tempdb..#StagedPeriods') IS NOT NULL DROP TABLE #StagedPeriods;
    IF OBJECT_ID(N'management_schema.timetable_period') IS NOT NULL
        BEGIN TRY SET IDENTITY_INSERT management_schema.timetable_period OFF; END TRY BEGIN CATCH END CATCH;
    PRINT CONCAT(N'Execution Error: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO
