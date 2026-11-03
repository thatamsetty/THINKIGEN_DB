/*
    Migration Script: 023_update_thinkigen_documents_teacher_leave_grievance.js
    Module:           Thinkigen Documents (MongoDB)
    Purpose:          Extend thinkigen_documents to support:
                      1. Teacher Leave Applications supporting documents:
                         - owner.entity_type = TEACHER_LEAVE_APPLICATION
                         - classification.category = TEACHER_LEAVE
                         - classification.attachment_type = SUPPORTING_DOCUMENT
                      2. Teacher Grievance evidence & attachments:
                         - owner.entity_type = TEACHER_GRIEVANCE
                         - classification.category = TEACHER_GRIEVANCE
                         - classification.attachment_type = EVIDENCE

    Safety & Compatibility:
    - Non-destructive idempotent execution via collMod.
    - Preserves all 9 existing owner.entity_type enums and adds 2 new values.
    - Preserves all 9 existing classification.category enums and adds 2 new values.
    - Reuses existing classification.attachment_type enum (SUPPORTING_DOCUMENT, EVIDENCE).
    - Reuses existing tenant, owner, storage, and lifecycle metadata schema.
    - Uses existing compound indexes (no duplicate indexes required).
    - Preserves existing document records without rewrite.
*/

var COLLECTION_NAME = "thinkigen_documents";

var validator = {
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
                                    "COMMUNITY_POST",
                                    "TEACHER_LEAVE_APPLICATION",
                                    "TEACHER_GRIEVANCE"
                                ]
                            },
                            entity_id: {
                                oneOf: [
                                    {
                                        bsonType: ["int", "long"],
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
                                    "COMMUNITY",
                                    "TEACHER_LEAVE",
                                    "TEACHER_GRIEVANCE"
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
                { "owner.entity_type": "COMMUNITY_POST", "classification.category": "COMMUNITY" },
                {
                    "owner.entity_type": "TEACHER_LEAVE_APPLICATION",
                    "classification.category": "TEACHER_LEAVE",
                    "classification.attachment_type": "SUPPORTING_DOCUMENT"
                },
                {
                    "owner.entity_type": "TEACHER_GRIEVANCE",
                    "classification.category": "TEACHER_GRIEVANCE",
                    "classification.attachment_type": "EVIDENCE"
                }
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
print("Applying Migration: 023_update_thinkigen_documents_teacher_leave_grievance");
print("========================================================================");

if (!db.getCollectionNames().includes(COLLECTION_NAME)) {
    print("Creating collection " + COLLECTION_NAME + " with updated schema validator...");
    db.createCollection(COLLECTION_NAME, {
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
} else {
    print("Modifying collection " + COLLECTION_NAME + " schema validator via collMod...");
    var res = db.runCommand({
        collMod: COLLECTION_NAME,
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
    if (res.ok !== 1) {
        throw new Error("collMod failed: " + JSON.stringify(res));
    }
}

print("Verifying workload indexes on " + COLLECTION_NAME + "...");
[
    [
        { document_id: 1 },
        { unique: true, name: "uq_thinkigen_documents_document_id" }
    ],
    [
        {
            "tenant.school_id": 1,
            "tenant.branch_id": 1,
            "owner.entity_type": 1,
            "owner.entity_id": 1,
            "lifecycle.status": 1
        },
        { name: "ix_thinkigen_documents_tenant_owner_status" }
    ],
    [
        {
            "tenant.school_id": 1,
            "tenant.branch_id": 1,
            "owner.entity_type": 1,
            "owner.entity_id": 1,
            created_at: -1
        },
        { name: "ix_thinkigen_documents_tenant_owner_newest" }
    ],
    [
        {
            "storage.provider": 1,
            "storage.bucket": 1,
            "storage.object_key": 1
        },
        { unique: true, name: "uq_thinkigen_documents_s3_object" }
    ],
    [
        {
            "communication.conversation_id": 1,
            "communication.message_id": 1,
            "lifecycle.status": 1,
            "created_at": 1
        },
        { name: "ix_thinkigen_documents_communication_message" }
    ],
    [
        {
            "communication.conversation_id": 1,
            "lifecycle.status": 1,
            "created_at": -1
        },
        { name: "ix_thinkigen_documents_communication_conversation" }
    ],
    [
        {
            "communication.message_id": 1,
            "lifecycle.status": 1
        },
        { name: "ix_thinkigen_documents_communication_message_id" }
    ],
    [
        {
            "community.community_id": 1,
            "lifecycle.status": 1,
            created_at: -1
        },
        { name: "ix_thinkigen_documents_community" }
    ],
    [
        { "tenant.school_id": 1, "file.checksum_sha256": 1 },
        { name: "ix_thinkigen_documents_tenant_checksum" }
    ],
    [
        { "lifecycle.status": 1, created_at: 1 },
        {
            name: "ix_thinkigen_documents_lifecycle_cleanup",
            partialFilterExpression: {
                "lifecycle.status": {
                    $in: ["UPLOADING", "FAILED", "QUARANTINED"]
                }
            }
        }
    ]
].forEach(function (indexDefinition) {
    if (!db.thinkigen_documents.getIndexes().some(function (idx) {
        return idx.name === indexDefinition[1].name;
    })) {
        print("Creating index: " + indexDefinition[1].name);
        db.thinkigen_documents.createIndex(indexDefinition[0], indexDefinition[1]);
    }
});

print("Migration applied successfully!");
