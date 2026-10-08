/*
    Collection: course_progress
    Purpose: Teacher-controlled section-level course completion percentage.
    Scope: school, branch, academic_year, class, section, subject.
    This is NOT student progress and does NOT include student_id.
*/

if (!db.getCollectionNames().includes("course_progress")) {
    db.createCollection("course_progress", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "progress_id",
                    "school_id",
                    "branch_id",
                    "academic_year_id",
                    "class_id",
                    "section_id",
                    "subject_id",
                    "syllabus_version",
                    "progress_percentage",
                    "progress_date",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    progress_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    school_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    branch_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    academic_year_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    class_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    section_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    subject_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    syllabus_version: { bsonType: "int", minimum: 1 },
                    progress_percentage: { bsonType: "double", minimum: 0, maximum: 100 },
                    progress_date: { bsonType: "date" },
                    timetable_id: { bsonType: ["string", "null"], maxLength: 128 },
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

if (!db.course_progress.getIndexes().some(function (idx) {
    return idx.name === "uq_course_progress_identity";
})) {
    db.course_progress.createIndex(
        {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            class_id: 1,
            section_id: 1,
            subject_id: 1,
            syllabus_version: 1,
            progress_date: 1
        },
        { unique: true, name: "uq_course_progress_identity" }
    );
}

if (!db.course_progress.getIndexes().some(function (idx) {
    return idx.name === "ix_course_progress_scope_date";
})) {
    db.course_progress.createIndex(
        {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            class_id: 1,
            section_id: 1,
            subject_id: 1,
            progress_date: -1
        },
        { name: "ix_course_progress_scope_date" }
    );
}
