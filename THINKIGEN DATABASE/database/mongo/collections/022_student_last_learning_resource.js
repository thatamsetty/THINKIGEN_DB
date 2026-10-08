/*
    Collection: student_last_learning_resource
    Purpose: Remember ONLY the single most recently accessed/watched VIDEO by each student.
    
    Notes are NOT stored or tracked in this collection.
    last_resource has been completely removed.
    
    Structure:
    - student_id, school_id, branch_id, academic_year_id, class_id, section_id
    - last_video: { resource_id, resource_type ("VIDEO"), source_type, subject_id, chapter_id, topic_id, last_accessed_at } (nullable)
    - updated_at
    
    Scoped per student per academic year:
    (school_id, branch_id, academic_year_id, student_id) is unique.
*/

var COLLECTION_NAME = "student_last_learning_resource";

var validator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "student_id",
            "school_id",
            "branch_id",
            "academic_year_id",
            "class_id",
            "section_id",
            "last_video",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: { bsonType: ["objectId", "string"] },
            student_id: { bsonType: "string", minLength: 1, maxLength: 128 },
            school_id: { bsonType: ["int", "long"], minimum: 1 },
            branch_id: { bsonType: ["int", "long"], minimum: 1 },
            academic_year_id: { bsonType: ["int", "long"], minimum: 1 },
            class_id: { bsonType: ["int", "long"], minimum: 1 },
            section_id: { bsonType: ["int", "long"], minimum: 1 },
            last_video: {
                bsonType: ["object", "null"],
                required: [
                    "resource_id",
                    "resource_type",
                    "source_type",
                    "subject_id",
                    "chapter_id",
                    "topic_id",
                    "last_accessed_at"
                ],
                additionalProperties: false,
                properties: {
                    resource_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    resource_type: {
                        bsonType: "string",
                        enum: ["VIDEO"]
                    },
                    source_type: {
                        bsonType: "string",
                        enum: ["TEACHER", "COMPASS"]
                    },
                    subject_id: { bsonType: ["int", "long"], minimum: 1 },
                    chapter_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    topic_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    last_accessed_at: { bsonType: "date" }
                }
            },
            updated_at: { bsonType: "date" }
        }
    }
};

/* --- FAIL-SAFE MIGRATION HELPERS --- */
function isNumericBSON(val) {
    if (val === null || val === undefined) return false;
    if (typeof val === "number") return true;
    if (val instanceof NumberInt || val instanceof NumberLong) return true;
    if (val._bsontype === "Int32" || val._bsontype === "Long" || val._bsontype === "Double") return true;
    return false;
}

function parseNumericID(val, fieldName, docId) {
    if (val === null || val === undefined) {
        throw new Error("MIGRATION STOPPED: Missing required numeric field '" + fieldName + "' in document " + docId);
    }
    if (isNumericBSON(val)) {
        var num = val.valueOf();
        if (num < 1) {
            throw new Error("MIGRATION STOPPED: Invalid minimum value (" + num + ") for numeric field '" + fieldName + "' in document " + docId);
        }
        return (val instanceof NumberLong || (val && val._bsontype === "Long")) ? NumberLong(num) : NumberInt(num);
    }
    if (typeof val === "string") {
        var trimmed = val.trim();
        if (/^\d+$/.test(trimmed)) {
            var parsed = parseInt(trimmed, 10);
            if (parsed < 1) {
                throw new Error("MIGRATION STOPPED: Invalid minimum value (" + parsed + ") for numeric string field '" + fieldName + "' in document " + docId);
            }
            return NumberInt(parsed);
        } else {
            throw new Error("MIGRATION STOPPED: Unsafe non-numeric string identifier found for " + fieldName + ": '" + val + "' in document " + docId);
        }
    }
    throw new Error("MIGRATION STOPPED: Unexpected type for " + fieldName + ": " + (typeof val) + " in document " + docId);
}

function parseBSONDate(val, fieldName, docId) {
    if (val instanceof Date && !isNaN(val.getTime())) {
        return val;
    }
    if (typeof val === "string" || typeof val === "number") {
        var d = new Date(val);
        if (!isNaN(d.getTime())) return d;
    }
    throw new Error("MIGRATION STOPPED: Invalid date value for " + fieldName + " in document " + docId);
}

function indexesAreEquivalent(existingIdx, desiredIdx) {
    var eFilter = existingIdx.partialFilterExpression ? JSON.stringify(existingIdx.partialFilterExpression) : null;
    var dFilter = desiredIdx.options.partialFilterExpression ? JSON.stringify(desiredIdx.options.partialFilterExpression) : null;

    var eCollation = existingIdx.collation ? JSON.stringify(existingIdx.collation) : null;
    var dCollation = desiredIdx.options.collation ? JSON.stringify(desiredIdx.options.collation) : null;

    return JSON.stringify(existingIdx.key) === JSON.stringify(desiredIdx.key) &&
        (existingIdx.unique === true) === (desiredIdx.options.unique === true) &&
        eFilter === dFilter &&
        (existingIdx.sparse === true) === (desiredIdx.options.sparse === true) &&
        eCollation === dCollation;
}

/* --- COLLECTION CREATION & MIGRATION BLOCK --- */
var docsMigratedCount = 0;

if (db.getCollectionNames().includes(COLLECTION_NAME)) {
    var existingDocs = db[COLLECTION_NAME].find({}).toArray();

    if (existingDocs.length > 0) {
        print("Checking and migrating " + existingDocs.length + " existing documents in " + COLLECTION_NAME + "...");

        existingDocs.forEach(function (doc) {
            var docIdStr = doc._id ? doc._id.toString() : doc.student_id;
            var updated = false;

            // 1. Root Numeric Scope IDs migration
            var rootSchoolId = parseNumericID(doc.school_id, "school_id", docIdStr);
            var rootBranchId = parseNumericID(doc.branch_id, "branch_id", docIdStr);
            var rootAcademicYearId = parseNumericID(doc.academic_year_id, "academic_year_id", docIdStr);
            var rootClassId = parseNumericID(doc.class_id, "class_id", docIdStr);
            var rootSectionId = parseNumericID(doc.section_id, "section_id", docIdStr);

            if (doc.school_id !== rootSchoolId) { doc.school_id = rootSchoolId; updated = true; }
            if (doc.branch_id !== rootBranchId) { doc.branch_id = rootBranchId; updated = true; }
            if (doc.academic_year_id !== rootAcademicYearId) { doc.academic_year_id = rootAcademicYearId; updated = true; }
            if (doc.class_id !== rootClassId) { doc.class_id = rootClassId; updated = true; }
            if (doc.section_id !== rootSectionId) { doc.section_id = rootSectionId; updated = true; }

            // Ensure student_id remains string
            if (typeof doc.student_id !== "string" || doc.student_id.trim() === "") {
                throw new Error("MIGRATION STOPPED: student_id must be a non-empty string in document " + docIdStr);
            }

            // 2. Process legacy last_resource if present & Purge it
            if (doc.last_resource !== undefined) {
                var lr = doc.last_resource;
                if (doc.last_video === undefined && lr && typeof lr === "object" && lr.resource_id) {
                    var lrType = lr.resource_type;
                    var lrSource = lr.source_type;

                    if (!lrType || !lrSource) {
                        var refLrDoc = db.learning_resource.findOne({ resource_id: lr.resource_id });
                        if (refLrDoc) {
                            lrType = lrType || refLrDoc.resource_type;
                            lrSource = lrSource || refLrDoc.source_type;
                        }
                    }

                    if (lrType === "VIDEO") {
                        doc.last_video = {
                            resource_id: lr.resource_id,
                            resource_type: "VIDEO",
                            source_type: lrSource || "TEACHER",
                            subject_id: parseNumericID(lr.subject_id, "last_resource.subject_id", docIdStr),
                            chapter_id: lr.chapter_id,
                            topic_id: lr.topic_id,
                            last_accessed_at: parseBSONDate(lr.last_accessed_at, "last_resource.last_accessed_at", docIdStr)
                        };
                    } else {
                        doc.last_video = null;
                    }
                }

                // Delete last_resource completely
                delete doc.last_resource;
                updated = true;
            }

            // 3. Validate / Migrate last_video
            if (doc.last_video === undefined) {
                doc.last_video = null;
                updated = true;
            } else if (doc.last_video !== null) {
                var lv = doc.last_video;
                if (typeof lv !== "object") {
                    throw new Error("MIGRATION STOPPED: last_video must be object or null in document " + docIdStr);
                }
                if (typeof lv.resource_id !== "string" || lv.resource_id.trim() === "") {
                    throw new Error("MIGRATION STOPPED: last_video.resource_id must be string in document " + docIdStr);
                }
                if (typeof lv.chapter_id !== "string" || lv.chapter_id.trim() === "") {
                    throw new Error("MIGRATION STOPPED: last_video.chapter_id must be string in document " + docIdStr);
                }
                if (typeof lv.topic_id !== "string" || lv.topic_id.trim() === "") {
                    throw new Error("MIGRATION STOPPED: last_video.topic_id must be string in document " + docIdStr);
                }

                var lvSubjectId = parseNumericID(lv.subject_id, "last_video.subject_id", docIdStr);
                if (lv.subject_id !== lvSubjectId) { lv.subject_id = lvSubjectId; updated = true; }

                var lvLastAccessedAt = parseBSONDate(lv.last_accessed_at, "last_video.last_accessed_at", docIdStr);
                if (lv.last_accessed_at !== lvLastAccessedAt) { lv.last_accessed_at = lvLastAccessedAt; updated = true; }

                if (!lv.resource_type || !lv.source_type) {
                    var refVideoDoc = db.learning_resource.findOne({ resource_id: lv.resource_id });
                    if (!refVideoDoc) {
                        throw new Error("MIGRATION STOPPED: Referenced learning_resource with resource_id '" + lv.resource_id + "' for last_video not found in learning_resource collection for document " + docIdStr);
                    }
                    lv.resource_type = refVideoDoc.resource_type;
                    lv.source_type = refVideoDoc.source_type;
                    updated = true;
                }

                if (lv.resource_type !== "VIDEO") {
                    throw new Error("MIGRATION STOPPED: last_video.resource_type MUST be 'VIDEO', found '" + lv.resource_type + "' in document " + docIdStr);
                }
                if (!["TEACHER", "COMPASS"].includes(lv.source_type)) {
                    throw new Error("MIGRATION STOPPED: Invalid last_video.source_type '" + lv.source_type + "' in document " + docIdStr);
                }
            }

            // Ensure root updated_at is Date
            var rootUpdatedAt = doc.updated_at ? parseBSONDate(doc.updated_at, "updated_at", docIdStr) : new Date();
            if (doc.updated_at !== rootUpdatedAt) { doc.updated_at = rootUpdatedAt; updated = true; }

            if (updated) {
                db[COLLECTION_NAME].replaceOne({ _id: doc._id }, doc);
                docsMigratedCount++;
            }
        });
        print("Successfully validated/migrated " + docsMigratedCount + " document(s).");
    }

    db.runCommand({
        collMod: COLLECTION_NAME,
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
} else {
    db.createCollection(COLLECTION_NAME, {
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
}

/* --- IDEMPOTENT INDEX MANAGEMENT BLOCK --- */
// Clean up obsolete indexes referencing last_resource if present
db[COLLECTION_NAME].getIndexes().forEach(function (idx) {
    if (idx.name === "ix_student_last_learning_resource_subject" || JSON.stringify(idx.key).indexOf("last_resource") !== -1) {
        print("Dropping obsolete index referencing last_resource: " + idx.name);
        db[COLLECTION_NAME].dropIndex(idx.name);
    }
});

var indexes = [
    {
        key: {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            student_id: 1
        },
        options: { unique: true, name: "uq_student_last_learning_resource" }
    },
    {
        key: {
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            class_id: 1,
            section_id: 1,
            student_id: 1
        },
        options: { name: "ix_student_last_learning_resource_scope" }
    }
];

indexes.forEach(function (idx) {
    var existingIndexes = db[COLLECTION_NAME].getIndexes();
    var existingIdx = existingIndexes.find(function (e) { return e.name === idx.options.name; });
    var needsCreation = false;

    if (existingIdx) {
        if (!indexesAreEquivalent(existingIdx, idx)) {
            print("Dropping outdated index definition: " + idx.options.name);
            db[COLLECTION_NAME].dropIndex(idx.options.name);
            needsCreation = true;
        }
    } else {
        needsCreation = true;
    }

    if (needsCreation) {
        existingIndexes = db[COLLECTION_NAME].getIndexes();
        var duplicate = existingIndexes.find(function (e) {
            return indexesAreEquivalent(e, idx) && e.name !== idx.options.name;
        });
        if (duplicate) {
            print("Dropping duplicate equivalent index with name: " + duplicate.name);
            db[COLLECTION_NAME].dropIndex(duplicate.name);
        }

        try {
            db[COLLECTION_NAME].createIndex(idx.key, idx.options);
            print("Created index: " + idx.options.name);
        } catch (e) {
            print("---------------------------------------------------------");
            print("CRITICAL ERROR: Failed to create index " + idx.options.name);
            print(e.message);
            print("---------------------------------------------------------");
            throw e;
        }
    }
});

/* --- FINAL VERIFICATION BLOCK --- */
var collections = db.getCollectionNames();
if (!collections.includes(COLLECTION_NAME)) {
    throw new Error("FINAL VERIFICATION FAILED: Collection " + COLLECTION_NAME + " does not exist.");
}

var infos = db.getCollectionInfos({ name: COLLECTION_NAME });
if (infos.length === 0 || !infos[0].options || !infos[0].options.validator) {
    throw new Error("FINAL VERIFICATION FAILED: Collection " + COLLECTION_NAME + " validator is missing.");
}
if (infos[0].options.validationLevel !== "strict" || infos[0].options.validationAction !== "error") {
    throw new Error("FINAL VERIFICATION FAILED: Validation level must be strict and action must be error.");
}

// Check existing documents against requirements
var allDocs = db[COLLECTION_NAME].find({}).toArray();
allDocs.forEach(function (doc) {
    var docIdStr = doc._id ? doc._id.toString() : doc.student_id;

    // Verify last_resource field does NOT exist
    if ("last_resource" in doc) {
        throw new Error("FINAL VERIFICATION FAILED: Obsolete last_resource field still exists in doc " + docIdStr);
    }

    // Check numeric scope IDs
    ["school_id", "branch_id", "academic_year_id", "class_id", "section_id"].forEach(function (f) {
        if (!isNumericBSON(doc[f])) {
            throw new Error("FINAL VERIFICATION FAILED: Field " + f + " is not numeric BSON in doc " + docIdStr);
        }
    });

    // Check string IDs
    if (typeof doc.student_id !== "string") {
        throw new Error("FINAL VERIFICATION FAILED: student_id is not a string in doc " + docIdStr);
    }

    // Check last_video structure & pointer integrity
    if (doc.last_video !== null) {
        if (typeof doc.last_video !== "object") {
            throw new Error("FINAL VERIFICATION FAILED: last_video is neither null nor object in doc " + docIdStr);
        }
        if (doc.last_video.resource_type !== "VIDEO") {
            throw new Error("FINAL VERIFICATION FAILED: last_video.resource_type is not 'VIDEO' in doc " + docIdStr);
        }
        if (!["TEACHER", "COMPASS"].includes(doc.last_video.source_type)) {
            throw new Error("FINAL VERIFICATION FAILED: Invalid last_video.source_type in doc " + docIdStr);
        }
        if (typeof doc.last_video.resource_id !== "string") {
            throw new Error("FINAL VERIFICATION FAILED: last_video.resource_id is not a string in doc " + docIdStr);
        }
        if (typeof doc.last_video.chapter_id !== "string") {
            throw new Error("FINAL VERIFICATION FAILED: last_video.chapter_id is not a string in doc " + docIdStr);
        }
        if (typeof doc.last_video.topic_id !== "string") {
            throw new Error("FINAL VERIFICATION FAILED: last_video.topic_id is not a string in doc " + docIdStr);
        }
        if (!isNumericBSON(doc.last_video.subject_id)) {
            throw new Error("FINAL VERIFICATION FAILED: last_video.subject_id is not numeric BSON in doc " + docIdStr);
        }

        // Pointer Integrity Check against learning_resource
        var lvCheck = db.learning_resource.findOne({ resource_id: doc.last_video.resource_id });
        if (!lvCheck) {
            throw new Error("FINAL VERIFICATION FAILED: last_video.resource_id '" + doc.last_video.resource_id + "' does not exist in learning_resource collection for doc " + docIdStr);
        }
        if (lvCheck.resource_type !== "VIDEO") {
            throw new Error("FINAL VERIFICATION FAILED: Referenced learning_resource '" + doc.last_video.resource_id + "' is not a VIDEO for doc " + docIdStr);
        }
        if (lvCheck.source_type !== doc.last_video.source_type) {
            throw new Error("FINAL VERIFICATION FAILED: source_type mismatch for referenced learning_resource '" + doc.last_video.resource_id + "' for doc " + docIdStr);
        }
        if (lvCheck.subject_id.valueOf() !== doc.last_video.subject_id.valueOf()) {
            throw new Error("FINAL VERIFICATION FAILED: subject_id mismatch for referenced learning_resource '" + doc.last_video.resource_id + "' for doc " + docIdStr);
        }
        if (lvCheck.chapter_id !== doc.last_video.chapter_id) {
            throw new Error("FINAL VERIFICATION FAILED: chapter_id mismatch for referenced learning_resource '" + doc.last_video.resource_id + "' for doc " + docIdStr);
        }
        if (lvCheck.topic_id !== doc.last_video.topic_id) {
            throw new Error("FINAL VERIFICATION FAILED: topic_id mismatch for referenced learning_resource '" + doc.last_video.resource_id + "' for doc " + docIdStr);
        }
        if (lvCheck.school_id.valueOf() !== doc.school_id.valueOf()) {
            throw new Error("FINAL VERIFICATION FAILED: school_id scope mismatch for doc " + docIdStr);
        }
        if (lvCheck.branch_id.valueOf() !== doc.branch_id.valueOf()) {
            throw new Error("FINAL VERIFICATION FAILED: branch_id scope mismatch for doc " + docIdStr);
        }
        if (lvCheck.academic_year_id.valueOf() !== doc.academic_year_id.valueOf()) {
            throw new Error("FINAL VERIFICATION FAILED: academic_year_id scope mismatch for doc " + docIdStr);
        }
        if (lvCheck.class_id.valueOf() !== doc.class_id.valueOf()) {
            throw new Error("FINAL VERIFICATION FAILED: class_id scope mismatch for doc " + docIdStr);
        }
        if (lvCheck.section_id.valueOf() !== doc.section_id.valueOf()) {
            throw new Error("FINAL VERIFICATION FAILED: section_id scope mismatch for doc " + docIdStr);
        }
    }
});

// Final Index Verifications
var finalIndexes = db[COLLECTION_NAME].getIndexes();
indexes.forEach(function (reqIdx) {
    var foundObj = finalIndexes.find(function (f) { return f.name === reqIdx.options.name; });
    if (!foundObj) {
        throw new Error("FINAL INDEX VERIFICATION FAILED: Index " + reqIdx.options.name + " is missing.");
    }
    if (!indexesAreEquivalent(foundObj, reqIdx)) {
        throw new Error("FINAL INDEX VERIFICATION FAILED: Index " + reqIdx.options.name + " definition mismatches requested constraints.");
    }
});

// Verify compound unique index
var uniqueIdx = finalIndexes.find(function (f) { return f.name === "uq_student_last_learning_resource"; });
if (!uniqueIdx || !uniqueIdx.unique || JSON.stringify(uniqueIdx.key) !== JSON.stringify({ school_id: 1, branch_id: 1, academic_year_id: 1, student_id: 1 })) {
    throw new Error("FINAL INDEX VERIFICATION FAILED: Unique index uq_student_last_learning_resource must be unique on (school_id, branch_id, academic_year_id, student_id).");
}

/* --- SUCCESS REPORTING --- */
print("=========================================================");
print("MIGRATION AND FINAL VERIFICATION SUCCESSFUL");
print("Collection: " + COLLECTION_NAME);
print("Validation Level: strict");
print("Validation Action: error");
print("Total documents in collection: " + allDocs.length);
print("Documents migrated/updated: " + docsMigratedCount);
print("Required indexes verified: " + indexes.length);
print("Unique compound index verified: (school_id, branch_id, academic_year_id, student_id)");
print("=========================================================");
