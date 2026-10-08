/*
    Migration runner: execute all module migrations in dependency order
    Environment: LOCAL / DEVELOPMENT only until formally promoted

    Module layout:
    001 schemas | 002 security | 003 management | 004 teacher | 005 student
    006 assignment | 007 announcement | 008 timetable | 009 homework
    010 attendance | 011 leave | 012 holidays | 013 grievance (grievance + grievance_history)
    014 library | 015 transport | 016 finance | 017 exam | 018 achievements
    019 residency + section teacher
*/

:r .\001_schemas.sql
:r .\002_security.sql
:r .\003_management.sql
:r .\004_teacher.sql
:r .\005_student.sql
:r .\006_assessment.sql
:r .\007_announcement.sql
:r .\008_timetable.sql
:r .\009_homework.sql
:r .\010_attendance.sql
:r .\011_leave.sql
:r .\012_holidays.sql
:r .\013_grievance.sql
:r .\014_library.sql
:r .\015_transport.sql
:r .\016_finance.sql
:r .\017_exam.sql
:r .\018_student_achievements.sql
:r .\019_student_residency_and_section_class_teacher.sql
:r .\020_alumni.sql
:r .\021_student_exam_performance.sql
:r .\022_personal_development.sql
:r .\023_cultural_participation.sql
:r .\024_teacher_designation.sql
:r .\025_sports_and_grievance_department.sql
:r ..\seeds\001_dev_seed.sql
:r ..\tests\001_schema_integrity.sql
