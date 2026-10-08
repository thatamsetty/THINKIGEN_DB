/*
    Collection: connect_community_poll_vote
    Module:     School ERP -> Connect -> Community -> Polls
    Purpose:    Authoritative record of user votes (ONE document = ONE user's vote for ONE poll)

    Production Rules:
    - Authoritative vote records reside here.
    - Exactly ONE vote per user per poll is enforced by unique index: uq_connect_community_poll_vote.
    - References connect_community_poll.poll_id and an option_id within options[].
    - User identity references security_schema.users(user_id) with no duplicate mutable user profiles.
    - Fast aggregate and option counters reside in connect_community_poll.
    - Strict $jsonSchema validation with validationLevel: "strict" and validationAction: "error".
    - Safe idempotent migration supporting initial creation and schema modification (collMod).
*/

var voteValidator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "poll_id",
            "user_id",
            "school_id",
            "option_id",
            "voted_at"
        ],
        additionalProperties: false,
        properties: {
            _id: {
                bsonType: "objectId"
            },
            poll_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Reference to connect_community_poll.poll_id; must be an integer >= 1"
            },
            user_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Reference to security_schema.users(user_id); must be an integer >= 1"
            },
            school_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Multi-tenant institutional boundary; must be an integer >= 1"
            },
            option_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Selected option identifier within connect_community_poll.options; integer >= 1"
            },
            voted_at: {
                bsonType: "date",
                description: "BSON UTC timestamp when the vote was cast"
            }
        }
    }
};

// 1. Create collection with validator or apply collMod if collection already exists
if (!db.getCollectionNames().includes("connect_community_poll_vote")) {
    db.createCollection("connect_community_poll_vote", {
        validator: voteValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Created collection: connect_community_poll_vote with strict schema validation.");
} else {
    db.runCommand({
        collMod: "connect_community_poll_vote",
        validator: voteValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Updated validator on existing collection: connect_community_poll_vote.");
}

// 2. Index Management: Clean legacy indexes if present
var existingVoteIndexes = db.connect_community_poll_vote.getIndexes();

if (existingVoteIndexes.some(function (idx) { return idx.name === "poll_id_1_user_id_1"; })) {
    db.connect_community_poll_vote.dropIndex("poll_id_1_user_id_1");
    print("Dropped legacy unnamed index: poll_id_1_user_id_1");
}

// Refresh index list after cleanups
existingVoteIndexes = db.connect_community_poll_vote.getIndexes();

// 3. Create named indexes
if (!existingVoteIndexes.some(function (idx) { return idx.name === "uq_connect_community_poll_vote"; })) {
    db.connect_community_poll_vote.createIndex(
        { poll_id: 1, user_id: 1 },
        { unique: true, name: "uq_connect_community_poll_vote" }
    );
    print("Created compound unique index: uq_connect_community_poll_vote");
}
