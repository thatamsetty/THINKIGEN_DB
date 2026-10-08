# Entity: student_schema.grievance + student_schema.grievance_history

## Purpose

Student complaint (grievance) with assignment and resolution workflow.

**Two tables** — `grievance` (current state) + `grievance_history` (lifecycle timestamps).
Evidence files: **MongoDB + Blob Storage**, not SQL.

## Display ID

- `grievance_number` — e.g. `GRV-2026-1`, unique org-wide; backend (FastAPI) generates on insert.
  Format: `GRV-{ACADEMIC_YEAR_START_YEAR}-{SEQUENCE}` (sequence is academic-year scoped, backend-managed).

## Academic hierarchy

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id` → `student_id`

Scope must match student placement at submit time.

## Complaint fields

| Column | Notes |
|--------|-------|
| title | Short title |
| category | ACADEMIC / TRANSPORT / HOSTEL / BULLYING / FACILITIES / FEE / STAFF_BEHAVIOR / OTHER |
| priority_level | LOW / MEDIUM / HIGH — student selects |
| incident_date | When incident occurred |
| location | Where it occurred |
| description | Full details |

## Status workflow

```text
SUBMITTED → UNDER_REVIEW → RESOLVED
```

| Status | Rules |
|--------|-------|
| SUBMITTED | `assigned_to` may be NULL or populated (backend assigns during submission) |
| UNDER_REVIEW | `assigned_to` MUST NOT be NULL |
| RESOLVED | `assigned_to` MUST NOT be NULL |

The database enforces `assigned_to NOT NULL` for `UNDER_REVIEW` and `RESOLVED` via `CK_grievance_assigned_to_required`.

## Department routing

A grievance belongs to a department via `department_id`:
- Student submits grievance
- Backend/FastAPI determines `department_id` based on complaint nature
- Department determines responsible Department Head user ID (`assigned_to`)
- Status transitions: `SUBMITTED` → `UNDER_REVIEW` → `RESOLVED`

No department routing tables or user-mapping logic are stored in SQL; resolution is handled by FastAPI.

## TABLE 1: student_schema.grievance

Stores the grievance and its **current state**.

| Column | Type | Notes |
|--------|------|-------|
| grievance_id | BIGINT IDENTITY | PK |
| grievance_number | NVARCHAR(30) | UQ; backend-generated (`GRV-YYYY-N`) |
| school_id | BIGINT | FK → management_schema.school |
| branch_id | BIGINT | FK → management_schema.branch |
| academic_year_id | BIGINT | FK → management_schema.academic_year |
| class_id | BIGINT | FK → management_schema.school_class |
| section_id | BIGINT | FK → management_schema.section |
| student_id | BIGINT | FK → student_schema.student |
| department_id | BIGINT | Department responsible for handling |
| title | NVARCHAR(200) | |
| category | NVARCHAR(50) | CHECK: 8 allowed values |
| priority_level | NVARCHAR(20) | CHECK: LOW/MEDIUM/HIGH |
| incident_date | DATE | |
| location | NVARCHAR(200) | |
| description | NVARCHAR(MAX) | |
| status | NVARCHAR(30) | CHECK: SUBMITTED/UNDER_REVIEW/RESOLVED |
| submitted_at | DATETIME2(0) | DEFAULT SYSUTCDATETIME() |
| assigned_to | BIGINT NULL | FK → security_schema.users; NOT NULL when UNDER_REVIEW/RESOLVED |
| is_active | BIT | DEFAULT 1 |
| created_at | DATETIME2(0) | DEFAULT SYSUTCDATETIME() |
| created_by | BIGINT | FK → security_schema.users |
| updated_at | DATETIME2(0) | DEFAULT SYSUTCDATETIME() |
| updated_by | BIGINT NULL | FK → security_schema.users |
| row_version | ROWVERSION | Concurrency |

## TABLE 2: student_schema.grievance_history

**One-to-one** lifecycle table. One row per grievance. Stores timestamps only — no business data.

| Column | Type | Notes |
|--------|------|-------|
| grievance_history_id | BIGINT IDENTITY | PK |
| grievance_id | BIGINT | FK → grievance; UQ (one-to-one) |
| submitted_by | BIGINT | FK → security_schema.users (student user ID) |
| submitted_at | DATETIME2(0) | When submitted |
| assigned_to | BIGINT NULL | FK → security_schema.users (teacher/in-charge) |
| reviewed_at | DATETIME2(0) NULL | When review completed |
| resolved_at | DATETIME2(0) NULL | When resolved |
| updated_at | DATETIME2(0) | DEFAULT SYSUTCDATETIME() |
| updated_by | BIGINT NULL | FK → security_schema.users |
| row_version | ROWVERSION | Concurrency |

### History constraints

- `resolved_at IS NULL OR reviewed_at IS NOT NULL` — cannot resolve without reviewing
- `reviewed_at IS NULL OR assigned_to IS NOT NULL` — cannot review without an assignee

### History lifecycle

| Phase | submitted_by | submitted_at | assigned_to | reviewed_at | resolved_at |
|-------|-------------|-------------|------------|-------------|-------------|
| After submission | populated | populated | populated (backend-assigned) | NULL | NULL |
| Under review | populated | populated | populated | populated | NULL |
| Resolved | populated | populated | populated | populated | populated |

## Relationship

```
student_schema.grievance  1 ──── 1  student_schema.grievance_history
```

## Indexes

### grievance
- `IX_grievance_scope_status` — management queue by school/branch/class/section (filtered: is_active=1)
- `IX_grievance_branch_status` — branch complaint list (filtered: is_active=1)
- `IX_grievance_student_status` — student "my grievances" (filtered: is_active=1)
- `IX_grievance_assigned_to_status` — assignee workload (filtered: is_active=1 AND assigned_to IS NOT NULL)
- `IX_grievance_submitted` — new queue awaiting assignment (filtered: is_active=1 AND status=SUBMITTED)

### grievance_history
- `UQ_grievance_history_grievance_id` — one-to-one enforcement (implicit unique index)
- `IX_grievance_history_resolved` — SLA/reporting (filtered: resolved_at IS NOT NULL)
- `IX_grievance_history_assigned_to` — assignee reporting (filtered: assigned_to IS NOT NULL)

## Application rules

- Backend generates `grievance_number` as `GRV-{year}-{sequence}` scoped to academic year
- `assigned_to` is set by backend during submission (not a separate database-level step)
- Student edit only when `status = SUBMITTED` (FastAPI RBAC)
- Soft delete only: use `is_active = 0`; never physically delete resolved grievances
- Evidence attachments: MongoDB collection keyed by `grievance_id` / `grievance_number`

## Migration history

| Migration | Description |
|-----------|-------------|
| `013_grievance.sql` | Original single-table design (7 statuses) |
| `020_grievance_refactor.sql` | Refactored to two-table, three-status design |
