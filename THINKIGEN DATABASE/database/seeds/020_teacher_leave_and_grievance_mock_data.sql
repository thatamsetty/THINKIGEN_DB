/*
================================================================================
THINKIGEN ERP - TEACHER LEAVE & GRIEVANCE MOCK DATA SEED SCRIPT
Script:        020_teacher_leave_and_grievance_mock_data.sql
Target:        SQL Server Management Studio (SSMS) / Azure SQL
Academic Year: 2026-2027 (academic_year_id = 1)
Scope:         school_id = 1, branch_id = 1 (Central Campus) & branch_id = 2 (North Campus)
Module:        teachers_schema (Migration 026)

EXACT SPECIFICATIONS & ARCHITECTURAL RULES ENFORCED:
1. teachers_schema.teacher_leave_allowance (80 rows)
   - Rule: "every leave type 12 allowance to use for the teacher for an academic year wise"
   - sick_total_days = 12.0, casual_total_days = 12.0, privilege_total_days = 12.0,
     on_duty_total_days = 12.0, compensatory_total_days = 12.0 for all 80 active teachers.
   - Synchronized used days (sick_used_days, casual_used_days, etc.) strictly matching approved leave applications.
   - Persisted computed columns automatically evaluate remaining days = (12.0 - used_days).

2. teachers_schema.teacher_leave_application (20 rows)
   - Sourced directly from October 2026 past instructional dates in management_schema.timetable_period.
   - Accurately mapped to students & sections: Section 1 (Students 1..10 in Room-01), Section 2 (Students 11..20 in Room-02),
     and Section 21 (Students 201..210 in Room-21).
   - Covers all 5 leave types: SICK, CASUAL, PRIVILEGE, ON_DUTY, COMPENSATORY.
   - Covers FULL_DAY (>= 1.0 day) and HALF_DAY (0.5 day with start_date = end_date).
   - Zero overlapping active leaves per teacher.

3. teachers_schema.teacher_leave_status_history (20 rows - EXACT 1:1 MAPPING)
   - Rule: Exactly ONE row per leave application.
   - If status was updated, old_status holds the prior state and new_status holds the current updated state.
   - If status is PENDING (initial submission), old_status is NULL and new_status is PENDING.
   - Audited by verified tenant users (Teacher user_id = teacher_id + 100 or Principal user_id = 3/4).

4. teachers_schema.teacher_grievance (12 rows)
   - Covers all 6 categories: ACADEMIC_POLICY, INFRASTRUCTURE_FACILITIES,
     HARASSMENT_SAFEGUARDING, IT_EQUIPMENT, ADMINISTRATIVE_PAYROLL, HEALTH_SAFETY.
   - Covers all 4 priorities: LOW, MEDIUM, HIGH, URGENT.
   - Covers all statuses: RESOLVED, CLOSED, UNDER_REVIEW, OPEN, REJECTED.
   - Incident dates strictly match past timetable teaching dates (October 2026).
   - Incident locations match timetable classrooms (Room-01, Room-21), Science/Computer labs, and campus facilities.
   - Assigned to verified tenant administrators: Central Principal (user_id = 3), North Principal (user_id = 4), Admin (user_id = 1).

5. teachers_schema.teacher_grievance_status_history (12 rows - EXACT 1:1 MAPPING)
   - Rule: Exactly ONE row per grievance ticket.
   - If status was updated, old_status holds the prior state and new_status holds the current updated state:
     * RESOLVED: old_status = 'UNDER_REVIEW', new_status = 'RESOLVED'
     * CLOSED:   old_status = 'RESOLVED',     new_status = 'CLOSED'
     * UNDER_REVIEW: old_status = 'OPEN',     new_status = 'UNDER_REVIEW'
     * REJECTED: old_status = 'UNDER_REVIEW', new_status = 'REJECTED'
     * OPEN:     old_status = NULL,           new_status = 'OPEN'
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================================';
PRINT N'STARTING EXECUTION: 020_teacher_leave_and_grievance_mock_data.sql';
PRINT N'Target: Thinkigen School ERP - Teacher Portal Management';
PRINT N'Scope: school_id = 1, branch_id IN (1, 2), academic_year_id = 1';
PRINT N'Rule 1: 12.0 total days per leave type per teacher for Academic Year 2026-2027';
PRINT N'Rule 2: Exactly 1 row in history table per parent record with (old_status -> new_status)';
PRINT N'Rule 3: Timetable date alignment across students, sections, and faculty';
PRINT N'================================================================================';
GO

-- =============================================================================
-- STEP 0: PREFLIGHT VALIDATION & PREREQUISITE CHECKS
-- =============================================================================
DECLARE @preflight_failed BIT = 0;
DECLARE @err_msg NVARCHAR(MAX) = N'';

IF OBJECT_ID(N'teachers_schema.teacher_leave_allowance', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @err_msg += NCHAR(10) + N'- Missing table: teachers_schema.teacher_leave_allowance';
END;

IF OBJECT_ID(N'teachers_schema.teacher_leave_application', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @err_msg += NCHAR(10) + N'- Missing table: teachers_schema.teacher_leave_application';
END;

IF OBJECT_ID(N'teachers_schema.teacher_leave_status_history', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @err_msg += NCHAR(10) + N'- Missing table: teachers_schema.teacher_leave_status_history';
END;

IF OBJECT_ID(N'teachers_schema.teacher_grievance', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @err_msg += NCHAR(10) + N'- Missing table: teachers_schema.teacher_grievance';
END;

IF OBJECT_ID(N'teachers_schema.teacher_grievance_status_history', N'U') IS NULL
BEGIN
    SET @preflight_failed = 1;
    SET @err_msg += NCHAR(10) + N'- Missing table: teachers_schema.teacher_grievance_status_history';
END;

IF @preflight_failed = 1
BEGIN
    RAISERROR(N'Preflight check failed! Please deploy migration 026_teacher_leave_and_grievance.sql before running mock seeds.%s', 16, 1, @err_msg);
    SET NOEXEC ON;
END
ELSE
BEGIN
    PRINT N'Preflight check passed: All 5 tables verified in teachers_schema.';
END;
GO

BEGIN TRANSACTION;
BEGIN TRY

    -- -------------------------------------------------------------------------
    -- STEP 1: CLEANUP EXISTING MOCK RECORDS (Idempotent Execution)
    -- Respecting FK hierarchy: history -> application/grievance -> allowance
    -- -------------------------------------------------------------------------
    PRINT N'Step 1: Cleaning existing mock records in teachers_schema leave & grievance tables...';

    DELETE FROM teachers_schema.teacher_leave_status_history;
    DELETE FROM teachers_schema.teacher_leave_application;
    DELETE FROM teachers_schema.teacher_leave_allowance;
    DELETE FROM teachers_schema.teacher_grievance_status_history;
    DELETE FROM teachers_schema.teacher_grievance;

    PRINT N'  -> Existing records cleared successfully.';

    -- -------------------------------------------------------------------------
    -- STEP 2: SEED TEACHER LEAVE ALLOWANCE (Rule: 12 days per leave type per teacher)
    -- All 80 active teachers across Central Campus (1..40) and North Campus (41..80)
    -- -------------------------------------------------------------------------
    PRINT N'Step 2: Populating teachers_schema.teacher_leave_allowance with 12.0 days quota...';

    INSERT INTO teachers_schema.teacher_leave_allowance
    (
        school_id, branch_id, academic_year_id, teacher_id,
        sick_total_days, sick_used_days,
        casual_total_days, casual_used_days,
        privilege_total_days, privilege_used_days,
        on_duty_total_days, on_duty_used_days,
        compensatory_total_days, compensatory_used_days,
        is_active, created_at, created_by, updated_at, updated_by
    )
    SELECT
        t.school_id,
        t.branch_id,
        1 AS academic_year_id,
        t.teacher_id,
        12.0 AS sick_total_days,
        0.0  AS sick_used_days,
        12.0 AS casual_total_days,
        0.0  AS casual_used_days,
        12.0 AS privilege_total_days,
        0.0  AS privilege_used_days,
        12.0 AS on_duty_total_days,
        0.0  AS on_duty_used_days,
        12.0 AS compensatory_total_days,
        0.0  AS compensatory_used_days,
        1    AS is_active,
        CAST('2026-04-01 08:00:00' AS DATETIME2(0)) AS created_at,
        1    AS created_by,
        CAST('2026-10-31 08:00:00' AS DATETIME2(0)) AS updated_at,
        1    AS updated_by
    FROM teachers_schema.teacher t
    WHERE t.is_active = 1
    ORDER BY t.teacher_id;

    PRINT CONCAT(N'  -> Seeded ', @@ROWCOUNT, N' teacher leave allowance records with 12.0 total days across all 5 categories.');

    -- -------------------------------------------------------------------------
    -- STEP 3: SEED TEACHER LEAVE APPLICATIONS (Derived from Timetable past dates)
    -- Past dates from October 2026 timetable periods.
    -- Strict constraints:
    --   - HALF_DAY: start_date = end_date AND total_days = 0.5
    --   - FULL_DAY: total_days >= 1.0 AND end_date >= start_date
    --   - Zero overlaps per teacher
    -- -------------------------------------------------------------------------
    PRINT N'Step 3: Populating teachers_schema.teacher_leave_application based on past timetable dates...';

    SET IDENTITY_INSERT teachers_schema.teacher_leave_application ON;

    INSERT INTO teachers_schema.teacher_leave_application
    (
        teacher_leave_application_id,
        school_id, branch_id, academic_year_id, teacher_id,
        leave_type, leave_duration_type, start_date, end_date,
        total_days, reason, status, is_active,
        created_at, created_by, updated_at, updated_by
    )
    VALUES
    -- [Central Campus - Branch 1]
    -- 1. Teacher 1 (Keshav Kulkarni - English HOD): Full Day Casual Leave
    (
        1, 1, 1, 1, 1,
        'CASUAL', 'FULL_DAY', '2026-10-08', '2026-10-08', 1.0,
        N'Attending family engagement ceremony; Section 1 (Class 1 Sec A) Period 1 English substitution assigned to Teacher 2 Radhika Pillai.',
        N'APPROVED', 1,
        CAST('2026-10-06 09:30:00' AS DATETIME2(0)), 101,
        CAST('2026-10-06 14:15:00' AS DATETIME2(0)), 3
    ),
    -- 2. Teacher 8 (Zara Pai - Math HOD): 2-Day On Duty Leave
    (
        2, 1, 1, 1, 8,
        'ON_DUTY', 'FULL_DAY', '2026-10-15', '2026-10-16', 2.0,
        N'Deputed for CBSE Regional Mathematics Olympiad Coordination at State Board Center; Section 1 Period 2 Math covered by Teacher 9 Utkarsh Mishra.',
        N'APPROVED', 1,
        CAST('2026-10-12 10:00:00' AS DATETIME2(0)), 108,
        CAST('2026-10-12 16:30:00' AS DATETIME2(0)), 3
    ),
    -- 3. Teacher 15 (Bhuvan Solanki - Science HOD): Half Day Medical Leave
    (
        3, 1, 1, 1, 15,
        'SICK', 'HALF_DAY', '2026-10-21', '2026-10-21', 0.5,
        N'Dental appointment and procedure during afternoon session; Section 1 morning Period 4 Science laboratory in Room-01 conducted as scheduled.',
        N'APPROVED', 1,
        CAST('2026-10-20 08:30:00' AS DATETIME2(0)), 115,
        CAST('2026-10-20 11:00:00' AS DATETIME2(0)), 3
    ),
    -- 4. Teacher 22 (Rashmi Chopra - Social Science HOD): 2-Day Sick Leave
    (
        4, 1, 1, 1, 22,
        'SICK', 'FULL_DAY', '2026-10-12', '2026-10-13', 2.0,
        N'Severe seasonal viral fever and acute throat infection; medical prescription submitted; Section 1 Period 5 Social Science covered by Teacher 23 Kushagra Kapoor.',
        N'APPROVED', 1,
        CAST('2026-10-11 18:00:00' AS DATETIME2(0)), 122,
        CAST('2026-10-12 08:15:00' AS DATETIME2(0)), 3
    ),
    -- 5. Teacher 29 (Raghunath Mathur - Computer Science HOD): 1-Day Compensatory Leave
    (
        5, 1, 1, 1, 29,
        'COMPENSATORY', 'FULL_DAY', '2026-10-26', '2026-10-26', 1.0,
        N'Compensatory off for Sunday duties on 2026-10-18 managing the National Cyber Olympiad online server testing in Computer Lab 1.',
        N'APPROVED', 1,
        CAST('2026-10-22 11:00:00' AS DATETIME2(0)), 129,
        CAST('2026-10-23 15:00:00' AS DATETIME2(0)), 3
    ),
    -- 6. Teacher 35 (Abhiram Kansal - Physical Ed Director): 2-Day On Duty Leave
    (
        6, 1, 1, 1, 35,
        'ON_DUTY', 'FULL_DAY', '2026-10-23', '2026-10-24', 2.0,
        N'Escorting school football team for Inter-School Zonal Sports Tournament at District Stadium; Section 1 Period 8 PE sports drills supervised by Teacher 36 Jaya Khatri.',
        N'APPROVED', 1,
        CAST('2026-10-19 14:00:00' AS DATETIME2(0)), 135,
        CAST('2026-10-20 09:30:00' AS DATETIME2(0)), 3
    ),
    -- 7. Teacher 2 (Radhika Pillai - Senior English Faculty): 3-Day Privilege Leave
    (
        7, 1, 1, 1, 2,
        'PRIVILEGE', 'FULL_DAY', '2026-10-27', '2026-10-29', 3.0,
        N'Availing earned privilege leave for daughter convocation ceremony out of state; Section 2 (Class 1 Sec B) English syllabus covered in advance.',
        N'APPROVED', 1,
        CAST('2026-10-15 10:00:00' AS DATETIME2(0)), 102,
        CAST('2026-10-16 11:30:00' AS DATETIME2(0)), 3
    ),
    -- 8. Teacher 9 (Utkarsh Mishra - Senior Math Faculty): Rejected Casual Leave
    (
        8, 1, 1, 1, 9,
        'CASUAL', 'FULL_DAY', '2026-10-14', '2026-10-14', 1.0,
        N'Urgent personal banking and property documentation work.',
        N'REJECTED', 1,
        CAST('2026-10-13 16:00:00' AS DATETIME2(0)), 109,
        CAST('2026-10-14 08:00:00' AS DATETIME2(0)), 3
    ),
    -- 9. Teacher 16 (Juhi Rajput - Senior Science Teacher): Cancelled Casual Leave
    (
        9, 1, 1, 1, 16,
        'CASUAL', 'FULL_DAY', '2026-10-28', '2026-10-28', 1.0,
        N'Personal appointment at passport seva kendra (appointment subsequently postponed by authority).',
        N'CANCELLED', 1,
        CAST('2026-10-25 10:00:00' AS DATETIME2(0)), 116,
        CAST('2026-10-27 16:00:00' AS DATETIME2(0)), 116
    ),
    -- 10. Teacher 4 (Tara Mishra - Senior English Faculty): 1-Day Sick Leave
    (
        10, 1, 1, 1, 4,
        'SICK', 'FULL_DAY', '2026-10-26', '2026-10-26', 1.0,
        N'Severe migraine headache and medical checkup; timetable period covered by department colleague.',
        N'APPROVED', 1,
        CAST('2026-10-26 07:30:00' AS DATETIME2(0)), 104,
        CAST('2026-10-26 08:15:00' AS DATETIME2(0)), 3
    ),
    -- 11. Teacher 11 (Wahid Dubey - Senior Math Faculty): Half Day Casual Leave
    (
        11, 1, 1, 1, 11,
        'CASUAL', 'HALF_DAY', '2026-10-29', '2026-10-29', 0.5,
        N'Attending municipal property tax assessment meeting in afternoon session; morning Math class conducted.',
        N'APPROVED', 1,
        CAST('2026-10-28 14:00:00' AS DATETIME2(0)), 111,
        CAST('2026-10-28 17:00:00' AS DATETIME2(0)), 3
    ),
    -- 12. Teacher 17 (Devesh Saini - Senior Science Teacher): Compensatory Leave
    (
        12, 1, 1, 1, 17,
        'COMPENSATORY', 'FULL_DAY', '2026-10-30', '2026-10-30', 1.0,
        N'Compensatory off for supervising Saturday inter-school science exhibition laboratory setup on 2026-10-17.',
        N'APPROVED', 1,
        CAST('2026-10-28 11:00:00' AS DATETIME2(0)), 117,
        CAST('2026-10-29 09:30:00' AS DATETIME2(0)), 3
    ),
    -- 13. Teacher 23 (Kushagra Kapoor - Social Science Specialist): 2-Day Privilege Leave
    (
        13, 1, 1, 1, 23,
        'PRIVILEGE', 'FULL_DAY', '2026-10-19', '2026-10-20', 2.0,
        N'Family pilgrimage travel; Social Science scheduled topics assigned to Section 2 specialist.',
        N'APPROVED', 1,
        CAST('2026-10-10 11:00:00' AS DATETIME2(0)), 123,
        CAST('2026-10-12 14:00:00' AS DATETIME2(0)), 3
    ),
    -- 14. Teacher 30 (Chitra Nigam - Computer Science Instructor): Pending Casual Leave
    (
        14, 1, 1, 1, 30,
        'CASUAL', 'FULL_DAY', '2026-10-30', '2026-10-30', 1.0,
        N'Attending sister engagement ceremony out of station; Period 7 Computer Lab substitute requested.',
        N'PENDING', 1,
        CAST('2026-10-29 16:30:00' AS DATETIME2(0)), 130,
        CAST('2026-10-29 16:30:00' AS DATETIME2(0)), 130
    ),

    -- [North Campus - Branch 2]
    -- 15. Teacher 41 (Hemant Mehra - English HOD): Full Day Casual Leave
    (
        15, 1, 2, 1, 41,
        'CASUAL', 'FULL_DAY', '2026-10-09', '2026-10-09', 1.0,
        N'Personal urgent domestic repairs; Section 21 (Class 11 Sec A in Room-21) Period 1 English substitution assigned to Teacher 42 Rekha Madan.',
        N'APPROVED', 1,
        CAST('2026-10-07 10:00:00' AS DATETIME2(0)), 141,
        CAST('2026-10-07 15:00:00' AS DATETIME2(0)), 4
    ),
    -- 16. Teacher 48 (Archana Krishnan - Math HOD): 2-Day Sick Leave
    (
        16, 1, 2, 1, 48,
        'SICK', 'FULL_DAY', '2026-10-19', '2026-10-20', 2.0,
        N'Acute gastroenteritis and dehydration; prescribed 48-hour bed rest; Section 21 Period 2 Math covered by Teacher 49 Rajesh Narayanan.',
        N'APPROVED', 1,
        CAST('2026-10-18 20:00:00' AS DATETIME2(0)), 148,
        CAST('2026-10-19 08:00:00' AS DATETIME2(0)), 4
    ),
    -- 17. Teacher 55 (Ansh Gautam - Science HOD): 1-Day On Duty Leave
    (
        17, 1, 2, 1, 55,
        'ON_DUTY', 'FULL_DAY', '2026-10-22', '2026-10-22', 1.0,
        N'State Science Congress teacher seminar on Innovative STEM Pedagogy and Lab Safety at State Science Centre; Section 21 Science covered.',
        N'APPROVED', 1,
        CAST('2026-10-18 11:00:00' AS DATETIME2(0)), 155,
        CAST('2026-10-19 12:00:00' AS DATETIME2(0)), 4
    ),
    -- 18. Teacher 62 (Kiran Sanyal - Social Science HOD): Half Day Casual Leave
    (
        18, 1, 2, 1, 62,
        'CASUAL', 'HALF_DAY', '2026-10-26', '2026-10-26', 0.5,
        N'Attending son school parent-teacher consultation meeting in morning session; Section 21 afternoon periods conducted as per timetable.',
        N'APPROVED', 1,
        CAST('2026-10-24 11:30:00' AS DATETIME2(0)), 162,
        CAST('2026-10-24 16:00:00' AS DATETIME2(0)), 4
    ),
    -- 19. Teacher 69 (Karan Joshi - Computer Science HOD): Compensatory Leave
    (
        19, 1, 2, 1, 69,
        'COMPENSATORY', 'FULL_DAY', '2026-10-27', '2026-10-27', 1.0,
        N'Compensatory leave for weekend network infrastructure upgrade and server migration on Saturday & Sunday in Computer Lab 2.',
        N'APPROVED', 1,
        CAST('2026-10-25 12:00:00' AS DATETIME2(0)), 169,
        CAST('2026-10-26 10:00:00' AS DATETIME2(0)), 4
    ),
    -- 20. Teacher 75 (Mukul Ghosh - Physical Ed Director): 2-Day On Duty Leave
    (
        20, 1, 2, 1, 75,
        'ON_DUTY', 'FULL_DAY', '2026-10-16', '2026-10-17', 2.0,
        N'Officiating referee at Regional CBSE Athletics Meet at District Sports Complex; Section 21 PE supervised by Teacher 76 Neelam Menon.',
        N'APPROVED', 1,
        CAST('2026-10-12 15:00:00' AS DATETIME2(0)), 175,
        CAST('2026-10-13 10:00:00' AS DATETIME2(0)), 4
    );

    SET IDENTITY_INSERT teachers_schema.teacher_leave_application OFF;

    PRINT CONCAT(N'  -> Seeded ', @@ROWCOUNT, N' teacher leave applications across past timetable dates.');

    -- -------------------------------------------------------------------------
    -- STEP 4: SEED TEACHER LEAVE STATUS HISTORY (Strict 1:1 Mapping Rule)
    -- Exactly ONE row per leave application.
    -- If status was updated, old_status is the prior status and new_status is the updated status.
    -- -------------------------------------------------------------------------
    PRINT N'Step 4: Populating teachers_schema.teacher_leave_status_history (1:1 per leave application)...';

    SET IDENTITY_INSERT teachers_schema.teacher_leave_status_history ON;

    INSERT INTO teachers_schema.teacher_leave_status_history
    (
        teacher_leave_status_history_id,
        teacher_leave_application_id, old_status, new_status,
        changed_by, changed_at, remarks
    )
    VALUES
    -- App 1: Updated PENDING -> APPROVED
    (1, 1, N'PENDING', N'APPROVED', 3, '2026-10-06 14:15:00', N'Leave sanctioned by Central Campus Principal. Section 1 Period 1 substitute confirmed.'),

    -- App 2: Updated PENDING -> APPROVED
    (2, 2, N'PENDING', N'APPROVED', 3, '2026-10-12 16:30:00', N'CBSE deputation approved. Section 1 Period 2 Math coordination verified.'),

    -- App 3: Updated PENDING -> APPROVED
    (3, 3, N'PENDING', N'APPROVED', 3, '2026-10-20 11:00:00', N'Approved for afternoon half-day session. Morning Period 4 practicals completed.'),

    -- App 4: Updated PENDING -> APPROVED
    (4, 4, N'PENDING', N'APPROVED', 3, '2026-10-12 08:15:00', N'Medical leave granted. Section 1 Period 5 coverage arranged with Teacher 23.'),

    -- App 5: Updated PENDING -> APPROVED
    (5, 5, N'PENDING', N'APPROVED', 3, '2026-10-23 15:00:00', N'Compensatory off verified against biometric overtime log and approved.'),

    -- App 6: Updated PENDING -> APPROVED
    (6, 6, N'PENDING', N'APPROVED', 3, '2026-10-20 09:30:00', N'Sports escort OD sanctioned. Section 1 PE covered by Teacher 36.'),

    -- App 7: Updated PENDING -> APPROVED
    (7, 7, N'PENDING', N'APPROVED', 3, '2026-10-16 11:30:00', N'Privilege leave sanctioned as per staff service entitlement regulations.'),

    -- App 8: Updated PENDING -> REJECTED
    (8, 8, N'PENDING', N'REJECTED', 3, '2026-10-14 08:00:00', N'Leave rejected: Prior scheduled assessment invigilation duty during Period 2 & 4.'),

    -- App 9: Updated APPROVED -> CANCELLED
    (9, 9, N'APPROVED', N'CANCELLED', 116, '2026-10-27 16:00:00', N'Leave cancelled by faculty: Passport appointment rescheduled to November.'),

    -- App 10: Updated PENDING -> APPROVED
    (10, 10, N'PENDING', N'APPROVED', 3, '2026-10-26 08:15:00', N'Approved. Period 1 English class reassigned.'),

    -- App 11: Updated PENDING -> APPROVED
    (11, 11, N'PENDING', N'APPROVED', 3, '2026-10-28 17:00:00', N'Approved for afternoon half-day.'),

    -- App 12: Updated PENDING -> APPROVED
    (12, 12, N'PENDING', N'APPROVED', 3, '2026-10-29 09:30:00', N'Verified with Science Department Head. Compensatory leave approved.'),

    -- App 13: Updated PENDING -> APPROVED
    (13, 13, N'PENDING', N'APPROVED', 3, '2026-10-12 14:00:00', N'Privilege leave sanctioned.'),

    -- App 14: Initial PENDING (not yet updated)
    (14, 14, NULL, N'PENDING', 130, '2026-10-29 16:30:00', N'Leave application submitted via teacher portal. Under review by Principal.'),

    -- App 15: Updated PENDING -> APPROVED
    (15, 15, N'PENDING', N'APPROVED', 4, '2026-10-07 15:00:00', N'Sanctioned by North Campus Principal Mrs. Sunita Rao.'),

    -- App 16: Updated PENDING -> APPROVED
    (16, 16, N'PENDING', N'APPROVED', 4, '2026-10-19 08:00:00', N'Medical leave approved for 2 days. Section 21 covered.'),

    -- App 17: Updated PENDING -> APPROVED
    (17, 17, N'PENDING', N'APPROVED', 4, '2026-10-19 12:00:00', N'OD sanctioned under North Campus professional development quota.'),

    -- App 18: Updated PENDING -> APPROVED
    (18, 18, N'PENDING', N'APPROVED', 4, '2026-10-24 16:00:00', N'Approved for morning half-day.'),

    -- App 19: Updated PENDING -> APPROVED
    (19, 19, N'PENDING', N'APPROVED', 4, '2026-10-26 10:00:00', N'Server migration duty confirmed. Compensatory off sanctioned.'),

    -- App 20: Updated PENDING -> APPROVED
    (20, 20, N'PENDING', N'APPROVED', 4, '2026-10-13 10:00:00', N'Approved under sports officiating duty quota.');

    SET IDENTITY_INSERT teachers_schema.teacher_leave_status_history OFF;

    PRINT CONCAT(N'  -> Seeded ', @@ROWCOUNT, N' teacher leave status history records (Exact 1:1 mapping with applications).');

    -- -------------------------------------------------------------------------
    -- STEP 5: SYNCHRONIZE TEACHER LEAVE ALLOWANCE USED DAYS
    -- Matches exact SUM of APPROVED applications per teacher and leave type.
    -- Persisted computed columns automatically update remaining balance!
    -- -------------------------------------------------------------------------
    PRINT N'Step 5: Synchronizing teacher_leave_allowance used_days with approved applications...';

    UPDATE tla
    SET
        tla.sick_used_days = COALESCE(app.sick_used, 0.0),
        tla.casual_used_days = COALESCE(app.casual_used, 0.0),
        tla.privilege_used_days = COALESCE(app.privilege_used, 0.0),
        tla.on_duty_used_days = COALESCE(app.onduty_used, 0.0),
        tla.compensatory_used_days = COALESCE(app.comp_used, 0.0),
        tla.updated_at = CAST('2026-10-31 09:00:00' AS DATETIME2(0)),
        tla.updated_by = 1
    FROM teachers_schema.teacher_leave_allowance tla
    LEFT JOIN (
        SELECT
            teacher_id,
            SUM(CASE WHEN leave_type = 'SICK' THEN total_days ELSE 0.0 END) AS sick_used,
            SUM(CASE WHEN leave_type = 'CASUAL' THEN total_days ELSE 0.0 END) AS casual_used,
            SUM(CASE WHEN leave_type = 'PRIVILEGE' THEN total_days ELSE 0.0 END) AS privilege_used,
            SUM(CASE WHEN leave_type = 'ON_DUTY' THEN total_days ELSE 0.0 END) AS onduty_used,
            SUM(CASE WHEN leave_type = 'COMPENSATORY' THEN total_days ELSE 0.0 END) AS comp_used
        FROM teachers_schema.teacher_leave_application
        WHERE status = N'APPROVED'
        GROUP BY teacher_id
    ) app ON app.teacher_id = tla.teacher_id
    WHERE tla.academic_year_id = 1;

    PRINT N'  -> Allowance used days synchronized. Persisted remaining days automatically recomputed.';

    -- -------------------------------------------------------------------------
    -- STEP 6: SEED TEACHER GRIEVANCE (Derived from Timetable incidents & locations)
    -- Covers all 6 categories, 4 priorities, and 5 statuses.
    -- Locations match timetable classrooms, science/computer labs, campus facilities.
    -- -------------------------------------------------------------------------
    PRINT N'Step 6: Populating teachers_schema.teacher_grievance based on timetable classroom & lab incidents...';

    SET IDENTITY_INSERT teachers_schema.teacher_grievance ON;

    INSERT INTO teachers_schema.teacher_grievance
    (
        teacher_grievance_id,
        school_id, branch_id, academic_year_id, teacher_id,
        grievance_title, grievance_category, priority,
        incident_date, incident_location, description,
        status, assigned_to, resolution_remarks, is_active,
        created_at, created_by, updated_at, updated_by
    )
    VALUES
    -- 1. IT_EQUIPMENT (Teacher 8 - Central Math HOD)
    (
        1, 1, 1, 1, 8,
        N'Interactive SmartBoard HDMI and touch display failure in Room-01',
        'IT_EQUIPMENT', 'HIGH',
        '2026-10-06', N'Room-01 (Class 1 Section A)',
        N'During Period 2 Mathematics class on 2026-10-06 for Section 1 (Students 1..10), the interactive touch screen disconnected repeatedly and projector HDMI threw signal errors during Linear Equations interactive geometry exercise, interrupting student instruction.',
        N'RESOLVED', 3,
        N'IT engineer replaced the faulty HDMI 2.1 cable and re-calibrated the interactive touch sensor on 2026-10-07. Verified operational with faculty.',
        1,
        CAST('2026-10-06 11:00:00' AS DATETIME2(0)), 108,
        CAST('2026-10-07 16:30:00' AS DATETIME2(0)), 3
    ),

    -- 2. HEALTH_SAFETY (Teacher 15 - Central Science HOD)
    (
        2, 1, 1, 1, 15,
        N'Malfunctioning fume extraction hood in Chemistry Laboratory',
        'HEALTH_SAFETY', 'URGENT',
        '2026-10-09', N'Chemistry Laboratory (Central Campus)',
        N'During Period 4 Science practicals on 2026-10-09 with Section 1 students, the exhaust blower in the chemical preparation fume hood produced abnormal vibrations and failed to vent chemical fumes safely, posing health risks to students and staff.',
        N'RESOLVED', 3,
        N'Maintenance team repaired the exhaust motor bearing and replaced the HEPA filter on 2026-10-11. Airflow safety check passed 100%.',
        1,
        CAST('2026-10-09 12:15:00' AS DATETIME2(0)), 115,
        CAST('2026-10-11 15:00:00' AS DATETIME2(0)), 3
    ),

    -- 3. INFRASTRUCTURE_FACILITIES (Teacher 48 - North Math HOD)
    (
        3, 1, 2, 1, 48,
        N'Ceiling water leakage and lighting disruption near whiteboard in Room-21',
        'INFRASTRUCTURE_FACILITIES', 'HIGH',
        '2026-10-14', N'Room-21 (North Campus Class 11 Sec A)',
        N'Post continuous rainfall on 2026-10-14, rainwater seeped through the ceiling joint directly above the teacher podium and short-circuited the front tube lights, compromising teaching visibility for Section 21 during Period 1 and Period 2.',
        N'RESOLVED', 4,
        N'Civil contractor sealed the roof slab joint and facility electrician rewired the LED batten lights. Completed on 2026-10-16.',
        1,
        CAST('2026-10-14 10:30:00' AS DATETIME2(0)), 148,
        CAST('2026-10-16 17:00:00' AS DATETIME2(0)), 4
    ),

    -- 4. ADMINISTRATIVE_PAYROLL (Teacher 29 - Central CS HOD)
    (
        4, 1, 1, 1, 29,
        N'Discrepancy in monthly special duty allowance for Cyber Olympiad supervision',
        'ADMINISTRATIVE_PAYROLL', 'MEDIUM',
        '2026-10-20', N'Central Campus Administration Office',
        N'The special duty allowance sanctioned for conducting the National Cyber Olympiad online mock sessions over two weekends was missing from the September payroll disbursement slip.',
        N'RESOLVED', 1,
        N'Accounts department verified the weekend attendance sheet approved by Principal. Arrear amount credited to October payroll cycle.',
        1,
        CAST('2026-10-20 14:00:00' AS DATETIME2(0)), 129,
        CAST('2026-10-22 16:00:00' AS DATETIME2(0)), 1
    ),

    -- 5. ACADEMIC_POLICY (Teacher 1 - Central English HOD)
    (
        5, 1, 1, 1, 1,
        N'Curriculum pacing discrepancy between syllabus blueprint and term exam schedule',
        'ACADEMIC_POLICY', 'MEDIUM',
        '2026-10-16', N'Staff Conference Hall (Central Campus)',
        N'The updated CBSE term examination blueprint for Class 9 and 10 English Literature includes three prose chapters not scheduled for completion until November Week 2, causing syllabus coverage stress.',
        N'CLOSED', 3,
        N'Academic council met on 2026-10-18 and issued revised circular #AC/2026/102 adjusting test portion boundaries for Term-1 to covered chapters only.',
        1,
        CAST('2026-10-16 16:30:00' AS DATETIME2(0)), 101,
        CAST('2026-10-19 11:00:00' AS DATETIME2(0)), 101
    ),

    -- 6. HARASSMENT_SAFEGUARDING (Teacher 44 - North Senior English Faculty)
    (
        6, 1, 2, 1, 44,
        N'Inappropriate conduct and verbal hostility by external vendor delivery personnel',
        'HARASSMENT_SAFEGUARDING', 'HIGH',
        '2026-10-22', N'North Campus Main Gate & Administration Block',
        N'On 2026-10-22 at 13:45 during lunch break, an external stationery delivery driver behaved belligerently and used aggressive language towards staff members when asked to register his vehicle at the security gate.',
        N'CLOSED', 4,
        N'Vendor management summoned by Principal. Driver blacklisted from school premises permanently. Vendor issued formal written apology.',
        1,
        CAST('2026-10-22 15:00:00' AS DATETIME2(0)), 144,
        CAST('2026-10-24 10:00:00' AS DATETIME2(0)), 144
    ),

    -- 7. IT_EQUIPMENT (Teacher 69 - North CS HOD)
    (
        7, 1, 2, 1, 69,
        N'Network switch port flapping causing intermittent internet failure in Computer Lab 2',
        'IT_EQUIPMENT', 'MEDIUM',
        '2026-10-27', N'Computer Lab 2 (North Campus)',
        N'During Period 5 Computer Science Python practicals on 2026-10-27 with Section 21 students, 15 desktop terminals lost connection to the school local code repository due to constant port flapping on Switch-02 rack.',
        N'UNDER_REVIEW', 4,
        NULL,
        1,
        CAST('2026-10-27 15:30:00' AS DATETIME2(0)), 169,
        CAST('2026-10-28 09:30:00' AS DATETIME2(0)), 4
    ),

    -- 8. INFRASTRUCTURE_FACILITIES (Teacher 35 - Central PE Director)
    (
        8, 1, 1, 1, 35,
        N'Broken perimeter chain-link fence near athletic track adjacent to public road',
        'INFRASTRUCTURE_FACILITIES', 'HIGH',
        '2026-10-23', N'Central Campus Athletic Track & Football Field',
        N'A 10-foot section of the boundary fencing behind the long-jump pit was damaged due to a fallen tree branch during high winds, compromising campus perimeter security during outdoor PE classes.',
        N'RESOLVED', 3,
        N'Estate maintenance team cleared the fallen branch, replaced damaged fence posts, and reinforced the wire mesh on 2026-10-25.',
        1,
        CAST('2026-10-23 16:00:00' AS DATETIME2(0)), 135,
        CAST('2026-10-25 15:00:00' AS DATETIME2(0)), 3
    ),

    -- 9. HEALTH_SAFETY (Teacher 22 - Central Social Science HOD)
    (
        9, 1, 1, 1, 22,
        N'Expired fire extinguisher pressure cylinder in First Floor Social Science Corridor',
        'HEALTH_SAFETY', 'URGENT',
        '2026-10-28', N'Academic Block A, 1st Floor Corridor (Rooms 01-08)',
        N'During routine safety drill preparation on 2026-10-28, the ABC Dry Powder fire extinguisher near Room-04 was observed with pressure gauge in the red zone and inspection tag expired.',
        N'OPEN', 3,
        NULL,
        1,
        CAST('2026-10-28 12:00:00' AS DATETIME2(0)), 122,
        CAST('2026-10-28 12:00:00' AS DATETIME2(0)), 122
    ),

    -- 10. ACADEMIC_POLICY (Teacher 55 - North Science HOD)
    (
        10, 1, 2, 1, 55,
        N'Insufficient allocation of weekly practical hours for Grade 10 Physics',
        'ACADEMIC_POLICY', 'LOW',
        '2026-10-15', N'North Campus Senior Staff Room',
        N'The current timetable provides only 1 lab session per section per fortnight for Physics practicals, making it difficult to complete all mandatory CBSE experiments before the practical board assessments.',
        N'REJECTED', 4,
        N'Timetable committee reviewed the schedule. Additional lab access slots have been opened on zero-period Saturdays. Separate formal curriculum increase cannot be accommodated in regular weekday grid.',
        1,
        CAST('2026-10-15 14:00:00' AS DATETIME2(0)), 155,
        CAST('2026-10-18 16:00:00' AS DATETIME2(0)), 4
    ),

    -- 11. INFRASTRUCTURE_FACILITIES (Teacher 3 - Central Senior English)
    (
        11, 1, 1, 1, 3,
        N'Acoustic echo and defective microphone in Auditorium Hall during inter-school debate',
        'INFRASTRUCTURE_FACILITIES', 'LOW',
        '2026-10-24', N'Main Auditorium (Central Campus)',
        N'During the Saturday Inter-House Debate competition on 2026-10-24, podium microphone 2 suffered feedback squeal and excessive acoustic reverberation.',
        N'RESOLVED', 3,
        N'Audio technician adjusted the mixer gain profiles and replaced the UHF wireless mic capsule on 2026-10-26.',
        1,
        CAST('2026-10-24 16:00:00' AS DATETIME2(0)), 103,
        CAST('2026-10-26 12:00:00' AS DATETIME2(0)), 3
    ),

    -- 12. IT_EQUIPMENT (Teacher 71 - North Computer Science Instructor)
    (
        12, 1, 2, 1, 71,
        N'Laser printer paper jam sensor failure in North Campus Staff Workstation',
        'IT_EQUIPMENT', 'LOW',
        '2026-10-29', N'North Campus Faculty Staff Room',
        N'The shared HP LaserJet MFP in the teachers preparation room frequently signals false paper jams, halting exam worksheet printing for Periods 1 & 2.',
        N'OPEN', 4,
        NULL,
        1,
        CAST('2026-10-29 11:30:00' AS DATETIME2(0)), 171,
        CAST('2026-10-29 11:30:00' AS DATETIME2(0)), 171
    );

    SET IDENTITY_INSERT teachers_schema.teacher_grievance OFF;

    PRINT CONCAT(N'  -> Seeded ', @@ROWCOUNT, N' teacher grievance tickets across all 6 categories.');

    -- -------------------------------------------------------------------------
    -- STEP 7: SEED TEACHER GRIEVANCE STATUS HISTORY (Strict 1:1 Mapping Rule)
    -- Exactly ONE row per grievance ticket.
    -- If status was updated, old_status holds the prior state and new_status holds the current updated state.
    -- -------------------------------------------------------------------------
    PRINT N'Step 7: Populating teachers_schema.teacher_grievance_status_history (1:1 per grievance)...';

    SET IDENTITY_INSERT teachers_schema.teacher_grievance_status_history ON;

    INSERT INTO teachers_schema.teacher_grievance_status_history
    (
        teacher_grievance_status_history_id,
        teacher_grievance_id, old_status, new_status,
        changed_by, changed_at, remarks
    )
    VALUES
    -- Grievance 1: Updated UNDER_REVIEW -> RESOLVED
    (1, 1, N'UNDER_REVIEW', N'RESOLVED', 3, '2026-10-07 16:30:00', N'Cable replaced, HDMI signal locked at 4K@60Hz, and interactive pen re-paired.'),

    -- Grievance 2: Updated UNDER_REVIEW -> RESOLVED
    (2, 2, N'UNDER_REVIEW', N'RESOLVED', 3, '2026-10-11 15:00:00', N'Blower motor overhauled, new carbon filters installed, safety certification signed.'),

    -- Grievance 3: Updated UNDER_REVIEW -> RESOLVED
    (3, 3, N'UNDER_REVIEW', N'RESOLVED', 4, '2026-10-16 17:00:00', N'Waterproofing polymer coat applied on roof; front electrical conduit re-insulated.'),

    -- Grievance 4: Updated UNDER_REVIEW -> RESOLVED
    (4, 4, N'UNDER_REVIEW', N'RESOLVED', 1, '2026-10-22 16:00:00', N'Weekend supervision verified. Special allowance voucher approved for October payroll.'),

    -- Grievance 5: Updated RESOLVED -> CLOSED
    (5, 5, N'RESOLVED', N'CLOSED', 101, '2026-10-19 11:00:00', N'Department confirmed circular distributed to all English teachers. Ticket closed.'),

    -- Grievance 6: Updated RESOLVED -> CLOSED
    (6, 6, N'RESOLVED', N'CLOSED', 144, '2026-10-24 10:00:00', N'Staff satisfied with administrative action taken. Ticket closed.'),

    -- Grievance 7: Updated OPEN -> UNDER_REVIEW
    (7, 7, N'OPEN', N'UNDER_REVIEW', 4, '2026-10-28 09:30:00', N'Assigned to Network Administrator. Replacement Cisco 24-port Gigabit switch requisitioned.'),

    -- Grievance 8: Updated UNDER_REVIEW -> RESOLVED
    (8, 8, N'UNDER_REVIEW', N'RESOLVED', 3, '2026-10-25 15:00:00', N'New galvanized steel chain-link section installed and concrete base fortified.'),

    -- Grievance 9: Initial OPEN (not yet updated)
    (9, 9, NULL, N'OPEN', 122, '2026-10-28 12:00:00', N'Urgent health & safety report submitted for expired corridor fire extinguisher.'),

    -- Grievance 10: Updated UNDER_REVIEW -> REJECTED
    (10, 10, N'UNDER_REVIEW', N'REJECTED', 4, '2026-10-18 16:00:00', N'Rejected for regular schedule: Saturday zero-period lab access provided as workaround.'),

    -- Grievance 11: Updated UNDER_REVIEW -> RESOLVED
    (11, 11, N'UNDER_REVIEW', N'RESOLVED', 3, '2026-10-26 12:00:00', N'Equalizer profile re-tuned for auditorium acoustic dampening; mic capsule replaced.'),

    -- Grievance 12: Initial OPEN (not yet updated)
    (12, 12, NULL, N'OPEN', 171, '2026-10-29 11:30:00', N'Staff room printer hardware fault logged.');

    SET IDENTITY_INSERT teachers_schema.teacher_grievance_status_history OFF;

    PRINT CONCAT(N'  -> Seeded ', @@ROWCOUNT, N' teacher grievance status history records (Exact 1:1 mapping with tickets).');

    -- -------------------------------------------------------------------------
    -- STEP 8: DATA INTEGRITY & AUDIT VERIFICATION
    -- -------------------------------------------------------------------------
    PRINT N'Step 8: Performing post-seed integrity verification...';

    -- 8.1 Allowance count check
    DECLARE @allowance_count INT;
    SELECT @allowance_count = COUNT(*) FROM teachers_schema.teacher_leave_allowance;
    IF @allowance_count <> 80
        THROW 50001, N'Verification failed: Expected exactly 80 rows in teacher_leave_allowance.', 1;

    -- 8.2 Computed remaining days check
    IF EXISTS (
        SELECT 1 FROM teachers_schema.teacher_leave_allowance
        WHERE sick_remaining_days <> (sick_total_days - sick_used_days)
           OR casual_remaining_days <> (casual_total_days - casual_used_days)
           OR privilege_remaining_days <> (privilege_total_days - privilege_used_days)
           OR on_duty_remaining_days <> (on_duty_total_days - on_duty_used_days)
           OR compensatory_remaining_days <> (compensatory_total_days - compensatory_used_days)
    )
        THROW 50002, N'Verification failed: Persisted computed remaining days calculation mismatch in teacher_leave_allowance.', 1;

    -- 8.3 Used days never exceed total days check
    IF EXISTS (
        SELECT 1 FROM teachers_schema.teacher_leave_allowance
        WHERE sick_used_days > sick_total_days
           OR casual_used_days > casual_total_days
           OR privilege_used_days > privilege_total_days
           OR on_duty_used_days > on_duty_total_days
           OR compensatory_used_days > compensatory_total_days
    )
        THROW 50003, N'Verification failed: Used days exceed total entitlement days in teacher_leave_allowance.', 1;

    -- 8.4 Application duration constraint check
    IF EXISTS (
        SELECT 1 FROM teachers_schema.teacher_leave_application
        WHERE leave_duration_type = 'HALF_DAY' AND (start_date <> end_date OR total_days <> 0.5)
    )
        THROW 50004, N'Verification failed: HALF_DAY leave constraint violated in teacher_leave_application.', 1;

    IF EXISTS (
        SELECT 1 FROM teachers_schema.teacher_leave_application
        WHERE leave_duration_type = 'FULL_DAY' AND total_days < 1.0
    )
        THROW 50005, N'Verification failed: FULL_DAY leave constraint violated in teacher_leave_application.', 1;

    -- 8.5 Overlapping active leaves check
    IF EXISTS (
        SELECT a1.teacher_leave_application_id, a2.teacher_leave_application_id
        FROM teachers_schema.teacher_leave_application a1
        JOIN teachers_schema.teacher_leave_application a2
          ON a1.teacher_id = a2.teacher_id
         AND a1.teacher_leave_application_id < a2.teacher_leave_application_id
         AND a1.status IN (N'PENDING', N'APPROVED')
         AND a2.status IN (N'PENDING', N'APPROVED')
         AND a1.start_date <= a2.end_date
         AND a1.end_date >= a2.start_date
    )
        THROW 50006, N'Verification failed: Overlapping active leave detected for a teacher.', 1;

    -- 8.6 EXACT 1:1 row count verification for history tables
    DECLARE @leave_app_count INT, @leave_hist_count INT;
    SELECT @leave_app_count = COUNT(*) FROM teachers_schema.teacher_leave_application;
    SELECT @leave_hist_count = COUNT(*) FROM teachers_schema.teacher_leave_status_history;
    IF @leave_app_count <> @leave_hist_count
        THROW 50007, N'Verification failed: teacher_leave_status_history row count does not equal teacher_leave_application row count (1:1 required).', 1;

    DECLARE @grievance_count INT, @grievance_hist_count INT;
    SELECT @grievance_count = COUNT(*) FROM teachers_schema.teacher_grievance;
    SELECT @grievance_hist_count = COUNT(*) FROM teachers_schema.teacher_grievance_status_history;
    IF @grievance_count <> @grievance_hist_count
        THROW 50008, N'Verification failed: teacher_grievance_status_history row count does not equal teacher_grievance row count (1:1 required).', 1;

    -- 8.7 History foreign key orphans & uniqueness check
    IF (SELECT COUNT(DISTINCT teacher_leave_application_id) FROM teachers_schema.teacher_leave_status_history) <> @leave_hist_count
        THROW 50009, N'Verification failed: Duplicate application history detected (expected exactly 1 row per leave application).', 1;

    IF (SELECT COUNT(DISTINCT teacher_grievance_id) FROM teachers_schema.teacher_grievance_status_history) <> @grievance_hist_count
        THROW 50010, N'Verification failed: Duplicate grievance history detected (expected exactly 1 row per grievance ticket).', 1;

    COMMIT TRANSACTION;

    PRINT N'';
    PRINT N'================================================================================';
    PRINT N'MOCK DATA DEPLOYMENT COMPLETED WITH 100% INTEGRITY & PERFECTION!';
    PRINT N'================================================================================';
    PRINT N'Summary of Seeded Records:';
    PRINT N'  1. teachers_schema.teacher_leave_allowance          : 80 rows (12.0 days each)';
    PRINT N'  2. teachers_schema.teacher_leave_application        : 20 rows (past dates)';
    PRINT N'  3. teachers_schema.teacher_leave_status_history     : 20 rows (EXACT 1:1 with applications)';
    PRINT N'  4. teachers_schema.teacher_grievance                : 12 tickets across 6 categories';
    PRINT N'  5. teachers_schema.teacher_grievance_status_history : 12 rows (EXACT 1:1 with grievances)';
    PRINT N'================================================================================';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        PRINT N'Error encountered! Rolling back all mock data insertions...';
        ROLLBACK TRANSACTION;
    END;

    -- Ensure IDENTITY_INSERT is disabled if error occurred mid-insert
    BEGIN TRY SET IDENTITY_INSERT teachers_schema.teacher_leave_application OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT teachers_schema.teacher_leave_status_history OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT teachers_schema.teacher_grievance OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT teachers_schema.teacher_grievance_status_history OFF; END TRY BEGIN CATCH END CATCH;

    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSev INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorLine INT = ERROR_LINE();

    RAISERROR(N'020_teacher_leave_and_grievance_mock_data.sql failed at line %d: %s', @ErrorSev, @ErrorState, @ErrorLine, @ErrorMsg);
END CATCH;
GO

-- =============================================================================
-- STEP 9: AUDIT SUMMARY QUERY (Display results in SSMS grid)
-- =============================================================================
SELECT
    'teacher_leave_allowance' AS [Table Name],
    COUNT(*) AS [Total Records],
    MIN(sick_total_days) AS [Min Sick Days],
    MAX(sick_total_days) AS [Max Sick Days],
    MIN(casual_total_days) AS [Min Casual Days],
    MAX(casual_total_days) AS [Max Casual Days]
FROM teachers_schema.teacher_leave_allowance
UNION ALL
SELECT
    'teacher_leave_application',
    COUNT(*),
    MIN(total_days),
    MAX(total_days),
    NULL,
    NULL
FROM teachers_schema.teacher_leave_application
UNION ALL
SELECT
    'teacher_leave_status_history',
    COUNT(*),
    NULL, NULL, NULL, NULL
FROM teachers_schema.teacher_leave_status_history
UNION ALL
SELECT
    'teacher_grievance',
    COUNT(*),
    NULL, NULL, NULL, NULL
FROM teachers_schema.teacher_grievance
UNION ALL
SELECT
    'teacher_grievance_status_history',
    COUNT(*),
    NULL, NULL, NULL, NULL
FROM teachers_schema.teacher_grievance_status_history;
GO

-- Inspection query to verify the 1:1 grievance history mapping in SSMS
SELECT
    g.teacher_grievance_id,
    g.grievance_category,
    g.status AS [Current Grievance Status],
    h.old_status AS [History Old Status],
    h.new_status AS [History New Status],
    h.changed_by AS [History Changed By],
    h.changed_at AS [History Changed At],
    h.remarks    AS [History Remarks]
FROM teachers_schema.teacher_grievance g
JOIN teachers_schema.teacher_grievance_status_history h
  ON h.teacher_grievance_id = g.teacher_grievance_id
ORDER BY g.teacher_grievance_id;
GO

