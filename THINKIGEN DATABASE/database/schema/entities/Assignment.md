# Entity: teachers_schema.assignment

## Purpose

Authoritative assignment master. One row = one assignment for one school, branch, academic year, class, section, and subject.

Students in that scope receive rows in `student_schema.assignment_status`.

Assignment file attachments/metadata: **MongoDB + Blob Storage**, not SQL.

## Primary key

- `assignment_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| school_id … section_id | BIGINT | NO | Academic scope FKs |
| subject_id | BIGINT | NO | Subject FK |
| teacher_id | BIGINT | NO | Creating teacher FK |
| title | NVARCHAR(200) | NO | Assignment title |
| description | NVARCHAR(MAX) | YES | Instructions |
| assignment_type | NVARCHAR(50) | NO | Classification |
| priority_level | NVARCHAR(20) | NO | HIGH / MEDIUM / LOW |
| assigned_at | DATETIME2(0) | NO | Assigned timestamp UTC |
| deadline_at | DATETIME2(0) | NO | Submission deadline UTC |
| allow_late_submission | BIT | NO | Late submission flag |
| status | NVARCHAR(20) | NO | DRAFT / PUBLISHED / CLOSED / CANCELLED |
| estimated_minutes | INT | YES | Estimated effort |
| max_marks | DECIMAL(6,2) | YES | Maximum marks when graded |
| published_at | DATETIME2(0) | YES | Required when PUBLISHED |
| is_active | BIT | NO | Soft-active flag |
| row_version | ROWVERSION | NO | Concurrency |

## Constraints

- `CK_assignment_priority` — HIGH, MEDIUM, LOW
- `CK_assignment_status` — DRAFT, PUBLISHED, CLOSED, CANCELLED
- `CK_assignment_deadline` — deadline_at >= assigned_at
- `CK_assignment_published_at` — PUBLISHED requires published_at

## Indexes

- `IX_assignment_scope_status_deadline` — teacher/class listing
- `IX_assignment_teacher_active` — teacher dashboard

## Business rules

- Do not duplicate scope columns on `assignment_status`
- OVERDUE is derived: `deadline_at < UTC now` AND status <> COMPLETED
- Status rows created only for students matching assignment scope
