# Entity: teachers_schema.teacher_subject_assignment

## Purpose

Section-level teaching assignment — which teacher teaches which subject to which section for an academic year.

## Primary key

- `teacher_subject_assignment_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| school_id … section_id | BIGINT | NO | Academic scope FKs |
| class_subject_id | BIGINT | NO | FK → class_subject |
| subject_id | BIGINT | NO | Subject FK |
| teacher_id | BIGINT | NO | Assigned teacher FK |
| is_active | BIT | NO | Active flag |
| row_version | ROWVERSION | NO | Concurrency |

## Uniqueness

`(school_id, branch_id, academic_year_id, class_id, section_id, subject_id)`

## Student subject list

Students inherit via `student.class_id` + `student.section_id` joined to `class_subject` and `teacher_subject_assignment`.
