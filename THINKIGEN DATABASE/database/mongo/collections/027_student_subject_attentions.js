/*
    Collection: student_subject_attentions
    Module:     Teacher Portal Management & Student Academic Health
    Purpose:    Maintains subject-level student attention alerts automatically generated when:
                1. Assessment Score is below passing marks (LOW_ASSESSMENT_SCORE: obtained_marks < pass_marks)
                2. Homework / Assignment is pending or unsubmitted past due date (PENDING_HOMEWORK)
                3. Attendance is absent in a specific subject period (ABSENT_ATTENDANCE)

    Structure:
    - Scoped per student per academic year
    - Granular array of subjects with assigned teachers, active alert counts, and detailed attention items
    - Enables Subject Teachers to quickly filter alerts for their subject
    - Enables Class Teachers to review holistically across all subjects for their section

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
            student_id: { bsonType: ["int", "long"], minimum: 1 },
            student_name: { bsonType: "string", minLength: 1, maxLength: 150 },
            admission_number: { bsonType: ["string", "null"], maxLength: 50 },
            roll_number: { bsonType: ["string", "null"], maxLength: 50 },
            school_id: { bsonType: ["int", "long"], minimum: 1 },
            branch_id: { bsonType: ["int", "long"], minimum: 1 },
            academic_year_id: { bsonType: ["int", "long"], minimum: 1 },
            class_id: { bsonType: ["int", "long"], minimum: 1 },
            class_name: { bsonType: "string", minLength: 1, maxLength: 50 },
            section_id: { bsonType: ["int", "long"], minimum: 1 },
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
                        subject_id: { bsonType: ["int", "long"], minimum: 1 },
                        subject_name: { bsonType: "string", minLength: 1, maxLength: 100 },
                        subject_code: { bsonType: "string", minLength: 1, maxLength: 30 },
                        assigned_teacher_id: { bsonType: ["int", "long", "null"] },
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
                                    source_id: { bsonType: ["int", "long"], minimum: 1 },
                                    triggered_at: { bsonType: "date" },
                                    status: {
                                        bsonType: "string",
                                        enum: ["ACTIVE", "ACKNOWLEDGED", "RESOLVED", "EXCUSED"]
                                    },
                                    resolved_at: { bsonType: ["date", "null"] },
                                    resolved_by_teacher_id: { bsonType: ["int", "long", "null"] },
                                    resolution_remarks: { bsonType: ["string", "null"], maxLength: 500 },

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
                                            assessment_id: { bsonType: ["int", "long"], minimum: 1 },
                                            assessment_name: { bsonType: "string", minLength: 1, maxLength: 150 },
                                            exam_type: { bsonType: ["string", "null"], maxLength: 50 },
                                            max_marks: { bsonType: ["int", "double"], minimum: 0 },
                                            pass_marks: { bsonType: ["int", "double"], minimum: 0 },
                                            obtained_marks: { bsonType: ["int", "double"], minimum: 0 },
                                            percentage: { bsonType: ["int", "double"], minimum: 0, maximum: 100 }
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
                                            homework_id: { bsonType: ["int", "long"], minimum: 1 },
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
                                            attendance_id: { bsonType: ["int", "long", "null"] },
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
                                    bsonType: ["int", "double"],
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
if (!db.getCollectionNames().includes(COLLECTION_NAME)) {
    db.createCollection(COLLECTION_NAME, {
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Created collection: " + COLLECTION_NAME);
} else {
    db.runCommand({
        collMod: COLLECTION_NAME,
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Updated schema validation for collection: " + COLLECTION_NAME);
}

// -----------------------------------------------------------------------------
// Index Definitions
// -----------------------------------------------------------------------------
var indexes = [
    {
        key: { student_id: 1, academic_year_id: 1 },
        options: { unique: true, name: "uq_student_subject_attentions_year" }
    },
    {
        key: { school_id: 1, branch_id: 1, class_id: 1, section_id: 1, academic_year_id: 1 },
        options: { name: "ix_student_attentions_scope" }
    },
    {
        key: { "subjects.assigned_teacher_id": 1, "subjects.active_attentions_count": 1 },
        options: { name: "ix_student_attentions_teacher" }
    },
    {
        key: { "subjects.attentions.status": 1, "subjects.attentions.attention_type": 1 },
        options: { name: "ix_student_attentions_status_type" }
    },
    {
        key: { section_id: 1, total_active_attentions: 1 },
        options: { name: "ix_student_attentions_section_total" }
    }
];

indexes.forEach(function (idx) {
    if (!db[COLLECTION_NAME].getIndexes().some(function (existing) {
        return existing.name === idx.options.name;
    })) {
        db[COLLECTION_NAME].createIndex(idx.key, idx.options);
        print("Created index: " + idx.options.name + " on " + COLLECTION_NAME);
    }
});
