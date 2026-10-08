/*
    Collection: class_subject_syllabus
    Purpose: Master curriculum structure for a class + subject + academic year.
    Important: this is SHARED across all sections of the same class + subject within a branch.
    It does NOT contain section_id.
*/

if (!db.getCollectionNames().includes("class_subject_syllabus")) {
    db.createCollection("class_subject_syllabus", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "school_id",
                    "branch_id",
                    "academic_year_id",
                    "class_id",
                    "subject_id",
                    "syllabus_version",
                    "chapters",
                    "is_active",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    school_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    branch_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    academic_year_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    class_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    subject_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    syllabus_version: { bsonType: "int", minimum: 1 },
                    chapters: {
                        bsonType: "array",
                        minItems: 1,
                        items: {
                            bsonType: "object",
                            required: ["chapter_id", "title", "display_order", "is_locked", "topics"],
                            additionalProperties: false,
                            properties: {
                                chapter_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                                title: { bsonType: "string", minLength: 1, maxLength: 200 },
                                display_order: { bsonType: "int", minimum: 1 },
                                is_locked: { bsonType: "bool" },
                                topics: {
                                    bsonType: "array",
                                    minItems: 0,
                                    items: {
                                        bsonType: "object",
                                        required: ["topic_id", "number", "title", "display_order"],
                                        additionalProperties: false,
                                        properties: {
                                            topic_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                                            number: { bsonType: "string", minLength: 1, maxLength: 20 },
                                            title: { bsonType: "string", minLength: 1, maxLength: 200 },
                                            description: { bsonType: ["string", "null"], maxLength: 4000 },
                                            learning_objective: { bsonType: ["string", "null"], maxLength: 2000 },
                                            display_order: { bsonType: "int", minimum: 1 }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_by: { bsonType: ["string", "null"], maxLength: 128 },
                    updated_by: { bsonType: ["string", "null"], maxLength: 128 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

if (!db.class_subject_syllabus.getIndexes().some(function (idx) {
    return idx.name === "uq_syllabus_version_scope";
})) {
    db.class_subject_syllabus.createIndex(
        {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            class_id: 1,
            subject_id: 1,
            syllabus_version: 1
        },
        { unique: true, name: "uq_syllabus_version_scope" }
    );
}

if (!db.class_subject_syllabus.getIndexes().some(function (idx) {
    return idx.name === "uq_syllabus_active_scope";
})) {
    db.class_subject_syllabus.createIndex(
        {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            class_id: 1,
            subject_id: 1,
            is_active: 1
        },
        {
            unique: true,
            partialFilterExpression: { is_active: true },
            name: "uq_syllabus_active_scope"
        }
    );
}

if (!db.class_subject_syllabus.getIndexes().some(function (idx) {
    return idx.name === "ix_syllabus_scope_active";
})) {
    db.class_subject_syllabus.createIndex(
        {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            class_id: 1,
            subject_id: 1,
            is_active: 1,
            syllabus_version: -1
        },
        { name: "ix_syllabus_scope_active" }
    );
}
