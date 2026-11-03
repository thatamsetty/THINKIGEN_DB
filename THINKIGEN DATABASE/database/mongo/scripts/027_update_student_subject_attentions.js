/*
    Migration Script: 027_update_student_subject_attentions.js
    Module:           Teacher Portal Management & Student Academic Health
    Target:           student_subject_attentions
    Purpose:          Production-grade migration to apply refined JSON schema validation,
                      deploy optimized indexes, perform pre-flight duplicate checks,
                      and verify collection integrity.
*/

(function () {
    var targetDb = typeof db !== "undefined" ? db.getSiblingDB("thinkigen") : null;
    if (!targetDb) {
        throw new Error("Unable to resolve target MongoDB database 'thinkigen'.");
    }

    var COLLECTION_NAME = "student_subject_attentions";
    print("================================================================================");
    print("STARTING MIGRATION: 027_update_student_subject_attentions");
    print("Target Database: " + targetDb.getName());
    print("Timestamp:       " + new Date().toISOString());
    print("================================================================================");

    // 1. PRE-FLIGHT CHECKS & DUPLICATE DETECTION
    var collections = targetDb.getCollectionNames();
    var collectionExists = collections.includes(COLLECTION_NAME);

    if (collectionExists) {
        print("[PRE-FLIGHT] Collection " + COLLECTION_NAME + " exists. Checking for duplicates...");
        var duplicates = targetDb[COLLECTION_NAME].aggregate([
            {
                $group: {
                    _id: { student_id: "$student_id", academic_year_id: "$academic_year_id" },
                    count: { $sum: 1 },
                    ids: { $push: "$_id" }
                }
            },
            {
                $match: {
                    count: { $gt: 1 }
                }
            }
        ]).toArray();

        if (duplicates.length > 0) {
            print("[ERROR] Found " + duplicates.length + " duplicate (student_id, academic_year_id) entries!");
            duplicates.forEach(function (dup) {
                print("  Conflict on student_id: " + dup._id.student_id + ", academic_year_id: " + dup._id.academic_year_id + " - IDs: " + JSON.stringify(dup.ids));
            });
            throw new Error("Pre-flight duplicate check failed. Aborting migration to prevent data inconsistency.");
        }
        print("[PRE-FLIGHT] Duplicate check passed. Zero duplicate (student_id, academic_year_id) documents found.");

        // 1.5 IN-PLACE MIGRATION OF EXISTING DOCUMENTS (CONVERT ALL IDs TO NumberInt)
        var existingDocsCount = targetDb[COLLECTION_NAME].countDocuments();
        if (existingDocsCount > 0) {
            print("[MIGRATION] Found " + existingDocsCount + " existing documents. Upgrading all IDs to 32-bit int (NumberInt)...");
            var migratedCount = 0;
            var cursor = targetDb[COLLECTION_NAME].find({});
            while (cursor.hasNext()) {
                var doc = cursor.next();

                // Cast Root IDs
                doc.student_id = NumberInt(doc.student_id);
                doc.school_id = NumberInt(doc.school_id);
                doc.branch_id = NumberInt(doc.branch_id);
                doc.academic_year_id = NumberInt(doc.academic_year_id);
                doc.class_id = NumberInt(doc.class_id);
                doc.section_id = NumberInt(doc.section_id);
                doc.total_active_attentions = NumberInt(doc.total_active_attentions);
                doc.critical_attentions_count = NumberInt(doc.critical_attentions_count);
                doc.is_active = NumberInt(doc.is_active || 1);

                // Cast nested subjects and attention IDs
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

                targetDb[COLLECTION_NAME].replaceOne({ _id: doc._id }, doc);
                migratedCount++;
            }
            print("[MIGRATION] Successfully converted all IDs to NumberInt across " + migratedCount + " documents.");
        }
    } else {
        print("[PRE-FLIGHT] Collection " + COLLECTION_NAME + " does not exist yet. It will be initialized.");
    }

    // 2. DEFINE REFINED SCHEMA VALIDATOR
    var validator = {
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
                is_active: { bsonType: "int", enum: [1] },
                created_at: { bsonType: "date" },
                updated_at: { bsonType: "date" }
            }
        }
    };

    // 3. APPLY SCHEMA VALIDATOR
    if (!collectionExists) {
        targetDb.createCollection(COLLECTION_NAME, {
            validator: validator,
            validationLevel: "strict",
            validationAction: "error"
        });
        print("[MIGRATION] Created collection " + COLLECTION_NAME + " with strict JSON Schema validator.");
    } else {
        var collModRes = targetDb.runCommand({
            collMod: COLLECTION_NAME,
            validator: validator,
            validationLevel: "strict",
            validationAction: "error"
        });
        if (collModRes.ok !== 1) {
            print("[ERROR] collMod failed: " + JSON.stringify(collModRes));
            throw new Error("collMod command failed.");
        }
        print("[MIGRATION] Successfully updated schema validation using collMod.");
    }

    // 4. DEPLOY AND RECONCILE INDEXES
    var targetIndexes = [
        {
            key: { student_id: 1, academic_year_id: 1 },
            options: { unique: true, name: "uq_student_subject_attentions_year" }
        },
        {
            key: { school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1 },
            options: { name: "ix_student_attentions_scope" }
        },
        {
            key: { "subjects.assigned_teacher_id": 1, academic_year_id: 1, "subjects.active_attentions_count": 1 },
            options: { name: "ix_student_attentions_teacher" }
        },
        {
            key: { academic_year_id: 1, "subjects.attentions.status": 1, "subjects.attentions.attention_type": 1, "subjects.attentions.severity": 1 },
            options: { name: "ix_student_attentions_status_type" }
        },
        {
            key: { section_id: 1, academic_year_id: 1, total_active_attentions: -1 },
            options: { name: "ix_student_attentions_section_total" }
        }
    ];

    var existingIndexes = targetDb[COLLECTION_NAME].getIndexes();
    targetIndexes.forEach(function (target) {
        var match = existingIndexes.find(function (e) {
            return e.name === target.options.name;
        });

        if (!match) {
            targetDb[COLLECTION_NAME].createIndex(target.key, target.options);
            print("[INDEX] Created new index: " + target.options.name);
        } else {
            var keysMatch = JSON.stringify(match.key) === JSON.stringify(target.key);
            if (!keysMatch) {
                print("[INDEX] Index " + target.options.name + " key specification changed. Rebuilding...");
                targetDb[COLLECTION_NAME].dropIndex(target.options.name);
                targetDb[COLLECTION_NAME].createIndex(target.key, target.options);
                print("[INDEX] Successfully rebuilt index: " + target.options.name);
            } else {
                print("[INDEX] Index " + target.options.name + " is up-to-date.");
            }
        }
    });

    // 5. POST-DEPLOYMENT VERIFICATION
    print("\n[VERIFICATION] Verifying deployed indexes on " + COLLECTION_NAME + ":");
    var finalIndexes = targetDb[COLLECTION_NAME].getIndexes();
    finalIndexes.forEach(function (idx) {
        print("  - " + idx.name + ": " + JSON.stringify(idx.key) + (idx.unique ? " [UNIQUE]" : ""));
    });

    print("\n================================================================================");
    print("MIGRATION COMPLETED SUCCESSFULLY FOR " + COLLECTION_NAME);
    print("================================================================================");
})();
