# Thinkigen Documents

`thinkigen_documents` is the single metadata collection for files shared by SQL-backed Thinkigen modules. It covers Student, Announcement, Assignment, Homework, Student Leave, and Grievance files. Connect and Learning Hub resource collections keep their existing ownership and are not migrated into this collection.

## Storage boundary

- SQL Server / Azure SQL owns business entities, relationships, users, and authorization facts.
- MongoDB owns document and file metadata only.
- Azure Blob Storage owns binary content. `storage.object_key` is the stable reference.
- FastAPI authenticates, validates SQL ownership and tenant scope, and generates short-lived signed URLs on demand.
- Never store binary data, permanent URLs, SAS tokens, credentials, or complete SQL entities in MongoDB.

Tenant and user identifiers use the BSON types defined by the validation script. `owner.entity_id` accepts either a BSON Int32 numeric business-entity ID or an application-generated string such as `STU-000001`, according to the application ID strategy.

## Apply

```javascript
load("database/mongo/collections/023_thinkigen_documents.js");
```

The script is safe to re-run. It creates only `thinkigen_documents` and four workload indexes. A checksum index is intentionally omitted until duplicate detection is implemented by the application.

## Confirmed mappings

| Module | `owner.entity_type` | `owner.entity_id` |
|---|---|---|
| Student | `STUDENT` | `student_id` |
| Announcement | `ANNOUNCEMENT` | `announcement_id` |
| Assignment | `ASSIGNMENT` | `assignment_id` |
| Homework | `HOMEWORK` | `homework_id` |
| Student Leave | `STUDENT_LEAVE` | `student_leave_id` |
| Grievance | `GRIEVANCE` | `grievance_id` |

`classification.category` is module-specific and application-configured. The collection does not impose a universal category list. Confirmed examples include `EVENT`, `ATTACHMENT`, `MEDICAL_CERTIFICATE`, and `EVIDENCE`; unsupported categories remain configurable/TBD.

## Sample records

Each sample is one MongoDB document. Use `NumberLong(...)` for numeric SQL IDs and `ISODate(...)` for UTC dates.

```javascript
{
    document_id: "DOC-00000001",
    tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
    owner: { entity_type: "STUDENT", entity_id: "STU-000001" },
    classification: { category: "CERTIFICATE", sub_category: null, document_type: "CERTIFICATE" },
    file: { original_name: "transfer_certificate.pdf", stored_name: "uuid-transfer_certificate.pdf", extension: "pdf", mime_type: "application/pdf", size_bytes: NumberLong(245678), checksum_sha256: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", content_encoding: null },
    storage: { provider: "AZURE_BLOB", container: "thinkigen-documents", object_key: "schools/1/branches/1/students/5001/DOC-00000001/uuid-transfer_certificate.pdf", storage_version_id: null },
    security: { visibility: "PRIVATE" },
    lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
    uploaded_by: { user_id: NumberLong(501) },
    display_order: 0, display_name: null, description: null,
    created_at: ISODate("2026-09-04T10:00:00Z"), updated_at: ISODate("2026-09-04T10:00:00Z")
}
```

For Announcement, Assignment, Homework, Student Leave, and Grievance, retain the same shape and change only the owner, category, document type, and Blob hierarchy. `owner.entity_type` is the authoritative module/entity classification. Suggested confirmed sample classifications are `ANNOUNCEMENT/EVENT/ATTACHMENT`, `ASSIGNMENT/ATTACHMENT/ATTACHMENT`, `HOMEWORK/ATTACHMENT/ATTACHMENT`, `STUDENT_LEAVE/MEDICAL_CERTIFICATE/CERTIFICATE`, and `GRIEVANCE/EVIDENCE/EVIDENCE`.

## Lifecycle and workflows

1. FastAPI authenticates the user, validates school/branch access, confirms the SQL owner exists, and validates module-specific category rules, extension, detected MIME type, and size.
2. FastAPI creates metadata as `UPLOADING`, uploads bytes to a private Blob container, computes SHA-256, then updates metadata to `ACTIVE`. Upload failure becomes `FAILED` and is never returned as active.
3. Download first loads by `document_id`, requires `ACTIVE`, checks tenant and SQL business authorization, then returns metadata plus a short-lived SAS URL. MongoDB is not an authorization boundary.
4. Delete first sets `DELETED`, `deleted_at`, and `deleted_by`; Blob deletion/archive is then retried asynchronously according to retention policy. Do not report cleanup complete until Blob operation succeeds.

Pydantic request models should mirror `tenant`, `owner`, and `classification`, with `entity_id: str`, `school_id/branch_id/academic_year_id: int`, and `category: str` validated by a module-specific FastAPI registry. Repository methods should always require `school_id` in lookup filters, exclude `DELETED` by default, and use `document_id` for the public API rather than exposing `_id`.

## Indexes

- `uq_thinkigen_documents_document_id`: public identifier uniqueness.
- `ix_thinkigen_documents_tenant_owner_status`: tenant-safe owner/status lookup.
- `ix_thinkigen_documents_tenant_owner_newest`: tenant-safe newest-first owner listing.
- `uq_thinkigen_documents_blob_object`: prevents duplicate Azure Blob object references.

Do not add a global filename uniqueness rule. A tenant-scoped checksum index should be added only when duplicate detection is implemented by FastAPI.