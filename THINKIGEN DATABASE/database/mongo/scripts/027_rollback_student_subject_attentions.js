/*
    Rollback Script:  027_rollback_student_subject_attentions.js
    Module:           Teacher Portal Management & Student Academic Health
    Target:           student_subject_attentions
    Purpose:          Rolls back indexes and JSON schema validator to the original baseline
                      without deleting or corrupting student attention data.
*/

(function () {
    var COLLECTION_NAME = "student_subject_attentions";
    print("================================================================================");
    print("STARTING ROLLBACK: 027_rollback_student_subject_attentions");
    print("Timestamp: " + new Date().toISOString());
    print("================================================================================");

    var collections = db.getCollectionNames();
    if (!collections.includes(COLLECTION_NAME)) {
        print("[ROLLBACK] Collection " + COLLECTION_NAME + " does not exist. Nothing to roll back.");
        return;
    }

    // 1. REVERT INDEXES TO ORIGINAL DEFINITIONS
    var originalIndexes = [
        {
            key: { student_id: 1, academic_year_id: 1 },
            options: { unique: true, name: "uq_student_subject_attentions_year" }
        },
        {
            key: { school_id: 1, branch_id: 1, class_id: 1, section_id: 1, academic_year_id: 1 },
            options: { name: "ix_student_attentions_scope" }
        },
        {
            key: { "subjects.assigned_teacher_id": 1, "subjects.active_attentions_count": 1 },
            options: { name: "ix_student_attentions_teacher" }
        },
        {
            key: { "subjects.attentions.status": 1, "subjects.attentions.attention_type": 1 },
            options: { name: "ix_student_attentions_status_type" }
        },
        {
            key: { section_id: 1, total_active_attentions: 1 },
            options: { name: "ix_student_attentions_section_total" }
        }
    ];

    originalIndexes.forEach(function (orig) {
        var existing = db[COLLECTION_NAME].getIndexes().find(function (e) {
            return e.name === orig.options.name;
        });

        if (existing) {
            var keysMatch = JSON.stringify(existing.key) === JSON.stringify(orig.key);
            if (!keysMatch) {
                print("[ROLLBACK] Reverting index: " + orig.options.name);
                db[COLLECTION_NAME].dropIndex(orig.options.name);
                db[COLLECTION_NAME].createIndex(orig.key, orig.options);
                print("[ROLLBACK] Restored original index: " + orig.options.name);
            } else {
                print("[ROLLBACK] Index " + orig.options.name + " matches original definition.");
            }
        } else {
            db[COLLECTION_NAME].createIndex(orig.key, orig.options);
            print("[ROLLBACK] Re-created original index: " + orig.options.name);
        }
    });

    // 2. REVERT SCHEMA VALIDATOR (Relax to moderate or baseline schema)
    // We retain schema validity to protect existing documents
    print("[ROLLBACK] Reverting collMod validation level to moderate...");
    db.runCommand({
        collMod: COLLECTION_NAME,
        validationLevel: "moderate"
    });

    print("\n[VERIFICATION] Final indexes after rollback:");
    db[COLLECTION_NAME].getIndexes().forEach(function (idx) {
        print("  - " + idx.name + ": " + JSON.stringify(idx.key));
    });

    print("\n================================================================================");
    print("ROLLBACK COMPLETED SUCCESSFULLY FOR " + COLLECTION_NAME);
    print("================================================================================");
})();
