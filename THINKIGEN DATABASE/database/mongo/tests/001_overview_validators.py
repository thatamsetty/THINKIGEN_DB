"""Contract checks for Overview Mongo validators (no live Mongo required)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MC = ROOT / "collections" / "001_student_mission_control_daily.js"
CI = ROOT / "collections" / "002_student_compass_intelligence_daily.js"
LH = ROOT / "collections" / "003_student_learning_health_daily.js"


def _read(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        raise SystemExit(f"empty file: {path}")
    return text


def test_mission_control() -> None:
    src = _read(MC)
    required = [
        'createCollection("student_mission_control_daily"',
        "$jsonSchema",
        "validationLevel: \"strict\"",
        "uq_mc_student_day",
        "readiness",
        "motivational_note",
        "suggested_checklist_items",
        "start_my_day_at",
        "task_streak",
        "daily_attendance",
        "daily_homework",
        "next_assessment",
        "source_type",
        "source_id",
    ]
    for token in required[:-1]:
        if token not in src:
            raise SystemExit(f"mission_control missing: {token}")
    if '"classes"' in src or '"assignments"' in src or '"assignment_id"' in src:
        raise SystemExit("mission_control must not store classes or assignment data")


def test_compass_intelligence() -> None:
    src = _read(CI)
    for token in [
        'createCollection("student_compass_intelligence_daily"',
        "$jsonSchema",
        "validationLevel: \"strict\"",
        "uq_compass_student_day",
        "for_you",
        "top_recommendation",
        "cta_label",
        '"learning"',
        '"focus"',
        '"health"',
        "quick_suggestions",
    ]:
        if token not in src:
            raise SystemExit(f"compass_intelligence missing: {token}")


def test_learning_health() -> None:
    src = _read(LH)
    for token in [
        'createCollection("student_learning_health_daily"',
        "$jsonSchema",
        "validationLevel: \"strict\"",
        "uq_learning_health_student_day",
        "overall_score",
        "overall_sub_label",
        "analyzed_by",
        "understanding",
        "wellbeing",
        "minItems: 5",
    ]:
        if token not in src:
            raise SystemExit(f"learning_health missing: {token}")
    if "performance" in src:
        raise SystemExit("learning_health must not include performance skill")


if __name__ == "__main__":
    test_mission_control()
    test_compass_intelligence()
    test_learning_health()
    print("001_overview_validators: PASS")
