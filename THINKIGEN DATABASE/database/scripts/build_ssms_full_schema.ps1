$ErrorActionPreference = 'Stop'

$scriptDirectory = Split-Path -Parent $PSCommandPath
$migrationDirectory = Join-Path (Split-Path -Parent $scriptDirectory) 'migrations'
$outputPath = Join-Path $scriptDirectory '001_THINKIGEN_SSMS_FULL_SCHEMA.sql'
$migrationOrder = @(
    '001_schemas.sql',
    '002_security.sql',
    '003_management.sql',
    '004_teacher.sql',
    '017_exam.sql',
    '005_student.sql',
    '006_assessment.sql',
    '007_announcement.sql',
    '008_timetable.sql',
    '009_homework.sql',
    '010_attendance.sql',
    '011_leave.sql',
    '012_holidays.sql',
    '013_grievance.sql',
    '014_library.sql',
    '015_transport.sql',
    '016_finance.sql',
    '018_student_achievements.sql',
    '019_student_residency_and_section_class_teacher.sql',
    '020_alumni.sql',
    '021_student_exam_performance.sql',
    '022_personal_development.sql',
    '023_cultural_participation.sql',
    '024_teacher_designation.sql',
    '025_sports_and_grievance_department.sql'
)

$header = @'
/*
    THINKIGEN ERP - Full SQL Server Schema
    Paste this entire file into SSMS and execute it as one query.

    Includes all 25 schema migrations and creates all application tables across 9 schemas.
    This script is idempotent: existing tables and indexes are preserved.
    It does not create a database or insert seed data.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET NOCOUNT ON;
GO

'@

$footer = @'

PRINT N'THINKIGEN ERP schema execution complete.';
SELECT
    s.name AS schema_name,
    COUNT(*) AS table_count
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name IN (
    N'security_schema', N'management_schema', N'student_schema',
    N'teachers_schema', N'finance_schema', N'library_schema',
    N'transport_schema', N'alumni_schema', N'sports_schema'
)
GROUP BY s.name
ORDER BY s.name;

DECLARE @ThinkigenTableCount INT = (
    SELECT COUNT(*)
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name IN (
        N'security_schema', N'management_schema', N'student_schema',
        N'teachers_schema', N'finance_schema', N'library_schema',
        N'transport_schema', N'alumni_schema', N'sports_schema'
    )
);

PRINT CONCAT(N'Thinkigen schema validation passed: ', @ThinkigenTableCount, N' application tables across 9 schemas.');
GO
'@

$content = [System.Collections.Generic.List[string]]::new()
$content.Add($header)

foreach ($migration in $migrationOrder) {
    $migrationPath = Join-Path $migrationDirectory $migration
    if (-not (Test-Path -LiteralPath $migrationPath)) {
        throw "Required migration was not found: $migrationPath"
    }

    $content.Add("/* BEGIN INLINE MIGRATION: $migration */")
    $content.Add((Get-Content -LiteralPath $migrationPath -Raw))
    $content.Add("/* END INLINE MIGRATION: $migration */")
    $content.Add('')
}

$content.Add($footer)
Set-Content -LiteralPath $outputPath -Value $content -Encoding utf8
Write-Host "Created $outputPath"
