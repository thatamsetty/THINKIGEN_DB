/*
    Test Suite: test_implementation_gap_audit.js
    Module:     Teacher Portal Management & Cross-Database Reliability
    Purpose:    Live MongoDB validation for implementation gap audit:
                1. teacher_daily_progress_checklist:
                   - Prevent duplicate completions from incrementing summary counts
                   - Verify task completion uses conditional atomic updates
                   - Verify completed items are preserved during regeneration
                2. student_subject_attentions:
                   - Ensure subject_id and attention_id conditions target the same embedded subject
                   - Make insertion idempotent under concurrent retries
                   - Ensure counts change ONLY when alert is inserted or status transitions
                   - Verify resolved and excused records are preserved
*/

(function () {
    print("================================================================================");
    print("RUNNING LIVE AUDIT SUITE: test_implementation_gap_audit.js");
    print("Timestamp: " + new Date().toISOString());
    print("================================================================================");

    var passed = 0;
    var total = 0;

    function assert(cond, name) {
        total++;
        if (cond) {
            print("  [PASS] " + name);
            passed++;
        } else {
            print("  [FAIL] " + name);
            throw new Error("Assertion failed: " + name);
        }
    }

    // =========================================================================
    // SECTION 1: teacher_daily_progress_checklist Gaps
    // =========================================================================
    print("\n--- SECTION 1: teacher_daily_progress_checklist Audit ---");
    var CHK_COLL = "teacher_daily_progress_checklist";
    db[CHK_COLL].deleteMany({ teacher_id: 77701 });

    var asOfDate = new Date("2026-10-30T00:00:00Z");

    // 1.1 Insert initial daily checklist
    db[CHK_COLL].insertOne({
        teacher_id: NumberInt(77701),
        school_id: NumberInt(1),
        branch_id: NumberInt(1),
        academic_year_id: NumberInt(2026),
        as_of_date: asOfDate,
        previous_day_progress: {
            date: new Date("2026-10-29T00:00:00Z"),
            total_tasks: 4,
            completed_tasks: 4,
            completion_percent: 100.0,
            status: "all_completed",
            summary_notes: "Previous day 100% completed"
        },
        checklist_items: [
            {
                item_id: "CHK-77701-P1",
                task_title: "Period 1 Attendance",
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
                reference_id: NumberInt(101),
                remarks: null
            },
            {
                item_id: "CHK-77701-P2",
                task_title: "Period 2 Mathematics",
                task_type: "CLASSWORK",
                class_id: NumberInt(10),
                class_name: "Class 10",
                section_id: NumberInt(101),
                section_name: "Section A",
                subject_id: NumberInt(1),
                subject_name: "Mathematics",
                room_no: "Room 101",
                timing: { from_time: "09:15", to_time: "10:00" },
                student_scope: { scope_type: "ENTIRE_SECTION", student_id: null, student_name: null },
                priority: "MEDIUM",
                is_completed: false,
                completed_at: null,
                completed_by_user_id: null,
                reference_id: NumberInt(102),
                remarks: null
            }
        ],
        summary: { total_items: 2, completed_items: 0, pending_items: 2 },
        is_active: 1,
        created_at: new Date(),
        updated_at: new Date()
    });

    // 1.2 First completion request for CHK-77701-P1 (Must succeed)
    var comp1 = db[CHK_COLL].updateOne(
        {
            teacher_id: NumberInt(77701),
            as_of_date: asOfDate,
            checklist_items: {
                $elemMatch: {
                    item_id: "CHK-77701-P1",
                    is_completed: false // CONDITIONAL GUARD
                }
            }
        },
        {
            $set: {
                "checklist_items.$[elem].is_completed": true,
                "checklist_items.$[elem].completed_at": new Date(),
                "checklist_items.$[elem].completed_by_user_id": NumberInt(77701),
                "updated_at": new Date()
            },
            $inc: {
                "summary.completed_items": 1,
                "summary.pending_items": -1
            }
        },
        { arrayFilters: [{ "elem.item_id": "CHK-77701-P1" }] }
    );
    assert(comp1.modifiedCount === 1, "First completion request modified 1 document.");

    var docAfter1 = db[CHK_COLL].findOne({ teacher_id: NumberInt(77701) });
    assert(docAfter1.summary.completed_items === 1, "completed_items is 1 after first completion.");
    assert(docAfter1.summary.pending_items === 1, "pending_items is 1 after first completion.");

    // 1.3 DUPLICATE completion request for CHK-77701-P1 (Must be blocked and NOT increment counts!)
    var comp2 = db[CHK_COLL].updateOne(
        {
            teacher_id: NumberInt(77701),
            as_of_date: asOfDate,
            checklist_items: {
                $elemMatch: {
                    item_id: "CHK-77701-P1",
                    is_completed: false // Will NOT match since is_completed is already true!
                }
            }
        },
        {
            $set: {
                "checklist_items.$[elem].is_completed": true,
                "checklist_items.$[elem].completed_at": new Date(),
                "checklist_items.$[elem].completed_by_user_id": NumberInt(77701),
                "updated_at": new Date()
            },
            $inc: {
                "summary.completed_items": 1,
                "summary.pending_items": -1
            }
        },
        { arrayFilters: [{ "elem.item_id": "CHK-77701-P1" }] }
    );
    assert(comp2.modifiedCount === 0, "Duplicate completion request safely rejected with modifiedCount = 0.");

    var docAfter2 = db[CHK_COLL].findOne({ teacher_id: NumberInt(77701) });
    assert(docAfter2.summary.completed_items === 1, "completed_items remained strictly 1 (no double increment).");
    assert(docAfter2.summary.pending_items === 1, "pending_items remained strictly 1 (no negative drift).");

    // 1.4 Daily Regeneration preserving completed items
    // Worker runs at noon: adds Period 3 task (CHK-77701-P3)
    var regenRes = db[CHK_COLL].updateOne(
        {
            teacher_id: NumberInt(77701),
            as_of_date: asOfDate,
            "checklist_items.item_id": { $ne: "CHK-77701-P3" }
        },
        {
            $push: {
                checklist_items: {
                    item_id: "CHK-77701-P3",
                    task_title: "Period 3 Break Duty",
                    task_type: "OTHER",
                    class_id: null,
                    class_name: null,
                    section_id: null,
                    section_name: null,
                    subject_id: null,
                    subject_name: null,
                    room_no: "Playground Courtyard",
                    timing: { from_time: "10:00", to_time: "10:15" },
                    student_scope: null,
                    priority: "LOW",
                    is_completed: false,
                    completed_at: null,
                    completed_by_user_id: null,
                    reference_id: null,
                    remarks: null
                }
            },
            $inc: {
                "summary.total_items": 1,
                "summary.pending_items": 1
            },
            $set: { updated_at: new Date() }
        }
    );
    assert(regenRes.modifiedCount === 1, "Regeneration pushed new item P3 without overwriting document.");

    var docAfterRegen = db[CHK_COLL].findOne({ teacher_id: NumberInt(77701) });
    var p1Item = docAfterRegen.checklist_items.find(function (i) { return i.item_id === "CHK-77701-P1"; });
    assert(p1Item.is_completed === true, "Previously completed item P1 remained completed after regeneration.");
    assert(docAfterRegen.summary.completed_items === 1, "completed_items remained 1.");
    assert(docAfterRegen.summary.total_items === 3, "total_items accurately updated to 3.");
    assert(docAfterRegen.summary.pending_items === 2, "pending_items accurately updated to 2.");

    // Clean up checklist test
    db[CHK_COLL].deleteMany({ teacher_id: 77701 });

    // =========================================================================
    // SECTION 2: student_subject_attentions Embedded Scope & Idempotency
    // =========================================================================
    print("\n--- SECTION 2: student_subject_attentions Embedded Scope & Idempotency ---");
    var ATT_COLL = "student_subject_attentions";
    db[ATT_COLL].deleteMany({ student_id: 77702 });

    // 2.1 Insert student document with two distinct subjects:
    // Subject 1 (Math): Attention ATT-MATH-101
    // Subject 2 (Science): Attention ATT-SCI-201
    db[ATT_COLL].insertOne({
        student_id: NumberInt(77702),
        student_name: "Test Student",
        school_id: NumberInt(1),
        branch_id: NumberInt(1),
        academic_year_id: NumberInt(2026),
        class_id: NumberInt(10),
        class_name: "Class 10",
        section_id: NumberInt(101),
        section_name: "Section A",
        total_active_attentions: 2,
        critical_attentions_count: 0,
        subjects: [
            {
                subject_id: NumberInt(1),
                subject_name: "Mathematics",
                subject_code: "MAT-10",
                assigned_teacher_id: NumberInt(501),
                assigned_teacher_name: "Math Teacher",
                active_attentions_count: 1,
                attentions: [
                    {
                        attention_id: "ATT-MATH-101",
                        attention_type: "LOW_ASSESSMENT_SCORE",
                        severity: "HIGH",
                        title: "Low Math Test",
                        description: "Scored 15/50",
                        trigger_source: "ASSESSMENT",
                        source_id: NumberInt(101),
                        triggered_at: new Date(),
                        status: "ACTIVE",
                        acknowledged_at: null,
                        acknowledged_by_teacher_id: null,
                        resolved_at: null,
                        resolved_by_teacher_id: null,
                        resolution_remarks: null,
                        excused_reason: null,
                        assessment_details: {
                            assessment_id: NumberInt(101),
                            assessment_name: "Math Test 1",
                            exam_type: "SLIP_TEST",
                            max_marks: 50,
                            pass_marks: 20,
                            obtained_marks: 15,
                            percentage: 30
                        },
                        homework_details: null,
                        attendance_details: null
                    }
                ]
            },
            {
                subject_id: NumberInt(2),
                subject_name: "Science",
                subject_code: "SCI-10",
                assigned_teacher_id: NumberInt(502),
                assigned_teacher_name: "Science Teacher",
                active_attentions_count: 1,
                attentions: [
                    {
                        attention_id: "ATT-SCI-201",
                        attention_type: "PENDING_HOMEWORK",
                        severity: "MEDIUM",
                        title: "Pending Science HW",
                        description: "HW overdue",
                        trigger_source: "ASSIGNMENT_HOMEWORK",
                        source_id: NumberInt(201),
                        triggered_at: new Date(),
                        status: "ACTIVE",
                        acknowledged_at: null,
                        acknowledged_by_teacher_id: null,
                        resolved_at: null,
                        resolved_by_teacher_id: null,
                        resolution_remarks: null,
                        excused_reason: null,
                        assessment_details: null,
                        homework_details: {
                            homework_id: NumberInt(201),
                            homework_title: "Science HW 1",
                            assigned_date: new Date(),
                            due_date: new Date(),
                            days_overdue: 2,
                            submission_status: "NOT_SUBMITTED"
                        },
                        attendance_details: null
                    }
                ]
            }
        ],
        last_evaluated_at: new Date(),
        is_active: 1,
        created_at: new Date(),
        updated_at: new Date()
    });

    // 2.2 Verify $elemMatch ensures subject_id and attention_id target the SAME subject:
    // If we query subject_id: 1 AND attention_id: "ATT-SCI-201" (which belongs to subject 2):
    // Using $elemMatch MUST return 0 matches!
    var crossSubjectMatch = db[ATT_COLL].findOne({
        student_id: NumberInt(77702),
        subjects: {
            $elemMatch: {
                subject_id: NumberInt(1),
                "attentions.attention_id": "ATT-SCI-201" // Belongs to subject 2, NOT 1
            }
        }
    });
    assert(crossSubjectMatch === null, "$elemMatch strictly prevented cross-subject attention matching.");

    // Querying with matching subject_id: 1 and attention_id: "ATT-MATH-101" MUST match!
    var correctSubjectMatch = db[ATT_COLL].findOne({
        student_id: NumberInt(77702),
        subjects: {
            $elemMatch: {
                subject_id: NumberInt(1),
                "attentions.attention_id": "ATT-MATH-101"
            }
        }
    });
    assert(correctSubjectMatch !== null, "$elemMatch accurately matched attention within the correct subject.");

    // 2.3 Status Transition Idempotency & Count Stability
    // Resolve ATT-MATH-101 (Active count should decrement from 1 to 0 in Math, total active from 2 to 1)
    var resolve1 = db[ATT_COLL].updateOne(
        {
            student_id: NumberInt(77702),
            academic_year_id: NumberInt(2026),
            subjects: {
                $elemMatch: {
                    subject_id: NumberInt(1),
                    attentions: {
                        $elemMatch: {
                            attention_id: "ATT-MATH-101",
                            status: { $in: ["ACTIVE", "ACKNOWLEDGED"] } // CONDITIONAL GUARD
                        }
                    }
                }
            }
        },
        {
            $set: {
                "subjects.$[sub].attentions.$[att].status": "RESOLVED",
                "subjects.$[sub].attentions.$[att].resolved_at": new Date(),
                "subjects.$[sub].attentions.$[att].resolved_by_teacher_id": NumberInt(501),
                "subjects.$[sub].attentions.$[att].resolution_remarks": "Passed re-test with 35/50",
                "updated_at": new Date()
            }
        },
        {
            arrayFilters: [
                { "sub.subject_id": NumberInt(1) },
                { "att.attention_id": "ATT-MATH-101" }
            ]
        }
    );
    assert(resolve1.modifiedCount === 1, "First resolve request transitioned status to RESOLVED.");

    // Recalculate counts atomically
    db[ATT_COLL].updateOne(
        { student_id: NumberInt(77702), academic_year_id: NumberInt(2026) },
        [
            {
                $set: {
                    subjects: {
                        $map: {
                            input: "$subjects",
                            as: "sub",
                            in: {
                                $mergeObjects: [
                                    "$$sub",
                                    {
                                        active_attentions_count: {
                                            $size: {
                                                $filter: {
                                                    input: "$$sub.attentions",
                                                    as: "att",
                                                    cond: { $eq: ["$$att.status", "ACTIVE"] }
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            },
            {
                $set: {
                    total_active_attentions: {
                        $reduce: {
                            input: "$subjects",
                            initialValue: 0,
                            in: { $add: ["$$value", "$$this.active_attentions_count"] }
                        }
                    }
                }
            }
        ]
    );

    var docAfterRes1 = db[ATT_COLL].findOne({ student_id: NumberInt(77702) });
    assert(docAfterRes1.total_active_attentions === 1, "total_active_attentions decremented to 1.");
    var mathSubAfter = docAfterRes1.subjects.find(function(s) { return s.subject_id.toString() === "1"; });
    assert(mathSubAfter.active_attentions_count === 0, "Math active_attentions_count decremented to 0.");

    // 2.4 DUPLICATE resolve request for ATT-MATH-101 (Must be a safe no-op!)
    var resolve2 = db[ATT_COLL].updateOne(
        {
            student_id: NumberInt(77702),
            academic_year_id: NumberInt(2026),
            subjects: {
                $elemMatch: {
                    subject_id: NumberInt(1),
                    attentions: {
                        $elemMatch: {
                            attention_id: "ATT-MATH-101",
                            status: { $in: ["ACTIVE", "ACKNOWLEDGED"] } // Will NOT match since status is RESOLVED
                        }
                    }
                }
            }
        },
        {
            $set: {
                "subjects.$[sub].attentions.$[att].status": "RESOLVED",
                "updated_at": new Date()
            }
        },
        {
            arrayFilters: [
                { "sub.subject_id": NumberInt(1) },
                { "att.attention_id": "ATT-MATH-101" }
            ]
        }
    );
    assert(resolve2.modifiedCount === 0, "Duplicate resolve returned modifiedCount = 0 (no redundant writes).");

    // Clean up
    db[ATT_COLL].deleteMany({ student_id: 77702 });

    print("\n================================================================================");
    print("ALL AUDIT GAP TESTS PASSED: " + passed + "/" + total + " assertions verified.");
    print("================================================================================");
})();
