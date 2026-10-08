# Entity: management_schema.class_subject

## Purpose

Class-wise subject curriculum — which master subjects are offered for a class in a given school, branch, and academic year.

## Primary key

- `class_subject_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| school_id, branch_id, academic_year_id, class_id | BIGINT | NO | Academic scope FKs |
| subject_id | BIGINT | NO | FK → management_schema.subject |
| is_active | BIT | NO | Active flag |
| row_version | ROWVERSION | NO | Concurrency |

## Uniqueness

`(school_id, branch_id, academic_year_id, class_id, subject_id)`

## UI flow

1. Admin selects school → branch → academic year → class.
2. Assigns subjects from master catalog.
3. Then assigns teachers per section in `teacher_subject_assignment`.

## Not stored here

- Teacher assignment → `teachers_schema.teacher_subject_assignment`
- Syllabus / course % → MongoDB + API
