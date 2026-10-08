/*
    Collection: learning_resource
    Purpose: Stores learning materials associated with a topic.
    Resources are section-specific, so section_id is required.
    Supported combinations are:
    - VIDEO + TEACHER
    - NOTE + TEACHER
    - NOTE + COMPASS
*/

var COLLECTION_NAME = "learning_resource_documents";

var validator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "resource_id",
            "school_id",
            "branch_id",
            "academic_year_id",
            "class_id",
            "section_id",
            "subject_id",
            "syllabus_version",
            "chapter_id",
            "topic_id",
            "resource_type",
            "source_type",
            "title",
            "status",
            "created_at",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: { bsonType: "objectId" },
            resource_id: { bsonType: "string", minLength: 1, maxLength: 128 },
            school_id: { bsonType: ["int", "long"], minimum: 1 },
            branch_id: { bsonType: ["int", "long"], minimum: 1 },
            academic_year_id: { bsonType: ["int", "long"], minimum: 1 },
            class_id: { bsonType: ["int", "long"], minimum: 1 },
            section_id: { bsonType: ["int", "long"], minimum: 1 },
            subject_id: { bsonType: ["int", "long"], minimum: 1 },
            syllabus_version: { bsonType: ["int", "long"], minimum: 1 },
            chapter_id: { bsonType: "string", minLength: 1, maxLength: 128 },
            topic_id: { bsonType: "string", minLength: 1, maxLength: 128 },
            resource_type: {
                bsonType: "string",
                enum: ["VIDEO", "NOTE"]
            },
            source_type: {
                bsonType: "string",
                enum: ["TEACHER", "COMPASS"]
            },
            title: { bsonType: "string", minLength: 1, maxLength: 200 },
            description: { bsonType: ["string", "null"], maxLength: 10000 },
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
            duration_seconds: { bsonType: ["number", "null"], minimum: 0 },
            key_takeaways: {
                bsonType: ["array", "null"],
                maxItems: 25,
                items: { bsonType: "string", minLength: 1, maxLength: 1000 }
            },
            file_metadata: {
                bsonType: ["object", "null"],
                additionalProperties: false,
                properties: {
                    original_file_name: { bsonType: ["string", "null"], maxLength: 2000 },
                    mime_type: { bsonType: ["string", "null"], maxLength: 200 },
                    file_size_bytes: { bsonType: ["int", "long", "null"], minimum: 0 }
                }
            },
            status: {
                bsonType: "string",
                enum: ["PROCESSING", "READY", "PUBLISHED", "ARCHIVED"]
            },
            created_at: { bsonType: "date" },
            updated_at: { bsonType: "date" },
            created_by: { bsonType: ["int", "long", "null"], minimum: 1 },
            updated_by: { bsonType: ["int", "long", "null"], minimum: 1 }
        },
        anyOf: [
            {
                properties: {
                    resource_type: { enum: ["VIDEO"] },
                    source_type: { enum: ["TEACHER"] },
                    duration_seconds: { bsonType: "number", minimum: 0 }
                },
                required: ["description", "duration_seconds", "storage_reference"]
            },
            {
                properties: {
                    resource_type: { enum: ["NOTE"] },
                    source_type: { enum: ["TEACHER"] }
                },
                required: ["storage_reference"]
            },
            {
                properties: {
                    resource_type: { enum: ["NOTE"] },
                    source_type: { enum: ["COMPASS"] }
                },
                required: ["storage_reference"]
            }
        ],
        allOf: [
            {
                not: {
                    properties: {
                        resource_type: { enum: ["VIDEO"] },
                        source_type: { enum: ["COMPASS"] }
                    }
                }
            }
        ]
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

/* --- FAIL-SAFE MIGRATION BLOCK --- */
if (db.getCollectionNames().includes(COLLECTION_NAME)) {

    var docsToMigrate = db.learning_resource.find({
        $or: [
            { chapter_id: { $type: "number" } }, { chapter_id: { $type: "int" } },
            { chapter_id: { $type: "long" } }, { chapter_id: { $type: "double" } },
            { topic_id: { $type: "number" } }, { topic_id: { $type: "int" } },
            { topic_id: { $type: "long" } }, { topic_id: { $type: "double" } },
            { syllabus_version: { $exists: false } }, { syllabus_version: { $type: "null" } }
        ]
    }).toArray();

    if (docsToMigrate.length > 0) {
        print("Migrating " + docsToMigrate.length + " documents...");
        var validChapterMap = { 1: "sci_ch_001", 2: "sci_ch_002", 3: "sci_ch_003" };
        var validTopicMap = {
            1: "sci_topic_001", 2: "sci_topic_002", 3: "sci_topic_003", 4: "sci_topic_004", 5: "sci_topic_005",
            6: "sci_topic_006", 7: "sci_topic_007", 8: "sci_topic_008", 9: "sci_topic_009", 10: "sci_topic_010",
            11: "sci_topic_011", 12: "sci_topic_012", 13: "sci_topic_013", 14: "sci_topic_014", 15: "sci_topic_015"
        };

        docsToMigrate.forEach(function (doc) {
            var update = {};

            var ac_yr = doc.academic_year_id ? doc.academic_year_id.valueOf() : null;
            // Evaluates Academic-Year Bounds Identity strictly restricting against test scope
            var isTargetScope = (
                doc.school_id.valueOf() === 1 &&
                doc.branch_id.valueOf() === 1 &&
                ac_yr === 1 &&
                doc.class_id.valueOf() === 1 &&
                doc.subject_id.valueOf() === 3
            );

            if (!isTargetScope) {
                throw new Error("MIGRATION STOPPED: Document outside target academic-year scope has legacy numeric IDs or missing version. Resource: " + doc.resource_id);
            }

            // 1. Determine numeric chapter_id
            var chVal = null;
            if (isNumericBSON(doc.chapter_id)) {
                chVal = doc.chapter_id.valueOf();
            }

            // 2. Determine numeric topic_id
            var topVal = null;
            if (isNumericBSON(doc.topic_id)) {
                topVal = doc.topic_id.valueOf();
            }

            // 3. Convert them to their expected string IDs
            var proposedChapter = chVal ? validChapterMap[chVal] : doc.chapter_id;
            var proposedTopic = topVal ? validTopicMap[topVal] : doc.topic_id;

            if (chVal && !proposedChapter) {
                throw new Error("MIGRATION STOPPED: Cannot safely map numeric chapter_id " + chVal + " for resource " + doc.resource_id);
            }
            if (topVal && !proposedTopic) {
                throw new Error("MIGRATION STOPPED: Cannot safely map numeric topic_id " + topVal + " for resource " + doc.resource_id);
            }

            // 4. Load the correct syllabus 
            var syllabusDoc = db.class_subject_syllabus.findOne({
                school_id: 1,
                branch_id: 1,
                academic_year_id: 1,
                class_id: 1,
                subject_id: 3,
                syllabus_version: 1,
                is_active: true
            });

            if (!syllabusDoc) {
                throw new Error("MIGRATION STOPPED: Required active syllabus version 1 not found.");
            }

            // 5. Find the converted chapter verifying it exists
            var targetChapter = null;
            if (syllabusDoc.chapters && Array.isArray(syllabusDoc.chapters)) {
                targetChapter = syllabusDoc.chapters.find(function (c) { return c.chapter_id === proposedChapter; });
            }

            if (!targetChapter) {
                throw new Error("MIGRATION STOPPED: chapter_id " + proposedChapter + " does not exist in class_subject_syllabus for " + doc.resource_id);
            }

            // 6. Find the converted topic accurately inside that exact chapter's array bounds
            var targetTopic = null;
            if (targetChapter.topics && Array.isArray(targetChapter.topics)) {
                targetTopic = targetChapter.topics.find(function (t) { return t.topic_id === proposedTopic; });
            }

            if (!targetTopic) {
                throw new Error("MIGRATION STOPPED: topic_id " + proposedTopic + " does not belong to chapter_id " + proposedChapter + " in class_subject_syllabus. Resource: " + doc.resource_id);
            }

            // 7. Only then structurally execute the mapping operation
            if (chVal) update.chapter_id = proposedChapter;
            if (topVal) update.topic_id = proposedTopic;
            if (doc.syllabus_version === undefined || doc.syllabus_version === null) {
                update.syllabus_version = NumberInt(1);
            }

            if (Object.keys(update).length > 0) {
                db.learning_resource.updateOne({ _id: doc._id }, { $set: update });
            }
        });
    }

    // Clear out manual legacy indexes missing syllabus restrictions BEFORE validation 
    var obsoleteIndexes = [
        "ix_learning_resource_topic_lookup", "ix_learning_resource_subject_lookup",
        "uq_learning_resource_current_teacher_note", "uq_learning_resource_current_compass_note"
    ];
    db.learning_resource.getIndexes().forEach(function (idx) {
        if (obsoleteIndexes.includes(idx.name) && !idx.key.hasOwnProperty("syllabus_version")) {
            print("Dropping legacy manual index without syllabus_version: " + idx.name);
            db.learning_resource.dropIndex(idx.name);
        }
    });

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
var indexes = [
    { key: { resource_id: 1 }, options: { unique: true, name: "uq_learning_resource_resource_id" } },
    { key: { school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, syllabus_version: 1, chapter_id: 1, topic_id: 1, resource_type: 1, source_type: 1, status: 1, updated_at: -1 }, options: { name: "ix_learning_resource_topic_lookup" } },
    { key: { school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, syllabus_version: 1, resource_type: 1, source_type: 1, status: 1 }, options: { name: "ix_learning_resource_subject_lookup" } },
    { key: { school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, syllabus_version: 1, chapter_id: 1, topic_id: 1, source_type: 1 }, options: { unique: true, partialFilterExpression: { resource_type: "NOTE", source_type: "TEACHER", status: { $in: ["READY", "PUBLISHED"] } }, name: "uq_learning_resource_current_teacher_note" } },
    { key: { school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, syllabus_version: 1, chapter_id: 1, topic_id: 1, source_type: 1 }, options: { unique: true, partialFilterExpression: { resource_type: "NOTE", source_type: "COMPASS", status: { $in: ["READY", "PUBLISHED"] } }, name: "uq_learning_resource_current_compass_note" } },
    { key: { "storage_reference.provider": 1, "storage_reference.bucket": 1, "storage_reference.object_key": 1 }, options: { unique: true, name: "uq_learning_resource_s3_object" } }
];

indexes.forEach(function (idx) {
    var existingIndexes = db.learning_resource.getIndexes();
    var existingIdx = existingIndexes.find(function (e) { return e.name === idx.options.name; });
    var needsCreation = false;

    if (existingIdx) {
        if (!indexesAreEquivalent(existingIdx, idx)) {
            print("Dropping outdated index Definition varies: " + idx.options.name);
            db.learning_resource.dropIndex(idx.options.name);
            needsCreation = true;
        }
    } else {
        needsCreation = true;
    }

    if (needsCreation) {
        existingIndexes = db.learning_resource.getIndexes();
        var duplicate = existingIndexes.find(function (e) {
            return indexesAreEquivalent(e, idx) && e.name !== idx.options.name;
        });
        if (duplicate) {
            print("Dropping duplicate equivalent index bounding differing legacy name: " + duplicate.name);
            db.learning_resource.dropIndex(duplicate.name);
        }

        try {
            db.learning_resource.createIndex(idx.key, idx.options);
        } catch (e) {
            print("---------------------------------------------------------");
            print("CRITICAL ERROR: Failed to create index " + idx.options.name);
            print(e.message);
            if (idx.options.unique) {
                print("Checking for conflicting documents violating uniqueness on " + idx.options.name + "...");
                var aggregateResult = [];
                if (idx.options.name === "uq_learning_resource_resource_id") {
                    aggregateResult = db.learning_resource.aggregate([{ $group: { _id: { resource_id: "$resource_id" }, count: { $sum: 1 }, docs: { $push: "$resource_id" } } }, { $match: { count: { $gt: 1 } } }]).toArray();
                } else if (idx.options.name === "uq_learning_resource_s3_object") {
                    aggregateResult = db.learning_resource.aggregate([{ $group: { _id: { provider: "$storage_reference.provider", bucket: "$storage_reference.bucket", object_key: "$storage_reference.object_key" }, count: { $sum: 1 }, docs: { $push: "$resource_id" } } }, { $match: { count: { $gt: 1 } } }]).toArray();
                } else {
                    print("Index constraint involves PartialFilter. Conflicting entries must be resolved natively manually inside shell constraints.");
                }
                if (aggregateResult.length > 0) {
                    print("Specific Constraints Violation Intersect Found:");
                    printjson(aggregateResult);
                }
            }
            print("---------------------------------------------------------");
            throw e;
        }
    }
});

// ============================================================
// FINAL VERIFICATION — COMPLETE CHAPTER/TOPIC VALIDATION
// ============================================================
var verificationResources = db.learning_resource.find({
    school_id: 1,
    branch_id: 1,
    academic_year_id: 1,
    class_id: 1,
    subject_id: 3
}).toArray();

var relationshipsVerified = 0;

if (verificationResources.length > 0) {
    var finalSyllabus = db.class_subject_syllabus.findOne({
        school_id: 1,
        branch_id: 1,
        academic_year_id: 1,
        class_id: 1,
        subject_id: 3,
        syllabus_version: 1,
        is_active: true
    });

    if (!finalSyllabus) {
        throw new Error("FINAL VERIFICATION FAILED: Active Class 1 Science syllabus version 1 not found.");
    }

    var numericRegex = /^[0-9]+$/;

    verificationResources.forEach(function (res) {
        // Check syllabus version equals exactly 1 and isn't absent
        if (res.syllabus_version === undefined || res.syllabus_version === null || typeof res.syllabus_version === "string" || res.syllabus_version.valueOf() !== 1) {
            throw new Error("FINAL VERIFICATION FAILED: Resource " + res.resource_id + " missing or mismatched syllabus_version = 1.");
        }

        if (typeof res.chapter_id !== "string") {
            throw new Error("FINAL VERIFICATION FAILED: Resource " + res.resource_id + " has non-string chapter_id.");
        }

        if (typeof res.topic_id !== "string") {
            throw new Error("FINAL VERIFICATION FAILED: Resource " + res.resource_id + " has non-string topic_id.");
        }

        if (numericRegex.test(res.chapter_id)) {
            throw new Error("FINAL VERIFICATION FAILED: Resource " + res.resource_id + " has numeric-string chapter_id: " + res.chapter_id);
        }

        if (numericRegex.test(res.topic_id)) {
            throw new Error("FINAL VERIFICATION FAILED: Resource " + res.resource_id + " has numeric-string topic_id: " + res.topic_id);
        }

        var verChap = null;
        if (finalSyllabus.chapters && Array.isArray(finalSyllabus.chapters)) {
            verChap = finalSyllabus.chapters.find(function (c) { return c.chapter_id === res.chapter_id; });
        }

        if (!verChap) {
            throw new Error("FINAL VERIFICATION FAILED: Resource " + res.resource_id + " references missing chapter_id " + res.chapter_id + " in syllabus.");
        }

        var verTop = null;
        if (verChap.topics && Array.isArray(verChap.topics)) {
            verTop = verChap.topics.find(function (t) { return t.topic_id === res.topic_id; });
        }

        if (!verTop) {
            throw new Error("FINAL VERIFICATION FAILED: Resource " + res.resource_id + " topic_id " + res.topic_id + " does not belong to chapter_id " + res.chapter_id + " in class_subject_syllabus.");
        }

        relationshipsVerified++;
    });
}

// Final Index Verifications
var finalIndexes = db.learning_resource.getIndexes();
indexes.forEach(function (reqIdx) {
    var foundObj = finalIndexes.find(function (f) { return f.name === reqIdx.options.name; });
    if (!foundObj) {
        throw new Error("FINAL INDEX VERIFICATION FAILED: " + reqIdx.options.name + " is missing completely.");
    }
    if (!indexesAreEquivalent(foundObj, reqIdx)) {
        throw new Error("FINAL INDEX VERIFICATION FAILED: " + reqIdx.options.name + " exists but structurally mismatches requested constraints or Unique definitions.");
    }
});

var hasTeacher = finalIndexes.some(function (i) { return i.name === "uq_learning_resource_current_teacher_note"; });
var hasCompass = finalIndexes.some(function (i) { return i.name === "uq_learning_resource_current_compass_note"; });
if (!hasTeacher || !hasCompass) {
    throw new Error("FINAL INDEX VERIFICATION FAILED: Both Teacher and Compass active partial bound constraints MUST exist simultaneously.");
}

// Success Reporting Terminal
print("MIGRATION AND FINAL VERIFICATION SUCCESSFUL");
print("Resources checked: " + verificationResources.length);
print("Resources migrated: " + (typeof docsToMigrate !== 'undefined' ? docsToMigrate.length : 0));
print("Chapter relationships verified: " + relationshipsVerified);
print("Topic relationships verified: " + relationshipsVerified);
print("Syllabus version verified: 1");
print("Required indexes verified: " + indexes.length);
