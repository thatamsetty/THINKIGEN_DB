/*
    Rollback: 020_alumni_rollback.sql
    Module:   020_alumni.sql
    Purpose:  Safely drop alumni module tables and schema in reverse dependency order
*/

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'alumni_schema.alumni_story', N'U') IS NOT NULL
BEGIN
    DROP TABLE alumni_schema.alumni_story;
    PRINT N'Dropped table alumni_schema.alumni_story.';
END;
GO

IF OBJECT_ID(N'alumni_schema.alumni_event', N'U') IS NOT NULL
BEGIN
    DROP TABLE alumni_schema.alumni_event;
    PRINT N'Dropped table alumni_schema.alumni_event.';
END;
GO

IF OBJECT_ID(N'alumni_schema.alumni_profile', N'U') IS NOT NULL
BEGIN
    DROP TABLE alumni_schema.alumni_profile;
    PRINT N'Dropped table alumni_schema.alumni_profile.';
END;
GO

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'alumni_schema')
BEGIN
    DROP SCHEMA alumni_schema;
    PRINT N'Dropped schema alumni_schema.';
END;
GO
