/*
    Collection: connect_community_join_request
    Purpose:    Community join requests + invitations

    request_type:
    - request    → user asks to join
    - invitation → admin/faculty invited a user

    Prevent more than one pending membership action for the same user + community.
*/

var joinRequestValidator = {
    $and: [
        {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "request_id",
                    "community_id",
                    "user_id",
                    "school_id",
                    "branch_id",
                    "request_type",
                    "status",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    request_id: { bsonType: ["int", "long"], minimum: 1 },
                    community_id: { bsonType: ["int", "long"], minimum: 1 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    branch_id: { bsonType: ["int", "long"], minimum: 1 },
                    request_type: {
                        bsonType: "string",
                        enum: ["request", "invitation"]
                    },
                    status: {
                        bsonType: "string",
                        enum: ["pending", "accepted", "declined", "cancelled"]
                    },
                    invited_by_user_id: { bsonType: ["int", "long", "null"] },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        {
            $or: [
                {
                    request_type: "request",
                    invited_by_user_id: null
                },
                {
                    request_type: "invitation",
                    invited_by_user_id: {
                        $gte: 1
                    }
                }
            ]
        }
    ]
};

if (!db.getCollectionNames().includes("connect_community_join_request")) {
    db.createCollection("connect_community_join_request", {
        validator: joinRequestValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
} else {
    db.runCommand({
        collMod: "connect_community_join_request",
        validator: joinRequestValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
}

if (!db.connect_community_join_request.getIndexes().some(function (idx) {
    return idx.name === "uq_connect_community_join_request_id";
})) {
    db.connect_community_join_request.createIndex(
        { request_id: 1 },
        { unique: true, name: "uq_connect_community_join_request_id" }
    );
}

// Clean up legacy index name if present from earlier migrations
if (db.connect_community_join_request.getIndexes().some(function (idx) {
    return idx.name === "uq_connect_pending_join_request";
})) {
    db.connect_community_join_request.dropIndex("uq_connect_pending_join_request");
}

if (!db.connect_community_join_request.getIndexes().some(function (idx) {
    return idx.name === "uq_connect_pending_membership_action";
})) {
    db.connect_community_join_request.createIndex(
        { community_id: 1, user_id: 1 },
        {
            unique: true,
            partialFilterExpression: { status: "pending" },
            name: "uq_connect_pending_membership_action"
        }
    );
}

if (!db.connect_community_join_request.getIndexes().some(function (idx) {
    return idx.name === "ix_connect_join_request_user_status";
})) {
    db.connect_community_join_request.createIndex(
        { user_id: 1, status: 1 },
        { name: "ix_connect_join_request_user_status" }
    );
}

if (!db.connect_community_join_request.getIndexes().some(function (idx) {
    return idx.name === "ix_connect_join_request_community_status";
})) {
    db.connect_community_join_request.createIndex(
        { community_id: 1, status: 1 },
        { name: "ix_connect_join_request_community_status" }
    );
}
