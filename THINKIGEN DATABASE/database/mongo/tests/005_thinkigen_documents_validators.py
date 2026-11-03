"""Contract checks for thinkigen_documents Mongo validator (no live Mongo required)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "collections" / "023_thinkigen_documents.js"
MIG = ROOT / "scripts" / "023_update_thinkigen_documents_teacher_leave_grievance.js"
ROL = ROOT / "scripts" / "023_rollback_thinkigen_documents_teacher_leave_grievance.js"


def _read(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        raise SystemExit(f"empty file: {path}")
    return text


def test_thinkigen_documents_contract() -> None:
    src = _read(DOC)
    
    # 1. Enums in entity_type
    required_entity_types = [
        '"STUDENT"',
        '"TEACHER"',
        '"ANNOUNCEMENT"',
        '"ASSIGNMENT"',
        '"HOMEWORK"',
        '"LEAVE"',
        '"GRIEVANCE"',
        '"COMMUNICATION"',
        '"COMMUNITY_POST"',
        '"TEACHER_LEAVE_APPLICATION"',
        '"TEACHER_GRIEVANCE"',
    ]
    for et in required_entity_types:
        if et not in src:
            raise SystemExit(f"thinkigen_documents missing entity_type: {et}")

    # 2. Enums in classification.category
    required_categories = [
        '"STUDENT_DOCUMENT"',
        '"TEACHER_DOCUMENT"',
        '"ANNOUNCEMENT"',
        '"ASSIGNMENT"',
        '"HOMEWORK"',
        '"STUDENT_LEAVE"',
        '"GRIEVANCE"',
        '"COMMUNICATION"',
        '"COMMUNITY"',
        '"TEACHER_LEAVE"',
        '"TEACHER_GRIEVANCE"',
    ]
    for cat in required_categories:
        if cat not in src:
            raise SystemExit(f"thinkigen_documents missing category: {cat}")

    # 3. Conditional validations for teacher leave and grievance
    required_conditionals = [
        '"owner.entity_type": "TEACHER_LEAVE_APPLICATION"',
        '"classification.category": "TEACHER_LEAVE"',
        '"classification.attachment_type": "SUPPORTING_DOCUMENT"',
        '"owner.entity_type": "TEACHER_GRIEVANCE"',
        '"classification.category": "TEACHER_GRIEVANCE"',
        '"classification.attachment_type": "EVIDENCE"',
    ]
    for cond in required_conditionals:
        if cond not in src:
            raise SystemExit(f"thinkigen_documents missing conditional rule: {cond}")

    # 4. Storage provider must be AWS S3
    if '"AWS_S3"' not in src:
        raise SystemExit("thinkigen_documents missing AWS_S3 storage provider")

    # 5. Indexes must include document_id uniqueness, tenant/owner status, tenant/owner newest, s3 object uniqueness
    required_indexes = [
        "uq_thinkigen_documents_document_id",
        "ix_thinkigen_documents_tenant_owner_status",
        "ix_thinkigen_documents_tenant_owner_newest",
        "uq_thinkigen_documents_s3_object",
    ]
    for idx in required_indexes:
        if idx not in src:
            raise SystemExit(f"thinkigen_documents missing index: {idx}")


def test_migration_and_rollback_scripts() -> None:
    mig_src = _read(MIG)
    rol_src = _read(ROL)

    if "TEACHER_LEAVE_APPLICATION" not in mig_src or "TEACHER_GRIEVANCE" not in mig_src:
        raise SystemExit("Migration script missing new teacher entity types")

    if "TEACHER_LEAVE_APPLICATION" in rol_src or "TEACHER_GRIEVANCE" in rol_src:
        raise SystemExit("Rollback script must NOT contain teacher leave or grievance in active validator")


if __name__ == "__main__":
    test_thinkigen_documents_contract()
    test_migration_and_rollback_scripts()
    print("005_thinkigen_documents_validators: PASS")
