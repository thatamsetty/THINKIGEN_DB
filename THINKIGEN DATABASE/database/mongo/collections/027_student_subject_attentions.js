/*
    Collection: student_subject_attentions
    Module:     Teacher Portal Management & Student Academic Health
    Purpose:    Maintains subject-level student attention alerts automatically generated from:
                1. Assessment Score is below passing marks (LOW_ASSESSMENT_SCORE: obtained_marks < pass_marks)
                2. Homework / Assignment is pending or unsubmitted past due date (PENDING_HOMEWORK)
                3. Attendance is absent in a specific subject period (ABSENT_ATTENDANCE)

    Structure:
    - Scoped per student per academic year
    - Granular array of subjects with assigned teachers, active alert counts, and detailed attention items
    - Enables Subject Teachers to quickly filter alerts for their subject
    - Enables Class Teachers to review holistically across all subjects for their section
    - Enables School & Branch Leadership to track systemic academic risks

    Unique Constraint: (student_id, academic_year_id)
*/

var COLLECTION_NAME = "student_subject_attentions";

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

            // Subjects array containing subject-specific attentions
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

                        // List of attention items for this subject
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

                                    // Contextual details for Assessment trigger (marks < pass_marks)
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

                                    // Contextual details for Pending Homework trigger
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

                                    // Contextual details for Absent Attendance trigger (subject period)
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

                        // Optional subject-level performance health summary
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

// -----------------------------------------------------------------------------
// Collection Initialization & Schema Enforcement
// -----------------------------------------------------------------------------
var targetDb = typeof db !== "undefined" ? db.getSiblingDB("thinkigen") : null;
if (!targetDb) {
    throw new Error("Unable to resolve target MongoDB database 'thinkigen'.");
}

if (!targetDb.getCollectionNames().includes(COLLECTION_NAME)) {
    targetDb.createCollection(COLLECTION_NAME, {
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Created collection: " + COLLECTION_NAME + " with strict int schema validation.");
} else {
    // In-place upgrade: Convert any existing document IDs from long to 32-bit int
    var existingDocsCount = targetDb[COLLECTION_NAME].countDocuments();
    if (existingDocsCount > 0) {
        print("[MIGRATION] Found " + existingDocsCount + " existing documents. Upgrading all IDs to 32-bit int (NumberInt)...");
        var cursor = targetDb[COLLECTION_NAME].find({});
        while (cursor.hasNext()) {
            var doc = cursor.next();

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

            targetDb[COLLECTION_NAME].replaceOne({ _id: doc._id }, doc);
        }
        print("[MIGRATION] Completed in-place conversion of all IDs to NumberInt.");
    }

    targetDb.runCommand({
        collMod: COLLECTION_NAME,
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Updated schema validation for collection: " + COLLECTION_NAME);
}

// -----------------------------------------------------------------------------
// Production Index Definitions
// -----------------------------------------------------------------------------
var indexes = [
    // 1. Root Unique Constraint: Enforces 1 document per student per academic year
    {
        key: { student_id: 1, academic_year_id: 1 },
        options: { unique: true, name: "uq_student_subject_attentions_year" }
    },
    // 2. Hierarchy Scope Index: Supports School, Branch, Year, Class, Section navigation
    // Field order: school_id -> branch_id -> academic_year_id -> class_id -> section_id
    // Allows prefix scans for management branch-level overviews as well as section-level queries
    {
        key: { school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1 },
        options: { name: "ix_student_attentions_scope" }
    },
    // 3. Subject Teacher Dashboard Index: Filter by assigned teacher in active academic year
    {
        key: { "subjects.assigned_teacher_id": 1, academic_year_id: 1, "subjects.active_attentions_count": 1 },
        options: { name: "ix_student_attentions_teacher" }
    },
    // 4. Status, Type, and Severity Alert Triage Index:
    // Anchored with academic_year_id to avoid whole-collection multikey index scans
    {
        key: { academic_year_id: 1, "subjects.attentions.status": 1, "subjects.attentions.attention_type": 1, "subjects.attentions.severity": 1 },
        options: { name: "ix_student_attentions_status_type" }
    },
    // 5. Class Teacher Section Priority Index:
    // Sorts students by total active attentions descending so critical interventions appear first
    {
        key: { section_id: 1, academic_year_id: 1, total_active_attentions: -1 },
        options: { name: "ix_student_attentions_section_total" }
    }
];

indexes.forEach(function (idx) {
    var existingIndexes = targetDb[COLLECTION_NAME].getIndexes();
    var match = existingIndexes.find(function (e) {
        return e.name === idx.options.name;
    });

    if (!match) {
        targetDb[COLLECTION_NAME].createIndex(idx.key, idx.options);
        print("Created index: " + idx.options.name + " on " + COLLECTION_NAME);
    } else {
        // Verify key pattern matches; if changed, drop and recreate
        var keysMatch = JSON.stringify(match.key) === JSON.stringify(idx.key);
        if (!keysMatch) {
            print("Index " + idx.options.name + " key pattern changed. Rebuilding index...");
            targetDb[COLLECTION_NAME].dropIndex(idx.options.name);
            targetDb[COLLECTION_NAME].createIndex(idx.key, idx.options);
            print("Rebuilt index: " + idx.options.name);
        } else {
            print("Index " + idx.options.name + " already exists with correct keys.");
        }
    }
});
