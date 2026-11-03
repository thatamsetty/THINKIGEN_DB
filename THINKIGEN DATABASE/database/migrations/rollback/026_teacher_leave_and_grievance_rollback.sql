/* ============================================================================
   Rollback Script: rollback_026_teacher_leave_and_grievance.sql
   Target: Teacher Leave Management & Grievance Management (teachers_schema)
   ============================================================================ */

SET NOCOUNT ON;
GO

PRINT N'Rolling back Migration 026: Teacher Leave & Grievance Management...';

-- 1. Drop Tables (in reverse dependency order)
IF OBJECT_ID(N'teachers_schema.teacher_grievance_status_history', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping table teachers_schema.teacher_grievance_status_history...';
    DROP TABLE teachers_schema.teacher_grievance_status_history;
END;
GO

IF OBJECT_ID(N'teachers_schema.teacher_grievance', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping table teachers_schema.teacher_grievance...';
    DROP TABLE teachers_schema.teacher_grievance;
END;
GO

IF OBJECT_ID(N'teachers_schema.teacher_leave_status_history', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping table teachers_schema.teacher_leave_status_history...';
    DROP TABLE teachers_schema.teacher_leave_status_history;
END;
GO

IF OBJECT_ID(N'teachers_schema.teacher_leave_application', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping table teachers_schema.teacher_leave_application...';
    DROP TABLE teachers_schema.teacher_leave_application;
END;
GO

IF OBJECT_ID(N'teachers_schema.teacher_leave_allowance', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping table teachers_schema.teacher_leave_allowance...';
    DROP TABLE teachers_schema.teacher_leave_allowance;
END;
GO

-- 2. Cleanup Legacy Server Objects (Views, Stored Procedures, Triggers) if present
IF OBJECT_ID(N'teachers_schema.vw_class_teacher_academic_grievances', N'V') IS NOT NULL
    DROP VIEW teachers_schema.vw_class_teacher_academic_grievances;
GO

IF OBJECT_ID(N'teachers_schema.vw_class_teacher_student_leave_approvals', N'V') IS NOT NULL
    DROP VIEW teachers_schema.vw_class_teacher_student_leave_approvals;
GO

IF OBJECT_ID(N'teachers_schema.usp_transition_teacher_grievance_status', N'P') IS NOT NULL
    DROP PROCEDURE teachers_schema.usp_transition_teacher_grievance_status;
GO

IF OBJECT_ID(N'teachers_schema.usp_submit_teacher_grievance', N'P') IS NOT NULL
    DROP PROCEDURE teachers_schema.usp_submit_teacher_grievance;
GO

IF OBJECT_ID(N'teachers_schema.usp_cancel_teacher_leave_application', N'P') IS NOT NULL
    DROP PROCEDURE teachers_schema.usp_cancel_teacher_leave_application;
GO

IF OBJECT_ID(N'teachers_schema.usp_review_teacher_leave_application', N'P') IS NOT NULL
    DROP PROCEDURE teachers_schema.usp_review_teacher_leave_application;
GO

IF OBJECT_ID(N'teachers_schema.usp_submit_teacher_leave_application', N'P') IS NOT NULL
    DROP PROCEDURE teachers_schema.usp_submit_teacher_leave_application;
GO

IF OBJECT_ID(N'teachers_schema.trg_teacher_grievance_status_history_append_only', N'TR') IS NOT NULL
    DROP TRIGGER teachers_schema.trg_teacher_grievance_status_history_append_only;
GO

IF OBJECT_ID(N'teachers_schema.trg_teacher_leave_status_history_append_only', N'TR') IS NOT NULL
    DROP TRIGGER teachers_schema.trg_teacher_leave_status_history_append_only;
GO

-- 3. Clean Migration Tracking (if recorded)
IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NOT NULL
BEGIN
    DELETE FROM security_schema.schema_version 
    WHERE migration_name IN (N'026_teacher_leave_and_grievance', N'026_teacher_leave_and_grievance.sql');
END;
GO

PRINT N'Rollback of Migration 026 completed successfully.';
GO
