/* ============================================================================
   THINKIGEN ERP — Complete SQL Database Initialization
   Generated: 2026-08-29
   Database: SQL Server / Azure SQL
   
   Total Tables: 48
   Total Schemas: 7
   Migrations: 001–018
   
   Usage: 
   - Run in SQL Server Management Studio (SSMS) or Azure SQL
   - Execute this master script to initialize all tables
   - Or run individual migrations in sequence if preferred
   
   ============================================================================ */

PRINT N'=================================================================';
PRINT N'THINKIGEN ERP — COMPLETE DATABASE INITIALIZATION';
PRINT N'=================================================================';
PRINT N'';
PRINT N'Database: ' + DB_NAME();
PRINT N'Server: ' + @@SERVERNAME;
PRINT N'Timestamp: ' + CONVERT(NVARCHAR(20), GETUTCDATE(), 120) + ' UTC';
PRINT N'';

-- Include all migrations in sequence:
-- Comment: This script assumes all migration files are available
-- Alternative: Run :r "migrations/001_schemas.sql" etc. in SSMS

PRINT N'Step 1/18: Creating schemas...';
:r "migrations/001_schemas.sql"
PRINT N'✓ Schemas created';
PRINT N'';

PRINT N'Step 2/18: Configuring security...';
:r "migrations/002_security.sql"
PRINT N'✓ Security tables created';
PRINT N'';

PRINT N'Step 3/18: Setting up management...';
:r "migrations/003_management.sql"
PRINT N'✓ Management tables created';
PRINT N'';

PRINT N'Step 4/18: Configuring teachers...';
:r "migrations/004_teacher.sql"
PRINT N'✓ Teacher tables created';
PRINT N'';

PRINT N'Step 5/18: Setting up students...';
:r "migrations/005_student.sql"
PRINT N'✓ Student tables created';
PRINT N'';

PRINT N'Step 6/18: Configuring assignments...';
:r "migrations/006_assignment.sql"
PRINT N'✓ Assignment tables created';
PRINT N'';

PRINT N'Step 7/18: Setting up announcements...';
:r "migrations/007_announcement.sql"
PRINT N'✓ Announcement tables created';
PRINT N'';

PRINT N'Step 8/18: Configuring timetable...';
:r "migrations/008_timetable.sql"
PRINT N'✓ Timetable tables created';
PRINT N'';

PRINT N'Step 9/18: Setting up homework...';
:r "migrations/009_homework.sql"
PRINT N'✓ Homework tables created';
PRINT N'';

PRINT N'Step 10/18: Configuring attendance...';
:r "migrations/010_attendance.sql"
PRINT N'✓ Attendance tables created';
PRINT N'';

PRINT N'Step 11/18: Setting up leave...';
:r "migrations/011_leave.sql"
PRINT N'✓ Leave tables created';
PRINT N'';

PRINT N'Step 12/18: Configuring holidays...';
:r "migrations/012_holidays.sql"
PRINT N'✓ Holiday tables created';
PRINT N'';

PRINT N'Step 13/18: Setting up grievance...';
:r "migrations/013_grievance.sql"
PRINT N'✓ Grievance tables created';
PRINT N'';

PRINT N'Step 14/18: Configuring library...';
:r "migrations/014_library.sql"
PRINT N'✓ Library tables created';
PRINT N'  - Added: subject, category, language columns';
PRINT N'  - Index: (school_id, branch_id, subject, category, language, is_active)';
PRINT N'';

PRINT N'Step 15/18: Setting up transport...';
:r "migrations/015_transport.sql"
PRINT N'✓ Transport tables created';
PRINT N'';

PRINT N'Step 16/18: Configuring finance...';
:r "migrations/016_finance.sql"
PRINT N'✓ Finance tables created';
PRINT N'';

PRINT N'Step 17/18: Setting up exams...';
:r "migrations/017_exam.sql"
PRINT N'✓ Exam tables created';
PRINT N'';

PRINT N'Step 18/18: Configuring achievements...';
:r "migrations/018_student_achievements.sql"
PRINT N'✓ Achievement tables created';
PRINT N'  - New Table: student_schema.student_achievement';
PRINT N'  - Fields: title, category, place, level, date_issued, certificate_url';
PRINT N'';

-- Verification Report
PRINT N'=================================================================';
PRINT N'DATABASE INITIALIZATION COMPLETE';
PRINT N'=================================================================';
PRINT N'';

-- Table Summary
DECLARE @SchemaTableCount TABLE (SchemaName NVARCHAR(128), TableCount INT);

INSERT INTO @SchemaTableCount
SELECT 
    TABLE_SCHEMA,
    COUNT(*) as TableCount
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
GROUP BY TABLE_SCHEMA
ORDER BY TABLE_SCHEMA;

PRINT N'Schema Summary:';
PRINT N'───────────────────────────────────────';

SELECT @Msg = COALESCE(@Msg + CHAR(13) + CHAR(10), '')
         + SchemaName + REPLICATE(' ', 30 - LEN(SchemaName)) 
         + CAST(TableCount AS NVARCHAR(3)) + ' tables'
FROM @SchemaTableCount;

PRINT @Msg;

DECLARE @TotalTables INT = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_TYPE = 'BASE TABLE'
);

PRINT N'';
PRINT N'Total Tables: ' + CAST(@TotalTables AS NVARCHAR(3));
PRINT N'Total Indexes: ' + CAST(
    (SELECT COUNT(*) FROM sys.indexes WHERE type > 0), NVARCHAR(5)
);

PRINT N'';
PRINT N'Expected:';
PRINT N'  • finance_schema: 6 tables';
PRINT N'  • library_schema: 5 tables';
PRINT N'  • management_schema: 13 tables';
PRINT N'  • security_schema: 3 tables';
PRINT N'  • student_schema: 11 tables (includes student_achievement)';
PRINT N'  • teachers_schema: 4 tables';
PRINT N'  • transport_schema: 6 tables';
PRINT N'  ─────────────────────────';
PRINT N'  TOTAL: 48 tables';
PRINT N'';
PRINT N'=================================================================';
PRINT N'Next Steps:';
PRINT N'  1. Create seed data (see: migrations/rollback/)';
PRINT N'  2. Configure FastAPI connection string';
PRINT N'  3. Sync MongoDB collections (mongo/000_THINKIGEN_COMPASS_INIT.js)';
PRINT N'  4. Run integration tests (tests/)';
PRINT N'=================================================================';
