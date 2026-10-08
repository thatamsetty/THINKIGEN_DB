/*
    Collection: connect_community_post
    Module:     School ERP -> Connect -> Community -> Feed
    Purpose:    Community feed posts (text, image, video, document/file attachments)

    Production Rules:
    - Authoritative likes reside in connect_community_post_like.
    - Authoritative comments reside in connect_community_comment.
    - like_count is a denormalized non-negative counter.
    - Mutable author information (author_name, author_role) is excluded.
    - media is replaced by a single unified attachments array.
    - Attachments strictly enforce object-storage references or external URLs via oneOf.
    - No large binary payloads, share_count, or nested comment/like arrays.
*/

var postValidator = {
    $jsonSchema: {
        bsonType: "object",
        required: [
            "post_id",
            "community_id",
            "school_id",
            "author_user_id",
            "content",
            "like_count",
            "is_active",
            "created_at",
            "updated_at"
        ],
        additionalProperties: false,
        properties: {
            _id: {
                bsonType: "objectId"
            },
            post_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Unique post identifier; must be an integer >= 1"
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
            author_user_id: {
                bsonType: ["int", "long"],
                minimum: 1,
                description: "Reference to security_schema.users(user_id); must be >= 1"
            },
            content: {
                bsonType: "string",
                minLength: 1,
                maxLength: 10000,
                pattern: "\\S",
                description: "Post body text; must contain non-whitespace characters (1-10,000 chars)"
            },
            attachments: {
                bsonType: ["array", "null"],
                description: "Unified post attachments list; each must reference object storage or external URL",
                items: {
                    bsonType: "object",
                    required: ["attachment_id", "attachment_type", "file_name"],
                    additionalProperties: false,
                    properties: {
                        attachment_id: {
                            bsonType: "string",
                            minLength: 1,
                            maxLength: 80,
                            description: "Client or system-generated unique attachment token"
                        },
                        attachment_type: {
                            bsonType: "string",
                            enum: ["image", "document", "video"],
                            description: "Media classification enum"
                        },
                        file_name: {
                            bsonType: "string",
                            minLength: 1,
                            maxLength: 255,
                            description: "Original filename with extension"
                        },
                        file_size_label: {
                            bsonType: ["string", "null"],
                            maxLength: 50,
                            description: "Human-readable file size (e.g. '2.4 MB')"
                        },
                        object_key: {
                            bsonType: ["string", "null"],
                            maxLength: 2048,
                            description: "S3/MinIO/GCS object storage bucket path"
                        },
                        external_url: {
                            bsonType: ["string", "null"],
                            maxLength: 2048,
                            description: "Direct HTTPS URI for externally hosted media"
                        },
                        alt: {
                            bsonType: ["string", "null"],
                            maxLength: 300,
                            description: "Accessibility / screen-reader text description"
                        }
                    },
                    oneOf: [
                        {
                            properties: {
                                object_key: { bsonType: "string", minLength: 1, maxLength: 2048 },
                                external_url: { bsonType: "null" }
                            },
                            required: ["object_key"]
                        },
                        {
                            properties: {
                                object_key: { bsonType: "null" },
                                external_url: { bsonType: "string", minLength: 1, maxLength: 2048 }
                            },
                            required: ["external_url"]
                        }
                    ]
                }
            },
            like_count: {
                bsonType: "int",
                minimum: 0,
                description: "Denormalized like counter; authoritative count in connect_community_post_like"
            },
            is_active: {
                bsonType: "bool",
                description: "Soft deletion indicator"
            },
            created_at: {
                bsonType: "date",
                description: "BSON UTC date when post was published"
            },
            updated_at: {
                bsonType: ["date", "null"],
                description: "BSON UTC date when post was edited; null on initial creation"
            }
        }
    }
};

// 1. Create collection with validator or apply collMod if collection already exists
if (!db.getCollectionNames().includes("connect_community_post")) {
    db.createCollection("connect_community_post", {
        validator: postValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Created collection: connect_community_post with strict schema validation.");
} else {
    db.runCommand({
        collMod: "connect_community_post",
        validator: postValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    print("Updated validator on existing collection: connect_community_post.");
}

// 2. Index Management: Clean legacy indexes if present
var existingPostIndexes = db.connect_community_post.getIndexes();

if (existingPostIndexes.some(function (idx) { return idx.name === "post_id_1"; })) {
    db.connect_community_post.dropIndex("post_id_1");
    print("Dropped legacy unnamed index: post_id_1");
}

if (existingPostIndexes.some(function (idx) { return idx.name === "community_id_1_created_at_-1"; })) {
    db.connect_community_post.dropIndex("community_id_1_created_at_-1");
    print("Dropped legacy unnamed index: community_id_1_created_at_-1");
}

// Refresh index list after cleanups
existingPostIndexes = db.connect_community_post.getIndexes();

// 3. Create named indexes
if (!existingPostIndexes.some(function (idx) { return idx.name === "uq_connect_community_post_id"; })) {
    db.connect_community_post.createIndex(
        { post_id: 1 },
        { unique: true, name: "uq_connect_community_post_id" }
    );
    print("Created unique index: uq_connect_community_post_id");
}

if (!existingPostIndexes.some(function (idx) { return idx.name === "ix_connect_community_post_feed"; })) {
    db.connect_community_post.createIndex(
        { community_id: 1, created_at: -1 },
        { name: "ix_connect_community_post_feed" }
    );
    print("Created compound index: ix_connect_community_post_feed");
}
