# Entity: student_schema.assessment_result

## Purpose

Per-student assessment marks for one assessment (project work, slip test, quiz).

Modeled as an assessment marks storing table, carrying academic scope (`school_id` → `section_id` → `student_id`) for ABAC filtering.

## Primary key

- `assessment_result_id` — `BIGINT IDENTITY`, clustered

## Columns

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| assessment_id | BIGINT | NO | — | FK → assessment |
| school_id | BIGINT | NO | — | FK → school |
| branch_id | BIGINT | NO | — | FK → branch |
| academic_year_id | BIGINT | NO | — | FK → academic_year |
| class_id | BIGINT | NO | — | FK → school_class |
| section_id | BIGINT | NO | — | FK → section |
| student_id | BIGINT | NO | — | FK → student |
| marks_obtained | DECIMAL(6,2) | YES | — | Student score |
| grade | NVARCHAR(10) | YES | — | Letter grade (e.g. A, B, C) |
| remarks | NVARCHAR(500) | YES | — | Teacher feedback / evaluation remarks |
| graded_at | DATETIME2(0) | YES | — | Evaluation timestamp |
| graded_by | BIGINT | YES | — | FK → users (evaluating teacher/user) |
| is_active | BIT | NO | 1 | Soft-active |
| row_version | ROWVERSION | NO | — | Concurrency |

## Constraints

| Name | Rule |
|------|------|
| UQ_assessment_result_assessment_student | One row per student per assessment |
| CK_assessment_result_marks | marks_obtained >= 0 when present |
| CK_assessment_result_graded | marks, graded_at, graded_by all set or all null |

## Indexes

- `IX_assessment_result_student_scope` — student academic scope
- `IX_assessment_result_student_assessment` — student direct assessment lookup
- `IX_assessment_result_assessment` — assessment marks overview
