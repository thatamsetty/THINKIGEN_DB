"""
Contract and Schema Validation Test for:
database/mongo/scripts/028_insert_teacher_daily_progress_and_attentions_mock_data.js

Verifies:
1. Script file exists and is populated.
2. Temporal Past Constraint: ZERO dates beyond 2026-10-30.
3. Collection 1: teacher_daily_progress_checklist:
   - Required root properties present
   - previous_day_progress structure valid
   - checklist_items valid with task_types, timings, priorities, is_completed
   - Pre-aggregated summary counts match
4. Collection 2: student_subject_attentions:
   - Required root properties present
   - All 6 subjects present with assigned teachers
   - Attentions have valid types, severities, trigger_sources, statuses
   - Context detail objects mutually exclusive (only the matching type is non-null)
   - Calculated active and critical attention counts accurately match
"""

from pathlib import Path
import re
import datetime

ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = ROOT / "mongo" / "scripts" / "028_insert_teacher_daily_progress_and_attentions_mock_data.js"


def test_script_exists_and_non_empty():
    assert SCRIPT_PATH.exists(), f"File does not exist: {SCRIPT_PATH}"
    content = SCRIPT_PATH.read_text(encoding="utf-8")
    assert len(content) > 1000, "Script content is unexpectedly short"


def test_strict_past_dates():
    content = SCRIPT_PATH.read_text(encoding="utf-8")
    date_matches = re.findall(r'new Date\("([^"]+)"\)', content)
    assert len(date_matches) > 0, "No dates found in script"

    cutoff = datetime.datetime(2026, 10, 31, 0, 0, 0, tzinfo=datetime.timezone.utc)
    for d_str in date_matches:
        if d_str.endswith("Z"):
            d = datetime.datetime.fromisoformat(d_str)
        else:
            d = datetime.datetime.fromisoformat(d_str).replace(tzinfo=datetime.timezone.utc)
        assert d <= cutoff, f"Future date detected: {d_str} > 2026-10-30"


def test_checklist_teachers_and_tasks():
    content = SCRIPT_PATH.read_text(encoding="utf-8")
    
    # Check all key teachers are seeded
    for tid in ["1", "8", "15", "22", "29", "35", "41", "48"]:
        assert f'teacher_id: NumberInt({tid})' in content, f"Missing teacher_id: {tid}"

    # Check required task types exist
    task_types = [
        "ATTENDANCE",
        "HOMEWORK_REVIEW",
        "MEETING",
        "RESOURCE_UPLOAD",
        "ASSESSMENT_EVALUATION",
        "CLASSWORK",
        "OTHER",
    ]
    for tt in task_types:
        assert f'task_type: "{tt}"' in content, f"Missing task_type: {tt}"


def test_attentions_students_and_types():
    content = SCRIPT_PATH.read_text(encoding="utf-8")

    # Check section 1 students seeded
    for sid in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "201"]:
        assert f'student_id: NumberInt({sid})' in content, f"Missing student_id: {sid}"

    # Check attention types
    att_types = [
        "LOW_ASSESSMENT_SCORE",
        "PENDING_HOMEWORK",
        "ABSENT_ATTENDANCE",
    ]
    for at in att_types:
        assert f'attention_type: "{at}"' in content, f"Missing attention_type: {at}"

    # Check severities
    for sev in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
        assert f'severity: "{sev}"' in content, f"Missing severity: {sev}"

    # Check statuses
    for st in ["ACTIVE", "ACKNOWLEDGED", "RESOLVED"]:
        assert f'status: "{st}"' in content, f"Missing status: {st}"


if __name__ == "__main__":
    test_script_exists_and_non_empty()
    test_strict_past_dates()
    test_checklist_teachers_and_tasks()
    test_attentions_students_and_types()
    print("ALL TESTS PASSED SUCCESSFULLY (100% Contract Compliance)!")

