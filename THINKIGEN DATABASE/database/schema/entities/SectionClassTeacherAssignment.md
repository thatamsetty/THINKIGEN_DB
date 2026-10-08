# Entity: teachers_schema.section_class_teacher_assignment

## Purpose

Stores the class teacher assigned to one section for an academic year. It is separate from `teacher_subject_assignment`, which assigns teachers to subjects.

## Primary key

- `section_class_teacher_assignment_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| school_id … section_id | BIGINT | NO | School, branch, academic year, class, and section scope |
| teacher_id | BIGINT | NO | Assigned class teacher in the same school and branch |
| is_active | BIT | NO | Only one active assignment is allowed per section scope |
| created_at / updated_at | DATETIME2(0) | NO | UTC audit timestamps |
| row_version | ROWVERSION | NO | Optimistic concurrency |

## Rules

- Each school, branch, academic year, class, and section combination has at most one active class teacher.
- Deactivate the current assignment before creating a replacement, preserving assignment history.
- The assigned teacher must belong to the same school and branch.
