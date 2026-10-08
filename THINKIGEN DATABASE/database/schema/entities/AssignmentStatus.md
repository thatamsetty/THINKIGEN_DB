# Entity: student_schema.assignment_status

## Purpose

Per-student assignment submission and marks for one assignment.

Carries **academic scope** (`school_id` → `section_id`) on each row for ABAC filtering without joining back to `assignment` master.

Does **not** duplicate assignment title, deadline, or `max_marks` from `teachers_schema.assignment`.

## Primary key

- `assignment_status_id` — `BIGINT IDENTITY`, clustered

## Columns

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| assignment_id | BIGINT | NO | — | FK → assignment |
| school_id | BIGINT | NO | — | FK → school |
| branch_id | BIGINT | NO | — | FK → branch |
| academic_year_id | BIGINT | NO | — | FK → academic_year |
| class_id | BIGINT | NO | — | FK → school_class |
| section_id | BIGINT | NO | — | FK → section |
| student_id | BIGINT | NO | — | FK → student |
| submission_status | NVARCHAR(20) | NO | NOT_SUBMITTED | NOT_SUBMITTED / SUBMITTED |
| submitted_at | DATETIME2(0) | YES | — | Set when SUBMITTED |
| marks_obtained | DECIMAL(6,2) | YES | — | Student marks (graded) |
| remarks | NVARCHAR(500) | YES | — | Grading remarks |
| graded_at | DATETIME2(0) | YES | — | When marks recorded |
| graded_by | BIGINT | YES | — | FK → users |
| is_active | BIT | NO | 1 | Soft-active |
| row_version | ROWVERSION | NO | — | Concurrency |

## Constraints

| Name | Rule |
|------|------|
| UQ_assignment_status_assignment_student | One row per student per assignment |
| CK_assignment_status_submission_status | NOT_SUBMITTED, SUBMITTED only |
| CK_assignment_status_submitted_at | SUBMITTED ↔ submitted_at consistency |
| CK_assignment_status_marks_obtained | marks >= 0 when present |
| CK_assignment_status_graded | marks, graded_at, graded_by all set or all null |

## Indexes

- `IX_assignment_status_student_scope` — scope + student ABAC queries
- `IX_assignment_status_student_submission` — student dashboard
- `IX_assignment_status_student_assignment` — direct lookup
- `IX_assignment_status_assignment_submission` — teacher submission view

## Business rules

- Scope columns must match parent `assignment` row and student's placement when status row is created (application layer)
- No `started_at` / `completed_at` / IN_PROGRESS lifecycle
- OVERDUE derived from `assignment.deadline_at` when `submission_status <> SUBMITTED`
- `max_marks` on assignment master; `marks_obtained` on this row per student
- `marks_obtained <= assignment.max_marks` enforced in application layer
