# Entity: management_schema.timetable_period

## Purpose

One calendar date + one period slot for a section timetable. Teachers are assigned per CLASS period for teacher UI.

## Columns

| Column | Type | Null | Notes |
|--------|------|------|-------|
| timetable_period_id | BIGINT | NO | PK; attendance FK → student_attendance |
| timetable_id | BIGINT | NO | FK → timetable |
| period_date | DATE | NO | Calendar date; weekday from API (IST) |
| period_number | TINYINT | NO | 1, 2, 3… per day |
| period_name | NVARCHAR(50) | YES | e.g. Period 1 |
| start_time / end_time | TIME(0) | NO | |
| period_type | NVARCHAR(30) | NO | CLASS / BREAK / LUNCH / ACTIVITY / FREE |
| subject_id | BIGINT | YES | Required when CLASS; subject_name via JOIN |
| subject_topic | NVARCHAR(200) | YES | Lesson/chapter topic for CLASS period |
| teacher_id | BIGINT | YES | Required when CLASS; teacher My Day |
| room_name | NVARCHAR(150) | YES | No room master |
| activity_name | NVARCHAR(150) | YES | ACTIVITY periods |
| row_version | ROWVERSION | NO | Concurrency |

## Constraints

| Name | Rule |
|------|------|
| UQ_timetable_period_slot | (timetable_id, period_date, period_number) |
| CK_timetable_period_class | CLASS requires subject_id + teacher_id |

## UI queries

- **Student My Day:** ACTIVE timetable for student's section + `period_date = today` (retrieves `subject_name`, `subject_topic`, `room_name`, `start_time`, `end_time`).
- **Teacher My Day:** `teacher_id = @teacher` + `period_date = today` + join timetable for class/section names (displays period workload & current `subject_topic`).
- **Teacher Topic Edit:** `UPDATE management_schema.timetable_period SET subject_topic = @topic, updated_at = SYSUTCDATETIME(), updated_by = @user_id WHERE timetable_period_id = @id AND is_active = 1 AND row_version = @expected_row_version` (concurrency-protected, CLASS periods only).

## Indexes

- `IX_timetable_period_my_day` — student section day view
- `IX_timetable_period_teacher_day` — teacher day view
