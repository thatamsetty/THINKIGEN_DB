/*
    Module: 001_schemas
    Purpose: Create all Thinkigen SQL Server schemas (one Organization = one database)
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'security_schema')
    EXEC(N'CREATE SCHEMA security_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'management_schema')
    EXEC(N'CREATE SCHEMA management_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'student_schema')
    EXEC(N'CREATE SCHEMA student_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'teachers_schema')
    EXEC(N'CREATE SCHEMA teachers_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'finance_schema')
    EXEC(N'CREATE SCHEMA finance_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'library_schema')
    EXEC(N'CREATE SCHEMA library_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'transport_schema')
    EXEC(N'CREATE SCHEMA transport_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'alumni_schema')
    EXEC(N'CREATE SCHEMA alumni_schema AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sports_schema')
    EXEC(N'CREATE SCHEMA sports_schema AUTHORIZATION dbo;');
GO
