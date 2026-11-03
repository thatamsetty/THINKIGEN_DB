/*
================================================================================
SCRIPT:        028_insert_teacher_daily_progress_and_attentions_mock_data.js
MODULE:        Teacher Portal Management & Student Academic Health
DATABASE:      thinkigen (MongoDB)
TARGET COLLECTIONS:
               1. teacher_daily_progress_checklist
               2. student_subject_attentions

ARCHITECTURAL RULES & TEMPORAL CONSTRAINTS ENFORCED:
1. STRICT TEMPORAL PAST CONSTRAINT:
   - ONLY past dates (strictly <= 2026-10-30). Zero future dates inserted!
   - Historical timetable instructional dates: October 2026 (e.g. 2026-10-28, 2026-10-29, 2026-10-30).
   - All checklist task completions, assessment scores, pending homeworks, and attendance absences
     occurred on or before October 30, 2026.

2. PERFECT REFERENTIAL INTEGRITY WITH SQL SERVER (SSMS):
   - School ID: 1, Academic Year ID: 1 (2026-2027)
   - Branches: Branch 1 (Central Campus) & Branch 2 (North Campus)
   - Classes & Sections:
     * Class 1 ("Class 8 - Central"), Section 1 ("A") in Room-101
     * Class 1 ("Class 8 - Central"), Section 2 ("B") in Room-102
     * Class 3 ("Class 8 - North"), Section 5 ("A") in Room-21 (North Section 21)
   - Faculty:
     * Teacher 1:  Keshav Kulkarni   (English HOD, user_id: 101)
     * Teacher 8:  Zara Pai          (Mathematics HOD, user_id: 108)
     * Teacher 15: Bhuvan Solanki    (Science HOD, user_id: 115)
     * Teacher 22: Rashmi Chopra     (Social Science HOD, user_id: 122)
     * Teacher 29: Raghunath Mathur  (Computer Science HOD, user_id: 129)
     * Teacher 35: Abhiram Kansal    (Physical Education Director, user_id: 135)
     * Teacher 41: Ananya Swaminathan(North Campus English Faculty, user_id: 141)
     * Teacher 48: Devendra Shukla   (North Campus Mathematics HOD, user_id: 148)
   - Students (Section 1: Class 8 - Central, Section A):
     * Student 1:  Karishma Shaik    (user_id: 201, ADM-2026-0001, roll: R-01)
     * Student 2:  Dhamodhar Rao     (user_id: 202, ADM-2026-0002, roll: R-02)
     * Student 3:  Sita Ram          (user_id: 203, ADM-2026-0003, roll: R-03)
     * Student 4:  Krupa Joseph      (user_id: 204, ADM-2026-0004, roll: R-04)
     * Student 5:  Jeswanth Reddy    (user_id: 205, ADM-2026-0005, roll: R-05)
     * Student 6:  Sravan Kumar      (user_id: 206, ADM-2026-0006, roll: R-06)
     * Student 7:  Gaurav Joshi      (user_id: 207, ADM-2026-0007, roll: R-07)
     * Student 8:  Manish Talwar     (user_id: 208, ADM-2026-0008, roll: R-08)
     * Student 9:  Zara Tiwari       (user_id: 209, ADM-2026-0009, roll: R-09)
     * Student 10: Sarita Sengupta   (user_id: 210, ADM-2026-0010, roll: R-10)
     * Student 201: North Campus Class 8 Sec A Student (Branch 2)

3. FULL SCHEMA CONTRACT ADHERENCE:
   - teacher_daily_progress_checklist:
     * Unique key: (teacher_id, as_of_date)
     * previous_day_progress object with date, total_tasks, completed_tasks, completion_percent, status
     * checklist_items with item_id, task_title, task_type, timing, priority, is_completed
     * Nullable class_id/section_id for MEETING tasks
     * Pre-aggregated summary: total_items, completed_items, pending_items
   - student_subject_attentions:
     * Unique key: (student_id, academic_year_id)
     * All 6 subjects represented with assigned teachers
     * Full attention types: LOW_ASSESSMENT_SCORE, PENDING_HOMEWORK, ABSENT_ATTENDANCE
     * Mutual exclusivity of contextual detail objects (exactly one non-null per attention)
     * Pre-calculated active and critical attention counts accurately synchronized
================================================================================
*/

(function () {
    var targetDb = typeof db !== "undefined" ? db.getSiblingDB("thinkigen") : null;
    if (!targetDb) {
        throw new Error("Unable to resolve target MongoDB database 'thinkigen'.");
    }

    print("================================================================================");
    print("STARTING MOCK SEED: 028_insert_teacher_daily_progress_and_attentions_mock_data");
    print("Target Database: " + targetDb.getName());
    print("Timestamp:       " + new Date().toISOString());
    print("================================================================================");

    // =========================================================================
    // SECTION 1: SEED teacher_daily_progress_checklist
    // =========================================================================
    var COLL_CHECKLIST = "teacher_daily_progress_checklist";
    print("\n--- Processing Collection: " + COLL_CHECKLIST + " ---");

    var checklistSeedTeacherIds = [
        NumberInt(1),
        NumberInt(8),
        NumberInt(15),
        NumberInt(22),
        NumberInt(29),
        NumberInt(35),
        NumberInt(41),
        NumberInt(48)
    ];

    // Delete existing mock records for target teachers to guarantee clean idempotency
    var delChecklist = targetDb[COLL_CHECKLIST].deleteMany({
        teacher_id: { $in: checklistSeedTeacherIds }
    });
    print("[CLEANUP] Deleted " + delChecklist.deletedCount + " prior mock documents from " + COLL_CHECKLIST);

    var checklistDocs = [
        // ---------------------------------------------------------------------
        // 1. Teacher 1 (Keshav Kulkarni - Central English HOD) - As of 2026-10-30
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(1),
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-29T00:00:00Z"),
                total_tasks: NumberInt(5),
                completed_tasks: NumberInt(5),
                completion_percent: 100.0,
                status: "all_completed",
                summary_notes: "All 5 periods and English department moderation tasks completed."
            },
            checklist_items: [
                {
                    item_id: "CHK-T001-20261030-P3",
                    task_title: "Period 3 Attendance - Class 8 A English",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "Room-101",
                    timing: { from_time: "10:15", to_time: "11:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T11:02:00Z"),
                    completed_by_user_id: NumberInt(101),
                    reference_id: "TP-20261030-C1S1-P3",
                    remarks: "All 10 students marked; discussed Unseen Prose Reading Comprehension."
                },
                {
                    item_id: "CHK-T001-20261030-HWREV",
                    task_title: "Review Descriptive Narrative Essays - Section A",
                    task_type: "HOMEWORK_REVIEW",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "Room-101",
                    timing: { from_time: "11:15", to_time: "12:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T12:05:00Z"),
                    completed_by_user_id: NumberInt(101),
                    reference_id: "HW-ENG-20261026",
                    remarks: "Reviewed 9 submissions; annotated grammatical structures and paragraph cohesion."
                },
                {
                    item_id: "CHK-T001-20261030-P7",
                    task_title: "Period 7 Attendance - Class 8 B English",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(2),
                    section_name: "B",
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "Room-102",
                    timing: { from_time: "14:15", to_time: "15:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T15:01:00Z"),
                    completed_by_user_id: NumberInt(101),
                    reference_id: "TP-20261030-C1S2-P7",
                    remarks: "Conducted dialogue writing and direct speech transformation exercises."
                },
                {
                    item_id: "CHK-T001-20261030-MTG-HOD",
                    task_title: "English Faculty Curriculum Sync - Term 1 Blueprint Review",
                    task_type: "MEETING",
                    class_id: null,
                    class_name: null,
                    section_id: null,
                    section_name: null,
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "Conference Room A",
                    timing: { from_time: "15:15", to_time: "16:00" },
                    student_scope: null,
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T16:05:00Z"),
                    completed_by_user_id: NumberInt(101),
                    reference_id: "MTG-ENG-20261030",
                    remarks: "Aligned question paper blueprint following revised academic council guidelines."
                },
                {
                    item_id: "CHK-T001-20261030-RES",
                    task_title: "Publish Poetry Recitation Audio Guides to Learning Hub",
                    task_type: "RESOURCE_UPLOAD",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "Staff Room B",
                    timing: { from_time: "16:00", to_time: "16:30" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "LOW",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T16:28:00Z"),
                    completed_by_user_id: NumberInt(101),
                    reference_id: "RES-ENG-AUD-01",
                    remarks: "Uploaded MP3 audio and PDF transcript to Learning Hub resource collection."
                }
            ],
            summary: {
                total_items: NumberInt(5),
                completed_items: NumberInt(5),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T16:30:00Z")
        },

        // ---------------------------------------------------------------------
        // 2. Teacher 1 (Keshav Kulkarni) - As of 2026-10-29 (Longitudinal History)
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(1),
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-29T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-28T00:00:00Z"),
                total_tasks: NumberInt(4),
                completed_tasks: NumberInt(4),
                completion_percent: 100.0,
                status: "all_completed",
                summary_notes: "All scheduled Wednesday teaching periods marked."
            },
            checklist_items: [
                {
                    item_id: "CHK-T001-20261029-P4",
                    task_title: "Period 4 Attendance - Class 8 A English Formal Letters",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "Room-101",
                    timing: { from_time: "11:00", to_time: "11:45" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-29T11:46:00Z"),
                    completed_by_user_id: NumberInt(101),
                    reference_id: "TP-20261029-C1S1-P4",
                    remarks: "Letter to editor format demonstrated; Krupa Joseph unexcused absent."
                },
                {
                    item_id: "CHK-T001-20261029-EVAL",
                    task_title: "Evaluate English Slip Test Answer Sheets",
                    task_type: "ASSESSMENT_EVALUATION",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "Staff Room B",
                    timing: { from_time: "14:15", to_time: "15:30" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-29T15:35:00Z"),
                    completed_by_user_id: NumberInt(101),
                    reference_id: "ASM-ENG-ST1",
                    remarks: "Graded all 10 student answer sheets; marks recorded into ERP results ledger."
                }
            ],
            summary: {
                total_items: NumberInt(2),
                completed_items: NumberInt(2),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-29T07:30:00Z"),
            updated_at: new Date("2026-10-29T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 3. Teacher 8 (Zara Pai - Central Mathematics HOD) - As of 2026-10-30
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(8),
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-29T00:00:00Z"),
                total_tasks: NumberInt(6),
                completed_tasks: NumberInt(5),
                completion_percent: 83.33,
                status: "partially_completed",
                summary_notes: "5 of 6 tasks completed; remedial algebra group session rescheduled to Friday."
            },
            checklist_items: [
                {
                    item_id: "CHK-T008-20261030-P2",
                    task_title: "Period 2 Attendance - Class 8 A Mathematics",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    room_no: "Room-101",
                    timing: { from_time: "09:15", to_time: "10:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T10:02:00Z"),
                    completed_by_user_id: NumberInt(108),
                    reference_id: "TP-20261030-C1S1-P2",
                    remarks: "Conducted Graphical Solutions to Linear Equations; homework collection done."
                },
                {
                    item_id: "CHK-T008-20261030-ASMUT2",
                    task_title: "Evaluate Unit Test 2 Answer Papers (Section A)",
                    task_type: "ASSESSMENT_EVALUATION",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    room_no: "Math Faculty Cabin",
                    timing: { from_time: "10:15", to_time: "11:30" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T11:35:00Z"),
                    completed_by_user_id: NumberInt(108),
                    reference_id: "ASM-MAT-1002",
                    remarks: "Graded 10 papers; Karishma Shaik (14/50) and Manish Talwar (11/50) flagged below pass threshold."
                },
                {
                    item_id: "CHK-T008-20261030-P6",
                    task_title: "Period 6 Attendance - Class 8 A Problem Solving",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    room_no: "Room-101",
                    timing: { from_time: "13:15", to_time: "14:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T14:03:00Z"),
                    completed_by_user_id: NumberInt(108),
                    reference_id: "TP-20261030-C1S1-P6",
                    remarks: "Step-by-step problem solving on the board with student participation."
                },
                {
                    item_id: "CHK-T008-20261030-REM-GRP",
                    task_title: "Remedial Algebra Problem Solving Cohort",
                    task_type: "CLASSWORK",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    room_no: "Room-101",
                    timing: { from_time: "15:15", to_time: "16:00" },
                    student_scope: {
                        scope_type: "GROUP",
                        student_id: null,
                        student_name: null,
                        group_id: "GRP-REM-MAT-01",
                        group_name: "Remedial Algebra Cohort",
                        student_ids: [NumberInt(1), NumberInt(2), NumberInt(4), NumberInt(8)]
                    },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T16:02:00Z"),
                    completed_by_user_id: NumberInt(108),
                    reference_id: "REM-MAT-20261030",
                    remarks: "Focused drills on Cartesian quadrant sign rules and linear graph slope calculations."
                },
                {
                    item_id: "CHK-T008-20261030-MTG-HOD",
                    task_title: "Math Department Term Syllabus Milestone Sync",
                    task_type: "MEETING",
                    class_id: null,
                    class_name: null,
                    section_id: null,
                    section_name: null,
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    room_no: "Conference Room B",
                    timing: { from_time: "16:15", to_time: "17:00" },
                    student_scope: null,
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T17:05:00Z"),
                    completed_by_user_id: NumberInt(108),
                    reference_id: "MTG-MAT-20261030",
                    remarks: "Confirmed Term 1 syllabus completion status across Classes 8, 9, and 10."
                }
            ],
            summary: {
                total_items: NumberInt(5),
                completed_items: NumberInt(5),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T17:10:00Z")
        },

        // ---------------------------------------------------------------------
        // 4. Teacher 15 (Bhuvan Solanki - Central Science HOD) - As of 2026-10-30
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(15),
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-29T00:00:00Z"),
                total_tasks: NumberInt(4),
                completed_tasks: NumberInt(4),
                completion_percent: 100.0,
                status: "all_completed",
                summary_notes: "All 4 laboratory sessions and chemistry stock audits completed."
            },
            checklist_items: [
                {
                    item_id: "CHK-T015-20261030-P1",
                    task_title: "Period 1 Attendance - Class 8 A Science Lab Briefing",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(3),
                    subject_name: "Science",
                    room_no: "Science Lab 1",
                    timing: { from_time: "08:30", to_time: "09:15" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T09:16:00Z"),
                    completed_by_user_id: NumberInt(115),
                    reference_id: "TP-20261030-C1S1-P1",
                    remarks: "Conducted laboratory safety check and plant morphology overview."
                },
                {
                    item_id: "CHK-T015-20261030-P4",
                    task_title: "Period 4 Attendance - Class 8 A Plant Roots Observation Practical",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(3),
                    subject_name: "Science",
                    room_no: "Science Lab 1",
                    timing: { from_time: "11:00", to_time: "11:45" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T11:48:00Z"),
                    completed_by_user_id: NumberInt(115),
                    reference_id: "TP-20261030-C1S1-P4",
                    remarks: "Microscope root hair observations completed successfully."
                },
                {
                    item_id: "CHK-T015-20261030-RES",
                    task_title: "Upload Lab Manual Chapter 2 Diagrams & Experiment Guide",
                    task_type: "RESOURCE_UPLOAD",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(3),
                    subject_name: "Science",
                    room_no: "Science Staff Room",
                    timing: { from_time: "12:30", to_time: "13:15" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T13:10:00Z"),
                    completed_by_user_id: NumberInt(115),
                    reference_id: "RES-SCI-MAN-02",
                    remarks: "Published high-resolution diagram handbook for plant tissues."
                },
                {
                    item_id: "CHK-T015-20261030-MTG-SAFE",
                    task_title: "Science Laboratory Safety & Chemical Hood Inspection Sync",
                    task_type: "MEETING",
                    class_id: null,
                    class_name: null,
                    section_id: null,
                    section_name: null,
                    subject_id: NumberInt(3),
                    subject_name: "Science",
                    room_no: "Science Staff Room",
                    timing: { from_time: "14:30", to_time: "15:15" },
                    student_scope: null,
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T15:18:00Z"),
                    completed_by_user_id: NumberInt(115),
                    reference_id: "MTG-SCI-20261030",
                    remarks: "Reviewed repaired chemical fume hood exhaust airflow measurements with facility team."
                }
            ],
            summary: {
                total_items: NumberInt(4),
                completed_items: NumberInt(4),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T15:30:00Z")
        },

        // ---------------------------------------------------------------------
        // 5. Teacher 22 (Rashmi Chopra - Central Social Science HOD) - As of 2026-10-30
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(22),
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-29T00:00:00Z"),
                total_tasks: NumberInt(3),
                completed_tasks: NumberInt(3),
                completion_percent: 100.0,
                status: "all_completed",
                summary_notes: "All Social Science periods and Civics project reviews completed."
            },
            checklist_items: [
                {
                    item_id: "CHK-T022-20261030-P5",
                    task_title: "Period 5 Attendance - Class 8 A Social Science",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(4),
                    subject_name: "Social Science",
                    room_no: "Room-101",
                    timing: { from_time: "12:30", to_time: "13:15" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T13:17:00Z"),
                    completed_by_user_id: NumberInt(122),
                    reference_id: "TP-20261030-C1S1-P5",
                    remarks: "Topic: Indian Constitution & Fundamental Rights; interactive group debate."
                },
                {
                    item_id: "CHK-T022-20261030-HWREV",
                    task_title: "Verify History Project Portfolios - Revolt of 1857",
                    task_type: "HOMEWORK_REVIEW",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(4),
                    subject_name: "Social Science",
                    room_no: "Room-101",
                    timing: { from_time: "13:30", to_time: "14:15" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T14:18:00Z"),
                    completed_by_user_id: NumberInt(122),
                    reference_id: "HW-SST-1857",
                    remarks: "Verified primary source citations and timeline charts for Section A."
                },
                {
                    item_id: "CHK-T022-20261030-OTH-DISP",
                    task_title: "National Integration Week Display Board Update",
                    task_type: "OTHER",
                    class_id: null,
                    class_name: null,
                    section_id: null,
                    section_name: null,
                    subject_id: NumberInt(4),
                    subject_name: "Social Science",
                    room_no: "Central Quadrangle Notice Board",
                    timing: { from_time: "15:00", to_time: "15:45" },
                    student_scope: null,
                    priority: "LOW",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T15:42:00Z"),
                    completed_by_user_id: NumberInt(122),
                    reference_id: "EVT-SST-NIW",
                    remarks: "Mounted historical independence maps and student artwork on campus bulletin."
                }
            ],
            summary: {
                total_items: NumberInt(3),
                completed_items: NumberInt(3),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 6. Teacher 29 (Raghunath Mathur - Central CS HOD) - As of 2026-10-30
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(29),
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-29T00:00:00Z"),
                total_tasks: NumberInt(3),
                completed_tasks: NumberInt(3),
                completion_percent: 100.0,
                status: "all_completed",
                summary_notes: "All computer lab practicals and database query sessions executed."
            },
            checklist_items: [
                {
                    item_id: "CHK-T029-20261030-P3",
                    task_title: "Period 3 Attendance - Class 8 A Computer Science Lab",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(5),
                    subject_name: "Computer Science",
                    room_no: "Computer Lab 1",
                    timing: { from_time: "10:15", to_time: "11:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T11:01:00Z"),
                    completed_by_user_id: NumberInt(129),
                    reference_id: "TP-20261030-C1S1-P3",
                    remarks: "Hands-on coding: Python Functions & Dictionary Manipulation."
                },
                {
                    item_id: "CHK-T029-20261030-EVAL-PY",
                    task_title: "Evaluate Python Lab Assignment 3 Code Submissions",
                    task_type: "ASSESSMENT_EVALUATION",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(5),
                    subject_name: "Computer Science",
                    room_no: "Computer Lab 1",
                    timing: { from_time: "11:30", to_time: "12:30" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T12:28:00Z"),
                    completed_by_user_id: NumberInt(129),
                    reference_id: "ASM-CSC-LAB3",
                    remarks: "Checked indentation and test assertion pass rate; Dhamodhar Rao submission pending."
                },
                {
                    item_id: "CHK-T029-20261030-RES-SQL",
                    task_title: "Publish Relational Database Queries Practice Guide",
                    task_type: "RESOURCE_UPLOAD",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(5),
                    subject_name: "Computer Science",
                    room_no: "Computer Lab 1",
                    timing: { from_time: "14:00", to_time: "14:45" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "LOW",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T14:40:00Z"),
                    completed_by_user_id: NumberInt(129),
                    reference_id: "RES-CSC-SQL-01",
                    remarks: "Uploaded SQL interactive exercises with sample student schemas to Learning Hub."
                }
            ],
            summary: {
                total_items: NumberInt(3),
                completed_items: NumberInt(3),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T15:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 7. Teacher 35 (Abhiram Kansal - Central PE Director) - As of 2026-10-30
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(35),
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-29T00:00:00Z"),
                total_tasks: NumberInt(3),
                completed_tasks: NumberInt(3),
                completion_percent: 100.0,
                status: "all_completed",
                summary_notes: "Track events and morning physical training drills completed."
            },
            checklist_items: [
                {
                    item_id: "CHK-T035-20261030-MTG-SPORTS",
                    task_title: "Inter-House Athletic Meet Committee Sync",
                    task_type: "MEETING",
                    class_id: null,
                    class_name: null,
                    section_id: null,
                    section_name: null,
                    subject_id: NumberInt(6),
                    subject_name: "Physical Education",
                    room_no: "Sports Complex Office",
                    timing: { from_time: "10:00", to_time: "11:00" },
                    student_scope: null,
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T11:05:00Z"),
                    completed_by_user_id: NumberInt(135),
                    reference_id: "MTG-PE-ATH-2026",
                    remarks: "Finalized track schedules and appointed student house captains."
                },
                {
                    item_id: "CHK-T035-20261030-P7",
                    task_title: "Period 7 Attendance - Class 8 A Physical Education",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(6),
                    subject_name: "Physical Education",
                    room_no: "Sports Ground",
                    timing: { from_time: "14:15", to_time: "15:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T15:02:00Z"),
                    completed_by_user_id: NumberInt(135),
                    reference_id: "TP-20261030-C1S1-P7",
                    remarks: "Conducted football agility drills and sprint technique sessions."
                },
                {
                    item_id: "CHK-T035-20261030-OTH-AUDIT",
                    task_title: "First Aid Kit & Sports Ground Equipment Safety Audit",
                    task_type: "OTHER",
                    class_id: null,
                    class_name: null,
                    section_id: null,
                    section_name: null,
                    subject_id: NumberInt(6),
                    subject_name: "Physical Education",
                    room_no: "Sports Pavilion",
                    timing: { from_time: "15:15", to_time: "16:00" },
                    student_scope: null,
                    priority: "LOW",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T15:58:00Z"),
                    completed_by_user_id: NumberInt(135),
                    reference_id: "AUD-PE-20261030",
                    remarks: "Replenished antiseptic bandages and cold packs in athletic store."
                }
            ],
            summary: {
                total_items: NumberInt(3),
                completed_items: NumberInt(3),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T16:15:00Z")
        },

        // ---------------------------------------------------------------------
        // 8. Teacher 41 (Ananya Swaminathan - North English Faculty) - As of 2026-10-30
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(41),
            school_id: NumberInt(1),
            branch_id: NumberInt(2),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-29T00:00:00Z"),
                total_tasks: NumberInt(3),
                completed_tasks: NumberInt(3),
                completion_percent: 100.0,
                status: "all_completed",
                summary_notes: "North Campus Class 8 English sessions completed."
            },
            checklist_items: [
                {
                    item_id: "CHK-T041-20261030-P1",
                    task_title: "Period 1 Attendance - Class 8 North Sec A English",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(3),
                    class_name: "Class 8 - North",
                    section_id: NumberInt(5),
                    section_name: "A",
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "Room-21",
                    timing: { from_time: "08:30", to_time: "09:15" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T09:17:00Z"),
                    completed_by_user_id: NumberInt(141),
                    reference_id: "TP-20261030-C3S5-P1",
                    remarks: "Conducted grammar transformation exercises in Room-21."
                },
                {
                    item_id: "CHK-T041-20261030-HWREV",
                    task_title: "North Campus Section A Grammar Workbook Correction",
                    task_type: "HOMEWORK_REVIEW",
                    class_id: NumberInt(3),
                    class_name: "Class 8 - North",
                    section_id: NumberInt(5),
                    section_name: "A",
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    room_no: "North Staff Room",
                    timing: { from_time: "10:15", to_time: "11:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T11:02:00Z"),
                    completed_by_user_id: NumberInt(141),
                    reference_id: "HW-ENG-N-01",
                    remarks: "Corrected 10 workbooks on Reported Speech conversions."
                }
            ],
            summary: {
                total_items: NumberInt(2),
                completed_items: NumberInt(2),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T11:30:00Z")
        },

        // ---------------------------------------------------------------------
        // 9. Teacher 48 (Devendra Shukla - North Math HOD) - As of 2026-10-30
        // ---------------------------------------------------------------------
        {
            teacher_id: NumberInt(48),
            school_id: NumberInt(1),
            branch_id: NumberInt(2),
            academic_year_id: NumberInt(1),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            previous_day_progress: {
                date: new Date("2026-10-29T00:00:00Z"),
                total_tasks: NumberInt(3),
                completed_tasks: NumberInt(3),
                completion_percent: 100.0,
                status: "all_completed",
                summary_notes: "All North campus math classes and remedial sessions completed."
            },
            checklist_items: [
                {
                    item_id: "CHK-T048-20261030-P2",
                    task_title: "Period 2 Attendance - Class 8 North Sec A Mathematics",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(3),
                    class_name: "Class 8 - North",
                    section_id: NumberInt(5),
                    section_name: "A",
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    room_no: "Room-21",
                    timing: { from_time: "09:15", to_time: "10:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T10:01:00Z"),
                    completed_by_user_id: NumberInt(148),
                    reference_id: "TP-20261030-C3S5-P2",
                    remarks: "Taught Quadratic Equations factorization methods in Room-21."
                },
                {
                    item_id: "CHK-T048-20261030-MTG",
                    task_title: "North Campus Academic Progress & Faculty Review",
                    task_type: "MEETING",
                    class_id: null,
                    class_name: null,
                    section_id: null,
                    section_name: null,
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    room_no: "North Conference Room",
                    timing: { from_time: "11:15", to_time: "12:15" },
                    student_scope: null,
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T12:18:00Z"),
                    completed_by_user_id: NumberInt(148),
                    reference_id: "MTG-NORTH-ACAD",
                    remarks: "Conducted Term-1 review with North Campus Principal (user_id: 4)."
                }
            ],
            summary: {
                total_items: NumberInt(2),
                completed_items: NumberInt(2),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T12:30:00Z")
        }
    ];

    var insertChecklistRes = targetDb[COLL_CHECKLIST].insertMany(checklistDocs);
    print("[SUCCESS] Inserted " + Object.keys(insertChecklistRes.insertedIds).length + " documents into " + COLL_CHECKLIST);


    // =========================================================================
    // SECTION 2: SEED student_subject_attentions
    // =========================================================================
    var COLL_ATTENTIONS = "student_subject_attentions";
    print("\n--- Processing Collection: " + COLL_ATTENTIONS + " ---");

    var attentionStudentIds = [
        NumberInt(1),
        NumberInt(2),
        NumberInt(3),
        NumberInt(4),
        NumberInt(5),
        NumberInt(6),
        NumberInt(7),
        NumberInt(8),
        NumberInt(9),
        NumberInt(10),
        NumberInt(201)
    ];

    // Delete existing mock records for target students to guarantee clean idempotency
    var delAttentions = targetDb[COLL_ATTENTIONS].deleteMany({
        student_id: { $in: attentionStudentIds },
        academic_year_id: NumberInt(1)
    });
    print("[CLEANUP] Deleted " + delAttentions.deletedCount + " prior mock documents from " + COLL_ATTENTIONS);

    // Standard subjects array template helper for Section 1 (Central Campus)
    function buildSection1Subjects(studentId, subjectOverrides) {
        var baseSubjects = [
            {
                subject_id: NumberInt(1),
                subject_name: "English",
                subject_code: "ENG",
                assigned_teacher_id: NumberInt(1),
                assigned_teacher_name: "Keshav Kulkarni",
                active_attentions_count: NumberInt(0),
                attentions: [],
                subject_summary: {
                    assessments_passed: NumberInt(4),
                    assessments_failed: NumberInt(0),
                    homework_submitted: NumberInt(8),
                    homework_pending: NumberInt(0),
                    subject_attendance_percent: 96.0
                }
            },
            {
                subject_id: NumberInt(2),
                subject_name: "Mathematics",
                subject_code: "MAT",
                assigned_teacher_id: NumberInt(8),
                assigned_teacher_name: "Zara Pai",
                active_attentions_count: NumberInt(0),
                attentions: [],
                subject_summary: {
                    assessments_passed: NumberInt(3),
                    assessments_failed: NumberInt(0),
                    homework_submitted: NumberInt(7),
                    homework_pending: NumberInt(0),
                    subject_attendance_percent: 94.0
                }
            },
            {
                subject_id: NumberInt(3),
                subject_name: "Science",
                subject_code: "SCI",
                assigned_teacher_id: NumberInt(15),
                assigned_teacher_name: "Bhuvan Solanki",
                active_attentions_count: NumberInt(0),
                attentions: [],
                subject_summary: {
                    assessments_passed: NumberInt(3),
                    assessments_failed: NumberInt(0),
                    homework_submitted: NumberInt(7),
                    homework_pending: NumberInt(0),
                    subject_attendance_percent: 95.0
                }
            },
            {
                subject_id: NumberInt(4),
                subject_name: "Social Science",
                subject_code: "SST",
                assigned_teacher_id: NumberInt(22),
                assigned_teacher_name: "Rashmi Chopra",
                active_attentions_count: NumberInt(0),
                attentions: [],
                subject_summary: {
                    assessments_passed: NumberInt(3),
                    assessments_failed: NumberInt(0),
                    homework_submitted: NumberInt(6),
                    homework_pending: NumberInt(0),
                    subject_attendance_percent: 97.0
                }
            },
            {
                subject_id: NumberInt(5),
                subject_name: "Computer Science",
                subject_code: "CSC",
                assigned_teacher_id: NumberInt(29),
                assigned_teacher_name: "Raghunath Mathur",
                active_attentions_count: NumberInt(0),
                attentions: [],
                subject_summary: {
                    assessments_passed: NumberInt(3),
                    assessments_failed: NumberInt(0),
                    homework_submitted: NumberInt(6),
                    homework_pending: NumberInt(0),
                    subject_attendance_percent: 98.0
                }
            },
            {
                subject_id: NumberInt(6),
                subject_name: "Physical Education",
                subject_code: "PE",
                assigned_teacher_id: NumberInt(35),
                assigned_teacher_name: "Abhiram Kansal",
                active_attentions_count: NumberInt(0),
                attentions: [],
                subject_summary: {
                    assessments_passed: NumberInt(2),
                    assessments_failed: NumberInt(0),
                    homework_submitted: NumberInt(4),
                    homework_pending: NumberInt(0),
                    subject_attendance_percent: 100.0
                }
            }
        ];

        // Apply overrides if provided for specific subjects
        if (subjectOverrides) {
            subjectOverrides.forEach(function (override) {
                var found = baseSubjects.find(function (s) {
                    return s.subject_id.toString() === override.subject_id.toString();
                });
                if (found) {
                    found.active_attentions_count = override.active_attentions_count;
                    found.attentions = override.attentions;
                    if (override.subject_summary) {
                        found.subject_summary = override.subject_summary;
                    }
                }
            });
        }

        return baseSubjects;
    }

    var attentionDocs = [
        // ---------------------------------------------------------------------
        // 1. Student 1: Karishma Shaik (ADM-2026-0001, roll: R-01, Class 8 Central Sec A)
        // Profile: 1 Critical (Math Low Score), 1 High (Math Pending HW), 1 High (Science Absent)
        // 1 Resolved (English HW)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(1),
            student_name: "Karishma Shaik",
            admission_number: "ADM-2026-0001",
            roll_number: "R-01",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(3),
            critical_attentions_count: NumberInt(1),
            subjects: buildSection1Subjects(1, [
                {
                    subject_id: NumberInt(1), // English
                    active_attentions_count: NumberInt(0),
                    attentions: [
                        {
                            attention_id: "ATT-S001-ENG-HW01-2026",
                            attention_type: "PENDING_HOMEWORK",
                            severity: "MEDIUM",
                            title: "Overdue Poetry Analysis Essay - The Road Not Taken",
                            description: "Poetry analysis essay assigned on Oct 12 was delayed but submitted late after teacher guidance.",
                            trigger_source: "ASSIGNMENT_HOMEWORK",
                            source_id: NumberInt(3001),
                            triggered_at: new Date("2026-10-16T09:00:00Z"),
                            status: "RESOLVED",
                            acknowledged_at: new Date("2026-10-16T11:00:00Z"),
                            acknowledged_by_teacher_id: NumberInt(1),
                            resolved_at: new Date("2026-10-18T14:30:00Z"),
                            resolved_by_teacher_id: NumberInt(1),
                            resolution_remarks: "Student submitted completed handwritten essay with annotations; evaluated and accepted.",
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: {
                                homework_id: NumberInt(3001),
                                homework_title: "Poetry Analysis - The Road Not Taken",
                                assigned_date: new Date("2026-10-12T00:00:00Z"),
                                due_date: new Date("2026-10-15T00:00:00Z"),
                                days_overdue: NumberInt(2),
                                submission_status: "LATE"
                            },
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(4),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(8),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 94.5
                    }
                },
                {
                    subject_id: NumberInt(2), // Mathematics
                    active_attentions_count: NumberInt(2),
                    attentions: [
                        {
                            attention_id: "ATT-S001-MAT-ASM01-2026",
                            attention_type: "LOW_ASSESSMENT_SCORE",
                            severity: "CRITICAL",
                            title: "Low Assessment Score in Unit Test 2 (Linear Equations)",
                            description: "Student obtained 14.0 marks out of 50.0, below the minimum passing threshold of 20.0 (28.0%).",
                            trigger_source: "ASSESSMENT",
                            source_id: NumberInt(1002),
                            triggered_at: new Date("2026-10-16T14:00:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: new Date("2026-10-17T09:30:00Z"),
                            acknowledged_by_teacher_id: NumberInt(8),
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: {
                                assessment_id: NumberInt(1002),
                                assessment_name: "Unit Test 2 - Linear Equations in Two Variables",
                                exam_type: "UNIT_TEST",
                                max_marks: 50.0,
                                pass_marks: 20.0,
                                obtained_marks: 14.0,
                                percentage: 28.0
                            },
                            homework_details: null,
                            attendance_details: null
                        },
                        {
                            attention_id: "ATT-S001-MAT-HW02-2026",
                            attention_type: "PENDING_HOMEWORK",
                            severity: "HIGH",
                            title: "Pending Homework: Ex 4.2 Linear Graph Plotting",
                            description: "Homework assigned on Oct 19 was not submitted by due date Oct 23. Currently 7 days overdue.",
                            trigger_source: "ASSIGNMENT_HOMEWORK",
                            source_id: NumberInt(3005),
                            triggered_at: new Date("2026-10-24T08:00:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: null,
                            acknowledged_by_teacher_id: null,
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: {
                                homework_id: NumberInt(3005),
                                homework_title: "Exercise 4.2 Graphical Solutions of Linear Equations",
                                assigned_date: new Date("2026-10-19T00:00:00Z"),
                                due_date: new Date("2026-10-23T00:00:00Z"),
                                days_overdue: NumberInt(7),
                                submission_status: "NOT_SUBMITTED"
                            },
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(2),
                        assessments_failed: NumberInt(1),
                        homework_submitted: NumberInt(5),
                        homework_pending: NumberInt(1),
                        subject_attendance_percent: 91.0
                    }
                },
                {
                    subject_id: NumberInt(3), // Science
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S001-SCI-ATT01-2026",
                            attention_type: "ABSENT_ATTENDANCE",
                            severity: "HIGH",
                            title: "Unexcused Absence in Science Laboratory Practical",
                            description: "Student was absent during Period 4 Science Lab session on Plant Roots and Stem morphology on Oct 21.",
                            trigger_source: "ATTENDANCE",
                            source_id: NumberInt(4012),
                            triggered_at: new Date("2026-10-21T11:50:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: null,
                            acknowledged_by_teacher_id: null,
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: null,
                            attendance_details: {
                                attendance_id: NumberInt(4012),
                                attendance_date: new Date("2026-10-21T00:00:00Z"),
                                period_number: NumberInt(4),
                                period_time: "11:00 - 11:45",
                                attendance_status: "ABSENT"
                            }
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 88.5
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-16T14:05:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 2. Student 2: Dhamodhar Rao (ADM-2026-0002, roll: R-02, Class 8 Central Sec A)
        // Profile: 1 Medium (SST Quiz), 1 High (CS Homework)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(2),
            student_name: "Dhamodhar Rao",
            admission_number: "ADM-2026-0002",
            roll_number: "R-02",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(2),
            critical_attentions_count: NumberInt(0),
            subjects: buildSection1Subjects(2, [
                {
                    subject_id: NumberInt(4), // Social Science
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S002-SST-ASM01-2026",
                            attention_type: "LOW_ASSESSMENT_SCORE",
                            severity: "MEDIUM",
                            title: "Low Assessment Score in Civics Quick Quiz",
                            description: "Student obtained 15.0 marks out of 40.0, below the required pass mark of 18.0 (37.5%).",
                            trigger_source: "ASSESSMENT",
                            source_id: NumberInt(1014),
                            triggered_at: new Date("2026-10-22T14:30:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: new Date("2026-10-23T10:00:00Z"),
                            acknowledged_by_teacher_id: NumberInt(22),
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: {
                                assessment_id: NumberInt(1014),
                                assessment_name: "Class Quiz - Indian Constitution and Preamble",
                                exam_type: "SLIP_TEST",
                                max_marks: 40.0,
                                pass_marks: 18.0,
                                obtained_marks: 15.0,
                                percentage: 37.5
                            },
                            homework_details: null,
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(2),
                        assessments_failed: NumberInt(1),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 92.0
                    }
                },
                {
                    subject_id: NumberInt(5), // Computer Science
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S002-CSC-HW01-2026",
                            attention_type: "PENDING_HOMEWORK",
                            severity: "HIGH",
                            title: "Overdue Homework: Python Loop Programming Lab 3",
                            description: "Programming assignment on while loops assigned Oct 23 was not submitted by due date Oct 27 (3 days overdue).",
                            trigger_source: "ASSIGNMENT_HOMEWORK",
                            source_id: NumberInt(3012),
                            triggered_at: new Date("2026-10-28T08:00:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: null,
                            acknowledged_by_teacher_id: null,
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: {
                                homework_id: NumberInt(3012),
                                homework_title: "Python Lab 3: Loop Iterations and Break Logic",
                                assigned_date: new Date("2026-10-23T00:00:00Z"),
                                due_date: new Date("2026-10-27T00:00:00Z"),
                                days_overdue: NumberInt(3),
                                submission_status: "PENDING"
                            },
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(5),
                        homework_pending: NumberInt(1),
                        subject_attendance_percent: 95.0
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-22T14:35:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 3. Student 3: Sita Ram (ADM-2026-0003, roll: R-03, Class 8 Central Sec A)
        // Profile: 1 Critical (Science Chemistry Test)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(3),
            student_name: "Sita Ram",
            admission_number: "ADM-2026-0003",
            roll_number: "R-03",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(1),
            critical_attentions_count: NumberInt(1),
            subjects: buildSection1Subjects(3, [
                {
                    subject_id: NumberInt(3), // Science
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S003-SCI-ASM01-2026",
                            attention_type: "LOW_ASSESSMENT_SCORE",
                            severity: "CRITICAL",
                            title: "Low Assessment Score in Chemistry Lab Safety Slip Test",
                            description: "Student obtained 8.0 marks out of 25.0, below the required pass mark of 12.0 (32.0%).",
                            trigger_source: "ASSESSMENT",
                            source_id: NumberInt(1019),
                            triggered_at: new Date("2026-10-19T11:30:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: new Date("2026-10-20T09:00:00Z"),
                            acknowledged_by_teacher_id: NumberInt(15),
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: {
                                assessment_id: NumberInt(1019),
                                assessment_name: "Chemistry Lab Safety & Hazard Identification Slip Test",
                                exam_type: "SLIP_TEST",
                                max_marks: 25.0,
                                pass_marks: 12.0,
                                obtained_marks: 8.0,
                                percentage: 32.0
                            },
                            homework_details: null,
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(2),
                        assessments_failed: NumberInt(1),
                        homework_submitted: NumberInt(7),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 93.0
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-19T11:35:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 4. Student 4: Krupa Joseph (ADM-2026-0004, roll: R-04, Class 8 Central Sec A)
        // Profile: 1 Medium (English Attendance Absence), 1 High (Math Pending HW)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(4),
            student_name: "Krupa Joseph",
            admission_number: "ADM-2026-0004",
            roll_number: "R-04",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(2),
            critical_attentions_count: NumberInt(0),
            subjects: buildSection1Subjects(4, [
                {
                    subject_id: NumberInt(1), // English
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S004-ENG-ATT01-2026",
                            attention_type: "ABSENT_ATTENDANCE",
                            severity: "MEDIUM",
                            title: "Unexcused Absence in English Formal Writing Lecture",
                            description: "Student was recorded absent without prior notice during Period 3 Formal Letter Writing on Oct 27.",
                            trigger_source: "ATTENDANCE",
                            source_id: NumberInt(4028),
                            triggered_at: new Date("2026-10-27T11:05:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: null,
                            acknowledged_by_teacher_id: null,
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: null,
                            attendance_details: {
                                attendance_id: NumberInt(4028),
                                attendance_date: new Date("2026-10-27T00:00:00Z"),
                                period_number: NumberInt(3),
                                period_time: "10:15 - 11:00",
                                attendance_status: "UNEXCUSED_ABSENCE"
                            }
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 89.0
                    }
                },
                {
                    subject_id: NumberInt(2), // Mathematics
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S004-MAT-HW01-2026",
                            attention_type: "PENDING_HOMEWORK",
                            severity: "HIGH",
                            title: "Pending Homework: Algebraic Identities Derivation Worksheet",
                            description: "Worksheet on (a+b)^2 and (a-b)^2 assigned Oct 26 was due on Oct 29; 1 day overdue.",
                            trigger_source: "ASSIGNMENT_HOMEWORK",
                            source_id: NumberInt(3022),
                            triggered_at: new Date("2026-10-30T08:00:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: null,
                            acknowledged_by_teacher_id: null,
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: {
                                homework_id: NumberInt(3022),
                                homework_title: "Algebraic Identities Derivations and Practice 3.1",
                                assigned_date: new Date("2026-10-26T00:00:00Z"),
                                due_date: new Date("2026-10-29T00:00:00Z"),
                                days_overdue: NumberInt(1),
                                submission_status: "PENDING"
                            },
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(1),
                        subject_attendance_percent: 92.5
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-27T11:10:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 5. Student 5: Jeswanth Reddy (ADM-2026-0005, roll: R-05, Class 8 Central Sec A)
        // Profile: 1 High (CS Low Assessment Score), 1 Low (PE Attendance - Acknowledged/Medical)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(5),
            student_name: "Jeswanth Reddy",
            admission_number: "ADM-2026-0005",
            roll_number: "R-05",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(1),
            critical_attentions_count: NumberInt(0),
            subjects: buildSection1Subjects(5, [
                {
                    subject_id: NumberInt(5), // Computer Science
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S005-CSC-ASM01-2026",
                            attention_type: "LOW_ASSESSMENT_SCORE",
                            severity: "HIGH",
                            title: "Low Assessment Score in SQL Basic Clauses Test",
                            description: "Student obtained 14.0 marks out of 35.0, below the required pass mark of 15.0 (40.0%).",
                            trigger_source: "ASSESSMENT",
                            source_id: NumberInt(1025),
                            triggered_at: new Date("2026-10-28T14:00:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: new Date("2026-10-29T10:15:00Z"),
                            acknowledged_by_teacher_id: NumberInt(29),
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: {
                                assessment_id: NumberInt(1025),
                                assessment_name: "SQL Queries - WHERE, ORDER BY and Aggregate Clauses Test",
                                exam_type: "SLIP_TEST",
                                max_marks: 35.0,
                                pass_marks: 15.0,
                                obtained_marks: 14.0,
                                percentage: 40.0
                            },
                            homework_details: null,
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(2),
                        assessments_failed: NumberInt(1),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 94.0
                    }
                },
                {
                    subject_id: NumberInt(6), // Physical Education
                    active_attentions_count: NumberInt(0),
                    attentions: [
                        {
                            attention_id: "ATT-S005-PE-ATT01-2026",
                            attention_type: "ABSENT_ATTENDANCE",
                            severity: "LOW",
                            title: "Absence in Sports Ground Track Sprints Drill",
                            description: "Student was absent for Period 7 PE sprints on Oct 23; medical slip submitted next day.",
                            trigger_source: "ATTENDANCE",
                            source_id: NumberInt(4036),
                            triggered_at: new Date("2026-10-23T15:10:00Z"),
                            status: "ACKNOWLEDGED",
                            acknowledged_at: new Date("2026-10-24T09:30:00Z"),
                            acknowledged_by_teacher_id: NumberInt(35),
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: "Minor ankle sprain documented by school infirmary.",
                            assessment_details: null,
                            homework_details: null,
                            attendance_details: {
                                attendance_id: NumberInt(4036),
                                attendance_date: new Date("2026-10-23T00:00:00Z"),
                                period_number: NumberInt(7),
                                period_time: "14:15 - 15:00",
                                attendance_status: "ABSENT"
                            }
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(2),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(4),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 95.0
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-23T15:15:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 6. Student 6: Sravan Kumar (ADM-2026-0006, roll: R-06, Class 8 Central Sec A)
        // Profile: Exemplary student, 0 active attentions, 1 resolved past homework
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(6),
            student_name: "Sravan Kumar",
            admission_number: "ADM-2026-0006",
            roll_number: "R-06",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(0),
            critical_attentions_count: NumberInt(0),
            subjects: buildSection1Subjects(6, [
                {
                    subject_id: NumberInt(2), // Mathematics
                    active_attentions_count: NumberInt(0),
                    attentions: [
                        {
                            attention_id: "ATT-S006-MAT-HW01-2026",
                            attention_type: "PENDING_HOMEWORK",
                            severity: "LOW",
                            title: "Minor Delay in Coordinate Geometry Graph Sheet Submission",
                            description: "Graph sheet due Oct 14 was turned in Oct 15 with teacher approval.",
                            trigger_source: "ASSIGNMENT_HOMEWORK",
                            source_id: NumberInt(3003),
                            triggered_at: new Date("2026-10-14T16:00:00Z"),
                            status: "RESOLVED",
                            acknowledged_at: new Date("2026-10-15T08:30:00Z"),
                            acknowledged_by_teacher_id: NumberInt(8),
                            resolved_at: new Date("2026-10-15T14:00:00Z"),
                            resolved_by_teacher_id: NumberInt(8),
                            resolution_remarks: "Submitted complete graph work; perfect scores awarded.",
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: {
                                homework_id: NumberInt(3003),
                                homework_title: "Coordinate Geometry Cartesian Graphing Exercise",
                                assigned_date: new Date("2026-10-10T00:00:00Z"),
                                due_date: new Date("2026-10-14T00:00:00Z"),
                                days_overdue: NumberInt(1),
                                submission_status: "LATE"
                            },
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(8),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 98.0
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-14T16:05:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 7. Student 7: Gaurav Joshi (ADM-2026-0007, roll: R-07, Class 8 Central Sec A)
        // Profile: 1 Medium (English Homework Pending)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(7),
            student_name: "Gaurav Joshi",
            admission_number: "ADM-2026-0007",
            roll_number: "R-07",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(1),
            critical_attentions_count: NumberInt(0),
            subjects: buildSection1Subjects(7, [
                {
                    subject_id: NumberInt(1), // English
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S007-ENG-HW01-2026",
                            attention_type: "PENDING_HOMEWORK",
                            severity: "MEDIUM",
                            title: "Pending Homework: Unseen Prose Comprehension Worksheet",
                            description: "Worksheet on unseen prose analysis assigned Oct 26 due Oct 29 not submitted; 1 day overdue.",
                            trigger_source: "ASSIGNMENT_HOMEWORK",
                            source_id: NumberInt(3029),
                            triggered_at: new Date("2026-10-30T08:00:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: null,
                            acknowledged_by_teacher_id: null,
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: {
                                homework_id: NumberInt(3029),
                                homework_title: "Reading Comprehension and Vocabulary Exercises",
                                assigned_date: new Date("2026-10-26T00:00:00Z"),
                                due_date: new Date("2026-10-29T00:00:00Z"),
                                days_overdue: NumberInt(1),
                                submission_status: "PENDING"
                            },
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(1),
                        subject_attendance_percent: 95.0
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T08:05:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 8. Student 8: Manish Talwar (ADM-2026-0008, roll: R-08, Class 8 Central Sec A)
        // Profile: 1 Critical (Math Low Score - 11/50)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(8),
            student_name: "Manish Talwar",
            admission_number: "ADM-2026-0008",
            roll_number: "R-08",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(1),
            critical_attentions_count: NumberInt(1),
            subjects: buildSection1Subjects(8, [
                {
                    subject_id: NumberInt(2), // Mathematics
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S008-MAT-ASM01-2026",
                            attention_type: "LOW_ASSESSMENT_SCORE",
                            severity: "CRITICAL",
                            title: "Critical Low Score in Unit Test 2 Linear Equations",
                            description: "Student obtained 11.0 marks out of 50.0, below the required pass mark of 20.0 (22.0%).",
                            trigger_source: "ASSESSMENT",
                            source_id: NumberInt(1002),
                            triggered_at: new Date("2026-10-16T14:00:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: new Date("2026-10-17T11:00:00Z"),
                            acknowledged_by_teacher_id: NumberInt(8),
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: {
                                assessment_id: NumberInt(1002),
                                assessment_name: "Unit Test 2 - Linear Equations in Two Variables",
                                exam_type: "UNIT_TEST",
                                max_marks: 50.0,
                                pass_marks: 20.0,
                                obtained_marks: 11.0,
                                percentage: 22.0
                            },
                            homework_details: null,
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(2),
                        assessments_failed: NumberInt(1),
                        homework_submitted: NumberInt(5),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 91.5
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-16T14:05:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 9. Student 9: Zara Tiwari (ADM-2026-0009, roll: R-09, Class 8 Central Sec A)
        // Profile: 1 Medium (Social Science Attendance Absence)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(9),
            student_name: "Zara Tiwari",
            admission_number: "ADM-2026-0009",
            roll_number: "R-09",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(1),
            critical_attentions_count: NumberInt(0),
            subjects: buildSection1Subjects(9, [
                {
                    subject_id: NumberInt(4), // Social Science
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S009-SST-ATT01-2026",
                            attention_type: "ABSENT_ATTENDANCE",
                            severity: "MEDIUM",
                            title: "Unexcused Absence in Civics Case Study Period",
                            description: "Student was absent for Period 5 Civics case study on fundamental rights on Oct 28.",
                            trigger_source: "ATTENDANCE",
                            source_id: NumberInt(4041),
                            triggered_at: new Date("2026-10-28T13:20:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: null,
                            acknowledged_by_teacher_id: null,
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: null,
                            homework_details: null,
                            attendance_details: {
                                attendance_id: NumberInt(4041),
                                attendance_date: new Date("2026-10-28T00:00:00Z"),
                                period_number: NumberInt(5),
                                period_time: "12:30 - 13:15",
                                attendance_status: "ABSENT"
                            }
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(7),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 91.0
                    }
                }
            ]),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-28T13:25:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 10. Student 10: Sarita Sengupta (ADM-2026-0010, roll: R-10, Class 8 Central Sec A)
        // Profile: Top honor roll scholar, 0 active attentions, 100% attendance
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(10),
            student_name: "Sarita Sengupta",
            admission_number: "ADM-2026-0010",
            roll_number: "R-10",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(1),
            section_name: "A",
            total_active_attentions: NumberInt(0),
            critical_attentions_count: NumberInt(0),
            subjects: buildSection1Subjects(10, []),
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-15T09:00:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        },

        // ---------------------------------------------------------------------
        // 11. Student 201: North Campus Student (Branch 2, Class 8 North Sec A)
        // Profile: 1 Critical (Math Unit Test 1 Low Score)
        // ---------------------------------------------------------------------
        {
            student_id: NumberInt(201),
            student_name: "Rohan Varma",
            admission_number: "ADM-2026-0201",
            roll_number: "R-01",
            school_id: NumberInt(1),
            branch_id: NumberInt(2),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(3),
            class_name: "Class 8 - North",
            section_id: NumberInt(5),
            section_name: "A",
            total_active_attentions: NumberInt(1),
            critical_attentions_count: NumberInt(1),
            subjects: [
                {
                    subject_id: NumberInt(1),
                    subject_name: "English",
                    subject_code: "ENG",
                    assigned_teacher_id: NumberInt(41),
                    assigned_teacher_name: "Ananya Swaminathan",
                    active_attentions_count: NumberInt(0),
                    attentions: [],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 95.0
                    }
                },
                {
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    subject_code: "MAT",
                    assigned_teacher_id: NumberInt(48),
                    assigned_teacher_name: "Devendra Shukla",
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-S201-MAT-ASM01-2026",
                            attention_type: "LOW_ASSESSMENT_SCORE",
                            severity: "CRITICAL",
                            title: "Low Assessment Score in North Campus Math Unit Test 1",
                            description: "Student obtained 12.0 marks out of 50.0, below the required pass mark of 20.0 (24.0%).",
                            trigger_source: "ASSESSMENT",
                            source_id: NumberInt(1051),
                            triggered_at: new Date("2026-10-20T14:30:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: new Date("2026-10-21T10:00:00Z"),
                            acknowledged_by_teacher_id: NumberInt(48),
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: {
                                assessment_id: NumberInt(1051),
                                assessment_name: "Unit Test 1 - Algebraic Identities and Polynomials",
                                exam_type: "UNIT_TEST",
                                max_marks: 50.0,
                                pass_marks: 20.0,
                                obtained_marks: 12.0,
                                percentage: 24.0
                            },
                            homework_details: null,
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(2),
                        assessments_failed: NumberInt(1),
                        homework_submitted: NumberInt(5),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 92.0
                    }
                },
                {
                    subject_id: NumberInt(3),
                    subject_name: "Science",
                    subject_code: "SCI",
                    assigned_teacher_id: NumberInt(55),
                    assigned_teacher_name: "Vandana Rao",
                    active_attentions_count: NumberInt(0),
                    attentions: [],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 96.0
                    }
                },
                {
                    subject_id: NumberInt(4),
                    subject_name: "Social Science",
                    subject_code: "SST",
                    assigned_teacher_id: NumberInt(62),
                    assigned_teacher_name: "Kamal Kishore",
                    active_attentions_count: NumberInt(0),
                    attentions: [],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(5),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 94.0
                    }
                },
                {
                    subject_id: NumberInt(5),
                    subject_name: "Computer Science",
                    subject_code: "CSC",
                    assigned_teacher_id: NumberInt(69),
                    assigned_teacher_name: "Deepak Soni",
                    active_attentions_count: NumberInt(0),
                    attentions: [],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(6),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 97.0
                    }
                },
                {
                    subject_id: NumberInt(6),
                    subject_name: "Physical Education",
                    subject_code: "PE",
                    assigned_teacher_id: NumberInt(75),
                    assigned_teacher_name: "Harish Rawat",
                    active_attentions_count: NumberInt(0),
                    attentions: [],
                    subject_summary: {
                        assessments_passed: NumberInt(2),
                        assessments_failed: NumberInt(0),
                        homework_submitted: NumberInt(4),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 99.0
                    }
                }
            ],
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-20T14:35:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        }
    ];

    var insertAttentionsRes = targetDb[COLL_ATTENTIONS].insertMany(attentionDocs);
    print("[SUCCESS] Inserted " + Object.keys(insertAttentionsRes.insertedIds).length + " documents into " + COLL_ATTENTIONS);

    // =========================================================================
    // SECTION 3: POST-INSERTION AUDIT & RECONCILIATION REPORT
    // =========================================================================
    print("\n================================================================================");
    print("MOCK SEED RECONCILIATION SUMMARY");
    print("================================================================================");

    var totalChecklistCount = targetDb[COLL_CHECKLIST].countDocuments({
        teacher_id: { $in: checklistSeedTeacherIds }
    });
    var totalAttentionCount = targetDb[COLL_ATTENTIONS].countDocuments({
        student_id: { $in: attentionStudentIds },
        academic_year_id: NumberInt(1)
    });

    print("Total teacher_daily_progress_checklist seeded: " + totalChecklistCount);
    print("Total student_subject_attentions seeded:       " + totalAttentionCount);

    // Validate that zero dates exceed October 30, 2026
    var cutoff = new Date("2026-10-30T23:59:59Z");
    var futureChecklists = targetDb[COLL_CHECKLIST].countDocuments({
        teacher_id: { $in: checklistSeedTeacherIds },
        as_of_date: { $gt: cutoff }
    });
    var futureAttentions = targetDb[COLL_ATTENTIONS].countDocuments({
        student_id: { $in: attentionStudentIds },
        last_evaluated_at: { $gt: cutoff }
    });

    if (futureChecklists === 0 && futureAttentions === 0) {
        print("[VERIFIED] 100% TEMPORAL COMPLIANCE: Zero future records detected (All <= 2026-10-30).");
    } else {
        print("[WARNING] Detected future records! Checklists: " + futureChecklists + ", Attentions: " + futureAttentions);
    }

    print("================================================================================");
    print("SCRIPT COMPLETED SUCCESSFULLY!");
    print("================================================================================");
})();
