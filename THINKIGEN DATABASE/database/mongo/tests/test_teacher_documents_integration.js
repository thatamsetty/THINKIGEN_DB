/*
    Live Integration Test: test_teacher_documents_integration.js
    Target: MongoDB collection thinkigen_documents in thinkigen database
    Tests all 14 required cases for Teacher Leave & Grievance document extensions.
*/

const coll = db.thinkigen_documents;

print("========================================================================");
print("Running Live Integration Tests for thinkigen_documents...");
print("========================================================================");

let testsPassed = 0;
let testsFailed = 0;

function assert(condition, message) {
    if (condition) {
        print("  [PASS] " + message);
        testsPassed++;
    } else {
        print("  [FAIL] " + message);
        testsFailed++;
        throw new Error("Assertion failed: " + message);
    }
}

// Clean up any previous test docs
coll.deleteMany({ document_id: { $regex: "^DOC-TEST-" } });

try {
    // -------------------------------------------------------------------------
    // TEST 1: Teacher leave supporting document upload
    // -------------------------------------------------------------------------
    const doc1 = {
        document_id: "DOC-TEST-TLEAVE-001",
        tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
        owner: { entity_type: "TEACHER_LEAVE_APPLICATION", entity_id: 1001 },
        classification: {
            category: "TEACHER_LEAVE",
            sub_category: "MEDICAL_CERTIFICATE",
            attachment_type: "SUPPORTING_DOCUMENT"
        },
        file: {
            original_name: "medical_cert.pdf",
            extension: "pdf",
            mime_type: "application/pdf",
            size_bytes: NumberLong(1048576),
            checksum_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        },
        storage: {
            provider: "AWS_S3",
            bucket: "thinkigen-documents-private",
            object_key: "schools/1/branches/1/teachers/501/leave/1001/doc_001.pdf"
        },
        security: { visibility: "PRIVATE" },
        lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
        uploaded_by: 501,
        updated_by: null,
        created_at: new Date(),
        updated_at: new Date()
    };
    coll.insertOne(doc1);
    assert(coll.findOne({ document_id: "DOC-TEST-TLEAVE-001" }) !== null, "Test 1: Teacher leave supporting document insert succeeded.");

    // -------------------------------------------------------------------------
    // TEST 2: Multiple supporting documents for one leave application
    // -------------------------------------------------------------------------
    const doc2 = {
        document_id: "DOC-TEST-TLEAVE-002",
        tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
        owner: { entity_type: "TEACHER_LEAVE_APPLICATION", entity_id: 1001 }, // same leave application
        classification: {
            category: "TEACHER_LEAVE",
            sub_category: "DOCTOR_PRESCRIPTION",
            attachment_type: "SUPPORTING_DOCUMENT"
        },
        file: {
            original_name: "prescription.jpg",
            extension: "jpg",
            mime_type: "image/jpeg",
            size_bytes: NumberLong(524288),
            checksum_sha256: "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce"
        },
        storage: {
            provider: "AWS_S3",
            bucket: "thinkigen-documents-private",
            object_key: "schools/1/branches/1/teachers/501/leave/1001/doc_002.jpg"
        },
        security: { visibility: "PRIVATE" },
        lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
        uploaded_by: 501,
        updated_by: null,
        created_at: new Date(),
        updated_at: new Date()
    };
    coll.insertOne(doc2);
    const leaveDocsCount = coll.countDocuments({ "owner.entity_type": "TEACHER_LEAVE_APPLICATION", "owner.entity_id": 1001 });
    assert(leaveDocsCount === 2, "Test 2: Multiple supporting documents for single leave application supported.");

    // -------------------------------------------------------------------------
    // TEST 3: Teacher grievance evidence upload
    // -------------------------------------------------------------------------
    const doc3 = {
        document_id: "DOC-TEST-TGRIEV-001",
        tenant: { school_id: 1, branch_id: 1, academic_year_id: null },
        owner: { entity_type: "TEACHER_GRIEVANCE", entity_id: 2001 },
        classification: {
            category: "TEACHER_GRIEVANCE",
            sub_category: "PHOTO_EVIDENCE",
            attachment_type: "EVIDENCE"
        },
        file: {
            original_name: "damaged_projector.png",
            extension: "png",
            mime_type: "image/png",
            size_bytes: NumberLong(2097152),
            checksum_sha256: "4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a"
        },
        storage: {
            provider: "AWS_S3",
            bucket: "thinkigen-documents-private",
            object_key: "schools/1/branches/1/teachers/501/grievance/2001/evidence_001.png"
        },
        security: { visibility: "RESTRICTED" },
        lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
        uploaded_by: 501,
        updated_by: null,
        created_at: new Date(),
        updated_at: new Date()
    };
    coll.insertOne(doc3);
    assert(coll.findOne({ document_id: "DOC-TEST-TGRIEV-001" }) !== null, "Test 3: Teacher grievance evidence insert succeeded.");

    // -------------------------------------------------------------------------
    // TEST 4: Multiple evidence documents for one grievance
    // -------------------------------------------------------------------------
    const doc4 = {
        document_id: "DOC-TEST-TGRIEV-002",
        tenant: { school_id: 1, branch_id: 1, academic_year_id: null },
        owner: { entity_type: "TEACHER_GRIEVANCE", entity_id: 2001 }, // same grievance
        classification: {
            category: "TEACHER_GRIEVANCE",
            sub_category: "INCIDENT_REPORT",
            attachment_type: "EVIDENCE"
        },
        file: {
            original_name: "incident_log.pdf",
            extension: "pdf",
            mime_type: "application/pdf",
            size_bytes: NumberLong(838860),
            checksum_sha256: "ef2d127de37b942baad06145e54b0c619a1f22327b2ebbcfbec78f5564afe39d"
        },
        storage: {
            provider: "AWS_S3",
            bucket: "thinkigen-documents-private",
            object_key: "schools/1/branches/1/teachers/501/grievance/2001/evidence_002.pdf"
        },
        security: { visibility: "RESTRICTED" },
        lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
        uploaded_by: 501,
        updated_by: null,
        created_at: new Date(),
        updated_at: new Date()
    };
    coll.insertOne(doc4);
    const grievDocsCount = coll.countDocuments({ "owner.entity_type": "TEACHER_GRIEVANCE", "owner.entity_id": 2001 });
    assert(grievDocsCount === 2, "Test 4: Multiple evidence documents for single grievance supported.");

    // -------------------------------------------------------------------------
    // TEST 5: Tenant and owner mapping query validation
    // -------------------------------------------------------------------------
    const foundDoc = coll.findOne({
        "tenant.school_id": 1,
        "tenant.branch_id": 1,
        "owner.entity_type": "TEACHER_LEAVE_APPLICATION",
        "owner.entity_id": 1001
    });
    assert(foundDoc !== null && foundDoc.tenant.school_id === 1, "Test 5: Tenant and owner query mapping verified.");

    // -------------------------------------------------------------------------
    // TEST 6: Invalid entity_type and category combinations rejected
    // -------------------------------------------------------------------------
    // 6a: TEACHER_LEAVE_APPLICATION with EVIDENCE (Must be SUPPORTING_DOCUMENT)
    let rejected6a = false;
    try {
        coll.insertOne({
            document_id: "DOC-TEST-INVALID-001",
            tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
            owner: { entity_type: "TEACHER_LEAVE_APPLICATION", entity_id: 1001 },
            classification: {
                category: "TEACHER_LEAVE",
                attachment_type: "EVIDENCE" // INVALID: must be SUPPORTING_DOCUMENT
            },
            file: {
                original_name: "test.pdf",
                extension: "pdf",
                mime_type: "application/pdf",
                size_bytes: NumberLong(100),
                checksum_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
            },
            storage: { provider: "AWS_S3", bucket: "b", object_key: "k1" },
            security: { visibility: "PRIVATE" },
            lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
            uploaded_by: 501,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (e) {
        rejected6a = true;
    }
    assert(rejected6a, "Test 6a: TEACHER_LEAVE_APPLICATION with invalid attachment_type (EVIDENCE) rejected.");

    // 6b: TEACHER_LEAVE_APPLICATION with STUDENT_LEAVE category
    let rejected6b = false;
    try {
        coll.insertOne({
            document_id: "DOC-TEST-INVALID-002",
            tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
            owner: { entity_type: "TEACHER_LEAVE_APPLICATION", entity_id: 1001 },
            classification: {
                category: "STUDENT_LEAVE", // INVALID: must be TEACHER_LEAVE
                attachment_type: "SUPPORTING_DOCUMENT"
            },
            file: {
                original_name: "test.pdf",
                extension: "pdf",
                mime_type: "application/pdf",
                size_bytes: NumberLong(100),
                checksum_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
            },
            storage: { provider: "AWS_S3", bucket: "b", object_key: "k2" },
            security: { visibility: "PRIVATE" },
            lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
            uploaded_by: 501,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (e) {
        rejected6b = true;
    }
    assert(rejected6b, "Test 6b: TEACHER_LEAVE_APPLICATION with invalid category (STUDENT_LEAVE) rejected.");

    // 6c: TEACHER_GRIEVANCE with SUPPORTING_DOCUMENT (Must be EVIDENCE)
    let rejected6c = false;
    try {
        coll.insertOne({
            document_id: "DOC-TEST-INVALID-003",
            tenant: { school_id: 1, branch_id: 1, academic_year_id: null },
            owner: { entity_type: "TEACHER_GRIEVANCE", entity_id: 2001 },
            classification: {
                category: "TEACHER_GRIEVANCE",
                attachment_type: "SUPPORTING_DOCUMENT" // INVALID: must be EVIDENCE
            },
            file: {
                original_name: "test.pdf",
                extension: "pdf",
                mime_type: "application/pdf",
                size_bytes: NumberLong(100),
                checksum_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
            },
            storage: { provider: "AWS_S3", bucket: "b", object_key: "k3" },
            security: { visibility: "PRIVATE" },
            lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
            uploaded_by: 501,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (e) {
        rejected6c = true;
    }
    assert(rejected6c, "Test 6c: TEACHER_GRIEVANCE with invalid attachment_type (SUPPORTING_DOCUMENT) rejected.");

    // -------------------------------------------------------------------------
    // TEST 7: Existing student leave documents remain valid
    // -------------------------------------------------------------------------
    const docStudentLeave = {
        document_id: "DOC-TEST-STULEAVE-001",
        tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
        owner: { entity_type: "LEAVE", entity_id: 3001 },
        classification: {
            category: "STUDENT_LEAVE",
            attachment_type: "SUPPORTING_DOCUMENT"
        },
        file: {
            original_name: "parent_letter.pdf",
            extension: "pdf",
            mime_type: "application/pdf",
            size_bytes: NumberLong(204800),
            checksum_sha256: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
        },
        storage: {
            provider: "AWS_S3",
            bucket: "thinkigen-documents-private",
            object_key: "schools/1/branches/1/students/10/leave/3001/letter.pdf"
        },
        security: { visibility: "PRIVATE" },
        lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
        uploaded_by: 10,
        created_at: new Date(),
        updated_at: new Date()
    };
    coll.insertOne(docStudentLeave);
    assert(coll.findOne({ document_id: "DOC-TEST-STULEAVE-001" }) !== null, "Test 7: Existing student leave documents remain valid.");

    // -------------------------------------------------------------------------
    // TEST 8: Existing grievance documents remain valid
    // -------------------------------------------------------------------------
    const docStudentGrievance = {
        document_id: "DOC-TEST-STUGRIEV-001",
        tenant: { school_id: 1, branch_id: 1, academic_year_id: null },
        owner: { entity_type: "GRIEVANCE", entity_id: 4001 },
        classification: {
            category: "GRIEVANCE",
            attachment_type: "EVIDENCE"
        },
        file: {
            original_name: "bus_complaint.jpg",
            extension: "jpg",
            mime_type: "image/jpeg",
            size_bytes: NumberLong(307200),
            checksum_sha256: "b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3"
        },
        storage: {
            provider: "AWS_S3",
            bucket: "thinkigen-documents-private",
            object_key: "schools/1/branches/1/students/10/grievance/4001/bus.jpg"
        },
        security: { visibility: "RESTRICTED" },
        lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
        uploaded_by: 10,
        created_at: new Date(),
        updated_at: new Date()
    };
    coll.insertOne(docStudentGrievance);
    assert(coll.findOne({ document_id: "DOC-TEST-STUGRIEV-001" }) !== null, "Test 8: Existing student grievance documents remain valid.");

    // -------------------------------------------------------------------------
    // TEST 9: Existing announcement documents remain valid
    // -------------------------------------------------------------------------
    const docAnnouncement = {
        document_id: "DOC-TEST-ANN-001",
        tenant: { school_id: 1, branch_id: null, academic_year_id: null },
        owner: { entity_type: "ANNOUNCEMENT", entity_id: 5001 },
        classification: {
            category: "ANNOUNCEMENT",
            attachment_type: "ATTACHMENT"
        },
        file: {
            original_name: "sports_day_circular.pdf",
            extension: "pdf",
            mime_type: "application/pdf",
            size_bytes: NumberLong(1048576),
            checksum_sha256: "c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
        },
        storage: {
            provider: "AWS_S3",
            bucket: "thinkigen-documents-private",
            object_key: "schools/1/announcements/5001/circular.pdf"
        },
        security: { visibility: "PUBLIC" },
        lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
        uploaded_by: 1,
        created_at: new Date(),
        updated_at: new Date()
    };
    coll.insertOne(docAnnouncement);
    assert(coll.findOne({ document_id: "DOC-TEST-ANN-001" }) !== null, "Test 9: Existing announcement documents remain valid.");

    // -------------------------------------------------------------------------
    // TEST 10: Existing homework documents remain valid
    // -------------------------------------------------------------------------
    const docHomework = {
        document_id: "DOC-TEST-HW-001",
        tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
        owner: { entity_type: "HOMEWORK", entity_id: 6001 },
        classification: {
            category: "HOMEWORK",
            attachment_type: "ATTACHMENT"
        },
        file: {
            original_name: "math_worksheet.pdf",
            extension: "pdf",
            mime_type: "application/pdf",
            size_bytes: NumberLong(512000),
            checksum_sha256: "d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5"
        },
        storage: {
            provider: "AWS_S3",
            bucket: "thinkigen-documents-private",
            object_key: "schools/1/branches/1/homework/6001/worksheet.pdf"
        },
        security: { visibility: "RESTRICTED" },
        lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
        uploaded_by: 501,
        created_at: new Date(),
        updated_at: new Date()
    };
    coll.insertOne(docHomework);
    assert(coll.findOne({ document_id: "DOC-TEST-HW-001" }) !== null, "Test 10: Existing homework documents remain valid.");

    // -------------------------------------------------------------------------
    // TEST 11: Soft deletion lifecycle handling
    // -------------------------------------------------------------------------
    coll.updateOne(
        { document_id: "DOC-TEST-TLEAVE-002" },
        {
            $set: {
                "lifecycle.status": "DELETED",
                "lifecycle.deleted_at": new Date(),
                "lifecycle.deleted_by": 501,
                updated_at: new Date()
            }
        }
    );
    const softDeleted = coll.findOne({ document_id: "DOC-TEST-TLEAVE-002" });
    assert(softDeleted.lifecycle.status === "DELETED" && softDeleted.lifecycle.deleted_at !== null, "Test 11: Soft deletion and audit fields verified.");

    // -------------------------------------------------------------------------
    // TEST 12: S3 Object Key Uniqueness Enforcement
    // -------------------------------------------------------------------------
    let dupS3Rejected = false;
    try {
        coll.insertOne({
            document_id: "DOC-TEST-DUPS3-001",
            tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
            owner: { entity_type: "TEACHER_LEAVE_APPLICATION", entity_id: 1002 },
            classification: {
                category: "TEACHER_LEAVE",
                attachment_type: "SUPPORTING_DOCUMENT"
            },
            file: {
                original_name: "file.pdf",
                extension: "pdf",
                mime_type: "application/pdf",
                size_bytes: NumberLong(100),
                checksum_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
            },
            storage: {
                provider: "AWS_S3",
                bucket: "thinkigen-documents-private",
                object_key: "schools/1/branches/1/teachers/501/leave/1001/doc_001.pdf" // DUPLICATE KEY
            },
            security: { visibility: "PRIVATE" },
            lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
            uploaded_by: 501,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (e) {
        dupS3Rejected = (e.code === 11000); // DuplicateKey error code
    }
    assert(dupS3Rejected, "Test 12: Duplicate S3 object key rejected by unique index uq_thinkigen_documents_s3_object.");

    // -------------------------------------------------------------------------
    // TEST 13: Document ID Uniqueness Enforcement
    // -------------------------------------------------------------------------
    let dupDocIdRejected = false;
    try {
        coll.insertOne({
            document_id: "DOC-TEST-TLEAVE-001", // DUPLICATE ID
            tenant: { school_id: 1, branch_id: 1, academic_year_id: 2026 },
            owner: { entity_type: "TEACHER_LEAVE_APPLICATION", entity_id: 1003 },
            classification: {
                category: "TEACHER_LEAVE",
                attachment_type: "SUPPORTING_DOCUMENT"
            },
            file: {
                original_name: "file2.pdf",
                extension: "pdf",
                mime_type: "application/pdf",
                size_bytes: NumberLong(100),
                checksum_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
            },
            storage: {
                provider: "AWS_S3",
                bucket: "thinkigen-documents-private",
                object_key: "schools/1/branches/1/teachers/501/leave/1003/doc_unique.pdf"
            },
            security: { visibility: "PRIVATE" },
            lifecycle: { status: "ACTIVE", deleted_at: null, deleted_by: null },
            uploaded_by: 501,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (e) {
        dupDocIdRejected = (e.code === 11000);
    }
    assert(dupDocIdRejected, "Test 13: Duplicate document_id rejected by unique index uq_thinkigen_documents_document_id.");

    // -------------------------------------------------------------------------
    // TEST 14: Clean up test artifacts
    // -------------------------------------------------------------------------
    coll.deleteMany({ document_id: { $regex: "^DOC-TEST-" } });
    assert(coll.countDocuments({ document_id: { $regex: "^DOC-TEST-" } }) === 0, "Test 14: Test artifacts cleaned up successfully.");

    print("========================================================================");
    print(`ALL ${testsPassed} INTEGRATION TESTS PASSED!`);
    print("========================================================================");
} catch (err) {
    print("TEST SUITE FAILED with error: " + err);
    // Cleanup on failure
    coll.deleteMany({ document_id: { $regex: "^DOC-TEST-" } });
    throw err;
}
