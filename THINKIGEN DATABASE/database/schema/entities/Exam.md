# Entity: management_schema.exam

## Purpose

Exam master for one section scope. Category examples: `ANNUAL`, `HALF_YEARLY`, `QUARTERLY`, `UNIT_TEST`.

## Academic hierarchy (on every exam table)

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id`

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| exam_id | BIGINT | NO | PK |
| school_id … section_id | BIGINT | NO | Full scope FKs |
| exam_name | NVARCHAR(150) | NO | Display name |
| exam_category | NVARCHAR(50) | NO | ANNUAL, HALF_YEARLY, etc. |
| start_date, end_date | DATE | NO | Exam period |
| status | NVARCHAR(20) | NO | DRAFT / PUBLISHED / COMPLETED / CANCELLED |
| row_version | ROWVERSION | NO | Concurrency |

No `term` column (fees only).

## Child tables

- `management_schema.exam_schedule` — subject papers
- `student_schema.exam_result` — student marks (via schedule)
