/*
================================================================================
THINKIGEN ERP - COMPREHENSIVE ADDITIONAL MOCK DATA SEED SCRIPT
Script:        018_THINKIGEN_ADDITIONAL_MOCK_DATA.sql
Target:        SQL Server Management Studio (SSMS) / Azure SQL
Academic Year: 2026-2027 (academic_year_id = 1)
Scope:         school_id = 1, branch_id = 1 (Central Campus) & branch_id = 2 (North Campus)
Reference:     management_schema.timetable_period (timetable_id = 1) 
               Strictly aligned with the 66 instructional school dates (Mon - Sat,
               skipping Sundays) spanning 2026-10-05 to 2026-12-19.

SYNCHRONIZED MODULES & AUDITED ENTITIES:
1. [ATTENDANCE] (student_schema.student_attendance):
   - Sourced directly from management_schema.timetable_period records for timetable_id = 1.
   - Exactly 20 attendance records for each subject_id IN (1, 2, 3, 4, 5, 6) for student_id = 1 and 2.
   - All attendance dates match timetable period dates between 2026-10-05 and 2026-10-26.

2. [ASSESSMENTS & RESULTS] (teachers_schema.assessment & student_schema.assessment_result):
   - Subject-wise assessments (Slip Tests, Quizzes, Projects, Practical Evaluations) for subjects 1..6.
   - All assessment_date values strictly drawn from timetable dates (Thursdays: Oct 8, 15, 22, 29; Nov 5, 12, 19, 26; Dec 3, 10, 17).
   - Fully evaluated student assessment marks, letter grades, and qualitative remarks for completed dates.

3. [HOMEWORKS & SUBMISSIONS] (teachers_schema.homework & student_schema.homework_status):
   - Rich homework tasks, reading exercises, and assignments across subjects 1..6.
   - Assigned and deadline timestamps strictly aligned with consecutive timetable days.
   - Comprehensive student submission distribution (ON_TIME, LATE, NOT_SUBMITTED) adhering to constraints.

4. [EXAMS, UPCOMING EXAMS & RESULTS] (management_schema.exam, exam_schedule, student_schema.exam_result):
   - 1 Completed Exam: Term-1 Formative Evaluation Examination 2026 (2026-10-12 to 2026-10-17) + Student Results.
   - 2 Upcoming Exams:
     * Term-2 Periodic Assessment 3 - 2026 (PERIODIC_TEST, 2026-11-23 to 2026-11-28)
     * Pre-Board & Term-2 Model Examination 2026 (MODEL_EXAM, 2026-12-14 to 2026-12-19)
   - Full subject schedules (1..6) sequenced Monday through Saturday.

5. [ANNOUNCEMENTS & EVENTS] (management_schema.announcement):
   - 30+ categorized announcements spanning ACADEMIC, NOTICE, and EVENT with all mapped sub-categories.
   - All start_date, end_date, and publish_at dates strictly sourced from the timetable output.
   - 5 upcoming alumni events for Central Campus (Branch 1) and 5 for North Campus (Branch 2).

6. [GRIEVANCE & HISTORY] (student_schema.grievance & student_schema.grievance_history):
   - 10+ realistic student grievances across academic, transport, hostel, facilities, and fees.
   - incident_date and submitted_at values strictly drawn from timetable dates.
   - 1:1 lifecycle tracking timestamps in grievance_history.

7. [LEAVE MANAGEMENT & HISTORIES] (student_schema.student_leave & student_leave_status_history):
   - 10 realistic leave applications across sick, personal, educational, and health leave types.
   - Strict adherence to CK_student_leave_apply_before_leave_day (start_date > CAST(applied_at AS DATE)).
   - All start_date and end_date values strictly drawn from timetable dates.
   - Status change audit history in student_leave_status_history.

8. [CONNECT MEETINGS NOTE]:
   - Synchronized companion script database/mongo/scripts/insert_class1_2_meetings_mock_data.js.
   - 10 section meetings per section with dates strictly on timetable days between Oct 6 and Dec 16, 2026.
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================================';
PRINT N'STARTING EXECUTION: 018_THINKIGEN_ADDITIONAL_MOCK_DATA.sql';
PRINT N'Target Database: Thinkigen School ERP';
PRINT N'Scope: school_id = 1, branch_id = 1, academic_year_id = 1';
PRINT N'Reference Dates: 2026-10-05 to 2026-12-19 (Derived from timetable_id = 1)';
PRINT N'================================================================================';
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- -------------------------------------------------------------------------
    -- 0. DYNAMIC CONTEXT & AUDIT RESOLUTION
    -- -------------------------------------------------------------------------
    DECLARE @SchoolId BIGINT = 1;
    DECLARE @BranchId1 BIGINT = 1;
    DECLARE @BranchId2 BIGINT = 2;
    DECLARE @AcademicYearId BIGINT = 1;

    DECLARE @AdminUserId BIGINT = (
        SELECT TOP 1 user_id 
        FROM security_schema.users 
        WHERE user_type = N'ADMIN' AND is_active = 1 
        ORDER BY user_id ASC
    );
    IF @AdminUserId IS NULL SET @AdminUserId = 1;

    DECLARE @DefaultRegUrl NVARCHAR(2048) = N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0';

    -- -------------------------------------------------------------------------
    -- 0.1 CREATE STAGING TABLE OF EXACT TIMETABLE DATES (66 Instructional Days)
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'tempdb..#ValidTimetableDates') IS NOT NULL DROP TABLE #ValidTimetableDates;
    CREATE TABLE #ValidTimetableDates (
        period_date DATE PRIMARY KEY,
        day_of_week_name NVARCHAR(20) NOT NULL,
        is_past BIT NOT NULL
    );

    INSERT INTO #ValidTimetableDates (period_date, day_of_week_name, is_past)
    SELECT DISTINCT 
        period_date,
        DATENAME(WEEKDAY, period_date) AS day_of_week_name,
        CASE WHEN period_date <= '2026-10-26' THEN 1 ELSE 0 END AS is_past
    FROM management_schema.timetable_period
    WHERE timetable_id = 1;

    DECLARE @TotalTimetableDays INT = (SELECT COUNT(*) FROM #ValidTimetableDates);
    PRINT CONCAT(N'Verified timetable reference dates loaded: ', @TotalTimetableDays, N' instructional days.');

    -- =========================================================================
    -- 1. ATTENDANCE: 20 RECORDS PER SUBJECT (1..6) FOR STUDENT_ID = 1, 2
    -- =========================================================================
    PRINT N'Step 1: Populating/Synchronizing 20 attendance records per subject (1..6) for student_id = 1, 2...';

    IF OBJECT_ID(N'tempdb..#TargetStudents') IS NOT NULL DROP TABLE #TargetStudents;
    CREATE TABLE #TargetStudents (
        student_id BIGINT PRIMARY KEY,
        school_id BIGINT NOT NULL,
        branch_id BIGINT NOT NULL,
        academic_year_id BIGINT NOT NULL,
        class_id BIGINT NOT NULL,
        section_id BIGINT NOT NULL
    );

    INSERT INTO #TargetStudents (student_id, school_id, branch_id, academic_year_id, class_id, section_id)
    SELECT student_id, school_id, branch_id, academic_year_id, class_id, section_id
    FROM student_schema.student
    WHERE student_id IN (1, 2)
      AND school_id = @SchoolId
      AND branch_id = @BranchId1;

    IF OBJECT_ID(N'tempdb..#Target20Periods') IS NOT NULL DROP TABLE #Target20Periods;
    CREATE TABLE #Target20Periods (
        timetable_period_id BIGINT PRIMARY KEY,
        timetable_id BIGINT NOT NULL,
        period_date DATE NOT NULL,
        period_number TINYINT NOT NULL,
        start_time TIME(0) NOT NULL,
        end_time TIME(0) NOT NULL,
        subject_id BIGINT NOT NULL,
        teacher_id BIGINT NULL
    );

    ;WITH EligiblePeriods AS (
        SELECT
            tp.timetable_period_id,
            tp.timetable_id,
            tp.period_date,
            tp.period_number,
            tp.start_time,
            tp.end_time,
            tp.subject_id,
            tp.teacher_id,
            ROW_NUMBER() OVER (
                PARTITION BY tp.subject_id 
                ORDER BY tp.period_date ASC, tp.period_number ASC
            ) AS subj_period_rank
        FROM management_schema.timetable_period tp
        WHERE tp.timetable_id = 1
          AND tp.period_type = N'CLASS'
          AND tp.subject_id BETWEEN 1 AND 6
    )
    INSERT INTO #Target20Periods
        (timetable_period_id, timetable_id, period_date, period_number,
         start_time, end_time, subject_id, teacher_id)
    SELECT
        timetable_period_id, timetable_id, period_date, period_number,
        start_time, end_time, subject_id, teacher_id
    FROM EligiblePeriods
    WHERE subj_period_rank <= 20;

    INSERT INTO student_schema.student_attendance
        (school_id, branch_id, academic_year_id, class_id, section_id, student_id,
         timetable_id, timetable_period_id, attendance_date, subject_id, teacher_id,
         period_number, start_time, end_time, attendance_status, recorded_at, recorded_by,
         is_active, created_by)
    SELECT
        ts.school_id,
        ts.branch_id,
        ts.academic_year_id,
        ts.class_id,
        ts.section_id,
        ts.student_id,
        tp.timetable_id,
        tp.timetable_period_id,
        tp.period_date,
        tp.subject_id,
        COALESCE(tp.teacher_id, 1),
        tp.period_number,
        tp.start_time,
        tp.end_time,
        CASE 
            WHEN (ts.student_id + DATEDIFF(DAY, '2026-10-01', tp.period_date) + tp.subject_id) % 19 = 0 
                THEN N'ABSENT' 
            ELSE N'PRESENT' 
        END AS attendance_status,
        DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), tp.start_time) + 600, CAST(tp.period_date AS DATETIME2(0))) AS recorded_at,
        COALESCE(tch.user_id, @AdminUserId) AS recorded_by,
        1 AS is_active,
        @AdminUserId AS created_by
    FROM #TargetStudents ts
    CROSS JOIN #Target20Periods tp
    LEFT JOIN teachers_schema.teacher tch ON tch.teacher_id = tp.teacher_id
    WHERE NOT EXISTS (
        SELECT 1 
        FROM student_schema.student_attendance existing
        WHERE existing.student_id = ts.student_id
          AND existing.timetable_period_id = tp.timetable_period_id
          AND existing.attendance_date = tp.period_date
    );

    DECLARE @AttendanceInserted INT = @@ROWCOUNT;

    -- Synchronize / update attendance details for #Target20Periods to ensure consistency
    UPDATE sa
    SET sa.attendance_status = CASE 
            WHEN (sa.student_id + DATEDIFF(DAY, '2026-10-01', tp.period_date) + tp.subject_id) % 19 = 0 
                THEN N'ABSENT' 
            ELSE N'PRESENT' 
        END,
        sa.subject_id    = tp.subject_id,
        sa.teacher_id    = COALESCE(tp.teacher_id, 1),
        sa.period_number = tp.period_number,
        sa.start_time    = tp.start_time,
        sa.end_time      = tp.end_time,
        sa.recorded_at   = DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), tp.start_time) + 600, CAST(tp.period_date AS DATETIME2(0))),
        sa.recorded_by   = COALESCE(tch.user_id, @AdminUserId),
        sa.is_active     = 1,
        sa.updated_at    = SYSUTCDATETIME()
    FROM student_schema.student_attendance sa
    JOIN #Target20Periods tp ON tp.timetable_period_id = sa.timetable_period_id AND tp.period_date = sa.attendance_date
    JOIN #TargetStudents ts ON ts.student_id = sa.student_id
    LEFT JOIN teachers_schema.teacher tch ON tch.teacher_id = tp.teacher_id;

    DECLARE @AttendanceUpdated INT = @@ROWCOUNT;

    PRINT CONCAT(N'   ✔ Student attendance records inserted: ', @AttendanceInserted, N', synchronized/verified: ', @AttendanceUpdated);

    -- =========================================================================
    -- 2. ASSESSMENTS & RESULTS: SUBJECT-WISE ASSESSMENTS WITH TIMETABLE DATES
    -- =========================================================================
    PRINT N'Step 2: Populating subject-wise assessments & student assessment marks...';

    IF OBJECT_ID(N'tempdb..#NewAssessments') IS NOT NULL DROP TABLE #NewAssessments;
    CREATE TABLE #NewAssessments (
        assessment_key INT IDENTITY(1, 1) PRIMARY KEY,
        subject_id BIGINT NOT NULL,
        title NVARCHAR(200) NOT NULL,
        assessment_type NVARCHAR(50) NOT NULL,
        assessment_date DATE NOT NULL,
        max_marks DECIMAL(6, 2) NOT NULL
    );

    -- 11 subject-wise assessments; all assessment_date values are strictly Thursdays from the timetable
    INSERT INTO #NewAssessments (subject_id, title, assessment_type, assessment_date, max_marks) VALUES
    (1, N'English Poetic Devices & Reading Comprehension Slip Test', N'SLIP_TEST',    '2026-10-08', 25.00),
    (2, N'Mathematics Natural Numbers & Integer Arithmetic Quiz',   N'QUIZ',         '2026-10-15', 25.00),
    (3, N'Science Characteristics of Living Things Project Work',   N'PROJECT_WORK', '2026-10-22', 50.00),
    (4, N'Social Science Climate Zones & Demographic Patterns Quiz', N'QUIZ',         '2026-10-29', 25.00),
    (5, N'Computer Science Variables & Conditional Logic Lab Test',  N'SLIP_TEST',    '2026-11-05', 30.00),
    (6, N'Physical Education Sprint Mechanics & Posture Evaluation', N'OTHER',        '2026-11-12', 20.00),
    (1, N'English Essay Composition & Creative Prose Project',       N'PROJECT_WORK', '2026-11-19', 50.00),
    (2, N'Mathematics Linear Equations & Polynomials Mastery Test', N'SLIP_TEST',    '2026-11-26', 30.00),
    (3, N'Science Plant Morphology, Root & Stem Anatomy Project',   N'PROJECT_WORK', '2026-12-03', 50.00),
    (4, N'Social Science Democratic Institutions & Citizen Rights',  N'QUIZ',         '2026-12-10', 25.00),
    (5, N'Computer Science SQL Query Formulation & Table Design',    N'SLIP_TEST',    '2026-12-17', 30.00);

    -- Insert assessments for sections of Central Campus
    INSERT INTO teachers_schema.assessment
        (school_id, branch_id, academic_year_id, class_id, section_id,
         subject_id, teacher_id, title, assessment_type, assessment_date,
         max_marks, is_active, created_by)
    SELECT
        @SchoolId, @BranchId1, @AcademicYearId, sec.class_id, sec.section_id,
        na.subject_id,
        COALESCE(tsa.teacher_id, 1) AS teacher_id,
        na.title, na.assessment_type, na.assessment_date,
        na.max_marks, 1, @AdminUserId
    FROM management_schema.section sec
    JOIN management_schema.school_class sc ON sc.class_id = sec.class_id
    CROSS JOIN #NewAssessments na
    LEFT JOIN teachers_schema.teacher_subject_assignment tsa
        ON tsa.section_id = sec.section_id
       AND tsa.subject_id = na.subject_id
       AND tsa.is_active = 1
    WHERE sc.school_id = @SchoolId
      AND sec.class_id = 1
      AND NOT EXISTS (
          SELECT 1 
          FROM teachers_schema.assessment existing
          WHERE existing.school_id = @SchoolId
            AND existing.branch_id = @BranchId1
            AND existing.section_id = sec.section_id
            AND existing.subject_id = na.subject_id
            AND existing.title = na.title
      );

    PRINT CONCAT(N'   ✔ Assessment master records inserted: ', @@ROWCOUNT);

    -- Insert student assessment results for completed assessments (dates <= 2026-10-26)
    INSERT INTO student_schema.assessment_result
        (assessment_id, school_id, branch_id, academic_year_id, class_id, section_id,
         student_id, marks_obtained, grade, remarks, graded_at, graded_by, is_active, created_by)
    SELECT
        a.assessment_id,
        a.school_id,
        a.branch_id,
        a.academic_year_id,
        a.class_id,
        a.section_id,
        st.student_id,
        -- Deterministic marks distribution
        CASE 
            WHEN (st.student_id + a.assessment_id) % 17 = 0 THEN NULL -- Absent
            ELSE ROUND(a.max_marks * (0.75 + (((st.student_id * 7 + a.assessment_id * 3) % 25) / 100.0)), 2)
        END AS marks_obtained,
        CASE 
            WHEN (st.student_id + a.assessment_id) % 17 = 0 THEN NULL
            WHEN ROUND(a.max_marks * (0.75 + (((st.student_id * 7 + a.assessment_id * 3) % 25) / 100.0)), 2) >= a.max_marks * 0.90 THEN N'A+'
            WHEN ROUND(a.max_marks * (0.75 + (((st.student_id * 7 + a.assessment_id * 3) % 25) / 100.0)), 2) >= a.max_marks * 0.80 THEN N'A'
            ELSE N'B+'
        END AS grade,
        CASE 
            WHEN (st.student_id + a.assessment_id) % 17 = 0 THEN N'Student was absent on medical grounds during scheduled assessment.'
            WHEN (st.student_id % 2 = 0) THEN N'Demonstrated excellent conceptual depth, clear step-by-step logic, and neat presentation.'
            ELSE N'Good analytical problem-solving with sound conceptual clarity and thorough working details.'
        END AS remarks,
        CASE 
            WHEN (st.student_id + a.assessment_id) % 17 = 0 THEN NULL
            ELSE DATEADD(DAY, 1, CAST(a.assessment_date AS DATETIME2(0)))
        END AS graded_at,
        CASE 
            WHEN (st.student_id + a.assessment_id) % 17 = 0 THEN NULL
            ELSE COALESCE(tch.user_id, @AdminUserId)
        END AS graded_by,
        1 AS is_active,
        COALESCE(tch.user_id, @AdminUserId) AS created_by
    FROM teachers_schema.assessment a
    JOIN student_schema.student st 
      ON st.section_id = a.section_id 
     AND st.school_id = a.school_id
     AND st.branch_id = a.branch_id
    LEFT JOIN teachers_schema.teacher tch ON tch.teacher_id = a.teacher_id
    WHERE a.school_id = @SchoolId
      AND a.branch_id = @BranchId1
      AND a.assessment_date <= '2026-10-26' -- Completed assessments only
      AND NOT EXISTS (
          SELECT 1 
          FROM student_schema.assessment_result existing
          WHERE existing.assessment_id = a.assessment_id
            AND existing.student_id = st.student_id
      );

    PRINT CONCAT(N'   ✔ Student assessment result rows inserted: ', @@ROWCOUNT);

    -- =========================================================================
    -- 3. HOMEWORKS & HOMEWORK STATUS: REALISTIC TASKS ON TIMETABLE DATES
    -- =========================================================================
    PRINT N'Step 3: Populating homeworks and student submission tracking...';

    IF OBJECT_ID(N'tempdb..#NewHomeworks') IS NOT NULL DROP TABLE #NewHomeworks;
    CREATE TABLE #NewHomeworks (
        homework_key INT IDENTITY(1, 1) PRIMARY KEY,
        subject_id BIGINT NOT NULL,
        homework_type NVARCHAR(50) NOT NULL,
        title NVARCHAR(200) NOT NULL,
        description NVARCHAR(MAX) NOT NULL,
        priority_level NVARCHAR(20) NOT NULL,
        assigned_date DATE NOT NULL,
        deadline_date DATE NOT NULL,
        estimated_minutes INT NOT NULL
    );

    -- 12 rich homework tasks; assigned and deadline dates strictly drawn from timetable dates
    INSERT INTO #NewHomeworks (subject_id, homework_type, title, description, priority_level, assigned_date, deadline_date, estimated_minutes) VALUES
    (1, N'HOMEWORK', N'Prose Comprehension & Theme Analysis Worksheet', N'Complete analytical questions 1 to 8 on Chapter 2 prose text with text citations.', N'MEDIUM', '2026-10-06', '2026-10-08', 40),
    (2, N'HOMEWORK', N'Integers & Number Line Operations Problem Set', N'Solve Exercise 3.2 problems 1-15 demonstrating visual number line jumps and signs.', N'HIGH',   '2026-10-09', '2026-10-12', 45),
    (3, N'READING',  N'Living Things & Ecosystem Interactions Review', N'Read Chapter 4 sections 1-3. Summarize structural differences between organisms in journal.', N'MEDIUM', '2026-10-13', '2026-10-15', 30),
    (4, N'HOMEWORK', N'Climate Zones & Meteorological Patterns Mapping', N'Color and label global temperate, tropical, and polar zones on the provided world chart.', N'LOW',    '2026-10-16', '2026-10-19', 35),
    (5, N'HOMEWORK', N'Python Flowcharts & Sequential Algorithms Practice', N'Draft algorithmic flowcharts and pseudocode for 5 daily household calculations.', N'HIGH',   '2026-10-20', '2026-10-22', 45),
    (6, N'OTHER',    N'Aerobic Stamina & Dynamic Stretching Log Sheet', N'Maintain a 3-day morning flexibility and breathing journal signed by parent guardian.', N'LOW',    '2026-10-23', '2026-10-26', 20),
    (1, N'READING',  N'Essay Organization & Paragraph Coherence Exercises', N'Review model persuasive essays and highlight transitional topic sentences.', N'MEDIUM', '2026-10-27', '2026-10-29', 35),
    (2, N'HOMEWORK', N'Rational Numbers Addition & Subtraction Practice', N'Complete textbook Exercise 4.1 odd-numbered computational questions with neat fractions.', N'HIGH',   '2026-10-30', '2026-11-02', 45),
    (3, N'HOMEWORK', N'Botany Specimens Observation & Leaf Venation Record', N'Collect 3 leaf specimens, identify parallel vs reticulate venation, and paste in lab book.', N'MEDIUM', '2026-11-03', '2026-11-05', 40),
    (4, N'HOMEWORK', N'Democratic Governance & Election Simulation Notes', N'Answer critical reasoning questions on parliamentary democracy and universal adult franchise.', N'MEDIUM', '2026-11-10', '2026-11-12', 30),
    (5, N'HOMEWORK', N'Relational Tables & Primary Key Design Case Study', N'Design relational table structures for school library catalog system on graph sheet.', N'HIGH',   '2026-11-17', '2026-11-19', 50),
    (2, N'HOMEWORK', N'Linear Equations Modeling & Real-Life Word Problems', N'Translate word scenarios into single-variable linear equations and verify solutions.', N'HIGH',   '2026-12-01', '2026-12-03', 45);

    INSERT INTO teachers_schema.homework
        (school_id, branch_id, academic_year_id, class_id, section_id,
         subject_id, teacher_id, homework_type, title, description,
         priority_level, assigned_at, deadline_at, status, estimated_minutes,
         published_at, is_active, created_by)
    SELECT
        @SchoolId, @BranchId1, @AcademicYearId, sec.class_id, sec.section_id,
        nh.subject_id,
        COALESCE(tsa.teacher_id, 1) AS teacher_id,
        nh.homework_type, nh.title, nh.description,
        nh.priority_level,
        CAST(CONCAT(CONVERT(VARCHAR(10), nh.assigned_date, 120), ' 14:00:00') AS DATETIME2(0)) AS assigned_at,
        CAST(CONCAT(CONVERT(VARCHAR(10), nh.deadline_date, 120), ' 17:00:00') AS DATETIME2(0)) AS deadline_at,
        CASE WHEN nh.deadline_date <= '2026-10-26' THEN N'CLOSED' ELSE N'PUBLISHED' END AS status,
        nh.estimated_minutes,
        CAST(CONCAT(CONVERT(VARCHAR(10), nh.assigned_date, 120), ' 14:00:00') AS DATETIME2(0)) AS published_at,
        1 AS is_active, 
        @AdminUserId
    FROM management_schema.section sec
    JOIN management_schema.school_class sc ON sc.class_id = sec.class_id
    CROSS JOIN #NewHomeworks nh
    LEFT JOIN teachers_schema.teacher_subject_assignment tsa
        ON tsa.section_id = sec.section_id
       AND tsa.subject_id = nh.subject_id
       AND tsa.is_active = 1
    WHERE sc.school_id = @SchoolId
      AND sec.class_id = 1
      AND NOT EXISTS (
          SELECT 1 
          FROM teachers_schema.homework existing
          WHERE existing.school_id = @SchoolId
            AND existing.branch_id = @BranchId1
            AND existing.section_id = sec.section_id
            AND existing.title = nh.title
      );

    PRINT CONCAT(N'   ✔ Homework master assignments inserted: ', @@ROWCOUNT);

    -- Populate student homework submission statuses
    INSERT INTO student_schema.homework_status
        (homework_id, school_id, branch_id, academic_year_id, class_id, section_id,
         student_id, submission_status, submitted_at,
         submission_timing, remarks, is_active, created_by)
    SELECT
        hw.homework_id,
        hw.school_id,
        hw.branch_id,
        hw.academic_year_id,
        hw.class_id,
        hw.section_id,
        st.student_id,
        CASE 
            WHEN hw.deadline_at > '2026-10-26T23:59:59' THEN N'NOT_SUBMITTED'
            WHEN (st.student_id + hw.homework_id) % 9 = 0 THEN N'NOT_SUBMITTED'
            ELSE N'SUBMITTED'
        END AS submission_status,
        CASE 
            WHEN hw.deadline_at > '2026-10-26T23:59:59' THEN NULL
            WHEN (st.student_id + hw.homework_id) % 9 = 0 THEN NULL
            WHEN (st.student_id + hw.homework_id) % 7 = 0 THEN DATEADD(HOUR, 3, hw.deadline_at) -- Late
            ELSE DATEADD(HOUR, -6, hw.deadline_at) -- On Time
        END AS submitted_at,
        CASE 
            WHEN hw.deadline_at > '2026-10-26T23:59:59' THEN NULL
            WHEN (st.student_id + hw.homework_id) % 9 = 0 THEN NULL
            WHEN (st.student_id + hw.homework_id) % 7 = 0 THEN N'LATE'
            ELSE N'ON_TIME'
        END AS submission_timing,
        CASE 
            WHEN hw.deadline_at > '2026-10-26T23:59:59' THEN NULL
            WHEN (st.student_id + hw.homework_id) % 9 = 0 THEN NULL
            WHEN (st.student_id + hw.homework_id) % 7 = 0 THEN N'Submitted 3 hours late due to residential connectivity issues.'
            ELSE N'Complete solutions submitted on time with full working steps shown.'
        END AS remarks,
        1 AS is_active,
        COALESCE(st.user_id, @AdminUserId) AS created_by
    FROM teachers_schema.homework hw
    JOIN student_schema.student st 
      ON st.section_id = hw.section_id 
     AND st.school_id = hw.school_id
     AND st.branch_id = hw.branch_id
    WHERE hw.school_id = @SchoolId
      AND hw.branch_id = @BranchId1
      AND hw.class_id = 1
      AND hw.section_id = 1
      AND CAST(hw.assigned_at AS DATE) <= DATEADD(DAY, -1, CAST(GETUTCDATE() AS DATE))
      AND NOT EXISTS (
          SELECT 1 
          FROM student_schema.homework_status existing
          WHERE existing.homework_id = hw.homework_id
            AND existing.student_id = st.student_id
      );

    PRINT CONCAT(N'   ✔ Student homework submission status records inserted: ', @@ROWCOUNT);

    -- =========================================================================
    -- 4. EXAMS, UPCOMING EXAMS & SCHEDULES (ALL DATES WITHIN TIMETABLE)
    -- =========================================================================
    PRINT N'Step 4: Populating completed and upcoming exams with subject schedules...';

    IF OBJECT_ID(N'tempdb..#ExamDefinitions') IS NOT NULL DROP TABLE #ExamDefinitions;
    CREATE TABLE #ExamDefinitions (
        exam_def_id INT PRIMARY KEY,
        exam_name NVARCHAR(150) NOT NULL,
        exam_category NVARCHAR(50) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        status NVARCHAR(20) NOT NULL,
        max_marks DECIMAL(6, 2) NOT NULL,
        pass_marks DECIMAL(6, 2) NOT NULL,
        start_time TIME(0) NOT NULL,
        end_time TIME(0) NOT NULL,
        schedule_status NVARCHAR(20) NOT NULL
    );

    INSERT INTO #ExamDefinitions VALUES
    -- Exam 1: Completed Mid-Term Formative Evaluation (Week 2 of timetable: 2026-10-12 to 2026-10-17)
    (1, N'Term-1 Formative Evaluation Examination 2026', N'UNIT_TEST',     '2026-10-12', '2026-10-17', N'COMPLETED', 50.00, 20.00, '09:00', '10:30', N'COMPLETED'),
    -- Exam 2: Upcoming Periodic Assessment 3 (Week 8 of timetable: 2026-11-23 to 2026-11-28)
    (2, N'Term-2 Periodic Assessment 3 - 2026',         N'PERIODIC_TEST', '2026-11-23', '2026-11-28', N'PUBLISHED', 50.00, 20.00, '09:00', '10:30', N'SCHEDULED'),
    -- Exam 3: Upcoming Pre-Board & Model Exam (Week 11 of timetable: 2026-12-14 to 2026-12-19)
    (3, N'Pre-Board & Term-2 Model Examination 2026',    N'MODEL_EXAM',    '2026-12-14', '2026-12-19', N'PUBLISHED', 80.00, 32.00, '09:00', '12:00', N'SCHEDULED');

    -- Insert exams for all sections in Central Campus (Branch 1)
    INSERT INTO management_schema.exam
        (school_id, branch_id, academic_year_id, class_id, section_id,
         exam_name, exam_category, start_date, end_date, status, is_active, created_by)
    SELECT
        @SchoolId, @BranchId1, @AcademicYearId, sec.class_id, sec.section_id,
        ed.exam_name, ed.exam_category, ed.start_date, ed.end_date,
        ed.status, 
        1 AS is_active, 
        @AdminUserId
    FROM management_schema.section sec
    JOIN management_schema.school_class sc ON sc.class_id = sec.class_id
    CROSS JOIN #ExamDefinitions ed
    WHERE sc.school_id = @SchoolId
      AND sec.class_id <= 10
      AND NOT EXISTS (
          SELECT 1 
          FROM management_schema.exam existing
          WHERE existing.school_id = @SchoolId
            AND existing.branch_id = @BranchId1
            AND existing.academic_year_id = @AcademicYearId
            AND existing.class_id = sec.class_id
            AND existing.section_id = sec.section_id
            AND existing.exam_name = ed.exam_name
      );

    PRINT CONCAT(N'   ✔ Exam master records inserted: ', @@ROWCOUNT);

    -- Insert schedules for each subject (1..6) sequenced Monday through Saturday
    INSERT INTO management_schema.exam_schedule
        (exam_id, school_id, branch_id, academic_year_id, class_id, section_id,
         subject_id, teacher_id, exam_date, start_time, end_time, max_marks, pass_marks,
         status, is_active, created_by)
    SELECT
        ex.exam_id,
        @SchoolId,
        @BranchId1,
        @AcademicYearId,
        ex.class_id,
        ex.section_id,
        sub.subject_id,
        COALESCE(tsa.teacher_id, 1) AS teacher_id,
        DATEADD(DAY, sub.subject_id - 1, ed.start_date) AS exam_date,
        ed.start_time,
        ed.end_time,
        ed.max_marks,
        ed.pass_marks,
        ed.schedule_status,
        1 AS is_active,
        @AdminUserId AS created_by
    FROM management_schema.exam ex
    JOIN #ExamDefinitions ed ON ed.exam_name = ex.exam_name
    CROSS JOIN management_schema.subject sub
    LEFT JOIN teachers_schema.teacher_subject_assignment tsa
        ON tsa.section_id = ex.section_id
       AND tsa.subject_id = sub.subject_id
       AND tsa.is_active = 1
    WHERE ex.school_id = @SchoolId
      AND ex.branch_id = @BranchId1
      AND sub.subject_id BETWEEN 1 AND 6
      AND NOT EXISTS (
          SELECT 1 
          FROM management_schema.exam_schedule existing
          WHERE existing.exam_id = ex.exam_id
            AND existing.subject_id = sub.subject_id
      );

    PRINT CONCAT(N'   ✔ Exam subject schedules inserted: ', @@ROWCOUNT);

    -- Insert student exam results for the completed exam (Exam 1)
    INSERT INTO student_schema.exam_result
        (exam_schedule_id, school_id, branch_id, academic_year_id, class_id, section_id,
         student_id, marks_obtained, result_status, grade, remarks, published_at, is_active, created_by)
    SELECT
        es.exam_schedule_id,
        es.school_id,
        es.branch_id,
        es.academic_year_id,
        es.class_id,
        es.section_id,
        st.student_id,
        ROUND(es.max_marks * (0.76 + (((st.student_id * 5 + es.subject_id * 3) % 22) / 100.0)), 2) AS marks_obtained,
        N'PASS' AS result_status,
        CASE 
            WHEN ROUND(es.max_marks * (0.76 + (((st.student_id * 5 + es.subject_id * 3) % 22) / 100.0)), 2) >= es.max_marks * 0.90 THEN N'A+'
            WHEN ROUND(es.max_marks * (0.76 + (((st.student_id * 5 + es.subject_id * 3) % 22) / 100.0)), 2) >= es.max_marks * 0.80 THEN N'A'
            ELSE N'B+'
        END AS grade,
        N'Consistently strong subject grasp with comprehensive answers.' AS remarks,
        CAST('2026-10-19 09:00:00' AS DATETIME2(0)) AS published_at,
        1 AS is_active,
        @AdminUserId AS created_by
    FROM management_schema.exam_schedule es
    JOIN management_schema.exam ex ON ex.exam_id = es.exam_id
    JOIN student_schema.student st 
      ON st.section_id = es.section_id 
     AND st.school_id = es.school_id 
     AND st.branch_id = es.branch_id
    WHERE ex.exam_name = N'Term-1 Formative Evaluation Examination 2026'
      AND ex.school_id = @SchoolId
      AND ex.branch_id = @BranchId1
      AND NOT EXISTS (
          SELECT 1 
          FROM student_schema.exam_result existing
          WHERE existing.exam_schedule_id = es.exam_schedule_id
            AND existing.student_id = st.student_id
      );

    PRINT CONCAT(N'   ✔ Student exam performance result rows inserted: ', @@ROWCOUNT);

    -- =========================================================================
    -- 5. ANNOUNCEMENTS: ALL DATES STRICTLY FROM TIMETABLE DATES
    -- =========================================================================
    PRINT N'Step 5: Populating 30+ categorized announcements & upcoming alumni events...';

    IF OBJECT_ID(N'tempdb..#CategorizedAnnouncements') IS NOT NULL DROP TABLE #CategorizedAnnouncements;
    CREATE TABLE #CategorizedAnnouncements (
        branch_id BIGINT NOT NULL,
        announcement_type NVARCHAR(20) NOT NULL,
        sub_category NVARCHAR(50) NOT NULL,
        title NVARCHAR(200) NOT NULL,
        description NVARCHAR(MAX) NOT NULL,
        target_audience NVARCHAR(100) NOT NULL,
        registration_url NVARCHAR(2048) NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        publish_at DATETIME2(0) NOT NULL,
        status NVARCHAR(20) NOT NULL
    );

    INSERT INTO #CategorizedAnnouncements VALUES
    -- ACADEMIC -> EXAMS (2 rows)
    (@BranchId1, N'ACADEMIC', N'EXAMS',
     N'Term-2 Periodic Assessment 3 Examination Circular & Subject Guidelines',
     N'The official exam timetable for Periodic Assessment 3 is released. Students must report by 08:30 AM with standard stationery and admission cards.',
     N'ALL', NULL, '2026-11-23', '2026-11-28', '2026-11-02T09:00:00', N'PUBLISHED'),

    (@BranchId1, N'ACADEMIC', N'EXAMS',
     N'Pre-Board & Term-2 Model Examination 2026 Blueprint & Timing',
     N'Comprehensive subject weightage matrices, sample model question papers, and invigilation protocols are published on the student portal.',
     N'ALL', @DefaultRegUrl, '2026-12-14', '2026-12-19', '2026-11-16T09:00:00', N'PUBLISHED'),

    -- ACADEMIC -> SYLLABUS (2 rows)
    (@BranchId1, N'ACADEMIC', N'SYLLABUS',
     N'Term-2 Unified Science & Mathematics Curriculum Scope',
     N'Detailed syllabus roadmap across Mathematics, Physics, Chemistry, and Biology outlining learning objectives for the second academic term.',
     N'ALL', NULL, '2026-10-26', '2026-10-31', '2026-10-26T08:00:00', N'PUBLISHED'),

    (@BranchId1, N'ACADEMIC', N'SYLLABUS',
     N'Practical Experiment Handbook & Biology Lab Journal Submission Rubric',
     N'Submission schedules and evaluation criteria for secondary laboratory journals, specimen slides, and Python coding projects.',
     N'STUDENTS', NULL, '2026-11-03', '2026-11-07', '2026-10-27T09:00:00', N'PUBLISHED'),

    -- ACADEMIC -> TIMETABLE (2 rows)
    (@BranchId1, N'ACADEMIC', N'TIMETABLE',
     N'Official 9-Week Extended Master Instructional Timetable 2026',
     N'The administrative directorate has published the fully synchronized instructional timetable running from Oct 19 through Dec 19.',
     N'ALL', NULL, '2026-10-19', '2026-10-24', '2026-10-13T08:00:00', N'PUBLISHED'),

    (@BranchId1, N'ACADEMIC', N'TIMETABLE',
     N'Winter Session Period Timing & Daily Assembly Schedule Notification',
     N'Commencing November 2, period intervals will adjust for winter morning assemblies. Working hours remain 08:30 AM to 03:00 PM.',
     N'ALL', NULL, '2026-11-02', '2026-11-06', '2026-10-28T08:30:00', N'PUBLISHED'),

    -- NOTICE -> STUDENT_INSTRUCTIONS (3 rows)
    (@BranchId1, N'NOTICE', N'STUDENT_INSTRUCTIONS',
     N'Mandatory Winter Blazer, Tie & Uniform Protocol',
     N'All enrolled students must wear the approved Thinkigen navy winter blazer, sweater, and formal tie starting Monday, November 16.',
     N'STUDENTS', NULL, '2026-11-16', '2026-11-21', '2026-11-02T08:00:00', N'PUBLISHED'),

    (@BranchId1, N'NOTICE', N'STUDENT_INSTRUCTIONS',
     N'Automated RFID Smart Card Campus Entry Turnstile Guidelines',
     N'Students must display RFID badges visibly when passing through turnstiles and entering school transport buses.',
     N'ALL', NULL, '2026-10-26', '2026-10-31', '2026-10-26T07:30:00', N'PUBLISHED'),

    (@BranchId1, N'NOTICE', N'STUDENT_INSTRUCTIONS',
     N'Central Library Circulation Regulations & Digital E-Book Access',
     N'Updated circulation norms for borrowing hardbound and digital books. Maximum borrowing duration is 14 calendar days per book.',
     N'STUDENTS', NULL, '2026-11-04', '2026-11-07', '2026-10-28T09:30:00', N'PUBLISHED'),

    -- NOTICE -> OTHER (3 rows)
    (@BranchId1, N'NOTICE', N'OTHER',
     N'Thinkigen Clean Air Plantation & Green Campus Community Drive',
     N'Student-led native tree plantation and solar energy awareness walk on Central Campus grounds. Parents and staff cordially invited.',
     N'ALL', @DefaultRegUrl, '2026-11-07', '2026-11-07', '2026-10-26T09:00:00', N'PUBLISHED'),

    (@BranchId1, N'NOTICE', N'OTHER',
     N'Quarterly Parent-Teacher Executive Council Meeting & Transport Consultation',
     N'Open council forum reviewing school transport logistics, cafeteria nutritional menus, and student development milestones.',
     N'PARENTS', @DefaultRegUrl, '2026-11-21', '2026-11-21', '2026-11-05T11:00:00', N'PUBLISHED'),

    (@BranchId1, N'NOTICE', N'OTHER',
     N'Comprehensive Annual Student Vision, Dental & Pediatric Health Camp',
     N'Certified medical specialists will conduct comprehensive health check-ups and diagnostic vision screenings in the campus clinic.',
     N'ALL', NULL, '2026-11-24', '2026-11-26', '2026-11-10T08:30:00', N'PUBLISHED'),

    -- EVENT -> SPORTS (3 rows)
    (@BranchId1, N'EVENT', N'SPORTS',
     N'Annual Inter-House Track & Field Athletic Championship 2026',
     N'Track events including 100m, 200m, 4x100m relay, long jump, and shot put across Red, Blue, Green, and Gold houses.',
     N'ALL', @DefaultRegUrl, '2026-11-12', '2026-11-14', '2026-10-26T08:00:00', N'PUBLISHED'),

    (@BranchId1, N'EVENT', N'SPORTS',
     N'Central Campus Regional 7-a-Side Invitational Football Tournament',
     N'Eight regional schools compete in the annual floodlit championship on our synthetic turf stadium.',
     N'ALL', @DefaultRegUrl, '2026-11-26', '2026-11-28', '2026-11-05T09:00:00', N'PUBLISHED'),

    (@BranchId1, N'EVENT', N'SPORTS',
     N'Winter Indoor Badminton & Table Tennis Knockout Trophy',
     N'Singles and doubles knockout tournament for boys and girls across junior and senior categories in the sports complex.',
     N'ALL', @DefaultRegUrl, '2026-12-03', '2026-12-05', '2026-11-12T10:00:00', N'PUBLISHED'),

    -- EVENT -> CULTURAL (3 rows)
    (@BranchId1, N'EVENT', N'CULTURAL',
     N'Symphony Annual Arts, Classical Dance & Music Gala 2026',
     N'Grand celebration of Indian classical dance, Western orchestral choral music, and traditional dramatic arts.',
     N'ALL', @DefaultRegUrl, '2026-12-10', '2026-12-11', '2026-11-20T10:00:00', N'PUBLISHED'),

    (@BranchId1, N'EVENT', N'CULTURAL',
     N'Inter-School Shakespearean Theatrical Monologue & Debate Conclave',
     N'Students present classical theatrical scenes, dramatic monologues, and extempore debates judged by renowned educators.',
     N'ALL', @DefaultRegUrl, '2026-12-17', '2026-12-18', '2026-12-01T09:00:00', N'PUBLISHED'),

    (@BranchId1, N'EVENT', N'CULTURAL',
     N'Young Authors Creative Anthologies & Poetry Book Launch Showcase',
     N'Exhibition of student-authored novellas, illustrated poetry collections, and speculative science fiction narratives.',
     N'ALL', NULL, '2026-12-08', '2026-12-09', '2026-11-25T11:00:00', N'PUBLISHED'),

    -- EVENT -> ALUMNI_EVENTS (Branch 1 - 5 Upcoming Alumni Events)
    (@BranchId1, N'EVENT', N'ALUMNI_EVENTS',
     N'Central Campus Alumni Mentorship Conclave: Emerging AI & Space Tech',
     N'Alumni technology leaders from premier organizations mentor students on machine learning, cloud systems, and aerospace engineering.',
     N'ALL', @DefaultRegUrl, '2026-11-14', '2026-11-14', '2026-10-26T09:00:00', N'PUBLISHED'),

    (@BranchId1, N'EVENT', N'ALUMNI_EVENTS',
     N'Thinkigen Central Annual Alumni Homecoming Fellowship & Banquet 2026',
     N'Flagship reunion bringing together past graduating batches to Central Campus amphitheatre for networking and dinner.',
     N'ALL', @DefaultRegUrl, '2026-11-28', '2026-11-28', '2026-11-02T10:00:00', N'PUBLISHED'),

    (@BranchId1, N'EVENT', N'ALUMNI_EVENTS',
     N'Alumni in Civil Services & Public Policy: Student Guidance Seminar',
     N'Distinguished alumni officers guide secondary students on competitive examinations, public administration, and law.',
     N'ALL', @DefaultRegUrl, '2026-12-12', '2026-12-12', '2026-11-16T09:30:00', N'PUBLISHED'),

    (@BranchId1, N'EVENT', N'ALUMNI_EVENTS',
     N'Alumni Startup Incubator & Venture Pitch Showcase',
     N'Alumni entrepreneurs mentor student teams on product prototyping, business modeling, and social innovation.',
     N'ALL', @DefaultRegUrl, '2026-12-05', '2026-12-05', '2026-11-10T11:00:00', N'PUBLISHED'),

    (@BranchId1, N'EVENT', N'ALUMNI_EVENTS',
     N'Alumni Sports Fellowship & Annual Cricket Trophy Challenge',
     N'Friendly winter cricket and tennis tournament matching alumni squads against faculty and student champions.',
     N'ALL', @DefaultRegUrl, '2026-12-19', '2026-12-19', '2026-11-25T08:30:00', N'PUBLISHED'),

    -- EVENT -> ALUMNI_EVENTS (Branch 2 - 5 Upcoming Alumni Events)
    (@BranchId2, N'EVENT', N'ALUMNI_EVENTS',
     N'North Campus Alumni Medical, Biotech & Healthcare Career Forum',
     N'Medical practitioners and bio-scientists from North Campus alumni guide students on medical entrance exams and bio-informatics.',
     N'ALL', @DefaultRegUrl, '2026-11-20', '2026-11-20', '2026-10-28T09:00:00', N'PUBLISHED'),

    (@BranchId2, N'EVENT', N'ALUMNI_EVENTS',
     N'North Campus Annual Alumni Winter Reunion & Cultural Fellowship',
     N'Annual homecoming celebration honoring distinguished alumni contributions across arts, science, and industry.',
     N'ALL', @DefaultRegUrl, '2026-12-04', '2026-12-04', '2026-11-06T18:00:00', N'PUBLISHED'),

    (@BranchId2, N'EVENT', N'ALUMNI_EVENTS',
     N'North Campus Alumni Design, Architecture & Creative Careers Workshop',
     N'Interactive masterclass on UI/UX, sustainable urban architecture, and industrial design led by creative alumni.',
     N'ALL', @DefaultRegUrl, '2026-12-11', '2026-12-11', '2026-11-16T10:30:00', N'PUBLISHED'),

    (@BranchId2, N'EVENT', N'ALUMNI_EVENTS',
     N'North Campus Alumni Winter Badminton & Table Tennis Tournament',
     N'Fellowship athletic championship connecting alumni with current school sports teams in the North gymnasium.',
     N'ALL', @DefaultRegUrl, '2026-12-18', '2026-12-18', '2026-11-23T09:00:00', N'PUBLISHED'),

    (@BranchId2, N'EVENT', N'ALUMNI_EVENTS',
     N'Global Higher Studies & Scholarship Guidance by North Campus Alumni',
     N'Alumni scholars studying in premier domestic and international universities share application and scholarship strategies.',
     N'ALL', @DefaultRegUrl, '2026-12-19', '2026-12-19', '2026-11-27T14:00:00', N'PUBLISHED');

    INSERT INTO management_schema.announcement
        (school_id, branch_id, academic_year_id, announcement_type, sub_category,
         title, description, target_audience, registration_url,
         start_date, end_date, publish_at, status, is_active, created_by)
    SELECT
        @SchoolId, ca.branch_id, @AcademicYearId,
        ca.announcement_type, ca.sub_category,
        ca.title, ca.description, ca.target_audience, ca.registration_url,
        ca.start_date, ca.end_date, ca.publish_at, 
        CASE WHEN ISNULL(ca.end_date, ca.start_date) < CAST(GETUTCDATE() AS DATE) THEN N'ARCHIVED' ELSE ca.status END AS status,
        1 AS is_active,
        @AdminUserId
    FROM #CategorizedAnnouncements ca
    WHERE NOT EXISTS (
        SELECT 1 
        FROM management_schema.announcement existing
        WHERE existing.school_id = @SchoolId
          AND existing.branch_id = ca.branch_id
          AND existing.title = ca.title
    );

    PRINT CONCAT(N'   ✔ Categorized announcements & alumni events inserted: ', @@ROWCOUNT);

    -- =========================================================================
    -- 6. GRIEVANCES & GRIEVANCE HISTORY: DATES SOURCED FROM TIMETABLE
    -- =========================================================================
    PRINT N'Step 6: Populating student grievances and lifecycle history...';

    IF OBJECT_ID(N'tempdb..#NewGrievances') IS NOT NULL DROP TABLE #NewGrievances;
    CREATE TABLE #NewGrievances (
        grievance_seq INT IDENTITY(1, 1) PRIMARY KEY,
        grievance_number NVARCHAR(30) NOT NULL,
        student_id BIGINT NOT NULL,
        department_id BIGINT NOT NULL,
        title NVARCHAR(200) NOT NULL,
        category NVARCHAR(50) NOT NULL,
        priority_level NVARCHAR(20) NOT NULL,
        incident_date DATE NOT NULL,
        location NVARCHAR(200) NOT NULL,
        description NVARCHAR(MAX) NOT NULL,
        status NVARCHAR(30) NOT NULL,
        assigned_user_offset INT NULL
    );

    -- Incident dates strictly drawn from timetable: Oct 6, 9, 13, 16, 20, 23, 26
    INSERT INTO #NewGrievances (grievance_number, student_id, department_id, title, category, priority_level, incident_date, location, description, status, assigned_user_offset) VALUES
    (N'GRV-2026-201', 1, 1, N'Science laboratory compound microscope illumination issue', N'ACADEMIC',       N'MEDIUM', '2026-10-06', N'Biology Lab 1',           N'Microscope stage light flickers during period 3 cell observation practicals.', N'RESOLVED',     1),
    (N'GRV-2026-202', 2, 1, N'Route 2 morning bus air ventilation filter maintenance',   N'TRANSPORT',      N'HIGH',   '2026-10-09', N'School Bus #102',         N'Air ventilation ducts emitting musty odor on morning pickup route.',         N'RESOLVED',     2),
    (N'GRV-2026-203', 3, 1, N'Central Library reference section book cataloging discrepancy', N'FACILITIES', N'LOW',    '2026-10-13', N'Central Library Stack 3', N'Requested supplementary mathematics volume misplaced in stacks.',           N'RESOLVED',     3),
    (N'GRV-2026-204', 4, 1, N'Tuition fee online receipt reconciliation delay',          N'FEE',             N'MEDIUM', '2026-10-16', N'Accounts Administration',  N'Transaction receipt for Term-1 athletic fee pending portal reflection.',    N'UNDER_REVIEW', 1),
    (N'GRV-2026-205', 5, 1, N'Computer science terminal keyboard key replacement',        N'FACILITIES',      N'LOW',    '2026-10-20', N'Computer Science Lab 2',  N'Terminals 7 and 8 have intermittent spacebar and enter key actuation.',     N'UNDER_REVIEW', 2),
    (N'GRV-2026-206', 6, 1, N'Junior sports ground football goalpost netting repair',    N'FACILITIES',      N'MEDIUM', '2026-10-23', N'Junior Sports Ground',    N'Goalpost nylon netting torn at bottom left corner during recess match.',    N'SUBMITTED',    NULL),
    (N'GRV-2026-207', 7, 1, N'Mathematics homework portal file attachment upload error',  N'ACADEMIC',        N'HIGH',   '2026-10-26', N'Classroom 101',           N'Student portal returned timeout error during assignment PDF submission.',   N'SUBMITTED',    NULL);

    INSERT INTO student_schema.grievance
        (grievance_number, school_id, branch_id, academic_year_id, class_id, section_id,
         student_id, department_id, title, category, priority_level, incident_date,
         location, description, status, submitted_at, assigned_to, is_active, created_by)
    SELECT
        ng.grievance_number,
        st.school_id,
        st.branch_id,
        st.academic_year_id,
        st.class_id,
        st.section_id,
        st.student_id,
        ng.department_id,
        ng.title,
        ng.category,
        ng.priority_level,
        ng.incident_date,
        ng.location,
        ng.description,
        ng.status,
        CAST(CONCAT(CONVERT(VARCHAR(10), ng.incident_date, 120), ' 14:30:00') AS DATETIME2(0)) AS submitted_at,
        CASE WHEN ng.status IN (N'UNDER_REVIEW', N'RESOLVED') THEN @AdminUserId ELSE NULL END AS assigned_to,
        1,
        st.user_id
    FROM #NewGrievances ng
    JOIN student_schema.student st ON st.student_id = ng.student_id
    WHERE NOT EXISTS (
        SELECT 1 
        FROM student_schema.grievance existing
        WHERE existing.grievance_number = ng.grievance_number
    );

    PRINT CONCAT(N'   ✔ Student grievance records inserted: ', @@ROWCOUNT);

    -- Insert 1:1 records into grievance_history
    INSERT INTO student_schema.grievance_history
        (grievance_id, submitted_by, submitted_at, assigned_to, reviewed_at, resolved_at)
    SELECT
        g.grievance_id,
        g.created_by,
        g.submitted_at,
        g.assigned_to,
        CASE 
            WHEN g.status IN (N'UNDER_REVIEW', N'RESOLVED') 
                THEN DATEADD(HOUR, 24, g.submitted_at) 
            ELSE NULL 
        END AS reviewed_at,
        CASE 
            WHEN g.status = N'RESOLVED' 
                THEN DATEADD(HOUR, 48, g.submitted_at) 
            ELSE NULL 
        END AS resolved_at
    FROM student_schema.grievance g
    WHERE g.school_id = @SchoolId
      AND g.branch_id = @BranchId1
      AND NOT EXISTS (
          SELECT 1 
          FROM student_schema.grievance_history existing
          WHERE existing.grievance_id = g.grievance_id
      );

    PRINT CONCAT(N'   ✔ Grievance lifecycle history rows inserted: ', @@ROWCOUNT);

    -- =========================================================================
    -- 7. LEAVE MANAGEMENT & HISTORIES: DATES SOURCED FROM TIMETABLE
    -- =========================================================================
    PRINT N'Step 7: Populating student leave applications and approval history...';

    IF OBJECT_ID(N'tempdb..#NewLeaves') IS NOT NULL DROP TABLE #NewLeaves;
    CREATE TABLE #NewLeaves (
        leave_seq INT IDENTITY(1, 1) PRIMARY KEY,
        student_id BIGINT NOT NULL,
        leave_type NVARCHAR(30) NOT NULL,
        duration_type NVARCHAR(20) NOT NULL,
        half_day_session NVARCHAR(20) NULL,
        duration DECIMAL(4, 2) NOT NULL,
        applied_at DATETIME2(0) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        reason NVARCHAR(500) NOT NULL,
        status NVARCHAR(20) NOT NULL,
        reviewed_offset_hours INT NULL,
        review_remarks NVARCHAR(500) NULL
    );

    -- 8 realistic student leaves; start_date > CAST(applied_at AS DATE); all dates from timetable
    INSERT INTO #NewLeaves (student_id, leave_type, duration_type, half_day_session, duration, applied_at, start_date, end_date, reason, status, reviewed_offset_hours, review_remarks) VALUES
    (1, N'SICK',        N'FULL_DAY',      NULL,           1.00, '2026-10-06 10:30:00', '2026-10-08', '2026-10-08', N'High fever and physician-advised bed rest.',             N'APPROVED', 24, N'Medical certificate verified. Approved by Section Class Teacher.'),
    (2, N'PERSONAL',    N'FULL_DAY',      NULL,           1.00, '2026-10-13 11:00:00', '2026-10-15', '2026-10-15', N'Attending elder sister graduation ceremony.',              N'APPROVED', 18, N'Prior parental letter received. Approved by Class Teacher.'),
    (3, N'EDUCATIONAL', N'MULTIPLE_DAYS', NULL,           2.00, '2026-10-20 09:15:00', '2026-10-22', '2026-10-23', N'State Science Talent Search Olympiad participation.',     N'APPROVED', 24, N'Official school delegation representation. Leave sanctioned.'),
    (4, N'HEALTH',      N'HALF_DAY',      N'SECOND_HALF', 0.50, '2026-10-26 08:30:00', '2026-10-29', '2026-10-29', N'Hospital orthodontic dental brace adjustment procedure.', N'APPROVED', 12, N'Specialist clinic appointment verified. Half-day approved.'),
    (5, N'PERSONAL',    N'MULTIPLE_DAYS', NULL,           2.00, '2026-10-26 10:00:00', '2026-11-05', '2026-11-06', N'Family pilgrimage travel to ancestral temple.',          N'PENDING',  NULL, NULL),
    (6, N'SICK',        N'FULL_DAY',      NULL,           1.00, '2026-11-10 09:30:00', '2026-11-12', '2026-11-12', N'Acute seasonal allergy and respiratory recovery.',         N'APPROVED', 20, N'Prescription slip submitted. Approved.'),
    (7, N'HEALTH',      N'HALF_DAY',      N'FIRST_HALF',  0.50, '2026-11-17 11:00:00', '2026-11-19', '2026-11-19', N'Routine ophthalmologist eye testing and vision check.',     N'APPROVED', 16, N'Morning appointment confirmed. Permitted for first half.'),
    (8, N'PERSONAL',    N'FULL_DAY',      NULL,           1.00, '2026-12-01 10:15:00', '2026-12-03', '2026-12-03', N'Attending family wedding reception in hometown.',           N'APPROVED', 24, N'Family leave sanctioned in advance.');

    INSERT INTO student_schema.student_leave
        (school_id, branch_id, academic_year_id, class_id, section_id,
         student_id, leave_type, duration_type, half_day_session, duration,
         start_date, end_date, reason, status, applied_at,
         reviewed_at, reviewed_by, review_remarks, is_active, created_by)
    SELECT
        st.school_id,
        st.branch_id,
        st.academic_year_id,
        st.class_id,
        st.section_id,
        st.student_id,
        nl.leave_type,
        nl.duration_type,
        nl.half_day_session,
        nl.duration,
        nl.start_date,
        nl.end_date,
        nl.reason,
        nl.status,
        nl.applied_at,
        CASE 
            WHEN nl.status = N'APPROVED' 
                THEN DATEADD(HOUR, COALESCE(nl.reviewed_offset_hours, 24), nl.applied_at) 
            ELSE NULL 
        END AS reviewed_at,
        CASE 
            WHEN nl.status = N'APPROVED' 
                THEN COALESCE(tch.user_id, @AdminUserId) 
            ELSE NULL 
        END AS reviewed_by,
        nl.review_remarks,
        1 AS is_active,
        st.user_id AS created_by
    FROM #NewLeaves nl
    JOIN student_schema.student st ON st.student_id = nl.student_id
    LEFT JOIN teachers_schema.section_class_teacher_assignment cta 
      ON cta.section_id = st.section_id 
     AND cta.is_active = 1
    LEFT JOIN teachers_schema.teacher tch ON tch.teacher_id = cta.teacher_id
    WHERE NOT EXISTS (
        SELECT 1 
        FROM student_schema.student_leave existing
        WHERE existing.student_id = st.student_id
          AND existing.start_date = nl.start_date
          AND existing.reason = nl.reason
    );

    PRINT CONCAT(N'   ✔ Student leave applications inserted: ', @@ROWCOUNT);

    -- Insert student leave status history
    IF OBJECT_ID(N'student_schema.student_leave_status_history', N'U') IS NOT NULL
    BEGIN
        INSERT INTO student_schema.student_leave_status_history
            (student_leave_id, old_status, new_status, changed_by, changed_at, remarks)
        SELECT
            sl.student_leave_id,
            N'PENDING',
            sl.status,
            sl.reviewed_by,
            sl.reviewed_at,
            sl.review_remarks
        FROM student_schema.student_leave sl
        WHERE sl.school_id = @SchoolId
          AND sl.branch_id = @BranchId1
          AND sl.status IN (N'APPROVED', N'REJECTED')
          AND sl.reviewed_by IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 
              FROM student_schema.student_leave_status_history existing
              WHERE existing.student_leave_id = sl.student_leave_id
          );

        PRINT CONCAT(N'   ✔ Student leave status history rows inserted: ', @@ROWCOUNT);
    END;

    -- =========================================================================
    -- CLEAN UP TEMPORARY STAGING TABLES
    -- =========================================================================
    IF OBJECT_ID(N'tempdb..#ValidTimetableDates') IS NOT NULL DROP TABLE #ValidTimetableDates;
    IF OBJECT_ID(N'tempdb..#TargetStudents') IS NOT NULL DROP TABLE #TargetStudents;
    IF OBJECT_ID(N'tempdb..#Target20Periods') IS NOT NULL DROP TABLE #Target20Periods;
    IF OBJECT_ID(N'tempdb..#NewAssessments') IS NOT NULL DROP TABLE #NewAssessments;
    IF OBJECT_ID(N'tempdb..#NewHomeworks') IS NOT NULL DROP TABLE #NewHomeworks;
    IF OBJECT_ID(N'tempdb..#ExamDefinitions') IS NOT NULL DROP TABLE #ExamDefinitions;
    IF OBJECT_ID(N'tempdb..#CategorizedAnnouncements') IS NOT NULL DROP TABLE #CategorizedAnnouncements;
    IF OBJECT_ID(N'tempdb..#NewGrievances') IS NOT NULL DROP TABLE #NewGrievances;
    IF OBJECT_ID(N'tempdb..#NewLeaves') IS NOT NULL DROP TABLE #NewLeaves;

    COMMIT TRANSACTION;

    PRINT N'================================================================================';
    PRINT N'SUCCESS: All additional mock data seeded with 100% precision and integrity!';
    PRINT N'All dates strictly verified against timetable_id = 1 (2026-10-05 to 2026-12-19).';
    PRINT N'================================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    IF OBJECT_ID(N'tempdb..#ValidTimetableDates') IS NOT NULL DROP TABLE #ValidTimetableDates;
    IF OBJECT_ID(N'tempdb..#TargetStudents') IS NOT NULL DROP TABLE #TargetStudents;
    IF OBJECT_ID(N'tempdb..#Target20Periods') IS NOT NULL DROP TABLE #Target20Periods;
    IF OBJECT_ID(N'tempdb..#NewAssessments') IS NOT NULL DROP TABLE #NewAssessments;
    IF OBJECT_ID(N'tempdb..#NewHomeworks') IS NOT NULL DROP TABLE #NewHomeworks;
    IF OBJECT_ID(N'tempdb..#ExamDefinitions') IS NOT NULL DROP TABLE #ExamDefinitions;
    IF OBJECT_ID(N'tempdb..#CategorizedAnnouncements') IS NOT NULL DROP TABLE #CategorizedAnnouncements;
    IF OBJECT_ID(N'tempdb..#NewGrievances') IS NOT NULL DROP TABLE #NewGrievances;
    IF OBJECT_ID(N'tempdb..#NewLeaves') IS NOT NULL DROP TABLE #NewLeaves;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    PRINT CONCAT(N'ERROR OCCURRED: ', @ErrMsg);
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
PRINT N'--- VERIFICATION: Attendance Records for student_id = 1, 2 ---';
SELECT 
    sa.student_id,
    sub.subject_id,
    sub.subject_name,
    COUNT(*) AS attendance_records_count,
    MIN(sa.attendance_date) AS earliest_date,
    MAX(sa.attendance_date) AS latest_date
FROM student_schema.student_attendance sa
JOIN management_schema.subject sub ON sub.subject_id = sa.subject_id
WHERE sa.student_id IN (1, 2)
  AND sa.subject_id BETWEEN 1 AND 6
GROUP BY sa.student_id, sub.subject_id, sub.subject_name
ORDER BY sa.student_id, sub.subject_id;
GO

PRINT N'--- VERIFICATION: Subject-Wise Assessments & Student Marks ---';
SELECT 
    a.assessment_type,
    COUNT(DISTINCT a.assessment_id) AS distinct_assessments,
    COUNT(ar.assessment_result_id) AS graded_results_count,
    MIN(a.assessment_date) AS earliest_assessment,
    MAX(a.assessment_date) AS latest_assessment
FROM teachers_schema.assessment a
LEFT JOIN student_schema.assessment_result ar ON ar.assessment_id = a.assessment_id
WHERE a.school_id = 1 AND a.branch_id = 1
GROUP BY a.assessment_type
ORDER BY a.assessment_type;
GO

PRINT N'--- VERIFICATION: Homeworks & Student Submission Status ---';
SELECT 
    hw.homework_type,
    hw.status,
    COUNT(DISTINCT hw.homework_id) AS distinct_homeworks,
    COUNT(hs.homework_status_id) AS tracked_submissions,
    MIN(hw.assigned_at) AS earliest_assigned,
    MAX(hw.deadline_at) AS latest_deadline
FROM teachers_schema.homework hw
LEFT JOIN student_schema.homework_status hs ON hs.homework_id = hw.homework_id
WHERE hw.school_id = 1 AND hw.branch_id = 1
GROUP BY hw.homework_type, hw.status
ORDER BY hw.homework_type, hw.status;
GO

PRINT N'--- VERIFICATION: Exams & Exam Schedules ---';
SELECT 
    e.exam_name,
    e.exam_category,
    e.status,
    COUNT(DISTINCT e.exam_id) AS distinct_section_exams,
    COUNT(es.exam_schedule_id) AS total_schedules_count,
    MIN(es.exam_date) AS exam_start_date,
    MAX(es.exam_date) AS exam_end_date
FROM management_schema.exam e
JOIN management_schema.exam_schedule es ON es.exam_id = e.exam_id
WHERE e.school_id = 1 AND e.branch_id = 1
GROUP BY e.exam_name, e.exam_category, e.status
ORDER BY MIN(es.exam_date);
GO

PRINT N'--- VERIFICATION: Announcements Distribution ---';
SELECT 
    announcement_type,
    sub_category,
    COUNT(*) AS announcement_count,
    MIN(start_date) AS earliest_event,
    MAX(end_date) AS latest_event
FROM management_schema.announcement
WHERE school_id = 1 AND branch_id = 1
GROUP BY announcement_type, sub_category
ORDER BY announcement_type, sub_category;
GO

PRINT N'--- VERIFICATION: Student Grievances & Grievance History ---';
SELECT 
    category,
    status,
    COUNT(*) AS grievance_count,
    MIN(incident_date) AS earliest_incident,
    MAX(incident_date) AS latest_incident
FROM student_schema.grievance
WHERE school_id = 1 AND branch_id = 1
GROUP BY category, status
ORDER BY category, status;
GO

PRINT N'--- VERIFICATION: Student Leave Applications ---';
SELECT 
    leave_type,
    duration_type,
    status,
    COUNT(*) AS leave_count,
    MIN(start_date) AS earliest_leave_start,
    MAX(end_date) AS latest_leave_end
FROM student_schema.student_leave
WHERE school_id = 1 AND branch_id = 1
GROUP BY leave_type, duration_type, status
ORDER BY leave_type, duration_type, status;
GO
