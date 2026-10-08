# Thinkigen Database Migrations

## Module layout (one SQL file per domain)

| File | Domain | Tables |
|------|--------|--------|
| `001_schemas.sql` | All schemas | — |
| `002_security.sql` | Identity & auth | users (with credentials), user_login_attempt, schema_version |
| `003_management.sql` | School structure | school, branch, academic_year, school_class, section, subject, class_subject |
| `004_teacher.sql` | Teachers | teacher, teacher_subject_assignment |
| `017_exam.sql` | Exams (management) | exam, exam_schedule |
| `005_student.sql` | Students | student, student_guardian, exam_result |
| `006_assignment.sql` | Assignments | assignment, assignment_status |
| `007_announcement.sql` | Announcements | announcement |
| `008_timetable.sql` | Timetable | timetable, timetable_period |
| `009_homework.sql` | Homework | homework, homework_status |
| `010_attendance.sql` | Attendance | student_attendance |
| `011_leave.sql` | Leave | student_leave |
| `012_holidays.sql` | Holidays | holiday (calendar) |
| `013_grievance.sql` | Grievances | grievance (3-status), grievance_history (one-to-one lifecycle) |
| `014_library.sql` | Library | library_book, library_book_copy, library_book_borrow, library_book_reservation, library_bookmark |
| `015_transport.sql` | Transport | vehicle, staff, vehicle_route, trip, trip_stop, speed_measurement, transport_assignment, transport_change_request |
| `016_finance.sql` | Finance | fee_structure_term, fee_structure_other, student_term_fee_record, student_other_fee_record, term_fee_payment_transaction, other_fee_payment_transaction |
| `020_alumni.sql` | Alumni | alumni_profile, alumni_story |
| `021_student_exam_performance.sql` | Student Performance | student_exam_performance (backend-calculated summary metrics) |
| `022_personal_development.sql` | Personal Development | student_personality_development, student_personality_development_review |
| `023_cultural_participation.sql` | Cultural Participation | student_cultural_participation |

## Run (local)

```bash
sqlcmd -S localhost -d ThinkigenOrg -E -i database/migrations/000_run_all.sql
```

Includes dev seed (`database/seeds/001_dev_seed.sql`) and integrity tests (`database/tests/001_schema_integrity.sql`).

## Dev admin login

- Email: `admin@thinkigen.local`
- Password: `Admin@123` (in `password_plain_dev` — hash before production)

## Auth storage

| Item | Store |
|------|-------|
| Password hash | SQL `users.password_hash` |
| Login attempt audit | SQL `user_login_attempt` (append-only; `user_id` NOT NULL) |
| Access + refresh token hashes | MongoDB `user_jwt_token` |
| Authorization | `user_type` + FastAPI domain rules (student/teacher placement) |
| Migration tracking | SQL `schema_version` |
