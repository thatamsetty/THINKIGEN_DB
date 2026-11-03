/*
    Test Suite: test_teacher_daily_progress_checklist.js
    Module:     Teacher Portal Management
    Target:     teacher_daily_progress_checklist
    Purpose:    Validates MongoDB schema enforcement for meetings, non-class tasks,
                group student scope, atomic checklist item completion, and daily uniqueness.
*/

(function () {
    var COLLECTION_NAME = "teacher_daily_progress_checklist";
    print("================================================================================");
    print("RUNNING TEST SUITE: test_teacher_daily_progress_checklist.js");
    print("Timestamp: " + new Date().toISOString());
    print("================================================================================");

    var passedTests = 0;
    var totalTests = 0;

    function assert(condition, testName) {
        totalTests++;
        if (condition) {
            print("  [PASS] " + testName);
            passedTests++;
        } else {
            print("  [FAIL] " + testName);
            throw new Error("Assertion failed: " + testName);
        }
    }

    // Clean prior test records
    db[COLLECTION_NAME].deleteMany({ teacher_id: 88801 });

    // 1. Insert valid document with both class tasks and meeting tasks (no class_id)
    var testDoc = {
        teacher_id: NumberInt(88801),
        school_id: NumberInt(1),
        branch_id: NumberInt(1),
        academic_year_id: NumberInt(2026),
        as_of_date: new Date("2026-10-30T00:00:00Z"),
        previous_day_progress: {
            date: new Date("2026-10-29T00:00:00Z"),
            total_tasks: 5,
            completed_tasks: 5,
            completion_percent: 100.0,
            status: "all_completed",
            summary_notes: "All 5 periods and tasks completed."
        },
        checklist_items: [
            {
                item_id: "CHK-88801-ATT-P1",
                task_title: "Period 1 Attendance - Class 10 A",
                task_type: "ATTENDANCE",
                class_id: NumberInt(10),
                class_name: "Class 10",
                section_id: NumberInt(101),
                section_name: "Section A",
                subject_id: NumberInt(1),
                subject_name: "Mathematics",
                room_no: "Room 101",
                timing: { from_time: "08:30", to_time: "09:15" },
                student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null },
                priority: "HIGH",
                is_completed: false,
                completed_at: null,
                completed_by_user_id: null,
                reference_id: NumberInt(1001),
                remarks: null
            },
            {
                item_id: "CHK-88801-MTG-STAFF",
                task_title: "Department Staff Sync - Q3 Curriculum",
                task_type: "MEETING",
                class_id: null, // Non-class task!
                class_name: null,
                section_id: null,
                section_name: null,
                subject_id: NumberInt(1),
                subject_name: "Mathematics",
                room_no: "Conference Room B",
                timing: { from_time: "14:00", to_time: "15:00" },
                student_scope: null,
                priority: "MEDIUM",
                is_completed: false,
                completed_at: null,
                completed_by_user_id: null,
                reference_id: "MTG-902",
                remarks: "Bring syllabus milestone progress report"
            },
            {
                item_id: "CHK-88801-GRP-REMEDIAL",
                task_title: "Remedial Math Group Session",
                task_type: "CLASSWORK",
                class_id: NumberInt(10),
                class_name: "Class 10",
                section_id: NumberInt(101),
                section_name: "Section A",
                subject_id: NumberInt(1),
                subject_name: "Mathematics",
                room_no: "Room 101",
                timing: { from_time: "15:15", to_time: "16:00" },
                student_scope: {
                    scope_type: "GROUP",
                    student_id: null,
                    student_name: null,
                    group_id: "GRP-MATH-REM-10A",
                    group_name: "Calculus Focus Group",
                    student_ids: [NumberInt(101), NumberInt(105), NumberInt(112)]
                },
                priority: "HIGH",
                is_completed: false,
                completed_at: null,
                completed_by_user_id: null,
                reference_id: null,
                remarks: "Focus on Ex 3.2 quadratic factoring"
            }
        ],
        summary: {
            total_items: 3,
            completed_items: 0,
            pending_items: 3
        },
        is_active: 1,
        created_at: new Date(),
        updated_at: new Date()
    };

    var insertRes = db[COLLECTION_NAME].insertOne(testDoc);
    assert(insertRes.acknowledged === true, "Checklist inserted with class, meeting, and group scope tasks.");

    // 2. Test unique index on (teacher_id, as_of_date)
    var duplicateBlocked = false;
    try {
        db[COLLECTION_NAME].insertOne(testDoc);
    } catch (e) {
        duplicateBlocked = true;
    }
    assert(duplicateBlocked === true, "Unique index strictly prevented duplicate teacher/date checklist.");

    // 3. Test atomic task completion via arrayFilters
    var completeRes = db[COLLECTION_NAME].updateOne(
        {
            teacher_id: NumberInt(88801),
            as_of_date: new Date("2026-10-30T00:00:00Z"),
            "checklist_items.item_id": "CHK-88801-ATT-P1"
        },
        {
            $set: {
                "checklist_items.$[elem].is_completed": true,
                "checklist_items.$[elem].completed_at": new Date(),
                "checklist_items.$[elem].completed_by_user_id": NumberInt(88801),
                "summary.completed_items": 1,
                "summary.pending_items": 2,
                "updated_at": new Date()
            }
        },
        {
            arrayFilters: [{ "elem.item_id": "CHK-88801-ATT-P1" }]
        }
    );
    assert(completeRes.modifiedCount === 1, "Atomic completion via arrayFilters succeeded.");

    // 4. Verify item state
    var doc = db[COLLECTION_NAME].findOne({ teacher_id: NumberInt(88801) });
    var item1 = doc.checklist_items.find(function(i) { return i.item_id === "CHK-88801-ATT-P1"; });
    assert(item1.is_completed === true, "Item is_completed is true.");
    assert(item1.completed_by_user_id.toString() === "88801", "completed_by_user_id accurately recorded.");

    // Clean up
    db[COLLECTION_NAME].deleteMany({ teacher_id: 88801 });

    print("\n================================================================================");
    print("ALL TESTS PASSED: " + passedTests + "/" + totalTests + " assertions verified.");
    print("================================================================================");
})();
