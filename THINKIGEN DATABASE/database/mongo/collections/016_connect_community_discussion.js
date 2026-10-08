/*
    Collection: connect_community_discussion
    Module:     School ERP -> Connect -> Community -> Discussions
    Purpose:    Community discussion thread master (ONE document = ONE discussion thread)

    Production Rules:
    - Authoritative discussion threads reside here.
    - Authoritative replies reside in connect_community_discussion_reply.
    - Mutable author information (author_name, author_role) is excluded.
    - Flat design: no replies array or nested comment arrays.
    - is_trending is a denormalized/derived boolean flag for fast UI filtering.
    - Enforces integer/long IDs >= 1.
    - Meaningful text required with pattern: "\\S".
*/

var discussionValidator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "discussion_id",
            "community_id",
            "school_id",
            "title",
            "author_user_id",
            "is_trending",
            "is_active",
            "created_at",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: {
                bsonType: "objectId"
            },
            discussion_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Unique discussion thread identifier; must be an integer >= 1"
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
            title: {
                bsonType: "string",
                minLength: 1,
                maxLength: 300,
                pattern: "\\S",
                description: "Discussion topic title; must contain non-whitespace characters (1-300 chars)"
            },
            description: {
                bsonType: ["string", "null"],
                maxLength: 4000,
                pattern: "\\S",
                description: "Optional detailed thread context/agenda (max 4,000 chars, non-whitespace if string)"
            },
            author_user_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Reference to security_schema.users(user_id); must be >= 1"
            },
            is_trending: {
                bsonType: "bool",
                description: "Derived flag indicating trending status for rapid feed filtering"
            },
            is_active: {
                bsonType: "bool",
                description: "Soft deletion indicator"
            },
            created_at: {
                bsonType: "date",
                description: "BSON UTC date when thread was opened"
            },
            updated_at: {
                bsonType: ["date", "null"],
                description: "BSON UTC date when thread was edited; null on initial creation"
            }
        }
    }
};

// 1. Create collection with validator or apply collMod if collection already exists
if (!db.getCollectionNames().includes("connect_community_discussion")) {
    db.createCollection("connect_community_discussion", {
        validator: discussionValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Created collection: connect_community_discussion with strict schema validation.");
} else {
    db.runCommand({
        collMod: "connect_community_discussion",
        validator: discussionValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Updated validator on existing collection: connect_community_discussion.");
}

// 2. Index Management: Clean legacy indexes if present
var existingDiscussionIndexes = db.connect_community_discussion.getIndexes();

if (existingDiscussionIndexes.some(function (idx) { return idx.name === "discussion_id_1"; })) {
    db.connect_community_discussion.dropIndex("discussion_id_1");
    print("Dropped legacy unnamed index: discussion_id_1");
}

if (existingDiscussionIndexes.some(function (idx) { return idx.name === "community_id_1_created_at_-1"; })) {
    db.connect_community_discussion.dropIndex("community_id_1_created_at_-1");
    print("Dropped legacy unnamed index: community_id_1_created_at_-1");
}

// Refresh index list after cleanups
existingDiscussionIndexes = db.connect_community_discussion.getIndexes();

// 3. Create named indexes
if (!existingDiscussionIndexes.some(function (idx) { return idx.name === "uq_connect_community_discussion_id"; })) {
    db.connect_community_discussion.createIndex(
        { discussion_id: 1 },
        { unique: true, name: "uq_connect_community_discussion_id" }
    );
    print("Created unique index: uq_connect_community_discussion_id");
}

if (!existingDiscussionIndexes.some(function (idx) { return idx.name === "ix_connect_community_discussion_feed"; })) {
    db.connect_community_discussion.createIndex(
        { community_id: 1, created_at: -1 },
        { name: "ix_connect_community_discussion_feed" }
    );
    print("Created compound index: ix_connect_community_discussion_feed");
}
