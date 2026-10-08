/*
    Collection: student_learning_health_daily
    Purpose:    Overview Learning Health snapshot (one document per student per calendar day)

    Stored (Compass-generated):
    - overall_score, status (Excellent), overall_sub_label
    - analyzed_by (AI Analyzed badge)
    - five skills: understanding, focus, confidence, application, wellbeing

    Not stored:
    - Compass Intelligence Health tab (student_compass_intelligence_daily)
    - skill bar colors (UI only)
    - SQL marks / attendance rows
    - no extra skill beyond the five on this widget
*/

if (!db.getCollectionNames().includes("student_learning_health_daily")) {
    db.createCollection("student_learning_health_daily", {
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
                    "overall_score",
                    "status",
                    "overall_sub_label",
                    "analyzed_by",
                    "skills"
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
                    generated_at: { bsonType: "date" },
                    model_version: { bsonType: ["string", "null"], maxLength: 50 },
                    overall_score: { bsonType: ["int", "double"], minimum: 0, maximum: 100 },
                    status: {
                        bsonType: "string",
                        enum: ["excellent", "good", "average", "needs_attention"]
                    },
                    overall_sub_label: { bsonType: "string", minLength: 1, maxLength: 120 },
                    analyzed_by: { bsonType: "string", enum: ["compass"] },
                    skills: {
                        bsonType: "array",
                        minItems: 5,
                        maxItems: 5,
                        items: {
                            bsonType: "object",
                            required: ["id", "description", "value"],
                            additionalProperties: false,
                            properties: {
                                id: {
                                    bsonType: "string",
                                    enum: [
                                        "understanding",
                                        "focus",
                                        "confidence",
                                        "application",
                                        "wellbeing"
                                    ]
                                },
                                description: { bsonType: "string", minLength: 1, maxLength: 200 },
                                value: { bsonType: ["int", "double"], minimum: 0, maximum: 100 }
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

if (!db.student_learning_health_daily.getIndexes().some(function (idx) {
    return idx.name === "uq_learning_health_student_day";
})) {
    db.student_learning_health_daily.createIndex(
        { student_id: 1, as_of_date: 1 },
        { unique: true, name: "uq_learning_health_student_day" }
    );
}
