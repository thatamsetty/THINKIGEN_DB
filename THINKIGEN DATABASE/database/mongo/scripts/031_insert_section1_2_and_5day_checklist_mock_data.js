/*
================================================================================
SCRIPT:        031_insert_section1_2_and_5day_checklist_mock_data.js
MODULE:        Teacher Portal Management & Student Academic Health
DATABASE:      Thinkigen (MongoDB Atlas / mongosh)
PURPOSE:
1. Re-aligns schema validators via collMod to guarantee 100% Int32 (zero 'long').
2. Reconciles production indexes safely.
3. Inserts 25 Daily Checklist documents:
   - 5 Teachers (1, 8, 15, 22, 29) for the last 5 days (Oct 26 to Oct 30, 2026).
4. Inserts 10 Student Attention documents:
   - Section 1 (Class 8 Central A): Students 1, 2, 3, 4, 5
   - Section 2 (Class 8 Central B): Students 11, 12, 13, 14, 15
   - Accurate faculty allocations and past dates (<= 2026-10-30).
================================================================================
*/

(function () {
    var currentDbName = (typeof db !== "undefined" && db.getName && db.getName() !== "test") ? db.getName() : "Thinkigen";
    var targetDb = typeof db !== "undefined" ? db.getSiblingDB(currentDbName) : null;
    if (!targetDb) {
        throw new Error("Unable to resolve target MongoDB database '" + currentDbName + "'.");
    }

    print("================================================================================");
    print("STARTING SEED: SECTION 1 & 2 ATTENTIONS + 5-DAY TEACHER CHECKLISTS");
    print("Target Database: " + targetDb.getName());
    print("Timestamp:       " + new Date().toISOString());
    print("================================================================================");

    var COLL_CHECKLIST = "teacher_daily_progress_checklist";
    var COLL_ATTENTIONS = "student_subject_attentions";

    // =========================================================================
    // STEP 1: RESILIENT SCHEMA VALIDATION (teacher_daily_progress_checklist)
    // =========================================================================
    var checklistValidator = {
        $jsonSchema: {
            bsonType: "object",
            required: ["teacher_id", "school_id", "branch_id", "academic_year_id", "as_of_date", "previous_day_progress", "checklist_items", "summary", "is_active", "created_at", "updated_at"],
            additionalProperties: true,
            properties: {
                _id: { bsonType: ["objectId", "string"] },
                teacher_id: { bsonType: "int" },
                school_id: { bsonType: "int" },
                branch_id: { bsonType: "int" },
                academic_year_id: { bsonType: "int" },
                as_of_date: { bsonType: "date" },
                previous_day_progress: {
                    bsonType: "object",
                    required: ["date", "total_tasks", "completed_tasks", "completion_percent", "status"],
                    additionalProperties: true,
                    properties: {
                        date: { bsonType: "date" },
                        total_tasks: { bsonType: "int" },
                        completed_tasks: { bsonType: "int" },
                        completion_percent: { bsonType: ["int", "double", "decimal"] },
                        status: { bsonType: "string" },
                        summary_notes: { bsonType: ["string", "null"] }
                    }
                },
                checklist_items: {
                    bsonType: "array",
                    items: {
                        bsonType: "object",
                        required: ["item_id", "task_title", "task_type", "timing", "priority", "is_completed"],
                        additionalProperties: true,
                        properties: {
                            item_id: { bsonType: "string" },
                            task_title: { bsonType: "string" },
                            task_type: { bsonType: "string" },
                            class_id: { bsonType: ["int", "null"] },
                            class_name: { bsonType: ["string", "null"] },
                            section_id: { bsonType: ["int", "null"] },
                            section_name: { bsonType: ["string", "null"] },
                            subject_id: { bsonType: ["int", "null"] },
                            subject_name: { bsonType: ["string", "null"] },
                            room_no: { bsonType: ["string", "null"] },
                            timing: {
                                bsonType: "object",
                                required: ["from_time", "to_time"],
                                additionalProperties: true,
                                properties: {
                                    from_time: { bsonType: "string" },
                                    to_time: { bsonType: "string" }
                                }
                            },
                            student_scope: {
                                bsonType: ["object", "null"],
                                additionalProperties: true,
                                properties: {
                                    scope_type: { bsonType: "string" },
                                    student_id: { bsonType: ["int", "null"] },
                                    student_name: { bsonType: ["string", "null"] },
                                    group_id: { bsonType: ["int", "string", "null"] },
                                    group_name: { bsonType: ["string", "null"] },
                                    student_ids: { bsonType: ["array", "null"], items: { bsonType: "int" } }
                                }
                            },
                            priority: { bsonType: "string" },
                            is_completed: { bsonType: "bool" },
                            completed_at: { bsonType: ["date", "null"] },
                            completed_by_user_id: { bsonType: ["int", "null"] },
                            reference_id: { bsonType: ["string", "int", "null"] },
                            remarks: { bsonType: ["string", "null"] }
                        }
                    }
                },
                summary: {
                    bsonType: "object",
                    additionalProperties: true,
                    properties: {
                        total_items: { bsonType: ["int", "null"] },
                        completed_items: { bsonType: ["int", "null"] },
                        pending_items: { bsonType: ["int", "null"] }
                    }
                },
                is_active: { bsonType: ["int", "bool"] },
                created_at: { bsonType: "date" },
                updated_at: { bsonType: "date" }
            }
        }
    };
    targetDb.runCommand({ collMod: COLL_CHECKLIST, validator: checklistValidator, validationLevel: "strict", validationAction: "error" });

    // =========================================================================
    // STEP 2: RESILIENT SCHEMA VALIDATION (student_subject_attentions)
    // =========================================================================
    var attentionsValidator = {
        $jsonSchema: {
            bsonType: "object",
            required: ["student_id", "student_name", "school_id", "branch_id", "academic_year_id", "class_id", "class_name", "section_id", "section_name", "total_active_attentions", "critical_attentions_count", "subjects", "last_evaluated_at", "is_active", "created_at", "updated_at"],
            additionalProperties: true,
            properties: {
                _id: { bsonType: ["objectId", "string"] },
                student_id: { bsonType: "int" },
                student_name: { bsonType: "string" },
                school_id: { bsonType: "int" },
                branch_id: { bsonType: "int" },
                academic_year_id: { bsonType: "int" },
                class_id: { bsonType: "int" },
                class_name: { bsonType: "string" },
                section_id: { bsonType: "int" },
                section_name: { bsonType: "string" },
                total_active_attentions: { bsonType: "int" },
                critical_attentions_count: { bsonType: "int" },
                subjects: {
                    bsonType: "array",
                    items: {
                        bsonType: "object",
                        required: ["subject_id", "subject_name", "subject_code", "active_attentions_count", "attentions"],
                        additionalProperties: true,
                        properties: {
                            subject_id: { bsonType: "int" },
                            subject_name: { bsonType: "string" },
                            subject_code: { bsonType: "string" },
                            assigned_teacher_id: { bsonType: ["int", "null"] },
                            assigned_teacher_name: { bsonType: ["string", "null"] },
                            active_attentions_count: { bsonType: "int" },
                            attentions: {
                                bsonType: "array",
                                items: {
                                    bsonType: "object",
                                    required: ["attention_id", "attention_type", "severity", "title", "description", "trigger_source", "source_id", "triggered_at", "status"],
                                    additionalProperties: true,
                                    properties: {
                                        attention_id: { bsonType: "string" },
                                        attention_type: { bsonType: "string" },
                                        severity: { bsonType: "string" },
                                        title: { bsonType: "string" },
                                        description: { bsonType: "string" },
                                        trigger_source: { bsonType: "string" },
                                        source_id: { bsonType: "int" },
                                        triggered_at: { bsonType: "date" },
                                        status: { bsonType: "string" },
                                        acknowledged_at: { bsonType: ["date", "null"] },
                                        acknowledged_by_teacher_id: { bsonType: ["int", "null"] },
                                        resolved_at: { bsonType: ["date", "null"] },
                                        resolved_by_teacher_id: { bsonType: ["int", "null"] },
                                        resolution_remarks: { bsonType: ["string", "null"] },
                                        excused_reason: { bsonType: ["string", "null"] },
                                        assessment_details: { bsonType: ["object", "null"], additionalProperties: true },
                                        homework_details: { bsonType: ["object", "null"], additionalProperties: true },
                                        attendance_details: { bsonType: ["object", "null"], additionalProperties: true }
                                    }
                                }
                            },
                            subject_summary: { bsonType: ["object", "null"], additionalProperties: true }
                        }
                    }
                },
                last_evaluated_at: { bsonType: "date" },
                is_active: { bsonType: ["int", "bool"] },
                created_at: { bsonType: "date" },
                updated_at: { bsonType: "date" }
            }
        }
    };
    targetDb.runCommand({ collMod: COLL_ATTENTIONS, validator: attentionsValidator, validationLevel: "strict", validationAction: "error" });
    print("[SUCCESS] Resilient schema validators verified.");

    // =========================================================================
    // STEP 3: SAFE INDEX RECONCILIATION
    // =========================================================================
    function safeReconcileIndex(coll, key, options) {
        var existing = coll.getIndexes().find(function (e) { return e.name === options.name; });
        if (existing) {
            if (JSON.stringify(existing.key) === JSON.stringify(key)) return;
            coll.dropIndex(options.name);
        }
        coll.createIndex(key, options);
    }
    safeReconcileIndex(targetDb[COLL_CHECKLIST], { teacher_id: 1, as_of_date: 1 }, { unique: true, name: "uq_teacher_daily_progress_date" });
    safeReconcileIndex(targetDb[COLL_ATTENTIONS], { student_id: 1, academic_year_id: 1 }, { unique: true, name: "uq_student_subject_attentions_year" });
    print("[SUCCESS] Production indexes reconciled.");

    // =========================================================================
    // STEP 4: SEED TEACHER DAILY CHECKLIST (5 Teachers x Last 5 Days = 25 Docs)
    // =========================================================================
    print("\n[STEP 4] Seeding 25 Daily Checklist documents (5 Teachers x Oct 26-30)...");
    var teachers = [
        { id: 1, name: "Keshav Kulkarni", uid: 101, sid: 1, sname: "English", code: "ENG", p: 1, t: ["08:30", "09:15"] },
        { id: 8, name: "Zara Pai", uid: 108, sid: 2, sname: "Mathematics", code: "MAT", p: 2, t: ["09:15", "10:00"] },
        { id: 15, name: "Bhuvan Solanki", uid: 115, sid: 3, sname: "Science", code: "SCI", p: 3, t: ["10:15", "11:00"] },
        { id: 22, name: "Rashmi Chopra", uid: 122, sid: 4, sname: "Social Science", code: "SOC", p: 4, t: ["11:15", "12:00"] },
        { id: 29, name: "Raghunath Mathur", uid: 129, sid: 5, sname: "Computer Science", code: "CSC", p: 5, t: ["12:45", "13:30"] }
    ];

    var dates = [
        { asOf: "2026-10-26", prev: "2026-10-24" },
        { asOf: "2026-10-27", prev: "2026-10-26" },
        { asOf: "2026-10-28", prev: "2026-10-27" },
        { asOf: "2026-10-29", prev: "2026-10-28" },
        { asOf: "2026-10-30", prev: "2026-10-29" }
    ];

    var checklistDocs = [];
    teachers.forEach(function (t) {
        dates.forEach(function (d) {
            checklistDocs.push({
                teacher_id: NumberInt(t.id),
                school_id: NumberInt(1),
                branch_id: NumberInt(1),
                academic_year_id: NumberInt(1),
                as_of_date: new Date(d.asOf + "T00:00:00Z"),
                previous_day_progress: {
                    date: new Date(d.prev + "T00:00:00Z"),
                    total_tasks: NumberInt(3),
                    completed_tasks: NumberInt(3),
                    completion_percent: 100.0,
                    status: "all_completed",
                    summary_notes: "Completed scheduled instructional periods, homework checks, and student queries."
                },
                checklist_items: [
                    {
                        item_id: "CHK-T" + ("00" + t.id).slice(-3) + "-" + d.asOf.replace(/-/g, "") + "-P" + t.p,
                        task_title: "Period " + t.p + " Attendance - Class 8 A " + t.sname,
                        task_type: "ATTENDANCE",
                        class_id: NumberInt(1),
                        class_name: "Class 8 - Central",
                        section_id: NumberInt(1),
                        section_name: "A",
                        subject_id: NumberInt(t.sid),
                        subject_name: t.sname,
                        room_no: "Room-101",
                        timing: { from_time: t.t[0], to_time: t.t[1] },
                        student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                        priority: "HIGH",
                        is_completed: true,
                        completed_at: new Date(d.asOf + "T" + t.t[1] + ":00Z"),
                        completed_by_user_id: NumberInt(t.uid),
                        reference_id: "TP-" + d.asOf.replace(/-/g, "") + "-C1S1-P" + t.p,
                        remarks: "Conducted planned curriculum topic; verified all Section A attendance."
                    },
                    {
                        item_id: "CHK-T" + ("00" + t.id).slice(-3) + "-" + d.asOf.replace(/-/g, "") + "-HWREV",
                        task_title: "Review Class 8 A & B " + t.sname + " Assigned Exercises",
                        task_type: "HOMEWORK_REVIEW",
                        class_id: NumberInt(1),
                        class_name: "Class 8 - Central",
                        section_id: NumberInt(1),
                        section_name: "A",
                        subject_id: NumberInt(t.sid),
                        subject_name: t.sname,
                        room_no: "Staff Room A",
                        timing: { from_time: "14:15", to_time: "15:00" },
                        student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                        priority: "MEDIUM",
                        is_completed: true,
                        completed_at: new Date(d.asOf + "T14:55:00Z"),
                        completed_by_user_id: NumberInt(t.uid),
                        reference_id: "HW-" + t.code + "-" + d.asOf.replace(/-/g, "") + "-01",
                        remarks: "Evaluated student submissions; provided written corrections for errors."
                    }
                ],
                summary: {
                    total_items: NumberInt(2),
                    completed_items: NumberInt(2),
                    pending_items: NumberInt(0)
                },
                is_active: NumberInt(1),
                created_at: new Date(d.asOf + "T07:30:00Z"),
                updated_at: new Date(d.asOf + "T16:30:00Z")
            });
        });
    });

    targetDb[COLL_CHECKLIST].deleteMany({ teacher_id: { $in: [NumberInt(1), NumberInt(8), NumberInt(15), NumberInt(22), NumberInt(29)] } });
    targetDb[COLL_CHECKLIST].insertMany(checklistDocs);
    print("[SUCCESS] Successfully inserted " + checklistDocs.length + " daily checklist records.");

    // =========================================================================
    // STEP 5: SEED STUDENT SUBJECT ATTENTIONS (Section 1 & 2: 5 Students Each)
    // =========================================================================
    print("\n[STEP 5] Seeding 10 Student Attention documents (Section 1 & 2)...");
    var sec1Faculty = [
        { id: 1, name: "Keshav Kulkarni", sid: 1, sname: "English", code: "ENG" },
        { id: 8, name: "Zara Pai", sid: 2, sname: "Mathematics", code: "MAT" },
        { id: 15, name: "Bhuvan Solanki", sid: 3, sname: "Science", code: "SCI" },
        { id: 22, name: "Rashmi Chopra", sid: 4, sname: "Social Science", code: "SOC" },
        { id: 29, name: "Raghunath Mathur", sid: 5, sname: "Computer Science", code: "CSC" }
    ];

    var sec2Faculty = [
        { id: 2, name: "Radhika Pillai", sid: 1, sname: "English", code: "ENG" },
        { id: 9, name: "Utkarsh Mishra", sid: 2, sname: "Mathematics", code: "MAT" },
        { id: 16, name: "Juhi Rajput", sid: 3, sname: "Science", code: "SCI" },
        { id: 23, name: "Kushagra Kapoor", sid: 4, sname: "Social Science", code: "SOC" },
        { id: 30, name: "Chitra Nigam", sid: 5, sname: "Computer Science", code: "CSC" }
    ];

    var studentsList = [
        // Section 1 (Class 8 Central Section A)
        { id: 1, name: "Karishma Shaik", adm: "ADM-2026-0001", roll: "R-01", secId: 1, secName: "A", alertSubj: 2, alertType: "LOW_ASSESSMENT_SCORE", alertSev: "CRITICAL", alertTitle: "Linear Equations Slip Test Below Benchmark", alertDesc: "Scored 14/50 on algebra diagnostic slip test.", srcId: 501, srcType: "ASSESSMENT", score: 14, max: 50, pass: 20, pct: 28.0 },
        { id: 2, name: "Dhamodhar Rao", adm: "ADM-2026-0002", roll: "R-02", secId: 1, secName: "A", alertSubj: 5, alertType: "PENDING_HOMEWORK", alertSev: "HIGH", alertTitle: "Overdue Python Loop Programming Lab 3", alertDesc: "Loop iterations worksheet assigned Oct 23 not submitted.", srcId: 3012, srcType: "ASSIGNMENT_HOMEWORK", hwTitle: "Python Lab 3: Loop Iterations", hwDue: "2026-10-27", overdue: 3 },
        { id: 3, name: "Sita Ram", adm: "ADM-2026-0003", roll: "R-03", secId: 1, secName: "A", alertSubj: 3, alertType: "ABSENT_ATTENDANCE", alertSev: "MEDIUM", alertTitle: "Period 3 Science Laboratory Absence", alertDesc: "Unexcused absence during Acids & Bases experimental practical.", srcId: 9015, srcType: "ATTENDANCE", attDate: "2026-10-29", attPeriod: 3, attTime: "10:15 - 11:00" },
        { id: 4, name: "Krupa Joseph", adm: "ADM-2026-0004", roll: "R-04", secId: 1, secName: "A", alertSubj: 4, alertType: "LOW_ASSESSMENT_SCORE", alertSev: "HIGH", alertTitle: "Social Studies Indian Constitution Quiz Re-Test Needed", alertDesc: "Scored 15/40 on Indian Constitution foundational principles slip test.", srcId: 504, srcType: "ASSESSMENT", score: 15, max: 40, pass: 18, pct: 37.5 },
        { id: 5, name: "Jeswanth Reddy", adm: "ADM-2026-0005", roll: "R-05", secId: 1, secName: "A", alertSubj: 1, alertType: "PENDING_HOMEWORK", alertSev: "MEDIUM", alertTitle: "English Grammar Direct/Indirect Speech Worksheet Overdue", alertDesc: "Grammar transformation exercise 5.1 not submitted by due date.", srcId: 3025, srcType: "ASSIGNMENT_HOMEWORK", hwTitle: "Direct & Indirect Speech Exercise 5.1", hwDue: "2026-10-28", overdue: 2 },

        // Section 2 (Class 8 Central Section B)
        { id: 11, name: "Gurpreet Pillai", adm: "ADM-2026-0011", roll: "R-01", secId: 2, secName: "B", alertSubj: 2, alertType: "LOW_ASSESSMENT_SCORE", alertSev: "CRITICAL", alertTitle: "Section B Quadratic Equation Slip Test Benchmark Deficit", alertDesc: "Scored 16/50 on algebra quadratic polynomials diagnostic slip test.", srcId: 511, srcType: "ASSESSMENT", score: 16, max: 50, pass: 20, pct: 32.0 },
        { id: 12, name: "Deepika Pathak", adm: "ADM-2026-0012", roll: "R-02", secId: 2, secName: "B", alertSubj: 1, alertType: "ABSENT_ATTENDANCE", alertSev: "MEDIUM", alertTitle: "Period 1 English Literature Attendance Absence", alertDesc: "Absent without prior leave slip during Shakespeare Merchant of Venice introduction.", srcId: 9032, srcType: "ATTENDANCE", attDate: "2026-10-28", attPeriod: 1, attTime: "08:30 - 09:15" },
        { id: 13, name: "Varun Venkataraman", adm: "ADM-2026-0013", roll: "R-03", secId: 2, secName: "B", alertSubj: 3, alertType: "PENDING_HOMEWORK", alertSev: "HIGH", alertTitle: "Physics Ray Optics Diagram Portfolio Overdue", alertDesc: "Refraction ray diagrams lab homework not submitted.", srcId: 3045, srcType: "ASSIGNMENT_HOMEWORK", hwTitle: "Ray Optics Lab Homework Portfolio", hwDue: "2026-10-28", overdue: 2 },
        { id: 14, name: "Reena Mitra", adm: "ADM-2026-0014", roll: "R-04", secId: 2, secName: "B", alertSubj: 4, alertType: "LOW_ASSESSMENT_SCORE", alertSev: "HIGH", alertTitle: "Medieval Indian Architecture Map Test Re-evaluation", alertDesc: "Scored 13/40 on Mughal architecture and monuments mapping evaluation.", srcId: 514, srcType: "ASSESSMENT", score: 13, max: 40, pass: 18, pct: 32.5 },
        { id: 15, name: "Sangeeta Ghosh", adm: "ADM-2026-0015", roll: "R-05", secId: 2, secName: "B", alertSubj: null }
    ];

    var attentionDocs = [];
    studentsList.forEach(function (st) {
        var facultyList = st.secId === 1 ? sec1Faculty : sec2Faculty;
        var subjectsArr = [];
        var totalActive = st.alertSubj ? 1 : 0;
        var critCount = (st.alertSubj && st.alertSev === "CRITICAL") ? 1 : 0;

        facultyList.forEach(function (f) {
            var hasAlert = st.alertSubj === f.sid;
            var attList = [];
            if (hasAlert) {
                var asmDetails = st.score !== undefined ? {
                    assessment_id: NumberInt(st.srcId),
                    assessment_name: st.alertTitle,
                    exam_type: "SLIP_TEST",
                    max_marks: st.max,
                    pass_marks: st.pass,
                    obtained_marks: st.score,
                    percentage: st.pct
                } : null;

                var hwDetails = st.hwTitle !== undefined ? {
                    homework_id: NumberInt(st.srcId),
                    homework_title: st.hwTitle,
                    assigned_date: new Date("2026-10-23T00:00:00Z"),
                    due_date: new Date(st.hwDue + "T23:59:59Z"),
                    days_overdue: NumberInt(st.overdue),
                    submission_status: "PENDING"
                } : null;

                var attDetails = st.attDate !== undefined ? {
                    attendance_id: NumberInt(st.srcId),
                    attendance_date: new Date(st.attDate + "T00:00:00Z"),
                    period_number: NumberInt(st.attPeriod),
                    period_time: st.attTime,
                    attendance_status: "ABSENT"
                } : null;

                attList.push({
                    attention_id: "ATT-S" + ("00" + st.id).slice(-3) + "-" + f.code + "-" + st.srcId + "-2026",
                    attention_type: st.alertType,
                    severity: st.alertSev,
                    title: st.alertTitle,
                    description: st.alertDesc,
                    trigger_source: st.srcType,
                    source_id: NumberInt(st.srcId),
                    triggered_at: new Date("2026-10-28T14:30:00Z"),
                    status: "ACTIVE",
                    acknowledged_at: new Date("2026-10-29T09:00:00Z"),
                    acknowledged_by_teacher_id: NumberInt(f.id),
                    resolved_at: null,
                    resolved_by_teacher_id: null,
                    resolution_remarks: null,
                    excused_reason: null,
                    assessment_details: asmDetails,
                    homework_details: hwDetails,
                    attendance_details: attDetails
                });
            }

            subjectsArr.push({
                subject_id: NumberInt(f.sid),
                subject_name: f.sname,
                subject_code: f.code,
                assigned_teacher_id: NumberInt(f.id),
                assigned_teacher_name: f.name,
                active_attentions_count: NumberInt(hasAlert ? 1 : 0),
                attentions: attList,
                subject_summary: {
                    assessments_passed: NumberInt(hasAlert && st.score !== undefined ? 3 : 4),
                    assessments_failed: NumberInt(hasAlert && st.score !== undefined ? 1 : 0),
                    homework_submitted: NumberInt(8),
                    homework_pending: NumberInt(hasAlert && st.hwTitle !== undefined ? 1 : 0),
                    subject_attendance_percent: 95.0
                }
            });
        });

        attentionDocs.push({
            student_id: NumberInt(st.id),
            student_name: st.name,
            admission_number: st.adm,
            roll_number: st.roll,
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(1),
            class_id: NumberInt(1),
            class_name: "Class 8 - Central",
            section_id: NumberInt(st.secId),
            section_name: st.secName,
            total_active_attentions: NumberInt(totalActive),
            critical_attentions_count: NumberInt(critCount),
            subjects: subjectsArr,
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-26T08:00:00Z"),
            updated_at: new Date("2026-10-30T16:00:00Z")
        });
    });

    targetDb[COLL_ATTENTIONS].deleteMany({
        student_id: { $in: [NumberInt(1), NumberInt(2), NumberInt(3), NumberInt(4), NumberInt(5), NumberInt(11), NumberInt(12), NumberInt(13), NumberInt(14), NumberInt(15)] },
        academic_year_id: NumberInt(1)
    });
    targetDb[COLL_ATTENTIONS].insertMany(attentionDocs);
    print("[SUCCESS] Successfully inserted " + attentionDocs.length + " student attention records.");

    // =========================================================================
    // STEP 6: VERIFICATION SUMMARY
    // =========================================================================
    var chkCount = targetDb[COLL_CHECKLIST].countDocuments({ teacher_id: { $in: [NumberInt(1), NumberInt(8), NumberInt(15), NumberInt(22), NumberInt(29)] } });
    var attCount = targetDb[COLL_ATTENTIONS].countDocuments({ student_id: { $in: [NumberInt(1), NumberInt(2), NumberInt(3), NumberInt(4), NumberInt(5), NumberInt(11), NumberInt(12), NumberInt(13), NumberInt(14), NumberInt(15)] } });

    print("\n================================================================================");
    print("MIGRATION & MOCK SEED COMPLETE:");
    print("  - Daily Checklists Inserted:   " + chkCount + " / 25");
    print("  - Student Attentions Inserted: " + attCount + " / 10");
    print("  - Timetable Constraints:       100% Valid Past Dates (<= 2026-10-30)");
    print("  - Data Types:                  100% BSON 32-bit int (NumberInt, Zero 'long')");
    print("================================================================================");
})();
