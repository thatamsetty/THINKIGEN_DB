"""Contract checks for Learning Hub Mongo validators (no live Mongo required)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SYL = ROOT / "collections" / "004_class_subject_syllabus.js"
RES = ROOT / "collections" / "005_learning_resource.js"
PAP = ROOT / "collections" / "006_exam_paper.js"
PRG = ROOT / "collections" / "007_student_learning_progress.js"


def _read(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        raise SystemExit(f"empty file: {path}")
    return text


def test_syllabus() -> None:
    src = _read(SYL)
    for token in [
        'createCollection("class_subject_syllabus"',
        "$jsonSchema",
        "validationLevel: \"strict\"",
        "uq_syllabus_scope_subject",
        "chapters",
        "topic_id",
        "minItems: 0",
    ]:
        if token not in src:
            raise SystemExit(f"syllabus missing: {token}")
    if "overall_progress_percent" in src or "course_percent" in src:
        raise SystemExit("syllabus must not store student course percent")


def test_learning_resource() -> None:
    src = _read(RES)
    for token in [
        'createCollection("learning_resource"',
        "uq_learning_resource_id",
        "resource_type",
        '"video"',
        '"notes"',
        '"quiz"',
        '"book"',
        "blob_id",
    ]:
        if token not in src:
            raise SystemExit(f"learning_resource missing: {token}")


def test_exam_paper() -> None:
    src = _read(PAP)
    for token in [
        'createCollection("exam_paper"',
        "uq_exam_paper_id",
        "uq_exam_paper_class_title",
        "ix_exam_paper_class_category",
        "preview_blob_id",
        "BOARD",
        "MID_TERM",
        "UNIT_TEST",
        "AI_GENERATED",
        "class_id",
    ]:
        if token not in src:
            raise SystemExit(f"exam_paper missing: {token}")
    if '"Board Papers"' in src or '"Mid Term Exams"' in src:
        raise SystemExit("exam_paper must store category codes, not UI labels")
    if "section_id" in src or "student_id" in src:
        raise SystemExit("exam_paper must be class-level only (no section/student)")


def test_progress() -> None:
    src = _read(PRG)
    for token in [
        'createCollection("student_learning_progress"',
        "uq_student_learning_progress",
        "overall_progress_percent",
        '"pending"',
        '"completed"',
        "continue_learning",
    ]:
        if token not in src:
            raise SystemExit(f"progress missing: {token}")


if __name__ == "__main__":
    test_syllabus()
    test_learning_resource()
    test_exam_paper()
    test_progress()
    print("002_learning_hub_validators: PASS")
