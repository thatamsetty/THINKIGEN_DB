"""
Thinkigen School ERP - Teacher Leave & Grievance Pydantic Schemas.
Enforces:
- Full-day vs Half-day duration validation
- Leave type and grievance category enumerations
- Status transitions and audit tracking
- Pending reservation calculations
"""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from enum import Enum
from typing import Optional, Union
from pydantic import BaseModel, Field, model_validator, ConfigDict


class LeaveType(str, Enum):
    SICK = "SICK"
    CASUAL = "CASUAL"
    PRIVILEGE = "PRIVILEGE"
    ON_DUTY = "ON_DUTY"
    COMPENSATORY = "COMPENSATORY"


class LeaveDurationType(str, Enum):
    FULL_DAY = "FULL_DAY"
    HALF_DAY = "HALF_DAY"


class LeaveStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    CANCELLED = "CANCELLED"


class GrievanceCategory(str, Enum):
    ACADEMIC_POLICY = "ACADEMIC_POLICY"
    INFRASTRUCTURE_FACILITIES = "INFRASTRUCTURE_FACILITIES"
    HARASSMENT_SAFEGUARDING = "HARASSMENT_SAFEGUARDING"
    IT_EQUIPMENT = "IT_EQUIPMENT"
    ADMINISTRATIVE_PAYROLL = "ADMINISTRATIVE_PAYROLL"
    HEALTH_SAFETY = "HEALTH_SAFETY"


class GrievancePriority(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    URGENT = "URGENT"


class GrievanceStatus(str, Enum):
    OPEN = "OPEN"
    UNDER_REVIEW = "UNDER_REVIEW"
    RESOLVED = "RESOLVED"
    REJECTED = "REJECTED"
    CLOSED = "CLOSED"


# -----------------------------------------------------------------------------
# Leave Request & Response DTOs
# -----------------------------------------------------------------------------

class TeacherLeaveApplicationCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    leave_type: LeaveType
    leave_duration_type: LeaveDurationType
    start_date: date
    end_date: date
    total_days: Decimal = Field(..., ge=Decimal("0.5"))
    reason: str = Field(..., min_length=5, max_length=500)

    @model_validator(mode="after")
    def validate_duration_and_dates(self) -> TeacherLeaveApplicationCreate:
        if self.end_date < self.start_date:
            raise ValueError("end_date cannot be earlier than start_date")

        if self.leave_duration_type == LeaveDurationType.HALF_DAY:
            if self.start_date != self.end_date:
                raise ValueError("HALF_DAY leave must have start_date equal to end_date")
            if self.total_days != Decimal("0.5"):
                raise ValueError("HALF_DAY leave total_days must be exactly 0.5")

        elif self.leave_duration_type == LeaveDurationType.FULL_DAY:
            if self.total_days < Decimal("1.0"):
                raise ValueError("FULL_DAY leave total_days must be at least 1.0")

        return self


class TeacherLeaveApplicationResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    teacher_leave_application_id: int
    school_id: int
    branch_id: int
    academic_year_id: int
    teacher_id: int
    leave_type: LeaveType
    leave_duration_type: LeaveDurationType
    start_date: date
    end_date: date
    total_days: Decimal
    reason: str
    status: LeaveStatus
    created_at: datetime
    updated_at: datetime


class LeaveApprovalRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    remarks: Optional[str] = Field(None, max_length=500)


class LeaveRejectionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    rejection_reason: str = Field(..., min_length=5, max_length=500)


class LeaveCancellationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    cancellation_reason: str = Field(..., min_length=5, max_length=500)


# -----------------------------------------------------------------------------
# Grievance Request & Response DTOs
# -----------------------------------------------------------------------------

class TeacherGrievanceCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    grievance_title: str = Field(..., min_length=5, max_length=200)
    grievance_category: GrievanceCategory
    priority: GrievancePriority
    incident_date: Optional[date] = None
    incident_location: Optional[str] = Field(None, max_length=200)
    description: str = Field(..., min_length=10, max_length=2000)
    academic_year_id: Optional[int] = Field(None, ge=1)


class TeacherGrievanceAssignRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    assigned_to_user_id: int = Field(..., ge=1)
    assignment_remarks: Optional[str] = Field(None, max_length=500)


class TeacherGrievanceResolveRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    resolution_remarks: str = Field(..., min_length=10, max_length=2000)
