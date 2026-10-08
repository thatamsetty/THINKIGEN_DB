# Entity: teachers_schema.homework & student_schema.homework_status

## Purpose

Section-scoped homework and non-graded learning tasks (homework, reading, other) with deadlines. **No marks** — graded work stays in `teachers_schema.assessment`.

Students in scope receive rows in `student_schema.homework_status`.

Attachment metadata: **MongoDB + Blob Storage**, not SQL.

## Primary key

- `homework_id` — `BIGINT IDENTITY`, clustered

## Key columns: teachers_schema.homework

| Column | Type | Null | Notes |
|--------|------|------|-------|
| school_id … section_id | BIGINT | NO | Academic scope FKs |
| subject_id | BIGINT | NO | Subject FK |
| teacher_id | BIGINT | NO | Creating teacher FK |
| homework_type | NVARCHAR(50) | NO | HOMEWORK / READING / OTHER |
| title | NVARCHAR(200) | NO | Task title |
| description | NVARCHAR(MAX) | YES | Instructions |
| priority_level | NVARCHAR(20) | NO | HIGH / MEDIUM / LOW |
| assigned_at | DATETIME2(0) | NO | Assigned timestamp UTC |
| deadline_at | DATETIME2(0) | NO | Submission deadline UTC |
| status | NVARCHAR(20) | NO | DRAFT / PUBLISHED / CLOSED / CANCELLED |
| estimated_minutes | INT | YES | Estimated effort |
| published_at | DATETIME2(0) | YES | Required when PUBLISHED |
| row_version | ROWVERSION | NO | Concurrency |

## Key columns: student_schema.homework_status

| Column | Type | Null | Notes |
|--------|------|------|-------|
| homework_status_id | BIGINT | NO | PK clustered |
| homework_id | BIGINT | NO | FK → homework |
| student_id | BIGINT | NO | FK → student |
| submission_status | NVARCHAR(20) | NO | NOT_SUBMITTED / SUBMITTED |
| submitted_at | DATETIME2(0) | YES | Submission timestamp UTC |
| submission_timing | NVARCHAR(20) | YES | ON_TIME / LATE / NULL |
| remarks | NVARCHAR(500) | YES | Student or teacher remarks |

## Submission Timing & Business Rules

- `NOT_SUBMITTED`:
  - `submission_status = 'NOT_SUBMITTED'`
  - `submitted_at = NULL`
  - `submission_timing = NULL`
- `SUBMITTED ON TIME`:
  - `submission_status = 'SUBMITTED'`
  - `submitted_at <= deadline_at` $\to$ `submission_timing = 'ON_TIME'`
- `SUBMITTED LATE`:
  - `submission_status = 'SUBMITTED'`
  - `submitted_at > deadline_at` $\to$ `submission_timing = 'LATE'`
- OVERDUE is derived: `deadline_at < UTC now` AND `submission_status = 'NOT_SUBMITTED'`
- No `max_marks` or grade columns on homework tables
- `allow_late_submission` column is removed; lateness is strictly determined by comparing `submitted_at` against `deadline_at`.
