/*
    Collection: teacher_daily_progress_checklist
    Module:     Teacher Portal Management
    Purpose:    Maintains teacher daily productivity snapshot including:
                1. Previous day's progress (date, completed task count, completion percentage, and status)
                2. Today's dynamic checklist of scheduled tasks by class, section, subject, room number,
                   timing (from-to), and task type:
                   - ATTENDANCE (period attendance marking)
                   - HOMEWORK_REVIEW (checking student submissions)
                   - MEETING (parent/student/department meetings)
                   - RESOURCE_UPLOAD (study material / video / notes publishing)
                   - ASSESSMENT_EVALUATION (grading test papers)
                   - CLASSWORK / OTHER

    Scoped per teacher per calendar day:
    (teacher_id, as_of_date) is unique.
*/

var COLLECTION_NAME = "teacher_daily_progress_checklist";

var validator = {
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
            teacher_id: { bsonType: ["int", "long"], minimum: 1 },
            school_id: { bsonType: ["int", "long"], minimum: 1 },
            branch_id: { bsonType: ["int", "long"], minimum: 1 },
            academic_year_id: { bsonType: ["int", "long"], minimum: 1 },
            as_of_date: { bsonType: "date" },
            
            // Previous Day's Progress Tracking
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
                        bsonType: ["int", "double"],
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

            // Today's Dynamic Checklist
            checklist_items: {
                bsonType: "array",
                items: {
                    bsonType: "object",
                    required: [
                        "item_id",
                        "task_title",
                        "task_type",
                        "class_id",
                        "class_name",
                        "section_id",
                        "section_name",
                        "room_no",
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
                        class_id: { bsonType: ["int", "long"], minimum: 1 },
                        class_name: { bsonType: "string", minLength: 1, maxLength: 50 },
                        section_id: { bsonType: ["int", "long"], minimum: 1 },
                        section_name: { bsonType: "string", minLength: 1, maxLength: 20 },
                        subject_id: { bsonType: ["int", "long", "null"] },
                        subject_name: { bsonType: ["string", "null"], maxLength: 100 },
                        room_no: { bsonType: "string", minLength: 1, maxLength: 50 },
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
                                student_id: { bsonType: ["int", "long", "null"] },
                                student_name: { bsonType: ["string", "null"], maxLength: 150 }
                            }
                        },
                        priority: {
                            bsonType: "string",
                            enum: ["HIGH", "MEDIUM", "LOW"]
                        },
                        is_completed: { bsonType: "bool" },
                        completed_at: { bsonType: ["date", "null"] },
                        reference_id: { bsonType: ["string", "int", "long", "null"] },
                        remarks: { bsonType: ["string", "null"], maxLength: 500 }
                    }
                }
            },

            // Pre-aggregated metrics for instant UI consumption
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
        key: { teacher_id: 1, as_of_date: 1 },
        options: { unique: true, name: "uq_teacher_daily_progress_date" }
    },
    {
        key: { school_id: 1, branch_id: 1, as_of_date: 1 },
        options: { name: "ix_teacher_daily_progress_scope" }
    },
    {
        key: { teacher_id: 1, "checklist_items.task_type": 1 },
        options: { name: "ix_teacher_daily_checklist_type" }
    },
    {
        key: { "checklist_items.class_id": 1, "checklist_items.section_id": 1, as_of_date: 1 },
        options: { name: "ix_teacher_daily_checklist_class_section" }
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
