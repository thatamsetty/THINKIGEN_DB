/*
    Collection: connect_community
    Purpose:    Connect → Community master (club / society / group)

    Stored:
    - name, type, description, owner, member_count, trending flag

    Not stored:
    - posts / comments / likes / polls (child collections)
    - trending id list (computed or Redis cache)
*/

var communityValidator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "community_id",
            "school_id",
            "branch_id",
            "name",
            "community_type",
            "owner_user_id",
            "member_count",
            "is_active",
            "created_at",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: { bsonType: "objectId" },
            community_id: { bsonType: ["int", "long"], minimum: 1 },
            school_id: { bsonType: ["int", "long"], minimum: 1 },
            branch_id: { bsonType: ["int", "long"], minimum: 1 },
            name: { bsonType: "string", minLength: 1, maxLength: 200, pattern: "\\S" },
            community_type: {
                bsonType: "string",
                enum: ["club", "society", "group"]
            },
            description: { bsonType: ["string", "null"], maxLength: 2000, pattern: "\\S" },
            owner_user_id: { bsonType: ["int", "long"], minimum: 1 },
            member_count: { bsonType: "int", minimum: 0 },
            is_trending: { bsonType: ["bool", "null"] },
            is_active: { bsonType: "bool" },
            created_at: { bsonType: "date" },
            updated_at: { bsonType: "date" },
            created_by: { bsonType: ["int", "long", "null"] },
            updated_by: { bsonType: ["int", "long", "null"] }
        }
    }
};

if (!db.getCollectionNames().includes("connect_community")) {
    db.createCollection("connect_community", {
        validator: communityValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
} else {
    db.runCommand({
        collMod: "connect_community",
        validator: communityValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
}

if (!db.connect_community.getIndexes().some(function (idx) {
    return idx.name === "uq_connect_community_id";
})) {
    db.connect_community.createIndex(
        { community_id: 1 },
        { unique: true, name: "uq_connect_community_id" }
    );
}

if (!db.connect_community.getIndexes().some(function (idx) {
    return idx.name === "ix_connect_community_scope_type";
})) {
    db.connect_community.createIndex(
        { school_id: 1, community_type: 1, is_active: 1 },
        { name: "ix_connect_community_scope_type" }
    );
}

if (!db.connect_community.getIndexes().some(function (idx) {
    return idx.name === "ix_connect_community_feed";
})) {
    db.connect_community.createIndex(
        { school_id: 1, branch_id: 1, is_active: 1, created_at: -1 },
        { name: "ix_connect_community_feed" }
    );
}
