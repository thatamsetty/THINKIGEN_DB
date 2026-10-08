"""
FastAPI Router for Timetable and Daily Period Topic Management.
Endpoints adhere to Thinkigen REST API conventions, ISO datetime standards, and concurrency controls.
"""

from __future__ import annotations

from datetime import date
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, status

from app.schemas.timetable import (
    TimetablePeriodCreate,
    TimetablePeriodUpdate,
    TimetablePeriodTopicUpdate,
    TimetablePeriodResponse,
    MyDayResponse,
)
from app.database import (
    get_my_day_student,
    get_my_day_teacher,
    get_section_timetable,
    get_period_by_id,
    create_period,
    update_period,
    update_period_topic,
    ConcurrencyConflictError,
    PeriodNotFoundError,
    InvalidPeriodOperationError,
)

router = APIRouter(prefix="/timetable", tags=["Timetable & My Day"])


@router.get(
    "/my-day",
    response_model=MyDayResponse,
    summary="Get My Day Schedule for Student or Teacher",
    description=(
        "Retrieves today's timetable period slots for either the active student or authenticated teacher. "
        "Each period slot includes period numbers, start/end times in ISO & IST (+05:30) display formats, "
        "subject name, room name, and the planned daily lesson topic (`subject_topic`)."
    ),
)
def get_my_day(
    role: str = Query("STUDENT", description="Role to filter schedule for ('STUDENT' or 'TEACHER')"),
    teacher_id: Optional[int] = Query(None, description="Teacher ID if role is TEACHER"),
    period_date: Optional[date] = Query(None, description="Filter for a specific date (defaults to today)"),
) -> MyDayResponse:
    if role.upper() == "TEACHER":
        t_id = teacher_id or 1
        return get_my_day_teacher(teacher_id=t_id, period_date=period_date)
    return get_my_day_student(period_date=period_date)


@router.get(
    "/section/{section_id}",
    response_model=list[TimetablePeriodResponse],
    summary="Get Section Timetable Periods",
    description="Returns all active period slots for a given section scope, including daily `subject_topic`.",
)
def get_section_periods(
    section_id: int,
    period_date: Optional[date] = Query(None, description="Date filter (defaults to today)"),
) -> list[TimetablePeriodResponse]:
    return get_section_timetable(section_id=section_id, period_date=period_date)


@router.get(
    "/period/{period_id}",
    response_model=TimetablePeriodResponse,
    summary="Get Single Timetable Period by ID",
    description="Fetches an individual timetable period with subject details, concurrency token, and `subject_topic`.",
)
def get_period(period_id: int) -> TimetablePeriodResponse:
    try:
        return get_period_by_id(period_id)
    except PeriodNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post(
    "/period",
    response_model=TimetablePeriodResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Timetable Period Slot",
    description=(
        "Creates a new timetable period slot. Enforces that `subject_topic` is only allowed when `period_type == 'CLASS'`. "
        "Generates initial `row_version` token and ISO timestamps."
    ),
)
def create_period_endpoint(payload: TimetablePeriodCreate) -> TimetablePeriodResponse:
    return create_period(payload)


@router.put(
    "/period/{period_id}",
    response_model=TimetablePeriodResponse,
    summary="Update Timetable Period Slot",
    description=(
        "Updates an existing timetable period. Preserves soft-delete (`is_active = 1`), enforces that `subject_topic` "
        "is only allowed on `CLASS` periods, and checks `row_version` to prevent concurrent overwrite."
    ),
)
def update_period_endpoint(period_id: int, payload: TimetablePeriodUpdate) -> TimetablePeriodResponse:
    try:
        return update_period(period_id, payload)
    except PeriodNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ConcurrencyConflictError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))
    except InvalidPeriodOperationError as e:
        raise HTTPException(status_code=422, detail=str(e))


@router.patch(
    "/period/{period_id}/topic",
    response_model=TimetablePeriodResponse,
    summary="Inline Fast Topic Update for Teacher",
    description=(
        "Enables a teacher to quickly update today's lesson/chapter topic (`subject_topic`) for a CLASS period. "
        "Validates that the period is an active CLASS slot and verifies the `row_version` concurrency token."
    ),
)
def update_period_topic_endpoint(period_id: int, payload: TimetablePeriodTopicUpdate) -> TimetablePeriodResponse:
    try:
        return update_period_topic(period_id, payload)
    except PeriodNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ConcurrencyConflictError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))
    except InvalidPeriodOperationError as e:
        raise HTTPException(status_code=422, detail=str(e))
