# Entity: student_schema.exam_result

## Purpose

Per-student result for one `exam_schedule` row.

## Academic hierarchy

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id` → `student_id`

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| exam_result_id | BIGINT | NO | PK |
| exam_schedule_id | BIGINT | NO | FK → exam_schedule |
| school_id … section_id | BIGINT | NO | Full scope FKs |
| student_id | BIGINT | NO | FK → student |
| marks_obtained | DECIMAL(6,2) | YES | NULL when ABSENT |
| result_status | NVARCHAR(20) | NO | PASS / FAIL / ABSENT |
| grade | NVARCHAR(10) | YES | Letter grade |
| rank_in_class | INT | YES | Optional rank |
| remarks | NVARCHAR(500) | YES | |
| published_at | DATETIME2(0) | YES | Visibility to student |

## Unique

`(exam_schedule_id, student_id)`

## Not stored

- `percentage` — compute from `marks_obtained` and `exam_schedule.max_marks`
- `term` — not on exams

## Application rules

- Scope columns must match parent `exam` / `exam_schedule` and `student` at insert time
- `marks_obtained <= max_marks` enforced in FastAPI
