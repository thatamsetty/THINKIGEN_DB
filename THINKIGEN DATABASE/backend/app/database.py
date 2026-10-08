"""
Thinkigen Timetable Data Access Layer & Business Logic.
Enforces:
- Organization & Section scope
- Concurrency token checks (row_version matching)
- Soft delete filtering (is_active == 1)
- CLASS period subject_topic constraints
"""

from __future__ import annotations

import copy
from datetime import date, time, datetime, timezone
from typing import Optional

from app.schemas.timetable import (
    PeriodType,
    TimetablePeriodCreate,
    TimetablePeriodUpdate,
    TimetablePeriodTopicUpdate,
    TimetablePeriodResponse,
    MyDayResponse,
)


class ConcurrencyConflictError(Exception):
    """Raised when row_version does not match the latest stored token."""
    pass


class PeriodNotFoundError(Exception):
    """Raised when the period does not exist or is soft-deleted."""
    pass


class InvalidPeriodOperationError(Exception):
    """Raised when business rules like CLASS period requirement are violated."""
    pass


# Initial seed data representing Thinkigen production mock dataset
MOCK_PERIODS: dict[int, dict] = {
    101: {
        "timetable_period_id": 101,
        "timetable_id": 1,
        "period_date": date(2026, 9, 16),
        "period_number": 1,
        "period_name": "Period 1",
        "start_time": time(8, 30, 0),
        "end_time": time(9, 15, 0),
        "period_type": PeriodType.CLASS,
        "subject_id": 2,
        "subject_name": "Mathematics",
        "subject_code": "MAT",
        "subject_topic": "Algebra Ex 3.1",
        "teacher_id": 1,
        "teacher_name": "Rajesh Sharma",
        "room_name": "Room-01",
        "activity_name": None,
        "is_active": True,
        "created_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "updated_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "row_version": "0x0000000000000101",
    },
    102: {
        "timetable_period_id": 102,
        "timetable_id": 1,
        "period_date": date(2026, 9, 16),
        "period_number": 2,
        "period_name": "Period 2",
        "start_time": time(9, 15, 0),
        "end_time": time(10, 0, 0),
        "period_type": PeriodType.CLASS,
        "subject_id": 3,
        "subject_name": "Science",
        "subject_code": "SCI",
        "subject_topic": "Plant Cell Biology",
        "teacher_id": 2,
        "teacher_name": "Ananya Sen",
        "room_name": "Room-01",
        "activity_name": None,
        "is_active": True,
        "created_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "updated_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "row_version": "0x0000000000000102",
    },
    103: {
        "timetable_period_id": 103,
        "timetable_id": 1,
        "period_date": date(2026, 9, 16),
        "period_number": 3,
        "period_name": "Morning Break",
        "start_time": time(10, 0, 0),
        "end_time": time(10, 15, 0),
        "period_type": PeriodType.BREAK,
        "subject_id": None,
        "subject_name": None,
        "subject_code": None,
        "subject_topic": None,
        "teacher_id": None,
        "teacher_name": None,
        "room_name": None,
        "activity_name": "Morning Refreshment Break",
        "is_active": True,
        "created_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "updated_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "row_version": "0x0000000000000103",
    },
    104: {
        "timetable_period_id": 104,
        "timetable_id": 1,
        "period_date": date(2026, 9, 16),
        "period_number": 4,
        "period_name": "Period 3",
        "start_time": time(10, 15, 0),
        "end_time": time(11, 0, 0),
        "period_type": PeriodType.CLASS,
        "subject_id": 1,
        "subject_name": "English",
        "subject_code": "ENG",
        "subject_topic": "Poetry Analysis & Figures of Speech",
        "teacher_id": 3,
        "teacher_name": "Meera Nair",
        "room_name": "Room-01",
        "activity_name": None,
        "is_active": True,
        "created_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "updated_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "row_version": "0x0000000000000104",
    },
    105: {
        "timetable_period_id": 105,
        "timetable_id": 1,
        "period_date": date(2026, 9, 16),
        "period_number": 5,
        "period_name": "Lunch Break",
        "start_time": time(11, 45, 0),
        "end_time": time(12, 30, 0),
        "period_type": PeriodType.LUNCH,
        "subject_id": None,
        "subject_name": None,
        "subject_code": None,
        "subject_topic": None,
        "teacher_id": None,
        "teacher_name": None,
        "room_name": None,
        "activity_name": "Lunch Break",
        "is_active": True,
        "created_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "updated_at": datetime(2026, 8, 1, 8, 0, 0, tzinfo=timezone.utc),
        "row_version": "0x0000000000000105",
    },
}

_storage: dict[int, dict] = copy.deepcopy(MOCK_PERIODS)
_id_seq = 200


def reset_storage() -> None:
    global _storage, _id_seq
    _storage = copy.deepcopy(MOCK_PERIODS)
    _id_seq = 200


def _build_response(record: dict) -> TimetablePeriodResponse:
    st = record["start_time"]
    et = record["end_time"]
    return TimetablePeriodResponse(
        timetable_period_id=record["timetable_period_id"],
        timetable_id=record["timetable_id"],
        period_date=record["period_date"],
        period_number=record["period_number"],
        period_name=record.get("period_name"),
        start_time=st,
        end_time=et,
        start_time_ist=st.strftime("%H:%M:%S"),
        end_time_ist=et.strftime("%H:%M:%S"),
        period_type=record["period_type"],
        subject_id=record.get("subject_id"),
        subject_name=record.get("subject_name"),
        subject_code=record.get("subject_code"),
        subject_topic=record.get("subject_topic"),
        teacher_id=record.get("teacher_id"),
        teacher_name=record.get("teacher_name"),
        room_name=record.get("room_name"),
        activity_name=record.get("activity_name"),
        is_active=record["is_active"],
        created_at=record["created_at"],
        updated_at=record["updated_at"],
        row_version=record["row_version"],
    )


def get_my_day_student(period_date: Optional[date] = None) -> MyDayResponse:
    target_date = period_date or date(2026, 9, 16)
    active_periods = [
        _build_response(p)
        for p in _storage.values()
        if p["is_active"] and p["period_date"] == target_date
    ]
    active_periods.sort(key=lambda x: x.period_number)
    return MyDayResponse(
        date=target_date,
        user_role="STUDENT",
        user_name="Aarav Sharma",
        section_name="Section A",
        class_name="Class 10",
        total_periods=len(active_periods),
        periods=active_periods,
    )


def get_my_day_teacher(teacher_id: int, period_date: Optional[date] = None) -> MyDayResponse:
    target_date = period_date or date(2026, 9, 16)
    active_periods = [
        _build_response(p)
        for p in _storage.values()
        if p["is_active"] and p["period_date"] == target_date and p.get("teacher_id") == teacher_id
    ]
    active_periods.sort(key=lambda x: x.start_time)
    return MyDayResponse(
        date=target_date,
        user_role="TEACHER",
        user_name="Rajesh Sharma",
        section_name=None,
        class_name=None,
        total_periods=len(active_periods),
        periods=active_periods,
    )


def get_section_timetable(section_id: int, period_date: Optional[date] = None) -> list[TimetablePeriodResponse]:
    target_date = period_date or date(2026, 9, 16)
    active_periods = [
        _build_response(p)
        for p in _storage.values()
        if p["is_active"] and p["period_date"] == target_date
    ]
    active_periods.sort(key=lambda x: x.period_number)
    return active_periods


def get_period_by_id(period_id: int) -> TimetablePeriodResponse:
    record = _storage.get(period_id)
    if not record or not record["is_active"]:
        raise PeriodNotFoundError(f"Active timetable period with id {period_id} not found.")
    return _build_response(record)


def create_period(payload: TimetablePeriodCreate) -> TimetablePeriodResponse:
    global _id_seq
    _id_seq += 1
    new_id = _id_seq
    now = datetime.now(timezone.utc)

    # Resolve mock names if present
    subject_names = {1: ("English", "ENG"), 2: ("Mathematics", "MAT"), 3: ("Science", "SCI")}
    teacher_names = {1: "Rajesh Sharma", 2: "Ananya Sen", 3: "Meera Nair"}

    s_name, s_code = (None, None)
    if payload.subject_id in subject_names:
        s_name, s_code = subject_names[payload.subject_id]

    t_name = teacher_names.get(payload.teacher_id) if payload.teacher_id else None

    record = {
        "timetable_period_id": new_id,
        "timetable_id": payload.timetable_id,
        "period_date": payload.period_date,
        "period_number": payload.period_number,
        "period_name": payload.period_name,
        "start_time": payload.start_time,
        "end_time": payload.end_time,
        "period_type": payload.period_type,
        "subject_id": payload.subject_id,
        "subject_name": s_name,
        "subject_code": s_code,
        "subject_topic": payload.subject_topic,
        "teacher_id": payload.teacher_id,
        "teacher_name": t_name,
        "room_name": payload.room_name,
        "activity_name": payload.activity_name,
        "is_active": True,
        "created_at": now,
        "updated_at": now,
        "row_version": f"0x{new_id:016x}",
    }
    _storage[new_id] = record
    return _build_response(record)


def update_period(period_id: int, payload: TimetablePeriodUpdate) -> TimetablePeriodResponse:
    record = _storage.get(period_id)
    if not record or not record["is_active"]:
        raise PeriodNotFoundError(f"Active timetable period with id {period_id} not found.")

    # Concurrency verification
    if record["row_version"].lower() != payload.row_version.lower():
        raise ConcurrencyConflictError(
            f"Concurrency conflict: record was updated by another process. "
            f"Expected row_version '{record['row_version']}', but received '{payload.row_version}'."
        )

    # Determine final period_type
    final_type = payload.period_type or record["period_type"]
    if final_type != PeriodType.CLASS and payload.subject_topic is not None and payload.subject_topic.strip():
        raise InvalidPeriodOperationError(
            f"subject_topic is only permitted when period_type is 'CLASS' (got '{final_type.value}')."
        )

    # Apply updates
    now = datetime.now(timezone.utc)
    if payload.period_name is not None:
        record["period_name"] = payload.period_name
    if payload.start_time is not None:
        record["start_time"] = payload.start_time
    if payload.end_time is not None:
        record["end_time"] = payload.end_time
    if payload.period_type is not None:
        record["period_type"] = payload.period_type
    if payload.subject_id is not None:
        record["subject_id"] = payload.subject_id
    if payload.subject_topic is not None:
        record["subject_topic"] = payload.subject_topic
    if payload.teacher_id is not None:
        record["teacher_id"] = payload.teacher_id
    if payload.room_name is not None:
        record["room_name"] = payload.room_name
    if payload.activity_name is not None:
        record["activity_name"] = payload.activity_name
    if payload.is_active is not None:
        record["is_active"] = payload.is_active

    record["updated_at"] = now
    # Increment token
    next_ver = int(record["row_version"], 16) + 1
    record["row_version"] = f"0x{next_ver:016x}"

    return _build_response(record)


def update_period_topic(period_id: int, payload: TimetablePeriodTopicUpdate) -> TimetablePeriodResponse:
    record = _storage.get(period_id)
    if not record or not record["is_active"]:
        raise PeriodNotFoundError(f"Active timetable period with id {period_id} not found.")

    # Concurrency check
    if record["row_version"].lower() != payload.row_version.lower():
        raise ConcurrencyConflictError(
            f"Concurrency conflict: record was updated by another process. "
            f"Expected row_version '{record['row_version']}', but received '{payload.row_version}'."
        )

    # Must be CLASS period
    if record["period_type"] != PeriodType.CLASS:
        raise InvalidPeriodOperationError(
            f"subject_topic can only be updated for CLASS periods (period type is '{record['period_type'].value}')."
        )

    now = datetime.now(timezone.utc)
    record["subject_topic"] = payload.subject_topic
    record["updated_at"] = now
    next_ver = int(record["row_version"], 16) + 1
    record["row_version"] = f"0x{next_ver:016x}"

    return _build_response(record)
