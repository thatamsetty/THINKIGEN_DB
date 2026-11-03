/*
    Test Suite: test_student_subject_attentions_integration.js
    Module:     Teacher Portal Management & Student Academic Health
    Target:     student_subject_attentions
    Purpose:    Validates MongoDB schema enforcement, index behavior, duplicate prevention,
                count calculation accuracy, status lifecycle transitions, and dashboard queries.
*/

(function () {
    var COLLECTION_NAME = "student_subject_attentions";
    print("================================================================================");
    print("RUNNING TEST SUITE: test_student_subject_attentions_integration.js");
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

    // Clean any prior test documents
    db[COLLECTION_NAME].deleteMany({ student_id: { $in: [99901, 99902] } });

    // -------------------------------------------------------------------------
    // TEST 1: Insert Valid Realistic Production Document
    // -------------------------------------------------------------------------
    print("\n--- TEST 1: Valid Realistic Document Insertion ---");
    var validDoc = {
        student_id: NumberInt(99901),
        student_name: "Aarav Sharma",
        admission_number: "ADM-2026-089",
        roll_number: "12",
        school_id: NumberInt(1),
        branch_id: NumberInt(1),
        academic_year_id: NumberInt(2026),
        class_id: NumberInt(10),
        class_name: "Class 10",
        section_id: NumberInt(101),
        section_name: "Section A",
        total_active_attentions: 3,
        critical_attentions_count: 1,
        subjects: [
            {
                subject_id: NumberInt(1),
                subject_name: "Mathematics",
                subject_code: "MAT-10",
                assigned_teacher_id: NumberInt(501),
                assigned_teacher_name: "Rajesh Sharma",
                active_attentions_count: 2,
                attentions: [
                    {
                        attention_id: "ATT-99901-ASM-1001-2026",
                        attention_type: "LOW_ASSESSMENT_SCORE",
                        severity: "CRITICAL",
                        title: "Low Assessment Score in Unit Test 2",
                        description: "Student obtained 14 marks out of 50, below the pass threshold of 20.",
                        trigger_source: "ASSESSMENT",
                        source_id: NumberInt(1001),
                        triggered_at: new Date("2026-10-15T09:30:00Z"),
                        status: "ACTIVE",
                        acknowledged_at: null,
                        acknowledged_by_teacher_id: null,
                        resolved_at: null,
                        resolved_by_teacher_id: null,
                        resolution_remarks: null,
                        excused_reason: null,
                        assessment_details: {
                            assessment_id: NumberInt(1001),
                            assessment_name: "Unit Test 2 - Quadratic Equations",
                            exam_type: "SLIP_TEST",
                            max_marks: 50.0,
                            pass_marks: 20.0,
                            obtained_marks: 14.0,
                            percentage: 28.0
                        },
                        homework_details: null,
                        attendance_details: null
                    },
                    {
                        attention_id: "ATT-99901-HW-2005-2026",
                        attention_type: "PENDING_HOMEWORK",
                        severity: "HIGH",
                        title: "Overdue Homework: Ex 4.2 Polynomials",
                        description: "Homework assigned on Oct 18 was not submitted by due date Oct 21.",
                        trigger_source: "ASSIGNMENT_HOMEWORK",
                        source_id: NumberInt(2005),
                        triggered_at: new Date("2026-10-22T08:00:00Z"),
                        status: "ACTIVE",
                        acknowledged_at: null,
                        acknowledged_by_teacher_id: null,
                        resolved_at: null,
                        resolved_by_teacher_id: null,
                        resolution_remarks: null,
                        excused_reason: null,
                        assessment_details: null,
                        homework_details: {
                            homework_id: NumberInt(2005),
                            homework_title: "Ex 4.2 Polynomials & Graphs",
                            assigned_date: new Date("2026-10-18T00:00:00Z"),
                            due_date: new Date("2026-10-21T23:59:59Z"),
                            days_overdue: 3,
                            submission_status: "NOT_SUBMITTED"
                        },
                        attendance_details: null
                    }
                ],
                subject_summary: {
                    assessments_passed: 3,
                    assessments_failed: 1,
                    homework_submitted: 8,
                    homework_pending: 1,
                    subject_attendance_percent: 92.5
                }
            },
            {
                subject_id: NumberInt(2),
                subject_name: "Science",
                subject_code: "SCI-10",
                assigned_teacher_id: NumberInt(502),
                assigned_teacher_name: "Ananya Sen",
                active_attentions_count: 1,
                attentions: [
                    {
                        attention_id: "ATT-99901-ATT-3010-2026",
                        attention_type: "ABSENT_ATTENDANCE",
                        severity: "MEDIUM",
                        title: "Unexcused Absence in Period 3 Lab Session",
                        description: "Student was recorded absent during Period 3 Chemistry Lab.",
                        trigger_source: "ATTENDANCE",
                        source_id: NumberInt(3010),
                        triggered_at: new Date("2026-10-25T11:00:00Z"),
                        status: "ACTIVE",
                        acknowledged_at: null,
                        acknowledged_by_teacher_id: null,
                        resolved_at: null,
                        resolved_by_teacher_id: null,
                        resolution_remarks: null,
                        excused_reason: null,
                        assessment_details: null,
                        homework_details: null,
                        attendance_details: {
                            attendance_id: NumberInt(3010),
                            attendance_date: new Date("2026-10-25T00:00:00Z"),
                            period_number: 3,
                            period_time: "10:15 - 11:00",
                            attendance_status: "ABSENT"
                        }
                    }
                ],
                subject_summary: {
                    assessments_passed: 4,
                    assessments_failed: 0,
                    homework_submitted: 10,
                    homework_pending: 0,
                    subject_attendance_percent: 88.0
                }
            }
        ],
        last_evaluated_at: new Date(),
        is_active: 1,
        created_at: new Date(),
        updated_at: new Date()
    };

    var insertRes = db[COLLECTION_NAME].insertOne(validDoc);
    assert(insertRes.acknowledged === true, "Valid document inserted successfully.");

    // -------------------------------------------------------------------------
    // TEST 2: Unique Constraint on (student_id, academic_year_id)
    // -------------------------------------------------------------------------
    print("\n--- TEST 2: Unique Constraint Enforcement ---");
    var duplicateErrorThrown = false;
    try {
        db[COLLECTION_NAME].insertOne({
            student_id: NumberInt(99901),
            student_name: "Aarav Sharma Duplicate",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(2026),
            class_id: NumberInt(10),
            class_name: "Class 10",
            section_id: NumberInt(101),
            section_name: "Section A",
            total_active_attentions: 0,
            critical_attentions_count: 0,
            subjects: [],
            last_evaluated_at: new Date(),
            is_active: 1,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (e) {
        duplicateErrorThrown = true;
        assert(e.code === 11000 || e.message.includes("E11000"), "Duplicate (student_id, academic_year_id) rejected with code 11000.");
    }
    assert(duplicateErrorThrown === true, "Unique index strictly prevented duplicate student-year document.");

    // -------------------------------------------------------------------------
    // TEST 3: Schema Validation Constraints (Invalid Enums, Missing Fields)
    // -------------------------------------------------------------------------
    print("\n--- TEST 3: Schema Validation Strictness ---");
    
    // 3a. Invalid Attention Type Enum
    var invalidEnumThrown = false;
    try {
        db[COLLECTION_NAME].insertOne({
            student_id: NumberInt(99902),
            student_name: "Invalid Student",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(2026),
            class_id: NumberInt(10),
            class_name: "Class 10",
            section_id: NumberInt(101),
            section_name: "Section A",
            total_active_attentions: 1,
            critical_attentions_count: 0,
            subjects: [
                {
                    subject_id: NumberInt(1),
                    subject_name: "Math",
                    subject_code: "MAT-10",
                    active_attentions_count: 1,
                    attentions: [
                        {
                            attention_id: "ATT-FAIL-1",
                            attention_type: "INVALID_ATTENTION_TYPE",
                            severity: "LOW",
                            title: "Invalid",
                            description: "Invalid",
                            trigger_source: "ASSESSMENT",
                            source_id: NumberInt(1),
                            triggered_at: new Date(),
                            status: "ACTIVE"
                        }
                    ]
                }
            ],
            last_evaluated_at: new Date(),
            is_active: 1,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (e) {
        invalidEnumThrown = true;
    }
    assert(invalidEnumThrown === true, "Schema strictly rejected invalid attention_type enum.");

    // 3b. Additional Properties Rejection
    var additionalPropThrown = false;
    try {
        db[COLLECTION_NAME].insertOne({
            student_id: NumberInt(99902),
            student_name: "Invalid Student",
            school_id: NumberInt(1),
            branch_id: NumberInt(1),
            academic_year_id: NumberInt(2026),
            class_id: NumberInt(10),
            class_name: "Class 10",
            section_id: NumberInt(101),
            section_name: "Section A",
            total_active_attentions: 0,
            critical_attentions_count: 0,
            unknown_root_field: "ILLEGAL_PROPERTY",
            subjects: [],
            last_evaluated_at: new Date(),
            is_active: 1,
            created_at: new Date(),
            updated_at: new Date()
        });
    } catch (e) {
        additionalPropThrown = true;
    }
    assert(additionalPropThrown === true, "additionalProperties: false strictly rejected unmodeled property.");

    // -------------------------------------------------------------------------
    // TEST 4: Idempotent Attention Upsert & Duplicate Prevention
    // -------------------------------------------------------------------------
    print("\n--- TEST 4: Idempotent Attention Upsert Logic ---");
    var existingAttentionId = "ATT-99901-ASM-1001-2026";
    
    // Attempting to push existing attention_id using $ne condition
    var retryPushRes = db[COLLECTION_NAME].updateOne(
        {
            student_id: NumberInt(99901),
            academic_year_id: NumberInt(2026),
            "subjects.subject_id": NumberInt(1),
            "subjects.attentions.attention_id": { $ne: existingAttentionId }
        },
        {
            $push: {
                "subjects.$.attentions": {
                    attention_id: existingAttentionId,
                    attention_type: "LOW_ASSESSMENT_SCORE",
                    severity: "CRITICAL",
                    title: "Duplicate Attempt",
                    description: "Duplicate",
                    trigger_source: "ASSESSMENT",
                    source_id: NumberInt(1001),
                    triggered_at: new Date(),
                    status: "ACTIVE"
                }
            }
        }
    );
    assert(retryPushRes.matchedCount === 0, "Idempotent $ne check safely prevented duplicate attention record on retry.");

    // Verify attention count in mathematics is still exactly 2
    var docCheck = db[COLLECTION_NAME].findOne({ student_id: NumberInt(99901) });
    var mathSubject = docCheck.subjects.find(function(s) { return s.subject_id.toString() === "1"; });
    assert(mathSubject.attentions.length === 2, "Mathematics attentions array length remained strictly 2.");

    // -------------------------------------------------------------------------
    // TEST 5: Status Lifecycle Transition (ACKNOWLEDGED, RESOLVED, EXCUSED)
    // -------------------------------------------------------------------------
    print("\n--- TEST 5: Status Lifecycle Transitions ---");
    
    // 5a. Acknowledge Attention
    var ackRes = db[COLLECTION_NAME].updateOne(
        {
            student_id: NumberInt(99901),
            academic_year_id: NumberInt(2026),
            "subjects.subject_id": NumberInt(1),
            "subjects.attentions.attention_id": "ATT-99901-HW-2005-2026"
        },
        {
            $set: {
                "subjects.$[sub].attentions.$[att].status": "ACKNOWLEDGED",
                "subjects.$[sub].attentions.$[att].acknowledged_at": new Date(),
                "subjects.$[sub].attentions.$[att].acknowledged_by_teacher_id": NumberInt(501),
                "updated_at": new Date()
            }
        },
        {
            arrayFilters: [
                { "sub.subject_id": NumberInt(1) },
                { "att.attention_id": "ATT-99901-HW-2005-2026" }
            ]
        }
    );
    assert(ackRes.modifiedCount === 1, "Status successfully transitioned to ACKNOWLEDGED with audit teacher ID.");

    // 5b. Resolve Attention
    var resolveRes = db[COLLECTION_NAME].updateOne(
        {
            student_id: NumberInt(99901),
            academic_year_id: NumberInt(2026),
            "subjects.subject_id": NumberInt(1),
            "subjects.attentions.attention_id": "ATT-99901-HW-2005-2026"
        },
        {
            $set: {
                "subjects.$[sub].attentions.$[att].status": "RESOLVED",
                "subjects.$[sub].attentions.$[att].resolved_at": new Date(),
                "subjects.$[sub].attentions.$[att].resolved_by_teacher_id": NumberInt(501),
                "subjects.$[sub].attentions.$[att].resolution_remarks": "Late submission accepted and verified in physical notebook.",
                "updated_at": new Date()
            }
        },
        {
            arrayFilters: [
                { "sub.subject_id": NumberInt(1) },
                { "att.attention_id": "ATT-99901-HW-2005-2026" }
            ]
        }
    );
    assert(resolveRes.modifiedCount === 1, "Status successfully transitioned to RESOLVED with remarks.");

    // 5c. Excuse Attendance Attention
    var excuseRes = db[COLLECTION_NAME].updateOne(
        {
            student_id: NumberInt(99901),
            academic_year_id: NumberInt(2026),
            "subjects.subject_id": NumberInt(2),
            "subjects.attentions.attention_id": "ATT-99901-ATT-3010-2026"
        },
        {
            $set: {
                "subjects.$[sub].attentions.$[att].status": "EXCUSED",
                "subjects.$[sub].attentions.$[att].resolved_at": new Date(),
                "subjects.$[sub].attentions.$[att].resolved_by_teacher_id": NumberInt(502),
                "subjects.$[sub].attentions.$[att].excused_reason": "Medical certificate submitted for doctor visit during lab hours.",
                "subjects.$[sub].attentions.$[att].resolution_remarks": "Excused by Science teacher per clinic note.",
                "updated_at": new Date()
            }
        },
        {
            arrayFilters: [
                { "sub.subject_id": NumberInt(2) },
                { "att.attention_id": "ATT-99901-ATT-3010-2026" }
            ]
        }
    );
    assert(excuseRes.modifiedCount === 1, "Status successfully transitioned to EXCUSED with medical exemption reason.");

    // -------------------------------------------------------------------------
    // TEST 6: Atomic Attention Count Recalculation Pipeline
    // -------------------------------------------------------------------------
    print("\n--- TEST 6: Atomic Count Recalculation ---");
    // After resolving HW and excusing ATT, only 1 attention remains ACTIVE: ATT-99901-ASM-1001-2026 (CRITICAL)
    // Expected:
    // Math active_attentions_count: 1
    // Science active_attentions_count: 0
    // total_active_attentions: 1
    // critical_attentions_count: 1
    var countRecalcRes = db[COLLECTION_NAME].updateOne(
        { student_id: NumberInt(99901), academic_year_id: NumberInt(2026) },
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
                    },
                    critical_attentions_count: {
                        $reduce: {
                            input: "$subjects",
                            initialValue: 0,
                            in: {
                                $add: [
                                    "$$value",
                                    {
                                        $size: {
                                            $filter: {
                                                input: "$$this.attentions",
                                                as: "att",
                                                cond: {
                                                    $and: [
                                                        { $eq: ["$$att.status", "ACTIVE"] },
                                                        { $eq: ["$$att.severity", "CRITICAL"] }
                                                    ]
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    },
                    updated_at: new Date()
                }
            }
        ]
    );
    assert(countRecalcRes.modifiedCount === 1, "Atomic aggregation update successfully recalculated counts.");

    var recalculatedDoc = db[COLLECTION_NAME].findOne({ student_id: NumberInt(99901) });
    assert(recalculatedDoc.total_active_attentions === 1, "total_active_attentions accurately updated to 1.");
    assert(recalculatedDoc.critical_attentions_count === 1, "critical_attentions_count accurately updated to 1.");
    
    var mathSub = recalculatedDoc.subjects.find(function(s) { return s.subject_id.toString() === "1"; });
    var sciSub = recalculatedDoc.subjects.find(function(s) { return s.subject_id.toString() === "2"; });
    assert(mathSub.active_attentions_count === 1, "Math active_attentions_count is exactly 1.");
    assert(sciSub.active_attentions_count === 0, "Science active_attentions_count is exactly 0.");

    // -------------------------------------------------------------------------
    // TEST 7: Dashboard Query Patterns with $elemMatch & Projection
    // -------------------------------------------------------------------------
    print("\n--- TEST 7: Dashboard Query Patterns ---");

    // 7a. Subject Teacher Dashboard (Teacher 501, Math, Active Alerts)
    var teacherResults = db[COLLECTION_NAME].aggregate([
        {
            $match: {
                academic_year_id: NumberInt(2026),
                subjects: {
                    $elemMatch: {
                        assigned_teacher_id: NumberInt(501),
                        active_attentions_count: { $gt: 0 }
                    }
                }
            }
        },
        {
            $project: {
                student_id: 1,
                student_name: 1,
                class_name: 1,
                section_name: 1,
                assigned_subjects: {
                    $filter: {
                        input: "$subjects",
                        as: "sub",
                        cond: {
                            $and: [
                                { $eq: ["$$sub.assigned_teacher_id", NumberInt(501)] },
                                { $gt: ["$$sub.active_attentions_count", 0] }
                            ]
                        }
                    }
                }
            }
        }
    ]).toArray();
    assert(teacherResults.length === 1, "Teacher 501 query correctly retrieved exactly 1 student.");
    assert(teacherResults[0].assigned_subjects.length === 1, "Teacher 501 projected only Math and excluded Science.");
    assert(teacherResults[0].assigned_subjects[0].subject_name === "Mathematics", "Subject correctly identified as Mathematics.");

    // 7b. Teacher 502 (Science) should find 0 active alerts
    var teacher502Active = db[COLLECTION_NAME].find({
        academic_year_id: NumberInt(2026),
        subjects: {
            $elemMatch: {
                assigned_teacher_id: NumberInt(502),
                active_attentions_count: { $gt: 0 }
            }
        }
    }).toArray();
    assert(teacher502Active.length === 0, "Teacher 502 correctly returned 0 active alert documents.");

    // 7c. Class Teacher Section Overview (Sorted by total_active_attentions desc)
    var classTeacherResults = db[COLLECTION_NAME].find({
        school_id: NumberInt(1),
        branch_id: NumberInt(1),
        academic_year_id: NumberInt(2026),
        class_id: NumberInt(10),
        section_id: NumberInt(101)
    }).sort({ total_active_attentions: -1 }).toArray();
    assert(classTeacherResults.length >= 1, "Class teacher section query successfully returned section students.");

    // 7d. Filter by Attention Type: LOW_ASSESSMENT_SCORE
    var lowScoreResults = db[COLLECTION_NAME].find({
        academic_year_id: NumberInt(2026),
        "subjects.attentions": {
            $elemMatch: {
                attention_type: "LOW_ASSESSMENT_SCORE",
                status: "ACTIVE"
            }
        }
    }).toArray();
    assert(lowScoreResults.length === 1, "Filter by attention_type: LOW_ASSESSMENT_SCORE matched student.");

    // 7e. Management Aggregation Summary
    var mgmtSummary = db[COLLECTION_NAME].aggregate([
        {
            $match: {
                school_id: NumberInt(1),
                branch_id: NumberInt(1),
                academic_year_id: NumberInt(2026)
            }
        },
        {
            $group: {
                _id: { class_id: "$class_id", section_id: "$section_id" },
                total_students_monitored: { $sum: 1 },
                students_with_attentions: {
                    $sum: { $cond: [{ $gt: ["$total_active_attentions", 0] }, 1, 0] }
                },
                total_active_alerts: { $sum: "$total_active_attentions" },
                total_critical_alerts: { $sum: "$critical_attentions_count" }
            }
        }
    ]).toArray();
    assert(mgmtSummary.length === 1, "Management summary aggregation executed successfully.");
    assert(mgmtSummary[0].total_active_alerts === 1, "Management summary reflects exactly 1 total active alert.");
    assert(mgmtSummary[0].total_critical_alerts === 1, "Management summary reflects exactly 1 total critical alert.");

    // -------------------------------------------------------------------------
    // CLEANUP
    // -------------------------------------------------------------------------
    db[COLLECTION_NAME].deleteMany({ student_id: { $in: [99901, 99902] } });
    print("\n[CLEANUP] Removed test records.");

    print("\n================================================================================");
    print("ALL TESTS PASSED: " + passedTests + "/" + totalTests + " assertions verified.");
    print("================================================================================");
})();
