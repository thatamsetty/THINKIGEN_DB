/*
    Collection: exam_paper
    Purpose: Final exam paper catalog for the Learning Hub.
    Scope: school -> branch -> academic_year -> class -> subject.
    Important: exam papers are class-level shared resources, not section-specific.
    No section_id, no student_id, no separate per-student copies.
*/

var COLLECTION_NAME = "exam_paper";

var validator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "exam_paper_id",
            "school_id",
            "branch_id",
            "academic_year_id",
            "class_id",
            "subject_id",
            "title",
            "exam_year",
            "category",
            "duration_minutes",
            "max_marks",
            "question_count",
            "storage_reference",
            "is_active",
            "created_at",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: { bsonType: "objectId" },
            exam_paper_id: { bsonType: ["int", "long"], minimum: 1 },
            school_id: { bsonType: ["int", "long"], minimum: 1 },
            branch_id: { bsonType: ["int", "long"], minimum: 1 },
            academic_year_id: { bsonType: ["int", "long"], minimum: 1 },
            class_id: { bsonType: ["int", "long"], minimum: 1 },
            subject_id: { bsonType: ["int", "long"], minimum: 1 },
            title: { bsonType: "string", minLength: 1, maxLength: 200 },
            exam_year: {
                bsonType: "string",
                pattern: "^(19|20)[0-9]{2}$"
            },
            category: {
                bsonType: "string",
                enum: ["UNIT_TEST", "MID_TERM", "PRE_FINAL", "FINAL", "BOARD", "AI_GENERATED"]
            },
            duration_minutes: { bsonType: ["int", "long"], minimum: 1, maximum: 1440 },
            max_marks: { bsonType: ["int", "long"], minimum: 1 },
            question_count: { bsonType: ["int", "long"], minimum: 1 },
            storage_reference: {
                bsonType: "object",
                additionalProperties: false,
                required: ["provider", "bucket", "object_key"],
                properties: {
                    provider: { bsonType: "string", enum: ["AWS_S3"] },
                    bucket: { bsonType: "string", enum: ["thinkigen"] },
                    object_key: { bsonType: "string", minLength: 1, maxLength: 2048 }
                }
            },
            is_active: { bsonType: "bool" },
            created_at: { bsonType: "date" },
            updated_at: { bsonType: "date" },
            created_by: { bsonType: ["int", "long", "null"], minimum: 1 },
            updated_by: { bsonType: ["int", "long", "null"], minimum: 1 }
        }
    }
};

if (!db.getCollectionNames().includes(COLLECTION_NAME)) {
    db.createCollection(COLLECTION_NAME, {
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
} else {
    db.runCommand({
        collMod: COLLECTION_NAME,
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
}

// Ensure old conflicting index is dropped if it previously existed
var existingIndexes = db.exam_paper.getIndexes();
if (existingIndexes.some(function (idx) { return idx.name === "uq_exam_paper_class_title"; })) {
    print("Dropping deprecated unique title index to safely support Set A/B/C variants...");
    db.exam_paper.dropIndex("uq_exam_paper_class_title");
}

if (!existingIndexes.some(function (idx) {
    return idx.name === "uq_exam_paper_id";
})) {
    db.exam_paper.createIndex(
        { exam_paper_id: 1 },
        { unique: true, name: "uq_exam_paper_id" }
    );
}

// Restored as a non-unique index to safely support Set A/B/C or identically titled papers across the same segment
if (!existingIndexes.some(function (idx) {
    return idx.name === "ix_exam_paper_class_title";
})) {
    db.exam_paper.createIndex(
        {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            class_id: 1,
            subject_id: 1,
            category: 1,
            exam_year: 1,
            title: 1
        },
        { name: "ix_exam_paper_class_title" }
    );
}

if (!existingIndexes.some(function (idx) {
    return idx.name === "ix_exam_paper_class_category";
})) {
    db.exam_paper.createIndex(
        {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            class_id: 1,
            subject_id: 1,
            category: 1,
            is_active: 1
        },
        { name: "ix_exam_paper_class_category" }
    );
}

print("exam_paper collection verified and structurally locked safely.");
