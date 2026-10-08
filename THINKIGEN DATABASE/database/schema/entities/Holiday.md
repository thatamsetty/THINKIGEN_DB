# Entity: management_schema.holiday

## Purpose

**Fixed** official holiday calendar per **branch** and academic year — planned non-working days (Independence Day, Diwali vacation, etc.).

Used to skip timetable period generation and attendance expectations on those dates.

## Distinction from announcements

| | `management_schema.holiday` | `management_schema.announcement` |
|--|---------------------------|----------------------------------|
| Nature | **Fixed / planned** calendar | **Unexpected or ad-hoc** communications |
| Examples | National holiday, term break | Sudden closure, extra class, urgent notice |
| Scope | Per **branch** + academic year | Per branch + academic year |
| Student UI | Calendar / no-school days | Student Overview feed (EVENT / HOLIDAY / NOTICE types) |

Do not duplicate the same fixed holiday as an announcement unless you also want a student-facing notice.

## Scope

`school_id` + `branch_id` + `academic_year_id` (holidays are **per branch**, not class/section)

## Key columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| holiday_id | BIGINT | NO | PK |
| holiday_type | NVARCHAR(30) | NO | NATIONAL / RELIGIOUS / FESTIVAL / VACATION / OPTIONAL / OTHER |
| holiday_name | NVARCHAR(150) | NO | Display name |
| description | NVARCHAR(MAX) | YES | Optional detail |
| start_date / end_date | DATE | NO | Inclusive range; same date for single-day holiday |

## Application rules

- Do not generate `timetable_period` on dates within an active holiday range for that branch/year
- Overlapping holiday ranges for the same branch: block or merge in application layer
