/*
    Test: 001_schema_integrity
    Purpose: Post-migration validation — objects exist, constraints, seed data

    Run after 000_run_all.sql on LOCAL / DEV only.
*/

SET NOCOUNT ON;

IF OBJECT_ID(N'tempdb..#schema_test_failures') IS NOT NULL
    DROP TABLE #schema_test_failures;

CREATE TABLE #schema_test_failures
(
    test_name NVARCHAR(200) NOT NULL,
    detail    NVARCHAR(500) NOT NULL
);

/* Expected: 54+ tables across 9 schemas */
DECLARE @table_count INT;
SELECT @table_count = COUNT(*)
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN (
    N'security_schema', N'management_schema', N'student_schema', N'teachers_schema',
    N'finance_schema', N'library_schema', N'transport_schema', N'alumni_schema', N'sports_schema'
);

IF @table_count < 54
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'table_count', CONCAT(N'Expected >= 54 tables, found ', @table_count));

IF NOT EXISTS (SELECT 1 FROM security_schema.users WHERE email_address = N'admin@thinkigen.local')
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'admin_user', N'admin user missing from seed');

IF NOT EXISTS (
    SELECT 1
    FROM security_schema.users u
    WHERE u.email_address = N'admin@thinkigen.local'
      AND u.password_plain_dev IS NOT NULL
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'admin_credential', N'admin password_plain_dev missing on users row');

IF COL_LENGTH(N'security_schema.users', N'username') IS NOT NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'legacy_username', N'users.username must not exist');

IF OBJECT_ID(N'security_schema.user_credential', N'U') IS NOT NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'legacy_user_credential', N'user_credential must not exist');

IF OBJECT_ID(N'security_schema.user_refresh_token', N'U') IS NOT NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'legacy_refresh_token', N'user_refresh_token must not exist');

IF OBJECT_ID(N'security_schema.role', N'U') IS NOT NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'legacy_role', N'role table must not exist');

IF OBJECT_ID(N'security_schema.permission', N'U') IS NOT NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'legacy_permission', N'permission table must not exist');

IF OBJECT_ID(N'security_schema.user_scope', N'U') IS NOT NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'legacy_user_scope', N'user_scope must not exist');

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_branch_school_scope'
      AND object_id = OBJECT_ID(N'management_schema.branch')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'scope_index_branch', N'UQ_branch_school_scope missing');

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_student_branch_scope'
      AND parent_object_id = OBJECT_ID(N'student_schema.student')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'student_scope_fk', N'FK_student_branch_scope missing');

IF OBJECT_ID(N'security_schema.user_login_attempt', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'login_attempt_table', N'user_login_attempt table missing');

IF OBJECT_ID(N'teachers_schema.assessment', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'assessment_table', N'teachers_schema.assessment table missing');

IF OBJECT_ID(N'student_schema.assessment_result', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'assessment_result_table', N'student_schema.assessment_result table missing');

IF OBJECT_ID(N'finance_schema.fee_structure_term', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'fee_structure_term', N'fee_structure_term table missing');

IF OBJECT_ID(N'finance_schema.fee_structure_other', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'fee_structure_other', N'fee_structure_other table missing');

IF OBJECT_ID(N'finance_schema.term_fee_payment_transaction', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'term_fee_payment_transaction', N'term_fee_payment_transaction table missing');

IF OBJECT_ID(N'finance_schema.other_fee_payment_transaction', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'other_fee_payment_transaction', N'other_fee_payment_transaction table missing');

IF OBJECT_ID(N'finance_schema.fee_payment_transaction', N'U') IS NOT NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'legacy_fee_payment_transaction', N'legacy fee_payment_transaction must not exist');

IF NOT EXISTS (SELECT 1 FROM security_schema.schema_version WHERE migration_name = N'002_security')
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'schema_version', N'schema_version not populated');

IF OBJECT_ID(N'student_schema.grievance_history', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'grievance_history_table', N'student_schema.grievance_history table missing');

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_grievance_status'
      AND parent_object_id = OBJECT_ID(N'student_schema.grievance')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'grievance_status_constraint', N'CK_grievance_status missing from student_schema.grievance');

IF EXISTS (
    SELECT 1 FROM student_schema.grievance
    WHERE status NOT IN (N'SUBMITTED', N'UNDER_REVIEW', N'RESOLVED')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'grievance_illegal_status', N'student_schema.grievance contains rows with disallowed status values');

IF COL_LENGTH(N'student_schema.grievance', N'department_id') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'grievance_department_id', N'department_id column missing from student_schema.grievance');

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_grievance_history_grievance_id'
      AND object_id = OBJECT_ID(N'student_schema.grievance_history')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'grievance_history_unique', N'UQ_grievance_history_grievance_id missing');

IF NOT EXISTS (
    SELECT 1 FROM security_schema.schema_version
    WHERE migration_name = N'013_grievance'
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'grievance_migration_version', N'013_grievance not recorded in schema_version');

IF COL_LENGTH(N'management_schema.timetable_period', N'subject_topic') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'timetable_period_subject_topic', N'subject_topic column missing from management_schema.timetable_period');

IF OBJECT_ID(N'alumni_schema.alumni_profile', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'alumni_profile_table', N'alumni_schema.alumni_profile table missing');

IF COL_LENGTH(N'management_schema.announcement', N'sub_category') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'announcement_sub_category', N'management_schema.announcement sub_category column missing');

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_announcement_sub_category'
      AND parent_object_id = OBJECT_ID(N'management_schema.announcement')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'announcement_sub_category_check', N'CK_announcement_sub_category check constraint missing');

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_announcement_type'
      AND parent_object_id = OBJECT_ID(N'management_schema.announcement')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'announcement_type_check', N'CK_announcement_type check constraint missing');

IF OBJECT_ID(N'alumni_schema.alumni_story', N'U') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'alumni_story_table', N'alumni_schema.alumni_story table missing');

IF COL_LENGTH(N'teachers_schema.homework', N'allow_late_submission') IS NOT NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'homework_allow_late_submission_dropped', N'allow_late_submission column still exists in teachers_schema.homework');

IF COL_LENGTH(N'student_schema.homework_status', N'submission_timing') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'homework_status_submission_timing_exists', N'submission_timing column missing from student_schema.homework_status');

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_homework_status_submission_timing'
      AND parent_object_id = OBJECT_ID(N'student_schema.homework_status')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'homework_status_submission_timing_check', N'CK_homework_status_submission_timing constraint missing');

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_homework_type'
      AND parent_object_id = OBJECT_ID(N'teachers_schema.homework')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'homework_type_check', N'CK_homework_type constraint missing');

IF COL_LENGTH(N'teachers_schema.teacher', N'designation') IS NULL
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'teacher_designation_exists', N'designation column missing from teachers_schema.teacher');

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'teachers_schema.teacher')
      AND name = N'designation'
      AND is_nullable = 1
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'teacher_designation_not_null', N'designation column must be NOT NULL');

IF EXISTS (
    SELECT 1
    FROM teachers_schema.teacher t
    LEFT JOIN management_schema.subject s ON s.subject_id = t.subject_id
    WHERE t.designation IS NULL
       OR t.designation <> CONCAT(s.subject_name, ' Teacher')
)
    INSERT INTO #schema_test_failures (test_name, detail)
    VALUES (N'teacher_designation_match', N'teacher designation must match <subject_name> Teacher');

IF EXISTS (SELECT 1 FROM #schema_test_failures)
BEGIN
    SELECT test_name, detail FROM #schema_test_failures;
    DROP TABLE #schema_test_failures;
    THROW 50001, N'Schema integrity tests FAILED. See result set above.', 1;
END;

DROP TABLE #schema_test_failures;
PRINT N'Schema integrity tests PASSED (51 tables, simplified security, finance 6-table model, grievance 2-table refactor, alumni module, seeds).';
GO
