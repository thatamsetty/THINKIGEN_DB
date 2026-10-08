/*
    Collection: connect_conversation
    Purpose:    Conversation master for 1:1 and group communication.
                No message bodies or chat events are stored here.
*/

var COLLECTION_NAME = "connect_conversation";

var validator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "conversation_id",
            "school_id",
            "branch_id",
            "conversation_type",
            "title",
            "participants",
            "is_active",
            "created_at",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: { bsonType: ["objectId", "string"] },
            conversation_id: { bsonType: "string", minLength: 1, maxLength: 80 },
            school_id: { bsonType: ["int", "long"], minimum: 1 },
            branch_id: { bsonType: ["int", "long"], minimum: 1 },
            conversation_type: { bsonType: "string", enum: ["one_to_one", "group"] },
            participant_pair_key: { bsonType: ["string", "null"], maxLength: 80 },
            title: { bsonType: "string", minLength: 1, maxLength: 200 },
            header_context: { bsonType: ["string", "null"], maxLength: 300 },
            academic_year_id: { bsonType: ["int", "long", "null"], minimum: 1 },
            class_id: { bsonType: ["int", "long", "null"], minimum: 1 },
            section_id: { bsonType: ["int", "long", "null"], minimum: 1 },
            subject_id: { bsonType: ["int", "long", "null"], minimum: 1 },
            group_type: { bsonType: ["string", "null"], enum: ["class_group", "section_group", "committee", "club", "society", null] },
            participants: {
                bsonType: "array",
                minItems: 2,
                items: {
                    bsonType: "object",
                    required: ["user_id", "participant_role"],
                    additionalProperties: false,
                    properties: {
                        user_id: { bsonType: ["int", "long"], minimum: 1 },
                        participant_role: {
                            bsonType: "string",
                            enum: ["student", "teacher", "staff", "admin", "faculty", "member", "moderator", "parent"]
                        },
                        display_name: { bsonType: ["string", "null"], maxLength: 200 }
                    }
                }
            },
            last_message_preview: { bsonType: ["string", "null"], maxLength: 500 },
            last_message_at: { bsonType: ["date", "null"] },
            last_message_sender_user_id: { bsonType: ["int", "long", "null"], minimum: 1 },
            is_active: { bsonType: "bool" },
            created_at: { bsonType: "date" },
            updated_at: { bsonType: "date" },
            created_by: { bsonType: ["int", "long", "null"], minimum: 1 },
            updated_by: { bsonType: ["int", "long", "null"], minimum: 1 }
        },
        anyOf: [
            {
                properties: {
                    conversation_type: { enum: ["one_to_one"] },
                    participant_pair_key: { bsonType: "string", minLength: 1 },
                    participants: { bsonType: "array", minItems: 2, maxItems: 2 }
                },
                required: ["participant_pair_key"]
            },
            {
                properties: {
                    conversation_type: { enum: ["group"] },
                    participant_pair_key: { bsonType: "null" },
                    participants: { bsonType: "array", minItems: 2 }
                }
            }
        ]
    }
};

function indexesAreEquivalent(existingIdx, desiredIdx) {
    var eFilter = existingIdx.partialFilterExpression ? JSON.stringify(existingIdx.partialFilterExpression) : null;
    var dFilter = desiredIdx.options.partialFilterExpression ? JSON.stringify(desiredIdx.options.partialFilterExpression) : null;
    return JSON.stringify(existingIdx.key) === JSON.stringify(desiredIdx.key) &&
        (existingIdx.unique === true) === (desiredIdx.options.unique === true) &&
        eFilter === dFilter;
}

print("============================================================");
print("STARTING MIGRATION FOR " + COLLECTION_NAME);
print("============================================================");

if (db.getCollectionNames().includes(COLLECTION_NAME)) {
    var existingDocs = db[COLLECTION_NAME].find({}).toArray();
    var pairKeys = {};

    print("Validating " + existingDocs.length + " existing documents...");

    existingDocs.forEach(function (doc) {
        var cId = doc.conversation_id;

        if (doc.conversation_type === "one_to_one") {
            if (!doc.participant_pair_key || typeof doc.participant_pair_key !== "string") {
                throw new Error("MIGRATION STOPPED: conversation_type is 'one_to_one' but participant_pair_key is missing or not a string. Conversation: " + cId);
            }
            if (!Array.isArray(doc.participants) || doc.participants.length !== 2) {
                throw new Error("MIGRATION STOPPED: 'one_to_one' conversation must have exactly 2 participants. Conversation: " + cId);
            }

            var p1 = doc.participants[0].user_id.valueOf();
            var p2 = doc.participants[1].user_id.valueOf();
            var sortedPair = [Number(p1), Number(p2)].sort(function (a, b) { return a - b; });
            var expectedKey = sortedPair[0] + ":" + sortedPair[1];
            if (doc.participant_pair_key !== expectedKey) {
                throw new Error("MIGRATION STOPPED: participant_pair_key mismatch. Expected '" + expectedKey + "', found '" + doc.participant_pair_key + "'. Conversation: " + cId);
            }

            if (pairKeys[doc.participant_pair_key]) {
                throw new Error("MIGRATION STOPPED: Duplicate participant_pair_key found: '" + doc.participant_pair_key + "'. Conversation: " + cId);
            }
            pairKeys[doc.participant_pair_key] = true;
        } else if (doc.conversation_type === "group") {
            if (doc.participant_pair_key !== null && doc.participant_pair_key !== undefined) {
                throw new Error("MIGRATION STOPPED: 'group' conversation must have a null or absent participant_pair_key. Conversation: " + cId);
            }
            if (doc.participant_pair_key === undefined) {
                doc.participant_pair_key = null;
                db[COLLECTION_NAME].updateOne({ _id: doc._id }, { $set: { participant_pair_key: null } });
            }
        }
    });

    db.runCommand({
        collMod: COLLECTION_NAME,
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Validator updated successfully.");
} else {
    db.createCollection(COLLECTION_NAME, {
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Collection " + COLLECTION_NAME + " created successfully.");
}

var indexes = [
    {
        key: { conversation_id: 1 },
        options: { unique: true, name: "uq_connect_conversation_id" }
    },
    {
        key: { participant_pair_key: 1 },
        options: {
            unique: true,
            partialFilterExpression: { conversation_type: "one_to_one" },
            name: "uq_connect_conversation_pair_key"
        }
    },
    {
        key: { school_id: 1, "participants.user_id": 1, updated_at: -1 },
        options: { name: "ix_connect_conversation_participant" }
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
        db[COLLECTION_NAME].createIndex(idx.key, idx.options);
        print("Created index: " + idx.options.name);
    }
});

// Final Verification
var verificationPass = true;

print("\n------------------------------------------------------------");
print("FINAL VERIFICATION: connect_conversation");
print("------------------------------------------------------------");

var infos = db.getCollectionInfos({ name: COLLECTION_NAME })[0];
var hasOptVal = infos && infos.options && infos.options.validator;
if (hasOptVal && infos.options.validationLevel === "strict" && infos.options.validationAction === "error") {
    print("    [PASS] validator");
} else {
    print("    [FAIL] validator");
    verificationPass = false;
}

var schema = hasOptVal ? infos.options.validator.$jsonSchema : null;
if (schema && Array.isArray(schema.required) && schema.required.includes("conversation_id")) {
    print("    [PASS] required fields");
} else {
    print("    [FAIL] required fields");
    verificationPass = false;
}

var hasOneToOne = false;
var hasGroup = false;
if (schema && schema.anyOf) {
    schema.anyOf.forEach(function (cond) {
        if (cond.properties && cond.properties.conversation_type && cond.properties.conversation_type.enum.includes("one_to_one")) hasOneToOne = true;
        if (cond.properties && cond.properties.conversation_type && cond.properties.conversation_type.enum.includes("group")) hasGroup = true;
    });
}
if (hasOneToOne) {
    print("    [PASS] one-to-one validation");
} else {
    print("    [FAIL] one-to-one validation");
    verificationPass = false;
}
if (hasGroup) {
    print("    [PASS] group validation");
} else {
    print("    [FAIL] group validation");
    verificationPass = false;
}

var finalIndexes = db[COLLECTION_NAME].getIndexes();
var foundUqId = finalIndexes.find(function (f) { return f.name === "uq_connect_conversation_id" && f.unique === true; });
if (foundUqId) {
    print("    [PASS] unique conversation_id index");
} else {
    print("    [FAIL] unique conversation_id index");
    verificationPass = false;
}

var foundUqPair = finalIndexes.find(function (f) { return f.name === "uq_connect_conversation_pair_key" && f.unique === true; });
if (foundUqPair) {
    print("    [PASS] unique pair-key index");
} else {
    print("    [FAIL] unique pair-key index");
    verificationPass = false;
}

var foundPartIdx = finalIndexes.find(function (f) { return f.name === "ix_connect_conversation_participant"; });
if (foundPartIdx) {
    print("    [PASS] participant index");
} else {
    print("    [FAIL] participant index");
    verificationPass = false;
}

var hasMessageFields = false;
var disallowed = ["messages", "message_history", "chat_messages", "message_events", "parquet_rows"];
if (schema && schema.properties) {
    disallowed.forEach(function (f) {
        if (schema.properties[f]) hasMessageFields = true;
    });
}
if (!hasMessageFields) {
    print("    [PASS] no message-history fields");
} else {
    print("    [FAIL] no message-history fields");
    verificationPass = false;
}

if (!verificationPass) {
    throw new Error("MIGRATION FAILED: connect_conversation verification did not pass all checks.");
}
print("============================================================");
