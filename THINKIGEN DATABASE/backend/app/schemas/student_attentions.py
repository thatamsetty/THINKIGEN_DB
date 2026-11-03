"""
Thinkigen School ERP - Student Subject Attentions Pydantic Schemas.
Enforces:
- Strict cross-field conditional validation for attention sources
- Deterministic ID validation
- Status transitions and audit tracking
- Safe data types compatible with MongoDB BSON
"""

from __future__ import annotations

from datetime import datetime, date
from decimal import Decimal
from enum import Enum
from typing import Optional, List, Union
from pydantic import BaseModel, Field, model_validator, ConfigDict


class AttentionType(str, Enum):
    LOW_ASSESSMENT_SCORE = "LOW_ASSESSMENT_SCORE"
    PENDING_HOMEWORK = "PENDING_HOMEWORK"
    ABSENT_ATTENDANCE = "ABSENT_ATTENDANCE"


class AttentionSeverity(str, Enum):
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"


class TriggerSource(str, Enum):
    ASSESSMENT = "ASSESSMENT"
    ASSIGNMENT_HOMEWORK = "ASSIGNMENT_HOMEWORK"
    ATTENDANCE = "ATTENDANCE"


class AttentionStatus(str, Enum):
    ACTIVE = "ACTIVE"
    ACKNOWLEDGED = "ACKNOWLEDGED"
    RESOLVED = "RESOLVED"
    EXCUSED = "EXCUSED"


class HomeworkSubmissionStatus(str, Enum):
    PENDING = "PENDING"
    NOT_SUBMITTED = "NOT_SUBMITTED"
    LATE = "LATE"


class AttendancePeriodStatus(str, Enum):
    ABSENT = "ABSENT"
    UNEXCUSED_ABSENCE = "UNEXCUSED_ABSENCE"
    LATE = "LATE"


# -----------------------------------------------------------------------------
# Contextual Detail Models
# -----------------------------------------------------------------------------

class AssessmentDetails(BaseModel):
    model_config = ConfigDict(extra="forbid")

    assessment_id: int = Field(..., ge=1, description="SQL Server assessment_id")
    assessment_name: str = Field(..., min_length=1, max_length=150)
    exam_type: Optional[str] = Field(None, max_length=50)
    max_marks: Union[int, float, Decimal] = Field(..., ge=0)
    pass_marks: Union[int, float, Decimal] = Field(..., ge=0)
    obtained_marks: Union[int, float, Decimal] = Field(..., ge=0)
    percentage: Union[int, float, Decimal] = Field(..., ge=0, le=100)


class HomeworkDetails(BaseModel):
    model_config = ConfigDict(extra="forbid")

    homework_id: int = Field(..., ge=1, description="SQL Server homework_id")
    homework_title: str = Field(..., min_length=1, max_length=200)
    assigned_date: Union[datetime, date]
    due_date: Union[datetime, date]
    days_overdue: Optional[int] = Field(None, ge=0)
    submission_status: HomeworkSubmissionStatus


class AttendanceDetails(BaseModel):
    model_config = ConfigDict(extra="forbid")

    attendance_id: Optional[int] = Field(None, ge=1, description="SQL Server student_attendance_id")
    attendance_date: Union[datetime, date]
    period_number: int = Field(..., ge=1)
    period_time: Optional[str] = Field(None, max_length=30)
    attendance_status: AttendancePeriodStatus


# -----------------------------------------------------------------------------
# Attention Item Models
# -----------------------------------------------------------------------------

class AttentionItemBase(BaseModel):
    model_config = ConfigDict(extra="forbid")

    attention_id: str = Field(..., min_length=1, max_length=64, description="Deterministic stable attention ID")
    attention_type: AttentionType
    severity: AttentionSeverity
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., min_length=1, max_length=500)
    trigger_source: TriggerSource
    source_id: int = Field(..., ge=1)
    triggered_at: datetime
    status: AttentionStatus = Field(default=AttentionStatus.ACTIVE)

    acknowledged_at: Optional[datetime] = None
    acknowledged_by_teacher_id: Optional[int] = Field(None, ge=1)

    resolved_at: Optional[datetime] = None
    resolved_by_teacher_id: Optional[int] = Field(None, ge=1)
    resolution_remarks: Optional[str] = Field(None, max_length=500)
    excused_reason: Optional[str] = Field(None, max_length=500)

    assessment_details: Optional[AssessmentDetails] = None
    homework_details: Optional[HomeworkDetails] = None
    attendance_details: Optional[AttendanceDetails] = None

    @model_validator(mode="after")
    def validate_attention_type_and_source_details(self) -> AttentionItemBase:
        """
        Enforce strict cross-field business logic:
        1. LOW_ASSESSMENT_SCORE -> trigger_source=ASSESSMENT, assessment_details required, others null
        2. PENDING_HOMEWORK -> trigger_source=ASSIGNMENT_HOMEWORK, homework_details required, others null
        3. ABSENT_ATTENDANCE -> trigger_source=ATTENDANCE, attendance_details required, others null
        """
        att_type = self.attention_type
        src = self.trigger_source

        if att_type == AttentionType.LOW_ASSESSMENT_SCORE:
            if src != TriggerSource.ASSESSMENT:
                raise ValueError(
                    f"LOW_ASSESSMENT_SCORE must have trigger_source = ASSESSMENT, received '{src}'"
                )
            if self.assessment_details is None:
                raise ValueError("assessment_details is required for LOW_ASSESSMENT_SCORE")
            if self.homework_details is not None or self.attendance_details is not None:
                raise ValueError(
                    "homework_details and attendance_details must be null for LOW_ASSESSMENT_SCORE"
                )

        elif att_type == AttentionType.PENDING_HOMEWORK:
            if src != TriggerSource.ASSIGNMENT_HOMEWORK:
                raise ValueError(
                    f"PENDING_HOMEWORK must have trigger_source = ASSIGNMENT_HOMEWORK, received '{src}'"
                )
            if self.homework_details is None:
                raise ValueError("homework_details is required for PENDING_HOMEWORK")
            if self.assessment_details is not None or self.attendance_details is not None:
                raise ValueError(
                    "assessment_details and attendance_details must be null for PENDING_HOMEWORK"
                )

        elif att_type == AttentionType.ABSENT_ATTENDANCE:
            if src != TriggerSource.ATTENDANCE:
                raise ValueError(
                    f"ABSENT_ATTENDANCE must have trigger_source = ATTENDANCE, received '{src}'"
                )
            if self.attendance_details is None:
                raise ValueError("attendance_details is required for ABSENT_ATTENDANCE")
            if self.assessment_details is not None or self.homework_details is not None:
                raise ValueError(
                    "assessment_details and homework_details must be null for ABSENT_ATTENDANCE"
                )

        # Audit validation for resolution
        if self.status == AttentionStatus.RESOLVED:
            if self.resolved_at is None:
                raise ValueError("resolved_at must be populated when status is RESOLVED")
        elif self.status == AttentionStatus.EXCUSED:
            if self.excused_reason is None:
                raise ValueError("excused_reason must be populated when status is EXCUSED")

        return self


# -----------------------------------------------------------------------------
# Subject & Document Models
# -----------------------------------------------------------------------------

class SubjectSummary(BaseModel):
    model_config = ConfigDict(extra="forbid")

    assessments_passed: int = Field(default=0, ge=0)
    assessments_failed: int = Field(default=0, ge=0)
    homework_submitted: int = Field(default=0, ge=0)
    homework_pending: int = Field(default=0, ge=0)
    subject_attendance_percent: Optional[Union[int, float, Decimal]] = Field(None, ge=0, le=100)


class SubjectAttentionItem(BaseModel):
    model_config = ConfigDict(extra="forbid")

    subject_id: int = Field(..., ge=1)
    subject_name: str = Field(..., min_length=1, max_length=100)
    subject_code: str = Field(..., min_length=1, max_length=30)
    assigned_teacher_id: Optional[int] = Field(None, ge=1)
    assigned_teacher_name: Optional[str] = Field(None, max_length=150)
    active_attentions_count: int = Field(default=0, ge=0)
    attentions: List[AttentionItemBase] = Field(default_factory=list)
    subject_summary: Optional[SubjectSummary] = None


class StudentSubjectAttentionDocument(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: Optional[str] = Field(None, alias="_id")
    student_id: int = Field(..., ge=1)
    student_name: str = Field(..., min_length=1, max_length=150)
    admission_number: Optional[str] = Field(None, max_length=50)
    roll_number: Optional[str] = Field(None, max_length=50)
    school_id: int = Field(..., ge=1)
    branch_id: int = Field(..., ge=1)
    academic_year_id: int = Field(..., ge=1)
    class_id: int = Field(..., ge=1)
    class_name: str = Field(..., min_length=1, max_length=50)
    section_id: int = Field(..., ge=1)
    section_name: str = Field(..., min_length=1, max_length=20)
    total_active_attentions: int = Field(default=0, ge=0)
    critical_attentions_count: int = Field(default=0, ge=0)
    subjects: List[SubjectAttentionItem] = Field(default_factory=list)
    last_evaluated_at: datetime
    is_active: int = Field(default=1)
    created_at: datetime
    updated_at: datetime

    def recalculate_counts(self) -> None:
        """
        Recalculates counts according to strict specification:
        - total_active_attentions = count of attention records with status == ACTIVE across all subjects
        - critical_attentions_count = count of ACTIVE attention records with severity == CRITICAL
        - active_attentions_count = count of ACTIVE attention records within each subject
        """
        tot_active = 0
        crit_active = 0
        for sub in self.subjects:
            sub_active = 0
            for att in sub.attentions:
                if att.status == AttentionStatus.ACTIVE:
                    sub_active += 1
                    tot_active += 1
                    if att.severity == AttentionSeverity.CRITICAL:
                        crit_active += 1
            sub.active_attentions_count = sub_active

        self.total_active_attentions = tot_active
        self.critical_attentions_count = crit_active


# -----------------------------------------------------------------------------
# Request & Response DTOs
# -----------------------------------------------------------------------------

class AttentionAcknowledgeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    teacher_id: int = Field(..., ge=1)


class AttentionResolveRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    teacher_id: int = Field(..., ge=1)
    resolution_remarks: str = Field(..., min_length=3, max_length=500)


class AttentionExcuseRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    teacher_id: int = Field(..., ge=1)
    excused_reason: str = Field(..., min_length=3, max_length=500)
    resolution_remarks: Optional[str] = Field(None, max_length=500)
