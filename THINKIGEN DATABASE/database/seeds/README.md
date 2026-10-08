# Database Seeds

## 001_dev_seed.sql

Bootstrap data for local development:

- Admin user (`admin@thinkigen.local` / `Admin@123`)
- `schema_version` tracking rows

No SQL roles/permissions (authorization via `user_type` + FastAPI).

Run automatically via `migrations/000_run_all.sql`.

## 002_THINKIGEN_REALISTIC_MOCK_DATA_V22.sql

Complete 48-table mock seed dataset covering realistic school operational data across all domains.

## 003_finance_mock_data_1_to_30.sql

Dedicated mock seed dataset for Finance module (students 1 to 30).

## 004_grievance_mock_data.sql

Dedicated mock seed dataset for Student Grievance module:
- 60 realistic records in `student_schema.grievance`
- 60 corresponding 1:1 lifecycle tracking records in `student_schema.grievance_history`
- Covers all 8 categories, 3 priority levels, and 3 statuses (`SUBMITTED`, `UNDER_REVIEW`, `RESOLVED`)
- Integrated with department routing via `department_id`

## 005_library_mock_data.sql

Dedicated mock seed dataset for Library module:
- 200 catalog titles across 4 branches in `library_schema.library_book` (`book_id` 1 to 200)
- 600 physical book copies across all 7 statuses (`AVAILABLE`, `BORROWED`, `OVERDUE`, `LOST`, `DAMAGED`, `MAINTENANCE`, `RETIRED`) in `library_schema.library_book_copy` (`book_copy_id` 1 to 600)
- 52 circulation ledger transactions across all 4 statuses (`ACTIVE`, `OVERDUE`, `RETURNED`, `LOST`) in `library_schema.library_book_borrow`, including 21 realistic transactions for Student 1 (`school_id = 1, branch_id = 1, class_id = 1, section_id = 1, student_id = 1`)
- Strict multi-tenant composite foreign keys matching school, branch, student, class, section, and academic year scopes
- Synchronized `total_copies` and `available_copies` inventory counters

## 006_timetable_period_subject_topic_mock_data.sql

Dedicated mock data script for Timetable Period Topics (`subject_topic`):
- Safely populates and updates `subject_topic` on existing `management_schema.timetable_period` rows without modifying any existing IDs or relations.
- Joins with `management_schema.subject` using `subject_id` to assign curriculum-aligned chapter and lesson topics (e.g. Mathematics: "Algebra Ex 3.1", Science: "Plant Cell Biology", English, Social Science, Computer Science, etc.).
- Preserves `NULL` for non-CLASS period types (BREAK, LUNCH, ACTIVITY, FREE).

## 007_alumni_directory_10th_passed_out_mock_data.sql

Dedicated mock seed dataset for Alumni Directory, Stories, and Events:
- **Strict Scope**: Exclusively populates 10th Class passed-out (graduated) students (`student_status = 'GRADUATED'`).
- **Running Year Exclusion**: Strictly excludes students from current running academic years (`is_current = 1`). Backed by past academic years (`2021-2022` through `2024-2025`, `is_current = 0`).
- **Alumni Profiles**: 8 realistic alumni records across tech domains (Google, Microsoft, ISRO, AWS, TCS, Zoho, Spicarts, IIT Madras).
- **Alumni Stories**: 3 featured success stories linked to verified alumni.
- **Alumni Events**: 3 career mentorship, reunion, and gala events.
- **Idempotent**: Safe to re-run; uses `IF NOT EXISTS` checks.

## 008_announcement_category_subcategory_mock_data.sql

Dedicated mock seed dataset for Announcement Category & Sub-Category distribution:
- **110 Realistic Announcements (100+ rows)**: Comprehensive distribution across all 4 branches.
- **Category Mappings Enforced**:
  - `EVENT` $\to$ `ALUMNI_EVENTS` (22), `SPORTS` (18), `CULTURAL` (18)
  - `ACADEMIC` $\to$ `EXAMS` (12), `SYLLABUS` (10), `TIMETABLE` (10)
  - `NOTICE` $\to$ `STUDENT_INSTRUCTIONS` (10), `OTHER` (10)
- **Registration URL Configured**: Configured with `https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0` on interactive events and competitions.
- **Multi-Tenant Referential Integrity**: Dynamically maps `school_id`, `branch_id`, and `academic_year_id` from `management_schema.branch`.
- **User Resolution**: Dynamically maps `created_by` and `updated_by` to verified users in `security_schema.users`.
- **Idempotent**: Safe to re-run; uses `WHERE NOT EXISTS` check on titles.

## 009_assessment_mock_data.sql

Dedicated mock seed dataset for Subject-Wise Assessments and Student Results:
- **Subject-Wise Assessments**: Covers `PROJECT_WORK`, `PROJECT`, `SLIP_TEST`, `QUIZ`, and `OTHER` across all active classes, sections, and subjects.
- **Student Assessment Marks**: Evaluates all enrolled students per section with realistic marks, letter grades (`A+`, `A`, `B+`, `B`, `C`), evaluator remarks, timestamps, and teacher audit linkage.
- **Constraint-Conforming Absent Handling**: Exactly respects `CK_assessment_result_graded` (`marks IS NULL AND graded_at IS NULL AND graded_by IS NULL` for absent students).
- **Idempotent**: Safe to re-run; uses `WHERE NOT EXISTS` on compound uniqueness keys.

## 010_homework_mock_data.sql

Dedicated mock seed dataset for Updated Homework Module:
- **Homework Master**: Populates `teachers_schema.homework` across `HOMEWORK`, `READING`, and `OTHER` types, with priority levels (`HIGH`, `MEDIUM`, `LOW`) and statuses (`PUBLISHED`, `CLOSED`), adhering to `deadline_at >= assigned_at` and `published_at` rules with NO `allow_late_submission`.
- **Student Homework Status**: Populates `student_schema.homework_status` for all students with realistic submission distribution:
  * `ON_TIME` (~70%): `submitted_at <= deadline_at`
  * `LATE` (~15%): `submitted_at > deadline_at`
  * `NOT_SUBMITTED` (~15%): `submitted_at = NULL` and `submission_timing = NULL`
- **Constraint Compliance**: Verified against `CK_homework_status_submitted_at` and `CK_homework_status_submission_timing`.
- **Idempotent**: Safe to re-run; checks compound uniqueness before inserting.

## 011_student_exam_performance_mock_data.sql

Dedicated mock data script for Student Exam Performance Summaries:
- **Source Data**: Directly queries existing records in `student_schema.exam_result`, `management_schema.exam_schedule`, and `management_schema.exam` (with fallback to `teachers_schema.assessment` & `student_schema.assessment_result`).
- **Simulates Backend Calculation**:
  1. Computes exam-level percentage: `SUM(marks_obtained) * 100.0 / SUM(max_marks)`
  2. Determines count of distinct exams evaluated: `COUNT(DISTINCT exam_id)`
  3. Computes student overall average percentage: `AVG(exam_percentage)`
- **Zero Database Computations**: Inserts pure summary values into `student_schema.student_exam_performance` without computed columns or triggers.
- **Idempotent**: Uses `MERGE` on `(student_id, academic_year_id, class_id, section_id)` for safe re-execution.

## 012_personal_development_mock_data.sql

Dedicated mock data script for Personal Development Module:
- **Class Teacher Ratings**: Populates `student_schema.student_personality_development` across leadership, communication, collaboration, responsibility, and overall rating on a 0.00 to 5.00 scale.
- **Subject-Based Reviews**: Populates `student_schema.student_personality_development_review` with qualitative reviews linked to respective subject teachers (Mathematics, Science, English, Social Science, Computer Science).
- **Idempotent**: Uses `NOT EXISTS` checks and validation queries.

## 013_cultural_participation_mock_data.sql

Dedicated mock data script for Cultural Participation Module:
- **50+ Realistic Participation Rows**: Populates `student_schema.student_cultural_participation` with rich student records spanning dance, theatre, choirs, fine arts, poetry, and folk festivals.
- **Announcement Event Integration**: Integrates directly with `management_schema.announcement` (`announcement_type = 'EVENT'`, `sub_category = 'CULTURAL'`), including defensive seeding of cultural events if not previously loaded.
- **Class Teacher Authorization Binding**: Accurately maps each student to their section's designated Class Teacher via `teachers_schema.section_class_teacher_assignment`.
- **Constraint-Safe Distribution**: Validated across all allowed statuses (`PARTICIPATED`, `REGISTERED`, `CANCELLED`), categories (`PERFORMING_ARTS`, `VISUAL_ARTS`, `MUSIC`, `CULTURAL_ACTIVITIES`), roles (`DANCER`, `VOCALIST`, `ACTOR`, `INSTRUMENTALIST`, `EXHIBITOR`, `PARTICIPANT`, `ORGANIZER`), and competition results (`FIRST_PLACE`, `SECOND_PLACE`, `THIRD_PLACE`, `RUNNER_UP`, `SPECIAL_MENTION`, `PERFORMED`, `COMPLETED`).
- **Idempotent & Deduplicated**: Safely re-runnable without constraint violations using `ROW_NUMBER()` partitioning and `NOT EXISTS` guards on `(student_id, announcement_id)`.

## 014_timetable_section1_two_weeks_mock_data.sql

Dedicated mock data replacement script for Class 8 - Section A (`school_id = 1, branch_id = 1, class_id = 1, section_id = 1`):
- **Exact 2-Week Duration**: Seeds 12 full school days (Monday through Saturday across 2 weeks, 7 periods/day = 84 periods).
- **Mandatory Subject Coverage**: Guarantees prominent presence of `subject_id = 3` (Science) on every single day with distinct, curriculum-aligned topics and lab activities.
- **Strict Zero-NULL Policy**: Eliminates all NULL values across all period columns (`period_name`, `start_time`, `end_time`, `period_type`, `subject_id`, `subject_topic`, `teacher_id`, `room_name`, `activity_name`, `updated_by`).
- **Complete Referential & Constraint Integrity**: Validates against `school`, `branch`, `school_class`, `section`, `academic_year`, `subject`, `teacher`, and `teacher_subject_assignment`. Safely manages `student_schema.student_attendance` foreign keys.

## 015_transport_mock_data.sql

Dedicated mock seed dataset for the Transport Module:
- **Prerequisites**: Tables and stored procedures deployed via `database/migrations/015_transport.sql`.
- **4 Vehicles**: 1 per campus branch (`transport_schema.vehicle`).
- **8 Staff**: 4 Drivers with verified licenses and 4 Attendants (`transport_schema.staff`).
- **8 Vehicle Routes**: Morning Pickup and Afternoon Drop across all 4 branches (`transport_schema.vehicle_route`).
- **24 Route Stops**: 3 stops per route with planned timings (`transport_schema.vehicle_route_stop`).
- **8 Trips**: 4 `IN_TRANSIT` with realized timestamps and 4 `SCHEDULED` (`transport_schema.trip`).
- **24 Operational Trip Stops**: Departed, Arrived, and Pending sequence statuses (`transport_schema.trip_stop`).
- **24 Speed Measurements**: GPS telemetry tracking logs aligned with trip vehicles (`transport_schema.speed_measurement`).
- **Active Day-Scholar Assignments**: Day-scholar student assignments with pickup and drop stop mapping (`student_schema.transport_assignment`).
- **4 Transport Change Requests**: Comprehensive coverage of `TEMPORARY` and `PERMANENT` request types across `APPROVED`, `PENDING`, and `REJECTED` lifecycle states (`student_schema.transport_change_request`).

## 017_sports_mock_data.sql

Dedicated mock seed dataset for the Sports History module:
- **Prerequisite**: `sports_schema.student_sport_history` table deployed via `database/migrations/025_sports_and_grievance_department.sql`.
- **Self-Sustaining Announcements**: Checks for existing SPORTS announcements; defensively seeds 4 realistic sports events if fewer than 3 exist.
- **19 Sport Events** across 9 sport types: Athletics, Cricket, Kabaddi, Kho-Kho, Basketball, Volleyball, Badminton, Table Tennis, Chess, Swimming, Handball, Football.
- **60+ Records** spread across Branch 1 & 2, Classes 6–10, both sections.
- **sport_category distribution**: `TRACK_AND_FIELD`, `TEAM`, `INDIVIDUAL`, `INDOOR`, `OUTDOOR`.
- **Realistic Results**: `1st Place`, `2nd Place`, `3rd Place`, `Selected for District`, `Winner`, `Team Member`, `Participated`.
- **Dynamic FK Resolution**: Resolves `school_id`, `branch_id`, `class_id`, `section_id`, `created_by` from live data — no hard-coded IDs.
- **Idempotent**: `NOT EXISTS` guard on `(student_id, sport_name, activity_date)` prevents duplicate rows on re-runs.

**Production:** Do not run dev/mock seeds. Use a controlled provisioning process and bcrypt/argon2 password hashes only.

