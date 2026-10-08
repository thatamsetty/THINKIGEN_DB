/*
    ================================================================================
    THINKIGEN GRIEVANCE MODULE — MOCK DATA SEED SCRIPT (60 REALISTIC RECORDS)
    ================================================================================
    Scope:
      - 60 comprehensive, realistic grievance records (grievance_id 1 to 60)
      - Covers all 8 categories:
          ACADEMIC, TRANSPORT, HOSTEL, BULLYING, FACILITIES, FEE, STAFF_BEHAVIOR, OTHER
      - Covers all 3 priority levels:
          LOW, MEDIUM, HIGH
      - Covers all 3 approved statuses:
          SUBMITTED    (~15 records)
          UNDER_REVIEW (~20 records)
          RESOLVED     (~25 records)
      - Exactly one corresponding lifecycle row in student_schema.grievance_history
        for each grievance (60 records in history, enforcing 1:1 relationship)
      - Department routing via department_id (1 to 8)
      - Scope foreign keys aligned with student_schema.student placements
    ================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'----------------------------------------------------------------------';
    PRINT N'1. CLEARING EXISTING GRIEVANCE DATA';
    PRINT N'----------------------------------------------------------------------';

    DELETE FROM student_schema.grievance_history;
    DELETE FROM student_schema.grievance;

    PRINT N'Cleared existing records from student_schema.grievance_history and grievance.';

    -- Drop legacy check constraints if present from older single-table schema
    DECLARE @drop_legacy_ck NVARCHAR(MAX) = N'';
    SELECT @drop_legacy_ck += N'ALTER TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' DROP CONSTRAINT ' + QUOTENAME(c.name) + N'; '
    FROM sys.check_constraints c
    JOIN sys.tables t ON c.parent_object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'student_schema' AND t.name = N'grievance'
      AND c.name IN (N'CK_grievance_assigned', N'CK_grievance_investigation', N'CK_grievance_review',
                     N'CK_grievance_resolved', N'CK_grievance_rejected', N'CK_grievance_cancelled');
    IF LEN(@drop_legacy_ck) > 0
        EXEC sys.sp_executesql @drop_legacy_ck;

    IF OBJECT_ID(N'student_schema.CK_grievance_assigned', N'C') IS NOT NULL
        ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_assigned;
    IF OBJECT_ID(N'student_schema.CK_grievance_investigation', N'C') IS NOT NULL
        ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_investigation;
    IF OBJECT_ID(N'student_schema.CK_grievance_review', N'C') IS NOT NULL
        ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_review;
    IF OBJECT_ID(N'student_schema.CK_grievance_resolved', N'C') IS NOT NULL
        ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_resolved;
    IF OBJECT_ID(N'student_schema.CK_grievance_rejected', N'C') IS NOT NULL
        ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_rejected;
    IF OBJECT_ID(N'student_schema.CK_grievance_cancelled', N'C') IS NOT NULL
        ALTER TABLE student_schema.grievance DROP CONSTRAINT CK_grievance_cancelled;

    PRINT N'----------------------------------------------------------------------';
    PRINT N'2. INSERTING 65 REALISTIC GRIEVANCE RECORDS';
    PRINT N'----------------------------------------------------------------------';

    SET IDENTITY_INSERT student_schema.grievance ON;

    INSERT INTO student_schema.grievance
    (
        grievance_id, grievance_number, school_id, branch_id, academic_year_id,
        class_id, section_id, student_id, department_id, title, category,
        priority_level, incident_date, location, description, status,
        submitted_at, assigned_to, is_active, created_at, created_by, updated_at
    )
    VALUES
    -- 1 to 10: ACADEMIC & TRANSPORT (RESOLVED / UNDER_REVIEW / SUBMITTED)
    (1, N'GRV-2026-1', 1, 1, 1, 1, 1, 1, 1, N'Math assignment formula clarification', N'ACADEMIC', N'LOW', '2026-08-01', N'Classroom 101', N'Student requested detailed clarification on quadratic formula problem set.', N'RESOLVED', '2026-08-01 09:30:00', 2, 1, '2026-08-01 09:30:00', 1, '2026-08-02 11:00:00'),
    (2, N'GRV-2026-2', 1, 1, 1, 1, 2, 2, 2, N'Bus Route 101 morning pickup delay', N'TRANSPORT', N'MEDIUM', '2026-08-02', N'Stop #4 Main Gate', N'Bus arrived 25 minutes late due to unexpected route deviation.', N'RESOLVED', '2026-08-02 08:15:00', 4, 1, '2026-08-02 08:15:00', 2, '2026-08-03 16:30:00'),
    (3, N'GRV-2026-3', 1, 1, 1, 2, 3, 3, 1, N'Physics lab practical apparatus shortage', N'ACADEMIC', N'HIGH', '2026-08-03', N'Physics Lab 2', N'Not enough vernier calipers available during period 3 lab session.', N'RESOLVED', '2026-08-03 11:20:00', 2, 1, '2026-08-03 11:20:00', 3, '2026-08-04 14:00:00'),
    (4, N'GRV-2026-4', 1, 1, 1, 2, 4, 4, 3, N'Hostel Block B hot water supply issue', N'HOSTEL', N'HIGH', '2026-08-04', N'Hostel Block B Wing 1', N'Solar heater pump failed on 2nd floor bathrooms early morning.', N'RESOLVED', '2026-08-04 07:00:00', 6, 1, '2026-08-04 07:00:00', 4, '2026-08-04 15:30:00'),
    (5, N'GRV-2026-5', 1, 2, 1, 3, 5, 5, 5, N'Term 1 receipt fee mismatch', N'FEE', N'MEDIUM', '2026-08-05', N'Accounts Desk', N'Receipt #104 shows incorrect tuition discount reconciliation.', N'RESOLVED', '2026-08-05 10:00:00', 8, 1, '2026-08-05 10:00:00', 5, '2026-08-06 12:00:00'),
    (6, N'GRV-2026-6', 1, 2, 1, 3, 6, 6, 4, N'Classroom projector bulb flickering', N'FACILITIES', N'LOW', '2026-08-06', N'Classroom 302', N'Projector screen flickers and dims after 15 minutes of usage.', N'RESOLVED', '2026-08-06 13:45:00', 10, 1, '2026-08-06 13:45:00', 6, '2026-08-07 10:15:00'),
    (7, N'GRV-2026-7', 1, 2, 1, 4, 7, 7, 6, N'Verbal bullying near cafeteria lockers', N'BULLYING', N'HIGH', '2026-08-07', N'Cafeteria Corridor', N'Senior students making inappropriate mocking remarks during lunch break.', N'RESOLVED', '2026-08-07 13:00:00', 12, 1, '2026-08-07 13:00:00', 7, '2026-08-08 17:00:00'),
    (8, N'GRV-2026-8', 1, 2, 1, 4, 8, 8, 7, N'Unprofessional tone during library check-out', N'STAFF_BEHAVIOR', N'MEDIUM', '2026-08-08', N'Central Library', N'Assistant librarian confiscated ID card without explanation.', N'RESOLVED', '2026-08-08 15:30:00', 14, 1, '2026-08-08 15:30:00', 8, '2026-08-09 11:30:00'),
    (9, N'GRV-2026-9', 2, 3, 2, 5, 9, 9, 2, N'Bus air conditioning malfunction', N'TRANSPORT', N'LOW', '2026-08-09', N'Route 202 Bus #14', N'Air conditioner vents blowing warm air on the afternoon return trip.', N'RESOLVED', '2026-08-09 17:00:00', 16, 1, '2026-08-09 17:00:00', 9, '2026-08-10 14:00:00'),
    (10, N'GRV-2026-10', 2, 3, 2, 5, 10, 10, 1, N'Chemistry lab reagent replenishment needed', N'ACADEMIC', N'MEDIUM', '2026-08-10', N'Chemistry Lab 1', N'Dilute hydrochloric acid bottles empty before scheduled titration.', N'RESOLVED', '2026-08-10 10:15:00', 2, 1, '2026-08-10 10:15:00', 10, '2026-08-11 09:30:00'),

    -- 11 to 20: HOSTEL & FACILITIES (RESOLVED / UNDER_REVIEW)
    (11, N'GRV-2026-11', 2, 3, 2, 6, 11, 11, 3, N'Hostel study room table light not working', N'HOSTEL', N'LOW', '2026-08-11', N'Hostel Study Hall A', N'Two tube lights are fused in the corner study cubicles.', N'RESOLVED', '2026-08-11 20:30:00', 6, 1, '2026-08-11 20:30:00', 11, '2026-08-12 11:00:00'),
    (12, N'GRV-2026-12', 2, 3, 2, 6, 12, 12, 4, N'Water cooler leaking near gymnasium', N'FACILITIES', N'MEDIUM', '2026-08-12', N'Gymnasium Entryway', N'Purified water cooler base leaking water onto floor causing slip hazard.', N'RESOLVED', '2026-08-12 14:10:00', 10, 1, '2026-08-12 14:10:00', 12, '2026-08-13 16:00:00'),
    (13, N'GRV-2026-13', 2, 4, 2, 7, 13, 13, 8, N'Lost student badge replacement inquiry', N'OTHER', N'LOW', '2026-08-13', N'Admin Reception', N'Requested reissue of misplaced student smart ID badge.', N'RESOLVED', '2026-08-13 11:00:00', 18, 1, '2026-08-13 11:00:00', 13, '2026-08-14 10:30:00'),
    (14, N'GRV-2026-14', 2, 4, 2, 7, 14, 14, 2, N'Bus driver skipped designated stop', N'TRANSPORT', N'HIGH', '2026-08-14', N'Shivaji Nagar Cross', N'Driver did not stop at official stop #3 despite student signaling.', N'RESOLVED', '2026-08-14 08:30:00', 4, 1, '2026-08-14 08:30:00', 14, '2026-08-15 12:00:00'),
    (15, N'GRV-2026-15', 2, 4, 2, 8, 15, 15, 5, N'Transport fee double deduction inquiry', N'FEE', N'HIGH', '2026-08-15', N'Finance Portal', N'Online payment portal debited bus fee twice for month of August.', N'RESOLVED', '2026-08-15 16:20:00', 8, 1, '2026-08-15 16:20:00', 15, '2026-08-16 11:00:00'),
    (16, N'GRV-2026-16', 2, 4, 2, 8, 16, 16, 1, N'Biology practical slide damaged', N'ACADEMIC', N'LOW', '2026-08-16', N'Bio Lab 1', N'Prepared onion root tip slide cracked; replacement requested.', N'RESOLVED', '2026-08-16 12:00:00', 2, 1, '2026-08-16 12:00:00', 16, '2026-08-17 14:00:00'),
    (17, N'GRV-2026-17', 1, 1, 1, 1, 1, 17, 3, N'Hostel mess dinner quality complaint', N'HOSTEL', N'MEDIUM', '2026-08-17', N'Dining Hall 2', N'Rice was undercooked and rotis were cold during evening mess.', N'RESOLVED', '2026-08-17 21:00:00', 6, 1, '2026-08-17 21:00:00', 17, '2026-08-18 10:00:00'),
    (18, N'GRV-2026-18', 1, 1, 1, 1, 2, 18, 4, N'Ceiling fan making screeching noise', N'FACILITIES', N'LOW', '2026-08-18', N'Classroom 104', N'Center fan squeaking loudly causing distraction during lectures.', N'RESOLVED', '2026-08-18 10:45:00', 10, 1, '2026-08-18 10:45:00', 18, '2026-08-19 15:20:00'),
    (19, N'GRV-2026-19', 1, 1, 1, 2, 3, 19, 6, N'Pushing in cafeteria lunch queue', N'BULLYING', N'MEDIUM', '2026-08-19', N'Dining Counter A', N'Group of boys repeatedly cutting queue and pushing junior students.', N'RESOLVED', '2026-08-19 13:15:00', 12, 1, '2026-08-19 13:15:00', 19, '2026-08-20 16:45:00'),
    (20, N'GRV-2026-20', 1, 1, 1, 2, 4, 20, 7, N'Lab attendant rude behavior during equipment issue', N'STAFF_BEHAVIOR', N'MEDIUM', '2026-08-20', N'Computer Lab 2', N'Attendant shouted at student when asking for replacement mouse.', N'RESOLVED', '2026-08-20 14:30:00', 14, 1, '2026-08-20 14:30:00', 20, '2026-08-21 11:30:00'),

    -- 21 to 30: RESOLVED continued
    (21, N'GRV-2026-21', 1, 2, 1, 3, 5, 21, 1, N'Computer lab internet speed during online test', N'ACADEMIC', N'HIGH', '2026-08-21', N'IT Lab 1', N'Frequent disconnection during coding assessment submission.', N'RESOLVED', '2026-08-21 11:00:00', 2, 1, '2026-08-21 11:00:00', 21, '2026-08-22 17:00:00'),
    (22, N'GRV-2026-22', 1, 2, 1, 3, 6, 22, 2, N'Transport pass QR code not scanning', N'TRANSPORT', N'LOW', '2026-08-22', N'Bus #102', N'Handheld scanner failed to read student ID digital QR code.', N'RESOLVED', '2026-08-22 08:20:00', 4, 1, '2026-08-22 08:20:00', 22, '2026-08-23 10:00:00'),
    (23, N'GRV-2026-23', 1, 2, 1, 4, 7, 23, 4, N'Broken window latch in classroom', N'FACILITIES', N'MEDIUM', '2026-08-23', N'Room 401', N'Window pane bangs violently during windy conditions.', N'RESOLVED', '2026-08-23 12:40:00', 10, 1, '2026-08-23 12:40:00', 23, '2026-08-24 14:30:00'),
    (24, N'GRV-2026-24', 1, 2, 1, 4, 8, 24, 3, N'Hostel laundry return delay', N'HOSTEL', N'LOW', '2026-08-24', N'Laundry Dispatch', N'Uniforms not delivered within promised 48-hour window.', N'RESOLVED', '2026-08-24 18:00:00', 6, 1, '2026-08-24 18:00:00', 24, '2026-08-25 12:15:00'),
    (25, N'GRV-2026-25', 2, 3, 2, 5, 9, 25, 5, N'Term 2 scholarship credit not reflected', N'FEE', N'HIGH', '2026-08-25', N'Accounts Office', N'Merit scholarship adjustment of 5,000 not deducted from term statement.', N'RESOLVED', '2026-08-25 10:30:00', 8, 1, '2026-08-25 10:30:00', 25, '2026-08-26 15:45:00'),

    -- 26 to 45: UNDER_REVIEW (~20 records)
    (26, N'GRV-2026-26', 2, 3, 2, 5, 10, 26, 1, N'Discrepancy in unit test evaluation marks', N'ACADEMIC', N'HIGH', '2026-08-26', N'Staff Room 3', N'Question 4 marks not totaled in chemistry mid-term paper.', N'UNDER_REVIEW', '2026-08-26 11:30:00', 2, 1, '2026-08-26 11:30:00', 26, '2026-08-27 14:00:00'),
    (27, N'GRV-2026-27', 2, 3, 2, 6, 11, 27, 2, N'Overcrowding on Bus Route 204', N'TRANSPORT', N'HIGH', '2026-08-27', N'Bus Route 204', N'Students forced to stand on steps due to insufficient seating capacity.', N'UNDER_REVIEW', '2026-08-27 08:45:00', 4, 1, '2026-08-27 08:45:00', 27, '2026-08-28 09:30:00'),
    (28, N'GRV-2026-28', 2, 3, 2, 6, 12, 28, 4, N'Restroom tap water pressure low', N'FACILITIES', N'MEDIUM', '2026-08-28', N'2nd Floor Washroom', N'Taps running at trickle speed; handwashing difficult during recess.', N'UNDER_REVIEW', '2026-08-28 12:15:00', 10, 1, '2026-08-28 12:15:00', 28, '2026-08-29 10:00:00'),
    (29, N'GRV-2026-29', 2, 4, 2, 7, 13, 29, 6, N'Online group chat harassment report', N'BULLYING', N'HIGH', '2026-08-29', N'School Communication App', N'Student receiving offensive messages in section homework chat group.', N'UNDER_REVIEW', '2026-08-29 19:00:00', 12, 1, '2026-08-29 19:00:00', 29, '2026-08-30 08:30:00'),
    (30, N'GRV-2026-30', 2, 4, 2, 7, 14, 30, 3, N'Hostel room air cooler motor burned out', N'HOSTEL', N'MEDIUM', '2026-08-30', N'Hostel Room 204', N'Room cooler stopped spinning; motor giving burning smell.', N'UNDER_REVIEW', '2026-08-30 16:00:00', 6, 1, '2026-08-30 16:00:00', 30, '2026-08-31 11:15:00'),
    (31, N'GRV-2026-31', 2, 4, 2, 8, 15, 31, 7, N'Security guard harsh tone at front gate', N'STAFF_BEHAVIOR', N'LOW', '2026-08-31', N'Gate #2', N'Guard spoke rudely to parent during rainy morning drop-off.', N'UNDER_REVIEW', '2026-08-31 08:10:00', 14, 1, '2026-08-31 08:10:00', 31, '2026-09-01 10:00:00'),
    (32, N'GRV-2026-32', 2, 4, 2, 8, 16, 32, 5, N'Late fee penalty dispute after system outage', N'FEE', N'MEDIUM', '2026-09-01', N'Fee Payment Portal', N'Late fine applied even though server was down on due date.', N'UNDER_REVIEW', '2026-09-01 09:30:00', 8, 1, '2026-09-01 09:30:00', 32, '2026-09-02 14:00:00'),
    (33, N'GRV-2026-33', 1, 1, 1, 1, 1, 1, 1, N'History syllabus coverage pace too fast', N'ACADEMIC', N'LOW', '2026-09-02', N'Room 101', N'Teacher rushed through Chapters 4 and 5 in single period.', N'UNDER_REVIEW', '2026-09-02 14:00:00', 2, 1, '2026-09-02 14:00:00', 1, '2026-09-03 11:30:00'),
    (34, N'GRV-2026-34', 1, 1, 1, 1, 2, 2, 2, N'Evening drop-off stop change request pending', N'TRANSPORT', N'MEDIUM', '2026-09-03', N'Transport Cell', N'Parent change-request submitted 5 days ago not yet activated.', N'UNDER_REVIEW', '2026-09-03 10:15:00', 4, 1, '2026-09-03 10:15:00', 2, '2026-09-04 09:45:00'),
    (35, N'GRV-2026-35', 1, 1, 1, 2, 3, 3, 4, N'Auditorium mic feedback noise during rehearsal', N'FACILITIES', N'LOW', '2026-09-04', N'Main Auditorium', N'Microphone screeching loudly during inter-house drama rehearsal.', N'UNDER_REVIEW', '2026-09-04 15:30:00', 10, 1, '2026-09-04 15:30:00', 3, '2026-09-05 13:00:00'),
    (36, N'GRV-2026-36', 1, 1, 1, 2, 4, 4, 3, N'Hostel WiFi network disconnects in Wing 3', N'HOSTEL', N'MEDIUM', '2026-09-05', N'Hostel Block A 3rd Floor', N'Signal drops every 10 minutes making online study modules unworkable.', N'UNDER_REVIEW', '2026-09-05 21:15:00', 6, 1, '2026-09-05 21:15:00', 4, '2026-09-06 10:00:00'),
    (37, N'GRV-2026-37', 1, 2, 1, 3, 5, 5, 8, N'Lost sports kit bag report', N'OTHER', N'LOW', '2026-09-06', N'Sports Complex Shed', N'Football gear bag missing from locker room shelf after game.', N'UNDER_REVIEW', '2026-09-06 17:00:00', 18, 1, '2026-09-06 17:00:00', 5, '2026-09-07 11:20:00'),
    (38, N'GRV-2026-38', 1, 2, 1, 3, 6, 6, 6, N'Exclusion from team games during recess', N'BULLYING', N'HIGH', '2026-09-07', N'Playground', N'Peer group intentionally isolating student and threatening if reported.', N'UNDER_REVIEW', '2026-09-07 13:30:00', 12, 1, '2026-09-07 13:30:00', 6, '2026-09-08 09:00:00'),
    (39, N'GRV-2026-39', 1, 2, 1, 4, 7, 7, 7, N'Bus conductor inappropriate language', N'STAFF_BEHAVIOR', N'HIGH', '2026-09-08', N'Bus Route 105', N'Conductor used abusive words when student asked for ticket receipt.', N'UNDER_REVIEW', '2026-09-08 08:45:00', 14, 1, '2026-09-08 08:45:00', 7, '2026-09-09 10:30:00'),
    (40, N'GRV-2026-40', 1, 2, 1, 4, 8, 8, 1, N'Extra coaching session timing clash with bus', N'ACADEMIC', N'MEDIUM', '2026-09-09', N'Room 305', N'Remedial math class ends at 4:30 PM but school bus departs at 4:15 PM.', N'UNDER_REVIEW', '2026-09-09 16:30:00', 2, 1, '2026-09-09 16:30:00', 8, '2026-09-10 12:00:00'),
    (41, N'GRV-2026-41', 2, 3, 2, 5, 9, 9, 2, N'Bus seat broken backrest causing back pain', N'TRANSPORT', N'LOW', '2026-09-10', N'Bus #201 Seat 12', N'Backrest hinge snapped; seat reclines completely backwards.', N'UNDER_REVIEW', '2026-09-10 08:30:00', 4, 1, '2026-09-10 08:30:00', 9, '2026-09-11 14:15:00'),
    (42, N'GRV-2026-42', 2, 3, 2, 5, 10, 10, 4, N'Drinking water taste abnormal near library', N'FACILITIES', N'HIGH', '2026-09-11', N'Library Water Cooler', N'Water smells muddy; filter cartridge replacement urgent.', N'UNDER_REVIEW', '2026-09-11 11:45:00', 10, 1, '2026-09-11 11:45:00', 10, '2026-09-12 09:30:00'),
    (43, N'GRV-2026-43', 2, 3, 2, 6, 11, 11, 3, N'Hostel washroom door latch broken', N'HOSTEL', N'MEDIUM', '2026-09-12', N'Hostel 1st Floor', N'Privacy latch does not lock from inside in bathroom cubicle 3.', N'UNDER_REVIEW', '2026-09-12 07:15:00', 6, 1, '2026-09-12 07:15:00', 11, '2026-09-12 11:00:00'),
    (44, N'GRV-2026-44', 2, 3, 2, 6, 12, 12, 5, N'Exam fee payment receipt missing transaction ID', N'FEE', N'LOW', '2026-09-12', N'Finance Counter', N'Printed receipt missing bank reference number for reimbursement claim.', N'UNDER_REVIEW', '2026-09-12 10:00:00', 8, 1, '2026-09-12 10:00:00', 12, '2026-09-12 11:30:00'),
    (45, N'GRV-2026-45', 2, 4, 2, 7, 13, 13, 1, N'Textbook shortage for revised English curriculum', N'ACADEMIC', N'HIGH', '2026-09-12', N'Bookstore', N'Bookstore ran out of copies of Grade 9 Supplementary English reader.', N'UNDER_REVIEW', '2026-09-12 09:00:00', 2, 1, '2026-09-12 09:00:00', 13, '2026-09-12 10:45:00'),

    -- 46 to 60: SUBMITTED (~15 records)
    (46, N'GRV-2026-46', 2, 4, 2, 7, 14, 14, 2, N'Bus arriving 15 minutes early at morning stop', N'TRANSPORT', N'MEDIUM', '2026-09-12', N'Green Valley Stop', N'Bus left early before scheduled 7:35 AM time; two students missed it.', N'SUBMITTED', '2026-09-12 07:50:00', NULL, 1, '2026-09-12 07:50:00', 14, '2026-09-12 07:50:00'),
    (47, N'GRV-2026-47', 2, 4, 2, 8, 15, 15, 4, N'Gymnasium locker jammed with student books inside', N'FACILITIES', N'MEDIUM', '2026-09-12', N'Boys Locker Room', N'Key turned but mechanism stuck; textbooks needed for homework.', N'SUBMITTED', '2026-09-12 08:15:00', NULL, 1, '2026-09-12 08:15:00', 15, '2026-09-12 08:15:00'),
    (48, N'GRV-2026-48', 2, 4, 2, 8, 16, 16, 6, N'Intimidation by bus route seniors during return trip', N'BULLYING', N'HIGH', '2026-09-12', N'Bus #203 Rear Row', N'Senior students demanding lunch snacks and threatening physical harm.', N'SUBMITTED', '2026-09-12 08:30:00', 12, 1, '2026-09-12 08:30:00', 16, '2026-09-12 08:30:00'),
    (49, N'GRV-2026-49', 1, 1, 1, 1, 1, 17, 3, N'Hostel night study lamp flickering in Room 108', N'HOSTEL', N'LOW', '2026-09-12', N'Room 108', N'Wall mounted reading lamp socket loose and sparks occasionally.', N'SUBMITTED', '2026-09-12 08:45:00', NULL, 1, '2026-09-12 08:45:00', 17, '2026-09-12 08:45:00'),
    (50, N'GRV-2026-50', 1, 1, 1, 1, 2, 18, 1, N'Request for extra practice worksheet in Hindi grammar', N'ACADEMIC', N'LOW', '2026-09-12', N'Room 102', N'Student needs sandhi and samas additional exercises before tests.', N'SUBMITTED', '2026-09-12 09:00:00', NULL, 1, '2026-09-12 09:00:00', 18, '2026-09-12 09:00:00'),
    (51, N'GRV-2026-51', 1, 1, 1, 2, 3, 19, 5, N'Late fee waiver request due to medical hospitalization', N'FEE', N'MEDIUM', '2026-09-12', N'Fee Counter', N'Parent submitted hospitalization discharge summary; fee waiver requested.', N'SUBMITTED', '2026-09-12 09:15:00', 8, 1, '2026-09-12 09:15:00', 19, '2026-09-12 09:15:00'),
    (52, N'GRV-2026-52', 1, 1, 1, 2, 4, 20, 7, N'Cafeteria cashier refused UPI payment without reason', N'STAFF_BEHAVIOR', N'LOW', '2026-09-12', N'Snack Bar', N'Cashier demanded cash only despite working QR scanner on display.', N'SUBMITTED', '2026-09-12 09:30:00', NULL, 1, '2026-09-12 09:30:00', 20, '2026-09-12 09:30:00'),
    (53, N'GRV-2026-53', 1, 2, 1, 3, 5, 21, 2, N'Emergency transport request for sick student', N'TRANSPORT', N'HIGH', '2026-09-12', N'Infirmary', N'Student running 102 fever; early drop-off van dispatch requested.', N'SUBMITTED', '2026-09-12 09:45:00', 4, 1, '2026-09-12 09:45:00', 21, '2026-09-12 09:45:00'),
    (54, N'GRV-2026-54', 1, 2, 1, 3, 6, 22, 4, N'Blackboard paint worn off causing chalk glare', N'FACILITIES', N'LOW', '2026-09-12', N'Classroom 306', N'Reflection from windows makes writing illegible from back benches.', N'SUBMITTED', '2026-09-12 10:00:00', NULL, 1, '2026-09-12 10:00:00', 22, '2026-09-12 10:00:00'),
    (55, N'GRV-2026-55', 1, 2, 1, 4, 7, 23, 8, N'Lost wrist watch in chemistry laboratory', N'OTHER', N'LOW', '2026-09-12', N'Chem Lab Table 4', N'Titan silver watch left near wash basin during 4th period practical.', N'SUBMITTED', '2026-09-12 10:15:00', NULL, 1, '2026-09-12 10:15:00', 23, '2026-09-12 10:15:00'),
    (56, N'GRV-2026-56', 1, 2, 1, 4, 8, 24, 1, N'Computer lab monitor power cable loose', N'ACADEMIC', N'LOW', '2026-09-12', N'PC Station 18', N'Screen shuts down whenever keyboard tray is pulled out.', N'SUBMITTED', '2026-09-12 10:30:00', NULL, 1, '2026-09-12 10:30:00', 24, '2026-09-12 10:30:00'),
    (57, N'GRV-2026-57', 2, 3, 2, 5, 9, 25, 3, N'Hostel balcony drain clogged with dried leaves', N'HOSTEL', N'MEDIUM', '2026-09-12', N'Block B 2nd Floor Balcony', N'Water accumulating after heavy morning downpour.', N'SUBMITTED', '2026-09-12 10:45:00', NULL, 1, '2026-09-12 10:45:00', 25, '2026-09-12 10:45:00'),
    (58, N'GRV-2026-58', 2, 3, 2, 5, 10, 26, 6, N'Name calling and mockery during PE class', N'BULLYING', N'HIGH', '2026-09-12', N'Athletics Track', N'Classmates taunting student regarding athletic performance.', N'SUBMITTED', '2026-09-12 11:00:00', 12, 1, '2026-09-12 11:00:00', 26, '2026-09-12 11:00:00'),
    (59, N'GRV-2026-59', 2, 3, 2, 6, 11, 27, 2, N'Bus Route 205 evening route delay inquiry', N'TRANSPORT', N'MEDIUM', '2026-09-12', N'Transport Inquiry', N'Parent inquiring about frequent traffic bottlenecks near flyover construction.', N'SUBMITTED', '2026-09-12 11:15:00', NULL, 1, '2026-09-12 11:15:00', 27, '2026-09-12 11:15:00'),
    (60, N'GRV-2026-60', 2, 3, 2, 6, 12, 28, 5, N'Installment payment option inquiry for annual excursion', N'FEE', N'LOW', '2026-09-12', N'Accounts Section', N'Parent requested paying science museum excursion fee in two parts.', N'SUBMITTED', '2026-09-12 11:30:00', 8, 1, '2026-09-12 11:30:00', 28, '2026-09-12 11:30:00'),
    (61, N'GRV-2026-61', 2, 4, 2, 7, 13, 29, 7, N'Library assistant issued torn encyclopedia volume', N'STAFF_BEHAVIOR', N'LOW', '2026-09-12', N'Senior Reference Section', N'Book pages 45-50 missing prior to checkout; noted on return desk.', N'SUBMITTED', '2026-09-12 11:45:00', NULL, 1, '2026-09-12 11:45:00', 29, '2026-09-12 11:45:00'),
    (62, N'GRV-2026-62', 2, 4, 2, 7, 14, 30, 4, N'Restroom exhaust fan making loud squealing noise', N'FACILITIES', N'LOW', '2026-09-12', N'Block C Restroom', N'Exhaust motor belt loose and whining loudly during morning hours.', N'SUBMITTED', '2026-09-12 12:00:00', NULL, 1, '2026-09-12 12:00:00', 30, '2026-09-12 12:00:00'),
    (63, N'GRV-2026-63', 2, 4, 2, 8, 15, 31, 1, N'Biology diagram test rubric grading clarification', N'ACADEMIC', N'MEDIUM', '2026-09-12', N'Room 402', N'Student requested re-evaluation of heart dissection diagram labeling.', N'SUBMITTED', '2026-09-12 12:15:00', NULL, 1, '2026-09-12 12:15:00', 31, '2026-09-12 12:15:00'),
    (64, N'GRV-2026-64', 2, 4, 2, 8, 16, 32, 2, N'Bus pass barcode scan failing on entry reader', N'TRANSPORT', N'LOW', '2026-09-12', N'Bus #204 Entry Door', N'Optical reader scratched; bus attender had to manually verify pass.', N'SUBMITTED', '2026-09-12 12:30:00', 4, 1, '2026-09-12 12:30:00', 32, '2026-09-12 12:30:00'),
    (65, N'GRV-2026-65', 1, 1, 1, 1, 1, 1, 6, N'Cyberbullying messages in unofficial class WhatsApp group', N'BULLYING', N'HIGH', '2026-09-12', N'Online / Chat', N'Aggressive messages and exclusion from study groups reported by parent.', N'SUBMITTED', '2026-09-12 12:45:00', 12, 1, '2026-09-12 12:45:00', 1, '2026-09-12 12:45:00');

    SET IDENTITY_INSERT student_schema.grievance OFF;

    PRINT N'Inserted 65 records into student_schema.grievance.';

    PRINT N'----------------------------------------------------------------------';
    PRINT N'3. INSERTING 65 1:1 LIFECYCLE RECORDS IN grievance_history';
    PRINT N'----------------------------------------------------------------------';

    SET IDENTITY_INSERT student_schema.grievance_history ON;

    INSERT INTO student_schema.grievance_history
    (
        grievance_history_id, grievance_id, submitted_by, submitted_at,
        assigned_to, reviewed_at, resolved_at, updated_at
    )
    VALUES
    -- 1 to 25: RESOLVED (both reviewed_at and resolved_at populated; submitted_by = student_id)
    (1, 1, 1, '2026-08-01 09:30:00', 2, '2026-08-01 14:00:00', '2026-08-02 11:00:00', '2026-08-02 11:00:00'),
    (2, 2, 2, '2026-08-02 08:15:00', 4, '2026-08-02 11:30:00', '2026-08-03 16:30:00', '2026-08-03 16:30:00'),
    (3, 3, 3, '2026-08-03 11:20:00', 2, '2026-08-03 16:00:00', '2026-08-04 14:00:00', '2026-08-04 14:00:00'),
    (4, 4, 4, '2026-08-04 07:00:00', 6, '2026-08-04 09:30:00', '2026-08-04 15:30:00', '2026-08-04 15:30:00'),
    (5, 5, 5, '2026-08-05 10:00:00', 8, '2026-08-05 15:00:00', '2026-08-06 12:00:00', '2026-08-06 12:00:00'),
    (6, 6, 6, '2026-08-06 13:45:00', 10, '2026-08-06 16:30:00', '2026-08-07 10:15:00', '2026-08-07 10:15:00'),
    (7, 7, 7, '2026-08-07 13:00:00', 12, '2026-08-07 14:30:00', '2026-08-08 17:00:00', '2026-08-08 17:00:00'),
    (8, 8, 8, '2026-08-08 15:30:00', 14, '2026-08-08 17:00:00', '2026-08-09 11:30:00', '2026-08-09 11:30:00'),
    (9, 9, 9, '2026-08-09 17:00:00', 16, '2026-08-10 09:00:00', '2026-08-10 14:00:00', '2026-08-10 14:00:00'),
    (10, 10, 10, '2026-08-10 10:15:00', 2, '2026-08-10 14:30:00', '2026-08-11 09:30:00', '2026-08-11 09:30:00'),
    (11, 11, 11, '2026-08-11 20:30:00', 6, '2026-08-12 09:00:00', '2026-08-12 11:00:00', '2026-08-12 11:00:00'),
    (12, 12, 12, '2026-08-12 14:10:00', 10, '2026-08-12 16:00:00', '2026-08-13 16:00:00', '2026-08-13 16:00:00'),
    (13, 13, 13, '2026-08-13 11:00:00', 18, '2026-08-13 14:00:00', '2026-08-14 10:30:00', '2026-08-14 10:30:00'),
    (14, 14, 14, '2026-08-14 08:30:00', 4, '2026-08-14 11:00:00', '2026-08-15 12:00:00', '2026-08-15 12:00:00'),
    (15, 15, 15, '2026-08-15 16:20:00', 8, '2026-08-15 18:00:00', '2026-08-16 11:00:00', '2026-08-16 11:00:00'),
    (16, 16, 16, '2026-08-16 12:00:00', 2, '2026-08-16 15:30:00', '2026-08-17 14:00:00', '2026-08-17 14:00:00'),
    (17, 17, 17, '2026-08-17 21:00:00', 6, '2026-08-18 08:30:00', '2026-08-18 10:00:00', '2026-08-18 10:00:00'),
    (18, 18, 18, '2026-08-18 10:45:00', 10, '2026-08-18 14:00:00', '2026-08-19 15:20:00', '2026-08-19 15:20:00'),
    (19, 19, 19, '2026-08-19 13:15:00', 12, '2026-08-19 15:00:00', '2026-08-20 16:45:00', '2026-08-20 16:45:00'),
    (20, 20, 20, '2026-08-20 14:30:00', 14, '2026-08-20 16:00:00', '2026-08-21 11:30:00', '2026-08-21 11:30:00'),
    (21, 21, 21, '2026-08-21 11:00:00', 2, '2026-08-21 15:00:00', '2026-08-22 17:00:00', '2026-08-22 17:00:00'),
    (22, 22, 22, '2026-08-22 08:20:00', 4, '2026-08-22 11:00:00', '2026-08-23 10:00:00', '2026-08-23 10:00:00'),
    (23, 23, 23, '2026-08-23 12:40:00', 10, '2026-08-23 15:00:00', '2026-08-24 14:30:00', '2026-08-24 14:30:00'),
    (24, 24, 24, '2026-08-24 18:00:00', 6, '2026-08-25 09:30:00', '2026-08-25 12:15:00', '2026-08-25 12:15:00'),
    (25, 25, 25, '2026-08-25 10:30:00', 8, '2026-08-25 14:00:00', '2026-08-26 15:45:00', '2026-08-26 15:45:00'),

    -- 26 to 45: UNDER_REVIEW (~20 records; submitted_by = student_id)
    (26, 26, 26, '2026-08-26 11:30:00', 2, '2026-08-27 14:00:00', NULL, '2026-08-27 14:00:00'),
    (27, 27, 27, '2026-08-27 08:45:00', 4, '2026-08-28 09:30:00', NULL, '2026-08-28 09:30:00'),
    (28, 28, 28, '2026-08-28 12:15:00', 10, '2026-08-29 10:00:00', NULL, '2026-08-29 10:00:00'),
    (29, 29, 29, '2026-08-29 19:00:00', 12, '2026-08-30 08:30:00', NULL, '2026-08-30 08:30:00'),
    (30, 30, 30, '2026-08-30 16:00:00', 6, '2026-08-31 11:15:00', NULL, '2026-08-31 11:15:00'),
    (31, 31, 31, '2026-08-31 08:10:00', 14, '2026-09-01 10:00:00', NULL, '2026-09-01 10:00:00'),
    (32, 32, 32, '2026-09-01 09:30:00', 8, '2026-09-02 14:00:00', NULL, '2026-09-02 14:00:00'),
    (33, 33, 1,  '2026-09-02 14:00:00', 2, '2026-09-03 11:30:00', NULL, '2026-09-03 11:30:00'),
    (34, 34, 2,  '2026-09-03 10:15:00', 4, '2026-09-04 09:45:00', NULL, '2026-09-04 09:45:00'),
    (35, 35, 3,  '2026-09-04 15:30:00', 10, '2026-09-05 13:00:00', NULL, '2026-09-05 13:00:00'),
    (36, 36, 4,  '2026-09-05 21:15:00', 6, '2026-09-06 10:00:00', NULL, '2026-09-06 10:00:00'),
    (37, 37, 5,  '2026-09-06 17:00:00', 18, '2026-09-07 11:20:00', NULL, '2026-09-07 11:20:00'),
    (38, 38, 6,  '2026-09-07 13:30:00', 12, '2026-09-08 09:00:00', NULL, '2026-09-08 09:00:00'),
    (39, 39, 7,  '2026-09-08 08:45:00', 14, '2026-09-09 10:30:00', NULL, '2026-09-09 10:30:00'),
    (40, 40, 8,  '2026-09-09 16:30:00', 2, '2026-09-10 12:00:00', NULL, '2026-09-10 12:00:00'),
    (41, 41, 9,  '2026-09-10 08:30:00', 4, '2026-09-11 14:15:00', NULL, '2026-09-11 14:15:00'),
    (42, 42, 10, '2026-09-11 11:45:00', 10, '2026-09-12 09:30:00', NULL, '2026-09-12 09:30:00'),
    (43, 43, 11, '2026-09-12 07:15:00', 6, '2026-09-12 11:00:00', NULL, '2026-09-12 11:00:00'),
    (44, 44, 12, '2026-09-12 10:00:00', 8, '2026-09-12 10:45:00', NULL, '2026-09-12 11:30:00'),
    (45, 45, 13, '2026-09-12 09:00:00', 2, '2026-09-12 10:00:00', NULL, '2026-09-12 10:45:00'),

    -- 46 to 65: SUBMITTED (20 records, reviewed_at NULL, resolved_at NULL; submitted_by = student_id)
    (46, 46, 14, '2026-09-12 07:50:00', NULL, NULL, NULL, '2026-09-12 07:50:00'),
    (47, 47, 15, '2026-09-12 08:15:00', NULL, NULL, NULL, '2026-09-12 08:15:00'),
    (48, 48, 16, '2026-09-12 08:30:00', 12, NULL, NULL, '2026-09-12 08:30:00'),
    (49, 49, 17, '2026-09-12 08:45:00', NULL, NULL, NULL, '2026-09-12 08:45:00'),
    (50, 50, 18, '2026-09-12 09:00:00', NULL, NULL, NULL, '2026-09-12 09:00:00'),
    (51, 51, 19, '2026-09-12 09:15:00', 8, NULL, NULL, '2026-09-12 09:15:00'),
    (52, 52, 20, '2026-09-12 09:30:00', NULL, NULL, NULL, '2026-09-12 09:30:00'),
    (53, 53, 21, '2026-09-12 09:45:00', 4, NULL, NULL, '2026-09-12 09:45:00'),
    (54, 54, 22, '2026-09-12 10:00:00', NULL, NULL, NULL, '2026-09-12 10:00:00'),
    (55, 55, 23, '2026-09-12 10:15:00', NULL, NULL, NULL, '2026-09-12 10:15:00'),
    (56, 56, 24, '2026-09-12 10:30:00', NULL, NULL, NULL, '2026-09-12 10:30:00'),
    (57, 57, 25, '2026-09-12 10:45:00', NULL, NULL, NULL, '2026-09-12 10:45:00'),
    (58, 58, 26, '2026-09-12 11:00:00', 12, NULL, NULL, '2026-09-12 11:00:00'),
    (59, 59, 27, '2026-09-12 11:15:00', NULL, NULL, NULL, '2026-09-12 11:15:00'),
    (60, 60, 28, '2026-09-12 11:30:00', 8, NULL, NULL, '2026-09-12 11:30:00'),
    (61, 61, 29, '2026-09-12 11:45:00', NULL, NULL, NULL, '2026-09-12 11:45:00'),
    (62, 62, 30, '2026-09-12 12:00:00', NULL, NULL, NULL, '2026-09-12 12:00:00'),
    (63, 63, 31, '2026-09-12 12:15:00', NULL, NULL, NULL, '2026-09-12 12:15:00'),
    (64, 64, 32, '2026-09-12 12:30:00', 4, NULL, NULL, '2026-09-12 12:30:00'),
    (65, 65, 1,  '2026-09-12 12:45:00', 12, NULL, NULL, '2026-09-12 12:45:00');

    SET IDENTITY_INSERT student_schema.grievance_history OFF;

    PRINT N'Inserted 65 records into student_schema.grievance_history.';

    PRINT N'----------------------------------------------------------------------';
    PRINT N'4. VERIFYING SEEDED GRIEVANCE DATA';
    PRINT N'----------------------------------------------------------------------';

    DECLARE @grievance_count INT;
    DECLARE @history_count INT;

    SELECT @grievance_count = COUNT(*) FROM student_schema.grievance;
    SELECT @history_count = COUNT(*) FROM student_schema.grievance_history;

    PRINT N'student_schema.grievance total count: ' + CAST(@grievance_count AS NVARCHAR(10));
    PRINT N'student_schema.grievance_history total count: ' + CAST(@history_count AS NVARCHAR(10));

    IF @grievance_count <> 65 OR @history_count <> 65
    BEGIN
        THROW 52000, N'Seed failed: Expected exactly 65 records in grievance and grievance_history.', 1;
    END;

    -- Constraint & Integrity Verification: Check that student_id and created_by are identical
    IF EXISTS (
        SELECT 1 FROM student_schema.grievance
        WHERE student_id <> created_by
    )
    BEGIN
        THROW 52001, N'Integrity check failed: student_id and created_by must match on all grievance records.', 1;
    END;

    -- Constraint & Integrity Verification: Check that student_id and submitted_by are identical
    IF EXISTS (
        SELECT 1
        FROM student_schema.grievance g
        JOIN student_schema.grievance_history h ON g.grievance_id = h.grievance_id
        WHERE g.student_id <> h.submitted_by
    )
    BEGIN
        THROW 52002, N'Integrity check failed: grievance.student_id and history.submitted_by must match.', 1;
    END;

    PRINT N'Constraint check verified: student_id = created_by = submitted_by across all 65 records.';

    COMMIT TRANSACTION;
    PRINT N'----------------------------------------------------------------------';
    PRINT N'GRIEVANCE 65-RECORD MOCK SEED COMPLETED SUCCESSFULLY';
    PRINT N'----------------------------------------------------------------------';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
