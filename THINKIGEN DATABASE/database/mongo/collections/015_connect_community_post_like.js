/*
    Collection: connect_community_post_like
    Module:     School ERP -> Connect -> Community -> Feed
    Purpose:    Authoritative record of likes (ONE document = ONE user's like on ONE post)

    Production Rules:
    - Exactly ONE like per user per post enforced via unique compound index (post_id, user_id).
    - Lightweight document: post_id, user_id, school_id, created_at.
    - No redundant community_id, like_id, user_name, or user_role.
    - Authoritative source for like status; post.like_count is a denormalized counter.
*/

var likeValidator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "post_id",
            "user_id",
            "school_id",
            "created_at"
        ],
        additionalProperties: false,
        properties: {
            _id: {
                bsonType: "objectId"
            },
            post_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Reference to connect_community_post.post_id; must be >= 1"
            },
            user_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Reference to security_schema.users(user_id); must be >= 1"
            },
            school_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Multi-tenant institutional boundary; must be >= 1"
            },
            created_at: {
                bsonType: "date",
                description: "BSON UTC date when like action was executed"
            }
        }
    }
};

// 1. Create collection with validator or apply collMod if collection already exists
if (!db.getCollectionNames().includes("connect_community_post_like")) {
    db.createCollection("connect_community_post_like", {
        validator: likeValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Created collection: connect_community_post_like with strict schema validation.");
} else {
    db.runCommand({
        collMod: "connect_community_post_like",
        validator: likeValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Updated validator on existing collection: connect_community_post_like.");
}

// 2. Index Management: Clean legacy unnamed index if present
var existingLikeIndexes = db.connect_community_post_like.getIndexes();

if (existingLikeIndexes.some(function (idx) { return idx.name === "post_id_1_user_id_1"; })) {
    db.connect_community_post_like.dropIndex("post_id_1_user_id_1");
    print("Dropped legacy unnamed index: post_id_1_user_id_1");
}

// Refresh index list after cleanup
existingLikeIndexes = db.connect_community_post_like.getIndexes();

// 3. Create unique compound index (post_id, user_id)
if (!existingLikeIndexes.some(function (idx) { return idx.name === "uq_connect_community_post_like"; })) {
    db.connect_community_post_like.createIndex(
        { post_id: 1, user_id: 1 },
        { unique: true, name: "uq_connect_community_post_like" }
    );
    print("Created unique index: uq_connect_community_post_like");
}
