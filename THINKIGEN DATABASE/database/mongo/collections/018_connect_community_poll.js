/*
    Collection: connect_community_poll
    Module:     School ERP -> Connect -> Community -> Polls
    Purpose:    Community poll master with embedded options & denormalized counters
                (ONE document = ONE poll)

    Production Rules:
    - Authoritative poll metadata & options reside here.
    - Options remain embedded (tight lifecycle with poll; no independent collection).
    - Authoritative user votes reside in connect_community_poll_vote.
    - vote_count and total_votes are fast-read denormalized counters updated atomically upon vote.
    - selectedOptionId is user-specific state and is NEVER stored here (derived from vote collection).
    - Mutable author information (author_name, author_role) is excluded; references user_id only.
    - updated_at is null upon creation and populated on edits.
    - Strict $jsonSchema validation with validationLevel: "strict" and validationAction: "error".
    - Safe idempotent migration supporting initial creation and schema modification (collMod).
*/

var pollValidator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "poll_id",
            "community_id",
            "school_id",
            "question",
            "options",
            "total_votes",
            "is_active",
            "created_at",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: {
                bsonType: "objectId"
            },
            poll_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Unique poll identifier; must be an integer >= 1"
            },
            community_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Reference to connect_community.community_id; must be >= 1"
            },
            school_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Multi-tenant institutional boundary; must be >= 1"
            },
            question: {
                bsonType: "string",
                minLength: 1,
                maxLength: 500,
                pattern: "\\S",
                description: "Poll question text; must contain non-whitespace characters (1-500 chars)"
            },
            options: {
                bsonType: "array",
                minItems: 2,
                description: "List of poll choices (minimum 2 options required)",
                items: {
                    bsonType: "object",
                    required: [
                        "option_id",
                        "label",
                        "vote_count"
                    ],
                    additionalProperties: false,
                    properties: {
                        option_id: {
                            bsonType: ["int", "long"],
                            minimum: 1,
                            description: "Option identifier unique within the poll (integer >= 1)"
                        },
                        label: {
                            bsonType: "string",
                            minLength: 1,
                            maxLength: 300,
                            pattern: "\\S",
                            description: "Option choice label; must contain non-whitespace characters (1-300 chars)"
                        },
                        vote_count: {
                            bsonType: "int",
                            minimum: 0,
                            description: "Denormalized tally of votes cast for this option; must be >= 0"
                        }
                    }
                }
            },
            total_votes: {
                bsonType: "int",
                minimum: 0,
                description: "Denormalized aggregate vote counter across all options; must be >= 0"
            },
            expires_at: {
                bsonType: ["date", "null"],
                description: "Optional poll expiration timestamp; null means no expiration"
            },
            is_active: {
                bsonType: "bool",
                description: "Poll active status flag for manual closure or soft deactivation"
            },
            created_at: {
                bsonType: "date",
                description: "BSON UTC timestamp when the poll was created"
            },
            updated_at: {
                bsonType: ["date", "null"],
                description: "BSON UTC timestamp when the poll was last edited; null upon creation"
            },
            created_by: {
                oneOf: [
                    { bsonType: "null" },
                    { bsonType: ["int", "long"], minimum: 1 }
                ],
                description: "Optional author reference to security_schema.users(user_id); integer >= 1 or null"
            }
        }
    }
};

// 1. Create collection with validator or apply collMod if collection already exists
if (!db.getCollectionNames().includes("connect_community_poll")) {
    db.createCollection("connect_community_poll", {
        validator: pollValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Created collection: connect_community_poll with strict schema validation.");
} else {
    db.runCommand({
        collMod: "connect_community_poll",
        validator: pollValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Updated validator on existing collection: connect_community_poll.");
}

// 2. Index Management: Clean legacy indexes if present
var existingPollIndexes = db.connect_community_poll.getIndexes();

if (existingPollIndexes.some(function (idx) { return idx.name === "poll_id_1"; })) {
    db.connect_community_poll.dropIndex("poll_id_1");
    print("Dropped legacy unnamed index: poll_id_1");
}

if (existingPollIndexes.some(function (idx) { return idx.name === "community_id_1_created_at_-1"; })) {
    db.connect_community_poll.dropIndex("community_id_1_created_at_-1");
    print("Dropped legacy unnamed index: community_id_1_created_at_-1");
}

// Refresh index list after cleanups
existingPollIndexes = db.connect_community_poll.getIndexes();

// 3. Create named indexes
if (!existingPollIndexes.some(function (idx) { return idx.name === "uq_connect_community_poll_id"; })) {
    db.connect_community_poll.createIndex(
        { poll_id: 1 },
        { unique: true, name: "uq_connect_community_poll_id" }
    );
    print("Created unique index: uq_connect_community_poll_id");
}

if (!existingPollIndexes.some(function (idx) { return idx.name === "ix_connect_community_poll_feed"; })) {
    db.connect_community_poll.createIndex(
        { community_id: 1, created_at: -1 },
        { name: "ix_connect_community_poll_feed" }
    );
    print("Created compound index: ix_connect_community_poll_feed");
}
