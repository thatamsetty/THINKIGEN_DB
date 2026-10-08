# Entity: teachers_schema.assessment

## Purpose

Authoritative assessment master. One row = one assessment (e.g. project work, slip test, quiz) for one school, branch, academic year, class, section, and subject.

All assessments are **subject-wise** (`subject_id`). Students in that scope receive rows in `student_schema.assessment_result`.

Assessment file attachments/metadata: **MongoDB + Blob Storage**, not SQL.

## Primary key

- `assessment_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| school_id … section_id | BIGINT | NO | Academic scope FKs |
| subject_id | BIGINT | NO | Subject FK (subject-wise) |
| teacher_id | BIGINT | NO | Creating teacher FK |
| title | NVARCHAR(200) | NO | Assessment title |
| assessment_type | NVARCHAR(50) | NO | PROJECT_WORK / SLIP_TEST / QUIZ / OTHER |
| assessment_date | DATE | NO | Scheduled date for slip test/quiz/assessment |
| max_marks | DECIMAL(6,2) | NO | Total maximum marks |
| is_active | BIT | NO | Soft-active flag |
| row_version | ROWVERSION | NO | Concurrency |

## Constraints

- `CK_assessment_type` — PROJECT_WORK, PROJECT, SLIP_TEST, QUIZ, OTHER
- `CK_assessment_max_marks` — max_marks > 0

## Indexes

- `IX_assessment_scope_date` — scope, assessment_date
- `IX_assessment_teacher_active` — teacher dashboard
- `IX_assessment_subject` — subject-wise assessment listing
