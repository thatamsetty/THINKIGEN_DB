/*
    Collection: thinkigen_documents
    Purpose: Central metadata registry for files stored natively in AWS S3.

    SQL Server remains authoritative for business entities, relationships, and users.
    MongoDB stores metadata only; AWS S3 permanently stores all physical file bytes.
    Connect and Learning Hub resource collections retain their existing records.
    FastAPI owns tenant authorization, SQL owner validation, storage operations, and presigned URL generation.
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
                    // ============================================================
                    // MONGODB FIELD: _id
                    // PURPOSE: Internal MongoDB primary key; never expose as the API document ID.
                    // DATA TYPE: ObjectId | REQUIRED BY MONGODB | OWNER: MongoDB
                    // ============================================================
                    _id: { bsonType: "objectId" },
                    // ============================================================
                    // MONGODB FIELD: document_id
                    // PURPOSE: Immutable, globally unique application identifier used by APIs and logs.
                    // DATA TYPE: String | REQUIRED | EXAMPLE: "DOC-ANN-000001"
                    // OWNER: FastAPI generates it; MongoDB enforces uniqueness.
                    // ============================================================
                    document_id: {
                        bsonType: "string",
                        pattern: "^DOC-[A-Z0-9]+(?:-[A-Z0-9]+)*$",
                        minLength: 7,
                        maxLength: 128
                    },
                    // ============================================================
                    // THINKIGEN SCOPE: All document-owning tabs
                    // MONGODB FIELD: tenant
                    // PURPOSE: Identifies the school and optional branch/academic-year scope.
                    // DATA TYPE: Object | REQUIRED | OWNER: SQL Server is authoritative.
                    // Tenant IDs use BSON Int32 values; FastAPI enforces isolation.
                    // ============================================================
                    tenant: {
                        bsonType: "object",
                        required: ["school_id"],
                        additionalProperties: false,
                        properties: {
                            // SQL ENTITY: school | SQL COLUMN: school_id
                            // PURPOSE: Required school owner of the metadata record.
                            school_id: { bsonType: "int", minimum: 1 },
                            // SQL ENTITY: branch | SQL COLUMN: branch_id | NULLABLE: Yes
                            // PURPOSE: Optional branch scope; null means school-level scope.
                            branch_id: { bsonType: ["int", "null"], minimum: 1 },
                            // SQL ENTITY: academic year | SQL COLUMN: academic_year_id | NULLABLE: Yes
                            // PURPOSE: Optional academic-year scope for year-independent documents.
                            academic_year_id: { bsonType: ["int", "null"], minimum: 1 }
                        }
                    },
                    // ============================================================
                    // THINKIGEN TAB: Student
                    // MONGODB FIELD: academic_scope
                    // PURPOSE: Optional context for student-owned academic documents.
                    // ============================================================
                    academic_scope: {
                        bsonType: "object",
                        additionalProperties: false,
                        properties: {
                            class_id: { bsonType: "int", minimum: 1 },
                            section_id: { bsonType: "int", minimum: 1 }
                        }
                    },
                    // ============================================================
                    // THINKIGEN TAB: Student, Announcements, Assignments, Homework,
                    //               Student Leave, Grievance, Connect Communication
                    // MONGODB FIELD: owner
                    // PURPOSE: Points to the exact SQL business entity owning this file.
                    // MongoDB does not enforce a foreign key; FastAPI validates SQL ownership.
                    // ============================================================
                    owner: {
                        bsonType: "object",
                        required: ["entity_type", "entity_id"],
                        additionalProperties: false,
                        properties: {
                            // EXAMPLES: "STUDENT", "TEACHER", "ANNOUNCEMENT", "ASSIGNMENT", "HOMEWORK",
                            //           "LEAVE", "GRIEVANCE", "COMMUNICATION", "COMMUNITY_POST"
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
                            // PURPOSE: Owning business entity identifier | REQUIRED.
                            // Supports BSON Int32 or an application-generated category-prefixed string.
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
                    // ============================================================
                    // THINKIGEN FIELD: Module-specific file classification
                    // MONGODB FIELD: classification
                    // PURPOSE: Describes the business meaning of the file.
                    // No classification.module exists; owner.entity_type is authoritative.
                    // Categories are validated by FastAPI per owning module, not globally here.
                    // ============================================================
                    classification: {
                        bsonType: "object",
                        required: ["category", "attachment_type"],
                        additionalProperties: false,
                        properties: {
                            // PURPOSE: Primary module-specific category | REQUIRED | EXAMPLE: "COMMUNICATION".
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
                            // PURPOSE: Optional module-specific refinement | NULLABLE | EXAMPLE: "CHAT_ATTACHMENT".
                            sub_category: { bsonType: ["string", "null"], maxLength: 100 },
                            attachment_type: {
                                // PURPOSE: Functional role of the file | REQUIRED.
                                // ALLOWED: ATTACHMENT, EVIDENCE, SUPPORTING_DOCUMENT, CERTIFICATE,
                                //          PROFILE_IMAGE, REFERENCE, RESOURCE, MEDIA.
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
                    // ============================================================
                    // THINKIGEN TAB: Connect Communication (1:1 and Group Chat Attachments)
                    // MONGODB FIELD: communication
                    // PURPOSE: Links file metadata to Connect conversation and message history (Parquet).
                    // ============================================================
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
                    // ============================================================
                    // THINKIGEN TAB: Connect Community
                    // MONGODB FIELD: community
                    // PURPOSE: Links file metadata to a specific community group/branch.
                    // ============================================================
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
                    // ============================================================
                    // MONGODB FIELD: file
                    // PURPOSE: Describes the bytes stored in object storage.
                    // MongoDB stores metadata only; it never stores the binary payload.
                    // ============================================================
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
                            // PURPOSE: User-provided name retained for display/audit; never a Blob/S3 key.
                            original_name: { bsonType: "string", minLength: 1, maxLength: 255 },
                            // PURPOSE: Lowercase extension validated by FastAPI against file content.
                            extension: {
                                bsonType: "string",
                                pattern: "^\\.?[a-zA-Z0-9]{1,15}$"
                            },
                            // PURPOSE: Server-detected/validated media type; do not trust client input.
                            mime_type: {
                                bsonType: "string",
                                pattern: "^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$",
                                minLength: 3,
                                maxLength: 200
                            },
                            // PURPOSE: Actual byte length; must be greater than zero.
                            size_bytes: { bsonType: ["int", "long"], minimum: 1 },
                            // PURPOSE: SHA-256 of actual file bytes for integrity and optional deduplication.
                            checksum_sha256: { bsonType: "string", pattern: "^[a-fA-F0-9]{64}$" }
                        }
                    },
                    // ============================================================
                    // STORAGE OWNER: AWS S3
                    // MONGODB FIELD: storage
                    // PURPOSE: Stable physical reference; no binary, permanent URL, presigned URL, or credential.
                    // ============================================================
                    storage: {
                        bsonType: "object",
                        required: ["provider", "object_key"],
                        additionalProperties: false,
                        properties: {
                            // ALLOWED: AWS_S3 | REQUIRED
                            provider: {
                                bsonType: "string",
                                enum: ["AWS_S3"]
                            },
                            // PURPOSE: Private AWS S3 bucket name, not a URL.
                            bucket: {
                                bsonType: "string",
                                minLength: 1,
                                maxLength: 255
                            },
                            // PURPOSE: Stable object path generated by FastAPI; never a presigned URL.
                            object_key: {
                                bsonType: "string",
                                minLength: 1,
                                maxLength: 2048
                            },
                            // PURPOSE: Optional provider object version identifier.
                            version_id: {
                                bsonType: "string",
                                minLength: 1,
                                maxLength: 512
                            }
                        }
                    },
                    // ============================================================
                    // MONGODB FIELD: security
                    // PURPOSE: Metadata visibility hint; FastAPI still performs authorization.
                    // No per-document encryption metadata is stored.
                    // ============================================================
                    security: {
                        bsonType: "object",
                        required: ["visibility"],
                        additionalProperties: false,
                        properties: {
                            // ALLOWED: PRIVATE, RESTRICTED, PUBLIC. PUBLIC never bypasses FastAPI rules.
                            visibility: { bsonType: "string", enum: ["PRIVATE", "RESTRICTED", "PUBLIC"] }
                        }
                    },
                    // ============================================================
                    // MONGODB FIELD: lifecycle
                    // PURPOSE: Upload, serving, quarantine, and soft-delete state.
                    // FastAPI transitions state idempotently; deleted metadata is retained for audit.
                    // ============================================================
                    lifecycle: {
                        bsonType: "object",
                        required: ["status"],
                        additionalProperties: false,
                        properties: {
                            status: {
                                // ALLOWED: UPLOADING, ACTIVE, FAILED, DELETED, QUARANTINED.
                                bsonType: "string",
                                enum: ["UPLOADING", "ACTIVE", "FAILED", "DELETED", "QUARANTINED"]
                            },
                            // SQL FIELD: deletion timestamp | BSON Date UTC | NULLABLE.
                            deleted_at: { bsonType: ["date", "null"] },
                            // SQL FIELD: deleting user BIGINT | BSON long | NULLABLE.
                            deleted_by: { bsonType: ["int", "null"] }
                        }
                    },
                    // ============================================================
                    // SQL ENTITY: security_schema.users
                    // MONGODB FIELD: uploaded_by
                    // PURPOSE: Records the SQL user who initiated upload; no user profile is copied.
                    // ============================================================
                    uploaded_by: { bsonType: "int", minimum: 1 },
                    // SQL ENTITY: security_schema.users | SQL FIELD: user_id BIGINT | NULLABLE.
                    // PURPOSE: Records the user who last modified metadata.
                    updated_by: { bsonType: ["int", "null"], minimum: 1 },
                    // ============================================================
                    // STORAGE OWNER: AWS S3
                    // MONGODB FIELD: preview
                    // PURPOSE: Optional pointer to preview bytes; preview binaries never enter MongoDB.
                    // ============================================================
                    preview: {
                        oneOf: [
                            { bsonType: "null" },
                            {
                                bsonType: "object",
                                required: ["available", "object_key", "mime_type"],
                                additionalProperties: false,
                                properties: {
                                    // PURPOSE: Whether the preview object is available in storage.
                                    available: { bsonType: "bool", enum: [true] },
                                    // PURPOSE: Stable preview object key, never a URL.
                                    object_key: { bsonType: "string", minLength: 1, maxLength: 2048 },
                                    // PURPOSE: MIME type of the preview object.
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
                    // ============================================================
                    // MONGODB FIELD: processing
                    // PURPOSE: Optional asynchronous processing state for scanning, OCR, or previews.
                    // ============================================================
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
                    // ============================================================
                    // MONGODB FIELD: storage_cleanup
                    // PURPOSE: Optional retry state for asynchronous object deletion/archive.
                    // Use only when the backend implements cleanup workers.
                    // ============================================================
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
                    // BSON Date UTC; server-managed creation time, never trusted from the client.
                    created_at: { bsonType: "date" },
                    // BSON Date UTC; updated on every metadata modification.
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

if (!db.getCollectionNames().includes(COLLECTION_NAME)) {
    db.createCollection(COLLECTION_NAME, {
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
} else {
    db.runCommand({
        collMod: COLLECTION_NAME,
        validator: validator,
        validationLevel: "strict",
        validationAction: "error"
    });
}

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
        db.thinkigen_documents.createIndex(indexDefinition[0], indexDefinition[1]);
    }
});
