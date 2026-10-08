/*
    Collection: student_compass_intelligence_daily
    Purpose:    Compass Intelligence snapshot (one document per student per calendar day)

    Tabs: for_you (UI: For You), learning, focus, health
    Generated from SQL academic facts; stored as Compass output only.
*/

if (!db.getCollectionNames().includes("student_compass_intelligence_daily")) {
    db.createCollection("student_compass_intelligence_daily", {
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
                    "content"
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
                    content: {
                        bsonType: "object",
                        required: ["for_you", "learning", "focus", "health"],
                        additionalProperties: false,
                        properties: {
                            for_you: {
                                bsonType: "object",
                                required: ["top_recommendation", "stats", "quick_suggestions"],
                                additionalProperties: false,
                                properties: {
                                    top_recommendation: {
                                        bsonType: "object",
                                        required: [
                                            "title",
                                            "body",
                                            "cta_label",
                                            "estimated_minutes",
                                            "priority",
                                            "expected_impact_percent"
                                        ],
                                        additionalProperties: false,
                                        properties: {
                                            title: { bsonType: "string", maxLength: 200 },
                                            body: { bsonType: "string", maxLength: 2000 },
                                            cta_label: { bsonType: "string", maxLength: 80 },
                                            estimated_minutes: { bsonType: "int", minimum: 0 },
                                            priority: { bsonType: "string", enum: ["high", "medium", "low"] },
                                            expected_impact_percent: { bsonType: ["int", "double"] }
                                        }
                                    },
                                    stats: {
                                        bsonType: "array",
                                        minItems: 3,
                                        maxItems: 3,
                                        items: {
                                            bsonType: "object",
                                            required: ["id", "sub_value"],
                                            additionalProperties: false,
                                            properties: {
                                                id: {
                                                    bsonType: "string",
                                                    enum: ["momentum", "attention", "strength"]
                                                },
                                                value: { bsonType: ["int", "double", "null"] },
                                                unit: { bsonType: ["string", "null"] },
                                                direction: {
                                                    bsonType: ["string", "null"],
                                                    enum: ["positive", "negative", "neutral", null]
                                                },
                                                task_count: { bsonType: ["int", "null"], minimum: 0 },
                                                sub_value: { bsonType: "string", maxLength: 300 }
                                            }
                                        }
                                    },
                                    quick_suggestions: {
                                        bsonType: "object",
                                        required: ["items"],
                                        additionalProperties: false,
                                        properties: {
                                            items: {
                                                bsonType: "array",
                                                items: {
                                                    bsonType: "object",
                                                    required: ["id", "text"],
                                                    additionalProperties: false,
                                                    properties: {
                                                        id: { bsonType: "string", maxLength: 50 },
                                                        text: { bsonType: "string", maxLength: 500 }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            },
                            learning: {
                                bsonType: "object",
                                additionalProperties: false,
                                properties: {
                                    in_progress: {
                                        bsonType: ["object", "null"],
                                        additionalProperties: false,
                                        properties: {
                                            subject: { bsonType: "string", maxLength: 150 },
                                            subject_topic: { bsonType: "string", maxLength: 200 },
                                            completed_resources: { bsonType: "int", minimum: 0 },
                                            total_resources: { bsonType: "int", minimum: 0 },
                                            performance_percent: {
                                                bsonType: ["int", "double"],
                                                minimum: 0,
                                                maximum: 100
                                            }
                                        }
                                    },
                                    metrics: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["id"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: "string", maxLength: 50 },
                                                minutes: { bsonType: ["int", "null"], minimum: 0 },
                                                count: { bsonType: ["int", "null"], minimum: 0 },
                                                percent: {
                                                    bsonType: ["int", "double", "null"],
                                                    minimum: 0,
                                                    maximum: 100
                                                }
                                            }
                                        }
                                    },
                                    suggestions: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["id", "label"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: "string", maxLength: 50 },
                                                label: { bsonType: "string", maxLength: 200 }
                                            }
                                        }
                                    },
                                    resources: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["id", "title"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: "string", maxLength: 50 },
                                                title: { bsonType: "string", maxLength: 200 },
                                                subtitle: { bsonType: ["string", "null"], maxLength: 300 }
                                            }
                                        }
                                    }
                                }
                            },
                            focus: {
                                bsonType: "object",
                                additionalProperties: false,
                                properties: {
                                    focus_analysis: {
                                        bsonType: ["object", "null"],
                                        additionalProperties: false,
                                        properties: {
                                            focus_score: {
                                                bsonType: ["int", "double"],
                                                minimum: 0,
                                                maximum: 100
                                            },
                                            deep_focus_minutes: { bsonType: "int", minimum: 0 },
                                            distractions_detected: { bsonType: "int", minimum: 0 }
                                        }
                                    },
                                    stats: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["id", "value", "unit"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: "string", maxLength: 50 },
                                                value: { bsonType: ["int", "double"] },
                                                unit: { bsonType: "string", maxLength: 30 }
                                            }
                                        }
                                    },
                                    suggestions: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["id", "label"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: "string", maxLength: 50 },
                                                label: { bsonType: "string", maxLength: 200 }
                                            }
                                        }
                                    },
                                    tip: {
                                        bsonType: ["object", "null"],
                                        additionalProperties: false,
                                        properties: {
                                            text: { bsonType: "string", maxLength: 500 }
                                        }
                                    },
                                    estimated_minutes: { bsonType: ["int", "null"], minimum: 0 },
                                    daily_goal: {
                                        bsonType: ["object", "null"],
                                        additionalProperties: false,
                                        properties: {
                                            percent: {
                                                bsonType: ["int", "double"],
                                                minimum: 0,
                                                maximum: 100
                                            }
                                        }
                                    }
                                }
                            },
                            health: {
                                bsonType: "object",
                                additionalProperties: false,
                                properties: {
                                    learning_wellness: {
                                        bsonType: ["object", "null"],
                                        additionalProperties: false,
                                        properties: {
                                            score: {
                                                bsonType: ["int", "double"],
                                                minimum: 0,
                                                maximum: 100
                                            },
                                            stress: {
                                                bsonType: "string",
                                                enum: ["low", "medium", "high"]
                                            },
                                            sleep_minutes: { bsonType: "int", minimum: 0 }
                                        }
                                    },
                                    screen_time_minutes: { bsonType: ["int", "null"], minimum: 0 },
                                    breaks_taken: { bsonType: ["int", "null"], minimum: 0 },
                                    hydration_status: {
                                        bsonType: ["string", "null"],
                                        enum: ["good", "low", "poor", null]
                                    },
                                    suggestions: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["id", "label"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: "string", maxLength: 50 },
                                                label: { bsonType: "string", maxLength: 200 }
                                            }
                                        }
                                    },
                                    habits: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["id"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: "string", maxLength: 50 },
                                                percent: {
                                                    bsonType: ["int", "double", "null"],
                                                    minimum: 0,
                                                    maximum: 100
                                                },
                                                level: {
                                                    bsonType: ["string", "null"],
                                                    enum: ["strong", "moderate", "low", null]
                                                }
                                            }
                                        }
                                    },
                                    ai_insight: {
                                        bsonType: ["object", "null"],
                                        additionalProperties: false,
                                        properties: {
                                            text: { bsonType: "string", maxLength: 2000 }
                                        }
                                    },
                                    reminder: {
                                        bsonType: ["object", "null"],
                                        additionalProperties: false,
                                        properties: {
                                            text: { bsonType: "string", maxLength: 1000 }
                                        }
                                    }
                                }
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

if (!db.student_compass_intelligence_daily.getIndexes().some(function (idx) {
    return idx.name === "uq_compass_student_day";
})) {
    db.student_compass_intelligence_daily.createIndex(
        { student_id: 1, as_of_date: 1 },
        { unique: true, name: "uq_compass_student_day" }
    );
}
