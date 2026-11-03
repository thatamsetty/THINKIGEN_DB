/*
================================================================================
SCRIPT:        030_fix_validation_and_seed_data.js
MODULE:        Teacher Portal Management & Student Academic Health
DATABASE:      Thinkigen (MongoDB Atlas / mongosh)
PURPOSE:
1. Re-aligns schema validators via collMod on both collections to ensure:
   - All identifier fields strictly require BSON 32-bit int (bsonType: "int").
   - ZERO BSON long data types allowed.
   - is_active supports both int (1) and boolean (true) without validation errors.
   - additionalProperties: true prevents schema rejection on summary fields.
2. Reconciles all production indexes safely without name or key spec conflicts.
3. Seeds timetable-aligned mock data (strictly <= 2026-10-30).
================================================================================
*/

(function () {
    var currentDbName = (typeof db !== "undefined" && db.getName && db.getName() !== "test") ? db.getName() : "Thinkigen";
    var targetDb = typeof db !== "undefined" ? db.getSiblingDB(currentDbName) : null;
    if (!targetDb) {
        throw new Error("Unable to resolve target MongoDB database '" + currentDbName + "'.");
    }

    print("================================================================================");
    print("FIXING SCHEMA VALIDATORS & SEEDING TIMETABLE-ALIGNED MOCK DATA");
    print("Target Database: " + targetDb.getName());
    print("Timestamp:       " + new Date().toISOString());
    print("================================================================================");

    var COLL_CHECKLIST = "teacher_daily_progress_checklist";
    var COLL_ATTENTIONS = "student_subject_attentions";

    // =========================================================================
    // STEP 1: RESILIENT SCHEMA VALIDATOR (teacher_daily_progress_checklist)
    // =========================================================================
    print("\n[STEP 1] Re-aligning collMod validator for " + COLL_CHECKLIST + "...");

    var checklistValidator = {
        $jsonSchema: {
            bsonType: "object",
            required: [
                "teacher_id",
                "school_id",
                "branch_id",
                "academic_year_id",
                "as_of_date",
                "previous_day_progress",
                "checklist_items",
                "summary",
                "is_active",
                "created_at",
                "updated_at"
            ],
            additionalProperties: true,
            properties: {
                _id: { bsonType: ["objectId", "string"] },
                teacher_id: { bsonType: "int", description: "Teacher ID (must be int)" },
                school_id: { bsonType: "int", description: "School ID (must be int)" },
                branch_id: { bsonType: "int", description: "Branch ID (must be int)" },
                academic_year_id: { bsonType: "int", description: "Academic Year ID (must be int)" },
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

    targetDb.runCommand({
        collMod: COLL_CHECKLIST,
        validator: checklistValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("  [SUCCESS] Updated collMod schema validator on " + COLL_CHECKLIST);

    // =========================================================================
    // STEP 2: RESILIENT SCHEMA VALIDATOR (student_subject_attentions)
    // =========================================================================
    print("\n[STEP 2] Re-aligning collMod validator for " + COLL_ATTENTIONS + "...");

    var attentionsValidator = {
        $jsonSchema: {
            bsonType: "object",
            required: [
                "student_id",
                "student_name",
                "school_id",
                "branch_id",
                "academic_year_id",
                "class_id",
                "class_name",
                "section_id",
                "section_name",
                "total_active_attentions",
                "critical_attentions_count",
                "subjects",
                "last_evaluated_at",
                "is_active",
                "created_at",
                "updated_at"
            ],
            additionalProperties: true,
            properties: {
                _id: { bsonType: ["objectId", "string"] },
                student_id: { bsonType: "int", description: "Student ID (must be int)" },
                student_name: { bsonType: "string" },
                admission_number: { bsonType: ["string", "null"] },
                roll_number: { bsonType: ["string", "null"] },
                school_id: { bsonType: "int", description: "School ID (must be int)" },
                branch_id: { bsonType: "int", description: "Branch ID (must be int)" },
                academic_year_id: { bsonType: "int", description: "Academic Year ID (must be int)" },
                class_id: { bsonType: "int", description: "Class ID (must be int)" },
                class_name: { bsonType: "string" },
                section_id: { bsonType: "int", description: "Section ID (must be int)" },
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
                                        assessment_details: {
                                            bsonType: ["object", "null"],
                                            additionalProperties: true,
                                            properties: {
                                                assessment_id: { bsonType: ["int", "null"] },
                                                assessment_name: { bsonType: ["string", "null"] },
                                                exam_type: { bsonType: ["string", "null"] },
                                                max_marks: { bsonType: ["int", "double", "decimal", "null"] },
                                                pass_marks: { bsonType: ["int", "double", "decimal", "null"] },
                                                obtained_marks: { bsonType: ["int", "double", "decimal", "null"] },
                                                percentage: { bsonType: ["int", "double", "decimal", "null"] }
                                            }
                                        },
                                        homework_details: {
                                            bsonType: ["object", "null"],
                                            additionalProperties: true,
                                            properties: {
                                                homework_id: { bsonType: ["int", "null"] },
                                                homework_title: { bsonType: ["string", "null"] },
                                                assigned_date: { bsonType: ["date", "null"] },
                                                due_date: { bsonType: ["date", "null"] },
                                                days_overdue: { bsonType: ["int", "null"] },
                                                submission_status: { bsonType: ["string", "null"] }
                                            }
                                        },
                                        attendance_details: {
                                            bsonType: ["object", "null"],
                                            additionalProperties: true,
                                            properties: {
                                                attendance_id: { bsonType: ["int", "null"] },
                                                attendance_date: { bsonType: ["date", "null"] },
                                                period_number: { bsonType: ["int", "null"] },
                                                period_time: { bsonType: ["string", "null"] },
                                                attendance_status: { bsonType: ["string", "null"] }
                                            }
                                        }
                                    }
                                }
                            },
                            subject_summary: {
                                bsonType: ["object", "null"],
                                additionalProperties: true,
                                properties: {
                                    assessments_passed: { bsonType: ["int", "null"] },
                                    assessments_failed: { bsonType: ["int", "null"] },
                                    homework_submitted: { bsonType: ["int", "null"] },
                                    homework_pending: { bsonType: ["int", "null"] },
                                    subject_attendance_percent: { bsonType: ["int", "double", "decimal", "null"] }
                                }
                            }
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

    targetDb.runCommand({
        collMod: COLL_ATTENTIONS,
        validator: attentionsValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("  [SUCCESS] Updated collMod schema validator on " + COLL_ATTENTIONS);

    // =========================================================================
    // STEP 3: RECONCILE INDEXES SAFELY
    // =========================================================================
    print("\n[STEP 3] Reconciling production indexes...");
    function safeReconcileIndex(coll, key, options) {
        var existingIndexes = coll.getIndexes();
        var existingByName = existingIndexes.find(function (e) {
            return e.name === options.name;
        });

        if (existingByName) {
            var existingKeyStr = JSON.stringify(existingByName.key);
            var targetKeyStr = JSON.stringify(key);

            if (existingKeyStr === targetKeyStr) {
                print("  [INDEX] Up-to-date: " + options.name + " (" + existingKeyStr + ")");
                return;
            }

            print("  [INDEX] Conflict on '" + options.name + "': Dropping legacy and rebuilding...");
            coll.dropIndex(options.name);
        }

        coll.createIndex(key, options);
        print("  [INDEX] Created index: " + options.name);
    }

    var chkIndexes = [
        { key: { teacher_id: 1, as_of_date: 1 }, options: { unique: true, name: "uq_teacher_daily_progress_date" } },
        { key: { school_id: 1, branch_id: 1, as_of_date: 1 }, options: { name: "ix_teacher_daily_progress_scope" } },
        { key: { teacher_id: 1, "checklist_items.task_type": 1 }, options: { name: "ix_teacher_daily_checklist_type" } },
        { key: { "checklist_items.class_id": 1, "checklist_items.section_id": 1, as_of_date: 1 }, options: { name: "ix_teacher_daily_checklist_class_section" } }
    ];
    chkIndexes.forEach(function (idx) { safeReconcileIndex(targetDb[COLL_CHECKLIST], idx.key, idx.options); });

    var attIndexes = [
        { key: { student_id: 1, academic_year_id: 1 }, options: { unique: true, name: "uq_student_subject_attentions_year" } },
        { key: { school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1 }, options: { name: "ix_student_attentions_scope" } },
        { key: { "subjects.assigned_teacher_id": 1, academic_year_id: 1, "subjects.active_attentions_count": 1 }, options: { name: "ix_student_attentions_teacher" } },
        { key: { academic_year_id: 1, "subjects.attentions.status": 1, "subjects.attentions.attention_type": 1, "subjects.attentions.severity": 1 }, options: { name: "ix_student_attentions_status_type" } },
        { key: { section_id: 1, academic_year_id: 1, total_active_attentions: -1 }, options: { name: "ix_student_attentions_section_total" } }
    ];
    attIndexes.forEach(function (idx) { safeReconcileIndex(targetDb[COLL_ATTENTIONS], idx.key, idx.options); });

    // =========================================================================
    // STEP 4: SEED VERIFIED TIMETABLE MOCK DATA (100% NumberInt & Past Dates)
    // =========================================================================
    print("\n[STEP 4] Seeding verified timetable mock data...");

    var checklistSeedTeacherIds = [
        NumberInt(1), NumberInt(8), NumberInt(15), NumberInt(22),
        NumberInt(29), NumberInt(35), NumberInt(41), NumberInt(48)
    ];
    targetDb[COLL_CHECKLIST].deleteMany({ teacher_id: { $in: checklistSeedTeacherIds } });

    var verifiedChecklists = [
        // Teacher 1 (Keshav Kulkarni - Central English HOD) - As of 2026-10-30
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
                    room_no: "Staff Room B",
                    timing: { from_time: "11:15", to_time: "12:00" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "MEDIUM",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T11:58:00Z"),
                    completed_by_user_id: NumberInt(101),
                    reference_id: "HW-ENG-20261028-01",
                    remarks: "Checked 10 notebooks. Commended Karishma and Dhamodhar for high vocabulary."
                }
            ],
            summary: {
                total_items: NumberInt(2),
                completed_items: NumberInt(2),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T16:30:00Z")
        },
        // Teacher 8 (Zara Pai - Central Mathematics HOD) - As of 2026-10-30
        {
            teacher_id: NumberInt(8),
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
                summary_notes: "Completed all scheduled periods and coordinated Grade 8 math remedial sync."
            },
            checklist_items: [
                {
                    item_id: "CHK-T008-20261030-P1",
                    task_title: "Period 1 Attendance - Class 8 A Mathematics",
                    task_type: "ATTENDANCE",
                    class_id: NumberInt(1),
                    class_name: "Class 8 - Central",
                    section_id: NumberInt(1),
                    section_name: "A",
                    subject_id: NumberInt(2),
                    subject_name: "Mathematics",
                    room_no: "Room-101",
                    timing: { from_time: "08:30", to_time: "09:15" },
                    student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null, group_id: null, group_name: null, student_ids: null },
                    priority: "HIGH",
                    is_completed: true,
                    completed_at: new Date("2026-10-30T08:32:00Z"),
                    completed_by_user_id: NumberInt(108),
                    reference_id: "TP-20261030-C1S1-P1",
                    remarks: "Conducted Linear Equations introductory problem set. All 10 students marked present."
                }
            ],
            summary: {
                total_items: NumberInt(1),
                completed_items: NumberInt(1),
                pending_items: NumberInt(0)
            },
            is_active: NumberInt(1),
            created_at: new Date("2026-10-30T07:30:00Z"),
            updated_at: new Date("2026-10-30T17:10:00Z")
        }
    ];

    try {
        targetDb[COLL_CHECKLIST].insertMany(verifiedChecklists);
        print("  [SUCCESS] Successfully seeded " + verifiedChecklists.length + " documents into " + COLL_CHECKLIST);
    } catch (e) {
        print("  [ERROR] Checklist insert error: " + e.message);
        if (e.errInfo && e.errInfo.details) {
            print("  [DETAILS] " + JSON.stringify(e.errInfo.details, null, 2));
        }
        throw e;
    }

    var attentionStudentIds = [
        NumberInt(1), NumberInt(2), NumberInt(3), NumberInt(4),
        NumberInt(5), NumberInt(6), NumberInt(7), NumberInt(8),
        NumberInt(9), NumberInt(10), NumberInt(201)
    ];
    targetDb[COLL_ATTENTIONS].deleteMany({
        student_id: { $in: attentionStudentIds },
        academic_year_id: NumberInt(1)
    });

    var verifiedAttentions = [
        // Student 1 (Karishma Shaik - Central Class 8 A)
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
            total_active_attentions: NumberInt(1),
            critical_attentions_count: NumberInt(1),
            subjects: [
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
                    active_attentions_count: NumberInt(1),
                    attentions: [
                        {
                            attention_id: "ATT-1-ASM-501-2026",
                            attention_type: "LOW_ASSESSMENT_SCORE",
                            severity: "CRITICAL",
                            title: "Algebra Slip Test Below Passing Benchmark",
                            description: "Scored 14 out of 50 in Mid-Term Linear Equations Test.",
                            trigger_source: "ASSESSMENT",
                            source_id: NumberInt(501),
                            triggered_at: new Date("2026-10-28T14:30:00Z"),
                            status: "ACTIVE",
                            acknowledged_at: new Date("2026-10-29T08:30:00Z"),
                            acknowledged_by_teacher_id: NumberInt(8),
                            resolved_at: null,
                            resolved_by_teacher_id: null,
                            resolution_remarks: null,
                            excused_reason: null,
                            assessment_details: {
                                assessment_id: NumberInt(501),
                                assessment_name: "Mid-Term Linear Equations Test",
                                exam_type: "SLIP_TEST",
                                max_marks: 50.0,
                                pass_marks: 20.0,
                                obtained_marks: 14.0,
                                percentage: 28.0
                            },
                            homework_details: null,
                            attendance_details: null
                        }
                    ],
                    subject_summary: {
                        assessments_passed: NumberInt(3),
                        assessments_failed: NumberInt(1),
                        homework_submitted: NumberInt(8),
                        homework_pending: NumberInt(0),
                        subject_attendance_percent: 94.5
                    }
                }
            ],
            last_evaluated_at: new Date("2026-10-30T16:00:00Z"),
            is_active: NumberInt(1),
            created_at: new Date("2026-10-28T14:30:00Z"),
            updated_at: new Date("2026-10-29T08:30:00Z")
        }
    ];

    try {
        targetDb[COLL_ATTENTIONS].insertMany(verifiedAttentions);
        print("  [SUCCESS] Successfully seeded " + verifiedAttentions.length + " documents into " + COLL_ATTENTIONS);
    } catch (e) {
        print("  [ERROR] Attentions insert error: " + e.message);
        if (e.errInfo && e.errInfo.details) {
            print("  [DETAILS] " + JSON.stringify(e.errInfo.details, null, 2));
        }
        throw e;
    }

    print("\n================================================================================");
    print("ALL MIGRATIONS, INDEX RECONCILIATIONS, & MOCK SEEDS COMPLETED SUCCESSFULLY!");
    print("================================================================================");
})();

