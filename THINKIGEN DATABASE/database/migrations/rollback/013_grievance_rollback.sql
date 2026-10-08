/* ============================================================================
   Rollback script: 013_grievance_rollback.sql
   Target: student_schema.grievance_history, student_schema.grievance
   ============================================================================ */

SET NOCOUNT ON;
GO

PRINT N'Rolling back 013_grievance...';

IF OBJECT_ID(N'student_schema.grievance_history', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping student_schema.grievance_history...';
    DROP TABLE student_schema.grievance_history;
END;
GO

IF OBJECT_ID(N'student_schema.grievance', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping student_schema.grievance...';
    DROP TABLE student_schema.grievance;
END;
GO

IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NOT NULL
BEGIN
    DELETE FROM security_schema.schema_version WHERE migration_name = N'013_grievance';
END;
GO

PRINT N'Rollback of 013_grievance complete.';
GO
