"""
Generate database/docs/full-table-reference.txt and .md from module migrations.
Run: python database/scripts/generate_full_table_reference.py
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS = ROOT / "migrations"
OUTPUT_TXT = ROOT / "docs" / "full-table-reference.txt"
OUTPUT_MD = ROOT / "docs" / "full-table-reference.md"

MIGRATION_ORDER = [
    "001_schemas.sql",
    "002_security.sql",
    "003_management.sql",
    "004_teacher.sql",
    "017_exam.sql",
    "005_student.sql",
    "006_assessment.sql",
    "007_announcement.sql",
    "008_timetable.sql",
    "009_homework.sql",
    "010_attendance.sql",
    "011_leave.sql",
    "012_holidays.sql",
    "013_grievance.sql",
    "014_library.sql",
    "015_transport.sql",
    "016_finance.sql",
]

COLUMN_HINTS = {
    "school_id": "School scope FK",
    "branch_id": "Branch scope FK",
    "academic_year_id": "Academic year FK",
    "class_id": "Class FK",
    "section_id": "Section FK",
    "student_id": "Student FK",
    "teacher_id": "Teacher FK",
    "subject_id": "Subject FK",
    "subject_topic": "Lesson/chapter topic for CLASS period",
    "user_id": "User FK",
    "is_active": "Soft active flag",
    "created_at": "Record created (UTC)",
    "created_by": "User who created",
    "updated_at": "Record last updated (UTC)",
    "updated_by": "User who last updated",
    "row_version": "Concurrency token",
    "recorded_at": "Recorded timestamp (UTC)",
    "recorded_by": "User who recorded",
}


def module_purpose(text: str) -> str:
    m = re.search(r"Purpose:\s*(.+)", text)
    if m:
        return sanitize_text(m.group(1).strip())
    m = re.search(r"Module:\s*(\S+)", text)
    return m.group(1) if m else "Thinkigen module table"


def column_section(body: str) -> str:
    lines: list[str] = []
    for raw in body.splitlines():
        s = raw.strip()
        if s.upper().startswith("CONSTRAINT "):
            break
        lines.append(raw)
    return "\n".join(lines)


def parse_columns(body: str) -> list[tuple[str, str, str, str]]:
    rows: list[tuple[str, str, str, str]] = []
    for raw in column_section(body).splitlines():
        line = raw.strip().rstrip(",")
        if not line:
            continue
        m = re.match(r"^([a-z_][a-z0-9_]*)\s+(.+)$", line, re.I)
        if not m:
            continue
        name, rest = m.group(1), m.group(2)
        nullable = "NOT NULL" if re.search(r"\bNOT\s+NULL\b", rest, re.I) else "NULL"
        col_type = re.split(r"\s+CONSTRAINT\b", rest, maxsplit=1)[0]
        col_type = re.sub(r"\s+DEFAULT\s+.*$", "", col_type, flags=re.I)
        col_type = re.sub(r"\s+NOT\s+NULL\b", "", col_type, flags=re.I)
        col_type = re.sub(r"\s+NULL\b", "", col_type, flags=re.I)
        col_type = re.sub(r"\s+IDENTITY\s*\(\s*\d+\s*,\s*\d+\s*\)", "", col_type, flags=re.I)
        col_type = col_type.strip()
        hint = COLUMN_HINTS.get(name, "")
        rows.append((name, col_type, nullable, hint))
    return rows


def sanitize_text(text: str) -> str:
    for old, new in {
        "\u2014": "-",
        "\u2019": "'",
        "\u201c": '"',
        "\u201d": '"',
    }.items():
        text = text.replace(old, new)
    return text


def parse_constraints(body: str) -> list[str]:
    items: list[str] = []
    for line in body.splitlines():
        s = line.strip().rstrip(",")
        if s.startswith("CONSTRAINT "):
            items.append(s)
    return items


def parse_indexes(sql: str, table_name: str) -> list[str]:
    pattern = re.compile(
        r"CREATE\s+(?:UNIQUE\s+)?NONCLUSTERED\s+INDEX\s+(\w+)\s+ON\s+"
        + re.escape(table_name)
        + r"\b",
        re.I,
    )
    return [m.group(1) for m in pattern.finditer(sql)]


def extract_tables(sql: str, migration_file: str) -> list[dict]:
    purpose = module_purpose(sql)
    tables: list[dict] = []
    for m in re.finditer(
        r"CREATE\s+TABLE\s+((?:\w+_schema)\.(\w+))\s*\(",
        sql,
        re.I,
    ):
        full_name = m.group(1)
        schema = m.group(1).split(".")[0]
        start = m.end()
        depth = 1
        i = start
        while i < len(sql) and depth:
            if sql[i] == "(":
                depth += 1
            elif sql[i] == ")":
                depth -= 1
            i += 1
        body = sql[start : i - 1]
        tables.append(
            {
                "full_name": full_name,
                "schema": schema,
                "table": m.group(2),
                "migration_file": migration_file,
                "purpose": purpose,
                "columns": parse_columns(body),
                "constraints": parse_constraints(body),
                "indexes": parse_indexes(sql[i:], full_name),
            }
        )
    return tables


def load_all_tables() -> list[dict]:
    all_tables: list[dict] = []
    for fname in MIGRATION_ORDER:
        path = MIGRATIONS / fname
        if not path.exists():
            continue
        sql = path.read_text(encoding="utf-8")
        all_tables.extend(extract_tables(sql, fname))
    return all_tables


def format_column_row(name: str, col_type: str, nullable: str, hint: str) -> str:
    if col_type.upper().startswith("AS "):
        nullable = "?"
    return f"  {name:<32} | {col_type:<22} | {nullable:<8} | {hint}"


def build_index(tables: list[dict]) -> tuple[str, int]:
    by_schema: dict[str, list[str]] = {}
    for t in tables:
        by_schema.setdefault(t["schema"], []).append(t["full_name"])
    lines = ["TABLE INDEX", "=" * 72]
    total = 0
    for schema in sorted(by_schema):
        names = sorted(by_schema[schema])
        total += len(names)
        lines.append(f"  {schema} ({len(names)} tables)")
        for n in names:
            lines.append(f"    - {n}")
    lines.append(f"  TOTAL: {total} tables")
    lines.append("")
    return "\n".join(lines), total


def build_index_md(tables: list[dict]) -> tuple[str, int]:
    by_schema: dict[str, list[str]] = {}
    for t in tables:
        by_schema.setdefault(t["schema"], []).append(t["full_name"])
    lines = ["## Table index", ""]
    total = 0
    for schema in sorted(by_schema):
        names = sorted(by_schema[schema])
        total += len(names)
        lines.append(f"### `{schema}` ({len(names)} tables)")
        lines.append("")
        for n in names:
            lines.append(f"- `{n}`")
        lines.append("")
    lines.append(f"**Total: {total} tables**")
    lines.append("")
    return "\n".join(lines), total


def render_table(t: dict) -> str:
    lines = [
        "-" * 72,
        f"TABLE: {t['full_name']}",
        f"Migration file: {t['migration_file']}",
        f"Module purpose: {t['purpose']}",
        "",
        "COLUMNS (name | type | null | column purpose):",
        "  " + "-" * 68,
    ]
    for name, col_type, nullable, hint in t["columns"]:
        lines.append(format_column_row(name, col_type, nullable, hint))
    lines.append("")
    lines.append("CONSTRAINTS:")
    if t["constraints"]:
        for c in t["constraints"]:
            lines.append(f"  {c}")
    else:
        lines.append("  (none)")
    lines.append("")
    lines.append("INDEXES:")
    if t["indexes"]:
        for idx in t["indexes"]:
            lines.append(f"  {idx}")
    else:
        lines.append("  (none)")
    lines.append("")
    return "\n".join(lines)


def render_table_md(t: dict) -> str:
    lines = [
        f"### `{t['full_name']}`",
        "",
        f"- **Migration:** `{t['migration_file']}`",
        f"- **Purpose:** {t['purpose']}",
        "",
        "| Column | Type | Null | Notes |",
        "|--------|------|------|-------|",
    ]
    for name, col_type, nullable, hint in t["columns"]:
        null_disp = nullable
        if col_type.upper().startswith("AS "):
            null_disp = "computed"
        note = hint or ""
        lines.append(f"| `{name}` | `{col_type}` | {null_disp} | {note} |")
    lines.append("")
    if t["constraints"]:
        lines.append("**Constraints**")
        lines.append("")
        for c in t["constraints"]:
            lines.append(f"- `{c}`")
        lines.append("")
    if t["indexes"]:
        lines.append("**Indexes**")
        lines.append("")
        for idx in t["indexes"]:
            lines.append(f"- `{idx}`")
        lines.append("")
    return "\n".join(lines)


def appendix(total: int) -> str:
    return f"""
========================================================================
APPENDIX: WHAT IS IN SQL vs MONGODB vs REDIS vs BLOB
========================================================================

SQL SERVER ({total} tables in this reference)
  Core ERP: students, teachers, masters, timetable, attendance,
  exams, assignments, homework, fees, receipts, library,
  transport, security (auth), leave, grievance, announcements.

MONGODB (see database/docs/mongodb-collections-reference.md)
  - Student Overview / Compass snapshots
  - Learning Hub (syllabus, resources, exam papers, progress)
  - Connect masters (chat threads, meetings, community)
  - Auth JWT session hashes (user_jwt_token)
  - Document / attachment metadata + Blob refs

AZURE BLOB STORAGE
  - Actual file bytes (PDF, images) linked from MongoDB metadata

REDIS (live only)
  - Live bus GPS lat/long and ETA
  - Connect unread / presence / recent message cache
  - Optional access-token blacklist on logout

AUTH IN SQL (security_schema)
  - users (identity + credentials), user_login_attempt, schema_version
  - Access + refresh token hashes: MongoDB user_jwt_token
  - Authorization: user_type + FastAPI domain rules (no SQL RBAC / user_scope)

NOT BUILT YET
  - Alumni tables
  - Dedicated audit_log schema

========================================================================
END OF REFERENCE
========================================================================
"""


def appendix_md(total: int) -> str:
    return f"""
## Appendix: SQL vs MongoDB vs Redis vs Blob

### SQL Server ({total} tables)

Core ERP: students, teachers, masters, timetable, attendance, exams, assignments, homework, fees, receipts, library, transport, security (auth), leave, grievance, announcements.

### MongoDB

See [mongodb-collections-reference.md](./mongodb-collections-reference.md).

- Student Overview / Compass snapshots
- Learning Hub (syllabus, resources, exam papers, progress)
- Connect masters (chat threads, meetings, community)
- Auth JWT session hashes (`user_jwt_token`)
- Document / attachment metadata + Blob refs

### Azure Blob Storage

Actual file bytes (PDF, images) linked from MongoDB metadata.

### Redis (live only)

- Live bus GPS lat/long and ETA
- Connect unread / presence / recent message cache
- Optional access-token blacklist on logout

### Auth in SQL (`security_schema`)

- `users` (identity + credentials), `user_login_attempt`, `schema_version`
- Access + refresh token hashes: MongoDB `user_jwt_token`
- Authorization: `user_type` + FastAPI domain rules (no SQL RBAC / `user_scope`)
"""


def main() -> None:
    tables = load_all_tables()
    index_block, total = build_index(tables)
    index_md, _ = build_index_md(tables)

    header = f"""THINKIGEN DATABASE - FULL TABLE REFERENCE
========================================================================
Generated from SQL module migrations 001-017

HOW TO READ THIS DOCUMENT
------------------------------------------------------------------------
PK       = Primary Key (unique row ID, clustered index)
FK       = Foreign Key (references another table)
UNIQUE   = Duplicate values not allowed
CHECK    = Allowed values / business rules
row_version = SQL Server concurrency protection

DATE/TIME API FORMATS
------------------------------------------------------------------------
DATETIME2(0)  ->  2026-07-17T14:00:00  (stored UTC)
DATE          ->  2026-07-18
TIME(0)       ->  14:00:00

{index_block}
"""

    header_md = f"""# Thinkigen Database — Full Table Reference

Generated from SQL module migrations `001`–`017`.

Related: [mongodb-collections-reference.md](./mongodb-collections-reference.md) · [conventions.md](./conventions.md)

## How to read

| Marker | Meaning |
|--------|---------|
| PK | Primary key (unique row ID, clustered) |
| FK | Foreign key |
| UNIQUE | Duplicate values not allowed |
| CHECK | Allowed values / business rules |
| row_version | SQL Server concurrency protection |

## Date/time API formats

| SQL type | API format |
|----------|------------|
| `DATETIME2(0)` | `2026-07-17T14:00:00` (stored UTC) |
| `DATE` | `2026-07-18` |
| `TIME(0)` | `14:00:00` |

{index_md}
"""

    by_schema: dict[str, list[dict]] = {}
    for t in tables:
        by_schema.setdefault(t["schema"], []).append(t)

    body_parts: list[str] = []
    body_md: list[str] = []
    for schema in sorted(by_schema):
        body_parts.append("=" * 72)
        body_parts.append(schema.upper())
        body_parts.append("=" * 72)
        body_parts.append("")
        body_md.append(f"## `{schema}`")
        body_md.append("")
        for t in sorted(by_schema[schema], key=lambda x: x["full_name"]):
            body_parts.append(render_table(t))
            body_md.append(render_table_md(t))

    content = header + "\n".join(body_parts) + appendix(total)
    content_md = header_md + "\n".join(body_md) + appendix_md(total)

    OUTPUT_TXT.write_text(content, encoding="utf-8")
    OUTPUT_MD.write_text(content_md, encoding="utf-8")
    print(f"Wrote {OUTPUT_TXT} ({total} tables)")
    print(f"Wrote {OUTPUT_MD} ({total} tables)")


if __name__ == "__main__":
    main()
