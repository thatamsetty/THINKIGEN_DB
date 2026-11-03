/*
    Rollback Script: 023_rollback_thinkigen_documents_teacher_leave_grievance.js
    Module:          Thinkigen Documents (MongoDB)
    Purpose:         Revert thinkigen_documents validator to previous 9-entity version.
                     Does NOT drop the collection or delete records.
*/

var COLLECTION_NAME = "thinkigen_documents";

var previousValidator = {
    $and: [
        {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "document_id",
                    "tenant",
                    "owner",
                    "classification",
                    "file",
                    "storage",
                    "security",
                    "lifecycle",
                    "uploaded_by",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    document_id: {
                        bsonType: "string",
                        pattern: "^DOC-[A-Z0-9]+(?:-[A-Z0-9]+)*$",
                        minLength: 7,
                        maxLength: 128
                    },
                    tenant: {
                        bsonType: "object",
                        required: ["school_id"],
                        additionalProperties: false,
                        properties: {
                            school_id: { bsonType: "int", minimum: 1 },
                            branch_id: { bsonType: ["int", "null"], minimum: 1 },
                            academic_year_id: { bsonType: ["int", "null"], minimum: 1 }
                        }
                    },
                    academic_scope: {
                        bsonType: "object",
                        additionalProperties: false,
                        properties: {
                            class_id: { bsonType: "int", minimum: 1 },
                            section_id: { bsonType: "int", minimum: 1 }
                        }
                    },
                    owner: {
                        bsonType: "object",
                        required: ["entity_type", "entity_id"],
                        additionalProperties: false,
                        properties: {
                            entity_type: {
                                bsonType: "string",
                                enum: [
                                    "STUDENT",
                                    "TEACHER",
                                    "ANNOUNCEMENT",
                                    "ASSIGNMENT",
                                    "HOMEWORK",
                                    "LEAVE",
                                    "GRIEVANCE",
                                    "COMMUNICATION",
                                    "COMMUNITY_POST"
                                ]
                            },
                            entity_id: {
                                oneOf: [
                                    {
                                        bsonType: "int",
                                        minimum: 1
                                    },
                                    {
                                        bsonType: "string",
                                        minLength: 1,
                                        maxLength: 128,
                                        pattern: "^[A-Za-z0-9_-]+$"
                                    }
                                ]
                            }
                        }
                    },
                    classification: {
                        bsonType: "object",
                        required: ["category", "attachment_type"],
                        additionalProperties: false,
                        properties: {
                            category: {
                                bsonType: "string",
                                enum: [
                                    "STUDENT_DOCUMENT",
                                    "TEACHER_DOCUMENT",
                                    "ANNOUNCEMENT",
                                    "ASSIGNMENT",
                                    "HOMEWORK",
                                    "STUDENT_LEAVE",
                                    "GRIEVANCE",
                                    "COMMUNICATION",
                                    "COMMUNITY"
                                ]
                            },
                            sub_category: { bsonType: ["string", "null"], maxLength: 100 },
                            attachment_type: {
                                bsonType: "string",
                                enum: [
                                    "ATTACHMENT",
                                    "EVIDENCE",
                                    "SUPPORTING_DOCUMENT",
                                    "CERTIFICATE",
                                    "PROFILE_IMAGE",
                                    "REFERENCE",
                                    "RESOURCE",
                                    "MEDIA"
                                ]
                            }
                        }
                    },
                    communication: {
                        oneOf: [
                            { bsonType: "null" },
                            {
                                bsonType: "object",
                                required: [
                                    "conversation_id",
                                    "message_id",
                                    "sender_user_id"
                                ],
                                additionalProperties: false,
                                properties: {
                                    conversation_id: {
                                        bsonType: "string",
                                        minLength: 1,
                                        maxLength: 128
                                    },
                                    message_id: {
                                        bsonType: "string",
                                        minLength: 1,
                                        maxLength: 128
                                    },
                                    sender_user_id: {
                                        bsonType: ["int", "long"],
                                        minimum: 1
                                    }
                                }
                            }
                        ]
                    },
                    community: {
                        oneOf: [
                            { bsonType: "null" },
                            {
                                bsonType: "object",
                                required: ["community_id"],
                                additionalProperties: false,
                                properties: {
                                    community_id: {
                                        bsonType: ["int", "long"],
                                        minimum: 1
                                    }
                                }
                            }
                        ]
                    },
                    file: {
                        bsonType: "object",
                        required: [
                            "original_name",
                            "extension",
                            "mime_type",
                            "size_bytes",
                            "checksum_sha256"
                        ],
                        additionalProperties: false,
                        properties: {
                            original_name: { bsonType: "string", minLength: 1, maxLength: 255 },
                            extension: {
                                bsonType: "string",
                                pattern: "^\\.?[a-zA-Z0-9]{1,15}$"
                            },
                            mime_type: {
                                bsonType: "string",
                                pattern: "^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$",
                                minLength: 3,
                                maxLength: 200
                            },
                            size_bytes: { bsonType: ["int", "long"], minimum: 1 },
                            checksum_sha256: { bsonType: "string", pattern: "^[a-fA-F0-9]{64}$" }
                        }
                    },
                    storage: {
                        bsonType: "object",
                        required: ["provider", "object_key"],
                        additionalProperties: false,
                        properties: {
                            provider: {
                                bsonType: "string",
                                enum: ["AWS_S3"]
                            },
                            bucket: {
                                bsonType: "string",
                                minLength: 1,
                                maxLength: 255
                            },
                            object_key: {
                                bsonType: "string",
                                minLength: 1,
                                maxLength: 2048
                            },
                            version_id: {
                                bsonType: "string",
                                minLength: 1,
                                maxLength: 512
                            }
                        }
                    },
                    security: {
                        bsonType: "object",
                        required: ["visibility"],
                        additionalProperties: false,
                        properties: {
                            visibility: { bsonType: "string", enum: ["PRIVATE", "RESTRICTED", "PUBLIC"] }
                        }
                    },
                    lifecycle: {
                        bsonType: "object",
                        required: ["status"],
                        additionalProperties: false,
                        properties: {
                            status: {
                                bsonType: "string",
                                enum: ["UPLOADING", "ACTIVE", "FAILED", "DELETED", "QUARANTINED"]
                            },
                            deleted_at: { bsonType: ["date", "null"] },
                            deleted_by: { bsonType: ["int", "null"] }
                        }
                    },
                    uploaded_by: { bsonType: "int", minimum: 1 },
                    updated_by: { bsonType: ["int", "null"], minimum: 1 },
                    preview: {
                        oneOf: [
                            { bsonType: "null" },
                            {
                                bsonType: "object",
                                required: ["available", "object_key", "mime_type"],
                                additionalProperties: false,
                                properties: {
                                    available: { bsonType: "bool", enum: [true] },
                                    object_key: { bsonType: "string", minLength: 1, maxLength: 2048 },
                                    mime_type: {
                                        bsonType: "string",
                                        pattern: "^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$",
                                        minLength: 3,
                                        maxLength: 200
                                    }
                                }
                            }
                        ]
                    },
                    processing: {
                        oneOf: [
                            { bsonType: "null" },
                            {
                                bsonType: "object",
                                required: ["status"],
                                additionalProperties: false,
                                properties: {
                                    status: {
                                        bsonType: "string",
                                        enum: ["NOT_REQUIRED", "PENDING", "PROCESSING", "COMPLETED", "FAILED"]
                                    },
                                    processed_at: { bsonType: ["date", "null"] },
                                    processor_version: { bsonType: ["string", "null"], maxLength: 100 },
                                    error_code: { bsonType: ["string", "null"], maxLength: 100 }
                                }
                            }
                        ]
                    },
                    storage_cleanup: {
                        oneOf: [
                            { bsonType: "null" },
                            {
                                bsonType: "object",
                                required: ["status", "attempts"],
                                additionalProperties: false,
                                properties: {
                                    status: { bsonType: "string", enum: ["PENDING", "COMPLETED", "FAILED"] },
                                    attempts: { bsonType: ["int", "long"], minimum: 0 },
                                    last_attempt_at: { bsonType: ["date", "null"] },
                                    last_error: { bsonType: ["string", "null"], maxLength: 2000 }
                                }
                            }
                        ]
                    },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        {
            $or: [
                { "owner.entity_type": "STUDENT", "classification.category": "STUDENT_DOCUMENT" },
                { "owner.entity_type": "TEACHER", "classification.category": "TEACHER_DOCUMENT" },
                { "owner.entity_type": "ANNOUNCEMENT", "classification.category": "ANNOUNCEMENT" },
                { "owner.entity_type": "ASSIGNMENT", "classification.category": "ASSIGNMENT" },
                { "owner.entity_type": "HOMEWORK", "classification.category": "HOMEWORK" },
                { "owner.entity_type": "LEAVE", "classification.category": "STUDENT_LEAVE" },
                { "owner.entity_type": "GRIEVANCE", "classification.category": "GRIEVANCE" },
                { "owner.entity_type": "COMMUNICATION", "classification.category": "COMMUNICATION" },
                { "owner.entity_type": "COMMUNITY_POST", "classification.category": "COMMUNITY" }
            ]
        },
        {
            "storage.provider": "AWS_S3",
            "storage.bucket": { $type: "string" }
        },
        {
            $or: [
                { "owner.entity_type": { $ne: "COMMUNICATION" } },
                { "communication": { $type: "object" } }
            ]
        },
        {
            $or: [
                { "owner.entity_type": { $ne: "COMMUNITY_POST" } },
                { "community": { $type: "object" } }
            ]
        },
        {
            $or: [
                {
                    "lifecycle.status": { $ne: "DELETED" },
                    "lifecycle.deleted_at": null,
                    "lifecycle.deleted_by": null
                },
                {
                    "lifecycle.status": "DELETED",
                    "lifecycle.deleted_at": { $type: "date" },
                    "lifecycle.deleted_by": { $type: "int" }
                }
            ]
        }
    ]
};

print("========================================================================");
print("Rollback: Reverting thinkigen_documents validator to 9-entity baseline");
print("========================================================================");

if (db.getCollectionNames().includes(COLLECTION_NAME)) {
    var res = db.runCommand({
        collMod: COLLECTION_NAME,
        validator: previousValidator,
        validationLevel: "strict",
        validationAction: "error"
    });
    if (res.ok !== 1) {
        throw new Error("collMod rollback failed: " + JSON.stringify(res));
    }
    print("Rollback applied successfully: validator reverted.");
} else {
    print("Collection " + COLLECTION_NAME + " does not exist. Nothing to roll back.");
}
