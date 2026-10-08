# Thinkigen MongoDB — Collections Reference

SQL Server remains the ERP system of record.
MongoDB stores Compass / Learning Hub / Connect documents and auth session hashes.
One Organization = one Mongo database (same isolation as SQL).

Related: [full-table-reference.md](./full-table-reference.md) · `database/mongo/README.md`

This document includes the **full `createCollection` validation script** for every collection,
generated from `database/mongo/collections/*.js`.

SQL BIGINT IDs must be stored as `NumberLong` in Mongo.

---

## Collection index

| Domain | Collection | Source script |
|--------|------------|---------------|
| Overview | `student_mission_control_daily` | `001_student_mission_control_daily.js` |
| Overview | `student_compass_intelligence_daily` | `002_student_compass_intelligence_daily.js` |
| Overview | `student_learning_health_daily` | `003_student_learning_health_daily.js` |
| Learning Hub | `class_subject_syllabus` | `004_class_subject_syllabus.js` |
| Learning Hub | `learning_resource` | `005_learning_resource(documets).js` |
| Learning Hub | `exam_paper` | `05_exam_paper.js` |
| Connect | `connect_conversation` | `008_connect_conversation.js` |
| Connect | `connect_meeting` | `009_connect_meeting.js` |
| Connect | `connect_community` | `010_connect_community.js` |
| Connect | `connect_community_member` | `011_connect_community_member.js` |
| Connect | `connect_community_join_request` | `012_connect_community_join_request.js` |
| Connect | `connect_community_post` | `013_connect_community_post.js` |
| Connect | `connect_community_comment` | `014_connect_community_comment.js` |
| Connect | `connect_community_post_like` | `015_connect_community_post_like.js` |
| Connect | `connect_community_discussion` | `016_connect_community_discussion.js` |
| Connect | `connect_community_discussion_reply` | `017_connect_community_discussion_reply.js` |
| Connect | `connect_community_poll` | `018_connect_community_poll.js` |
| Connect | `connect_community_poll_vote` | `019_connect_community_poll_vote.js` |
| Auth | `user_jwt_token` | `020_user_jwt_token.js` |
| Shared Documents | `thinkigen_documents` | `023_thinkigen_documents.js` |
| Career Explorer | `career_industries` | `025_career_explorer.js` |
| Career Explorer | `career_paths` | `025_career_explorer.js` |
| Other | `024_connect_community_production_hardening` | `024_connect_community_production_hardening.js` |
| Other | `connect_conversation_user_state` | `020_connect_conversation_user_state.js` |
| Other | `course_progress` | `021_course_progress.js` |
| Other | `student_last_learning_resource` | `022_student_last_learning_resource.js` |

**Total collections:** 26

---

## Overview

### `student_mission_control_daily`

- **Source:** `database/mongo/collections/001_student_mission_control_daily.js`
- **Purpose:** Compass-generated Mission Control snapshot (one document per student per calendar day)

**Indexes**

- `uq_mc_student_day` — `{ student_id: 1, as_of_date: 1 }` [unique]
- `ix_mc_scope_day` — `{ school_id: 1, section_id: 1, as_of_date: 1 }`

**Validation script**

```javascript
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
```

### `student_compass_intelligence_daily`

- **Source:** `database/mongo/collections/002_student_compass_intelligence_daily.js`
- **Purpose:** Compass stores AI-generated daily intelligence for a student. Source academic/activity/student data remains in the existing system of record.

**Indexes**

- `uq_compass_student_day` — `{ student_id: 1, as_of_date: 1 }` [unique]
- `ix_compass_hierarchy_day` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, as_of_date: 1 }`

**Validation script**

```javascript
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
                    generation_version: { bsonType: ["string", "int", "null"], maxLength: 50 },
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
                                            "priority"
                                        ],
                                        additionalProperties: false,
                                        properties: {
                                            title: { bsonType: "string", maxLength: 200 },
                                            body: { bsonType: "string", maxLength: 2000 },
                                            cta_label: { bsonType: "string", maxLength: 80 },
                                            estimated_minutes: { bsonType: "int", minimum: 0 },
                                            priority: { bsonType: "string", enum: ["high", "medium", "low"] },
                                            expected_impact: { bsonType: ["string", "null"], maxLength: 200 },
                                            expected_impact_percent: {
                                                bsonType: ["int", "double", "null"],
                                                minimum: 0,
                                                maximum: 100
                                            }
                                        }
                                    },
                                    stats: {
                                        bsonType: "array",
                                        items: {
                                            bsonType: "object",
                                            required: ["id", "sub_value"],
                                            additionalProperties: false,
                                            properties: {
                                                id: {
                                                    bsonType: "string",
                                                    enum: ["momentum", "attention", "strength"]
                                                },
                                                label: { bsonType: ["string", "null"], maxLength: 100 },
                                                value: { bsonType: ["int", "double", "null"] },
                                                unit: { bsonType: ["string", "null"], maxLength: 30 },
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
                                            summary: { bsonType: ["string", "null"], maxLength: 1000 },
                                            learning_area: { bsonType: ["string", "null"], maxLength: 150 },
                                            subject: { bsonType: ["string", "null"], maxLength: 150 },
                                            topic: { bsonType: ["string", "null"], maxLength: 200 },
                                            subject_topic: { bsonType: ["string", "null"], maxLength: 200 },
                                            progress_percent: {
                                                bsonType: ["int", "double", "null"],
                                                minimum: 0,
                                                maximum: 100
                                            },
                                            completed_resources: { bsonType: ["int", "null"], minimum: 0 },
                                            total_resources: { bsonType: ["int", "null"], minimum: 0 },
                                            performance_percent: {
                                                bsonType: ["int", "double", "null"],
                                                minimum: 0,
                                                maximum: 100
                                            },
                                            recommendation: { bsonType: ["string", "null"], maxLength: 500 }
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
                                                label: { bsonType: ["string", "null"], maxLength: 100 },
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
                                                label: { bsonType: "string", maxLength: 200 },
                                                description: { bsonType: ["string", "null"], maxLength: 500 }
                                            }
                                        }
                                    },
                                    resources: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["title"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: ["string", "null"], maxLength: 50 },
                                                title: { bsonType: "string", maxLength: 200 },
                                                subtitle: { bsonType: ["string", "null"], maxLength: 300 },
                                                description: { bsonType: ["string", "null"], maxLength: 1000 },
                                                topic: { bsonType: ["string", "null"], maxLength: 200 },
                                                recommendation: { bsonType: ["string", "null"], maxLength: 500 }
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
                                                bsonType: ["int", "double", "null"],
                                                minimum: 0,
                                                maximum: 100
                                            },
                                            deep_focus_minutes: { bsonType: ["int", "null"], minimum: 0 },
                                            deep_focus_description: { bsonType: ["string", "null"], maxLength: 500 },
                                            distractions_detected: { bsonType: ["int", "null"], minimum: 0 },
                                            distraction_information: { bsonType: ["string", "null"], maxLength: 500 },
                                            summary: { bsonType: ["string", "null"], maxLength: 1000 }
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
                                                label: { bsonType: ["string", "null"], maxLength: 100 },
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
                                                label: { bsonType: "string", maxLength: 200 },
                                                description: { bsonType: ["string", "null"], maxLength: 500 }
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
                                            title: { bsonType: ["string", "null"], maxLength: 200 },
                                            percent: {
                                                bsonType: ["int", "double"],
                                                minimum: 0,
                                                maximum: 100
                                            },
                                            target_minutes: { bsonType: ["int", "null"], minimum: 0 }
                                        }
                                    },
                                    upcoming_priorities: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["title"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: ["string", "null"], maxLength: 50 },
                                                title: { bsonType: "string", maxLength: 200 },
                                                priority: {
                                                    bsonType: ["string", "null"],
                                                    enum: ["high", "medium", "low", null]
                                                },
                                                due_description: { bsonType: ["string", "null"], maxLength: 150 },
                                                estimated_minutes: { bsonType: ["int", "null"], minimum: 0 },
                                                action_label: { bsonType: ["string", "null"], maxLength: 80 }
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
                                                bsonType: ["string", "null"],
                                                enum: ["low", "medium", "high", null]
                                            },
                                            sleep_minutes: { bsonType: ["int", "null"], minimum: 0 },
                                            sleep_hours: { bsonType: ["int", "double", "null"], minimum: 0 },
                                            sleep_quality: {
                                                bsonType: ["string", "null"],
                                                enum: ["good", "fair", "poor", null]
                                            }
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
                                                label: { bsonType: "string", maxLength: 200 },
                                                description: { bsonType: ["string", "null"], maxLength: 500 }
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
                                                label: { bsonType: ["string", "null"], maxLength: 100 },
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
                                    },
                                    reminders: {
                                        bsonType: ["array", "null"],
                                        items: {
                                            bsonType: "object",
                                            required: ["text"],
                                            additionalProperties: false,
                                            properties: {
                                                id: { bsonType: ["string", "null"], maxLength: 50 },
                                                text: { bsonType: "string", maxLength: 500 }
                                            }
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
```

### `student_learning_health_daily`

- **Source:** `database/mongo/collections/003_student_learning_health_daily.js`
- **Purpose:** Overview Learning Health snapshot (one document per student per calendar day)

**Indexes**

- `uq_learning_health_student_day` — `{ student_id: 1, as_of_date: 1 }` [unique]

**Validation script**

```javascript
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
```

## Learning Hub

### `class_subject_syllabus`

- **Source:** `database/mongo/collections/004_class_subject_syllabus.js`
- **Purpose:** Master curriculum structure for a class + subject + academic year.

**Indexes**

- `uq_syllabus_version_scope` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, subject_id: 1, syllabus_version: 1 }` [unique]
- `uq_syllabus_active_scope` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, subject_id: 1, is_active: 1 }` [unique]
- `ix_syllabus_scope_active` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, subject_id: 1, is_active: 1, syllabus_version: -1 }`

**Validation script**

```javascript
db.createCollection("class_subject_syllabus", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "school_id",
                    "branch_id",
                    "academic_year_id",
                    "class_id",
                    "subject_id",
                    "syllabus_version",
                    "chapters",
                    "is_active",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    school_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    branch_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    academic_year_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    class_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    subject_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    syllabus_version: { bsonType: "int", minimum: 1 },
                    chapters: {
                        bsonType: "array",
                        minItems: 1,
                        items: {
                            bsonType: "object",
                            required: ["chapter_id", "title", "display_order", "is_locked", "topics"],
                            additionalProperties: false,
                            properties: {
                                chapter_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                                title: { bsonType: "string", minLength: 1, maxLength: 200 },
                                display_order: { bsonType: "int", minimum: 1 },
                                is_locked: { bsonType: "bool" },
                                topics: {
                                    bsonType: "array",
                                    minItems: 0,
                                    items: {
                                        bsonType: "object",
                                        required: ["topic_id", "number", "title", "display_order"],
                                        additionalProperties: false,
                                        properties: {
                                            topic_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                                            number: { bsonType: "string", minLength: 1, maxLength: 20 },
                                            title: { bsonType: "string", minLength: 1, maxLength: 200 },
                                            description: { bsonType: ["string", "null"], maxLength: 4000 },
                                            learning_objective: { bsonType: ["string", "null"], maxLength: 2000 },
                                            display_order: { bsonType: "int", minimum: 1 }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_by: { bsonType: ["string", "null"], maxLength: 128 },
                    updated_by: { bsonType: ["string", "null"], maxLength: 128 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `learning_resource`

- **Source:** `database/mongo/collections/005_learning_resource(documets).js`
- **Purpose:** Stores learning materials associated with a topic. Resources are section-specific, so section_id is required. Supported combinations are: - VIDEO + TEACHER - NOTE + TEACHER - NOTE + COMPASS

**Indexes**

- `uq_learning_resource_resource_id` — `{ resource_id: 1 }` [unique]
- `ix_learning_resource_topic_lookup` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, topic_id: 1, resource_type: 1, source_type: 1, status: 1, updated_at: -1 }`
- `ix_learning_resource_subject_lookup` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, resource_type: 1, source_type: 1, status: 1 }`
- `uq_learning_resource_current_teacher_note` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, topic_id: 1, source_type: 1 }` [unique]
- `uq_learning_resource_current_compass_note` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, topic_id: 1, source_type: 1 }` [unique]

**Validation script**

```javascript
db.createCollection("learning_resource", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "resource_id",
                    "school_id",
                    "branch_id",
                    "academic_year_id",
                    "class_id",
                    "section_id",
                    "subject_id",
                    "topic_id",
                    "resource_type",
                    "source_type",
                    "title",
                    "status",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    resource_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    school_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    branch_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    academic_year_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    class_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    section_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    subject_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    topic_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    resource_type: {
                        bsonType: "string",
                        enum: ["VIDEO", "NOTE"]
                    },
                    source_type: {
                        bsonType: "string",
                        enum: ["TEACHER", "COMPASS"]
                    },
                    title: { bsonType: "string", minLength: 1, maxLength: 200 },
                    description: { bsonType: ["string", "null"], maxLength: 10000 },
                    storage_reference: {
                        bsonType: "object",
                        additionalProperties: false,
                        anyOf: [
                            {
                                required: ["object_key"],
                                properties: {
                                    object_key: { bsonType: "string", minLength: 1, maxLength: 2048 },
                                    external_url: { bsonType: ["null", "string"] }
                                }
                            },
                            {
                                required: ["external_url"],
                                properties: {
                                    object_key: { bsonType: ["null", "string"] },
                                    external_url: { bsonType: "string", minLength: 1, maxLength: 2048 }
                                }
                            }
                        ]
                    },
                    duration_seconds: { bsonType: ["int", "long", "null"], minimum: 0 },
                    key_takeaways: {
                        bsonType: ["array", "null"],
                        maxItems: 25,
                        items: { bsonType: "string", minLength: 1, maxLength: 1000 }
                    },
                    file_metadata: {
                        bsonType: ["object", "null"],
                        additionalProperties: false,
                        properties: {
                            mime_type: { bsonType: ["string", "null"], maxLength: 200 },
                            file_size_bytes: { bsonType: ["int", "long", "null"], minimum: 0 }
                        }
                    },
                    status: {
                        bsonType: "string",
                        enum: ["PROCESSING", "READY", "PUBLISHED", "ARCHIVED"]
                    },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_by: { bsonType: ["string", "null"], maxLength: 128 },
                    updated_by: { bsonType: ["string", "null"], maxLength: 128 }
                },
                anyOf: [
                    {
                        properties: {
                            resource_type: { enum: ["VIDEO"] },
                            source_type: { enum: ["TEACHER"] }
                        },
                        required: ["description", "duration_seconds", "storage_reference"]
                    },
                    {
                        properties: {
                            resource_type: { enum: ["NOTE"] },
                            source_type: { enum: ["TEACHER"] }
                        },
                        required: ["storage_reference"]
                    },
                    {
                        properties: {
                            resource_type: { enum: ["NOTE"] },
                            source_type: { enum: ["COMPASS"] }
                        },
                        required: ["storage_reference"]
                    }
                ],
                allOf: [
                    {
                        not: {
                            properties: {
                                resource_type: { enum: ["VIDEO"] },
                                source_type: { enum: ["COMPASS"] }
                            }
                        }
                    }
                ]
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `exam_paper`

- **Source:** `database/mongo/collections/05_exam_paper.js`
- **Purpose:** Final exam paper catalog for the Learning Hub.

**Indexes**

- `uq_exam_paper_id` — `{ exam_paper_id: 1 }` [unique]
- `uq_exam_paper_class_title` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, subject_id: 1, category: 1, exam_year: 1, title: 1 }` [unique]
- `ix_exam_paper_class_category` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, subject_id: 1, category: 1, is_active: 1 }`

**Validation script**

```javascript
db.createCollection("exam_paper", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "exam_paper_id",
                    "school_id",
                    "branch_id",
                    "academic_year_id",
                    "class_id",
                    "subject_id",
                    "subject_name",
                    "title",
                    "exam_year",
                    "category",
                    "duration_minutes",
                    "max_marks",
                    "question_count",
                    "file_url",
                    "is_active",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    exam_paper_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    branch_id: { bsonType: ["int", "long"], minimum: 1 },
                    academic_year_id: { bsonType: ["int", "long"], minimum: 1 },
                    class_id: { bsonType: ["int", "long"], minimum: 1 },
                    subject_id: { bsonType: ["int", "long"], minimum: 1 },
                    subject_name: { bsonType: "string", minLength: 1, maxLength: 200 },
                    title: { bsonType: "string", minLength: 1, maxLength: 200 },
                    exam_year: {
                        bsonType: "string",
                        pattern: "^(19|20)[0-9]{2}$"
                    },
                    category: {
                        bsonType: "string",
                        enum: ["UNIT_TEST", "MID_TERM", "PRE_FINAL", "FINAL", "BOARD", "AI_GENERATED"]
                    },
                    duration_minutes: { bsonType: ["int", "long"], minimum: 1, maximum: 1440 },
                    max_marks: { bsonType: ["int", "long"], minimum: 1 },
                    question_count: { bsonType: ["int", "long"], minimum: 1 },
                    file_url: { bsonType: "string", minLength: 1, maxLength: 2048 },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_by: { bsonType: ["int", "long", "null"], minimum: 1 },
                    updated_by: { bsonType: ["int", "long", "null"], minimum: 1 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `student_learning_progress`

_Collection script not found._

## Connect

### `connect_conversation`

- **Source:** `database/mongo/collections/008_connect_conversation.js`
- **Purpose:** Connect → conversation master for 1:1 and group communication

**Indexes**

- `uq_connect_conversation_id` — `{ conversation_id: 1 }` [unique]
- `uq_connect_conversation_pair_key` — `{ participant_pair_key: 1 }` [unique]
- `ix_connect_conversation_participant` — `{ school_id: 1, "participants.user_id": 1, updated_at: -1 }`

**Validation script**

```javascript
db.createCollection("connect_conversation", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "conversation_id",
                    "school_id",
                    "branch_id",
                    "conversation_type",
                    "title",
                    "participants",
                    "is_active",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    conversation_id: { bsonType: "string", minLength: 1, maxLength: 80 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    branch_id: { bsonType: ["int", "long"], minimum: 1 },
                    conversation_type: { bsonType: "string", enum: ["one_to_one", "group"] },
                    participant_pair_key: { bsonType: ["string", "null"], minLength: 1, maxLength: 80 },
                    title: { bsonType: "string", minLength: 1, maxLength: 200 },
                    header_context: { bsonType: ["string", "null"], maxLength: 300 },
                    academic_year_id: { bsonType: ["int", "long", "null"], minimum: 1 },
                    class_id: { bsonType: ["int", "long", "null"], minimum: 1 },
                    section_id: { bsonType: ["int", "long", "null"], minimum: 1 },
                    subject_id: { bsonType: ["int", "long", "null"], minimum: 1 },
                    group_type: { bsonType: ["string", "null"], enum: ["class_group", "section_group", "committee", "club", "society", null] },
                    participants: {
                        bsonType: "array",
                        minItems: 2,
                        items: {
                            bsonType: "object",
                            required: ["user_id", "participant_role"],
                            additionalProperties: false,
                            properties: {
                                user_id: { bsonType: ["int", "long"], minimum: 1 },
                                participant_role: {
                                    bsonType: "string",
                                    enum: ["student", "teacher", "staff", "admin", "faculty", "member", "moderator", "parent"]
                                },
                                display_name: { bsonType: ["string", "null"], maxLength: 200 }
                            }
                        }
                    },
                    last_message_preview: { bsonType: ["string", "null"], maxLength: 500 },
                    last_message_at: { bsonType: ["date", "null"] },
                    last_message_sender_user_id: { bsonType: ["int", "long", "null"], minimum: 1 },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_by: { bsonType: ["int", "long", "null"], minimum: 1 },
                    updated_by: { bsonType: ["int", "long", "null"], minimum: 1 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_meeting`

- **Source:** `database/mongo/collections/009_connect_meeting.js`
- **Purpose:** Connect → meeting master

**Indexes**

- `uq_connect_meeting_id` — `{ meeting_id: 1 }` [unique]
- `ix_connect_meeting_schedule` — `{ school_id: 1, scheduled_at: 1, status: 1 }`

**Validation script**

```javascript
db.createCollection("connect_meeting", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "meeting_id",
                    "school_id",
                    "branch_id",
                    "title",
                    "status",
                    "meeting_type",
                    "scheduled_at",
                    "duration_minutes",
                    "organizer",
                    "targets",
                    "is_active",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                anyOf: [
                    {
                        properties: {
                            meeting_type: { bsonType: "string", enum: ["VIRTUAL"] }
                        },
                        required: ["online_details"]
                    },
                    {
                        properties: {
                            meeting_type: { bsonType: "string", enum: ["IN_PERSON"] }
                        },
                        required: ["location"]
                    }
                ],
                properties: {
                    _id: { bsonType: "objectId" },
                    meeting_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    branch_id: { bsonType: ["int", "long"], minimum: 1 },
                    title: { bsonType: "string", minLength: 1, maxLength: 300 },
                    status: {
                        bsonType: "string",
                        enum: ["scheduled", "pending", "ongoing", "completed", "cancelled"]
                    },
                    meeting_type: { bsonType: "string", enum: ["VIRTUAL", "IN_PERSON"] },
                    scheduled_at: { bsonType: "date" },
                    duration_minutes: { bsonType: ["int", "long"], minimum: 1, maximum: 1440 },
                    organizer: {
                        bsonType: "object",
                        required: ["user_id"],
                        additionalProperties: false,
                        properties: {
                            user_id: { bsonType: ["int", "long"], minimum: 1 },
                            name: { bsonType: ["string", "null"], maxLength: 200 },
                            role: { bsonType: ["string", "null"], maxLength: 200 },
                            email: { bsonType: ["string", "null"], maxLength: 254 }
                        }
                    },
                    targets: {
                        bsonType: "array",
                        minItems: 1,
                        items: {
                            bsonType: "object",
                            required: ["target_type", "role", "user_ids"],
                            additionalProperties: false,
                            properties: {
                                target_type: { bsonType: "string", enum: ["USER"] },
                                role: {
                                    bsonType: "string",
                                    enum: ["STUDENT", "TEACHER", "PRINCIPAL", "MANAGEMENT", "FINANCE", "TRANSPORT", "STAFF", "PARENT", "OTHER_AUTHORIZED_ROLE"]
                                },
                                user_ids: {
                                    bsonType: "array",
                                    minItems: 1,
                                    items: { bsonType: ["int", "long"], minimum: 1 }
                                }
                            }
                        }
                    },
                    agenda: {
                        bsonType: ["array", "null"],
                        items: {
                            bsonType: "object",
                            required: ["agenda_id", "title"],
                            additionalProperties: false,
                            properties: {
                                agenda_id: { bsonType: ["int", "long"], minimum: 1 },
                                title: { bsonType: "string", minLength: 1, maxLength: 500 }
                            }
                        }
                    },
                    online_details: {
                        bsonType: ["object", "null"],
                        additionalProperties: false,
                        properties: {
                            platform: { bsonType: "string", enum: ["GOOGLE_MEET"] },
                            meeting_url: { bsonType: "string", minLength: 1, maxLength: 2048 }
                        }
                    },
                    location: { bsonType: ["string", "null"], maxLength: 200 },
                    room_no: { bsonType: ["string", "null"], maxLength: 100 },
                    resources: {
                        bsonType: ["array", "null"],
                        items: {
                            bsonType: "object",
                            required: ["resource_id", "title", "resource_type"],
                            additionalProperties: false,
                            properties: {
                                resource_id: { bsonType: ["int", "long"], minimum: 1 },
                                title: { bsonType: "string", minLength: 1, maxLength: 255 },
                                resource_type: { bsonType: "string", enum: ["document", "link"] },
                                url: { bsonType: ["string", "null"], maxLength: 2048 },
                                object_key: { bsonType: ["string", "null"], minLength: 1, maxLength: 512 }
                            }
                        }
                    },
                    notification_reminder: {
                        bsonType: ["object", "null"],
                        additionalProperties: false,
                        properties: {
                            enabled: { bsonType: "bool" },
                            minutes_before: { bsonType: ["int", "null"], minimum: 1 }
                        }
                    },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_by: { bsonType: ["int", "long", "null"], minimum: 1 },
                    updated_by: { bsonType: ["int", "long", "null"], minimum: 1 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community`

- **Source:** `database/mongo/collections/010_connect_community.js`
- **Purpose:** Connect → Community master (club / society / group)

**Indexes**

- `uq_connect_community_id` — `{ community_id: 1 }` [unique]
- `ix_connect_community_scope_type` — `{ school_id: 1, community_type: 1, is_active: 1 }`
- `ix_connect_community_feed` — `{ school_id: 1, branch_id: 1, is_active: 1, created_at: -1 }`

**Validation script**

```javascript
db.createCollection("connect_community", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "community_id",
                    "school_id",
                    "branch_id",
                    "name",
                    "community_type",
                    "owner_user_id",
                    "member_count",
                    "is_active",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    community_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    branch_id: { bsonType: ["int", "long"], minimum: 1 },
                    name: { bsonType: "string", minLength: 1, maxLength: 200, pattern: "\\S" },
                    community_type: {
                        bsonType: "string",
                        enum: ["club", "society", "group"]
                    },
                    description: { bsonType: ["string", "null"], maxLength: 2000, pattern: "\\S" },
                    owner_user_id: { bsonType: ["int", "long"], minimum: 1 },
                    owner_name: { bsonType: ["string", "null"], maxLength: 200 },
                    owner_role: { bsonType: ["string", "null"], maxLength: 100 },
                    member_count: { bsonType: "int", minimum: 0 },
                    is_trending: { bsonType: ["bool", "null"] },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_by: { bsonType: ["int", "long", "null"] },
                    updated_by: { bsonType: ["int", "long", "null"] }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_member`

- **Source:** `database/mongo/collections/011_connect_community_member.js`
- **Purpose:** Who joined which community + role

**Indexes**

- `uq_connect_community_member` — `{ community_id: 1, user_id: 1 }` [unique]
- `ix_connect_community_member_user` — `{ user_id: 1, membership_status: 1 }`

**Validation script**

```javascript
db.createCollection("connect_community_member", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "community_id",
                    "user_id",
                    "school_id",
                    "member_role",
                    "membership_status",
                    "joined_at",
                    "left_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    community_id: { bsonType: ["int", "long"], minimum: 1 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    display_name: { bsonType: ["string", "null"], maxLength: 200 },
                    user_role: {
                        bsonType: ["string", "null"],
                        enum: ["student", "teacher", "staff", "faculty", "admin", null]
                    },
                    member_role: {
                        bsonType: "string",
                        enum: ["member", "moderator", "owner"]
                    },
                    membership_status: {
                        bsonType: "string",
                        enum: ["joined", "left", "removed"]
                    },
                    joined_at: { bsonType: "date" },
                    left_at: { bsonType: ["date", "null"] }
                },
                oneOf: [
                    { properties: { membership_status: { enum: ["joined"] }, left_at: { bsonType: "null" } } },
                    { properties: { membership_status: { enum: ["left", "removed"] }, left_at: { bsonType: "date" } } }
                ]
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_join_request`

- **Source:** `database/mongo/collections/012_connect_community_join_request.js`
- **Purpose:** Community join requests + invitations

**Indexes**

- `uq_connect_community_join_request_id` — `{ request_id: 1 }` [unique]
- `uq_connect_pending_membership_action` — `{ community_id: 1, user_id: 1 }` [unique]
- `ix_connect_join_request_user_status` — `{ user_id: 1, status: 1 }`
- `ix_connect_join_request_community_status` — `{ community_id: 1, status: 1 }`

**Validation script**

```javascript
db.createCollection("connect_community_join_request", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "request_id",
                    "community_id",
                    "user_id",
                    "school_id",
                    "request_type",
                    "status",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    request_id: { bsonType: ["int", "long"], minimum: 1 },
                    community_id: { bsonType: ["int", "long"], minimum: 1 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    request_type: {
                        bsonType: "string",
                        enum: ["request", "invitation"]
                    },
                    status: {
                        bsonType: "string",
                        enum: ["pending", "accepted", "declined", "cancelled"]
                    },
                    invited_by_user_id: { bsonType: ["int", "long", "null"], minimum: 1 },
                    invited_by_name: { bsonType: ["string", "null"], maxLength: 200 },
                    invited_by_role: { bsonType: ["string", "null"], maxLength: 100 },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_post`

- **Source:** `database/mongo/collections/013_connect_community_post.js`
- **Purpose:** Community feed posts (text / media / attachments)

**Indexes**

- `uq_connect_community_post_id` — `{ post_id: 1 }` [unique]
- `ix_connect_community_post_feed` — `{ community_id: 1, created_at: -1 }`

**Validation script**

```javascript
db.createCollection("connect_community_post", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "post_id",
                    "community_id",
                    "school_id",
                    "author_user_id",
                    "content",
                    "like_count",
                    "is_active",
                    "created_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    post_id: { bsonType: ["int", "long"], minimum: 1 },
                    community_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    author_user_id: { bsonType: ["int", "long"], minimum: 1 },
                    author_name: { bsonType: ["string", "null"], maxLength: 200 },
                    author_role: {
                        bsonType: ["string", "null"],
                        enum: ["student", "teacher", "staff", "faculty", "admin", null]
                    },
                    content: { bsonType: "string", minLength: 1, maxLength: 10000, pattern: "\\S" },
                    media: {
                        bsonType: ["array", "null"],
                        items: {
                            bsonType: "object",
                            required: ["media_id", "media_type"],
                            additionalProperties: false,
                            properties: {
                                media_id: { bsonType: ["int", "long"], minimum: 1 },
                                media_type: { bsonType: "string", enum: ["image", "video"] },
                                object_key: { bsonType: ["string", "null"], maxLength: 2048 },
                                external_url: { bsonType: ["string", "null"], maxLength: 2048 },
                                alt: { bsonType: ["string", "null"], maxLength: 300 }
                            },
                            anyOf: [
                                { required: ["object_key"], properties: { object_key: { bsonType: "string", minLength: 1 } } },
                                { required: ["external_url"], properties: { external_url: { bsonType: "string", minLength: 1 } } }
                            ]
                        }
                    },
                    attachments: {
                        bsonType: ["array", "null"],
                        items: {
                            bsonType: "object",
                            required: ["attachment_id", "attachment_type", "file_name"],
                            additionalProperties: false,
                            properties: {
                                attachment_id: { bsonType: "string", minLength: 1, maxLength: 80 },
                                attachment_type: {
                                    bsonType: "string",
                                    enum: ["image", "document", "video"]
                                },
                                file_name: { bsonType: "string", maxLength: 255 },
                                file_size_label: { bsonType: ["string", "null"], maxLength: 50 },
                                object_key: { bsonType: ["string", "null"], maxLength: 2048 },
                                external_url: { bsonType: ["string", "null"], maxLength: 2048 }
                            },
                            anyOf: [
                                { required: ["object_key"], properties: { object_key: { bsonType: "string", minLength: 1 } } },
                                { required: ["external_url"], properties: { external_url: { bsonType: "string", minLength: 1 } } }
                            ]
                        }
                    },
                    like_count: { bsonType: "int", minimum: 0 },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: ["date", "null"] }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_comment`

- **Source:** `database/mongo/collections/014_connect_community_comment.js`
- **Purpose:** Post comments (not nested comment replies)

**Indexes**

- `uq_connect_community_comment_id` — `{ comment_id: 1 }` [unique]
- `ix_connect_community_comment_post` — `{ post_id: 1, created_at: 1 }`

**Validation script**

```javascript
db.createCollection("connect_community_comment", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "comment_id",
                    "post_id",
                    "community_id",
                    "school_id",
                    "author_user_id",
                    "content",
                    "is_active",
                    "created_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    comment_id: { bsonType: ["int", "long"] },
                    post_id: { bsonType: ["int", "long"] },
                    community_id: { bsonType: ["int", "long"] },
                    school_id: { bsonType: ["int", "long"] },
                    author_user_id: { bsonType: ["int", "long"] },
                    author_name: { bsonType: ["string", "null"], maxLength: 200 },
                    author_role: {
                        bsonType: ["string", "null"],
                        enum: ["student", "teacher", "staff", "faculty", "admin", null]
                    },
                    content: { bsonType: "string", minLength: 1, maxLength: 4000, pattern: "\\S" },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_post_like`

- **Source:** `database/mongo/collections/015_connect_community_post_like.js`
- **Purpose:** One like per user per community post

**Indexes**

- `uq_connect_community_post_like` — `{ post_id: 1, user_id: 1 }` [unique]

**Validation script**

```javascript
db.createCollection("connect_community_post_like", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["post_id", "user_id", "school_id", "created_at"],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    post_id: { bsonType: ["int", "long"] },
                    user_id: { bsonType: ["int", "long"] },
                    school_id: { bsonType: ["int", "long"] },
                    created_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_discussion`

- **Source:** `database/mongo/collections/016_connect_community_discussion.js`
- **Purpose:** Community discussion threads

**Indexes**

- `uq_connect_community_discussion_id` — `{ discussion_id: 1 }` [unique]
- `ix_connect_community_discussion_feed` — `{ community_id: 1, created_at: -1 }`

**Validation script**

```javascript
db.createCollection("connect_community_discussion", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "discussion_id",
                    "community_id",
                    "school_id",
                    "title",
                    "author_user_id",
                    "is_trending",
                    "is_active",
                    "created_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    discussion_id: { bsonType: ["int", "long"] },
                    community_id: { bsonType: ["int", "long"] },
                    school_id: { bsonType: ["int", "long"] },
                    title: { bsonType: "string", minLength: 1, maxLength: 300, pattern: "\\S" },
                    description: { bsonType: ["string", "null"], maxLength: 4000, pattern: "\\S" },
                    author_user_id: { bsonType: ["int", "long"] },
                    author_name: { bsonType: ["string", "null"], maxLength: 200 },
                    author_role: {
                        bsonType: ["string", "null"],
                        enum: ["student", "teacher", "staff", "faculty", "admin", null]
                    },
                    is_trending: { bsonType: "bool" },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: ["date", "null"] }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_discussion_reply`

- **Source:** `database/mongo/collections/017_connect_community_discussion_reply.js`
- **Purpose:** Replies inside a community discussion thread

**Indexes**

- `uq_connect_community_discussion_reply_id` — `{ reply_id: 1 }` [unique]
- `ix_connect_community_discussion_reply_thread` — `{ discussion_id: 1, created_at: 1 }`

**Validation script**

```javascript
db.createCollection("connect_community_discussion_reply", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "reply_id",
                    "discussion_id",
                    "community_id",
                    "school_id",
                    "author_user_id",
                    "content",
                    "is_active",
                    "created_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    reply_id: { bsonType: ["int", "long"] },
                    discussion_id: { bsonType: ["int", "long"] },
                    community_id: { bsonType: ["int", "long"] },
                    school_id: { bsonType: ["int", "long"] },
                    author_user_id: { bsonType: ["int", "long"] },
                    author_name: { bsonType: ["string", "null"], maxLength: 200 },
                    author_role: {
                        bsonType: ["string", "null"],
                        enum: ["student", "teacher", "staff", "faculty", "admin", null]
                    },
                    content: { bsonType: "string", minLength: 1, maxLength: 4000, pattern: "\\S" },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_poll`

- **Source:** `database/mongo/collections/018_connect_community_poll.js`
- **Purpose:** Community polls + option vote counts

**Indexes**

- `uq_connect_community_poll_id` — `{ poll_id: 1 }` [unique]
- `ix_connect_community_poll_feed` — `{ community_id: 1, created_at: -1 }`

**Validation script**

```javascript
db.createCollection("connect_community_poll", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "poll_id",
                    "community_id",
                    "school_id",
                    "question",
                    "options",
                    "total_votes",
                    "is_active",
                    "created_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    poll_id: { bsonType: ["int", "long"] },
                    community_id: { bsonType: ["int", "long"] },
                    school_id: { bsonType: ["int", "long"] },
                    question: { bsonType: "string", minLength: 1, maxLength: 500, pattern: "\\S" },
                    options: {
                        bsonType: "array",
                        minItems: 2,
                        items: {
                            bsonType: "object",
                            required: ["option_id", "label", "vote_count"],
                            additionalProperties: false,
                            properties: {
                                option_id: { bsonType: ["int", "long"], minimum: 1 },
                                label: { bsonType: "string", minLength: 1, maxLength: 300, pattern: "\\S" },
                                vote_count: { bsonType: "int", minimum: 0 }
                            }
                        }
                    },
                    total_votes: { bsonType: "int", minimum: 0 },
                    expires_at: { bsonType: ["date", "null"] },
                    is_active: { bsonType: "bool" },
                    created_at: { bsonType: "date" },
                    created_by: { bsonType: ["int", "long", "null"] }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `connect_community_poll_vote`

- **Source:** `database/mongo/collections/019_connect_community_poll_vote.js`
- **Purpose:** One vote per user per poll

**Indexes**

- `uq_connect_community_poll_vote` — `{ poll_id: 1, user_id: 1 }` [unique]

**Validation script**

```javascript
db.createCollection("connect_community_poll_vote", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "poll_id",
                    "user_id",
                    "school_id",
                    "option_id",
                    "voted_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    poll_id: { bsonType: ["int", "long"], minimum: 1 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    school_id: { bsonType: ["int", "long"], minimum: 1 },
                    option_id: { bsonType: ["int", "long"], minimum: 1 },
                    voted_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

## Auth

### `user_jwt_token`

- **Source:** `database/mongo/collections/020_user_jwt_token.js`
- **Purpose:** Multi-login JWT session tracking per SQL user

**Indexes**

- `uq_user_jwt_session_id` — `{ session_id: 1 }` [unique]
- `ix_user_jwt_user_status` — `{ user_id: 1, status: 1 }`
- `ix_user_jwt_user_refresh_expiry` — `{ user_id: 1, refresh_expires_at: 1 }`
- `uq_user_jwt_refresh_hash` — `{ refresh_token_hash: 1 }` [unique]
- `uq_user_jwt_access_jti` — `{ access_jti: 1 }` [unique]
- `uq_user_jwt_refresh_jti` — `{ refresh_jti: 1 }` [unique]
- `ttl_user_jwt_refresh_expires` — `{ refresh_expires_at: 1 }` [TTL]

**Validation script**

```javascript
db.createCollection("user_jwt_token", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "session_id",
                    "user_id",
                    "device_id",
                    "token_family_id",
                    "access_jti",
                    "refresh_jti",
                    "refresh_token_hash",
                    "access_expires_at",
                    "refresh_expires_at",
                    "status",
                    "is_revoked",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    session_id: { bsonType: "string", minLength: 10, maxLength: 128 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    device_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    token_family_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    access_jti: { bsonType: "string", minLength: 10, maxLength: 128 },
                    refresh_jti: { bsonType: "string", minLength: 10, maxLength: 128 },
                    refresh_token_hash: { bsonType: "string", minLength: 64, maxLength: 64 },
                    access_expires_at: { bsonType: "date" },
                    refresh_expires_at: { bsonType: "date" },
                    status: { bsonType: "string", enum: ["active", "revoked", "expired"] },
                    is_revoked: { bsonType: "bool" },
                    revoked_at: { bsonType: ["date", "null"] },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_ip: { bsonType: ["string", "null"], maxLength: 45 },
                    user_agent: { bsonType: ["string", "null"], maxLength: 500 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

## Shared Documents

### `thinkigen_documents`

- **Source:** `database/mongo/collections/023_thinkigen_documents.js`
- **Purpose:** Central metadata registry for files stored in Azure Blob Storage.

**Validation script**

```javascript
// validator not found for thinkigen_documents
```

## Career Explorer

### `career_industries`

- **Source:** `database/mongo/collections/025_career_explorer.js`
- **Purpose:** Career Explorer domain storing industry categories, key sectors, skills used, and detailed career paths matching UI.

**Indexes**

- `uq_career_industry_id` — `{ industry_id: 1 }` [unique]

**Validation script**

```javascript
db.createCollection("career_industries", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "industry_id",
                    "industry_name",
                    "summary",
                    "about_industry",
                    "why_explore",
                    "key_sectors",
                    "skills_used",
                    "relevant_subjects",
                    "related_industries",
                    "career_path_ids"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    industry_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    industry_name: { bsonType: "string", minLength: 1, maxLength: 150 },
                    summary: { bsonType: "string" },
                    about_industry: { bsonType: "string" },
                    why_explore: {
                        bsonType: "array",
                        items: {
                            bsonType: "object",
                            required: ["title", "description"],
                            properties: {
                                title: { bsonType: "string" },
                                description: { bsonType: "string" }
                            }
                        }
                    },
                    key_sectors: {
                        bsonType: "array",
                        items: {
                            bsonType: "object",
                            required: ["sector_id", "title", "description"],
                            properties: {
                                sector_id: { bsonType: "string" },
                                title: { bsonType: "string" },
                                description: { bsonType: "string" }
                            }
                        }
                    },
                    skills_used: {
                        bsonType: "object",
                        required: ["technical", "transferable"],
                        properties: {
                            technical: { bsonType: "array", items: { bsonType: "string" } },
                            transferable: { bsonType: "array", items: { bsonType: "string" } }
                        }
                    },
                    relevant_subjects: { bsonType: "array", items: { bsonType: "string" } },
                    related_industries: {
                        bsonType: "array",
                        items: {
                            bsonType: "object",
                            required: ["industry_id", "industry_name"],
                            properties: {
                                industry_id: { bsonType: "string" },
                                industry_name: { bsonType: "string" }
                            }
                        }
                    },
                    career_path_ids: { bsonType: "array", items: { bsonType: "string" } },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `career_paths`

- **Source:** `database/mongo/collections/025_career_explorer.js`
- **Purpose:** Career Explorer domain storing industry categories, key sectors, skills used, and detailed career paths matching UI.

**Indexes**

- `uq_career_path_id` — `{ career_id: 1 }` [unique]
- `ix_career_path_industry` — `{ industry_id: 1, title: 1 }`

**Validation script**

```javascript
db.createCollection("career_paths", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "career_id",
                    "industry_id",
                    "industry_name",
                    "category",
                    "title",
                    "subtitle",
                    "about_role",
                    "what_it_involves",
                    "where_it_can_lead",
                    "skills_used",
                    "relevant_subjects"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    career_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    industry_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    industry_name: { bsonType: "string", minLength: 1, maxLength: 150 },
                    category: { bsonType: "string", minLength: 1, maxLength: 100 },
                    title: { bsonType: "string", minLength: 1, maxLength: 150 },
                    subtitle: { bsonType: "string" },
                    about_role: { bsonType: "string" },
                    what_it_involves: {
                        bsonType: "array",
                        items: { bsonType: "string" }
                    },
                    where_it_can_lead: {
                        bsonType: "array",
                        items: { bsonType: "string" }
                    },
                    skills_used: {
                        bsonType: "object",
                        required: ["technical", "transferable"],
                        properties: {
                            technical: { bsonType: "array", items: { bsonType: "string" } },
                            transferable: { bsonType: "array", items: { bsonType: "string" } }
                        }
                    },
                    relevant_subjects: { bsonType: "array", items: { bsonType: "string" } },
                    match_tag: { bsonType: ["string", "null"] },
                    connected_subjects_tag: { bsonType: ["string", "null"] },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

## Other

### `024_connect_community_production_hardening`

- **Source:** `database/mongo/collections/024_connect_community_production_hardening.js`

**Validation script**

```javascript
// validator not found for 024_connect_community_production_hardening
```

### `connect_conversation_user_state`

- **Source:** `database/mongo/collections/020_connect_conversation_user_state.js`
- **Purpose:** Per-user visibility/state for messages in a shared conversation

**Indexes**

- `uq_connect_conversation_user_state` — `{ conversation_id: 1, user_id: 1 }` [unique]
- `ix_connect_conversation_user_state_user_deleted` — `{ user_id: 1, deleted_at: 1, last_read_at: -1 }`
- `ix_connect_conversation_user_state_conversation` — `{ conversation_id: 1, updated_at: -1 }`

**Validation script**

```javascript
db.createCollection("connect_conversation_user_state", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "conversation_id",
                    "user_id",
                    "deleted_at",
                    "last_read_at",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    conversation_id: { bsonType: "string", minLength: 1, maxLength: 80 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    deleted_at: { bsonType: ["date", "null"] },
                    last_read_at: { bsonType: ["date", "null"] },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `course_progress`

- **Source:** `database/mongo/collections/021_course_progress.js`
- **Purpose:** Teacher-controlled section-level course completion percentage.

**Indexes**

- `uq_course_progress_identity` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, syllabus_version: 1, progress_date: 1 }` [unique]
- `ix_course_progress_scope_date` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, subject_id: 1, progress_date: -1 }`

**Validation script**

```javascript
db.createCollection("course_progress", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "progress_id",
                    "school_id",
                    "branch_id",
                    "academic_year_id",
                    "class_id",
                    "section_id",
                    "subject_id",
                    "syllabus_version",
                    "progress_percentage",
                    "progress_date",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    progress_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    school_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    branch_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    academic_year_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    class_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    section_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    subject_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    syllabus_version: { bsonType: "int", minimum: 1 },
                    progress_percentage: { bsonType: "double", minimum: 0, maximum: 100 },
                    progress_date: { bsonType: "date" },
                    timetable_id: { bsonType: ["string", "null"], maxLength: 128 },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_by: { bsonType: ["string", "null"], maxLength: 128 },
                    updated_by: { bsonType: ["string", "null"], maxLength: 128 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

### `student_last_learning_resource`

- **Source:** `database/mongo/collections/022_student_last_learning_resource.js`
- **Purpose:** Remember the single most recent learning resource accessed by each student. This is a pointer to the actual resource document, not a per-resource progress record.

**Indexes**

- `uq_student_last_learning_resource` — `{ student_id: 1 }` [unique]
- `ix_student_last_learning_resource_scope` — `{ school_id: 1, branch_id: 1, academic_year_id: 1, class_id: 1, section_id: 1, student_id: 1 }`

**Validation script**

```javascript
db.createCollection("student_last_learning_resource", {
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
                    "last_resource",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    student_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    school_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    branch_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    academic_year_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    class_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    section_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    last_resource: {
                        bsonType: "object",
                        required: ["resource_id", "subject_id", "chapter_id", "topic_id", "last_accessed_at"],
                        additionalProperties: false,
                        properties: {
                            resource_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                            subject_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                            chapter_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                            topic_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                            last_accessed_at: { bsonType: "date" }
                        }
                    },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
```

---

## Not stored in Mongo

### Connect

- Chat / group message history → Parquet `chat_events`
- Unread / presence / recent message cache → Redis
- Removed: meeting “I'm Interested”

### Overview (SQL / API)

- Classes KPI (timetable + attendance)
- Assignments KPI
- Next assessment card (`exam_schedule`)
- Teacher homework / assignment checklist rows

---

## Apply (local)

```javascript
load("database/mongo/collections/001_student_mission_control_daily.js");
load("database/mongo/collections/002_student_compass_intelligence_daily.js");
load("database/mongo/collections/003_student_learning_health_daily.js");
load("database/mongo/collections/004_class_subject_syllabus.js");
load("database/mongo/collections/005_learning_resource(documets).js");
load("database/mongo/collections/008_connect_conversation.js");
load("database/mongo/collections/009_connect_meeting.js");
load("database/mongo/collections/010_connect_community.js");
load("database/mongo/collections/011_connect_community_member.js");
load("database/mongo/collections/012_connect_community_join_request.js");
load("database/mongo/collections/013_connect_community_post.js");
load("database/mongo/collections/014_connect_community_comment.js");
load("database/mongo/collections/015_connect_community_post_like.js");
load("database/mongo/collections/016_connect_community_discussion.js");
load("database/mongo/collections/017_connect_community_discussion_reply.js");
load("database/mongo/collections/018_connect_community_poll.js");
load("database/mongo/collections/019_connect_community_poll_vote.js");
load("database/mongo/collections/020_connect_conversation_user_state.js");
load("database/mongo/collections/020_user_jwt_token.js");
load("database/mongo/collections/021_course_progress.js");
load("database/mongo/collections/022_student_last_learning_resource.js");
load("database/mongo/collections/023_thinkigen_documents.js");
load("database/mongo/collections/024_connect_community_production_hardening.js");
load("database/mongo/collections/025_career_explorer.js");
load("database/mongo/collections/05_exam_paper.js");
```

Or run each file in `mongosh` against the Organization database.

---

## Regenerate this document

```bash
python database/scripts/generate_mongodb_collections_reference.py
```

## Related docs

| Doc | Path |
|-----|------|
| SQL full table reference | [full-table-reference.md](./full-table-reference.md) |
| Mongo apply notes | `database/mongo/README.md` |
| Chat Parquet | `database/parquet/connect_chat_events.md` |
| Community Parquet | `database/parquet/connect_community_events.md` |
| Redis keys | `database/redis/connect_keys.md` |
