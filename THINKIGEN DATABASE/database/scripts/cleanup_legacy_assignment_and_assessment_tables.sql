/*
    Script:    cleanup_legacy_assignment_and_assessment_tables.sql
    Directory: database/scripts/
    Purpose:   Safely remove legacy assignment tables (teachers_schema.assignment,
               student_schema.assignment_status) and clean mock data from assessment tables.

    This script handles:
    1. Dropping legacy child table: student_schema.assignment_status
    2. Dropping legacy parent table: teachers_schema.assignment
    3. Resetting / deleting mock data from assessment tables (teachers_schema.assessment,
       student_schema.assessment_result) if requested.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Cleaning Up Legacy Assignment Tables & Mock Data...';
PRINT N'========================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    -- =========================================================================
    -- 1. DROP CONSTRAINTS / CHILD: student_schema.assignment_status
    -- =========================================================================
    IF OBJECT_ID(N'student_schema.assignment_status', N'U') IS NOT NULL
    BEGIN
        PRINT N'Dropping table: student_schema.assignment_status...';
        DROP TABLE student_schema.assignment_status;
        PRINT N'Dropped table student_schema.assignment_status successfully.';
    END
    ELSE
    BEGIN
        PRINT N'Table student_schema.assignment_status does not exist. Skipping.';
    END;

    -- =========================================================================
    -- 2. DROP PARENT: teachers_schema.assignment
    -- =========================================================================
    IF OBJECT_ID(N'teachers_schema.assignment', N'U') IS NOT NULL
    BEGIN
        PRINT N'Dropping table: teachers_schema.assignment...';
        DROP TABLE teachers_schema.assignment;
        PRINT N'Dropped table teachers_schema.assignment successfully.';
    END
    ELSE
    BEGIN
        PRINT N'Table teachers_schema.assignment does not exist. Skipping.';
    END;

    -- =========================================================================
    -- 3. RESET MOCK DATA IN ASSESSMENT TABLES (OPTIONAL / SAFE RESEED)
    -- =========================================================================
    -- If you also want to clear mock data from the assessment tables to re-run 009_assessment_mock_data.sql:
    IF OBJECT_ID(N'student_schema.assessment_result', N'U') IS NOT NULL
    BEGIN
        DELETE FROM student_schema.assessment_result;
        PRINT N'Cleared existing mock rows from student_schema.assessment_result.';
    END;

    IF OBJECT_ID(N'teachers_schema.assessment', N'U') IS NOT NULL
    BEGIN
        DELETE FROM teachers_schema.assessment;
        PRINT N'Cleared existing mock rows from teachers_schema.assessment.';
    END;

    COMMIT TRANSACTION;
    PRINT N'========================================================================';
    PRINT N'Cleanup completed and committed successfully.';
    PRINT N'========================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO
