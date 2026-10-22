/**
 * ==============================================================================
 * MongoDB Script: Find and Remove Learning Resources for Subjects 1, 2, 4, 5, 6
 * Target Collection : Learning_resource(documents)
 * Scope             : Subjects 1, 2, 4, 5, 6
 * Safety Rule       : Subject 3 (Science) is strictly preserved and NEVER deleted.
 *
 * Usage:
 *   mongosh "<connection_string>/<database>" find_and_remove_learning_resources_subjects_1_2_4_5_6.js
 * ==============================================================================
 */

(function () {
    "use strict";

    const targetCollectionName = "Learning_resource(documents)";
    const col = db.getCollection(targetCollectionName);

    print(`\n==============================================================================`);
    print(`Target Collection : ${targetCollectionName}`);
    print(`Operation         : Find & Remove for Subjects 1, 2, 4, 5, 6`);
    print(`Protection        : Subject 3 (Science) is strictly PRESERVED`);
    print(`==============================================================================\n`);

    // Target filter: Subjects 1, 2, 4, 5, 6 (handling both NumberInt and standard int)
    const targetFilter = {
        subject_id: {
            $in: [1, 2, 4, 5, 6, NumberInt(1), NumberInt(2), NumberInt(4), NumberInt(5), NumberInt(6)],
            $ne: NumberInt(3) // Extra explicit safeguard for Science
        }
    };

    // 1. FIND & COUNT BEFORE REMOVAL
    print("--- STEP 1: AUDIT BEFORE REMOVAL ---");
    const countToRemove = col.countDocuments(targetFilter);
    print(`Documents found matching subjects 1, 2, 4, 5, 6: ${countToRemove}`);

    const scienceCountBefore = col.countDocuments({
        subject_id: { $in: [3, NumberInt(3)] }
    });
    print(`Science (Subject 3) documents currently in collection: ${scienceCountBefore}`);

    // Breakdown before deletion
    const breakdownBefore = col.aggregate([
        {
            $group: {
                _id: "$subject_id",
                count: { $sum: 1 }
            }
        },
        { $sort: { _id: 1 } }
    ]).toArray();

    print("\nCurrent breakdown by subject_id:");
    breakdownBefore.forEach((item) => {
        const isScience = (item._id === 3);
        print(`  - subject_id [${item._id}]: ${item.count} documents ${isScience ? "(Science - SAFE)" : "(Will be removed)"}`);
    });

    if (countToRemove === 0) {
        print("\nNo documents found for subjects 1, 2, 4, 5, 6. Nothing to delete.");
        return;
    }

    // 2. REMOVE DOCUMENTS FOR SUBJECTS 1, 2, 4, 5, 6
    print("\n--- STEP 2: REMOVING DOCUMENTS ---");
    const deleteResult = col.deleteMany(targetFilter);
    print(`Deleted count: ${deleteResult.deletedCount}`);

    // 3. FIND & VERIFY AFTER REMOVAL
    print("\n--- STEP 3: AUDIT AFTER REMOVAL ---");
    const remainingTargetCount = col.countDocuments(targetFilter);
    print(`Remaining documents for subjects 1, 2, 4, 5, 6: ${remainingTargetCount}`);

    const scienceCountAfter = col.countDocuments({
        subject_id: { $in: [3, NumberInt(3)] }
    });
    print(`Science (Subject 3) documents remaining: ${scienceCountAfter} (Untouched: ${scienceCountBefore === scienceCountAfter ? "YES ✓" : "NO ⚠️"})`);

    const breakdownAfter = col.aggregate([
        {
            $group: {
                _id: "$subject_id",
                count: { $sum: 1 }
            }
        },
        { $sort: { _id: 1 } }
    ]).toArray();

    print("\nFinal collection breakdown by subject_id:");
    if (breakdownAfter.length === 0) {
        print("  (Collection is empty)");
    } else {
        breakdownAfter.forEach((item) => {
            print(`  - subject_id [${item._id}]: ${item.count} documents`);
        });
    }

    print(`\n==============================================================================`);
    print(`Operation complete. Removed ${deleteResult.deletedCount} documents.`);
    print(`==============================================================================\n`);
})();
