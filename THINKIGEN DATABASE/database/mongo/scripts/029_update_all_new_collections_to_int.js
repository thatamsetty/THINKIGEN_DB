/*
================================================================================
SCRIPT:        029_update_all_new_collections_to_int.js
MODULE:        Teacher Portal Management & Student Academic Health
DATABASE:      thinkigen (MongoDB)
TARGET COLLECTIONS:
               1. teacher_daily_progress_checklist
               2. student_subject_attentions

PURPOSE:
1. Upgrade existing documents in-place across all newly created teacher collections:
   Converts all identifier fields from BSON long (Int64) to BSON 32-bit int (Int32 / NumberInt).
2. Apply strict JSON Schema validators via collMod where all IDs require bsonType: "int"
   (zero 'long' data types permitted for identifiers).
3. Reconcile and build production indexes on both collections.
4. Output detailed verification and migration statistics.

EXECUTION:
   mongosh thinkigen 029_update_all_new_collections_to_int.js
   - OR -
   Execute directly in MongoDB Compass (_mongosh tab).
================================================================================
*/

(function () {
    var currentDbName = (typeof db !== "undefined" && db.getName && db.getName() !== "test") ? db.getName() : "Thinkigen";
    var targetDb = typeof db !== "undefined" ? db.getSiblingDB(currentDbName) : null;

    // Safe index reconciler to prevent IndexKeySpecsConflict
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

            print("  [INDEX] Key spec conflict detected on '" + options.name + "':");
            print("          Existing: " + existingKeyStr);
            print("          Target:   " + targetKeyStr);
            print("          Dropping legacy index '" + options.name + "' to resolve conflict...");
            coll.dropIndex(options.name);
            print("          Dropped legacy index '" + options.name + "'.");
        }

        coll.createIndex(key, options);
        print("  [INDEX] Created index: " + options.name);
    }

    if (!targetDb) {
        throw new Error("Unable to resolve target MongoDB database 'thinkigen'.");
    }

    print("================================================================================");
    print("STARTING MIGRATION: 029_update_all_new_collections_to_int");
    print("Target Database: " + targetDb.getName());
    print("Timestamp:       " + new Date().toISOString());
    print("================================================================================");

    var allCollections = targetDb.getCollectionNames();

    // =========================================================================
    // PART 1: teacher_daily_progress_checklist
    // =========================================================================
    var COLL_CHECKLIST = "teacher_daily_progress_checklist";
    print("\n--------------------------------------------------------------------------------");
    print("UPGRADING COLLECTION: " + COLL_CHECKLIST);
    print("--------------------------------------------------------------------------------");

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
            additionalProperties: false,
            properties: {
                _id: { bsonType: ["objectId", "string"] },
                teacher_id: { bsonType: "int", minimum: 1 },
                school_id: { bsonType: "int", minimum: 1 },
                branch_id: { bsonType: "int", minimum: 1 },
                academic_year_id: { bsonType: "int", minimum: 1 },
                as_of_date: { bsonType: "date" },
                
                previous_day_progress: {
                    bsonType: "object",
                    required: [
                        "date",
                        "total_tasks",
                        "completed_tasks",
                        "completion_percent",
                        "status"
                    ],
                    additionalProperties: false,
                    properties: {
                        date: { bsonType: "date" },
                        total_tasks: { bsonType: "int", minimum: 0 },
                        completed_tasks: { bsonType: "int", minimum: 0 },
                        completion_percent: {
                            bsonType: ["int", "double", "decimal"],
                            minimum: 0,
                            maximum: 100
                        },
                        status: {
                            bsonType: "string",
                            enum: ["all_completed", "partially_completed", "pending", "no_tasks"]
                        },
                        summary_notes: { bsonType: ["string", "null"], maxLength: 500 }
                    }
                },

                checklist_items: {
                    bsonType: "array",
                    items: {
                        bsonType: "object",
                        required: [
                            "item_id",
                            "task_title",
                            "task_type",
                            "timing",
                            "priority",
                            "is_completed"
                        ],
                        additionalProperties: false,
                        properties: {
                            item_id: { bsonType: "string", minLength: 1, maxLength: 64 },
                            task_title: { bsonType: "string", minLength: 1, maxLength: 250 },
                            task_type: {
                                bsonType: "string",
                                enum: [
                                    "ATTENDANCE",
                                    "HOMEWORK_REVIEW",
                                    "MEETING",
                                    "RESOURCE_UPLOAD",
                                    "ASSESSMENT_EVALUATION",
                                    "CLASSWORK",
                                    "OTHER"
                                ]
                            },
                            class_id: { bsonType: ["int", "null"], minimum: 1 },
                            class_name: { bsonType: ["string", "null"], maxLength: 50 },
                            section_id: { bsonType: ["int", "null"], minimum: 1 },
                            section_name: { bsonType: ["string", "null"], maxLength: 20 },
                            subject_id: { bsonType: ["int", "null"] },
                            subject_name: { bsonType: ["string", "null"], maxLength: 100 },
                            room_no: { bsonType: ["string", "null"], maxLength: 50 },
                            timing: {
                                bsonType: "object",
                                required: ["from_time", "to_time"],
                                additionalProperties: false,
                                properties: {
                                    from_time: { bsonType: "string", minLength: 4, maxLength: 15 },
                                    to_time: { bsonType: "string", minLength: 4, maxLength: 15 }
                                }
                            },
                            student_scope: {
                                bsonType: ["object", "null"],
                                required: ["scope_type"],
                                additionalProperties: false,
                                properties: {
                                    scope_type: {
                                        bsonType: "string",
                                        enum: ["ENTIRE_SECTION", "INDIVIDUAL_STUDENT", "GROUP"]
                                    },
                                    student_id: { bsonType: ["int", "null"] },
                                    student_name: { bsonType: ["string", "null"], maxLength: 150 },
                                    group_id: { bsonType: ["int", "string", "null"] },
                                    group_name: { bsonType: ["string", "null"], maxLength: 100 },
                                    student_ids: {
                                        bsonType: ["array", "null"],
                                        items: { bsonType: "int" }
                                    }
                                }
                            },
                            priority: {
                                bsonType: "string",
                                enum: ["HIGH", "MEDIUM", "LOW"]
                            },
                            is_completed: { bsonType: "bool" },
                            completed_at: { bsonType: ["date", "null"] },
                            completed_by_user_id: { bsonType: ["int", "null"] },
                            reference_id: { bsonType: ["string", "int", "null"] },
                            remarks: { bsonType: ["string", "null"], maxLength: 500 }
                        }
                    }
                },

                summary: {
                    bsonType: "object",
                    required: ["total_items", "completed_items", "pending_items"],
                    additionalProperties: false,
                    properties: {
                        total_items: { bsonType: "int", minimum: 0 },
                        completed_items: { bsonType: "int", minimum: 0 },
                        pending_items: { bsonType: "int", minimum: 0 }
                    }
                },

                is_active: { bsonType: ["int", "bool"] },
                created_at: { bsonType: "date" },
                updated_at: { bsonType: "date" }
            }
        }
    };

    if (allCollections.includes(COLL_CHECKLIST)) {
        var chkDocsCount = targetDb[COLL_CHECKLIST].countDocuments();
        if (chkDocsCount > 0) {
            print("[MIGRATION] Found " + chkDocsCount + " documents in " + COLL_CHECKLIST + ". Upgrading IDs to NumberInt...");
            var chkMigrated = 0;
            var chkCursor = targetDb[COLL_CHECKLIST].find({});
            while (chkCursor.hasNext()) {
                var doc = chkCursor.next();

                doc.teacher_id = NumberInt(doc.teacher_id);
                doc.school_id = NumberInt(doc.school_id);
                doc.branch_id = NumberInt(doc.branch_id);
                doc.academic_year_id = NumberInt(doc.academic_year_id);
                doc.is_active = NumberInt(doc.is_active || 1);

                if (doc.previous_day_progress) {
                    doc.previous_day_progress.total_tasks = NumberInt(doc.previous_day_progress.total_tasks);
                    doc.previous_day_progress.completed_tasks = NumberInt(doc.previous_day_progress.completed_tasks);
                }

                if (Array.isArray(doc.checklist_items)) {
                    doc.checklist_items.forEach(function (item) {
                        if (item.class_id != null) item.class_id = NumberInt(item.class_id);
                        if (item.section_id != null) item.section_id = NumberInt(item.section_id);
                        if (item.subject_id != null) item.subject_id = NumberInt(item.subject_id);
                        if (item.completed_by_user_id != null) item.completed_by_user_id = NumberInt(item.completed_by_user_id);

                        if (item.student_scope) {
                            if (item.student_scope.student_id != null) item.student_scope.student_id = NumberInt(item.student_scope.student_id);
                            if (Array.isArray(item.student_scope.student_ids)) {
                                item.student_scope.student_ids = item.student_scope.student_ids.map(function (id) {
                                    return NumberInt(id);
                                });
                            }
                        }
                    });
                }

                if (doc.summary) {
                    doc.summary.total_items = NumberInt(doc.summary.total_items);
                    doc.summary.completed_items = NumberInt(doc.summary.completed_items);
                    doc.summary.pending_items = NumberInt(doc.summary.pending_items);
                }

                targetDb[COLL_CHECKLIST].replaceOne({ _id: doc._id }, doc);
                chkMigrated++;
            }
            print("[SUCCESS] Upgraded " + chkMigrated + " documents in " + COLL_CHECKLIST + " to NumberInt.");
        }

        var chkMod = targetDb.runCommand({
            collMod: COLL_CHECKLIST,
            validator: checklistValidator,
            validationLevel: "strict",
            validationAction: "error"
        });
        if (chkMod.ok !== 1) {
            print("[ERROR] collMod failed on " + COLL_CHECKLIST + ": " + JSON.stringify(chkMod));
            throw new Error("collMod failed on " + COLL_CHECKLIST);
        }
        print("[SUCCESS] Applied strict int JSON Schema validator to " + COLL_CHECKLIST);
    } else {
        targetDb.createCollection(COLL_CHECKLIST, {
            validator: checklistValidator,
            validationLevel: "strict",
            validationAction: "error"
        });
        print("[SUCCESS] Created collection " + COLL_CHECKLIST + " with strict int JSON Schema validator.");
    }

    // Deploy indexes on checklist
    var chkIndexes = [
        { key: { teacher_id: 1, as_of_date: 1 }, options: { unique: true, name: "uq_teacher_daily_progress_date" } },
        { key: { school_id: 1, branch_id: 1, as_of_date: 1 }, options: { name: "ix_teacher_daily_progress_scope" } },
        { key: { teacher_id: 1, "checklist_items.task_type": 1 }, options: { name: "ix_teacher_daily_checklist_type" } },
        { key: { "checklist_items.class_id": 1, "checklist_items.section_id": 1, as_of_date: 1 }, options: { name: "ix_teacher_daily_checklist_class_section" } }
    ];
    chkIndexes.forEach(function (idx) {
        safeReconcileIndex(targetDb[COLL_CHECKLIST], idx.key, idx.options);
    });


    // =========================================================================
    // PART 2: student_subject_attentions
    // =========================================================================
    var COLL_ATTENTIONS = "student_subject_attentions";
    print("\n--------------------------------------------------------------------------------");
    print("UPGRADING COLLECTION: " + COLL_ATTENTIONS);
    print("--------------------------------------------------------------------------------");

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
            additionalProperties: false,
            properties: {
                _id: { bsonType: ["objectId", "string"] },
                student_id: { bsonType: "int", minimum: 1 },
                student_name: { bsonType: "string", minLength: 1, maxLength: 150 },
                admission_number: { bsonType: ["string", "null"], maxLength: 50 },
                roll_number: { bsonType: ["string", "null"], maxLength: 50 },
                school_id: { bsonType: "int", minimum: 1 },
                branch_id: { bsonType: "int", minimum: 1 },
                academic_year_id: { bsonType: "int", minimum: 1 },
                class_id: { bsonType: "int", minimum: 1 },
                class_name: { bsonType: "string", minLength: 1, maxLength: 50 },
                section_id: { bsonType: "int", minimum: 1 },
                section_name: { bsonType: "string", minLength: 1, maxLength: 20 },
                total_active_attentions: { bsonType: "int", minimum: 0 },
                critical_attentions_count: { bsonType: "int", minimum: 0 },

                subjects: {
                    bsonType: "array",
                    items: {
                        bsonType: "object",
                        required: [
                            "subject_id",
                            "subject_name",
                            "subject_code",
                            "active_attentions_count",
                            "attentions"
                        ],
                        additionalProperties: false,
                        properties: {
                            subject_id: { bsonType: "int", minimum: 1 },
                            subject_name: { bsonType: "string", minLength: 1, maxLength: 100 },
                            subject_code: { bsonType: "string", minLength: 1, maxLength: 30 },
                            assigned_teacher_id: { bsonType: ["int", "null"] },
                            assigned_teacher_name: { bsonType: ["string", "null"], maxLength: 150 },
                            active_attentions_count: { bsonType: "int", minimum: 0 },

                            attentions: {
                                bsonType: "array",
                                items: {
                                    bsonType: "object",
                                    required: [
                                        "attention_id",
                                        "attention_type",
                                        "severity",
                                        "title",
                                        "description",
                                        "trigger_source",
                                        "source_id",
                                        "triggered_at",
                                        "status"
                                    ],
                                    additionalProperties: false,
                                    properties: {
                                        attention_id: { bsonType: "string", minLength: 1, maxLength: 64 },
                                        attention_type: {
                                            bsonType: "string",
                                            enum: [
                                                "LOW_ASSESSMENT_SCORE",
                                                "PENDING_HOMEWORK",
                                                "ABSENT_ATTENDANCE"
                                            ]
                                        },
                                        severity: {
                                            bsonType: "string",
                                            enum: ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
                                        },
                                        title: { bsonType: "string", minLength: 1, maxLength: 200 },
                                        description: { bsonType: "string", minLength: 1, maxLength: 500 },
                                        trigger_source: {
                                            bsonType: "string",
                                            enum: ["ASSESSMENT", "ASSIGNMENT_HOMEWORK", "ATTENDANCE"]
                                        },
                                        source_id: { bsonType: "int", minimum: 1 },
                                        triggered_at: { bsonType: "date" },
                                        status: {
                                            bsonType: "string",
                                            enum: ["ACTIVE", "ACKNOWLEDGED", "RESOLVED", "EXCUSED"]
                                        },
                                        acknowledged_at: { bsonType: ["date", "null"] },
                                        acknowledged_by_teacher_id: { bsonType: ["int", "null"] },
                                        resolved_at: { bsonType: ["date", "null"] },
                                        resolved_by_teacher_id: { bsonType: ["int", "null"] },
                                        resolution_remarks: { bsonType: ["string", "null"], maxLength: 500 },
                                        excused_reason: { bsonType: ["string", "null"], maxLength: 500 },

                                        assessment_details: {
                                            bsonType: ["object", "null"],
                                            required: [
                                                "assessment_id",
                                                "assessment_name",
                                                "max_marks",
                                                "pass_marks",
                                                "obtained_marks",
                                                "percentage"
                                            ],
                                            additionalProperties: false,
                                            properties: {
                                                assessment_id: { bsonType: "int", minimum: 1 },
                                                assessment_name: { bsonType: "string", minLength: 1, maxLength: 150 },
                                                exam_type: { bsonType: ["string", "null"], maxLength: 50 },
                                                max_marks: { bsonType: ["int", "double", "decimal"], minimum: 0 },
                                                pass_marks: { bsonType: ["int", "double", "decimal"], minimum: 0 },
                                                obtained_marks: { bsonType: ["int", "double", "decimal"], minimum: 0 },
                                                percentage: { bsonType: ["int", "double", "decimal"], minimum: 0, maximum: 100 }
                                            }
                                        },

                                        homework_details: {
                                            bsonType: ["object", "null"],
                                            required: [
                                                "homework_id",
                                                "homework_title",
                                                "assigned_date",
                                                "due_date",
                                                "submission_status"
                                            ],
                                            additionalProperties: false,
                                            properties: {
                                                homework_id: { bsonType: "int", minimum: 1 },
                                                homework_title: { bsonType: "string", minLength: 1, maxLength: 200 },
                                                assigned_date: { bsonType: "date" },
                                                due_date: { bsonType: "date" },
                                                days_overdue: { bsonType: ["int", "null"], minimum: 0 },
                                                submission_status: {
                                                    bsonType: "string",
                                                    enum: ["PENDING", "NOT_SUBMITTED", "LATE"]
                                                }
                                            }
                                        },

                                        attendance_details: {
                                            bsonType: ["object", "null"],
                                            required: [
                                                "attendance_date",
                                                "period_number",
                                                "attendance_status"
                                            ],
                                            additionalProperties: false,
                                            properties: {
                                                attendance_id: { bsonType: ["int", "null"], minimum: 1 },
                                                attendance_date: { bsonType: "date" },
                                                period_number: { bsonType: "int", minimum: 1 },
                                                period_time: { bsonType: ["string", "null"], maxLength: 30 },
                                                attendance_status: {
                                                    bsonType: "string",
                                                    enum: ["ABSENT", "UNEXCUSED_ABSENCE", "LATE"]
                                                }
                                            }
                                        }
                                    }
                                }
                            },

                            subject_summary: {
                                bsonType: ["object", "null"],
                                additionalProperties: false,
                                properties: {
                                    assessments_passed: { bsonType: "int", minimum: 0 },
                                    assessments_failed: { bsonType: "int", minimum: 0 },
                                    homework_submitted: { bsonType: "int", minimum: 0 },
                                    homework_pending: { bsonType: "int", minimum: 0 },
                                    subject_attendance_percent: {
                                        bsonType: ["int", "double", "decimal"],
                                        minimum: 0,
                                        maximum: 100
                                    }
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

    if (allCollections.includes(COLL_ATTENTIONS)) {
        var attDocsCount = targetDb[COLL_ATTENTIONS].countDocuments();
        if (attDocsCount > 0) {
            print("[MIGRATION] Found " + attDocsCount + " documents in " + COLL_ATTENTIONS + ". Upgrading IDs to NumberInt...");
            var attMigrated = 0;
            var attCursor = targetDb[COLL_ATTENTIONS].find({});
            while (attCursor.hasNext()) {
                var doc = attCursor.next();

                doc.student_id = NumberInt(doc.student_id);
                doc.school_id = NumberInt(doc.school_id);
                doc.branch_id = NumberInt(doc.branch_id);
                doc.academic_year_id = NumberInt(doc.academic_year_id);
                doc.class_id = NumberInt(doc.class_id);
                doc.section_id = NumberInt(doc.section_id);
                doc.total_active_attentions = NumberInt(doc.total_active_attentions);
                doc.critical_attentions_count = NumberInt(doc.critical_attentions_count);
                doc.is_active = NumberInt(doc.is_active || 1);

                if (Array.isArray(doc.subjects)) {
                    doc.subjects.forEach(function (subj) {
                        subj.subject_id = NumberInt(subj.subject_id);
                        if (subj.assigned_teacher_id != null) {
                            subj.assigned_teacher_id = NumberInt(subj.assigned_teacher_id);
                        }
                        subj.active_attentions_count = NumberInt(subj.active_attentions_count);

                        if (Array.isArray(subj.attentions)) {
                            subj.attentions.forEach(function (att) {
                                att.source_id = NumberInt(att.source_id);
                                if (att.acknowledged_by_teacher_id != null) {
                                    att.acknowledged_by_teacher_id = NumberInt(att.acknowledged_by_teacher_id);
                                }
                                if (att.resolved_by_teacher_id != null) {
                                    att.resolved_by_teacher_id = NumberInt(att.resolved_by_teacher_id);
                                }
                                if (att.assessment_details && att.assessment_details.assessment_id != null) {
                                    att.assessment_details.assessment_id = NumberInt(att.assessment_details.assessment_id);
                                }
                                if (att.homework_details && att.homework_details.homework_id != null) {
                                    att.homework_details.homework_id = NumberInt(att.homework_details.homework_id);
                                    if (att.homework_details.days_overdue != null) {
                                        att.homework_details.days_overdue = NumberInt(att.homework_details.days_overdue);
                                    }
                                }
                                if (att.attendance_details) {
                                    if (att.attendance_details.attendance_id != null) {
                                        att.attendance_details.attendance_id = NumberInt(att.attendance_details.attendance_id);
                                    }
                                    if (att.attendance_details.period_number != null) {
                                        att.attendance_details.period_number = NumberInt(att.attendance_details.period_number);
                                    }
                                }
                            });
                        }

                        if (subj.subject_summary) {
                            if (subj.subject_summary.assessments_passed != null) {
                                subj.subject_summary.assessments_passed = NumberInt(subj.subject_summary.assessments_passed);
                            }
                            if (subj.subject_summary.assessments_failed != null) {
                                subj.subject_summary.assessments_failed = NumberInt(subj.subject_summary.assessments_failed);
                            }
                            if (subj.subject_summary.homework_submitted != null) {
                                subj.subject_summary.homework_submitted = NumberInt(subj.subject_summary.homework_submitted);
                            }
                            if (subj.subject_summary.homework_pending != null) {
                                subj.subject_summary.homework_pending = NumberInt(subj.subject_summary.homework_pending);
                            }
                        }
                    });
                }

                targetDb[COLL_ATTENTIONS].replaceOne({ _id: doc._id }, doc);
                attMigrated++;
            }
            print("[SUCCESS] Upgraded " + attMigrated + " documents in " + COLL_ATTENTIONS + " to NumberInt.");
        }

        var attMod = targetDb.runCommand({
            collMod: COLL_ATTENTIONS,
            validator: attentionsValidator,
            validationLevel: "strict",
            validationAction: "error"
        });
        if (attMod.ok !== 1) {
            print("[ERROR] collMod failed on " + COLL_ATTENTIONS + ": " + JSON.stringify(attMod));
            throw new Error("collMod failed on " + COLL_ATTENTIONS);
        }
        print("[SUCCESS] Applied strict int JSON Schema validator to " + COLL_ATTENTIONS);
    } else {
        targetDb.createCollection(COLL_ATTENTIONS, {
            validator: attentionsValidator,
            validationLevel: "strict",
            validationAction: "error"
        });
        print("[SUCCESS] Created collection " + COLL_ATTENTIONS + " with strict int JSON Schema validator.");
    }

    // Deploy indexes on attentions
    var attIndexes = [
        { key: { student_id: 1, academic_year_id: 1 }, options: { unique: true, name: "uq_student_subject_attentions_year" } },
        { key: { school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1 }, options: { name: "ix_student_attentions_scope" } },
        { key: { "subjects.assigned_teacher_id": 1, academic_year_id: 1, "subjects.active_attentions_count": 1 }, options: { name: "ix_student_attentions_teacher" } },
        { key: { academic_year_id: 1, "subjects.attentions.status": 1, "subjects.attentions.attention_type": 1, "subjects.attentions.severity": 1 }, options: { name: "ix_student_attentions_status_type" } },
        { key: { section_id: 1, academic_year_id: 1, total_active_attentions: -1 }, options: { name: "ix_student_attentions_section_total" } }
    ];
    attIndexes.forEach(function (idx) {
        safeReconcileIndex(targetDb[COLL_ATTENTIONS], idx.key, idx.options);
    });

    print("\n================================================================================");
    print("MIGRATION COMPLETED SUCCESSFULLY FOR ALL NEW COLLECTIONS (100% Int32 / NumberInt)");
    print("================================================================================");
})();

