# Entity: student_schema.student_attendance

## Purpose

Period-wise attendance fact for each student. Links a student to an exact `timetable_period` on a calendar date with `PRESENT` or `ABSENT`.

One organization database; scope columns support school, branch, class, and section reporting without extra summary tables.

## Core business rule

**One student + one `timetable_period_id` + one `attendance_date` = one attendance row.**

## Primary key

- `student_attendance_id` — `BIGINT IDENTITY`, clustered

## Academic hierarchy

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id` → `student_id`

## Timetable link

| Column | Notes |
|--------|-------|
| `timetable_id` | FK → `management_schema.timetable` |
| `timetable_period_id` | FK → `management_schema.timetable_period` |
| `attendance_date` | Calendar date (display weekday in API, IST) |

## Period snapshot (at record time)

| Column | Type | Notes |
|--------|------|-------|
| `subject_id` | BIGINT | FK → subject |
| `teacher_id` | BIGINT | FK → teacher |
| `period_number` | TINYINT | > 0 |
| `start_time` / `end_time` | TIME(0) | `end_time > start_time` |

## Attendance

| Column | Type | Notes |
|--------|------|-------|
| `attendance_status` | NVARCHAR(10) | `PRESENT` / `ABSENT` only |
| `recorded_at` | DATETIME2(0) | UTC when marked |
| `recorded_by` | BIGINT | FK → users (who marked) |

## Constraints

| Name | Rule |
|------|------|
| `UQ_student_attendance_student_period_date` | `(student_id, timetable_period_id, attendance_date)` |
| `CK_student_attendance_status` | PRESENT, ABSENT |
| `CK_student_attendance_period_number` | period_number > 0 |
| `CK_student_attendance_time` | end_time > start_time |

## Indexes

- `IX_student_attendance_student_date` — student daily/history
- `IX_student_attendance_student_year_date` — academic-year student reports
- `IX_student_attendance_section_date` — section daily reports
- `IX_student_attendance_section_period_date` — period-wise section view
- `IX_student_attendance_teacher_date` — teacher workload
- `IX_student_attendance_status_date` — present/absent reporting
- `IX_student_attendance_timetable_period_date` — mark/view attendance for one period slot

## Application rules

- Scope and period snapshot must match `timetable`, `timetable_period`, and student placement at insert time
- `attendance_date` should equal `timetable_period.period_date` for that slot
- Create attendance only for `period_type = CLASS` unless business approves otherwise
- UI display example: `16 Aug 2026, Sun` + `10:00 AM – 12:00 PM` from `attendance_date`, `start_time`, `end_time` (IST in API)
- No LATE / LEAVE / EXCUSED / HALF_DAY statuses in approved model

## Concurrency

- `row_version` on table for optimistic concurrency on updates

## Security

Sensitive student data; enforce RBAC + ABAC using scope columns and authorized `student_id`.
