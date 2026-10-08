# Entity: management_schema.exam_schedule

## Purpose

Subject-wise exam paper within a parent `exam`.

## Academic hierarchy

Same scope columns as `exam`:

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id`

Plus: `exam_id`, `subject_id`, `teacher_id`, schedule times, marks config.

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| exam_schedule_id | BIGINT | NO | PK |
| exam_id | BIGINT | NO | FK → exam |
| school_id … section_id | BIGINT | NO | Full scope FKs |
| subject_id | BIGINT | NO | FK → subject |
| teacher_id | BIGINT | NO | FK → teacher |
| exam_date | DATE | NO | Paper date |
| start_time, end_time | TIME(0) | NO | Session time |
| max_marks | DECIMAL(6,2) | NO | > 0 |
| pass_marks | DECIMAL(6,2) | YES | <= max_marks |
| status | NVARCHAR(20) | NO | SCHEDULED / COMPLETED / CANCELLED |

## Unique

`(exam_id, subject_id)` — one paper per subject per exam.
