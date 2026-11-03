/*
    Collection: teacher_daily_progress_checklist
    Module:     Teacher Portal Management
    Purpose:    Maintains teacher daily productivity snapshot including:
                1. Previous day's progress (date, completed task count, completion percentage, and status)
                2. Today's dynamic checklist of scheduled tasks by class, section, subject, room number,
                   timing (from-to), and task type:
                   - ATTENDANCE (period attendance marking)
                   - HOMEWORK_REVIEW (checking student submissions)
                   - MEETING (parent/student/department meetings - class/section optional)
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
            teacher_id: { bsonType: "int", minimum: 1 },
            school_id: { bsonType: "int", minimum: 1 },
            branch_id: { bsonType: "int", minimum: 1 },
            academic_year_id: { bsonType: "int", minimum: 1 },
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

            // Today's Dynamic Checklist
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
                        // Class and Section are nullable/optional to support MEETINGS, RESOURCE_UPLOADS, and OTHER tasks
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
                        // Student scope supports ENTIRE_SECTION, INDIVIDUAL_STUDENT, and GROUP (with group details)
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

            targetDb[COLLECTION_NAME].replaceOne({ _id: doc._id }, doc);
        }
        print("[MIGRATION] Completed in-place conversion of all checklist IDs to NumberInt.");
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
    var existing = targetDb[COLLECTION_NAME].getIndexes().find(function (e) {
        return e.name === idx.options.name;
    });

    if (!existing) {
        targetDb[COLLECTION_NAME].createIndex(idx.key, idx.options);
        print("Created index: " + idx.options.name + " on " + COLLECTION_NAME);
    } else {
        print("Index " + idx.options.name + " already exists.");
    }
});
