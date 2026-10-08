"""
Automated Pytest Suite for Timetable API and subject_topic Validation.
Verifies production standards:
- DTO schemas & ISO / IST formatting
- Period type topic validation (CLASS allowed, non-CLASS rejected)
- Soft-delete handling (is_active = 1)
- Concurrency token checks (row_version matching & 409 Conflict)
- OpenAPI schema documentation
"""

from __future__ import annotations

import sys
from pathlib import Path

# Add backend directory to sys.path
BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.database import reset_storage


@pytest.fixture(autouse=True)
def run_before_each_test():
    reset_storage()
    yield
    reset_storage()


client = TestClient(app)


def test_get_my_day_student_payload_structure():
    """Verify Student My Day returns subject_topic, subject_name, room_name, and IST times."""
    response = client.get("/timetable/my-day?role=STUDENT")
    assert response.status_code == 200
    data = response.json()

    assert data["user_role"] == "STUDENT"
    assert data["total_periods"] == 5
    periods = data["periods"]
    assert len(periods) == 5

    # Period 1 - CLASS (Mathematics)
    p1 = periods[0]
    assert p1["period_number"] == 1
    assert p1["period_type"] == "CLASS"
    assert p1["subject_name"] == "Mathematics"
    assert p1["subject_topic"] == "Algebra Ex 3.1"
    assert p1["room_name"] == "Room-01"
    assert p1["start_time_ist"] == "08:30:00"
    assert "row_version" in p1

    # Period 2 - CLASS (Science)
    p2 = periods[1]
    assert p2["period_type"] == "CLASS"
    assert p2["subject_name"] == "Science"
    assert p2["subject_topic"] == "Plant Cell Biology"

    # Period 3 - BREAK
    p3 = periods[2]
    assert p3["period_type"] == "BREAK"
    assert p3["subject_topic"] is None
    assert p3["activity_name"] == "Morning Refreshment Break"


def test_get_my_day_teacher_payload():
    """Verify Teacher My Day returns teacher's assigned periods and current topics."""
    response = client.get("/timetable/my-day?role=TEACHER&teacher_id=1")
    assert response.status_code == 200
    data = response.json()

    assert data["user_role"] == "TEACHER"
    periods = data["periods"]
    assert len(periods) == 1
    assert periods[0]["teacher_name"] == "Rajesh Sharma"
    assert periods[0]["subject_topic"] == "Algebra Ex 3.1"


def test_get_section_timetable():
    """Verify Section timetable retrieves periods with subject_topic."""
    response = client.get("/timetable/section/1")
    assert response.status_code == 200
    periods = response.json()
    assert len(periods) == 5
    assert any(p["subject_topic"] == "Algebra Ex 3.1" for p in periods)


def test_subject_topic_allowed_on_class_period_creation():
    """Validates that a new CLASS period with a valid subject_topic is accepted (201 Created)."""
    payload = {
        "timetable_id": 1,
        "period_date": "2026-09-16",
        "period_number": 6,
        "period_name": "Period 6",
        "start_time": "13:15:00",
        "end_time": "14:00:00",
        "period_type": "CLASS",
        "subject_id": 2,
        "subject_topic": "Linear Equations in Two Variables",
        "teacher_id": 1,
        "room_name": "Room-02",
    }
    response = client.post("/timetable/period", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["subject_topic"] == "Linear Equations in Two Variables"
    assert data["period_type"] == "CLASS"
    assert data["is_active"] is True
    assert "row_version" in data


def test_subject_topic_rejected_on_break_period():
    """Validates that assigning subject_topic to a BREAK period raises 422 Unprocessable Entity."""
    payload = {
        "timetable_id": 1,
        "period_date": "2026-09-16",
        "period_number": 7,
        "period_name": "Evening Break",
        "start_time": "14:00:00",
        "end_time": "14:15:00",
        "period_type": "BREAK",
        "subject_topic": "Disallowed topic on break",
    }
    response = client.post("/timetable/period", json=payload)
    assert response.status_code == 422
    assert "subject_topic is only permitted when period_type is 'CLASS'" in response.text


def test_subject_topic_max_length_validation():
    """Validates that subject_topic exceeding 200 characters is rejected."""
    long_topic = "A" * 201
    payload = {
        "timetable_id": 1,
        "period_date": "2026-09-16",
        "period_number": 8,
        "start_time": "14:15:00",
        "end_time": "15:00:00",
        "period_type": "CLASS",
        "subject_id": 1,
        "teacher_id": 3,
        "subject_topic": long_topic,
    }
    response = client.post("/timetable/period", json=payload)
    assert response.status_code == 422


def test_teacher_inline_topic_update_success():
    """Teacher updates today's topic on CLASS period with matching row_version."""
    current = client.get("/timetable/period/101").json()
    rv = current["row_version"]

    payload = {
        "subject_topic": "Algebra Ex 3.2 - Elimination Method",
        "row_version": rv,
    }
    response = client.patch("/timetable/period/101/topic", json=payload)
    assert response.status_code == 200
    updated = response.json()
    assert updated["subject_topic"] == "Algebra Ex 3.2 - Elimination Method"
    assert updated["row_version"] != rv  # Concurrency token advanced


def test_concurrency_conflict_on_stale_row_version():
    """Confirms HTTP 409 Conflict when updating with an outdated row_version."""
    payload = {
        "subject_topic": "Concurrent topic update",
        "row_version": "0x0000000000000000",  # Stale token
    }
    response = client.patch("/timetable/period/101/topic", json=payload)
    assert response.status_code == 409
    assert "Concurrency conflict" in response.json()["detail"]


def test_soft_deleted_period_cannot_update_topic():
    """Confirms that attempting to update a soft-deleted period returns 404."""
    current = client.get("/timetable/period/101").json()
    # Mark period as inactive
    client.put("/timetable/period/101", json={"is_active": False, "row_version": current["row_version"]})

    # Now attempt to update topic
    patch_resp = client.patch("/timetable/period/101/topic", json={
        "subject_topic": "Should fail",
        "row_version": "0x0000000000000102",
    })
    assert patch_resp.status_code == 404


def test_cannot_update_topic_on_break_slot():
    """Validates that PATCH /topic on a non-CLASS slot returns 422."""
    current = client.get("/timetable/period/103").json()  # Morning Break
    response = client.patch("/timetable/period/103/topic", json={
        "subject_topic": "Invalid Break Topic",
        "row_version": current["row_version"],
    })
    assert response.status_code == 422
    assert "subject_topic can only be updated for CLASS periods" in response.json()["detail"]


def test_openapi_schema_contains_subject_topic():
    """Verifies that OpenAPI documentation contains subject_topic definitions and descriptions."""
    response = client.get("/openapi.json")
    assert response.status_code == 200
    schema = response.json()

    schemas = schema["components"]["schemas"]
    assert "TimetablePeriodResponse" in schemas
    assert "subject_topic" in schemas["TimetablePeriodResponse"]["properties"]
    assert "TimetablePeriodCreate" in schemas
    assert "subject_topic" in schemas["TimetablePeriodCreate"]["properties"]
    assert "TimetablePeriodTopicUpdate" in schemas
    assert "subject_topic" in schemas["TimetablePeriodTopicUpdate"]["properties"]
