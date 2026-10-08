# Entity: student_schema.student_leave

## Purpose

Student leave application and approval workflow. **Students only** — not teacher or staff leave.

Supporting documents: **MongoDB + Blob Storage**, not SQL.

## Academic hierarchy

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id` → `student_id`

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| student_leave_id | BIGINT | NO | PK |
| leave_type | NVARCHAR(30) | NO | CASUAL / SICK / EDUCATIONAL / PERSONAL / HEALTH |
| duration_type | NVARCHAR(20) | NO | HALF_DAY / FULL_DAY / MULTIPLE_DAYS |
| half_day_session | NVARCHAR(20) | YES | FIRST_HALF / SECOND_HALF — required when HALF_DAY |
| start_date / end_date | DATE | NO | Inclusive date range |
| reason | NVARCHAR(500) | NO | Application reason |
| status | NVARCHAR(20) | NO | PENDING / APPROVED / REJECTED / CANCELLED |
| applied_at | DATETIME2(0) | NO | When applied (UTC); no separate applied_by |
| reviewed_at / reviewed_by / review_remarks | | | Required when APPROVED or REJECTED |
| row_version | ROWVERSION | NO | Concurrency |

## Half-day meaning

| Value | Meaning |
|-------|---------|
| `FIRST_HALF` | Before lunch |
| `SECOND_HALF` | After lunch |

No period numbers on the leave row. Lunch boundary comes from branch/school configuration in the application.

## Duration rules

| duration_type | Rule |
|---------------|------|
| HALF_DAY | `start_date = end_date`, `half_day_session` required |
| FULL_DAY | `start_date = end_date`, `half_day_session` null |
| MULTIPLE_DAYS | `end_date >= start_date` |

## Prior permission rule (approved business rule)

1. Leave must be **applied before the leave day** (`start_date > CAST(applied_at AS DATE)` in SQL; validate using **IST calendar date** in FastAPI).
2. Only **`APPROVED`** leave counts as prior permission.
3. **No prior approved leave** for that day/session → student is treated as **unauthorized absence**:
   - Record **`ABSENT`** in `student_attendance` (status model stays PRESENT / ABSENT only).
   - **No excuse** path; application may apply **punishment** rules outside SQL.
4. Approver roles (class teacher / principal): enforced in **FastAPI RBAC**, not in SQL.

## Overlap prevention

Before setting `status = APPROVED`, FastAPI must reject if the student already has another **active `APPROVED`** leave whose date range overlaps, including half-day conflicts on the same date.

Overlap query pattern (use `IX_student_leave_approved_student_dates`):

```sql
-- Example: candidate [start_date, end_date] for student_id = @student_id
SELECT 1
FROM student_schema.student_leave AS existing
WHERE existing.student_id = @student_id
  AND existing.status = N'APPROVED'
  AND existing.is_active = 1
  AND existing.student_leave_id <> @candidate_leave_id
  AND existing.start_date <= @candidate_end_date
  AND existing.end_date >= @candidate_start_date;
```

For **half-day** overlap on the same date, application must also block two approved half-days on the same date or block half-day vs full-day on the same date.

## Cancellation

Rare case: update `status` from `APPROVED` to `CANCELLED` only. **`reviewed_at` / `reviewed_by` are retained** (historical approval record).

## SQL constraints

| Name | Rule |
|------|------|
| `CK_student_leave_apply_before_leave_day` | `start_date > CAST(applied_at AS DATE)` |
| `CK_student_leave_reviewed` | APPROVED/REJECTED require `reviewed_at` + `reviewed_by` |

## Not in SQL

- Overlap blocking (application layer before approve)
- Punishment / excuse flags
- Attachment metadata (MongoDB)
