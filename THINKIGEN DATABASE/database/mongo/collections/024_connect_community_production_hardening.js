/*
    Community production hardening

    This migration is safe to rerun. It does not drop collections or rewrite IDs.
    It reapplies strict/error validation to existing Community collections and
    replaces the older request_type-scoped pending index with the single pending
    membership-action rule.

    MongoDB cannot validate parent existence, tenant equality, authenticated
    identity, poll option membership, or counter transitions. FastAPI must do so.
*/

var communityCollections = [
    "connect_community",
    "connect_community_member",
    "connect_community_join_request",
    "connect_community_post",
    "connect_community_comment",
    "connect_community_post_like",
    "connect_community_discussion",
    "connect_community_discussion_reply",
    "connect_community_poll",
    "connect_community_poll_vote"
];

communityCollections.forEach(function (collectionName) {
    var collectionInfo = db.getCollectionInfos({ name: collectionName })[0];
    if (!collectionInfo) {
        print("Skipping missing Community collection: " + collectionName);
        return;
    }

    var currentValidator = collectionInfo.options && collectionInfo.options.validator;
    if (!currentValidator) {
        print("Skipping validator update with no existing validator: " + collectionName);
        return;
    }

    var validator = currentValidator;
    if (collectionName === "connect_community_member") {
        validator = {
            $and: [
                currentValidator,
                {
                    $or: [
                        { membership_status: "joined", left_at: null },
                        { membership_status: { $in: ["left", "removed"] }, left_at: { $type: "date" } }
                    ]
                }
            ]
        };
    }

    db.runCommand({
        collMod: collectionName,
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
});

var joinRequest = db.getCollection("connect_community_join_request");
var joinRequestIndexes = joinRequest.getIndexes();
var pendingIndex = joinRequestIndexes.some(function (idx) {
    return idx.name === "uq_connect_pending_join_request";
});
var singlePendingIndex = joinRequestIndexes.some(function (idx) {
    return idx.name === "uq_connect_pending_membership_action";
});

if (!singlePendingIndex) {
    joinRequest.createIndex(
        { community_id: 1, user_id: 1 },
        {
            unique: true,
            partialFilterExpression: { status: "pending" },
            name: "uq_connect_pending_membership_action"
        }
    );
}

if (pendingIndex) {
    joinRequest.dropIndex("uq_connect_pending_join_request");
}

print("Community production hardening complete; existing identifiers and documents were preserved.");
