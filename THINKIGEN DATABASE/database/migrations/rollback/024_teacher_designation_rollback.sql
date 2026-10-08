/* Rollback: 024_teacher_designation_rollback.sql */
/*
    Rollback migration 024: remove designation column from teachers_schema.teacher
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'Rolling back Migration 024: Dropping designation column from teachers_schema.teacher...';

IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'teachers_schema.teacher', N'designation') IS NOT NULL
    BEGIN
        ALTER TABLE teachers_schema.teacher
            DROP COLUMN designation;
        PRINT N'✔ Column designation successfully dropped from teachers_schema.teacher.';
    END;
END;
GO
