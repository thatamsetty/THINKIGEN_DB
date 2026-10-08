# Entity: student_schema.homework_status

## Purpose

Per-student submission state for one homework task. **No marks** — only submission tracking and optional teacher remarks.

Carries **academic scope** (`school_id` → `section_id`) on each row for ABAC filtering without joining back to `homework` master.

## Primary key

- `homework_status_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| homework_id | BIGINT | NO | FK → teachers_schema.homework |
| school_id | BIGINT | NO | FK → school |
| branch_id | BIGINT | NO | FK → branch |
| academic_year_id | BIGINT | NO | FK → academic_year |
| class_id | BIGINT | NO | FK → school_class |
| section_id | BIGINT | NO | FK → section |
| student_id | BIGINT | NO | FK → student_schema.student |
| submission_status | NVARCHAR(20) | NO | NOT_SUBMITTED / SUBMITTED |
| submitted_at | DATETIME2(0) | YES | Required when SUBMITTED |
| remarks | NVARCHAR(500) | YES | Optional teacher feedback (not grading) |
| row_version | ROWVERSION | NO | Concurrency |

## Constraints

- `UQ_homework_status_homework_student` — one row per student per homework

## Indexes

- `IX_homework_status_student_scope` — scope + student ABAC queries
- `IX_homework_status_student_submission` — student dashboard

## Business rules

- Scope columns must match parent `homework` row and student's placement when status row is created (application layer)
