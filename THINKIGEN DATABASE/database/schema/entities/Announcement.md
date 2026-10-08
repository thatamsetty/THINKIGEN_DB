# Entity: management_schema.announcement

## Purpose

School/branch-level announcements for Student Overview: **EVENT**, **ACADEMIC**, **NOTICE**.

Categories and Sub-categories mapping:
- **ACADEMIC**: `EXAMS`, `SYLLABUS`, `TIMETABLE`
- **NOTICE**: `STUDENT_INSTRUCTIONS`, `OTHER`
- **EVENT**: `SPORTS`, `CULTURAL`, `ALUMNI_EVENTS`

Used for unexpected or ad-hoc communications (exams, syllabus, notices, sports, cultural/alumni events).  
For fixed planned non-working days, use `management_schema.holiday` (branch calendar master).

## Academic scope

`school_id` → `branch_id` → `academic_year_id`

**Not** class, section, or student (all students in the branch see published announcements).

## Columns

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| announcement_id | BIGINT | NO | IDENTITY | PK clustered |
| school_id | BIGINT | NO | — | FK → school |
| branch_id | BIGINT | NO | — | FK → branch |
| academic_year_id | BIGINT | NO | — | FK → academic_year |
| announcement_type | NVARCHAR(20) | NO | — | EVENT / ACADEMIC / NOTICE |
| sub_category | NVARCHAR(50) | NO | 'STUDENT_INSTRUCTIONS' | Mapped to category (ACADEMIC: EXAMS, SYLLABUS, TIMETABLE; NOTICE: STUDENT_INSTRUCTIONS, OTHER; EVENT: SPORTS, CULTURAL, ALUMNI_EVENTS) |
| title | NVARCHAR(200) | NO | — | Title |
| description | NVARCHAR(MAX) | YES | — | Body text |
| target_audience | NVARCHAR(100) | NO | 'ALL' | Target audience (ALL, STUDENTS, TEACHERS, PARENTS, etc.) |
| registration_url | NVARCHAR(2048) | YES | — | Optional HTTPS registration URL |
| start_date | DATE | YES | — | Event/holiday start |
| end_date | DATE | YES | — | Event/holiday end |
| publish_at | DATETIME2(0) | NO | — | Visibility datetime UTC |
| status | NVARCHAR(20) | NO | — | DRAFT / PUBLISHED / ARCHIVED |
| is_active | BIT | NO | 1 | Soft active |
| created_at | DATETIME2(0) | NO | SYSUTCDATETIME() | |
| created_by | BIGINT | NO | — | FK → users |
| updated_at | DATETIME2(0) | NO | SYSUTCDATETIME() | |
| updated_by | BIGINT | YES | — | FK → users |

## Constraints

| Name | Rule |
|------|------|
| CK_announcement_type | EVENT, ACADEMIC, NOTICE |
| CK_announcement_sub_category | Enforces mapping per category: ACADEMIC (EXAMS, SYLLABUS, TIMETABLE), NOTICE (STUDENT_INSTRUCTIONS, OTHER), EVENT (SPORTS, CULTURAL, ALUMNI_EVENTS) |
| CK_announcement_status | DRAFT, PUBLISHED, ARCHIVED |
| CK_announcement_date_range | end_date >= start_date when both set |

## Indexes

| Name | Columns | Purpose |
|------|---------|---------|
| IX_announcement_branch_status_publish | school_id, branch_id, status, publish_at | Student feed |
| IX_announcement_branch_date | branch_id, start_date, end_date | Current/upcoming |
| IX_announcement_type_date | branch_id, announcement_type, start_date | Type filter |
| IX_announcement_academic_year | academic_year_id, branch_id, announcement_type | Year reports |

## Attachments

MongoDB + Blob Storage only. No SQL attachment table or `blob_id` on this table.

## Not used

- No `row_version` (per approved doc)
- No recipient table
- No separate event/holiday/notice tables

## Student query pattern

Match student's `school_id`, `branch_id`, `academic_year_id`; `status = PUBLISHED`; `publish_at <= UTC now`; `is_active = 1`.
