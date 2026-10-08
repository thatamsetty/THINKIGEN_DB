# Entity: teachers_schema.teacher

## Purpose

Teacher identity master within the Organization database.

`subject_id` is an optional primary-subject reference only. Authoritative teaching scope is `teachers_schema.teacher_subject_assignment`.

Subject name and code are **not duplicated** on this table.

## Primary key

- `teacher_id` — `BIGINT IDENTITY`, clustered

## Columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| teacher_id | BIGINT | NO | PK |
| user_id | BIGINT | YES | Optional login FK |
| school_id | BIGINT | NO | School FK |
| branch_id | BIGINT | NO | Branch FK |
| subject_id | BIGINT | YES | Optional FK → subject master |
| designation | VARCHAR(100) | NO | `<subject_name> Teacher` (mapped from subject master) |
| employee_code | NVARCHAR(50) | NO | Unique per school |
| status | NVARCHAR(20) | NO | ACTIVE / INACTIVE / ON_LEAVE |
| row_version | ROWVERSION | NO | Concurrency |

## Uniqueness

`(school_id, employee_code)`

## Related tables

- `teachers_schema.teacher_subject_assignment` — section-level teaching scope
- `teachers_schema.assessment` — assessments and graded tests (separate from teacher master)
