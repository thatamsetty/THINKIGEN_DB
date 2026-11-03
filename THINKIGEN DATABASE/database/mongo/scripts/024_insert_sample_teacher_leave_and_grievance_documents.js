/*
    Script:    024_insert_sample_teacher_leave_and_grievance_documents.js
    Module:    Thinkigen Documents (MongoDB)
    Purpose:   Insert production-valid sample metadata records for:
               1. Teacher Leave Application supporting document
               2. Teacher Grievance evidence document
*/

const targetDb = db.getSiblingDB("thinkigen");

// 1. Teacher Leave Application Supporting Document
const teacherLeaveDocument = {
    document_id: "DOC-TL-2026-000001",
    tenant: {
        school_id: NumberInt(1),
        branch_id: NumberInt(1),
        academic_year_id: NumberInt(1)
    },
    owner: {
        entity_type: "TEACHER_LEAVE_APPLICATION",
        entity_id: NumberInt(101) // Maps to SQL Server leave_application_id (INT/BIGINT)
    },
    classification: {
        category: "TEACHER_LEAVE",
        sub_category: "MEDICAL_CERTIFICATE",
        attachment_type: "SUPPORTING_DOCUMENT"
    },
    file: {
        original_name: "doctor_prescription_october_2026.pdf",
        extension: ".pdf",
        mime_type: "application/pdf",
        size_bytes: NumberInt(348160),
        checksum_sha256: "a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0"
    },
    storage: {
        provider: "AWS_S3",
        bucket: "thinkigen-school-docs-prod",
        object_key: "schools/1/teachers/leave/101/DOC-TL-2026-000001.pdf"
    },
    security: {
        visibility: "RESTRICTED"
    },
    lifecycle: {
        status: "ACTIVE",
        deleted_at: null,
        deleted_by: null
    },
    uploaded_by: NumberInt(5001), // SQL Server user_id of the teacher
    updated_by: null,
    preview: null,
    processing: null,
    storage_cleanup: null,
    created_at: new Date(),
    updated_at: new Date()
};

// 2. Teacher Grievance Evidence Document
const teacherGrievanceDocument = {
    document_id: "DOC-TG-2026-000001",
    tenant: {
        school_id: NumberInt(1),
        branch_id: NumberInt(1),
        academic_year_id: NumberInt(1)
    },
    owner: {
        entity_type: "TEACHER_GRIEVANCE",
        entity_id: NumberInt(201) // Maps to SQL Server grievance_id (INT/BIGINT)
    },
    classification: {
        category: "TEACHER_GRIEVANCE",
        sub_category: "INCIDENT_EVIDENCE",
        attachment_type: "EVIDENCE"
    },
    file: {
        original_name: "incident_witness_statement.pdf",
        extension: ".pdf",
        mime_type: "application/pdf",
        size_bytes: NumberInt(524288),
        checksum_sha256: "b2c3d4e5f6a17890123456789abcdef0123456789abcdef0123456789abcdef0"
    },
    storage: {
        provider: "AWS_S3",
        bucket: "thinkigen-school-docs-prod",
        object_key: "schools/1/teachers/grievance/201/DOC-TG-2026-000001.pdf"
    },
    security: {
        visibility: "PRIVATE"
    },
    lifecycle: {
        status: "ACTIVE",
        deleted_at: null,
        deleted_by: null
    },
    uploaded_by: NumberInt(5001), // SQL Server user_id of the filing teacher
    updated_by: null,
    preview: null,
    processing: null,
    storage_cleanup: null,
    created_at: new Date(),
    updated_at: new Date()
};

// Upsert / idempotent insert
targetDb.thinkigen_documents.deleteMany({
    document_id: { $in: [teacherLeaveDocument.document_id, teacherGrievanceDocument.document_id] }
});

const resLeave = targetDb.thinkigen_documents.insertOne(teacherLeaveDocument);
print("Teacher Leave Document inserted successfully. _id: " + resLeave.insertedId);

const resGrievance = targetDb.thinkigen_documents.insertOne(teacherGrievanceDocument);
print("Teacher Grievance Document inserted successfully. _id: " + resGrievance.insertedId);
