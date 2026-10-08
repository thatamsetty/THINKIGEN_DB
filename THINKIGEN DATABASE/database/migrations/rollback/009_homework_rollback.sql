/*
    Rollback: 009_homework_rollback.sql
    Module:   teachers_schema.homework & student_schema.homework_status
    Purpose:  Rollback allow_late_submission removal and submission_timing addition.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
BEGIN TRY
    -- 1. Rollback student_schema.homework_status
    IF OBJECT_ID(N'student_schema.homework_status', N'U') IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 FROM sys.check_constraints
            WHERE name = N'CK_homework_status_submission_timing'
              AND parent_object_id = OBJECT_ID(N'student_schema.homework_status')
        )
        BEGIN
            ALTER TABLE student_schema.homework_status
                DROP CONSTRAINT CK_homework_status_submission_timing;
        END;

        IF COL_LENGTH(N'student_schema.homework_status', N'submission_timing') IS NOT NULL
        BEGIN
            ALTER TABLE student_schema.homework_status
                DROP COLUMN submission_timing;
        END;
    END;

    -- 2. Rollback teachers_schema.homework
    IF OBJECT_ID(N'teachers_schema.homework', N'U') IS NOT NULL
    BEGIN
        -- Re-add allow_late_submission if missing
        IF COL_LENGTH(N'teachers_schema.homework', N'allow_late_submission') IS NULL
        BEGIN
            ALTER TABLE teachers_schema.homework
                ADD allow_late_submission BIT NOT NULL CONSTRAINT DF_homework_allow_late_submission DEFAULT (0);
        END;

        -- Re-expand CK_homework_type
        IF EXISTS (
            SELECT 1 FROM sys.check_constraints
            WHERE name = N'CK_homework_type'
              AND parent_object_id = OBJECT_ID(N'teachers_schema.homework')
        )
        BEGIN
            ALTER TABLE teachers_schema.homework
                DROP CONSTRAINT CK_homework_type;
        END;

        ALTER TABLE teachers_schema.homework
            ADD CONSTRAINT CK_homework_type CHECK
            (homework_type IN (
                N'HOMEWORK', N'PROJECT_WORK', N'READING', N'REVISION',
                N'LAB_REPORT', N'WRITTEN_WORK', N'PROJECT', N'OTHER'));
    END;

    COMMIT TRANSACTION;
    PRINT N'Homework rollback completed successfully.';
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
