# Entity: library_schema.library_book

## Purpose

Library catalog master per branch — title, author, ISBN, subject, physical/digital format.

Digital files and cover images: **MongoDB + Blob Storage**, not SQL.

## Scope

`school_id` + `branch_id`

## Key columns

| Column | Notes |
|--------|-------|
| title, author, edition, isbn, subject | Search/filter |
| resource_format | PHYSICAL / DIGITAL |
| digital_access_type | INSTANT_ACCESS / LICENSED (required when DIGITAL) |
| location_label, shelf_code, rack_code | Physical location or "Digital Collection" |
| total_copies | Physical inventory count; digital often 0 copies table |

## KPI

Available count = copies with `copy_status = AVAILABLE` or digital instant access (computed in API).
