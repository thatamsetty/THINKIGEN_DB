"""
Thinkigen School ERP - Student Subject Attentions Service & Data Access Layer.
Enforces:
- Deterministic ID generation preventing duplicate attention records
- Idempotent MongoDB upserts & worker concurrency safety
- Strict attention lifecycle status transitions (ACTIVE -> ACKNOWLEDGED -> RESOLVED / EXCUSED)
- Real-time atomic count recalculation via MongoDB aggregation update pipelines
- Scoped multi-tenant and role-based query isolation for Teachers & Management
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from app.schemas.student_attentions import (
    AttentionType,
    AttentionSeverity,
    TriggerSource,
    AttentionStatus,
    AttentionItemBase,
    AssessmentDetails,
    HomeworkDetails,
    AttendanceDetails,
    StudentSubjectAttentionDocument,
)

logger = logging.getLogger("thinkigen.attentions")


def generate_deterministic_attention_id(
    student_id: int,
    trigger_source: TriggerSource,
    source_id: int,
    academic_year_id: int,
) -> str:
    """
    Generates a deterministic, immutable attention ID.
    Guarantees idempotency across retry workers and scheduled cron syncs.
    Format: ATT-{student_id}-{SRC_CODE}-{source_id}-{academic_year_id}
    """
    prefix_map = {
        TriggerSource.ASSESSMENT: "ASM",
        TriggerSource.ASSIGNMENT_HOMEWORK: "HW",
        TriggerSource.ATTENDANCE: "ATT",
    }
    src_code = prefix_map[trigger_source]
    return f"ATT-{student_id}-{src_code}-{source_id}-{academic_year_id}"


class StudentAttentionService:
    """
    Principal Service handling Student Subject Attentions lifecycle,
    idempotent generation, and atomic count synchronization.
    """

    COLLECTION_NAME = "student_subject_attentions"

    def __init__(self, mongo_db: Any):
        self.db = mongo_db
        self.collection = mongo_db[self.COLLECTION_NAME]

    # -------------------------------------------------------------------------
    # 1. Idempotent Attention Generation & Upsert
    # -------------------------------------------------------------------------
    async def upsert_attention_record(
        self,
        student_id: int,
        student_name: str,
        school_id: int,
        branch_id: int,
        academic_year_id: int,
        class_id: int,
        class_name: str,
        section_id: int,
        section_name: str,
        subject_id: int,
        subject_name: str,
        subject_code: str,
        assigned_teacher_id: Optional[int],
        assigned_teacher_name: Optional[str],
        attention_item: AttentionItemBase,
        admission_number: Optional[str] = None,
        roll_number: Optional[str] = None,
    ) -> bool:
        """
        Idempotently inserts or updates an attention record.
        Prevents duplicate attention records in arrays during worker retries or concurrency.
        """
        now = datetime.now(timezone.utc)

        # Step 1: Ensure Root Document Exists (Upsert student document skeleton if missing)
        await self.collection.update_one(
            {
                "student_id": student_id,
                "academic_year_id": academic_year_id,
            },
            {
                "$setOnInsert": {
                    "student_id": student_id,
                    "student_name": student_name,
                    "admission_number": admission_number,
                    "roll_number": roll_number,
                    "school_id": school_id,
                    "branch_id": branch_id,
                    "academic_year_id": academic_year_id,
                    "class_id": class_id,
                    "class_name": class_name,
                    "section_id": section_id,
                    "section_name": section_name,
                    "total_active_attentions": 0,
                    "critical_attentions_count": 0,
                    "subjects": [],
                    "is_active": 1,
                    "created_at": now,
                },
                "$set": {
                    "last_evaluated_at": now,
                    "updated_at": now,
                },
            },
            upsert=True,
        )

        # Step 2: Ensure Subject Element Exists in subjects array
        await self.collection.update_one(
            {
                "student_id": student_id,
                "academic_year_id": academic_year_id,
                "subjects.subject_id": {"$ne": subject_id},
            },
            {
                "$push": {
                    "subjects": {
                        "subject_id": subject_id,
                        "subject_name": subject_name,
                        "subject_code": subject_code,
                        "assigned_teacher_id": assigned_teacher_id,
                        "assigned_teacher_name": assigned_teacher_name,
                        "active_attentions_count": 0,
                        "attentions": [],
                        "subject_summary": None,
                    }
                },
                "$set": {"updated_at": now},
            },
        )

        # Step 3: Attempt Update if attention_id already exists (idempotent overwrite)
        att_dict = attention_item.model_dump(exclude_none=False)
        update_existing_res = await self.collection.update_one(
            {
                "student_id": student_id,
                "academic_year_id": academic_year_id,
                "subjects.subject_id": subject_id,
                "subjects.attentions.attention_id": attention_item.attention_id,
            },
            {
                "$set": {
                    "subjects.$[sub].attentions.$[att].title": attention_item.title,
                    "subjects.$[sub].attentions.$[att].description": attention_item.description,
                    "subjects.$[sub].attentions.$[att].severity": attention_item.severity.value,
                    "subjects.$[sub].attentions.$[att].assessment_details": (
                        attention_item.assessment_details.model_dump()
                        if attention_item.assessment_details
                        else None
                    ),
                    "subjects.$[sub].attentions.$[att].homework_details": (
                        attention_item.homework_details.model_dump()
                        if attention_item.homework_details
                        else None
                    ),
                    "subjects.$[sub].attentions.$[att].attendance_details": (
                        attention_item.attendance_details.model_dump()
                        if attention_item.attendance_details
                        else None
                    ),
                    "last_evaluated_at": now,
                    "updated_at": now,
                }
            },
            array_filters=[
                {"sub.subject_id": subject_id},
                {"att.attention_id": attention_item.attention_id},
            ],
        )

        # Step 4: If attention was not present, push it safely using $ne: attention_id
        if update_existing_res.matched_count == 0:
            push_res = await self.collection.update_one(
                {
                    "student_id": student_id,
                    "academic_year_id": academic_year_id,
                    "subjects.subject_id": subject_id,
                    "subjects.attentions.attention_id": {"$ne": attention_item.attention_id},
                },
                {
                    "$push": {
                        "subjects.$.attentions": att_dict,
                    },
                    "$set": {
                        "last_evaluated_at": now,
                        "updated_at": now,
                    },
                },
            )
            logger.info(
                "Pushed new attention %s for student %s in subject %s (matched: %s)",
                attention_item.attention_id,
                student_id,
                subject_id,
                push_res.matched_count,
            )

        # Step 5: Atomically recalculate all document counts
        await self.recalculate_document_counts_atomic(student_id, academic_year_id)
        return True

    # -------------------------------------------------------------------------
    # 2. Status Lifecycle Transitions
    # -------------------------------------------------------------------------
    async def acknowledge_attention(
        self,
        student_id: int,
        academic_year_id: int,
        subject_id: int,
        attention_id: str,
        teacher_id: int,
    ) -> bool:
        """
        Transitions attention from ACTIVE to ACKNOWLEDGED.
        Records teacher identity and timestamp.
        """
        now = datetime.now(timezone.utc)
        res = await self.collection.update_one(
            {
                "student_id": student_id,
                "academic_year_id": academic_year_id,
                "subjects.subject_id": subject_id,
                "subjects.attentions.attention_id": attention_id,
                "subjects.attentions.status": AttentionStatus.ACTIVE.value,
            },
            {
                "$set": {
                    "subjects.$[sub].attentions.$[att].status": AttentionStatus.ACKNOWLEDGED.value,
                    "subjects.$[sub].attentions.$[att].acknowledged_at": now,
                    "subjects.$[sub].attentions.$[att].acknowledged_by_teacher_id": teacher_id,
                    "updated_at": now,
                }
            },
            array_filters=[
                {"sub.subject_id": subject_id},
                {"att.attention_id": attention_id},
            ],
        )

        if res.modified_count > 0:
            await self.recalculate_document_counts_atomic(student_id, academic_year_id)
            return True
        return False

    async def resolve_attention(
        self,
        student_id: int,
        academic_year_id: int,
        subject_id: int,
        attention_id: str,
        teacher_id: int,
        resolution_remarks: str,
    ) -> bool:
        """
        Resolves an attention. Preserves historical alert item.
        Recalculates counts so active counts decrement.
        """
        now = datetime.now(timezone.utc)
        res = await self.collection.update_one(
            {
                "student_id": student_id,
                "academic_year_id": academic_year_id,
                "subjects.subject_id": subject_id,
                "subjects.attentions.attention_id": attention_id,
                "subjects.attentions.status": {
                    "$in": [AttentionStatus.ACTIVE.value, AttentionStatus.ACKNOWLEDGED.value]
                },
            },
            {
                "$set": {
                    "subjects.$[sub].attentions.$[att].status": AttentionStatus.RESOLVED.value,
                    "subjects.$[sub].attentions.$[att].resolved_at": now,
                    "subjects.$[sub].attentions.$[att].resolved_by_teacher_id": teacher_id,
                    "subjects.$[sub].attentions.$[att].resolution_remarks": resolution_remarks,
                    "updated_at": now,
                }
            },
            array_filters=[
                {"sub.subject_id": subject_id},
                {"att.attention_id": attention_id},
            ],
        )

        if res.modified_count > 0:
            await self.recalculate_document_counts_atomic(student_id, academic_year_id)
            return True
        return False

    async def excuse_attention(
        self,
        student_id: int,
        academic_year_id: int,
        subject_id: int,
        attention_id: str,
        teacher_id: int,
        excused_reason: str,
        resolution_remarks: Optional[str] = None,
    ) -> bool:
        """
        Excuses an attention with formal reason (e.g. Medical or Official Leave).
        """
        now = datetime.now(timezone.utc)
        res = await self.collection.update_one(
            {
                "student_id": student_id,
                "academic_year_id": academic_year_id,
                "subjects.subject_id": subject_id,
                "subjects.attentions.attention_id": attention_id,
                "subjects.attentions.status": {
                    "$in": [AttentionStatus.ACTIVE.value, AttentionStatus.ACKNOWLEDGED.value]
                },
            },
            {
                "$set": {
                    "subjects.$[sub].attentions.$[att].status": AttentionStatus.EXCUSED.value,
                    "subjects.$[sub].attentions.$[att].resolved_at": now,
                    "subjects.$[sub].attentions.$[att].resolved_by_teacher_id": teacher_id,
                    "subjects.$[sub].attentions.$[att].excused_reason": excused_reason,
                    "subjects.$[sub].attentions.$[att].resolution_remarks": resolution_remarks,
                    "updated_at": now,
                }
            },
            array_filters=[
                {"sub.subject_id": subject_id},
                {"att.attention_id": attention_id},
            ],
        )

        if res.modified_count > 0:
            await self.recalculate_document_counts_atomic(student_id, academic_year_id)
            return True
        return False

    # -------------------------------------------------------------------------
    # 3. Atomic Server-Side Count Recalculation
    # -------------------------------------------------------------------------
    async def recalculate_document_counts_atomic(
        self, student_id: int, academic_year_id: int
    ) -> None:
        """
        Executes an atomic MongoDB aggregation update pipeline that computes
        exact counts in a single database roundtrip without lost updates.
        """
        pipeline = [
            {
                "$set": {
                    "subjects": {
                        "$map": {
                            "input": "$subjects",
                            "as": "sub",
                            "in": {
                                "$mergeObjects": [
                                    "$$sub",
                                    {
                                        "active_attentions_count": {
                                            "$size": {
                                                "$filter": {
                                                    "input": "$$sub.attentions",
                                                    "as": "att",
                                                    "cond": {"$eq": ["$$att.status", "ACTIVE"]},
                                                }
                                            }
                                        }
                                    },
                                ]
                            },
                        }
                    }
                }
            },
            {
                "$set": {
                    "total_active_attentions": {
                        "$reduce": {
                            "input": "$subjects",
                            "initialValue": 0,
                            "in": {"$add": ["$$value", "$$this.active_attentions_count"]},
                        }
                    },
                    "critical_attentions_count": {
                        "$reduce": {
                            "input": "$subjects",
                            "initialValue": 0,
                            "in": {
                                "$add": [
                                    "$$value",
                                    {
                                        "$size": {
                                            "$filter": {
                                                "input": "$$this.attentions",
                                                "as": "att",
                                                "cond": {
                                                    "$and": [
                                                        {"$eq": ["$$att.status", "ACTIVE"]},
                                                        {"$eq": ["$$att.severity", "CRITICAL"]},
                                                    ]
                                                },
                                            }
                                        }
                                    },
                                ]
                            },
                        }
                    },
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        ]

        await self.collection.update_one(
            {"student_id": student_id, "academic_year_id": academic_year_id},
            pipeline,
        )

    # -------------------------------------------------------------------------
    # 4. Production Dashboard Query Patterns
    # -------------------------------------------------------------------------

    async def get_teacher_dashboard(
        self,
        teacher_id: int,
        academic_year_id: int,
        school_id: int,
        branch_id: int,
    ) -> List[Dict[str, Any]]:
        """
        Pattern 1: Subject Teacher Dashboard.
        Uses $elemMatch to match documents where assigned_teacher_id matches and active_attentions_count > 0.
        Uses $filter in projection so the teacher ONLY sees subjects assigned to them.
        """
        pipeline = [
            {
                "$match": {
                    "school_id": school_id,
                    "branch_id": branch_id,
                    "academic_year_id": academic_year_id,
                    "subjects": {
                        "$elemMatch": {
                            "assigned_teacher_id": teacher_id,
                            "active_attentions_count": {"$gt": 0},
                        }
                    },
                }
            },
            {
                "$project": {
                    "student_id": 1,
                    "student_name": 1,
                    "admission_number": 1,
                    "roll_number": 1,
                    "class_name": 1,
                    "section_name": 1,
                    "assigned_subjects": {
                        "$filter": {
                            "input": "$subjects",
                            "as": "sub",
                            "cond": {
                                "$and": [
                                    {"$eq": ["$$sub.assigned_teacher_id", teacher_id]},
                                    {"$gt": ["$$sub.active_attentions_count", 0]},
                                ]
                            },
                        }
                    },
                }
            },
        ]
        cursor = self.collection.aggregate(pipeline)
        return await cursor.to_list(length=500)

    async def get_class_teacher_section_overview(
        self,
        school_id: int,
        branch_id: int,
        academic_year_id: int,
        class_id: int,
        section_id: int,
    ) -> List[Dict[str, Any]]:
        """
        Pattern 4: Class Teacher Complete Section Overview.
        Sorted by total_active_attentions DESC so students requiring urgent intervention appear first.
        Covered by index: ix_student_attentions_section_total.
        """
        cursor = self.collection.find(
            {
                "school_id": school_id,
                "branch_id": branch_id,
                "academic_year_id": academic_year_id,
                "class_id": class_id,
                "section_id": section_id,
            }
        ).sort("total_active_attentions", -1)
        return await cursor.to_list(length=100)

    async def get_management_summary(
        self,
        school_id: int,
        branch_id: int,
        academic_year_id: int,
    ) -> List[Dict[str, Any]]:
        """
        Pattern 5: School / Branch Level Management Attention Summary.
        Aggregates systemic academic risks across classes and sections.
        """
        pipeline = [
            {
                "$match": {
                    "school_id": school_id,
                    "branch_id": branch_id,
                    "academic_year_id": academic_year_id,
                }
            },
            {
                "$group": {
                    "_id": {
                        "class_id": "$class_id",
                        "class_name": "$class_name",
                        "section_id": "$section_id",
                        "section_name": "$section_name",
                    },
                    "total_students_enrolled": {"$sum": 1},
                    "students_with_alerts": {
                        "$sum": {"$cond": [{"$gt": ["$total_active_attentions", 0]}, 1, 0]}
                    },
                    "total_active_alerts": {"$sum": "$total_active_attentions"},
                    "total_critical_alerts": {"$sum": "$critical_attentions_count"},
                }
            },
            {
                "$sort": {
                    "_id.class_id": 1,
                    "_id.section_id": 1,
                }
            },
        ]
        cursor = self.collection.aggregate(pipeline)
        return await cursor.to_list(length=200)
