/*
    Collection: student_mission_control_daily
    Purpose:    Compass-generated Mission Control snapshot (one document per student per calendar day)

    Stored:
    - readiness (percent, status, change vs last week)
    - motivational quote
    - task streak
    - daily attendance and homework summaries
    - next assessment card
    - start_my_day_at (student button-hit timestamp)
    - Compass suggested checklist items, including homework items
    - optional task_time cache

    Not stored:
    - assignment data
    - teacher homework rows (SQL remains authoritative)
*/

if (!db.getCollectionNames().includes("student_mission_control_daily")) {
    db.createCollection("student_mission_control_daily", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "student_id",
                    "school_id",
                    "branch_id",
                    "academic_year_id",
                    "class_id",
                    "section_id",
                    "as_of_date",
                    "generated_at",
                    "readiness",
                    "motivational_note"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    student_id: { bsonType: ["int", "long"] },
                    school_id: { bsonType: ["int", "long"] },
                    branch_id: { bsonType: ["int", "long"] },
                    academic_year_id: { bsonType: ["int", "long"] },
                    class_id: { bsonType: ["int", "long"] },
                    section_id: { bsonType: ["int", "long"] },
                    as_of_date: { bsonType: "date" },
                    start_my_day_at: { bsonType: ["date", "null"] },
                    generated_at: { bsonType: "date" },
                    model_version: { bsonType: ["string", "null"], maxLength: 50 },
                    daily_attendance: {
                        bsonType: ["object", "null"],
                        required: ["attended_count", "expected_count"],
                        additionalProperties: false,
                        properties: {
                            attended_count: { bsonType: "int", minimum: 0 },
                            expected_count: { bsonType: "int", minimum: 0 },
                            attendance_percent: {
                                bsonType: ["int", "double"],
                                minimum: 0,
                                maximum: 100
                            },
                            status: {
                                bsonType: "string",
                                enum: ["not_started", "in_progress", "complete"]
                            }
                        }
                    },
                    daily_homework: {
                        bsonType: ["object", "null"],
                        required: ["completed_count", "total_count"],
                        additionalProperties: false,
                        properties: {
                            completed_count: { bsonType: "int", minimum: 0 },
                            total_count: { bsonType: "int", minimum: 0 },
                            completion_percent: {
                                bsonType: ["int", "double"],
                                minimum: 0,
                                maximum: 100
                            }
                        }
                    },
                    next_assessment: {
                        bsonType: ["object", "null"],
                        required: ["assessment_id", "subject_name", "assessment_at"],
                        additionalProperties: false,
                        properties: {
                            assessment_id: { bsonType: ["int", "long"] },
                            subject_id: { bsonType: ["int", "long", "null"] },
                            subject_name: {
                                bsonType: "string",
                                minLength: 1,
                                maxLength: 150
                            },
                            assessment_name: {
                                bsonType: ["string", "null"],
                                maxLength: 150
                            },
                            assessment_at: { bsonType: "date" }
                        }
                    },
                    readiness: {
                        bsonType: "object",
                        required: ["percent", "status", "change_percent", "comparison_period"],
                        additionalProperties: false,
                        properties: {
                            percent: { bsonType: ["int", "double"], minimum: 0, maximum: 100 },
                            status: {
                                bsonType: "string",
                                enum: ["excellent", "good", "average", "needs_attention"]
                            },
                            change_percent: { bsonType: ["int", "double"] },
                            comparison_period: { bsonType: "string", enum: ["last-week"] }
                        }
                    },
                    motivational_note: { bsonType: "string", minLength: 1, maxLength: 1000 },
                    task_streak: {
                        bsonType: ["object", "null"],
                        required: ["days", "status"],
                        additionalProperties: false,
                        properties: {
                            days: { bsonType: "int", minimum: 0 },
                            status: { bsonType: "string", enum: ["on-track", "at-risk", "broken"] }
                        }
                    },
                    task_time: {
                        bsonType: ["object", "null"],
                        additionalProperties: false,
                        properties: {
                            total_minutes: { bsonType: "int", minimum: 0 }
                        }
                    },
                    suggested_checklist_items: {
                        bsonType: ["array", "null"],
                        items: {
                            bsonType: "object",
                            required: ["item_key", "title", "completed"],
                            additionalProperties: false,
                            properties: {
                                item_key: { bsonType: "string", minLength: 1, maxLength: 80 },
                                title: { bsonType: "string", minLength: 1, maxLength: 200 },
                                source_type: {
                                    bsonType: ["string", "null"],
                                    enum: ["HOMEWORK", "OTHER", null]
                                },
                                source_id: { bsonType: ["int", "long", "null"] },
                                scheduled_time: { bsonType: ["string", "null"], maxLength: 8 },
                                estimated_minutes: { bsonType: ["int", "null"], minimum: 0 },
                                completed: { bsonType: "bool" },
                                completed_at: { bsonType: ["date", "null"] }
                            }
                        }
                    }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

if (!db.student_mission_control_daily.getIndexes().some(function (idx) {
    return idx.name === "uq_mc_student_day";
})) {
    db.student_mission_control_daily.createIndex(
        { student_id: 1, as_of_date: 1 },
        { unique: true, name: "uq_mc_student_day" }
    );
}

if (!db.student_mission_control_daily.getIndexes().some(function (idx) {
    return idx.name === "ix_mc_scope_day";
})) {
    db.student_mission_control_daily.createIndex(
        { school_id: 1, section_id: 1, as_of_date: 1 },
        { name: "ix_mc_scope_day" }
    );
}
