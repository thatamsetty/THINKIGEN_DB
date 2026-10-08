# Entity: management_schema.timetable

## Purpose

Section-wise timetable master. One ACTIVE timetable per section scope per academic year; periods are stored in `timetable_period`.

## Academic scope

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id`

Each section (e.g. 8-A at Branch Main) has its own timetable. Different branches and sections have separate timetables.

## Columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| timetable_id | BIGINT | NO | PK |
| school_id … section_id | BIGINT | NO | Full scope FKs |
| timetable_name | NVARCHAR(150) | NO | Display name |
| status | NVARCHAR(20) | NO | DRAFT / ACTIVE / INACTIVE |
| is_active | BIT | NO | Soft delete |
| row_version | ROWVERSION | NO | Concurrency on master edits |
| audit columns | DATETIME2(0) UTC | | created_at/by, updated_at/by |

## Constraints

| Name | Rule |
|------|------|
| UX_timetable_section_active | One ACTIVE + is_active row per section scope |
| CK_timetable_status | DRAFT, ACTIVE, INACTIVE |

## Lifecycle

1. Create timetable (DRAFT)
2. Add rows in `timetable_period`
3. Publish → status ACTIVE (only one ACTIVE per section)
4. Edit periods in place; use row_version on update

## Not used

- No `day_of_week` (use `period_date` on periods)
- No `effective_from` versioning
- No `room` master table
