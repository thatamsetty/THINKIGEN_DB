"""
Generate database/docs/mongodb-collections-reference.md from mongo/collections/*.js
Includes purpose, indexes, and full createCollection validator for each collection.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COLLECTIONS = ROOT / "mongo" / "collections"
OUTPUT = ROOT / "docs" / "mongodb-collections-reference.md"

DOMAIN_ORDER = [
    ("Overview", [
        "student_mission_control_daily",
        "student_compass_intelligence_daily",
        "student_learning_health_daily",
    ]),
    ("Learning Hub", [
        "class_subject_syllabus",
        "learning_resource",
        "exam_paper",
        "student_learning_progress",
    ]),
    ("Connect", [
        "connect_conversation",
        "connect_meeting",
        "connect_community",
        "connect_community_member",
        "connect_community_join_request",
        "connect_community_post",
        "connect_community_comment",
        "connect_community_post_like",
        "connect_community_discussion",
        "connect_community_discussion_reply",
        "connect_community_poll",
        "connect_community_poll_vote",
    ]),
    ("Auth", [
        "user_jwt_token",
    ]),
    ("Shared Documents", [
        "thinkigen_documents",
    ]),
    ("Career Explorer", [
        "career_industries",
        "career_paths",
    ]),
]


def extract_header_comment(text: str) -> str:
    m = re.match(r"/\*(.*?)\*/", text, re.S)
    return m.group(1).strip() if m else ""


def extract_purpose(header: str) -> str:
    m = re.search(r"Purpose:\s*(.+?)(?:\n\s*\n|\n\s*[A-Z][a-z]+:|\Z)", header, re.S)
    if not m:
        m = re.search(r"Purpose:\s*(.+)", header)
    if not m:
        return ""
    purpose = re.sub(r"\s+", " ", m.group(1)).strip()
    return purpose


def extract_collection_name(text: str, fallback: str) -> str:
    m = re.search(r'createCollection\(\s*"([^"]+)"', text)
    if m:
        return m.group(1)
    m = re.search(r"Collection:\s*(\S+)", text)
    return m.group(1) if m else fallback


def extract_validator_call(text: str, collection: str) -> str:
    """Return createCollection(... validationAction: \"error\" }) block."""
    needle = f'db.createCollection("{collection}"'
    start = text.find(needle)
    if start < 0:
        return ""
    # find matching closing for createCollection( ... );
    i = text.find("(", start)
    depth = 0
    end = None
    for j in range(i, len(text)):
        ch = text[j]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                end = j + 1
                break
    if end is None:
        return ""
    block = text[start:end].rstrip()
    if not block.endswith(";"):
        # include trailing ); already ended at )
        pass
    return block + ";"


def extract_indexes(text: str, collection: str) -> list[str]:
    indexes: list[str] = []
    # createIndex({ ... }, { ... })
    pattern = re.compile(
        rf"db\.{re.escape(collection)}\.createIndex\(\s*(\{{.*?\}})\s*,\s*(\{{.*?\}})\s*\)",
        re.S,
    )
    for m in pattern.finditer(text):
        keys = re.sub(r"\s+", " ", m.group(1).strip())
        opts = re.sub(r"\s+", " ", m.group(2).strip())
        name_m = re.search(r'name:\s*"([^"]+)"', opts)
        name = name_m.group(1) if name_m else "(unnamed)"
        extras = []
        if "unique: true" in opts:
            extras.append("unique")
        if "sparse: true" in opts:
            extras.append("sparse")
        if "expireAfterSeconds" in opts:
            extras.append("TTL")
        suffix = f" [{', '.join(extras)}]" if extras else ""
        indexes.append(f"`{name}` — `{keys}`{suffix}")
    return indexes


def load_collections() -> dict[str, dict]:
    result: dict[str, dict] = {}
    for path in sorted(COLLECTIONS.glob("*.js")):
        text = path.read_text(encoding="utf-8")
        header = extract_header_comment(text)
        names = re.findall(r'createCollection\(\s*"([^"]+)"', text)
        if not names:
            name = extract_collection_name(text, path.stem)
            names = [name]
        for name in names:
            result[name] = {
                "file": path.name,
                "purpose": extract_purpose(header),
                "header": header,
                "validator": extract_validator_call(text, name),
                "indexes": extract_indexes(text, name),
            }
    return result


def render_collection(name: str, meta: dict) -> str:
    lines = [
        f"### `{name}`",
        "",
        f"- **Source:** `database/mongo/collections/{meta['file']}`",
    ]
    if meta["purpose"]:
        lines.append(f"- **Purpose:** {meta['purpose']}")
    lines.append("")
    if meta["indexes"]:
        lines.append("**Indexes**")
        lines.append("")
        for idx in meta["indexes"]:
            lines.append(f"- {idx}")
        lines.append("")
    lines.append("**Validation script**")
    lines.append("")
    lines.append("```javascript")
    lines.append(meta["validator"] or f'// validator not found for {name}')
    lines.append("```")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    cols = load_collections()
    known = set()
    for _, names in DOMAIN_ORDER:
        known.update(names)

    missing = [n for n in cols if n not in known]
    extra_domain = ("Other", sorted(missing)) if missing else None

    lines: list[str] = [
        "# Thinkigen MongoDB — Collections Reference",
        "",
        "SQL Server remains the ERP system of record.",
        "MongoDB stores Compass / Learning Hub / Connect documents and auth session hashes.",
        "One Organization = one Mongo database (same isolation as SQL).",
        "",
        "Related: [full-table-reference.md](./full-table-reference.md) · `database/mongo/README.md`",
        "",
        "This document includes the **full `createCollection` validation script** for every collection,",
        "generated from `database/mongo/collections/*.js`.",
        "",
        "SQL BIGINT IDs must be stored as `NumberLong` in Mongo.",
        "",
        "---",
        "",
        "## Collection index",
        "",
        "| Domain | Collection | Source script |",
        "|--------|------------|---------------|",
    ]

    domains = list(DOMAIN_ORDER)
    if extra_domain:
        domains.append(extra_domain)

    for domain, names in domains:
        for name in names:
            meta = cols.get(name)
            if not meta:
                continue
            lines.append(f"| {domain} | `{name}` | `{meta['file']}` |")

    lines.append("")
    lines.append(f"**Total collections:** {len(cols)}")
    lines.append("")
    lines.append("---")
    lines.append("")

    for domain, names in domains:
        lines.append(f"## {domain}")
        lines.append("")
        for name in names:
            meta = cols.get(name)
            if not meta:
                lines.append(f"### `{name}`")
                lines.append("")
                lines.append("_Collection script not found._")
                lines.append("")
                continue
            lines.append(render_collection(name, meta))

    lines.extend(
        [
            "---",
            "",
            "## Not stored in Mongo",
            "",
            "### Connect",
            "",
            "- Chat / group message history → Parquet `chat_events`",
            "- Unread / presence / recent message cache → Redis",
            "- Removed: meeting “I'm Interested”",
            "",
            "### Overview (SQL / API)",
            "",
            "- Classes KPI (timetable + attendance)",
            "- Assignments KPI",
            "- Next assessment card (`exam_schedule`)",
            "- Teacher homework / assignment checklist rows",
            "",
            "---",
            "",
            "## Apply (local)",
            "",
            "```javascript",
        ]
    )
    for path in sorted(COLLECTIONS.glob("*.js")):
        lines.append(f'load("database/mongo/collections/{path.name}");')
    lines.extend(
        [
            "```",
            "",
            "Or run each file in `mongosh` against the Organization database.",
            "",
            "---",
            "",
            "## Regenerate this document",
            "",
            "```bash",
            "python database/scripts/generate_mongodb_collections_reference.py",
            "```",
            "",
            "## Related docs",
            "",
            "| Doc | Path |",
            "|-----|------|",
            "| SQL full table reference | [full-table-reference.md](./full-table-reference.md) |",
            "| Mongo apply notes | `database/mongo/README.md` |",
            "| Chat Parquet | `database/parquet/connect_chat_events.md` |",
            "| Community Parquet | `database/parquet/connect_community_events.md` |",
            "| Redis keys | `database/redis/connect_keys.md` |",
            "",
        ]
    )

    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUTPUT} ({len(cols)} collections)")


if __name__ == "__main__":
    main()
