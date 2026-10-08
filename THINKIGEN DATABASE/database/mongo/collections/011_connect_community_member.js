/*
    Collection: connect_community_member
    Purpose:    Who joined which community + role
*/

var memberValidator = {
    $and: [
        {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "community_id",
                    "user_id",
                    "school_id",
                    "branch_id",
                    "display_name",
                    "user_role",
                    "member_role",
                    "membership_status",
                    "joined_at",
                    "left_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    community_id: { bsonType: ["int", "long"], minimum: 1 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    branch_id: { bsonType: ["int", "long"], minimum: 1 },
                    display_name: { bsonType: "string", minLength: 1, maxLength: 200, pattern: "\\S" },
                    user_role: {
                        bsonType: ["string", "null"],
                        enum: ["student", "teacher", "staff", "faculty", "admin", null]
                    },
                    member_role: {
                        bsonType: "string",
                        enum: ["member", "moderator", "owner"]
                    },
                    membership_status: {
                        bsonType: "string",
                        enum: ["joined", "left", "removed"]
                    },
                    joined_at: { bsonType: "date" },
                    left_at: { bsonType: ["date", "null"] }
                }
            }
        },
        {
            $or: [
                { membership_status: "joined", left_at: null },
                { membership_status: { $in: ["left", "removed"] }, left_at: { $type: "date" } }
            ]
        }
    ]
};

if (!db.getCollectionNames().includes("connect_community_member")) {
    db.createCollection("connect_community_member", {
        validator: memberValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
} else {
    db.runCommand({
        collMod: "connect_community_member",
        validator: memberValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
}

if (!db.connect_community_member.getIndexes().some(function (idx) {
    return idx.name === "uq_connect_community_member";
})) {
    db.connect_community_member.createIndex(
        { community_id: 1, user_id: 1 },
        { unique: true, name: "uq_connect_community_member" }
    );
}

if (!db.connect_community_member.getIndexes().some(function (idx) {
    return idx.name === "ix_connect_community_member_user";
})) {
    db.connect_community_member.createIndex(
        { user_id: 1, membership_status: 1 },
        { name: "ix_connect_community_member_user" }
    );
}

if (!db.connect_community_member.getIndexes().some(function (idx) {
    return idx.name === "ix_connect_community_member_community_status";
})) {
    db.connect_community_member.createIndex(
        { community_id: 1, membership_status: 1 },
        { name: "ix_connect_community_member_community_status" }
    );
}

if (!db.connect_community_member.getIndexes().some(function (idx) {
    return idx.name === "ix_connect_community_member_branch_user";
})) {
    db.connect_community_member.createIndex(
        { school_id: 1, branch_id: 1, user_id: 1 },
        { name: "ix_connect_community_member_branch_user" }
    );
}
