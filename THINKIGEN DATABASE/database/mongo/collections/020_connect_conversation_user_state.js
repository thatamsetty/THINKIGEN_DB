/*
    Collection: connect_conversation_user_state
    Purpose:    Per-user visibility/state for messages in a shared conversation.
                This collection stores state that cannot live at conversation level
                because deletion visibility and read status are user-specific.

    Core logic:
    - conversation_id + user_id => one document per user per conversation
    - deleted_at is ONLY a historical boundary for the user; does not destroy Parquet history
    - last_read_at tracks the user's last read state for the conversation
*/

var COLLECTION_NAME = "connect_conversation_user_state";

var validator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "conversation_id",
            "user_id",
            "deleted_at",
            "last_read_at",
            "created_at",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: { bsonType: ["objectId", "string"] },
            conversation_id: { bsonType: "string", minLength: 1, maxLength: 80 },
            user_id: { bsonType: ["int", "long"], minimum: 1 },
            deleted_at: { bsonType: ["date", "null"] },
            last_read_at: { bsonType: ["date", "null"] },
            created_at: { bsonType: "date" },
            updated_at: { bsonType: "date" }
        }
    }
};

print("============================================================");
print("STARTING MIGRATION FOR " + COLLECTION_NAME);
print("============================================================");

if (db.getCollectionNames().includes(COLLECTION_NAME)) {
    var existingDocs = db[COLLECTION_NAME].find({}).toArray();
    print("Validating " + existingDocs.length + " existing documents...");

    existingDocs.forEach(function (doc) {
        var cId = doc.conversation_id;
        var uId = doc.user_id;

        var conversation = db.connect_conversation.findOne({ conversation_id: cId });
        if (!conversation) {
            throw new Error("MIGRATION STOPPED: user_state found for conversation_id '" + cId + "', but this conversation does NOT exist in connect_conversation. State ID: " + doc._id);
        }

        var participantExists = false;
        if (conversation.participants && Array.isArray(conversation.participants)) {
            for (var i = 0; i < conversation.participants.length; i++) {
                if (conversation.participants[i].user_id.valueOf() === uId.valueOf()) {
                    participantExists = true;
                    break;
                }
            }
        }

        if (!participantExists) {
            throw new Error("MIGRATION STOPPED: user_id " + uId + " has a state document for conversation " + cId + " but is NOT listed as a participant in that conversation. State ID: " + doc._id);
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

function indexesAreEquivalent(existingIdx, desiredIdx) {
    var eFilter = existingIdx.partialFilterExpression ? JSON.stringify(existingIdx.partialFilterExpression) : null;
    var dFilter = desiredIdx.options.partialFilterExpression ? JSON.stringify(desiredIdx.options.partialFilterExpression) : null;
    return JSON.stringify(existingIdx.key) === JSON.stringify(desiredIdx.key) &&
        (existingIdx.unique === true) === (desiredIdx.options.unique === true) &&
        eFilter === dFilter;
}

var indexes = [
    {
        key: { conversation_id: 1, user_id: 1 },
        options: { unique: true, name: "uq_connect_conversation_user_state" }
    },
    {
        key: { user_id: 1, deleted_at: 1, last_read_at: -1 },
        options: { name: "ix_connect_conversation_user_state_user_deleted" }
    },
    {
        key: { conversation_id: 1, updated_at: -1 },
        options: { name: "ix_connect_conversation_user_state_conversation" }
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
print("FINAL VERIFICATION: connect_conversation_user_state");
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
if (schema && Array.isArray(schema.required) && schema.required.includes("conversation_id") && schema.required.includes("user_id")) {
    print("    [PASS] required fields");
} else {
    print("    [FAIL] required fields");
    verificationPass = false;
}

var finalIndexes = db[COLLECTION_NAME].getIndexes();
var uniqueIdx = finalIndexes.find(function (f) { return f.name === "uq_connect_conversation_user_state"; });
if (uniqueIdx && uniqueIdx.unique) {
    print("    [PASS] unique conversation/user index");
} else {
    print("    [FAIL] unique conversation/user index");
    verificationPass = false;
}

var userDelIdx = finalIndexes.find(function (f) { return f.name === "ix_connect_conversation_user_state_user_deleted"; });
if (userDelIdx) {
    print("    [PASS] user/deleted index");
} else {
    print("    [FAIL] user/deleted index");
    verificationPass = false;
}

var convIdx = finalIndexes.find(function (f) { return f.name === "ix_connect_conversation_user_state_conversation"; });
if (convIdx) {
    print("    [PASS] conversation index");
} else {
    print("    [FAIL] conversation index");
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

var relationPass = true;
db[COLLECTION_NAME].find({}).forEach(function (doc) {
    var conversation = db.connect_conversation.findOne({ conversation_id: doc.conversation_id });
    if (!conversation) {
        relationPass = false;
    } else {
        var isParticipant = false;
        if (conversation.participants) {
            for (var i = 0; i < conversation.participants.length; i++) {
                if (conversation.participants[i].user_id.valueOf() === doc.user_id.valueOf()) {
                    isParticipant = true;
                    break;
                }
            }
        }
        if (!isParticipant) relationPass = false;
    }
});

if (relationPass) {
    print("    [PASS] relationship validation logic");
} else {
    print("    [FAIL] relationship validation logic");
    verificationPass = false;
}

if (!verificationPass) {
    throw new Error("MIGRATION FAILED: connect_conversation_user_state verification did not pass all checks.");
}
print("============================================================");
