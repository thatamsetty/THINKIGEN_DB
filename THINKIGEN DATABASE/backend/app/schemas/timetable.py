"""
Pydantic Schemas and DTOs for Timetable and Timetable Period.
Includes subject_topic validation, ISO datetime serialization, and row_version concurrency tokens.
"""

from __future__ import annotations

from datetime import date, time, datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, model_validator


class PeriodType(str, Enum):
    CLASS = "CLASS"
    BREAK = "BREAK"
    LUNCH = "LUNCH"
    ACTIVITY = "ACTIVITY"
    FREE = "FREE"


class TimetablePeriodBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    period_date: date = Field(..., description="Calendar date for the period slot (YYYY-MM-DD)")
    period_number: int = Field(..., gt=0, le=15, description="Sequential period index per day (1, 2, 3...)")
    period_name: Optional[str] = Field(None, max_length=50, description="Period label (e.g. 'Period 1', 'Morning Break')")
    start_time: time = Field(..., description="Slot start time (HH:mm:ss)")
    end_time: time = Field(..., description="Slot end time (HH:mm:ss)")
    period_type: PeriodType = Field(..., description="Type of period: CLASS, BREAK, LUNCH, ACTIVITY, FREE")
    subject_id: Optional[int] = Field(None, description="Foreign key to management_schema.subject (required if CLASS)")
    subject_topic: Optional[str] = Field(
        None,
        max_length=200,
        description="Daily planned lesson/chapter topic for CLASS periods (e.g. 'Algebra Ex 3.1', 'Plant Cell Biology')"
    )
    teacher_id: Optional[int] = Field(None, description="Assigned teacher ID (required if CLASS)")
    room_name: Optional[str] = Field(None, max_length=150, description="Room identifier (e.g. 'Room-01')")
    activity_name: Optional[str] = Field(None, max_length=150, description="Activity description for ACTIVITY periods")

    @model_validator(mode="after")
    def validate_period_business_rules(self) -> TimetablePeriodBase:
        if self.end_time <= self.start_time:
            raise ValueError("end_time must be greater than start_time.")

        if self.period_type == PeriodType.CLASS:
            if self.subject_id is None:
                raise ValueError("subject_id is required when period_type is 'CLASS'.")
            if self.teacher_id is None:
                raise ValueError("teacher_id is required when period_type is 'CLASS'.")
        else:
            if self.subject_topic is not None and self.subject_topic.strip():
                raise ValueError(
                    f"subject_topic is only permitted when period_type is 'CLASS' (got '{self.period_type.value}')."
                )

        return self


class TimetablePeriodCreate(TimetablePeriodBase):
    timetable_id: int = Field(..., description="Foreign key to management_schema.timetable")


class TimetablePeriodUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    period_name: Optional[str] = Field(None, max_length=50)
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    period_type: Optional[PeriodType] = None
    subject_id: Optional[int] = None
    subject_topic: Optional[str] = Field(
        None,
        max_length=200,
        description="Daily planned lesson/chapter topic for CLASS periods"
    )
    teacher_id: Optional[int] = None
    room_name: Optional[str] = Field(None, max_length=150)
    activity_name: Optional[str] = Field(None, max_length=150)
    is_active: Optional[bool] = Field(None, description="Soft active flag (0=deleted, 1=active)")
    row_version: str = Field(..., description="Hex/Base64 concurrency token to detect conflicting updates")

    @model_validator(mode="after")
    def validate_update_rules(self) -> TimetablePeriodUpdate:
        if self.start_time is not None and self.end_time is not None:
            if self.end_time <= self.start_time:
                raise ValueError("end_time must be greater than start_time.")

        if self.period_type is not None and self.period_type != PeriodType.CLASS:
            if self.subject_topic is not None and self.subject_topic.strip():
                raise ValueError(
                    f"subject_topic is only permitted when period_type is 'CLASS' (got '{self.period_type.value}')."
                )

        return self


class TimetablePeriodTopicUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    subject_topic: Optional[str] = Field(
        None,
        max_length=200,
        description="Updated lesson topic for today's period"
    )
    row_version: str = Field(
        ...,
        description="Current row_version concurrency token"
    )


class TimetablePeriodResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    timetable_period_id: int
    timetable_id: int
    period_date: date
    period_number: int
    period_name: Optional[str] = None
    start_time: time
    end_time: time
    start_time_ist: str = Field(..., description="IST 24-hour display format HH:mm:ss")
    end_time_ist: str = Field(..., description="IST 24-hour display format HH:mm:ss")
    period_type: PeriodType
    subject_id: Optional[int] = None
    subject_name: Optional[str] = None
    subject_code: Optional[str] = None
    subject_topic: Optional[str] = Field(
        None,
        max_length=200,
        description="Daily planned lesson/chapter topic for CLASS periods"
    )
    teacher_id: Optional[int] = None
    teacher_name: Optional[str] = None
    room_name: Optional[str] = None
    activity_name: Optional[str] = None
    is_active: bool
    created_at: datetime = Field(..., description="UTC creation timestamp (ISO-8601)")
    updated_at: datetime = Field(..., description="UTC last updated timestamp (ISO-8601)")
    row_version: str = Field(..., description="Concurrency token")


class MyDayResponse(BaseModel):
    date: date
    user_role: str
    user_name: str
    section_name: Optional[str] = None
    class_name: Optional[str] = None
    total_periods: int
    periods: list[TimetablePeriodResponse]
