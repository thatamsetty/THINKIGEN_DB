/*
================================================================================
THINKIGEN ERP - REALISTIC MOCK / TEST DATA SEED - V23 (STANDARDIZED)
Target: SQL Server / SSMS
Academic Year: 2026-2027
Generated: Authentic Single School, 2 Branches, Classes 1-10, Sections A & B,
           10 Students Per Section (400 Active Students), Management Staff,
           Teachers, and 10th Class Passed-Out Alumni Students.

MOCK USER EMAIL STANDARDS ENFORCED:
- Student:     stu_XXXX@schoolname.edu   (e.g., stu_1201@schoolname.edu)
- Teacher:     tch_XXXX@schoolname.edu   (e.g., tch_1201@schoolname.edu)
- Management:  mgt_XXXX@schoolname.edu   (e.g., mgt_1201@schoolname.edu)

ACADEMIC & TENANT STRUCTURE:
- 1 School: Thinkigen International School (school_id = 1)
- 2 Branches: Central Campus (branch_id = 1), North Campus (branch_id = 2)
- 20 Classes: Classes 1 to 10 in Central (1..10), Classes 1 to 10 in North (11..20)
- 40 Sections: A and B for each class (20 sections in Central, 20 in North)
- 400 Active Students: Exactly 10 students per section (no duplicates)
- 20 Alumni Students: Class 10 passed out from past academic year (2025-2026, is_current = 0)
- 80 Teachers: 40 in Central Campus, 40 in North Campus (40 Class Teachers + 40 Co-Teachers)
- 21 Management Staff: Admin, Principal, Transport Staff, Finance Staff, Library Staff
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

/* Session hygiene: Turn IDENTITY_INSERT OFF for all seed tables before starting */
BEGIN TRY SET IDENTITY_INSERT security_schema.users OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT security_schema.schema_version OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.school OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.branch OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.academic_year OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.school_class OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.section OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.subject OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.class_subject OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT teachers_schema.teacher OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT teachers_schema.teacher_subject_assignment OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT teachers_schema.section_class_teacher_assignment OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student_guardian OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.exam OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.exam_schedule OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.exam_result OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT teachers_schema.assessment OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.assessment_result OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT teachers_schema.homework OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.homework_status OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.announcement OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.timetable OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.timetable_period OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student_attendance OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student_leave OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.holiday OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.grievance OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.grievance_history OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT library_schema.library_book OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT library_schema.library_book_copy OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT library_schema.library_book_borrow OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT transport_schema.vehicle OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT transport_schema.staff OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT transport_schema.vehicle_route OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT transport_schema.vehicle_route_stop OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT transport_schema.trip OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT transport_schema.trip_stop OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT transport_schema.speed_measurement OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.transport_assignment OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.transport_change_request OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT finance_schema.fee_structure_term OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT finance_schema.student_fee_record OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT finance_schema.fee_payment_transaction OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student_achievement OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT alumni_schema.alumni_profile OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT alumni_schema.alumni_story OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.grievance_department OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student_exam_performance OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student_personality_development OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student_personality_development_review OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student_cultural_participation OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT sports_schema.student_sport_history OFF; END TRY BEGIN CATCH END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;

    /* ============================================================
       0. RESET EXISTING APPLICATION DATA
       ============================================================ */
    DECLARE @sql NVARCHAR(MAX)=N'';

    /* Tables outside the seed schemas can still reference students, users, and teachers.
       NOCHECK on the seed tables does not disable those foreign keys.
       Example: sports_schema.student_sport_history.student_id -> student_schema.student. */
    IF OBJECT_ID(N'tempdb..#seed_reset_tables') IS NOT NULL DROP TABLE #seed_reset_tables;
    CREATE TABLE #seed_reset_tables
    (
        object_id   INT NOT NULL PRIMARY KEY,
        is_seed     BIT NOT NULL
    );

    INSERT INTO #seed_reset_tables (object_id, is_seed)
    SELECT t.object_id, 1
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name IN (N'security_schema',N'management_schema',N'student_schema',N'teachers_schema',N'finance_schema',N'library_schema',N'transport_schema',N'alumni_schema',N'sports_schema');

    DECLARE @added INT = 1;
    WHILE @added > 0
    BEGIN
        INSERT INTO #seed_reset_tables (object_id, is_seed)
        SELECT DISTINCT fk.parent_object_id, 0
        FROM sys.foreign_keys fk
        JOIN #seed_reset_tables r ON r.object_id = fk.referenced_object_id
        WHERE NOT EXISTS (
            SELECT 1 FROM #seed_reset_tables x WHERE x.object_id = fk.parent_object_id
        );
        SET @added = @@ROWCOUNT;
    END;

    SELECT @sql=@sql + N'ALTER TABLE '+QUOTENAME(SCHEMA_NAME(t.schema_id))+N'.'+QUOTENAME(t.name)+N' NOCHECK CONSTRAINT ALL;'+CHAR(13)+CHAR(10)
    FROM #seed_reset_tables r
    JOIN sys.tables t ON t.object_id = r.object_id;
    EXEC sys.sp_executesql @sql;

    /* Delete outside children first (sport history and any similar tables), then the seed tables. */
    SET @sql=N'';
    SELECT @sql=@sql + N'DELETE FROM '+QUOTENAME(SCHEMA_NAME(t.schema_id))+N'.'+QUOTENAME(t.name)+N';'+CHAR(13)+CHAR(10)
    FROM #seed_reset_tables r
    JOIN sys.tables t ON t.object_id = r.object_id
    WHERE r.is_seed = 0;
    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    SET @sql=N'';
    SELECT @sql=@sql + N'DELETE FROM '+QUOTENAME(SCHEMA_NAME(t.schema_id))+N'.'+QUOTENAME(t.name)+N';'+CHAR(13)+CHAR(10)
    FROM #seed_reset_tables r
    JOIN sys.tables t ON t.object_id = r.object_id
    WHERE r.is_seed = 1;
    EXEC sys.sp_executesql @sql;

    SET @sql=N'';
    SELECT @sql=@sql + N'ALTER TABLE '+QUOTENAME(SCHEMA_NAME(t.schema_id))+N'.'+QUOTENAME(t.name)+N' WITH CHECK CHECK CONSTRAINT ALL;'+CHAR(13)+CHAR(10)
    FROM #seed_reset_tables r
    JOIN sys.tables t ON t.object_id = r.object_id;
    EXEC sys.sp_executesql @sql;

    DROP TABLE #seed_reset_tables;

    /* Reset every identity column dynamically */
    SET @sql=N'';
    SELECT @sql=@sql + N'DBCC CHECKIDENT (' + QUOTENAME(s.name+N'.'+t.name, '''') + N', RESEED, 0) WITH NO_INFOMSGS;'+CHAR(13)+CHAR(10)
    FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.identity_columns ic ON ic.object_id=t.object_id
    WHERE s.name IN (N'security_schema',N'management_schema',N'student_schema',N'teachers_schema',N'finance_schema',N'library_schema',N'transport_schema',N'alumni_schema');
    EXEC sys.sp_executesql @sql;

    /* ============================================================
       1. SECURITY - USERS
       ============================================================ */
    SET IDENTITY_INSERT security_schema.users ON;

    -- 1.1 Management & Administrative Users (mgt_1201@schoolname.edu ...)
    INSERT INTO security_schema.users
        (user_id,email_address,user_type,is_active,password_hash,password_plain_dev,password_set_at,failed_login_count,locked_until,last_login_at)
    VALUES
        (1,N'mgt_1201@schoolname.edu',N'ADMIN',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (2,N'mgt_1202@schoolname.edu',N'ADMIN',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (3,N'mgt_1203@schoolname.edu',N'PRINCIPAL',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (4,N'mgt_1204@schoolname.edu',N'PRINCIPAL',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (5,N'mgt_1205@schoolname.edu',N'VICE_PRINCIPAL',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (6,N'mgt_1206@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (7,N'mgt_1207@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (8,N'mgt_1208@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (9,N'mgt_1209@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (10,N'mgt_1210@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (11,N'mgt_1211@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (12,N'mgt_1212@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (13,N'mgt_1213@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (14,N'mgt_1214@schoolname.edu',N'TRANSPORT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (15,N'mgt_1215@schoolname.edu',N'FINANCE',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (16,N'mgt_1216@schoolname.edu',N'FINANCE',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (17,N'mgt_1217@schoolname.edu',N'FINANCE',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (18,N'mgt_1218@schoolname.edu',N'LIBRARIAN',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (19,N'mgt_1219@schoolname.edu',N'LIBRARIAN',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (20,N'mgt_1220@schoolname.edu',N'LIBRARIAN',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (21,N'mgt_1221@schoolname.edu',N'LIBRARIAN',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL);

    -- 1.2 Teachers (tch_1201@schoolname.edu to tch_1280@schoolname.edu)
    INSERT INTO security_schema.users
        (user_id,email_address,user_type,is_active,password_hash,password_plain_dev,password_set_at,failed_login_count,locked_until,last_login_at)
    VALUES
        (101,N'tch_1201@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (102,N'tch_1202@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (103,N'tch_1203@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (104,N'tch_1204@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (105,N'tch_1205@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (106,N'tch_1206@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (107,N'tch_1207@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (108,N'tch_1208@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (109,N'tch_1209@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (110,N'tch_1210@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (111,N'tch_1211@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (112,N'tch_1212@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (113,N'tch_1213@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (114,N'tch_1214@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (115,N'tch_1215@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (116,N'tch_1216@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (117,N'tch_1217@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (118,N'tch_1218@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (119,N'tch_1219@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (120,N'tch_1220@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (121,N'tch_1221@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (122,N'tch_1222@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (123,N'tch_1223@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (124,N'tch_1224@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (125,N'tch_1225@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (126,N'tch_1226@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (127,N'tch_1227@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (128,N'tch_1228@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (129,N'tch_1229@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (130,N'tch_1230@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (131,N'tch_1231@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (132,N'tch_1232@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (133,N'tch_1233@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (134,N'tch_1234@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (135,N'tch_1235@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (136,N'tch_1236@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (137,N'tch_1237@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (138,N'tch_1238@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (139,N'tch_1239@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (140,N'tch_1240@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (141,N'tch_1241@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (142,N'tch_1242@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (143,N'tch_1243@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (144,N'tch_1244@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (145,N'tch_1245@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (146,N'tch_1246@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (147,N'tch_1247@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (148,N'tch_1248@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (149,N'tch_1249@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (150,N'tch_1250@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (151,N'tch_1251@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (152,N'tch_1252@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (153,N'tch_1253@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (154,N'tch_1254@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (155,N'tch_1255@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (156,N'tch_1256@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (157,N'tch_1257@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (158,N'tch_1258@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (159,N'tch_1259@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (160,N'tch_1260@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (161,N'tch_1261@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (162,N'tch_1262@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (163,N'tch_1263@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (164,N'tch_1264@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (165,N'tch_1265@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (166,N'tch_1266@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (167,N'tch_1267@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (168,N'tch_1268@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (169,N'tch_1269@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (170,N'tch_1270@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (171,N'tch_1271@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (172,N'tch_1272@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (173,N'tch_1273@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (174,N'tch_1274@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (175,N'tch_1275@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (176,N'tch_1276@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (177,N'tch_1277@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (178,N'tch_1278@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (179,N'tch_1279@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (180,N'tch_1280@schoolname.edu',N'TEACHER',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL);

    -- 1.3 Active Students (stu_1201@schoolname.edu to stu_1600@schoolname.edu)
    INSERT INTO security_schema.users
        (user_id,email_address,user_type,is_active,password_hash,password_plain_dev,password_set_at,failed_login_count,locked_until,last_login_at)
    VALUES
        (201,N'stu_1201@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (202,N'stu_1202@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (203,N'stu_1203@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (204,N'stu_1204@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (205,N'stu_1205@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (206,N'stu_1206@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (207,N'stu_1207@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (208,N'stu_1208@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (209,N'stu_1209@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (210,N'stu_1210@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (211,N'stu_1211@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (212,N'stu_1212@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (213,N'stu_1213@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (214,N'stu_1214@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (215,N'stu_1215@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (216,N'stu_1216@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (217,N'stu_1217@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (218,N'stu_1218@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (219,N'stu_1219@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (220,N'stu_1220@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (221,N'stu_1221@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (222,N'stu_1222@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (223,N'stu_1223@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (224,N'stu_1224@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (225,N'stu_1225@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (226,N'stu_1226@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (227,N'stu_1227@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (228,N'stu_1228@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (229,N'stu_1229@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (230,N'stu_1230@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (231,N'stu_1231@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (232,N'stu_1232@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (233,N'stu_1233@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (234,N'stu_1234@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (235,N'stu_1235@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (236,N'stu_1236@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (237,N'stu_1237@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (238,N'stu_1238@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (239,N'stu_1239@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (240,N'stu_1240@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (241,N'stu_1241@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (242,N'stu_1242@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (243,N'stu_1243@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (244,N'stu_1244@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (245,N'stu_1245@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (246,N'stu_1246@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (247,N'stu_1247@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (248,N'stu_1248@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (249,N'stu_1249@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (250,N'stu_1250@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (251,N'stu_1251@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (252,N'stu_1252@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (253,N'stu_1253@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (254,N'stu_1254@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (255,N'stu_1255@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (256,N'stu_1256@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (257,N'stu_1257@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (258,N'stu_1258@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (259,N'stu_1259@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (260,N'stu_1260@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (261,N'stu_1261@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (262,N'stu_1262@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (263,N'stu_1263@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (264,N'stu_1264@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (265,N'stu_1265@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (266,N'stu_1266@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (267,N'stu_1267@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (268,N'stu_1268@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (269,N'stu_1269@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (270,N'stu_1270@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (271,N'stu_1271@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (272,N'stu_1272@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (273,N'stu_1273@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (274,N'stu_1274@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (275,N'stu_1275@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (276,N'stu_1276@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (277,N'stu_1277@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (278,N'stu_1278@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (279,N'stu_1279@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (280,N'stu_1280@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (281,N'stu_1281@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (282,N'stu_1282@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (283,N'stu_1283@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (284,N'stu_1284@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (285,N'stu_1285@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (286,N'stu_1286@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (287,N'stu_1287@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (288,N'stu_1288@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (289,N'stu_1289@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (290,N'stu_1290@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (291,N'stu_1291@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (292,N'stu_1292@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (293,N'stu_1293@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (294,N'stu_1294@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (295,N'stu_1295@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (296,N'stu_1296@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (297,N'stu_1297@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (298,N'stu_1298@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (299,N'stu_1299@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (300,N'stu_1300@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (301,N'stu_1301@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (302,N'stu_1302@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (303,N'stu_1303@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (304,N'stu_1304@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (305,N'stu_1305@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (306,N'stu_1306@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (307,N'stu_1307@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (308,N'stu_1308@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (309,N'stu_1309@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (310,N'stu_1310@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (311,N'stu_1311@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (312,N'stu_1312@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (313,N'stu_1313@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (314,N'stu_1314@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (315,N'stu_1315@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (316,N'stu_1316@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (317,N'stu_1317@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (318,N'stu_1318@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (319,N'stu_1319@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (320,N'stu_1320@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (321,N'stu_1321@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (322,N'stu_1322@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (323,N'stu_1323@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (324,N'stu_1324@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (325,N'stu_1325@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (326,N'stu_1326@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (327,N'stu_1327@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (328,N'stu_1328@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (329,N'stu_1329@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (330,N'stu_1330@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (331,N'stu_1331@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (332,N'stu_1332@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (333,N'stu_1333@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (334,N'stu_1334@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (335,N'stu_1335@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (336,N'stu_1336@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (337,N'stu_1337@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (338,N'stu_1338@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (339,N'stu_1339@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (340,N'stu_1340@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (341,N'stu_1341@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (342,N'stu_1342@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (343,N'stu_1343@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (344,N'stu_1344@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (345,N'stu_1345@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (346,N'stu_1346@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (347,N'stu_1347@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (348,N'stu_1348@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (349,N'stu_1349@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (350,N'stu_1350@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (351,N'stu_1351@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (352,N'stu_1352@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (353,N'stu_1353@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (354,N'stu_1354@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (355,N'stu_1355@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (356,N'stu_1356@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (357,N'stu_1357@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (358,N'stu_1358@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (359,N'stu_1359@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (360,N'stu_1360@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (361,N'stu_1361@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (362,N'stu_1362@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (363,N'stu_1363@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (364,N'stu_1364@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (365,N'stu_1365@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (366,N'stu_1366@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (367,N'stu_1367@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (368,N'stu_1368@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (369,N'stu_1369@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (370,N'stu_1370@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (371,N'stu_1371@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (372,N'stu_1372@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (373,N'stu_1373@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (374,N'stu_1374@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (375,N'stu_1375@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (376,N'stu_1376@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (377,N'stu_1377@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (378,N'stu_1378@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (379,N'stu_1379@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (380,N'stu_1380@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (381,N'stu_1381@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (382,N'stu_1382@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (383,N'stu_1383@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (384,N'stu_1384@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (385,N'stu_1385@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (386,N'stu_1386@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (387,N'stu_1387@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (388,N'stu_1388@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (389,N'stu_1389@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (390,N'stu_1390@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (391,N'stu_1391@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (392,N'stu_1392@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (393,N'stu_1393@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (394,N'stu_1394@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (395,N'stu_1395@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (396,N'stu_1396@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (397,N'stu_1397@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (398,N'stu_1398@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (399,N'stu_1399@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (400,N'stu_1400@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (401,N'stu_1401@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (402,N'stu_1402@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (403,N'stu_1403@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (404,N'stu_1404@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (405,N'stu_1405@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (406,N'stu_1406@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (407,N'stu_1407@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (408,N'stu_1408@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (409,N'stu_1409@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (410,N'stu_1410@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (411,N'stu_1411@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (412,N'stu_1412@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (413,N'stu_1413@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (414,N'stu_1414@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (415,N'stu_1415@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (416,N'stu_1416@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (417,N'stu_1417@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (418,N'stu_1418@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (419,N'stu_1419@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (420,N'stu_1420@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (421,N'stu_1421@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (422,N'stu_1422@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (423,N'stu_1423@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (424,N'stu_1424@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (425,N'stu_1425@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (426,N'stu_1426@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (427,N'stu_1427@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (428,N'stu_1428@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (429,N'stu_1429@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (430,N'stu_1430@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (431,N'stu_1431@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (432,N'stu_1432@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (433,N'stu_1433@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (434,N'stu_1434@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (435,N'stu_1435@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (436,N'stu_1436@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (437,N'stu_1437@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (438,N'stu_1438@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (439,N'stu_1439@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (440,N'stu_1440@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (441,N'stu_1441@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (442,N'stu_1442@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (443,N'stu_1443@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (444,N'stu_1444@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (445,N'stu_1445@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (446,N'stu_1446@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (447,N'stu_1447@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (448,N'stu_1448@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (449,N'stu_1449@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (450,N'stu_1450@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (451,N'stu_1451@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (452,N'stu_1452@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (453,N'stu_1453@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (454,N'stu_1454@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (455,N'stu_1455@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (456,N'stu_1456@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (457,N'stu_1457@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (458,N'stu_1458@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (459,N'stu_1459@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (460,N'stu_1460@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (461,N'stu_1461@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (462,N'stu_1462@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (463,N'stu_1463@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (464,N'stu_1464@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (465,N'stu_1465@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (466,N'stu_1466@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (467,N'stu_1467@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (468,N'stu_1468@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (469,N'stu_1469@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (470,N'stu_1470@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (471,N'stu_1471@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (472,N'stu_1472@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (473,N'stu_1473@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (474,N'stu_1474@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (475,N'stu_1475@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (476,N'stu_1476@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (477,N'stu_1477@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (478,N'stu_1478@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (479,N'stu_1479@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (480,N'stu_1480@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (481,N'stu_1481@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (482,N'stu_1482@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (483,N'stu_1483@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (484,N'stu_1484@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (485,N'stu_1485@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (486,N'stu_1486@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (487,N'stu_1487@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (488,N'stu_1488@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (489,N'stu_1489@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (490,N'stu_1490@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (491,N'stu_1491@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (492,N'stu_1492@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (493,N'stu_1493@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (494,N'stu_1494@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (495,N'stu_1495@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (496,N'stu_1496@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (497,N'stu_1497@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (498,N'stu_1498@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (499,N'stu_1499@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (500,N'stu_1500@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (501,N'stu_1501@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (502,N'stu_1502@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (503,N'stu_1503@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (504,N'stu_1504@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (505,N'stu_1505@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (506,N'stu_1506@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (507,N'stu_1507@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (508,N'stu_1508@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (509,N'stu_1509@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (510,N'stu_1510@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (511,N'stu_1511@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (512,N'stu_1512@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (513,N'stu_1513@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (514,N'stu_1514@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (515,N'stu_1515@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (516,N'stu_1516@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (517,N'stu_1517@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (518,N'stu_1518@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (519,N'stu_1519@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (520,N'stu_1520@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (521,N'stu_1521@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (522,N'stu_1522@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (523,N'stu_1523@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (524,N'stu_1524@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (525,N'stu_1525@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (526,N'stu_1526@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (527,N'stu_1527@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (528,N'stu_1528@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (529,N'stu_1529@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (530,N'stu_1530@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (531,N'stu_1531@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (532,N'stu_1532@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (533,N'stu_1533@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (534,N'stu_1534@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (535,N'stu_1535@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (536,N'stu_1536@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (537,N'stu_1537@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (538,N'stu_1538@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (539,N'stu_1539@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (540,N'stu_1540@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (541,N'stu_1541@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (542,N'stu_1542@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (543,N'stu_1543@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (544,N'stu_1544@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (545,N'stu_1545@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (546,N'stu_1546@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (547,N'stu_1547@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (548,N'stu_1548@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (549,N'stu_1549@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (550,N'stu_1550@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (551,N'stu_1551@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (552,N'stu_1552@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (553,N'stu_1553@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (554,N'stu_1554@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (555,N'stu_1555@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (556,N'stu_1556@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (557,N'stu_1557@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (558,N'stu_1558@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (559,N'stu_1559@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (560,N'stu_1560@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (561,N'stu_1561@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (562,N'stu_1562@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (563,N'stu_1563@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (564,N'stu_1564@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (565,N'stu_1565@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (566,N'stu_1566@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (567,N'stu_1567@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (568,N'stu_1568@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (569,N'stu_1569@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (570,N'stu_1570@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (571,N'stu_1571@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (572,N'stu_1572@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (573,N'stu_1573@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (574,N'stu_1574@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (575,N'stu_1575@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (576,N'stu_1576@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (577,N'stu_1577@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (578,N'stu_1578@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (579,N'stu_1579@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (580,N'stu_1580@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (581,N'stu_1581@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (582,N'stu_1582@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (583,N'stu_1583@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (584,N'stu_1584@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (585,N'stu_1585@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (586,N'stu_1586@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (587,N'stu_1587@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (588,N'stu_1588@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (589,N'stu_1589@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (590,N'stu_1590@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (591,N'stu_1591@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (592,N'stu_1592@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (593,N'stu_1593@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (594,N'stu_1594@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (595,N'stu_1595@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (596,N'stu_1596@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (597,N'stu_1597@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (598,N'stu_1598@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (599,N'stu_1599@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL),
        (600,N'stu_1600@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2026-04-01T08:00:00',0,NULL,NULL);

    -- 1.4 Alumni Students - Class 10 Passed-out Graduates (stu_1601@schoolname.edu to stu_1620@schoolname.edu)
    INSERT INTO security_schema.users
        (user_id,email_address,user_type,is_active,password_hash,password_plain_dev,password_set_at,failed_login_count,locked_until,last_login_at)
    VALUES
        (601,N'stu_1601@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (602,N'stu_1602@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (603,N'stu_1603@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (604,N'stu_1604@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (605,N'stu_1605@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (606,N'stu_1606@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (607,N'stu_1607@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (608,N'stu_1608@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (609,N'stu_1609@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (610,N'stu_1610@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (611,N'stu_1611@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (612,N'stu_1612@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (613,N'stu_1613@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (614,N'stu_1614@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (615,N'stu_1615@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (616,N'stu_1616@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (617,N'stu_1617@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (618,N'stu_1618@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (619,N'stu_1619@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL),
        (620,N'stu_1620@schoolname.edu',N'STUDENT',1,NULL,N'Test@12345','2025-04-01T08:00:00',0,NULL,NULL);

    SET IDENTITY_INSERT security_schema.users OFF;

    INSERT INTO security_schema.user_login_attempt
        (user_id,is_success,failure_reason,ip_address,user_agent,attempted_at)
    VALUES
        (1,1,NULL,N'10.10.1.10',N'Thinkigen-Web/Management','2026-08-31T08:00:00'),
        (3,1,NULL,N'10.10.1.20',N'Thinkigen-Web/Management','2026-08-31T08:01:00'),
        (101,1,NULL,N'10.10.1.25',N'Thinkigen-Web/Teacher','2026-08-31T08:02:00'),
        (201,1,NULL,N'10.10.2.10',N'Thinkigen-Mobile/Student','2026-08-31T08:03:00'),
        (202,0,N'BAD_PASSWORD',N'10.10.2.11',N'Thinkigen-Mobile/Student','2026-08-31T08:04:00'),
        (7,1,NULL,N'10.10.3.10',N'Thinkigen-Transport/Mock','2026-08-31T08:05:00');

    SET IDENTITY_INSERT security_schema.schema_version ON;
    INSERT INTO security_schema.schema_version(schema_version_id,migration_name,applied_at)
    VALUES
      (1,N'001_schemas.sql','2026-03-20T08:00:00'),
      (2,N'002_security.sql','2026-03-20T08:01:00'),
      (3,N'003_management.sql','2026-03-20T08:02:00'),
      (4,N'004_teacher.sql','2026-03-20T08:03:00'),
      (5,N'017_exam.sql','2026-03-20T08:04:00'),
      (6,N'005_student.sql','2026-03-20T08:05:00'),
      (7,N'006_assignment.sql','2026-03-20T08:06:00'),
      (8,N'007_announcement.sql','2026-03-20T08:07:00'),
      (9,N'008_timetable.sql','2026-03-20T08:08:00'),
      (10,N'009_homework.sql','2026-03-20T08:09:00'),
      (11,N'010_attendance.sql','2026-03-20T08:10:00'),
      (12,N'011_leave.sql','2026-03-20T08:11:00'),
      (13,N'012_holidays.sql','2026-03-20T08:12:00'),
      (14,N'013_grievance.sql','2026-03-20T08:13:00'),
      (15,N'014_library.sql','2026-03-20T08:14:00'),
      (16,N'015_transport.sql','2026-03-20T08:15:00'),
      (17,N'016_finance.sql','2026-03-20T08:16:00'),
      (18,N'018_student_achievements.sql','2026-03-20T08:17:00'),
      (19,N'019_student_residency_and_section_class_teacher.sql','2026-03-20T08:18:00'),
      (20,N'020_alumni.sql','2026-03-20T08:19:00'),
      (21,N'021_student_exam_performance.sql','2026-03-20T08:20:00'),
      (22,N'022_personal_development.sql','2026-03-20T08:21:00'),
      (23,N'023_cultural_participation.sql','2026-03-20T08:22:00'),
      (24,N'024_teacher_designation.sql','2026-03-20T08:23:00');
    SET IDENTITY_INSERT security_schema.schema_version OFF;

    /* ============================================================
       2. MANAGEMENT FOUNDATION: 1 SCHOOL, 2 BRANCHES, ACADEMIC YEARS
       ============================================================ */
    SET IDENTITY_INSERT management_schema.school ON;
    INSERT INTO management_schema.school(school_id,school_code,school_name,is_active,created_by)
    VALUES
      (1,N'TG-SCH-001',N'Thinkigen International School',1,1);
    SET IDENTITY_INSERT management_schema.school OFF;

    SET IDENTITY_INSERT management_schema.branch ON;
    INSERT INTO management_schema.branch(branch_id,school_id,branch_code,branch_name,is_active,created_by)
    VALUES
      (1,1,N'BR-01',N'Central Campus',1,1),
      (2,1,N'BR-02',N'North Campus',1,1);
    SET IDENTITY_INSERT management_schema.branch OFF;

    SET IDENTITY_INSERT management_schema.academic_year ON;
    INSERT INTO management_schema.academic_year
        (academic_year_id,school_id,year_name,start_date,end_date,is_current,is_active,created_by)
    VALUES
      (1,1,N'2026-2027','2026-04-01','2027-03-31',1,1,1),
      (101,1,N'2025-2026','2025-04-01','2026-03-31',0,1,1),
      (102,1,N'2024-2025','2024-04-01','2025-03-31',0,1,1);
    SET IDENTITY_INSERT management_schema.academic_year OFF;

    /* 20 Classes: Classes 1 to 10 in Central Campus, Classes 1 to 10 in North Campus */
    SET IDENTITY_INSERT management_schema.school_class ON;
    INSERT INTO management_schema.school_class
        (class_id,school_id,class_name,display_order,is_active,created_by)
    VALUES
      (1,1,N'Class 1 - Central',1,1,1),
      (2,1,N'Class 2 - Central',2,1,1),
      (3,1,N'Class 3 - Central',3,1,1),
      (4,1,N'Class 4 - Central',4,1,1),
      (5,1,N'Class 5 - Central',5,1,1),
      (6,1,N'Class 6 - Central',6,1,1),
      (7,1,N'Class 7 - Central',7,1,1),
      (8,1,N'Class 8 - Central',8,1,1),
      (9,1,N'Class 9 - Central',9,1,1),
      (10,1,N'Class 10 - Central',10,1,1),
      (11,1,N'Class 1 - North',1,1,1),
      (12,1,N'Class 2 - North',2,1,1),
      (13,1,N'Class 3 - North',3,1,1),
      (14,1,N'Class 4 - North',4,1,1),
      (15,1,N'Class 5 - North',5,1,1),
      (16,1,N'Class 6 - North',6,1,1),
      (17,1,N'Class 7 - North',7,1,1),
      (18,1,N'Class 8 - North',8,1,1),
      (19,1,N'Class 9 - North',9,1,1),
      (20,1,N'Class 10 - North',10,1,1);

    SET IDENTITY_INSERT management_schema.school_class OFF;

    /* 40 Sections: Sections A and B for each of the 20 classes */
    SET IDENTITY_INSERT management_schema.section ON;
    INSERT INTO management_schema.section(section_id,class_id,section_name,is_active,created_by)
    VALUES
      (1,1,N'A',1,1),
      (2,1,N'B',1,1),
      (3,2,N'A',1,1),
      (4,2,N'B',1,1),
      (5,3,N'A',1,1),
      (6,3,N'B',1,1),
      (7,4,N'A',1,1),
      (8,4,N'B',1,1),
      (9,5,N'A',1,1),
      (10,5,N'B',1,1),
      (11,6,N'A',1,1),
      (12,6,N'B',1,1),
      (13,7,N'A',1,1),
      (14,7,N'B',1,1),
      (15,8,N'A',1,1),
      (16,8,N'B',1,1),
      (17,9,N'A',1,1),
      (18,9,N'B',1,1),
      (19,10,N'A',1,1),
      (20,10,N'B',1,1),
      (21,11,N'A',1,1),
      (22,11,N'B',1,1),
      (23,12,N'A',1,1),
      (24,12,N'B',1,1),
      (25,13,N'A',1,1),
      (26,13,N'B',1,1),
      (27,14,N'A',1,1),
      (28,14,N'B',1,1),
      (29,15,N'A',1,1),
      (30,15,N'B',1,1),
      (31,16,N'A',1,1),
      (32,16,N'B',1,1),
      (33,17,N'A',1,1),
      (34,17,N'B',1,1),
      (35,18,N'A',1,1),
      (36,18,N'B',1,1),
      (37,19,N'A',1,1),
      (38,19,N'B',1,1),
      (39,20,N'A',1,1),
      (40,20,N'B',1,1);

    SET IDENTITY_INSERT management_schema.section OFF;

    /* 6 Core Subjects */
    SET IDENTITY_INSERT management_schema.subject ON;
    INSERT INTO management_schema.subject
        (subject_id,school_id,subject_code,subject_name,is_active,created_by)
    VALUES
      (1,1,N'ENG',N'English',1,1),
      (2,1,N'MAT',N'Mathematics',1,1),
      (3,1,N'SCI',N'Science',1,1),
      (4,1,N'SST',N'Social Science',1,1),
      (5,1,N'CSC',N'Computer Science',1,1),
      (6,1,N'PE',N'Physical Education',1,1);
    SET IDENTITY_INSERT management_schema.subject OFF;

    /* Class-Subject Mappings: 20 classes x 6 subjects = 120 */
    SET IDENTITY_INSERT management_schema.class_subject ON;
    INSERT INTO management_schema.class_subject
        (class_subject_id,school_id,branch_id,academic_year_id,class_id,subject_id,is_active,created_by)
    SELECT
        ROW_NUMBER() OVER (ORDER BY c.class_id, s.subject_id),
        1,
        CASE WHEN c.class_id <= 10 THEN 1 ELSE 2 END,
        1,
        c.class_id,
        s.subject_id,
        1,
        1
    FROM management_schema.school_class c
    CROSS JOIN management_schema.subject s;
    SET IDENTITY_INSERT management_schema.class_subject OFF;

    /* ============================================================
       3. TEACHERS (80 Teachers: 40 in Central Campus, 40 in North Campus)
       Teacher Emails: tch_1201@schoolname.edu to tch_1280@schoolname.edu
       Section s (1..40) has Class Teacher: (s-1)*2 + 1, and Co-Teacher: (s-1)*2 + 2
       ============================================================ */
    SET IDENTITY_INSERT teachers_schema.teacher ON;
    INSERT INTO teachers_schema.teacher
        (teacher_id,user_id,school_id,branch_id,subject_id,designation,employee_code,first_name,last_name,
         mobile_number,email_address,status,is_active,created_by)
    VALUES
      -- Branch 1 (Central Campus: Teachers 1..40)
      -- Subject 1: English (Teachers 1..7)
      (1,101,1,1,1,N'English Department Head',N'TCHR001',N'Keshav',N'Kulkarni',N'9870110010',N'tch_1201@schoolname.edu',N'ACTIVE',1,1),
      (2,102,1,1,1,N'Senior English Faculty',N'TCHR002',N'Radhika',N'Pillai',N'9870210020',N'tch_1202@schoolname.edu',N'ACTIVE',1,1),
      (3,103,1,1,1,N'Senior English Faculty',N'TCHR003',N'Mayank',N'Mukherjee',N'9870310030',N'tch_1203@schoolname.edu',N'ACTIVE',1,1),
      (4,104,1,1,1,N'Senior English Faculty',N'TCHR004',N'Tara',N'Mishra',N'9870410040',N'tch_1204@schoolname.edu',N'ACTIVE',1,1),
      (5,105,1,1,1,N'Senior English Faculty',N'TCHR005',N'Om',N'Tiwari',N'9870510050',N'tch_1205@schoolname.edu',N'ACTIVE',1,1),
      (6,106,1,1,1,N'Senior English Faculty',N'TCHR006',N'Veda',N'Menon',N'9870610060',N'tch_1206@schoolname.edu',N'ACTIVE',1,1),
      (7,107,1,1,1,N'Senior English Faculty',N'TCHR007',N'Raghav',N'Shetty',N'9870710070',N'tch_1207@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 2: Mathematics (Teachers 8..14)
      (8,108,1,1,2,N'Mathematics Department Head',N'TCHR008',N'Zara',N'Pai',N'9870810080',N'tch_1208@schoolname.edu',N'ACTIVE',1,1),
      (9,109,1,1,2,N'Senior Mathematics Faculty',N'TCHR009',N'Utkarsh',N'Mishra',N'9870910090',N'tch_1209@schoolname.edu',N'ACTIVE',1,1),
      (10,110,1,1,2,N'Senior Mathematics Faculty',N'TCHR010',N'Barkha',N'Tiwari',N'9871010100',N'tch_1210@schoolname.edu',N'ACTIVE',1,1),
      (11,111,1,1,2,N'Senior Mathematics Faculty',N'TCHR011',N'Wahid',N'Dubey',N'9871110110',N'tch_1211@schoolname.edu',N'ACTIVE',1,1),
      (12,112,1,1,2,N'Senior Mathematics Faculty',N'TCHR012',N'Damini',N'Pathak',N'9871210120',N'tch_1212@schoolname.edu',N'ACTIVE',1,1),
      (13,113,1,1,2,N'Senior Mathematics Faculty',N'TCHR013',N'Zayan',N'Jha',N'9871310130',N'tch_1213@schoolname.edu',N'ACTIVE',1,1),
      (14,114,1,1,2,N'Senior Mathematics Faculty',N'TCHR014',N'Harini',N'Chauhan',N'9871410140',N'tch_1214@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 3: Science (Teachers 15..21)
      (15,115,1,1,3,N'Science Department Head',N'TCHR015',N'Bhuvan',N'Solanki',N'9871510150',N'tch_1215@schoolname.edu',N'ACTIVE',1,1),
      (16,116,1,1,3,N'Senior Science Teacher',N'TCHR016',N'Juhi',N'Rajput',N'9871610160',N'tch_1216@schoolname.edu',N'ACTIVE',1,1),
      (17,117,1,1,3,N'Senior Science Teacher',N'TCHR017',N'Devesh',N'Saini',N'9871710170',N'tch_1217@schoolname.edu',N'ACTIVE',1,1),
      (18,118,1,1,3,N'Senior Science Teacher',N'TCHR018',N'Leela',N'Malik',N'9871810180',N'tch_1218@schoolname.edu',N'ACTIVE',1,1),
      (19,119,1,1,3,N'Senior Science Teacher',N'TCHR019',N'Gautam',N'Dhillon',N'9871910190',N'tch_1219@schoolname.edu',N'ACTIVE',1,1),
      (20,120,1,1,3,N'Senior Science Teacher',N'TCHR020',N'Nidhi',N'Sidhu',N'9872010200',N'tch_1220@schoolname.edu',N'ACTIVE',1,1),
      (21,121,1,1,3,N'Senior Science Teacher',N'TCHR021',N'Indrajit',N'Bajwa',N'9872110210',N'tch_1221@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 4: Social Science (Teachers 22..28)
      (22,122,1,1,4,N'Social Science Department Head',N'TCHR022',N'Rashmi',N'Chopra',N'9872210220',N'tch_1222@schoolname.edu',N'ACTIVE',1,1),
      (23,123,1,1,4,N'Social Science Specialist',N'TCHR023',N'Kushagra',N'Kapoor',N'9872310230',N'tch_1223@schoolname.edu',N'ACTIVE',1,1),
      (24,124,1,1,4,N'Social Science Specialist',N'TCHR024',N'Tripti',N'Grover',N'9872410240',N'tch_1224@schoolname.edu',N'ACTIVE',1,1),
      (25,125,1,1,4,N'Social Science Specialist',N'TCHR025',N'Mohit',N'Tandon',N'9872510250',N'tch_1225@schoolname.edu',N'ACTIVE',1,1),
      (26,126,1,1,4,N'Social Science Specialist',N'TCHR026',N'Vandana',N'Kohli',N'9872610260',N'tch_1226@schoolname.edu',N'ACTIVE',1,1),
      (27,127,1,1,4,N'Social Science Specialist',N'TCHR027',N'Ojas',N'Bhatia',N'9872710270',N'tch_1227@schoolname.edu',N'ACTIVE',1,1),
      (28,128,1,1,4,N'Social Science Specialist',N'TCHR028',N'Aastha',N'Sachdeva',N'9872810280',N'tch_1228@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 5: Computer Science (Teachers 29..34)
      (29,129,1,1,5,N'Computer Science Department Head',N'TCHR029',N'Raghunath',N'Mathur',N'9872910290',N'tch_1229@schoolname.edu',N'ACTIVE',1,1),
      (30,130,1,1,5,N'Computer Science Instructor',N'TCHR030',N'Chitra',N'Nigam',N'9873010300',N'tch_1230@schoolname.edu',N'ACTIVE',1,1),
      (31,131,1,1,5,N'Computer Science Instructor',N'TCHR031',N'Tarun',N'Kulshrestha',N'9873110310',N'tch_1231@schoolname.edu',N'ACTIVE',1,1),
      (32,132,1,1,5,N'Computer Science Instructor',N'TCHR032',N'Ekta',N'Agarwal',N'9873210320',N'tch_1232@schoolname.edu',N'ACTIVE',1,1),
      (33,133,1,1,5,N'Computer Science Instructor',N'TCHR033',N'Veer',N'Mittal',N'9873310330',N'tch_1233@schoolname.edu',N'ACTIVE',1,1),
      (34,134,1,1,5,N'Computer Science Instructor',N'TCHR034',N'Hema',N'Bansal',N'9873410340',N'tch_1234@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 6: Physical Education (Teachers 35..40)
      (35,135,1,1,6,N'Physical Education Director',N'TCHR035',N'Abhiram',N'Kansal',N'9873510350',N'tch_1235@schoolname.edu',N'ACTIVE',1,1),
      (36,136,1,1,6,N'Physical Education Teacher',N'TCHR036',N'Jaya',N'Khatri',N'9873610360',N'tch_1236@schoolname.edu',N'ACTIVE',1,1),
      (37,137,1,1,6,N'Physical Education Teacher',N'TCHR037',N'Chandan',N'Talwar',N'9873710370',N'tch_1237@schoolname.edu',N'ACTIVE',1,1),
      (38,138,1,1,6,N'Physical Education Teacher',N'TCHR038',N'Lata',N'Chawla',N'9873810380',N'tch_1238@schoolname.edu',N'ACTIVE',1,1),
      (39,139,1,1,6,N'Physical Education Teacher',N'TCHR039',N'Eashan',N'Sodhi',N'9873910390',N'tch_1239@schoolname.edu',N'ACTIVE',1,1),
      (40,140,1,1,6,N'Physical Education Teacher',N'TCHR040',N'Neha',N'Lamba',N'9874010400',N'tch_1240@schoolname.edu',N'ACTIVE',1,1),

      -- Branch 2 (North Campus: Teachers 41..80)
      -- Subject 1: English (Teachers 41..47)
      (41,141,1,2,1,N'English Department Head',N'TCHR041',N'Hemant',N'Mehra',N'9874110410',N'tch_1241@schoolname.edu',N'ACTIVE',1,1),
      (42,142,1,2,1,N'Senior English Faculty',N'TCHR042',N'Rekha',N'Madan',N'9874210420',N'tch_1242@schoolname.edu',N'ACTIVE',1,1),
      (43,143,1,2,1,N'Senior English Faculty',N'TCHR043',N'Jagdish',N'Munjal',N'9874310430',N'tch_1243@schoolname.edu',N'ACTIVE',1,1),
      (44,144,1,2,1,N'Senior English Faculty',N'TCHR044',N'Tulsi',N'Gowda',N'9874410440',N'tch_1244@schoolname.edu',N'ACTIVE',1,1),
      (45,145,1,2,1,N'Senior English Faculty',N'TCHR045',N'Lalit',N'Chowdary',N'9874510450',N'tch_1245@schoolname.edu',N'ACTIVE',1,1),
      (46,146,1,2,1,N'Senior English Faculty',N'TCHR046',N'Vani',N'Venkatesh',N'9874610460',N'tch_1246@schoolname.edu',N'ACTIVE',1,1),
      (47,147,1,2,1,N'Senior English Faculty',N'TCHR047',N'Naveen',N'Subramanian',N'9874710470',N'tch_1247@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 2: Mathematics (Teachers 48..54)
      (48,148,1,2,2,N'Mathematics Department Head',N'TCHR048',N'Archana',N'Krishnan',N'9874810480',N'tch_1248@schoolname.edu',N'ACTIVE',1,1),
      (49,149,1,2,2,N'Senior Mathematics Faculty',N'TCHR049',N'Rajesh',N'Narayanan',N'9874910490',N'tch_1249@schoolname.edu',N'ACTIVE',1,1),
      (50,150,1,2,2,N'Senior Mathematics Faculty',N'TCHR050',N'Asha',N'Srinivasan',N'9875010500',N'tch_1250@schoolname.edu',N'ACTIVE',1,1),
      (51,151,1,2,2,N'Senior Mathematics Faculty',N'TCHR051',N'Abhay',N'Venkataraman',N'9875110510',N'tch_1251@schoolname.edu',N'ACTIVE',1,1),
      (52,152,1,2,2,N'Senior Mathematics Faculty',N'TCHR052',N'Beena',N'Ananthakrishnan',N'9875210520',N'tch_1252@schoolname.edu',N'ACTIVE',1,1),
      (53,153,1,2,2,N'Senior Mathematics Faculty',N'TCHR053',N'Amrit',N'Swaminathan',N'9875310530',N'tch_1253@schoolname.edu',N'ACTIVE',1,1),
      (54,154,1,2,2,N'Senior Mathematics Faculty',N'TCHR054',N'Chhaya',N'Kaushik',N'9875410540',N'tch_1254@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 3: Science (Teachers 55..61)
      (55,155,1,2,3,N'Science Department Head',N'TCHR055',N'Ansh',N'Gautam',N'9875510550',N'tch_1255@schoolname.edu',N'ACTIVE',1,1),
      (56,156,1,2,3,N'Senior Science Teacher',N'TCHR056',N'Deepika',N'Awasthi',N'9875610560',N'tch_1256@schoolname.edu',N'ACTIVE',1,1),
      (57,157,1,2,3,N'Senior Science Teacher',N'TCHR057',N'Ashish',N'Vaidya',N'9875710570',N'tch_1257@schoolname.edu',N'ACTIVE',1,1),
      (58,158,1,2,3,N'Senior Science Teacher',N'TCHR058',N'Geetika',N'Somayaji',N'9875810580',N'tch_1258@schoolname.edu',N'ACTIVE',1,1),
      (59,159,1,2,3,N'Senior Science Teacher',N'TCHR059',N'Bharat',N'Bhattacharya',N'9875910590',N'tch_1259@schoolname.edu',N'ACTIVE',1,1),
      (60,160,1,2,3,N'Senior Science Teacher',N'TCHR060',N'Kamla',N'Ganguly',N'9876010600',N'tch_1260@schoolname.edu',N'ACTIVE',1,1),
      (61,161,1,2,3,N'Senior Science Teacher',N'TCHR061',N'Devendra',N'Majumdar',N'9876110610',N'tch_1261@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 4: Social Science (Teachers 62..68)
      (62,162,1,2,4,N'Social Science Department Head',N'TCHR062',N'Kiran',N'Sanyal',N'9876210620',N'tch_1262@schoolname.edu',N'ACTIVE',1,1),
      (63,163,1,2,4,N'Social Science Specialist',N'TCHR063',N'Girish',N'Bhowmick',N'9876310630',N'tch_1263@schoolname.edu',N'ACTIVE',1,1),
      (64,164,1,2,4,N'Social Science Specialist',N'TCHR064',N'Kusum',N'Varma',N'9876410640',N'tch_1264@schoolname.edu',N'ACTIVE',1,1),
      (65,165,1,2,4,N'Social Science Specialist',N'TCHR065',N'Harish',N'Patel',N'9876510650',N'tch_1265@schoolname.edu',N'ACTIVE',1,1),
      (66,166,1,2,4,N'Social Science Specialist',N'TCHR066',N'Madhu',N'Kumar',N'9876610660',N'tch_1266@schoolname.edu',N'ACTIVE',1,1),
      (67,167,1,2,4,N'Social Science Specialist',N'TCHR067',N'Jitendra',N'Rao',N'9876710670',N'tch_1267@schoolname.edu',N'ACTIVE',1,1),
      (68,168,1,2,4,N'Social Science Specialist',N'TCHR068',N'Manju',N'Iyer',N'9876810680',N'tch_1268@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 5: Computer Science (Teachers 69..74)
      (69,169,1,2,5,N'Computer Science Department Head',N'TCHR069',N'Karan',N'Joshi',N'9876910690',N'tch_1269@schoolname.edu',N'ACTIVE',1,1),
      (70,170,1,2,5,N'Computer Science Instructor',N'TCHR070',N'Meena',N'Sen',N'9877010700',N'tch_1270@schoolname.edu',N'ACTIVE',1,1),
      (71,171,1,2,5,N'Computer Science Instructor',N'TCHR071',N'Kishore',N'Kulkarni',N'9877110710',N'tch_1271@schoolname.edu',N'ACTIVE',1,1),
      (72,172,1,2,5,N'Computer Science Instructor',N'TCHR072',N'Mohini',N'Pillai',N'9877210720',N'tch_1272@schoolname.edu',N'ACTIVE',1,1),
      (73,173,1,2,5,N'Computer Science Instructor',N'TCHR073',N'Manish',N'Mukherjee',N'9877310730',N'tch_1273@schoolname.edu',N'ACTIVE',1,1),
      (74,174,1,2,5,N'Computer Science Instructor',N'TCHR074',N'Nalini',N'Bose',N'9877410740',N'tch_1274@schoolname.edu',N'ACTIVE',1,1),

      -- Subject 6: Physical Education (Teachers 75..80)
      (75,175,1,2,6,N'Physical Education Director',N'TCHR075',N'Mukul',N'Ghosh',N'9877510750',N'tch_1275@schoolname.edu',N'ACTIVE',1,1),
      (76,176,1,2,6,N'Physical Education Teacher',N'TCHR076',N'Neelam',N'Menon',N'9877610760',N'tch_1276@schoolname.edu',N'ACTIVE',1,1),
      (77,177,1,2,6,N'Physical Education Teacher',N'TCHR077',N'Nitin',N'Shetty',N'9877710770',N'tch_1277@schoolname.edu',N'ACTIVE',1,1),
      (78,178,1,2,6,N'Physical Education Teacher',N'TCHR078',N'Nirmala',N'Pai',N'9877810780',N'tch_1278@schoolname.edu',N'ACTIVE',1,1),
      (79,179,1,2,6,N'Physical Education Teacher',N'TCHR079',N'Pradeep',N'Mishra',N'9877910790',N'tch_1279@schoolname.edu',N'ACTIVE',1,1),
      (80,180,1,2,6,N'Physical Education Teacher',N'TCHR080',N'Pallavi',N'Tiwari',N'9878010800',N'tch_1280@schoolname.edu',N'ACTIVE',1,1);


    SET IDENTITY_INSERT teachers_schema.teacher OFF;

    /* Section Class Teacher Assignments: Exactly 1 Unique Class Teacher per Section */
    SET IDENTITY_INSERT teachers_schema.section_class_teacher_assignment ON;
    INSERT INTO teachers_schema.section_class_teacher_assignment
      (section_class_teacher_assignment_id,school_id,branch_id,academic_year_id,class_id,section_id,
       teacher_id,is_active,created_by)
    SELECT
      sec.section_id,
      1,
      CASE WHEN sec.class_id <= 10 THEN 1 ELSE 2 END,
      1,
      sec.class_id,
      sec.section_id,
      CASE 
        WHEN sec.section_id <= 20 THEN sec.section_id
        ELSE                           20 + sec.section_id
      END,
      1,
      1
    FROM management_schema.section sec;
    SET IDENTITY_INSERT teachers_schema.section_class_teacher_assignment OFF;

    /* Teacher Subject Assignment: 6 subjects per section
       Each teacher is strictly specialized in EXACTLY ONE subject */
    SET IDENTITY_INSERT teachers_schema.teacher_subject_assignment ON;
    INSERT INTO teachers_schema.teacher_subject_assignment
      (teacher_subject_assignment_id,school_id,branch_id,academic_year_id,class_id,section_id,
       class_subject_id,subject_id,teacher_id,is_active,created_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY sec.section_id, cs.subject_id),
      1,
      CASE WHEN sec.class_id <= 10 THEN 1 ELSE 2 END,
      1,
      sec.class_id,
      sec.section_id,
      cs.class_subject_id,
      cs.subject_id,
      CASE 
        WHEN sec.section_id <= 20 THEN
            CASE cs.subject_id
                WHEN 1 THEN 1  + ((sec.section_id - 1) % 7)
                WHEN 2 THEN 8  + ((sec.section_id - 1) % 7)
                WHEN 3 THEN 15 + ((sec.section_id - 1) % 7)
                WHEN 4 THEN 22 + ((sec.section_id - 1) % 7)
                WHEN 5 THEN 29 + ((sec.section_id - 1) % 6)
                WHEN 6 THEN 35 + ((sec.section_id - 1) % 6)
            END
        ELSE
            CASE cs.subject_id
                WHEN 1 THEN 41 + ((sec.section_id - 21) % 7)
                WHEN 2 THEN 48 + ((sec.section_id - 21) % 7)
                WHEN 3 THEN 55 + ((sec.section_id - 21) % 7)
                WHEN 4 THEN 62 + ((sec.section_id - 21) % 7)
                WHEN 5 THEN 69 + ((sec.section_id - 21) % 6)
                WHEN 6 THEN 75 + ((sec.section_id - 21) % 6)
            END
      END,
      1,
      1
    FROM management_schema.section sec
    JOIN management_schema.class_subject cs
      ON cs.class_id = sec.class_id
     AND cs.branch_id = (CASE WHEN sec.class_id <= 10 THEN 1 ELSE 2 END);
    SET IDENTITY_INSERT teachers_schema.teacher_subject_assignment OFF;

    /* ============================================================
       4. STUDENTS (400 Active Students = 10 per Section, plus 20 Alumni)
       Emails: stu_1201@schoolname.edu to stu_1600@schoolname.edu (Active)
               stu_1601@schoolname.edu to stu_1620@schoolname.edu (Alumni)
       ============================================================ */
    SET IDENTITY_INSERT student_schema.student ON;
    INSERT INTO student_schema.student
      (student_id,user_id,school_id,branch_id,academic_year_id,class_id,section_id,
       admission_number,roll_number,first_name,last_name,date_of_birth,gender,blood_group,
       nationality,mother_tongue,religion,student_category,admission_date,student_status,
       status_effective_date,mobile_number,email_address,address_line_1,address_line_2,
       landmark,city,district,state,postal_code,country,is_active,residency_type,created_by)
    VALUES
      (1,201,1,1,1,1,1,N'ADM-2026-0001',N'R-01',N'Karishma',N'Shaik','2020-08-12',N'FEMALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980001011',N'stu_1201@schoolname.edu',N'House 101, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500011',N'India',1,N'DAY_SCHOLAR',1),
      (2,202,1,1,1,1,1,N'ADM-2026-0002',N'R-02',N'Dhamodhar',N'Rao','2020-03-23',N'MALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980002011',N'stu_1202@schoolname.edu',N'House 102, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500012',N'India',1,N'DAY_SCHOLAR',1),
      (3,203,1,1,1,1,1,N'ADM-2026-0003',N'R-03',N'Sita',N'Ram','2020-10-06',N'FEMALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980003011',N'stu_1203@schoolname.edu',N'House 103, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500013',N'India',1,N'DAY_SCHOLAR',1),
      (4,204,1,1,1,1,1,N'ADM-2026-0004',N'R-04',N'Krupa',N'Joseph','2020-05-17',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980004011',N'stu_1204@schoolname.edu',N'House 104, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500014',N'India',1,N'DAY_SCHOLAR',1),
      (5,205,1,1,1,1,1,N'ADM-2026-0005',N'R-05',N'Jeswanth',N'Reddy','2020-12-28',N'MALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980005011',N'stu_1205@schoolname.edu',N'House 105, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500015',N'India',1,N'HOSTELLER',1),
      (6,206,1,1,1,1,1,N'ADM-2026-0006',N'R-06',N'Sravan',N'Kumar','2020-07-11',N'MALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980006011',N'stu_1206@schoolname.edu',N'House 106, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500016',N'India',1,N'DAY_SCHOLAR',1),
      (7,207,1,1,1,1,1,N'ADM-2026-0007',N'R-07',N'Gaurav',N'Joshi','2020-02-22',N'MALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980007011',N'stu_1207@schoolname.edu',N'House 107, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500017',N'India',1,N'DAY_SCHOLAR',1),
      (8,208,1,1,1,1,1,N'ADM-2026-0008',N'R-08',N'Manish',N'Talwar','2020-09-05',N'MALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980008011',N'stu_1208@schoolname.edu',N'House 108, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500018',N'India',1,N'DAY_SCHOLAR',1),
      (9,209,1,1,1,1,1,N'ADM-2026-0009',N'R-09',N'Zara',N'Tiwari','2020-04-16',N'FEMALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980009011',N'stu_1209@schoolname.edu',N'House 109, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500019',N'India',1,N'DAY_SCHOLAR',1),
      (10,210,1,1,1,1,1,N'ADM-2026-0010',N'R-10',N'Sarita',N'Sengupta','2020-11-27',N'FEMALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980010011',N'stu_1210@schoolname.edu',N'House 110, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500020',N'India',1,N'HOSTELLER',1),
      (11,211,1,1,1,1,2,N'ADM-2026-0011',N'R-01',N'Gurpreet',N'Pillai','2020-06-10',N'MALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980011021',N'stu_1211@schoolname.edu',N'House 111, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500021',N'India',1,N'DAY_SCHOLAR',1),
      (12,212,1,1,1,1,2,N'ADM-2026-0012',N'R-02',N'Deepika',N'Pathak','2020-01-21',N'FEMALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980012021',N'stu_1212@schoolname.edu',N'House 112, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500022',N'India',1,N'DAY_SCHOLAR',1),
      (13,213,1,1,1,1,2,N'ADM-2026-0013',N'R-03',N'Varun',N'Venkataraman','2020-08-04',N'MALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980013021',N'stu_1213@schoolname.edu',N'House 113, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500023',N'India',1,N'DAY_SCHOLAR',1),
      (14,214,1,1,1,1,2,N'ADM-2026-0014',N'R-04',N'Reena',N'Mitra','2020-03-15',N'FEMALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980014021',N'stu_1214@schoolname.edu',N'House 114, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500024',N'India',1,N'DAY_SCHOLAR',1),
      (15,215,1,1,1,1,2,N'ADM-2026-0015',N'R-05',N'Sangeeta',N'Ghosh','2020-10-26',N'FEMALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980015021',N'stu_1215@schoolname.edu',N'House 115, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500025',N'India',1,N'HOSTELLER',1),
      (16,216,1,1,1,1,2,N'ADM-2026-0016',N'R-06',N'Uma',N'Asthana','2020-05-09',N'FEMALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980016021',N'stu_1216@schoolname.edu',N'House 116, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500026',N'India',1,N'DAY_SCHOLAR',1),
      (17,217,1,1,1,1,2,N'ADM-2026-0017',N'R-07',N'Nikhil',N'Acharya','2020-12-20',N'MALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980017021',N'stu_1217@schoolname.edu',N'House 117, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500027',N'India',1,N'DAY_SCHOLAR',1),
      (18,218,1,1,1,1,2,N'ADM-2026-0018',N'R-08',N'Kavya',N'Sidhu','2020-07-03',N'FEMALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980018021',N'stu_1218@schoolname.edu',N'House 118, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500028',N'India',1,N'DAY_SCHOLAR',1),
      (19,219,1,1,1,1,2,N'ADM-2026-0019',N'R-09',N'Suresh',N'Banerjee','2020-02-14',N'MALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980019021',N'stu_1219@schoolname.edu',N'House 119, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500029',N'India',1,N'DAY_SCHOLAR',1),
      (20,220,1,1,1,1,2,N'ADM-2026-0020',N'R-10',N'Nakul',N'Chatterjee','2020-09-25',N'MALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980020021',N'stu_1220@schoolname.edu',N'House 120, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500030',N'India',1,N'HOSTELLER',1),
      (21,221,1,1,1,2,3,N'ADM-2026-0021',N'R-01',N'Rashmi',N'Kulshrestha','2019-04-08',N'FEMALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980021031',N'stu_1221@schoolname.edu',N'House 121, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500031',N'India',1,N'DAY_SCHOLAR',1),
      (22,222,1,1,1,2,3,N'ADM-2026-0022',N'R-02',N'Vinod',N'Bhandari','2019-11-19',N'MALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980022031',N'stu_1222@schoolname.edu',N'House 122, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500032',N'India',1,N'DAY_SCHOLAR',1),
      (23,223,1,1,1,2,3,N'ADM-2026-0023',N'R-03',N'Radhika',N'Kulkarni','2019-06-02',N'FEMALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980023031',N'stu_1223@schoolname.edu',N'House 123, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500033',N'India',1,N'DAY_SCHOLAR',1),
      (24,224,1,1,1,2,3,N'ADM-2026-0024',N'R-04',N'Piyush',N'Bakshi','2019-01-13',N'MALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980024031',N'stu_1224@schoolname.edu',N'House 124, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500034',N'India',1,N'DAY_SCHOLAR',1),
      (25,225,1,1,1,2,3,N'ADM-2026-0025',N'R-05',N'Krishna',N'Hegde','2019-08-24',N'MALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980025031',N'stu_1225@schoolname.edu',N'House 125, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500035',N'India',1,N'HOSTELLER',1),
      (26,226,1,1,1,2,3,N'ADM-2026-0026',N'R-06',N'Gautam',N'Kohli','2019-03-07',N'MALE',N'O+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980026031',N'stu_1226@schoolname.edu',N'House 126, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500036',N'India',1,N'DAY_SCHOLAR',1),
      (27,227,1,1,1,2,3,N'ADM-2026-0027',N'R-07',N'Manpreet',N'Dubey','2019-10-18',N'MALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980027031',N'stu_1227@schoolname.edu',N'House 127, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500037',N'India',1,N'DAY_SCHOLAR',1),
      (28,228,1,1,1,2,3,N'ADM-2026-0028',N'R-08',N'Vivaan',N'Rao','2019-05-01',N'MALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980028031',N'stu_1228@schoolname.edu',N'House 128, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500038',N'India',1,N'DAY_SCHOLAR',1),
      (29,229,1,1,1,2,3,N'ADM-2026-0029',N'R-09',N'Veena',N'Kansal','2019-12-12',N'FEMALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980029031',N'stu_1229@schoolname.edu',N'House 129, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500039',N'India',1,N'DAY_SCHOLAR',1),
      (30,230,1,1,1,2,3,N'ADM-2026-0030',N'R-10',N'Anamika',N'Nagpal','2019-07-23',N'FEMALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980030031',N'stu_1230@schoolname.edu',N'House 130, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500040',N'India',1,N'HOSTELLER',1),
      (31,231,1,1,1,2,4,N'ADM-2026-0031',N'R-01',N'Barkha',N'Jha','2019-02-06',N'FEMALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980031041',N'stu_1231@schoolname.edu',N'House 131, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500041',N'India',1,N'DAY_SCHOLAR',1),
      (32,232,1,1,1,2,4,N'ADM-2026-0032',N'R-02',N'Tara',N'Bose','2019-09-17',N'FEMALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980032041',N'stu_1232@schoolname.edu',N'House 132, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500042',N'India',1,N'DAY_SCHOLAR',1),
      (33,233,1,1,1,2,4,N'ADM-2026-0033',N'R-03',N'Dhriti',N'Goswami','2019-04-28',N'FEMALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980033041',N'stu_1233@schoolname.edu',N'House 133, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500043',N'India',1,N'DAY_SCHOLAR',1),
      (34,234,1,1,1,2,4,N'ADM-2026-0034',N'R-04',N'Ira',N'Pai','2019-11-11',N'FEMALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980034041',N'stu_1234@schoolname.edu',N'House 134, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500044',N'India',1,N'DAY_SCHOLAR',1),
      (35,235,1,1,1,2,4,N'ADM-2026-0035',N'R-05',N'Pratyush',N'Nambiar','2019-06-22',N'MALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980035041',N'stu_1235@schoolname.edu',N'House 135, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500045',N'India',1,N'HOSTELLER',1),
      (36,236,1,1,1,2,4,N'ADM-2026-0036',N'R-06',N'Ronit',N'Chowdary','2019-01-05',N'MALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980036041',N'stu_1236@schoolname.edu',N'House 136, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500046',N'India',1,N'DAY_SCHOLAR',1),
      (37,237,1,1,1,2,4,N'ADM-2026-0037',N'R-07',N'Shilpa',N'Parmar','2019-08-16',N'FEMALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980037041',N'stu_1237@schoolname.edu',N'House 137, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500047',N'India',1,N'DAY_SCHOLAR',1),
      (38,238,1,1,1,2,4,N'ADM-2026-0038',N'R-08',N'Divya',N'Naidu','2019-03-27',N'FEMALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980038041',N'stu_1238@schoolname.edu',N'House 138, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500048',N'India',1,N'DAY_SCHOLAR',1),
      (39,239,1,1,1,2,4,N'ADM-2026-0039',N'R-09',N'Vedant',N'Ojha','2019-10-10',N'MALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980039041',N'stu_1239@schoolname.edu',N'House 139, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500049',N'India',1,N'DAY_SCHOLAR',1),
      (40,240,1,1,1,2,4,N'ADM-2026-0040',N'R-10',N'Swara',N'Bhattacharya','2019-05-21',N'FEMALE',N'O-',N'Indian',N'English',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980040041',N'stu_1240@schoolname.edu',N'House 140, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500050',N'India',1,N'HOSTELLER',1),
      (41,241,1,1,1,3,5,N'ADM-2026-0041',N'R-01',N'Diya',N'Sharma','2018-12-04',N'FEMALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980041051',N'stu_1241@schoolname.edu',N'House 141, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500051',N'India',1,N'DAY_SCHOLAR',1),
      (42,242,1,1,1,3,5,N'ADM-2026-0042',N'R-02',N'Neha',N'Somayaji','2018-07-15',N'FEMALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980042051',N'stu_1242@schoolname.edu',N'House 142, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500052',N'India',1,N'DAY_SCHOLAR',1),
      (43,243,1,1,1,3,5,N'ADM-2026-0043',N'R-03',N'Mahi',N'Bakshi','2018-02-26',N'FEMALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980043051',N'stu_1243@schoolname.edu',N'House 143, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500053',N'India',1,N'DAY_SCHOLAR',1),
      (44,244,1,1,1,3,5,N'ADM-2026-0044',N'R-04',N'Aadhya',N'Vashist','2018-09-09',N'FEMALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980044051',N'stu_1244@schoolname.edu',N'House 144, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500054',N'India',1,N'DAY_SCHOLAR',1),
      (45,245,1,1,1,3,5,N'ADM-2026-0045',N'R-05',N'Bhavin',N'Bhandari','2018-04-20',N'MALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980045051',N'stu_1245@schoolname.edu',N'House 145, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500055',N'India',1,N'HOSTELLER',1),
      (46,246,1,1,1,3,5,N'ADM-2026-0046',N'R-06',N'Prabha',N'Venkataraman','2018-11-03',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980046051',N'stu_1246@schoolname.edu',N'House 146, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500056',N'India',1,N'DAY_SCHOLAR',1),
      (47,247,1,1,1,3,5,N'ADM-2026-0047',N'R-07',N'Bhavya',N'Vashist','2018-06-14',N'FEMALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980047051',N'stu_1247@schoolname.edu',N'House 147, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500057',N'India',1,N'DAY_SCHOLAR',1),
      (48,248,1,1,1,3,5,N'ADM-2026-0048',N'R-08',N'Pavan',N'Mehta','2018-01-25',N'MALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980048051',N'stu_1248@schoolname.edu',N'House 148, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500058',N'India',1,N'DAY_SCHOLAR',1),
      (49,249,1,1,1,3,5,N'ADM-2026-0049',N'R-09',N'Mukta',N'Bhandari','2018-08-08',N'FEMALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980049051',N'stu_1249@schoolname.edu',N'House 149, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500059',N'India',1,N'DAY_SCHOLAR',1),
      (50,250,1,1,1,3,5,N'ADM-2026-0050',N'R-10',N'Sanjeev',N'Das','2018-03-19',N'MALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980050051',N'stu_1250@schoolname.edu',N'House 150, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500060',N'India',1,N'HOSTELLER',1),
      (51,251,1,1,1,3,6,N'ADM-2026-0051',N'R-01',N'Adhiraj',N'Prasad','2018-10-02',N'MALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980051061',N'stu_1251@schoolname.edu',N'House 151, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500061',N'India',1,N'DAY_SCHOLAR',1),
      (52,252,1,1,1,3,6,N'ADM-2026-0052',N'R-02',N'Devesh',N'Kapoor','2018-05-13',N'MALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980052061',N'stu_1252@schoolname.edu',N'House 152, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500062',N'India',1,N'DAY_SCHOLAR',1),
      (53,253,1,1,1,3,6,N'ADM-2026-0053',N'R-03',N'Sharda',N'Dubey','2018-12-24',N'FEMALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980053061',N'stu_1253@schoolname.edu',N'House 153, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500063',N'India',1,N'DAY_SCHOLAR',1),
      (54,254,1,1,1,3,6,N'ADM-2026-0054',N'R-04',N'Chetan',N'Mitra','2018-07-07',N'MALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980054061',N'stu_1254@schoolname.edu',N'House 154, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500064',N'India',1,N'DAY_SCHOLAR',1),
      (55,255,1,1,1,3,6,N'ADM-2026-0055',N'R-05',N'Pihu',N'Kansal','2018-02-18',N'FEMALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980055061',N'stu_1255@schoolname.edu',N'House 155, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500065',N'India',1,N'HOSTELLER',1),
      (56,256,1,1,1,3,6,N'ADM-2026-0056',N'R-06',N'Santosh',N'Sen','2018-09-01',N'MALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980056061',N'stu_1256@schoolname.edu',N'House 156, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500066',N'India',1,N'DAY_SCHOLAR',1),
      (57,257,1,1,1,3,6,N'ADM-2026-0057',N'R-07',N'Riya',N'Chauhan','2018-04-12',N'FEMALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980057061',N'stu_1257@schoolname.edu',N'House 157, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500067',N'India',1,N'DAY_SCHOLAR',1),
      (58,258,1,1,1,3,6,N'ADM-2026-0058',N'R-08',N'Naman',N'Suri','2018-11-23',N'MALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980058061',N'stu_1258@schoolname.edu',N'House 158, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500068',N'India',1,N'DAY_SCHOLAR',1),
      (59,259,1,1,1,3,6,N'ADM-2026-0059',N'R-09',N'Ankita',N'Raju','2018-06-06',N'FEMALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980059061',N'stu_1259@schoolname.edu',N'House 159, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500069',N'India',1,N'DAY_SCHOLAR',1),
      (60,260,1,1,1,3,6,N'ADM-2026-0060',N'R-10',N'Rachna',N'Vaidya','2018-01-17',N'FEMALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980060061',N'stu_1260@schoolname.edu',N'House 160, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500070',N'India',1,N'HOSTELLER',1),
      (61,261,1,1,1,4,7,N'ADM-2026-0061',N'R-01',N'Eashan',N'Awasthi','2017-08-28',N'MALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980061071',N'stu_1261@schoolname.edu',N'House 161, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500071',N'India',1,N'DAY_SCHOLAR',1),
      (62,262,1,1,1,4,7,N'ADM-2026-0062',N'R-02',N'Angel',N'Sanyal','2017-03-11',N'FEMALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980062071',N'stu_1262@schoolname.edu',N'House 162, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500072',N'India',1,N'DAY_SCHOLAR',1),
      (63,263,1,1,1,4,7,N'ADM-2026-0063',N'R-03',N'Parth',N'Mittal','2017-10-22',N'MALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980063071',N'stu_1263@schoolname.edu',N'House 163, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500073',N'India',1,N'DAY_SCHOLAR',1),
      (64,264,1,1,1,4,7,N'ADM-2026-0064',N'R-04',N'Kushagra',N'Agarwal','2017-05-05',N'MALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980064071',N'stu_1264@schoolname.edu',N'House 164, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500074',N'India',1,N'DAY_SCHOLAR',1),
      (65,265,1,1,1,4,7,N'ADM-2026-0065',N'R-05',N'Anuraag',N'Kaushik','2017-12-16',N'MALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980065071',N'stu_1265@schoolname.edu',N'House 165, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500075',N'India',1,N'HOSTELLER',1),
      (66,266,1,1,1,4,7,N'ADM-2026-0066',N'R-06',N'Yatharth',N'Trehan','2017-07-27',N'MALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980066071',N'stu_1266@schoolname.edu',N'House 166, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500076',N'India',1,N'DAY_SCHOLAR',1),
      (67,267,1,1,1,4,7,N'ADM-2026-0067',N'R-07',N'Neeru',N'Kashyap','2017-02-10',N'FEMALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980067071',N'stu_1267@schoolname.edu',N'House 167, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500077',N'India',1,N'DAY_SCHOLAR',1),
      (68,268,1,1,1,4,7,N'ADM-2026-0068',N'R-08',N'Prashant',N'Narayanan','2017-09-21',N'MALE',N'O+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980068071',N'stu_1268@schoolname.edu',N'House 168, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500078',N'India',1,N'DAY_SCHOLAR',1),
      (69,269,1,1,1,4,7,N'ADM-2026-0069',N'R-09',N'Pankaj',N'Naidu','2017-04-04',N'MALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980069071',N'stu_1269@schoolname.edu',N'House 169, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500079',N'India',1,N'DAY_SCHOLAR',1),
      (70,270,1,1,1,4,7,N'ADM-2026-0070',N'R-10',N'Manoj',N'Ghai','2017-11-15',N'MALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980070071',N'stu_1270@schoolname.edu',N'House 170, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500080',N'India',1,N'HOSTELLER',1),
      (71,271,1,1,1,4,8,N'ADM-2026-0071',N'R-01',N'Niharika',N'Singh','2017-06-26',N'FEMALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980071081',N'stu_1271@schoolname.edu',N'House 171, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500081',N'India',1,N'DAY_SCHOLAR',1),
      (72,272,1,1,1,4,8,N'ADM-2026-0072',N'R-02',N'Preeti',N'Kaushik','2017-01-09',N'FEMALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980072081',N'stu_1272@schoolname.edu',N'House 172, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500082',N'India',1,N'DAY_SCHOLAR',1),
      (73,273,1,1,1,4,8,N'ADM-2026-0073',N'R-03',N'Ishan',N'Mishra','2017-08-20',N'MALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980073081',N'stu_1273@schoolname.edu',N'House 173, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500083',N'India',1,N'DAY_SCHOLAR',1),
      (74,274,1,1,1,4,8,N'ADM-2026-0074',N'R-04',N'Chaitanya',N'Bedi','2017-03-03',N'MALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980074081',N'stu_1274@schoolname.edu',N'House 174, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500084',N'India',1,N'DAY_SCHOLAR',1),
      (75,275,1,1,1,4,8,N'ADM-2026-0075',N'R-05',N'Sadhana',N'Pillai','2017-10-14',N'FEMALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980075081',N'stu_1275@schoolname.edu',N'House 175, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500085',N'India',1,N'HOSTELLER',1),
      (76,276,1,1,1,4,8,N'ADM-2026-0076',N'R-06',N'Seema',N'Pai','2017-05-25',N'FEMALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980076081',N'stu_1276@schoolname.edu',N'House 176, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500086',N'India',1,N'DAY_SCHOLAR',1),
      (77,277,1,1,1,4,8,N'ADM-2026-0077',N'R-07',N'Indu',N'Raghavan','2017-12-08',N'FEMALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980077081',N'stu_1277@schoolname.edu',N'House 177, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500087',N'India',1,N'DAY_SCHOLAR',1),
      (78,278,1,1,1,4,8,N'ADM-2026-0078',N'R-08',N'Bhuvan',N'Sidhu','2017-07-19',N'MALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980078081',N'stu_1278@schoolname.edu',N'House 178, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500088',N'India',1,N'DAY_SCHOLAR',1),
      (79,279,1,1,1,4,8,N'ADM-2026-0079',N'R-09',N'Umesh',N'Bhatia','2017-02-02',N'MALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980079081',N'stu_1279@schoolname.edu',N'House 179, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500089',N'India',1,N'DAY_SCHOLAR',1),
      (80,280,1,1,1,4,8,N'ADM-2026-0080',N'R-10',N'Balram',N'Viswanathan','2017-09-13',N'MALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980080081',N'stu_1280@schoolname.edu',N'House 180, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500010',N'India',1,N'HOSTELLER',1),
      (81,281,1,1,1,5,9,N'ADM-2026-0081',N'R-01',N'Sudhir',N'Solanki','2016-04-24',N'MALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980081091',N'stu_1281@schoolname.edu',N'House 181, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500011',N'India',1,N'DAY_SCHOLAR',1),
      (82,282,1,1,1,5,9,N'ADM-2026-0082',N'R-02',N'Kishore',N'Bansal','2016-11-07',N'MALE',N'O-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980082091',N'stu_1282@schoolname.edu',N'House 182, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500012',N'India',1,N'DAY_SCHOLAR',1),
      (83,283,1,1,1,5,9,N'ADM-2026-0083',N'R-03',N'Poonam',N'Ganesan','2016-06-18',N'FEMALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980083091',N'stu_1283@schoolname.edu',N'House 183, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500013',N'India',1,N'DAY_SCHOLAR',1),
      (84,284,1,1,1,5,9,N'ADM-2026-0084',N'R-04',N'Disha',N'Agarwal','2016-01-01',N'FEMALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980084091',N'stu_1284@schoolname.edu',N'House 184, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500014',N'India',1,N'DAY_SCHOLAR',1),
      (85,285,1,1,1,5,9,N'ADM-2026-0085',N'R-05',N'Ishita',N'Sethi','2016-08-12',N'FEMALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980085091',N'stu_1285@schoolname.edu',N'House 185, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500015',N'India',1,N'HOSTELLER',1),
      (86,286,1,1,1,5,9,N'ADM-2026-0086',N'R-06',N'Mohit',N'Kansal','2016-03-23',N'MALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980086091',N'stu_1286@schoolname.edu',N'House 186, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500016',N'India',1,N'DAY_SCHOLAR',1),
      (87,287,1,1,1,5,9,N'ADM-2026-0087',N'R-07',N'Ashish',N'Jha','2016-10-06',N'MALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980087091',N'stu_1287@schoolname.edu',N'House 187, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500017',N'India',1,N'DAY_SCHOLAR',1),
      (88,288,1,1,1,5,9,N'ADM-2026-0088',N'R-08',N'Anika',N'Joshi','2016-05-17',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980088091',N'stu_1288@schoolname.edu',N'House 188, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500018',N'India',1,N'DAY_SCHOLAR',1),
      (89,289,1,1,1,5,9,N'ADM-2026-0089',N'R-09',N'Yash',N'Ganesan','2016-12-28',N'MALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980089091',N'stu_1289@schoolname.edu',N'House 189, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500019',N'India',1,N'DAY_SCHOLAR',1),
      (90,290,1,1,1,5,9,N'ADM-2026-0090',N'R-10',N'Anvi',N'Dubey','2016-07-11',N'FEMALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980090091',N'stu_1290@schoolname.edu',N'House 190, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500020',N'India',1,N'HOSTELLER',1),
      (91,291,1,1,1,5,10,N'ADM-2026-0091',N'R-01',N'Malini',N'Narang','2016-02-22',N'FEMALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980091101',N'stu_1291@schoolname.edu',N'House 191, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500021',N'India',1,N'DAY_SCHOLAR',1),
      (92,292,1,1,1,5,10,N'ADM-2026-0092',N'R-02',N'Nandini',N'Mehra','2016-09-05',N'FEMALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980092101',N'stu_1292@schoolname.edu',N'House 192, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500022',N'India',1,N'DAY_SCHOLAR',1),
      (93,293,1,1,1,5,10,N'ADM-2026-0093',N'R-03',N'Rajni',N'Acharya','2016-04-16',N'FEMALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980093101',N'stu_1293@schoolname.edu',N'House 193, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500023',N'India',1,N'DAY_SCHOLAR',1),
      (94,294,1,1,1,5,10,N'ADM-2026-0094',N'R-04',N'Vikram',N'Singhal','2016-11-27',N'MALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980094101',N'stu_1294@schoolname.edu',N'House 194, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500024',N'India',1,N'DAY_SCHOLAR',1),
      (95,295,1,1,1,5,10,N'ADM-2026-0095',N'R-05',N'Vijay',N'Bhatnagar','2016-06-10',N'MALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980095101',N'stu_1295@schoolname.edu',N'House 195, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500025',N'India',1,N'HOSTELLER',1),
      (96,296,1,1,1,5,10,N'ADM-2026-0096',N'R-06',N'Kalyan',N'Sharma','2016-01-21',N'MALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980096101',N'stu_1296@schoolname.edu',N'House 196, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500026',N'India',1,N'DAY_SCHOLAR',1),
      (97,297,1,1,1,5,10,N'ADM-2026-0097',N'R-07',N'Ganesh',N'Sastry','2016-08-04',N'MALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980097101',N'stu_1297@schoolname.edu',N'House 197, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500027',N'India',1,N'DAY_SCHOLAR',1),
      (98,298,1,1,1,5,10,N'ADM-2026-0098',N'R-08',N'Smita',N'Gill','2016-03-15',N'FEMALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980098101',N'stu_1298@schoolname.edu',N'House 198, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500028',N'India',1,N'DAY_SCHOLAR',1),
      (99,299,1,1,1,5,10,N'ADM-2026-0099',N'R-09',N'Maya',N'Bhatnagar','2016-10-26',N'FEMALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980099101',N'stu_1299@schoolname.edu',N'House 199, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500029',N'India',1,N'DAY_SCHOLAR',1),
      (100,300,1,1,1,5,10,N'ADM-2026-0100',N'R-10',N'Vipul',N'Sodhi','2016-05-09',N'MALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980100101',N'stu_1300@schoolname.edu',N'House 200, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500030',N'India',1,N'HOSTELLER',1),
      (101,301,1,1,1,6,11,N'ADM-2026-0101',N'R-01',N'Abhay',N'Bose','2015-12-20',N'MALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980101111',N'stu_1301@schoolname.edu',N'House 201, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500031',N'India',1,N'DAY_SCHOLAR',1),
      (102,302,1,1,1,6,11,N'ADM-2026-0102',N'R-02',N'Surendra',N'Khanna','2015-07-03',N'MALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980102111',N'stu_1302@schoolname.edu',N'House 202, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500032',N'India',1,N'DAY_SCHOLAR',1),
      (103,303,1,1,1,6,11,N'ADM-2026-0103',N'R-03',N'Anindita',N'Gowda','2015-02-14',N'FEMALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980103111',N'stu_1303@schoolname.edu',N'House 203, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500033',N'India',1,N'DAY_SCHOLAR',1),
      (104,304,1,1,1,6,11,N'ADM-2026-0104',N'R-04',N'Tulsi',N'Varma','2015-09-25',N'FEMALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980104111',N'stu_1304@schoolname.edu',N'House 204, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500034',N'India',1,N'DAY_SCHOLAR',1),
      (105,305,1,1,1,6,11,N'ADM-2026-0105',N'R-05',N'Kiara',N'Garg','2015-04-08',N'FEMALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980105111',N'stu_1305@schoolname.edu',N'House 205, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500035',N'India',1,N'HOSTELLER',1),
      (106,306,1,1,1,6,11,N'ADM-2026-0106',N'R-06',N'Dhananjay',N'Kumar','2015-11-19',N'MALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980106111',N'stu_1306@schoolname.edu',N'House 206, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500036',N'India',1,N'DAY_SCHOLAR',1),
      (107,307,1,1,1,6,11,N'ADM-2026-0107',N'R-07',N'Arnav',N'Dutta','2015-06-02',N'MALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980107111',N'stu_1307@schoolname.edu',N'House 207, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500037',N'India',1,N'DAY_SCHOLAR',1),
      (108,308,1,1,1,6,11,N'ADM-2026-0108',N'R-08',N'Kriti',N'Awasthi','2015-01-13',N'FEMALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980108111',N'stu_1308@schoolname.edu',N'House 208, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500038',N'India',1,N'DAY_SCHOLAR',1),
      (109,309,1,1,1,6,11,N'ADM-2026-0109',N'R-09',N'Ravindra',N'Sengupta','2015-08-24',N'MALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980109111',N'stu_1309@schoolname.edu',N'House 209, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500039',N'India',1,N'DAY_SCHOLAR',1),
      (110,310,1,1,1,6,11,N'ADM-2026-0110',N'R-10',N'Meera',N'Kohli','2015-03-07',N'FEMALE',N'O+',N'Indian',N'English',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980110111',N'stu_1310@schoolname.edu',N'House 210, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500040',N'India',1,N'HOSTELLER',1),
      (111,311,1,1,1,6,12,N'ADM-2026-0111',N'R-01',N'Urmila',N'Gupta','2015-10-18',N'FEMALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980111121',N'stu_1311@schoolname.edu',N'House 211, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500041',N'India',1,N'DAY_SCHOLAR',1),
      (112,312,1,1,1,6,12,N'ADM-2026-0112',N'R-02',N'Shobha',N'Saini','2015-05-01',N'FEMALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980112121',N'stu_1312@schoolname.edu',N'House 212, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500042',N'India',1,N'DAY_SCHOLAR',1),
      (113,313,1,1,1,6,12,N'ADM-2026-0113',N'R-03',N'Avni',N'Bedi','2015-12-12',N'FEMALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980113121',N'stu_1313@schoolname.edu',N'House 213, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500043',N'India',1,N'DAY_SCHOLAR',1),
      (114,314,1,1,1,6,12,N'ADM-2026-0114',N'R-04',N'Hema',N'Narayanan','2015-07-23',N'FEMALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980114121',N'stu_1314@schoolname.edu',N'House 214, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500044',N'India',1,N'DAY_SCHOLAR',1),
      (115,315,1,1,1,6,12,N'ADM-2026-0115',N'R-05',N'Rahul',N'Bhardwaj','2015-02-06',N'MALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980115121',N'stu_1315@schoolname.edu',N'House 215, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500045',N'India',1,N'HOSTELLER',1),
      (116,316,1,1,1,6,12,N'ADM-2026-0116',N'R-06',N'Naveen',N'Iyer','2015-09-17',N'MALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980116121',N'stu_1316@schoolname.edu',N'House 216, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500046',N'India',1,N'DAY_SCHOLAR',1),
      (117,317,1,1,1,6,12,N'ADM-2026-0117',N'R-07',N'Shaurya',N'Shukla','2015-04-28',N'MALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980117121',N'stu_1317@schoolname.edu',N'House 217, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500047',N'India',1,N'DAY_SCHOLAR',1),
      (118,318,1,1,1,6,12,N'ADM-2026-0118',N'R-08',N'Isha',N'Grewal','2015-11-11',N'FEMALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980118121',N'stu_1318@schoolname.edu',N'House 218, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500048',N'India',1,N'DAY_SCHOLAR',1),
      (119,319,1,1,1,6,12,N'ADM-2026-0119',N'R-09',N'Meenakshi',N'Singhal','2015-06-22',N'FEMALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980119121',N'stu_1319@schoolname.edu',N'House 219, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500049',N'India',1,N'DAY_SCHOLAR',1),
      (120,320,1,1,1,6,12,N'ADM-2026-0120',N'R-10',N'Hitesh',N'Walia','2015-01-05',N'MALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980120121',N'stu_1320@schoolname.edu',N'House 220, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500050',N'India',1,N'HOSTELLER',1),
      (121,321,1,1,1,7,13,N'ADM-2026-0121',N'R-01',N'Kusum',N'Grover','2014-08-16',N'FEMALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980121131',N'stu_1321@schoolname.edu',N'House 221, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500051',N'India',1,N'DAY_SCHOLAR',1),
      (122,322,1,1,1,7,13,N'ADM-2026-0122',N'R-02',N'Sai',N'Mukherjee','2014-03-27',N'MALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980122131',N'stu_1322@schoolname.edu',N'House 222, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500052',N'India',1,N'DAY_SCHOLAR',1),
      (123,323,1,1,1,7,13,N'ADM-2026-0123',N'R-03',N'Kavya',N'Tiwari','2014-10-10',N'FEMALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980123131',N'stu_1323@schoolname.edu',N'House 223, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500053',N'India',1,N'DAY_SCHOLAR',1),
      (124,324,1,1,1,7,13,N'ADM-2026-0124',N'R-04',N'Ekta',N'Venkatesh','2014-05-21',N'FEMALE',N'O-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980124131',N'stu_1324@schoolname.edu',N'House 224, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500054',N'India',1,N'DAY_SCHOLAR',1),
      (125,325,1,1,1,7,13,N'ADM-2026-0125',N'R-05',N'Deepak',N'Chaudhary','2014-12-04',N'MALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980125131',N'stu_1325@schoolname.edu',N'House 225, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500055',N'India',1,N'HOSTELLER',1),
      (126,326,1,1,1,7,13,N'ADM-2026-0126',N'R-06',N'Shankar',N'Hegde','2014-07-15',N'MALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980126131',N'stu_1326@schoolname.edu',N'House 226, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500056',N'India',1,N'DAY_SCHOLAR',1),
      (127,327,1,1,1,7,13,N'ADM-2026-0127',N'R-07',N'Amol',N'Venkataraman','2014-02-26',N'MALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980127131',N'stu_1327@schoolname.edu',N'House 227, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500057',N'India',1,N'DAY_SCHOLAR',1),
      (128,328,1,1,1,7,13,N'ADM-2026-0128',N'R-08',N'Hari',N'Malhotra','2014-09-09',N'MALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980128131',N'stu_1328@schoolname.edu',N'House 228, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500058',N'India',1,N'DAY_SCHOLAR',1),
      (129,329,1,1,1,7,13,N'ADM-2026-0129',N'R-09',N'Ritvik',N'Khanna','2014-04-20',N'MALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980129131',N'stu_1329@schoolname.edu',N'House 229, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500059',N'India',1,N'DAY_SCHOLAR',1),
      (130,330,1,1,1,7,13,N'ADM-2026-0130',N'R-10',N'Paavni',N'Mehta','2014-11-03',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980130131',N'stu_1330@schoolname.edu',N'House 230, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500060',N'India',1,N'HOSTELLER',1),
      (131,331,1,1,1,7,14,N'ADM-2026-0131',N'R-01',N'Karan',N'Kulshrestha','2014-06-14',N'MALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980131141',N'stu_1331@schoolname.edu',N'House 231, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500061',N'India',1,N'DAY_SCHOLAR',1),
      (132,332,1,1,1,7,14,N'ADM-2026-0132',N'R-02',N'Mridula',N'Patel','2014-01-25',N'FEMALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980132141',N'stu_1332@schoolname.edu',N'House 232, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500062',N'India',1,N'DAY_SCHOLAR',1),
      (133,333,1,1,1,7,14,N'ADM-2026-0133',N'R-03',N'Bindu',N'Uppal','2014-08-08',N'FEMALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980133141',N'stu_1333@schoolname.edu',N'House 233, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500063',N'India',1,N'DAY_SCHOLAR',1),
      (134,334,1,1,1,7,14,N'ADM-2026-0134',N'R-04',N'Sunil',N'Sandhu','2014-03-19',N'MALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980134141',N'stu_1334@schoolname.edu',N'House 234, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500064',N'India',1,N'DAY_SCHOLAR',1),
      (135,335,1,1,1,7,14,N'ADM-2026-0135',N'R-05',N'Pushpa',N'Upadhyay','2014-10-02',N'FEMALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980135141',N'stu_1335@schoolname.edu',N'House 235, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500065',N'India',1,N'HOSTELLER',1),
      (136,336,1,1,1,7,14,N'ADM-2026-0136',N'R-06',N'Riya',N'Bose','2014-05-13',N'FEMALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980136141',N'stu_1336@schoolname.edu',N'House 236, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500066',N'India',1,N'DAY_SCHOLAR',1),
      (137,337,1,1,1,7,14,N'ADM-2026-0137',N'R-07',N'Shivam',N'Pathak','2014-12-24',N'MALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980137141',N'stu_1337@schoolname.edu',N'House 237, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500067',N'India',1,N'DAY_SCHOLAR',1),
      (138,338,1,1,1,7,14,N'ADM-2026-0138',N'R-08',N'Sheetal',N'Ojha','2014-07-07',N'FEMALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980138141',N'stu_1338@schoolname.edu',N'House 238, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500068',N'India',1,N'DAY_SCHOLAR',1),
      (139,339,1,1,1,7,14,N'ADM-2026-0139',N'R-09',N'Atul',N'Ganguly','2014-02-18',N'MALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980139141',N'stu_1339@schoolname.edu',N'House 239, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500069',N'India',1,N'DAY_SCHOLAR',1),
      (140,340,1,1,1,7,14,N'ADM-2026-0140',N'R-10',N'Alaknanda',N'Bakshi','2014-09-01',N'FEMALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980140141',N'stu_1340@schoolname.edu',N'House 240, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500070',N'India',1,N'HOSTELLER',1),
      (141,341,1,1,1,8,15,N'ADM-2026-0141',N'R-01',N'Renu',N'Bhowmick','2013-04-12',N'FEMALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980141151',N'stu_1341@schoolname.edu',N'House 241, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500071',N'India',1,N'DAY_SCHOLAR',1),
      (142,342,1,1,1,8,15,N'ADM-2026-0142',N'R-02',N'Anand',N'Choudhury','2013-11-23',N'MALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980142151',N'stu_1342@schoolname.edu',N'House 242, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500072',N'India',1,N'DAY_SCHOLAR',1),
      (143,343,1,1,1,8,15,N'ADM-2026-0143',N'R-03',N'Gopichand',N'Deshmukh','2013-06-06',N'MALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980143151',N'stu_1343@schoolname.edu',N'House 243, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500073',N'India',1,N'DAY_SCHOLAR',1),
      (144,344,1,1,1,8,15,N'ADM-2026-0144',N'R-04',N'Yuvan',N'Bhatnagar','2013-01-17',N'MALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980144151',N'stu_1344@schoolname.edu',N'House 244, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500074',N'India',1,N'DAY_SCHOLAR',1),
      (145,345,1,1,1,8,15,N'ADM-2026-0145',N'R-05',N'Apsara',N'Raman','2013-08-28',N'FEMALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980145151',N'stu_1345@schoolname.edu',N'House 245, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500075',N'India',1,N'HOSTELLER',1),
      (146,346,1,1,1,8,15,N'ADM-2026-0146',N'R-06',N'Pallavi',N'Krishnan','2013-03-11',N'FEMALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980146151',N'stu_1346@schoolname.edu',N'House 246, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500076',N'India',1,N'DAY_SCHOLAR',1),
      (147,347,1,1,1,8,15,N'ADM-2026-0147',N'R-07',N'Anuj',N'Tripathi','2013-10-22',N'MALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980147151',N'stu_1347@schoolname.edu',N'House 247, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500077',N'India',1,N'DAY_SCHOLAR',1),
      (148,348,1,1,1,8,15,N'ADM-2026-0148',N'R-08',N'Ananya',N'Kumar','2013-05-05',N'FEMALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980148151',N'stu_1348@schoolname.edu',N'House 248, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500078',N'India',1,N'DAY_SCHOLAR',1),
      (149,349,1,1,1,8,15,N'ADM-2026-0149',N'R-09',N'Hemant',N'Bhattacharya','2013-12-16',N'MALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980149151',N'stu_1349@schoolname.edu',N'House 249, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500079',N'India',1,N'DAY_SCHOLAR',1),
      (150,350,1,1,1,8,15,N'ADM-2026-0150',N'R-10',N'Sushma',N'Walia','2013-07-27',N'FEMALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980150151',N'stu_1350@schoolname.edu',N'House 250, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500080',N'India',1,N'HOSTELLER',1),
      (151,351,1,1,1,8,16,N'ADM-2026-0151',N'R-01',N'Shashank',N'Shukla','2013-02-10',N'MALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980151161',N'stu_1351@schoolname.edu',N'House 251, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500081',N'India',1,N'DAY_SCHOLAR',1),
      (152,352,1,1,1,8,16,N'ADM-2026-0152',N'R-02',N'Aastha',N'Lamba','2013-09-21',N'FEMALE',N'O+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980152161',N'stu_1352@schoolname.edu',N'House 252, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500082',N'India',1,N'DAY_SCHOLAR',1),
      (153,353,1,1,1,8,16,N'ADM-2026-0153',N'R-03',N'Hardik',N'Kumar','2013-04-04',N'MALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980153161',N'stu_1353@schoolname.edu',N'House 253, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500083',N'India',1,N'DAY_SCHOLAR',1),
      (154,354,1,1,1,8,16,N'ADM-2026-0154',N'R-04',N'Ansh',N'Tiwari','2013-11-15',N'MALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980154161',N'stu_1354@schoolname.edu',N'House 254, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500084',N'India',1,N'DAY_SCHOLAR',1),
      (155,355,1,1,1,8,16,N'ADM-2026-0155',N'R-05',N'Sunder',N'Malik','2013-06-26',N'MALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980155161',N'stu_1355@schoolname.edu',N'House 255, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500085',N'India',1,N'HOSTELLER',1),
      (156,356,1,1,1,8,16,N'ADM-2026-0156',N'R-06',N'Zayan',N'Saini','2013-01-09',N'MALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980156161',N'stu_1356@schoolname.edu',N'House 256, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500086',N'India',1,N'DAY_SCHOLAR',1),
      (157,357,1,1,1,8,16,N'ADM-2026-0157',N'R-07',N'Myra',N'Ghosh','2013-08-20',N'FEMALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980157161',N'stu_1357@schoolname.edu',N'House 257, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500087',N'India',1,N'DAY_SCHOLAR',1),
      (158,358,1,1,1,8,16,N'ADM-2026-0158',N'R-08',N'Saurabh',N'Dutta','2013-03-03',N'MALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980158161',N'stu_1358@schoolname.edu',N'House 258, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500088',N'India',1,N'DAY_SCHOLAR',1),
      (159,359,1,1,1,8,16,N'ADM-2026-0159',N'R-09',N'Satish',N'Mukherjee','2013-10-14',N'MALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980159161',N'stu_1359@schoolname.edu',N'House 259, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500089',N'India',1,N'DAY_SCHOLAR',1),
      (160,360,1,1,1,8,16,N'ADM-2026-0160',N'R-10',N'Babita',N'Dutta','2013-05-25',N'FEMALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980160161',N'stu_1360@schoolname.edu',N'House 260, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500010',N'India',1,N'HOSTELLER',1),
      (161,361,1,1,1,9,17,N'ADM-2026-0161',N'R-01',N'Mansi',N'Viswanathan','2012-12-08',N'FEMALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980161171',N'stu_1361@schoolname.edu',N'House 261, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500011',N'India',1,N'DAY_SCHOLAR',1),
      (162,362,1,1,1,9,17,N'ADM-2026-0162',N'R-02',N'Aadhya',N'Reddy','2012-07-19',N'FEMALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980162171',N'stu_1362@schoolname.edu',N'House 262, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500012',N'India',1,N'DAY_SCHOLAR',1),
      (163,363,1,1,1,9,17,N'ADM-2026-0163',N'R-03',N'Madhu',N'Bhatia','2012-02-02',N'FEMALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980163171',N'stu_1363@schoolname.edu',N'House 263, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500013',N'India',1,N'DAY_SCHOLAR',1),
      (164,364,1,1,1,9,17,N'ADM-2026-0164',N'R-04',N'Aruna',N'Bhat','2012-09-13',N'FEMALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980164171',N'stu_1364@schoolname.edu',N'House 264, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500014',N'India',1,N'DAY_SCHOLAR',1),
      (165,365,1,1,1,9,17,N'ADM-2026-0165',N'R-05',N'Wahid',N'Chauhan','2012-04-24',N'MALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980165171',N'stu_1365@schoolname.edu',N'House 265, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500015',N'India',1,N'HOSTELLER',1),
      (166,366,1,1,1,9,17,N'ADM-2026-0166',N'R-06',N'Praveen',N'Raghavan','2012-11-07',N'MALE',N'O-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980166171',N'stu_1366@schoolname.edu',N'House 266, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500016',N'India',1,N'DAY_SCHOLAR',1),
      (167,367,1,1,1,9,17,N'ADM-2026-0167',N'R-07',N'Vivek',N'Kashyap','2012-06-18',N'MALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980167171',N'stu_1367@schoolname.edu',N'House 267, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500017',N'India',1,N'DAY_SCHOLAR',1),
      (168,368,1,1,1,9,17,N'ADM-2026-0168',N'R-08',N'Abhiram',N'Srinivasan','2012-01-01',N'MALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980168171',N'stu_1368@schoolname.edu',N'House 268, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500018',N'India',1,N'DAY_SCHOLAR',1),
      (169,369,1,1,1,9,17,N'ADM-2026-0169',N'R-09',N'Aayan',N'Menon','2012-08-12',N'MALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980169171',N'stu_1369@schoolname.edu',N'House 269, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500019',N'India',1,N'DAY_SCHOLAR',1),
      (170,370,1,1,1,9,17,N'ADM-2026-0170',N'R-10',N'Vijaya',N'Chawla','2012-03-23',N'FEMALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980170171',N'stu_1370@schoolname.edu',N'House 270, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500020',N'India',1,N'HOSTELLER',1),
      (171,371,1,1,1,9,18,N'ADM-2026-0171',N'R-01',N'Alok',N'Ganesan','2012-10-06',N'MALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980171181',N'stu_1371@schoolname.edu',N'House 271, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500021',N'India',1,N'DAY_SCHOLAR',1),
      (172,372,1,1,1,9,18,N'ADM-2026-0172',N'R-02',N'Pari',N'Sastry','2012-05-17',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980172181',N'stu_1372@schoolname.edu',N'House 272, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500022',N'India',1,N'DAY_SCHOLAR',1),
      (173,373,1,1,1,9,18,N'ADM-2026-0173',N'R-03',N'Archana',N'Sen','2012-12-28',N'FEMALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980173181',N'stu_1373@schoolname.edu',N'House 273, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500023',N'India',1,N'DAY_SCHOLAR',1),
      (174,374,1,1,1,9,18,N'ADM-2026-0174',N'R-04',N'Kabir',N'Bajwa','2012-07-11',N'MALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980174181',N'stu_1374@schoolname.edu',N'House 274, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500024',N'India',1,N'DAY_SCHOLAR',1),
      (175,375,1,1,1,9,18,N'ADM-2026-0175',N'R-05',N'Bimla',N'Viswanathan','2012-02-22',N'FEMALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980175181',N'stu_1375@schoolname.edu',N'House 275, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500025',N'India',1,N'HOSTELLER',1),
      (176,376,1,1,1,9,18,N'ADM-2026-0176',N'R-06',N'Yamini',N'Ghai','2012-09-05',N'FEMALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980176181',N'stu_1376@schoolname.edu',N'House 276, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500026',N'India',1,N'DAY_SCHOLAR',1),
      (177,377,1,1,1,9,18,N'ADM-2026-0177',N'R-07',N'Anupam',N'Sundaram','2012-04-16',N'MALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980177181',N'stu_1377@schoolname.edu',N'House 277, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500027',N'India',1,N'DAY_SCHOLAR',1),
      (178,378,1,1,1,9,18,N'ADM-2026-0178',N'R-08',N'Kalyani',N'Malhotra','2012-11-27',N'FEMALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980178181',N'stu_1378@schoolname.edu',N'House 278, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500028',N'India',1,N'DAY_SCHOLAR',1),
      (179,379,1,1,1,9,18,N'ADM-2026-0179',N'R-09',N'Sameer',N'Gupta','2012-06-10',N'MALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980179181',N'stu_1379@schoolname.edu',N'House 279, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500029',N'India',1,N'DAY_SCHOLAR',1),
      (180,380,1,1,1,9,18,N'ADM-2026-0180',N'R-10',N'Gargi',N'Chaudhary','2012-01-21',N'FEMALE',N'A+',N'Indian',N'English',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980180181',N'stu_1380@schoolname.edu',N'House 280, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500030',N'India',1,N'HOSTELLER',1),
      (181,381,1,1,1,10,19,N'ADM-2026-0181',N'R-01',N'Leela',N'Tandon','2011-08-04',N'FEMALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980181191',N'stu_1381@schoolname.edu',N'House 281, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500031',N'India',1,N'DAY_SCHOLAR',1),
      (182,382,1,1,1,10,19,N'ADM-2026-0182',N'R-02',N'Chandan',N'Swaminathan','2011-03-15',N'MALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980182191',N'stu_1382@schoolname.edu',N'House 282, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500032',N'India',1,N'DAY_SCHOLAR',1),
      (183,383,1,1,1,10,19,N'ADM-2026-0183',N'R-03',N'Deepa',N'Shukla','2011-10-26',N'FEMALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980183191',N'stu_1383@schoolname.edu',N'House 283, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500033',N'India',1,N'DAY_SCHOLAR',1),
      (184,384,1,1,1,10,19,N'ADM-2026-0184',N'R-04',N'Harini',N'Dhillon','2011-05-09',N'FEMALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980184191',N'stu_1384@schoolname.edu',N'House 284, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500034',N'India',1,N'DAY_SCHOLAR',1),
      (185,385,1,1,1,10,19,N'ADM-2026-0185',N'R-05',N'Ruchi',N'Deshmukh','2011-12-20',N'FEMALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980185191',N'stu_1385@schoolname.edu',N'House 285, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500035',N'India',1,N'HOSTELLER',1),
      (186,386,1,1,1,10,19,N'ADM-2026-0186',N'R-06',N'Tanish',N'Sodhi','2011-07-03',N'MALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980186191',N'stu_1386@schoolname.edu',N'House 286, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500036',N'India',1,N'DAY_SCHOLAR',1),
      (187,387,1,1,1,10,19,N'ADM-2026-0187',N'R-07',N'Himanshu',N'Narang','2011-02-14',N'MALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980187191',N'stu_1387@schoolname.edu',N'House 287, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500037',N'India',1,N'DAY_SCHOLAR',1),
      (188,388,1,1,1,10,19,N'ADM-2026-0188',N'R-08',N'Prem',N'Ananthakrishnan','2011-09-25',N'MALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980188191',N'stu_1388@schoolname.edu',N'House 288, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500038',N'India',1,N'DAY_SCHOLAR',1),
      (189,389,1,1,1,10,19,N'ADM-2026-0189',N'R-09',N'Ritu',N'Kumar','2011-04-08',N'FEMALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980189191',N'stu_1389@schoolname.edu',N'House 289, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500039',N'India',1,N'DAY_SCHOLAR',1),
      (190,390,1,1,1,10,19,N'ADM-2026-0190',N'R-10',N'Poorvi',N'Sastry','2011-11-19',N'FEMALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980190191',N'stu_1390@schoolname.edu',N'House 290, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500040',N'India',1,N'HOSTELLER',1),
      (191,391,1,1,1,10,20,N'ADM-2026-0191',N'R-01',N'Geetika',N'Solanki','2011-06-02',N'FEMALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980191201',N'stu_1391@schoolname.edu',N'House 291, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500041',N'India',1,N'DAY_SCHOLAR',1),
      (192,392,1,1,1,10,20,N'ADM-2026-0192',N'R-02',N'Vishal',N'Trehan','2011-01-13',N'MALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980192201',N'stu_1392@schoolname.edu',N'House 292, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500042',N'India',1,N'DAY_SCHOLAR',1),
      (193,393,1,1,1,10,20,N'ADM-2026-0193',N'R-03',N'Amrit',N'Shetty','2011-08-24',N'MALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980193201',N'stu_1393@schoolname.edu',N'House 293, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500043',N'India',1,N'DAY_SCHOLAR',1),
      (194,394,1,1,1,10,20,N'ADM-2026-0194',N'R-04',N'Sonia',N'Bedi','2011-03-07',N'FEMALE',N'O+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980194201',N'stu_1394@schoolname.edu',N'House 294, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500044',N'India',1,N'DAY_SCHOLAR',1),
      (195,395,1,1,1,10,20,N'ADM-2026-0195',N'R-05',N'Arpit',N'Vaidya','2011-10-18',N'MALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980195201',N'stu_1395@schoolname.edu',N'House 295, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500045',N'India',1,N'HOSTELLER',1),
      (196,396,1,1,1,10,20,N'ADM-2026-0196',N'R-06',N'Nisha',N'Prasad','2011-05-01',N'FEMALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980196201',N'stu_1396@schoolname.edu',N'House 296, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500046',N'India',1,N'DAY_SCHOLAR',1),
      (197,397,1,1,1,10,20,N'ADM-2026-0197',N'R-07',N'Shalini',N'Pandey','2011-12-12',N'FEMALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980197201',N'stu_1397@schoolname.edu',N'House 297, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500047',N'India',1,N'DAY_SCHOLAR',1),
      (198,398,1,1,1,10,20,N'ADM-2026-0198',N'R-08',N'Namrata',N'Trehan','2011-07-23',N'FEMALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980198201',N'stu_1398@schoolname.edu',N'House 298, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500048',N'India',1,N'DAY_SCHOLAR',1),
      (199,399,1,1,1,10,20,N'ADM-2026-0199',N'R-09',N'Roshni',N'Joshi','2011-02-06',N'FEMALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980199201',N'stu_1399@schoolname.edu',N'House 299, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500049',N'India',1,N'DAY_SCHOLAR',1),
      (200,400,1,1,1,10,20,N'ADM-2026-0200',N'R-10',N'Nidhi',N'Sachdeva','2011-09-17',N'FEMALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980200201',N'stu_1400@schoolname.edu',N'House 300, Green Park Avenue',N'Phase 2',N'Opposite Central Library',N'Hyderabad',N'Hyderabad',N'Telangana',N'500050',N'India',1,N'HOSTELLER',1),
      (201,401,1,2,1,11,21,N'ADM-2026-0201',N'R-01',N'Om',N'Ghosh','2020-04-28',N'MALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980201211',N'stu_1401@schoolname.edu',N'House 301, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500051',N'India',1,N'DAY_SCHOLAR',1),
      (202,402,1,2,1,11,21,N'ADM-2026-0202',N'R-02',N'Aparna',N'Das','2020-11-11',N'FEMALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980202211',N'stu_1402@schoolname.edu',N'House 302, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500052',N'India',1,N'DAY_SCHOLAR',1),
      (203,403,1,2,1,11,21,N'ADM-2026-0203',N'R-03',N'Jiya',N'Sanyal','2020-06-22',N'FEMALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980203211',N'stu_1403@schoolname.edu',N'House 303, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500053',N'India',1,N'DAY_SCHOLAR',1),
      (204,404,1,2,1,11,21,N'ADM-2026-0204',N'R-04',N'Charvi',N'Srinivasan','2020-01-05',N'FEMALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980204211',N'stu_1404@schoolname.edu',N'House 304, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500054',N'India',1,N'DAY_SCHOLAR',1),
      (205,405,1,2,1,11,21,N'ADM-2026-0205',N'R-05',N'Farhan',N'Sethi','2020-08-16',N'MALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980205211',N'stu_1405@schoolname.edu',N'House 305, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500055',N'India',1,N'HOSTELLER',1),
      (206,406,1,2,1,11,21,N'ADM-2026-0206',N'R-06',N'Rohan',N'Vaidya','2020-03-27',N'MALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980206211',N'stu_1406@schoolname.edu',N'House 306, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500056',N'India',1,N'DAY_SCHOLAR',1),
      (207,407,1,2,1,11,21,N'ADM-2026-0207',N'R-07',N'Anaya',N'Shetty','2020-10-10',N'FEMALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980207211',N'stu_1407@schoolname.edu',N'House 307, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500057',N'India',1,N'DAY_SCHOLAR',1),
      (208,408,1,2,1,11,21,N'ADM-2026-0208',N'R-08',N'Kunal',N'Mahajan','2020-05-21',N'MALE',N'O-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980208211',N'stu_1408@schoolname.edu',N'House 308, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500058',N'India',1,N'DAY_SCHOLAR',1),
      (209,409,1,2,1,11,21,N'ADM-2026-0209',N'R-09',N'Vinay',N'Khatri','2020-12-04',N'MALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980209211',N'stu_1409@schoolname.edu',N'House 309, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500059',N'India',1,N'DAY_SCHOLAR',1),
      (210,410,1,2,1,11,21,N'ADM-2026-0210',N'R-10',N'Ahana',N'Pandey','2020-07-15',N'FEMALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980210211',N'stu_1410@schoolname.edu',N'House 310, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500060',N'India',1,N'HOSTELLER',1),
      (211,411,1,2,1,11,22,N'ADM-2026-0211',N'R-01',N'Sanya',N'Goel','2020-02-26',N'FEMALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980211221',N'stu_1411@schoolname.edu',N'House 311, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500061',N'India',1,N'DAY_SCHOLAR',1),
      (212,412,1,2,1,11,22,N'ADM-2026-0212',N'R-02',N'Jaspreet',N'Pai','2020-09-09',N'MALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980212221',N'stu_1412@schoolname.edu',N'House 312, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500062',N'India',1,N'DAY_SCHOLAR',1),
      (213,413,1,2,1,11,22,N'ADM-2026-0213',N'R-03',N'Juhi',N'Chopra','2020-04-20',N'FEMALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980213221',N'stu_1413@schoolname.edu',N'House 313, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500063',N'India',1,N'DAY_SCHOLAR',1),
      (214,414,1,2,1,11,22,N'ADM-2026-0214',N'R-04',N'Manju',N'Nigam','2020-11-03',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980214221',N'stu_1414@schoolname.edu',N'House 314, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500064',N'India',1,N'DAY_SCHOLAR',1),
      (215,415,1,2,1,11,22,N'ADM-2026-0215',N'R-05',N'Dhruv',N'Sandhu','2020-06-14',N'MALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980215221',N'stu_1415@schoolname.edu',N'House 315, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500065',N'India',1,N'HOSTELLER',1),
      (216,416,1,2,1,11,22,N'ADM-2026-0216',N'R-06',N'Sara',N'Nambiar','2020-01-25',N'FEMALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980216221',N'stu_1416@schoolname.edu',N'House 316, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500066',N'India',1,N'DAY_SCHOLAR',1),
      (217,417,1,2,1,11,22,N'ADM-2026-0217',N'R-07',N'Mukul',N'Lamba','2020-08-08',N'MALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980217221',N'stu_1417@schoolname.edu',N'House 317, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500067',N'India',1,N'DAY_SCHOLAR',1),
      (218,418,1,2,1,11,22,N'ADM-2026-0218',N'R-08',N'Chinmay',N'Reddy','2020-03-19',N'MALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980218221',N'stu_1418@schoolname.edu',N'House 318, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500068',N'India',1,N'DAY_SCHOLAR',1),
      (219,419,1,2,1,11,22,N'ADM-2026-0219',N'R-09',N'Aniket',N'Anand','2020-10-02',N'MALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980219221',N'stu_1419@schoolname.edu',N'House 319, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500069',N'India',1,N'DAY_SCHOLAR',1),
      (220,420,1,2,1,11,22,N'ADM-2026-0220',N'R-10',N'Darsh',N'Grover','2020-05-13',N'MALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980220221',N'stu_1420@schoolname.edu',N'House 320, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500070',N'India',1,N'HOSTELLER',1),
      (221,421,1,2,1,12,23,N'ADM-2026-0221',N'R-01',N'Sarvesh',N'Bhat','2019-12-24',N'MALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980221231',N'stu_1421@schoolname.edu',N'House 321, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500071',N'India',1,N'DAY_SCHOLAR',1),
      (222,422,1,2,1,12,23,N'ADM-2026-0222',N'R-02',N'Tanya',N'Mathur','2019-07-07',N'FEMALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980222231',N'stu_1422@schoolname.edu',N'House 322, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500072',N'India',1,N'DAY_SCHOLAR',1),
      (223,423,1,2,1,12,23,N'ADM-2026-0223',N'R-03',N'Pranav',N'Solanki','2019-02-18',N'MALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980223231',N'stu_1423@schoolname.edu',N'House 323, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500073',N'India',1,N'DAY_SCHOLAR',1),
      (224,424,1,2,1,12,23,N'ADM-2026-0224',N'R-04',N'Yuvraj',N'Parmar','2019-09-01',N'MALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980224231',N'stu_1424@schoolname.edu',N'House 324, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500074',N'India',1,N'DAY_SCHOLAR',1),
      (225,425,1,2,1,12,23,N'ADM-2026-0225',N'R-05',N'Madhuri',N'Dwivedi','2019-04-12',N'FEMALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980225231',N'stu_1425@schoolname.edu',N'House 325, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500075',N'India',1,N'HOSTELLER',1),
      (226,426,1,2,1,12,23,N'ADM-2026-0226',N'R-06',N'Diya',N'Chatterjee','2019-11-23',N'FEMALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980226231',N'stu_1426@schoolname.edu',N'House 326, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500076',N'India',1,N'DAY_SCHOLAR',1),
      (227,427,1,2,1,12,23,N'ADM-2026-0227',N'R-07',N'Prisha',N'Ojha','2019-06-06',N'FEMALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980227231',N'stu_1427@schoolname.edu',N'House 327, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500077',N'India',1,N'DAY_SCHOLAR',1),
      (228,428,1,2,1,12,23,N'ADM-2026-0228',N'R-08',N'Siya',N'Asthana','2019-01-17',N'FEMALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980228231',N'stu_1428@schoolname.edu',N'House 328, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500078',N'India',1,N'DAY_SCHOLAR',1),
      (229,429,1,2,1,12,23,N'ADM-2026-0229',N'R-09',N'Jagdish',N'Sanyal','2019-08-28',N'MALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980229231',N'stu_1429@schoolname.edu',N'House 329, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500079',N'India',1,N'DAY_SCHOLAR',1),
      (230,430,1,2,1,12,23,N'ADM-2026-0230',N'R-10',N'Geeta',N'Thakur','2019-03-11',N'FEMALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980230231',N'stu_1430@schoolname.edu',N'House 330, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500080',N'India',1,N'HOSTELLER',1),
      (231,431,1,2,1,12,24,N'ADM-2026-0231',N'R-01',N'Reyansh',N'Sen','2019-10-22',N'MALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980231241',N'stu_1431@schoolname.edu',N'House 331, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500081',N'India',1,N'DAY_SCHOLAR',1),
      (232,432,1,2,1,12,24,N'ADM-2026-0232',N'R-02',N'Laxmi',N'Anand','2019-05-05',N'FEMALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980232241',N'stu_1432@schoolname.edu',N'House 332, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500082',N'India',1,N'DAY_SCHOLAR',1),
      (233,433,1,2,1,12,24,N'ADM-2026-0233',N'R-03',N'Veer',N'Subramanian','2019-12-16',N'MALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980233241',N'stu_1433@schoolname.edu',N'House 333, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500083',N'India',1,N'DAY_SCHOLAR',1),
      (234,434,1,2,1,12,24,N'ADM-2026-0234',N'R-04',N'Subhash',N'Thakur','2019-07-27',N'MALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980234241',N'stu_1434@schoolname.edu',N'House 334, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500084',N'India',1,N'DAY_SCHOLAR',1),
      (235,435,1,2,1,12,24,N'ADM-2026-0235',N'R-05',N'Aarav',N'Varma','2019-02-10',N'MALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980235241',N'stu_1435@schoolname.edu',N'House 335, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500085',N'India',1,N'HOSTELLER',1),
      (236,436,1,2,1,12,24,N'ADM-2026-0236',N'R-06',N'Ira',N'Iyer','2019-09-21',N'FEMALE',N'O+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980236241',N'stu_1436@schoolname.edu',N'House 336, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500086',N'India',1,N'DAY_SCHOLAR',1),
      (237,437,1,2,1,12,24,N'ADM-2026-0237',N'R-07',N'Rekha',N'Majumdar','2019-04-04',N'FEMALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980237241',N'stu_1437@schoolname.edu',N'House 337, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500087',N'India',1,N'DAY_SCHOLAR',1),
      (238,438,1,2,1,12,24,N'ADM-2026-0238',N'R-08',N'Komal',N'Khanna','2019-11-15',N'FEMALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980238241',N'stu_1438@schoolname.edu',N'House 338, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500088',N'India',1,N'DAY_SCHOLAR',1),
      (239,439,1,2,1,12,24,N'ADM-2026-0239',N'R-09',N'Navneet',N'Ojha','2019-06-26',N'MALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980239241',N'stu_1439@schoolname.edu',N'House 339, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500089',N'India',1,N'DAY_SCHOLAR',1),
      (240,440,1,2,1,12,24,N'ADM-2026-0240',N'R-10',N'Kanchan',N'Sandhu','2019-01-09',N'FEMALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980240241',N'stu_1440@schoolname.edu',N'House 340, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500010',N'India',1,N'HOSTELLER',1),
      (241,441,1,2,1,13,25,N'ADM-2026-0241',N'R-01',N'Tanmay',N'Upadhyay','2018-08-20',N'MALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980241251',N'stu_1441@schoolname.edu',N'House 341, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500011',N'India',1,N'DAY_SCHOLAR',1),
      (242,442,1,2,1,13,25,N'ADM-2026-0242',N'R-02',N'Payal',N'Srivastava','2018-03-03',N'FEMALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980242251',N'stu_1442@schoolname.edu',N'House 342, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500012',N'India',1,N'DAY_SCHOLAR',1),
      (243,443,1,2,1,13,25,N'ADM-2026-0243',N'R-03',N'Mahesh',N'Singh','2018-10-14',N'MALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980243251',N'stu_1443@schoolname.edu',N'House 343, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500013',N'India',1,N'DAY_SCHOLAR',1),
      (244,444,1,2,1,13,25,N'ADM-2026-0244',N'R-04',N'Madhav',N'Sundaram','2018-05-25',N'MALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980244251',N'stu_1444@schoolname.edu',N'House 344, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500014',N'India',1,N'DAY_SCHOLAR',1),
      (245,445,1,2,1,13,25,N'ADM-2026-0245',N'R-05',N'Keshav',N'Joshi','2018-12-08',N'MALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980245251',N'stu_1445@schoolname.edu',N'House 345, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500015',N'India',1,N'HOSTELLER',1),
      (246,446,1,2,1,13,25,N'ADM-2026-0246',N'R-06',N'Sumit',N'Yadav','2018-07-19',N'MALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980246251',N'stu_1446@schoolname.edu',N'House 346, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500016',N'India',1,N'DAY_SCHOLAR',1),
      (247,447,1,2,1,13,25,N'ADM-2026-0247',N'R-07',N'Urvi',N'Roy','2018-02-02',N'FEMALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980247251',N'stu_1447@schoolname.edu',N'House 347, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500017',N'India',1,N'DAY_SCHOLAR',1),
      (248,448,1,2,1,13,25,N'ADM-2026-0248',N'R-08',N'Vaibhav',N'Saxena','2018-09-13',N'MALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980248251',N'stu_1448@schoolname.edu',N'House 348, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500018',N'India',1,N'DAY_SCHOLAR',1),
      (249,449,1,2,1,13,25,N'ADM-2026-0249',N'R-09',N'Anaya',N'Saini','2018-04-24',N'FEMALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980249251',N'stu_1449@schoolname.edu',N'House 349, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500019',N'India',1,N'DAY_SCHOLAR',1),
      (250,450,1,2,1,13,25,N'ADM-2026-0250',N'R-10',N'Ojas',N'Chawla','2018-11-07',N'MALE',N'O-',N'Indian',N'English',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980250251',N'stu_1450@schoolname.edu',N'House 350, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500020',N'India',1,N'HOSTELLER',1),
      (251,451,1,2,1,13,26,N'ADM-2026-0251',N'R-01',N'Surya',N'Grover','2018-06-18',N'MALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980251261',N'stu_1451@schoolname.edu',N'House 351, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500021',N'India',1,N'DAY_SCHOLAR',1),
      (252,452,1,2,1,13,26,N'ADM-2026-0252',N'R-02',N'Damini',N'Rajput','2018-01-01',N'FEMALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980252261',N'stu_1452@schoolname.edu',N'House 352, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500022',N'India',1,N'DAY_SCHOLAR',1),
      (253,453,1,2,1,13,26,N'ADM-2026-0253',N'R-03',N'Krrish',N'Singhal','2018-08-12',N'MALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980253261',N'stu_1453@schoolname.edu',N'House 353, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500023',N'India',1,N'DAY_SCHOLAR',1),
      (254,454,1,2,1,13,26,N'ADM-2026-0254',N'R-04',N'Shreya',N'Gowda','2018-03-23',N'FEMALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980254261',N'stu_1454@schoolname.edu',N'House 354, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500024',N'India',1,N'DAY_SCHOLAR',1),
      (255,455,1,2,1,13,26,N'ADM-2026-0255',N'R-05',N'Prakash',N'Balakrishnan','2018-10-06',N'MALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980255261',N'stu_1455@schoolname.edu',N'House 355, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500025',N'India',1,N'HOSTELLER',1),
      (256,456,1,2,1,13,26,N'ADM-2026-0256',N'R-06',N'Ishwar',N'Goswami','2018-05-17',N'MALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980256261',N'stu_1456@schoolname.edu',N'House 356, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500026',N'India',1,N'DAY_SCHOLAR',1),
      (257,457,1,2,1,13,26,N'ADM-2026-0257',N'R-07',N'Yashvi',N'Choudhury','2018-12-28',N'FEMALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980257261',N'stu_1457@schoolname.edu',N'House 357, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500027',N'India',1,N'DAY_SCHOLAR',1),
      (258,458,1,2,1,13,26,N'ADM-2026-0258',N'R-08',N'Karuna',N'Bhardwaj','2018-07-11',N'FEMALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980258261',N'stu_1458@schoolname.edu',N'House 358, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500028',N'India',1,N'DAY_SCHOLAR',1),
      (259,459,1,2,1,13,26,N'ADM-2026-0259',N'R-09',N'Vihaan',N'Gupta','2018-02-22',N'MALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980259261',N'stu_1459@schoolname.edu',N'House 359, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500029',N'India',1,N'DAY_SCHOLAR',1),
      (260,460,1,2,1,13,26,N'ADM-2026-0260',N'R-10',N'Neelam',N'Madan','2018-09-05',N'FEMALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980260261',N'stu_1460@schoolname.edu',N'House 360, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500030',N'India',1,N'HOSTELLER',1),
      (261,461,1,2,1,14,27,N'ADM-2026-0261',N'R-01',N'Tarun',N'Gowda','2017-04-16',N'MALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980261271',N'stu_1461@schoolname.edu',N'House 361, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500031',N'India',1,N'DAY_SCHOLAR',1),
      (262,462,1,2,1,14,27,N'ADM-2026-0262',N'R-02',N'Riddhi',N'Walia','2017-11-27',N'FEMALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980262271',N'stu_1462@schoolname.edu',N'House 362, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500032',N'India',1,N'DAY_SCHOLAR',1),
      (263,463,1,2,1,14,27,N'ADM-2026-0263',N'R-03',N'Richa',N'Reddy','2017-06-10',N'FEMALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980263271',N'stu_1463@schoolname.edu',N'House 363, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500033',N'India',1,N'DAY_SCHOLAR',1),
      (264,464,1,2,1,14,27,N'ADM-2026-0264',N'R-04',N'Avni',N'Tripathi','2017-01-21',N'FEMALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980264271',N'stu_1464@schoolname.edu',N'House 364, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500034',N'India',1,N'DAY_SCHOLAR',1),
      (265,465,1,2,1,14,27,N'ADM-2026-0265',N'R-05',N'Suman',N'Sethi','2017-08-04',N'FEMALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980265271',N'stu_1465@schoolname.edu',N'House 365, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500035',N'India',1,N'HOSTELLER',1),
      (266,466,1,2,1,14,27,N'ADM-2026-0266',N'R-06',N'Meena',N'Mittal','2017-03-15',N'FEMALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980266271',N'stu_1466@schoolname.edu',N'House 366, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500036',N'India',1,N'DAY_SCHOLAR',1),
      (267,467,1,2,1,14,27,N'ADM-2026-0267',N'R-07',N'Utkarsh',N'Dubey','2017-10-26',N'MALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980267271',N'stu_1467@schoolname.edu',N'House 367, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500037',N'India',1,N'DAY_SCHOLAR',1),
      (268,468,1,2,1,14,27,N'ADM-2026-0268',N'R-08',N'Muhammad',N'Bhat','2017-05-09',N'MALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980268271',N'stu_1468@schoolname.edu',N'House 368, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500038',N'India',1,N'DAY_SCHOLAR',1),
      (269,469,1,2,1,14,27,N'ADM-2026-0269',N'R-09',N'Pradeep',N'Venkatesh','2017-12-20',N'MALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980269271',N'stu_1469@schoolname.edu',N'House 369, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500039',N'India',1,N'DAY_SCHOLAR',1),
      (270,470,1,2,1,14,27,N'ADM-2026-0270',N'R-10',N'Vidhi',N'Swaminathan','2017-07-03',N'FEMALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980270271',N'stu_1470@schoolname.edu',N'House 370, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500040',N'India',1,N'HOSTELLER',1),
      (271,471,1,2,1,14,28,N'ADM-2026-0271',N'R-01',N'Inderjit',N'Nambiar','2017-02-14',N'MALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980271281',N'stu_1471@schoolname.edu',N'House 371, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500041',N'India',1,N'DAY_SCHOLAR',1),
      (272,472,1,2,1,14,28,N'ADM-2026-0272',N'R-02',N'Kuldeep',N'Pandey','2017-09-25',N'MALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980272281',N'stu_1472@schoolname.edu',N'House 372, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500042',N'India',1,N'DAY_SCHOLAR',1),
      (273,473,1,2,1,14,28,N'ADM-2026-0273',N'R-03',N'Tejas',N'Madan','2017-04-08',N'MALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980273281',N'stu_1473@schoolname.edu',N'House 373, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500043',N'India',1,N'DAY_SCHOLAR',1),
      (274,474,1,2,1,14,28,N'ADM-2026-0274',N'R-04',N'Sunita',N'Kohli','2017-11-19',N'FEMALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980274281',N'stu_1474@schoolname.edu',N'House 374, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500044',N'India',1,N'DAY_SCHOLAR',1),
      (275,475,1,2,1,14,28,N'ADM-2026-0275',N'R-05',N'Swati',N'Mathur','2017-06-02',N'FEMALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980275281',N'stu_1475@schoolname.edu',N'House 375, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500045',N'India',1,N'HOSTELLER',1),
      (276,476,1,2,1,14,28,N'ADM-2026-0276',N'R-06',N'Raghunath',N'Mehra','2017-01-13',N'MALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980276281',N'stu_1476@schoolname.edu',N'House 376, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500046',N'India',1,N'DAY_SCHOLAR',1),
      (277,477,1,2,1,14,28,N'ADM-2026-0277',N'R-07',N'Raghav',N'Pai','2017-08-24',N'MALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980277281',N'stu_1477@schoolname.edu',N'House 377, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500047',N'India',1,N'DAY_SCHOLAR',1),
      (278,478,1,2,1,14,28,N'ADM-2026-0278',N'R-08',N'Manan',N'Nigam','2017-03-07',N'MALE',N'O+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980278281',N'stu_1478@schoolname.edu',N'House 378, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500048',N'India',1,N'DAY_SCHOLAR',1),
      (279,479,1,2,1,14,28,N'ADM-2026-0279',N'R-09',N'Daksh',N'Bhowmick','2017-10-18',N'MALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980279281',N'stu_1479@schoolname.edu',N'House 379, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500049',N'India',1,N'DAY_SCHOLAR',1),
      (280,480,1,2,1,14,28,N'ADM-2026-0280',N'R-10',N'Sanjana',N'Banerjee','2017-05-01',N'FEMALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980280281',N'stu_1480@schoolname.edu',N'House 380, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500050',N'India',1,N'HOSTELLER',1),
      (281,481,1,2,1,15,29,N'ADM-2026-0281',N'R-01',N'Chetna',N'Rathore','2016-12-12',N'FEMALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980281291',N'stu_1481@schoolname.edu',N'House 381, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500051',N'India',1,N'DAY_SCHOLAR',1),
      (282,482,1,2,1,15,29,N'ADM-2026-0282',N'R-02',N'Indrajit',N'Mathur','2016-07-23',N'MALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980282291',N'stu_1482@schoolname.edu',N'House 382, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500052',N'India',1,N'DAY_SCHOLAR',1),
      (283,483,1,2,1,15,29,N'ADM-2026-0283',N'R-03',N'Anvi',N'Kulkarni','2016-02-06',N'FEMALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980283291',N'stu_1483@schoolname.edu',N'House 383, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500053',N'India',1,N'DAY_SCHOLAR',1),
      (284,484,1,2,1,15,29,N'ADM-2026-0284',N'R-04',N'Rani',N'Ganguly','2016-09-17',N'FEMALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980284291',N'stu_1484@schoolname.edu',N'House 384, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500054',N'India',1,N'DAY_SCHOLAR',1),
      (285,485,1,2,1,15,29,N'ADM-2026-0285',N'R-05',N'Navya',N'Deshmukh','2016-04-28',N'FEMALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980285291',N'stu_1485@schoolname.edu',N'House 385, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500055',N'India',1,N'HOSTELLER',1),
      (286,486,1,2,1,15,29,N'ADM-2026-0286',N'R-06',N'Sneha',N'Kapoor','2016-11-11',N'FEMALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980286291',N'stu_1486@schoolname.edu',N'House 386, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500056',N'India',1,N'DAY_SCHOLAR',1),
      (287,487,1,2,1,15,29,N'ADM-2026-0287',N'R-07',N'Rajiv',N'Gautam','2016-06-22',N'MALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980287291',N'stu_1487@schoolname.edu',N'House 387, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500057',N'India',1,N'DAY_SCHOLAR',1),
      (288,488,1,2,1,15,29,N'ADM-2026-0288',N'R-08',N'Vandana',N'Talwar','2016-01-05',N'FEMALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980288291',N'stu_1488@schoolname.edu',N'House 388, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500058',N'India',1,N'DAY_SCHOLAR',1),
      (289,489,1,2,1,15,29,N'ADM-2026-0289',N'R-09',N'Anuradha',N'Subramanian','2016-08-16',N'FEMALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980289291',N'stu_1489@schoolname.edu',N'House 389, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500059',N'India',1,N'DAY_SCHOLAR',1),
      (290,490,1,2,1,15,29,N'ADM-2026-0290',N'R-10',N'Nitin',N'Munjal','2016-03-27',N'MALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980290291',N'stu_1490@schoolname.edu',N'House 390, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500060',N'India',1,N'HOSTELLER',1),
      (291,491,1,2,1,15,30,N'ADM-2026-0291',N'R-01',N'Prisha',N'Banerjee','2016-10-10',N'FEMALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980291301',N'stu_1491@schoolname.edu',N'House 391, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500061',N'India',1,N'DAY_SCHOLAR',1),
      (292,492,1,2,1,15,30,N'ADM-2026-0292',N'R-02',N'Sapna',N'Nambiar','2016-05-21',N'FEMALE',N'O-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980292301',N'stu_1492@schoolname.edu',N'House 392, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500062',N'India',1,N'DAY_SCHOLAR',1),
      (293,493,1,2,1,15,30,N'ADM-2026-0293',N'R-03',N'Lokesh',N'Garg','2016-12-04',N'MALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980293301',N'stu_1493@schoolname.edu',N'House 393, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500063',N'India',1,N'DAY_SCHOLAR',1),
      (294,494,1,2,1,15,30,N'ADM-2026-0294',N'R-04',N'Samiksha',N'Raju','2016-07-15',N'FEMALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980294301',N'stu_1494@schoolname.edu',N'House 394, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500064',N'India',1,N'DAY_SCHOLAR',1),
      (295,495,1,2,1,15,30,N'ADM-2026-0295',N'R-05',N'Pari',N'Nair','2016-02-26',N'FEMALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980295301',N'stu_1495@schoolname.edu',N'House 395, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500065',N'India',1,N'HOSTELLER',1),
      (296,496,1,2,1,15,30,N'ADM-2026-0296',N'R-06',N'Veda',N'Shetty','2016-09-09',N'FEMALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980296301',N'stu_1496@schoolname.edu',N'House 396, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500066',N'India',1,N'DAY_SCHOLAR',1),
      (297,497,1,2,1,15,30,N'ADM-2026-0297',N'R-07',N'Asha',N'Mukherjee','2016-04-20',N'FEMALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980297301',N'stu_1497@schoolname.edu',N'House 397, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500067',N'India',1,N'DAY_SCHOLAR',1),
      (298,498,1,2,1,15,30,N'ADM-2026-0298',N'R-08',N'Chhaya',N'Mishra','2016-11-03',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980298301',N'stu_1498@schoolname.edu',N'House 398, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500068',N'India',1,N'DAY_SCHOLAR',1),
      (299,499,1,2,1,15,30,N'ADM-2026-0299',N'R-09',N'Pooja',N'Chakraborty','2016-06-14',N'FEMALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980299301',N'stu_1499@schoolname.edu',N'House 399, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500069',N'India',1,N'DAY_SCHOLAR',1),
      (300,500,1,2,1,15,30,N'ADM-2026-0300',N'R-10',N'Bharat',N'Rajput','2016-01-25',N'MALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980300301',N'stu_1500@schoolname.edu',N'House 400, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500070',N'India',1,N'HOSTELLER',1),
      (301,501,1,2,1,16,31,N'ADM-2026-0301',N'R-01',N'Rishabh',N'Kashyap','2015-08-08',N'MALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980301311',N'stu_1501@schoolname.edu',N'House 401, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500071',N'India',1,N'DAY_SCHOLAR',1),
      (302,502,1,2,1,16,31,N'ADM-2026-0302',N'R-02',N'Ramesh',N'Chakraborty','2015-03-19',N'MALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980302311',N'stu_1502@schoolname.edu',N'House 402, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500072',N'India',1,N'DAY_SCHOLAR',1),
      (303,503,1,2,1,16,31,N'ADM-2026-0303',N'R-03',N'Angel',N'Pillai','2015-10-02',N'FEMALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980303311',N'stu_1503@schoolname.edu',N'House 403, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500073',N'India',1,N'DAY_SCHOLAR',1),
      (304,504,1,2,1,16,31,N'ADM-2026-0304',N'R-04',N'Swapnil',N'Anand','2015-05-13',N'MALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980304311',N'stu_1504@schoolname.edu',N'House 404, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500074',N'India',1,N'DAY_SCHOLAR',1),
      (305,505,1,2,1,16,31,N'ADM-2026-0305',N'R-05',N'Anika',N'Bhattacharya','2015-12-24',N'FEMALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980305311',N'stu_1505@schoolname.edu',N'House 405, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500075',N'India',1,N'HOSTELLER',1),
      (306,506,1,2,1,16,31,N'ADM-2026-0306',N'R-06',N'Kamal',N'Srivastava','2015-07-07',N'MALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980306311',N'stu_1506@schoolname.edu',N'House 406, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500076',N'India',1,N'DAY_SCHOLAR',1),
      (307,507,1,2,1,16,31,N'ADM-2026-0307',N'R-07',N'Dev',N'Khatri','2015-02-18',N'MALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980307311',N'stu_1507@schoolname.edu',N'House 407, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500077',N'India',1,N'DAY_SCHOLAR',1),
      (308,508,1,2,1,16,31,N'ADM-2026-0308',N'R-08',N'Vikas',N'Mittal','2015-09-01',N'MALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980308311',N'stu_1508@schoolname.edu',N'House 408, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500078',N'India',1,N'DAY_SCHOLAR',1),
      (309,509,1,2,1,16,31,N'ADM-2026-0309',N'R-09',N'Vibhuti',N'Suri','2015-04-12',N'FEMALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980309311',N'stu_1509@schoolname.edu',N'House 409, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500079',N'India',1,N'DAY_SCHOLAR',1),
      (310,510,1,2,1,16,31,N'ADM-2026-0310',N'R-10',N'Jaya',N'Ananthakrishnan','2015-11-23',N'FEMALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980310311',N'stu_1510@schoolname.edu',N'House 410, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500080',N'India',1,N'HOSTELLER',1),
      (311,511,1,2,1,16,32,N'ADM-2026-0311',N'R-01',N'Ravi',N'Majumdar','2015-06-06',N'MALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980311321',N'stu_1511@schoolname.edu',N'House 411, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500081',N'India',1,N'DAY_SCHOLAR',1),
      (312,512,1,2,1,16,32,N'ADM-2026-0312',N'R-02',N'Sneha',N'Jha','2015-01-17',N'FEMALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980312321',N'stu_1512@schoolname.edu',N'House 412, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500082',N'India',1,N'DAY_SCHOLAR',1),
      (313,513,1,2,1,16,32,N'ADM-2026-0313',N'R-03',N'Kashvi',N'Raman','2015-08-28',N'FEMALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980313321',N'stu_1513@schoolname.edu',N'House 413, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500083',N'India',1,N'DAY_SCHOLAR',1),
      (314,514,1,2,1,16,32,N'ADM-2026-0314',N'R-04',N'Nalini',N'Sodhi','2015-03-11',N'FEMALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980314321',N'stu_1514@schoolname.edu',N'House 414, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500084',N'India',1,N'DAY_SCHOLAR',1),
      (315,515,1,2,1,16,32,N'ADM-2026-0315',N'R-05',N'Aarohi',N'Roy','2015-10-22',N'FEMALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980315321',N'stu_1515@schoolname.edu',N'House 415, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500085',N'India',1,N'HOSTELLER',1),
      (316,516,1,2,1,16,32,N'ADM-2026-0316',N'R-06',N'Tripti',N'Bansal','2015-05-05',N'FEMALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980316321',N'stu_1516@schoolname.edu',N'House 416, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500086',N'India',1,N'DAY_SCHOLAR',1),
      (317,517,1,2,1,16,32,N'ADM-2026-0317',N'R-07',N'Dinesh',N'Vashist','2015-12-16',N'MALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980317321',N'stu_1517@schoolname.edu',N'House 417, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500087',N'India',1,N'DAY_SCHOLAR',1),
      (318,518,1,2,1,16,32,N'ADM-2026-0318',N'R-08',N'Kiran',N'Bajwa','2015-07-27',N'FEMALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980318321',N'stu_1518@schoolname.edu',N'House 418, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500088',N'India',1,N'DAY_SCHOLAR',1),
      (319,519,1,2,1,16,32,N'ADM-2026-0319',N'R-09',N'Siddharth',N'Krishnan','2015-02-10',N'MALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980319321',N'stu_1519@schoolname.edu',N'House 419, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500089',N'India',1,N'DAY_SCHOLAR',1),
      (320,520,1,2,1,16,32,N'ADM-2026-0320',N'R-10',N'Raman',N'Somayaji','2015-09-21',N'MALE',N'O+',N'Indian',N'English',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980320321',N'stu_1520@schoolname.edu',N'House 420, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500010',N'India',1,N'HOSTELLER',1),
      (321,521,1,2,1,17,33,N'ADM-2026-0321',N'R-01',N'Avinash',N'Rathore','2014-04-04',N'MALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980321331',N'stu_1521@schoolname.edu',N'House 421, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500011',N'India',1,N'DAY_SCHOLAR',1),
      (322,522,1,2,1,17,33,N'ADM-2026-0322',N'R-02',N'Apoorv',N'Upadhyay','2014-11-15',N'MALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980322331',N'stu_1522@schoolname.edu',N'House 422, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500012',N'India',1,N'DAY_SCHOLAR',1),
      (323,523,1,2,1,17,33,N'ADM-2026-0323',N'R-03',N'Divyansh',N'Nair','2014-06-26',N'MALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980323331',N'stu_1523@schoolname.edu',N'House 423, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500013',N'India',1,N'DAY_SCHOLAR',1),
      (324,524,1,2,1,17,33,N'ADM-2026-0324',N'R-04',N'Zeeshan',N'Raman','2014-01-09',N'MALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980324331',N'stu_1524@schoolname.edu',N'House 424, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500014',N'India',1,N'DAY_SCHOLAR',1),
      (325,525,1,2,1,17,33,N'ADM-2026-0325',N'R-05',N'Brijesh',N'Bhowmick','2014-08-20',N'MALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980325331',N'stu_1525@schoolname.edu',N'House 425, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500015',N'India',1,N'HOSTELLER',1),
      (326,526,1,2,1,17,33,N'ADM-2026-0326',N'R-06',N'Trisha',N'Nagpal','2014-03-03',N'FEMALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980326331',N'stu_1526@schoolname.edu',N'House 426, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500016',N'India',1,N'DAY_SCHOLAR',1),
      (327,527,1,2,1,17,33,N'ADM-2026-0327',N'R-07',N'Amrita',N'Mehra','2014-10-14',N'FEMALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980327331',N'stu_1527@schoolname.edu',N'House 427, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500017',N'India',1,N'DAY_SCHOLAR',1),
      (328,528,1,2,1,17,33,N'ADM-2026-0328',N'R-08',N'Shikha',N'Chauhan','2014-05-25',N'FEMALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980328331',N'stu_1528@schoolname.edu',N'House 428, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500018',N'India',1,N'DAY_SCHOLAR',1),
      (329,529,1,2,1,17,33,N'ADM-2026-0329',N'R-09',N'Lakshya',N'Deshmukh','2014-12-08',N'MALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980329331',N'stu_1529@schoolname.edu',N'House 429, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500019',N'India',1,N'DAY_SCHOLAR',1),
      (330,530,1,2,1,17,33,N'ADM-2026-0330',N'R-10',N'Sara',N'Singh','2014-07-19',N'FEMALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980330331',N'stu_1530@schoolname.edu',N'House 430, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500020',N'India',1,N'HOSTELLER',1),
      (331,531,1,2,1,17,34,N'ADM-2026-0331',N'R-01',N'Roopa',N'Nair','2014-02-02',N'FEMALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980331341',N'stu_1531@schoolname.edu',N'House 431, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500021',N'India',1,N'DAY_SCHOLAR',1),
      (332,532,1,2,1,17,34,N'ADM-2026-0332',N'R-02',N'Shailesh',N'Menon','2014-09-13',N'MALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980332341',N'stu_1532@schoolname.edu',N'House 432, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500022',N'India',1,N'DAY_SCHOLAR',1),
      (333,533,1,2,1,17,34,N'ADM-2026-0333',N'R-03',N'Jitendra',N'Sachdeva','2014-04-24',N'MALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980333341',N'stu_1533@schoolname.edu',N'House 433, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500023',N'India',1,N'DAY_SCHOLAR',1),
      (334,534,1,2,1,17,34,N'ADM-2026-0334',N'R-04',N'Samarth',N'Saxena','2014-11-07',N'MALE',N'O-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980334341',N'stu_1534@schoolname.edu',N'House 434, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500024',N'India',1,N'DAY_SCHOLAR',1),
      (335,535,1,2,1,17,34,N'ADM-2026-0335',N'R-05',N'Ayush',N'Prasad','2014-06-18',N'MALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980335341',N'stu_1535@schoolname.edu',N'House 435, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500025',N'India',1,N'HOSTELLER',1),
      (336,536,1,2,1,17,34,N'ADM-2026-0336',N'R-06',N'Rajesh',N'Kulkarni','2014-01-01',N'MALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980336341',N'stu_1536@schoolname.edu',N'House 436, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500026',N'India',1,N'DAY_SCHOLAR',1),
      (337,537,1,2,1,17,34,N'ADM-2026-0337',N'R-07',N'Vani',N'Rao','2014-08-12',N'FEMALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980337341',N'stu_1537@schoolname.edu',N'House 437, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500027',N'India',1,N'DAY_SCHOLAR',1),
      (338,538,1,2,1,17,34,N'ADM-2026-0338',N'R-08',N'Bhavesh',N'Mitra','2014-03-23',N'MALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980338341',N'stu_1538@schoolname.edu',N'House 438, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500028',N'India',1,N'DAY_SCHOLAR',1),
      (339,539,1,2,1,17,34,N'ADM-2026-0339',N'R-09',N'Mamta',N'Saxena','2014-10-06',N'FEMALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980339341',N'stu_1539@schoolname.edu',N'House 439, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500029',N'India',1,N'DAY_SCHOLAR',1),
      (340,540,1,2,1,17,34,N'ADM-2026-0340',N'R-10',N'Mohini',N'Khatri','2014-05-17',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980340341',N'stu_1540@schoolname.edu',N'House 440, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500030',N'India',1,N'HOSTELLER',1),
      (341,541,1,2,1,18,35,N'ADM-2026-0341',N'R-01',N'Sharad',N'Mishra','2013-12-28',N'MALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980341351',N'stu_1541@schoolname.edu',N'House 441, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500031',N'India',1,N'DAY_SCHOLAR',1),
      (342,542,1,2,1,18,35,N'ADM-2026-0342',N'R-02',N'Gauri',N'Balakrishnan','2013-07-11',N'FEMALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980342351',N'stu_1542@schoolname.edu',N'House 442, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500032',N'India',1,N'DAY_SCHOLAR',1),
      (343,543,1,2,1,18,35,N'ADM-2026-0343',N'R-03',N'Chirag',N'Kaushik','2013-02-22',N'MALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980343351',N'stu_1543@schoolname.edu',N'House 443, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500033',N'India',1,N'DAY_SCHOLAR',1),
      (344,544,1,2,1,18,35,N'ADM-2026-0344',N'R-04',N'Harbhajan',N'Chatterjee','2013-09-05',N'MALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980344351',N'stu_1544@schoolname.edu',N'House 444, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500034',N'India',1,N'DAY_SCHOLAR',1),
      (345,545,1,2,1,18,35,N'ADM-2026-0345',N'R-05',N'Agastya',N'Gill','2013-04-16',N'MALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980345351',N'stu_1545@schoolname.edu',N'House 445, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500035',N'India',1,N'HOSTELLER',1),
      (346,546,1,2,1,18,35,N'ADM-2026-0346',N'R-06',N'Upasana',N'Mahajan','2013-11-27',N'FEMALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980346351',N'stu_1546@schoolname.edu',N'House 446, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500036',N'India',1,N'DAY_SCHOLAR',1),
      (347,547,1,2,1,18,35,N'ADM-2026-0347',N'R-07',N'Aditi',N'Subramanian','2013-06-10',N'FEMALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980347351',N'stu_1547@schoolname.edu',N'House 447, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500037',N'India',1,N'DAY_SCHOLAR',1),
      (348,548,1,2,1,18,35,N'ADM-2026-0348',N'R-08',N'Harshit',N'Bhatia','2013-01-21',N'MALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980348351',N'stu_1548@schoolname.edu',N'House 448, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500038',N'India',1,N'DAY_SCHOLAR',1),
      (349,549,1,2,1,18,35,N'ADM-2026-0349',N'R-09',N'Rakesh',N'Dwivedi','2013-08-04',N'MALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980349351',N'stu_1549@schoolname.edu',N'House 449, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500039',N'India',1,N'DAY_SCHOLAR',1),
      (350,550,1,2,1,18,35,N'ADM-2026-0350',N'R-10',N'Kamla',N'Malik','2013-03-15',N'FEMALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980350351',N'stu_1550@schoolname.edu',N'House 450, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500040',N'India',1,N'HOSTELLER',1),
      (351,551,1,2,1,18,36,N'ADM-2026-0351',N'R-01',N'Akshat',N'Krishnan','2013-10-26',N'MALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980351361',N'stu_1551@schoolname.edu',N'House 451, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500041',N'India',1,N'DAY_SCHOLAR',1),
      (352,552,1,2,1,18,36,N'ADM-2026-0352',N'R-02',N'Ashok',N'Acharya','2013-05-09',N'MALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980352361',N'stu_1552@schoolname.edu',N'House 452, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500042',N'India',1,N'DAY_SCHOLAR',1),
      (353,553,1,2,1,18,36,N'ADM-2026-0353',N'R-03',N'Jayant',N'Nair','2013-12-20',N'MALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980353361',N'stu_1553@schoolname.edu',N'House 453, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500043',N'India',1,N'DAY_SCHOLAR',1),
      (354,554,1,2,1,18,36,N'ADM-2026-0354',N'R-04',N'Harpreet',N'Ghosh','2013-07-03',N'MALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980354361',N'stu_1554@schoolname.edu',N'House 454, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500044',N'India',1,N'DAY_SCHOLAR',1),
      (355,555,1,2,1,18,36,N'ADM-2026-0355',N'R-05',N'Ananya',N'Awasthi','2013-02-14',N'FEMALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980355361',N'stu_1555@schoolname.edu',N'House 455, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500045',N'India',1,N'HOSTELLER',1),
      (356,556,1,2,1,18,36,N'ADM-2026-0356',N'R-06',N'Ahana',N'Mehta','2013-09-25',N'FEMALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980356361',N'stu_1556@schoolname.edu',N'House 456, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500046',N'India',1,N'DAY_SCHOLAR',1),
      (357,557,1,2,1,18,36,N'ADM-2026-0357',N'R-07',N'Vishnu',N'Madan','2013-04-08',N'MALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980357361',N'stu_1557@schoolname.edu',N'House 457, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500047',N'India',1,N'DAY_SCHOLAR',1),
      (358,558,1,2,1,18,36,N'ADM-2026-0358',N'R-08',N'Devendra',N'Dhillon','2013-11-19',N'MALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980358361',N'stu_1558@schoolname.edu',N'House 458, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500048',N'India',1,N'DAY_SCHOLAR',1),
      (359,559,1,2,1,18,36,N'ADM-2026-0359',N'R-09',N'Sahil',N'Nagpal','2013-06-02',N'MALE',N'A-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980359361',N'stu_1559@schoolname.edu',N'House 459, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500049',N'India',1,N'DAY_SCHOLAR',1),
      (360,560,1,2,1,18,36,N'ADM-2026-0360',N'R-10',N'Usha',N'Agarwal','2013-01-13',N'FEMALE',N'A+',N'Indian',N'Kannada',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980360361',N'stu_1560@schoolname.edu',N'House 460, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500050',N'India',1,N'HOSTELLER',1),
      (361,561,1,2,1,19,37,N'ADM-2026-0361',N'R-01',N'Abhijeet',N'Chowdary','2012-08-24',N'MALE',N'B+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980361371',N'stu_1561@schoolname.edu',N'House 461, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500051',N'India',1,N'DAY_SCHOLAR',1),
      (362,562,1,2,1,19,37,N'ADM-2026-0362',N'R-02',N'Navya',N'Goswami','2012-03-07',N'FEMALE',N'O+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980362371',N'stu_1562@schoolname.edu',N'House 462, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500052',N'India',1,N'DAY_SCHOLAR',1),
      (363,563,1,2,1,19,37,N'ADM-2026-0363',N'R-03',N'Sonal',N'Sidhu','2012-10-18',N'FEMALE',N'AB+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980363371',N'stu_1563@schoolname.edu',N'House 463, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500053',N'India',1,N'DAY_SCHOLAR',1),
      (364,564,1,2,1,19,37,N'ADM-2026-0364',N'R-04',N'Uday',N'Raju','2012-05-01',N'MALE',N'O-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980364371',N'stu_1564@schoolname.edu',N'House 464, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500054',N'India',1,N'DAY_SCHOLAR',1),
      (365,565,1,2,1,19,37,N'ADM-2026-0365',N'R-05',N'Arjun',N'Das','2012-12-12',N'MALE',N'A-',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980365371',N'stu_1565@schoolname.edu',N'House 465, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500055',N'India',1,N'HOSTELLER',1),
      (366,566,1,2,1,19,37,N'ADM-2026-0366',N'R-06',N'Sanjay',N'Rao','2012-07-23',N'MALE',N'A+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980366371',N'stu_1566@schoolname.edu',N'House 466, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500056',N'India',1,N'DAY_SCHOLAR',1),
      (367,567,1,2,1,19,37,N'ADM-2026-0367',N'R-07',N'Beena',N'Menon','2012-02-06',N'FEMALE',N'B+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980367371',N'stu_1567@schoolname.edu',N'House 467, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500057',N'India',1,N'DAY_SCHOLAR',1),
      (368,568,1,2,1,19,37,N'ADM-2026-0368',N'R-08',N'Khushi',N'Chawla','2012-09-17',N'FEMALE',N'O+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980368371',N'stu_1568@schoolname.edu',N'House 468, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500058',N'India',1,N'DAY_SCHOLAR',1),
      (369,569,1,2,1,19,37,N'ADM-2026-0369',N'R-09',N'Girish',N'Chopra','2012-04-28',N'MALE',N'AB+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980369371',N'stu_1569@schoolname.edu',N'House 469, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500059',N'India',1,N'DAY_SCHOLAR',1),
      (370,570,1,2,1,19,37,N'ADM-2026-0370',N'R-10',N'Aarohi',N'Parmar','2012-11-11',N'FEMALE',N'O-',N'Indian',N'Bengali',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980370371',N'stu_1570@schoolname.edu',N'House 470, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500060',N'India',1,N'HOSTELLER',1),
      (371,571,1,2,1,19,38,N'ADM-2026-0371',N'R-01',N'Myra',N'Patel','2012-06-22',N'FEMALE',N'A-',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980371381',N'stu_1571@schoolname.edu',N'House 471, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500061',N'India',1,N'DAY_SCHOLAR',1),
      (372,572,1,2,1,19,38,N'ADM-2026-0372',N'R-02',N'Sudha',N'Kapoor','2012-01-05',N'FEMALE',N'A+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980372381',N'stu_1572@schoolname.edu',N'House 472, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500062',N'India',1,N'DAY_SCHOLAR',1),
      (373,573,1,2,1,19,38,N'ADM-2026-0373',N'R-03',N'Pratibha',N'Sundaram','2012-08-16',N'FEMALE',N'B+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980373381',N'stu_1573@schoolname.edu',N'House 473, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500063',N'India',1,N'DAY_SCHOLAR',1),
      (374,574,1,2,1,19,38,N'ADM-2026-0374',N'R-04',N'Varsha',N'Garg','2012-03-27',N'FEMALE',N'O+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980374381',N'stu_1574@schoolname.edu',N'House 474, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500064',N'India',1,N'DAY_SCHOLAR',1),
      (375,575,1,2,1,19,38,N'ADM-2026-0375',N'R-05',N'Akash',N'Roy','2012-10-10',N'MALE',N'AB+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980375381',N'stu_1575@schoolname.edu',N'House 475, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500065',N'India',1,N'HOSTELLER',1),
      (376,576,1,2,1,19,38,N'ADM-2026-0376',N'R-06',N'Lata',N'Gautam','2012-05-21',N'FEMALE',N'O-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980376381',N'stu_1576@schoolname.edu',N'House 476, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500066',N'India',1,N'DAY_SCHOLAR',1),
      (377,577,1,2,1,19,38,N'ADM-2026-0377',N'R-07',N'Advik',N'Thakur','2012-12-04',N'MALE',N'A-',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980377381',N'stu_1577@schoolname.edu',N'House 477, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500067',N'India',1,N'DAY_SCHOLAR',1),
      (378,578,1,2,1,19,38,N'ADM-2026-0378',N'R-08',N'Jyoti',N'Yadav','2012-07-15',N'FEMALE',N'A+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980378381',N'stu_1578@schoolname.edu',N'House 478, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500068',N'India',1,N'DAY_SCHOLAR',1),
      (379,579,1,2,1,19,38,N'ADM-2026-0379',N'R-09',N'Akshara',N'Tripathi','2012-02-26',N'FEMALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980379381',N'stu_1579@schoolname.edu',N'House 479, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500069',N'India',1,N'DAY_SCHOLAR',1),
      (380,580,1,2,1,19,38,N'ADM-2026-0380',N'R-10',N'Kartik',N'Goel','2012-09-09',N'MALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980380381',N'stu_1580@schoolname.edu',N'House 480, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500070',N'India',1,N'HOSTELLER',1),
      (381,581,1,2,1,20,39,N'ADM-2026-0381',N'R-01',N'Dilip',N'Grewal','2011-04-20',N'MALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980381391',N'stu_1581@schoolname.edu',N'House 481, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500071',N'India',1,N'DAY_SCHOLAR',1),
      (382,582,1,2,1,20,39,N'ADM-2026-0382',N'R-02',N'Eklavya',N'Reddy','2011-11-03',N'MALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980382391',N'stu_1582@schoolname.edu',N'House 482, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500072',N'India',1,N'DAY_SCHOLAR',1),
      (383,583,1,2,1,20,39,N'ADM-2026-0383',N'R-03',N'Advaith',N'Yadav','2011-06-14',N'MALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980383391',N'stu_1583@schoolname.edu',N'House 483, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500073',N'India',1,N'DAY_SCHOLAR',1),
      (384,584,1,2,1,20,39,N'ADM-2026-0384',N'R-04',N'Aryan',N'Malik','2011-01-25',N'MALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980384391',N'stu_1584@schoolname.edu',N'House 484, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500074',N'India',1,N'DAY_SCHOLAR',1),
      (385,585,1,2,1,20,39,N'ADM-2026-0385',N'R-05',N'Shanaya',N'Gill','2011-08-08',N'FEMALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980385391',N'stu_1585@schoolname.edu',N'House 485, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500075',N'India',1,N'HOSTELLER',1),
      (386,586,1,2,1,20,39,N'ADM-2026-0386',N'R-06',N'Bela',N'Hegde','2011-03-19',N'FEMALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980386391',N'stu_1586@schoolname.edu',N'House 486, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500076',N'India',1,N'DAY_SCHOLAR',1),
      (387,587,1,2,1,20,39,N'ADM-2026-0387',N'R-07',N'Abhimanyu',N'Ganguly','2011-10-02',N'MALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980387391',N'stu_1587@schoolname.edu',N'House 487, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500077',N'India',1,N'DAY_SCHOLAR',1),
      (388,588,1,2,1,20,39,N'ADM-2026-0388',N'R-08',N'Chitra',N'Munjal','2011-05-13',N'FEMALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980388391',N'stu_1588@schoolname.edu',N'House 488, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500078',N'India',1,N'DAY_SCHOLAR',1),
      (389,589,1,2,1,20,39,N'ADM-2026-0389',N'R-09',N'Shanaya',N'Choudhury','2011-12-24',N'FEMALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980389391',N'stu_1589@schoolname.edu',N'House 489, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500079',N'India',1,N'DAY_SCHOLAR',1),
      (390,590,1,2,1,20,39,N'ADM-2026-0390',N'R-10',N'Sandhya',N'Chatterjee','2011-07-07',N'FEMALE',N'A+',N'Indian',N'English',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980390391',N'stu_1590@schoolname.edu',N'House 490, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500080',N'India',1,N'HOSTELLER',1),
      (391,591,1,2,1,20,40,N'ADM-2026-0391',N'R-01',N'Mayank',N'Pillai','2011-02-18',N'MALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980391401',N'stu_1591@schoolname.edu',N'House 491, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500081',N'India',1,N'DAY_SCHOLAR',1),
      (392,592,1,2,1,20,40,N'ADM-2026-0392',N'R-02',N'Avani',N'Srinivasan','2011-09-01',N'FEMALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980392401',N'stu_1592@schoolname.edu',N'House 492, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500082',N'India',1,N'DAY_SCHOLAR',1),
      (393,593,1,2,1,20,40,N'ADM-2026-0393',N'R-03',N'Jatin',N'Asthana','2011-04-12',N'MALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980393401',N'stu_1593@schoolname.edu',N'House 493, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500083',N'India',1,N'DAY_SCHOLAR',1),
      (394,594,1,2,1,20,40,N'ADM-2026-0394',N'R-04',N'Harish',N'Tandon','2011-11-23',N'MALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980394401',N'stu_1594@schoolname.edu',N'House 494, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500084',N'India',1,N'DAY_SCHOLAR',1),
      (395,595,1,2,1,20,40,N'ADM-2026-0395',N'R-05',N'Mukesh',N'Uppal','2011-06-06',N'MALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980395401',N'stu_1595@schoolname.edu',N'House 495, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500085',N'India',1,N'HOSTELLER',1),
      (396,596,1,2,1,20,40,N'ADM-2026-0396',N'R-06',N'Sachin',N'Varma','2011-01-17',N'MALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980396401',N'stu_1596@schoolname.edu',N'House 496, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500086',N'India',1,N'DAY_SCHOLAR',1),
      (397,597,1,2,1,20,40,N'ADM-2026-0397',N'R-07',N'Chandni',N'Swaminathan','2011-08-28',N'FEMALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980397401',N'stu_1597@schoolname.edu',N'House 497, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500087',N'India',1,N'DAY_SCHOLAR',1),
      (398,598,1,2,1,20,40,N'ADM-2026-0398',N'R-08',N'Atharva',N'Pathak','2011-03-11',N'MALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980398401',N'stu_1598@schoolname.edu',N'House 498, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500088',N'India',1,N'DAY_SCHOLAR',1),
      (399,599,1,2,1,20,40,N'ADM-2026-0399',N'R-09',N'Samar',N'Pandey','2011-10-22',N'MALE',N'AB+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2026-04-01',N'ACTIVE','2026-04-01',N'91980399401',N'stu_1599@schoolname.edu',N'House 499, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500089',N'India',1,N'DAY_SCHOLAR',1),
      (400,600,1,2,1,20,40,N'ADM-2026-0400',N'R-10',N'Nirmala',N'Chowdary','2011-05-05',N'FEMALE',N'O-',N'Indian',N'Hindi',N'Not Specified',N'SCHOLARSHIP','2026-04-01',N'ACTIVE','2026-04-01',N'91980400401',N'stu_1600@schoolname.edu',N'House 500, Banjara Hills Main Road',N'Phase 2',N'Near Metro Station',N'Hyderabad',N'Hyderabad',N'Telangana',N'500010',N'India',1,N'HOSTELLER',1),
      (401,601,1,1,101,10,19,N'ALUMNI-2025-001',N'R-01',N'Kishore',N'Thakur','2010-06-08',N'MALE',N'B+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700019900',N'stu_1601@schoolname.edu',N'Plot 201, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500011',N'India',1,N'DAY_SCHOLAR',1),
      (402,602,1,1,101,10,19,N'ALUMNI-2025-002',N'R-02',N'Mohini',N'Parmar','2010-11-15',N'FEMALE',N'O+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700029900',N'stu_1602@schoolname.edu',N'Plot 202, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500012',N'India',1,N'DAY_SCHOLAR',1),
      (403,603,1,1,101,10,19,N'ALUMNI-2025-003',N'R-03',N'Manish',N'Chaudhary','2010-04-22',N'MALE',N'AB+',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700039900',N'stu_1603@schoolname.edu',N'Plot 203, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500013',N'India',1,N'DAY_SCHOLAR',1),
      (404,604,1,1,101,10,19,N'ALUMNI-2025-004',N'R-04',N'Nalini',N'Sandhu','2010-09-01',N'FEMALE',N'O-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700049900',N'stu_1604@schoolname.edu',N'Plot 204, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500014',N'India',1,N'HOSTELLER',1),
      (405,605,1,1,101,10,19,N'ALUMNI-2025-005',N'R-05',N'Mukul',N'Bedi','2010-02-08',N'MALE',N'A-',N'Indian',N'English',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700059900',N'stu_1605@schoolname.edu',N'Plot 205, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500015',N'India',1,N'DAY_SCHOLAR',1),
      (406,606,1,1,101,10,20,N'ALUMNI-2025-006',N'R-06',N'Neelam',N'Malhotra','2010-07-15',N'FEMALE',N'A+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700069900',N'stu_1606@schoolname.edu',N'Plot 206, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500016',N'India',1,N'DAY_SCHOLAR',1),
      (407,607,1,1,101,10,20,N'ALUMNI-2025-007',N'R-07',N'Nitin',N'Anand','2010-12-22',N'MALE',N'B+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700079900',N'stu_1607@schoolname.edu',N'Plot 207, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500017',N'India',1,N'DAY_SCHOLAR',1),
      (408,608,1,1,101,10,20,N'ALUMNI-2025-008',N'R-08',N'Nirmala',N'Walia','2010-05-01',N'FEMALE',N'O+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700089900',N'stu_1608@schoolname.edu',N'Plot 208, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500018',N'India',1,N'HOSTELLER',1),
      (409,609,1,1,101,10,20,N'ALUMNI-2025-009',N'R-09',N'Pradeep',N'Srivastava','2010-10-08',N'MALE',N'AB+',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700099900',N'stu_1609@schoolname.edu',N'Plot 209, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500019',N'India',1,N'DAY_SCHOLAR',1),
      (410,610,1,1,101,10,20,N'ALUMNI-2025-010',N'R-10',N'Pallavi',N'Bhatnagar','2010-03-15',N'FEMALE',N'O-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700109900',N'stu_1610@schoolname.edu',N'Plot 210, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500020',N'India',1,N'DAY_SCHOLAR',1),
      (411,611,1,2,101,20,39,N'ALUMNI-2025-011',N'R-01',N'Prashant',N'Garg','2010-08-22',N'MALE',N'A-',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700119900',N'stu_1611@schoolname.edu',N'Plot 211, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500021',N'India',1,N'DAY_SCHOLAR',1),
      (412,612,1,2,101,20,39,N'ALUMNI-2025-012',N'R-02',N'Prabha',N'Mahajan','2010-01-01',N'FEMALE',N'A+',N'Indian',N'English',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700129900',N'stu_1612@schoolname.edu',N'Plot 212, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500022',N'India',1,N'HOSTELLER',1),
      (413,613,1,2,101,20,39,N'ALUMNI-2025-013',N'R-03',N'Prem',N'Bhandari','2010-06-08',N'MALE',N'B+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700139900',N'stu_1613@schoolname.edu',N'Plot 213, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500023',N'India',1,N'DAY_SCHOLAR',1),
      (414,614,1,2,101,20,39,N'ALUMNI-2025-014',N'R-04',N'Preeti',N'Bakshi','2010-11-15',N'FEMALE',N'O+',N'Indian',N'Telugu',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700149900',N'stu_1614@schoolname.edu',N'Plot 214, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500024',N'India',1,N'DAY_SCHOLAR',1),
      (415,615,1,2,101,20,39,N'ALUMNI-2025-015',N'R-05',N'Rajiv',N'Uppal','2010-04-22',N'MALE',N'AB+',N'Indian',N'Hindi',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700159900',N'stu_1615@schoolname.edu',N'Plot 215, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500025',N'India',1,N'DAY_SCHOLAR',1),
      (416,616,1,2,101,20,40,N'ALUMNI-2025-016',N'R-06',N'Rachna',N'Kashyap','2010-09-01',N'FEMALE',N'O-',N'Indian',N'Tamil',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700169900',N'stu_1616@schoolname.edu',N'Plot 216, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500026',N'India',1,N'HOSTELLER',1),
      (417,617,1,2,101,20,40,N'ALUMNI-2025-017',N'R-07',N'Raman',N'Raju','2010-02-08',N'MALE',N'A-',N'Indian',N'Kannada',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700179900',N'stu_1617@schoolname.edu',N'Plot 217, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500027',N'India',1,N'DAY_SCHOLAR',1),
      (418,618,1,2,101,20,40,N'ALUMNI-2025-018',N'R-08',N'Rani',N'Balakrishnan','2010-07-15',N'FEMALE',N'A+',N'Indian',N'Marathi',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700189900',N'stu_1618@schoolname.edu',N'Plot 218, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500028',N'India',1,N'DAY_SCHOLAR',1),
      (419,619,1,2,101,20,40,N'ALUMNI-2025-019',N'R-09',N'Ravi',N'Ganesan','2010-12-22',N'MALE',N'B+',N'Indian',N'English',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700199900',N'stu_1619@schoolname.edu',N'Plot 219, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500029',N'India',1,N'DAY_SCHOLAR',1),
      (420,620,1,2,101,20,40,N'ALUMNI-2025-020',N'R-10',N'Renu',N'Viswanathan','2010-05-01',N'FEMALE',N'O+',N'Indian',N'Bengali',N'Not Specified',N'GENERAL','2016-06-15',N'GRADUATED','2026-03-31',N'919700209900',N'stu_1620@schoolname.edu',N'Plot 220, Jubilee Enclave',N'Sector 3',N'Near Tech Park',N'Hyderabad',N'Hyderabad',N'Telangana',N'500030',N'India',1,N'HOSTELLER',1);

    SET IDENTITY_INSERT student_schema.student OFF;

    /* Student Guardians: 2 per student (Father + Mother, Father is primary contact) */
    SET IDENTITY_INSERT student_schema.student_guardian ON;
    INSERT INTO student_schema.student_guardian
      (student_guardian_id,student_id,guardian_name,relationship_type,mobile_number,
       alternate_mobile_number,email_address,occupation,organization_name,
       is_legal_guardian,is_primary_contact,is_emergency_contact,is_pickup_authorized,
       is_active,created_by)
    VALUES
      (1,1,N'Ramesh Iyer',N'FATHER',N'918800010001',NULL,N'father_stu_1201@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (2,1,N'Sunita Iyer',N'MOTHER',N'918800010002',NULL,N'mother_stu_1201@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (3,2,N'Ramesh Patel',N'FATHER',N'918800020001',NULL,N'father_stu_1202@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (4,2,N'Sunita Patel',N'MOTHER',N'918800020002',NULL,N'mother_stu_1202@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (5,3,N'Ramesh Bajwa',N'FATHER',N'918800030001',NULL,N'father_stu_1203@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (6,3,N'Sunita Bajwa',N'MOTHER',N'918800030002',NULL,N'mother_stu_1203@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (7,4,N'Ramesh Nigam',N'FATHER',N'918800040001',NULL,N'father_stu_1204@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (8,4,N'Sunita Nigam',N'MOTHER',N'918800040002',NULL,N'mother_stu_1204@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (9,5,N'Ramesh Sharma',N'FATHER',N'918800050001',NULL,N'father_stu_1205@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (10,5,N'Sunita Sharma',N'MOTHER',N'918800050002',NULL,N'mother_stu_1205@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (11,6,N'Ramesh Suri',N'FATHER',N'918800060001',NULL,N'father_stu_1206@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (12,6,N'Sunita Suri',N'MOTHER',N'918800060002',NULL,N'mother_stu_1206@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (13,7,N'Ramesh Joshi',N'FATHER',N'918800070001',NULL,N'father_stu_1207@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (14,7,N'Sunita Joshi',N'MOTHER',N'918800070002',NULL,N'mother_stu_1207@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (15,8,N'Ramesh Talwar',N'FATHER',N'918800080001',NULL,N'father_stu_1208@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (16,8,N'Sunita Talwar',N'MOTHER',N'918800080002',NULL,N'mother_stu_1208@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (17,9,N'Ramesh Tiwari',N'FATHER',N'918800090001',NULL,N'father_stu_1209@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (18,9,N'Sunita Tiwari',N'MOTHER',N'918800090002',NULL,N'mother_stu_1209@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (19,10,N'Ramesh Sengupta',N'FATHER',N'918800100001',NULL,N'father_stu_1210@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (20,10,N'Sunita Sengupta',N'MOTHER',N'918800100002',NULL,N'mother_stu_1210@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (21,11,N'Ramesh Pillai',N'FATHER',N'918800110001',NULL,N'father_stu_1211@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (22,11,N'Sunita Pillai',N'MOTHER',N'918800110002',NULL,N'mother_stu_1211@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (23,12,N'Ramesh Pathak',N'FATHER',N'918800120001',NULL,N'father_stu_1212@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (24,12,N'Sunita Pathak',N'MOTHER',N'918800120002',NULL,N'mother_stu_1212@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (25,13,N'Ramesh Venkataraman',N'FATHER',N'918800130001',NULL,N'father_stu_1213@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (26,13,N'Sunita Venkataraman',N'MOTHER',N'918800130002',NULL,N'mother_stu_1213@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (27,14,N'Ramesh Mitra',N'FATHER',N'918800140001',NULL,N'father_stu_1214@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (28,14,N'Sunita Mitra',N'MOTHER',N'918800140002',NULL,N'mother_stu_1214@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (29,15,N'Ramesh Ghosh',N'FATHER',N'918800150001',NULL,N'father_stu_1215@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (30,15,N'Sunita Ghosh',N'MOTHER',N'918800150002',NULL,N'mother_stu_1215@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (31,16,N'Ramesh Asthana',N'FATHER',N'918800160001',NULL,N'father_stu_1216@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (32,16,N'Sunita Asthana',N'MOTHER',N'918800160002',NULL,N'mother_stu_1216@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (33,17,N'Ramesh Acharya',N'FATHER',N'918800170001',NULL,N'father_stu_1217@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (34,17,N'Sunita Acharya',N'MOTHER',N'918800170002',NULL,N'mother_stu_1217@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (35,18,N'Ramesh Sidhu',N'FATHER',N'918800180001',NULL,N'father_stu_1218@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (36,18,N'Sunita Sidhu',N'MOTHER',N'918800180002',NULL,N'mother_stu_1218@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (37,19,N'Ramesh Banerjee',N'FATHER',N'918800190001',NULL,N'father_stu_1219@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (38,19,N'Sunita Banerjee',N'MOTHER',N'918800190002',NULL,N'mother_stu_1219@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (39,20,N'Ramesh Chatterjee',N'FATHER',N'918800200001',NULL,N'father_stu_1220@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (40,20,N'Sunita Chatterjee',N'MOTHER',N'918800200002',NULL,N'mother_stu_1220@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (41,21,N'Ramesh Kulshrestha',N'FATHER',N'918800210001',NULL,N'father_stu_1221@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (42,21,N'Sunita Kulshrestha',N'MOTHER',N'918800210002',NULL,N'mother_stu_1221@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (43,22,N'Ramesh Bhandari',N'FATHER',N'918800220001',NULL,N'father_stu_1222@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (44,22,N'Sunita Bhandari',N'MOTHER',N'918800220002',NULL,N'mother_stu_1222@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (45,23,N'Ramesh Kulkarni',N'FATHER',N'918800230001',NULL,N'father_stu_1223@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (46,23,N'Sunita Kulkarni',N'MOTHER',N'918800230002',NULL,N'mother_stu_1223@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (47,24,N'Ramesh Bakshi',N'FATHER',N'918800240001',NULL,N'father_stu_1224@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (48,24,N'Sunita Bakshi',N'MOTHER',N'918800240002',NULL,N'mother_stu_1224@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (49,25,N'Ramesh Hegde',N'FATHER',N'918800250001',NULL,N'father_stu_1225@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (50,25,N'Sunita Hegde',N'MOTHER',N'918800250002',NULL,N'mother_stu_1225@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (51,26,N'Ramesh Kohli',N'FATHER',N'918800260001',NULL,N'father_stu_1226@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (52,26,N'Sunita Kohli',N'MOTHER',N'918800260002',NULL,N'mother_stu_1226@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (53,27,N'Ramesh Dubey',N'FATHER',N'918800270001',NULL,N'father_stu_1227@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (54,27,N'Sunita Dubey',N'MOTHER',N'918800270002',NULL,N'mother_stu_1227@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (55,28,N'Ramesh Rao',N'FATHER',N'918800280001',NULL,N'father_stu_1228@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (56,28,N'Sunita Rao',N'MOTHER',N'918800280002',NULL,N'mother_stu_1228@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (57,29,N'Ramesh Kansal',N'FATHER',N'918800290001',NULL,N'father_stu_1229@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (58,29,N'Sunita Kansal',N'MOTHER',N'918800290002',NULL,N'mother_stu_1229@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (59,30,N'Ramesh Nagpal',N'FATHER',N'918800300001',NULL,N'father_stu_1230@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (60,30,N'Sunita Nagpal',N'MOTHER',N'918800300002',NULL,N'mother_stu_1230@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (61,31,N'Ramesh Jha',N'FATHER',N'918800310001',NULL,N'father_stu_1231@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (62,31,N'Sunita Jha',N'MOTHER',N'918800310002',NULL,N'mother_stu_1231@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (63,32,N'Ramesh Bose',N'FATHER',N'918800320001',NULL,N'father_stu_1232@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (64,32,N'Sunita Bose',N'MOTHER',N'918800320002',NULL,N'mother_stu_1232@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (65,33,N'Ramesh Goswami',N'FATHER',N'918800330001',NULL,N'father_stu_1233@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (66,33,N'Sunita Goswami',N'MOTHER',N'918800330002',NULL,N'mother_stu_1233@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (67,34,N'Ramesh Pai',N'FATHER',N'918800340001',NULL,N'father_stu_1234@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (68,34,N'Sunita Pai',N'MOTHER',N'918800340002',NULL,N'mother_stu_1234@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (69,35,N'Ramesh Nambiar',N'FATHER',N'918800350001',NULL,N'father_stu_1235@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (70,35,N'Sunita Nambiar',N'MOTHER',N'918800350002',NULL,N'mother_stu_1235@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (71,36,N'Ramesh Chowdary',N'FATHER',N'918800360001',NULL,N'father_stu_1236@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (72,36,N'Sunita Chowdary',N'MOTHER',N'918800360002',NULL,N'mother_stu_1236@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (73,37,N'Ramesh Parmar',N'FATHER',N'918800370001',NULL,N'father_stu_1237@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (74,37,N'Sunita Parmar',N'MOTHER',N'918800370002',NULL,N'mother_stu_1237@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (75,38,N'Ramesh Naidu',N'FATHER',N'918800380001',NULL,N'father_stu_1238@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (76,38,N'Sunita Naidu',N'MOTHER',N'918800380002',NULL,N'mother_stu_1238@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (77,39,N'Ramesh Ojha',N'FATHER',N'918800390001',NULL,N'father_stu_1239@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (78,39,N'Sunita Ojha',N'MOTHER',N'918800390002',NULL,N'mother_stu_1239@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (79,40,N'Ramesh Bhattacharya',N'FATHER',N'918800400001',NULL,N'father_stu_1240@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (80,40,N'Sunita Bhattacharya',N'MOTHER',N'918800400002',NULL,N'mother_stu_1240@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (81,41,N'Ramesh Sharma',N'FATHER',N'918800410001',NULL,N'father_stu_1241@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (82,41,N'Sunita Sharma',N'MOTHER',N'918800410002',NULL,N'mother_stu_1241@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (83,42,N'Ramesh Somayaji',N'FATHER',N'918800420001',NULL,N'father_stu_1242@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (84,42,N'Sunita Somayaji',N'MOTHER',N'918800420002',NULL,N'mother_stu_1242@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (85,43,N'Ramesh Bakshi',N'FATHER',N'918800430001',NULL,N'father_stu_1243@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (86,43,N'Sunita Bakshi',N'MOTHER',N'918800430002',NULL,N'mother_stu_1243@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (87,44,N'Ramesh Vashist',N'FATHER',N'918800440001',NULL,N'father_stu_1244@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (88,44,N'Sunita Vashist',N'MOTHER',N'918800440002',NULL,N'mother_stu_1244@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (89,45,N'Ramesh Bhandari',N'FATHER',N'918800450001',NULL,N'father_stu_1245@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (90,45,N'Sunita Bhandari',N'MOTHER',N'918800450002',NULL,N'mother_stu_1245@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (91,46,N'Ramesh Venkataraman',N'FATHER',N'918800460001',NULL,N'father_stu_1246@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (92,46,N'Sunita Venkataraman',N'MOTHER',N'918800460002',NULL,N'mother_stu_1246@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (93,47,N'Ramesh Vashist',N'FATHER',N'918800470001',NULL,N'father_stu_1247@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (94,47,N'Sunita Vashist',N'MOTHER',N'918800470002',NULL,N'mother_stu_1247@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (95,48,N'Ramesh Mehta',N'FATHER',N'918800480001',NULL,N'father_stu_1248@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (96,48,N'Sunita Mehta',N'MOTHER',N'918800480002',NULL,N'mother_stu_1248@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (97,49,N'Ramesh Bhandari',N'FATHER',N'918800490001',NULL,N'father_stu_1249@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (98,49,N'Sunita Bhandari',N'MOTHER',N'918800490002',NULL,N'mother_stu_1249@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (99,50,N'Ramesh Das',N'FATHER',N'918800500001',NULL,N'father_stu_1250@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (100,50,N'Sunita Das',N'MOTHER',N'918800500002',NULL,N'mother_stu_1250@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (101,51,N'Ramesh Prasad',N'FATHER',N'918800510001',NULL,N'father_stu_1251@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (102,51,N'Sunita Prasad',N'MOTHER',N'918800510002',NULL,N'mother_stu_1251@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (103,52,N'Ramesh Kapoor',N'FATHER',N'918800520001',NULL,N'father_stu_1252@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (104,52,N'Sunita Kapoor',N'MOTHER',N'918800520002',NULL,N'mother_stu_1252@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (105,53,N'Ramesh Dubey',N'FATHER',N'918800530001',NULL,N'father_stu_1253@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (106,53,N'Sunita Dubey',N'MOTHER',N'918800530002',NULL,N'mother_stu_1253@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (107,54,N'Ramesh Mitra',N'FATHER',N'918800540001',NULL,N'father_stu_1254@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (108,54,N'Sunita Mitra',N'MOTHER',N'918800540002',NULL,N'mother_stu_1254@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (109,55,N'Ramesh Kansal',N'FATHER',N'918800550001',NULL,N'father_stu_1255@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (110,55,N'Sunita Kansal',N'MOTHER',N'918800550002',NULL,N'mother_stu_1255@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (111,56,N'Ramesh Sen',N'FATHER',N'918800560001',NULL,N'father_stu_1256@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (112,56,N'Sunita Sen',N'MOTHER',N'918800560002',NULL,N'mother_stu_1256@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (113,57,N'Ramesh Chauhan',N'FATHER',N'918800570001',NULL,N'father_stu_1257@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (114,57,N'Sunita Chauhan',N'MOTHER',N'918800570002',NULL,N'mother_stu_1257@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (115,58,N'Ramesh Suri',N'FATHER',N'918800580001',NULL,N'father_stu_1258@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (116,58,N'Sunita Suri',N'MOTHER',N'918800580002',NULL,N'mother_stu_1258@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (117,59,N'Ramesh Raju',N'FATHER',N'918800590001',NULL,N'father_stu_1259@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (118,59,N'Sunita Raju',N'MOTHER',N'918800590002',NULL,N'mother_stu_1259@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (119,60,N'Ramesh Vaidya',N'FATHER',N'918800600001',NULL,N'father_stu_1260@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (120,60,N'Sunita Vaidya',N'MOTHER',N'918800600002',NULL,N'mother_stu_1260@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (121,61,N'Ramesh Awasthi',N'FATHER',N'918800610001',NULL,N'father_stu_1261@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (122,61,N'Sunita Awasthi',N'MOTHER',N'918800610002',NULL,N'mother_stu_1261@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (123,62,N'Ramesh Sanyal',N'FATHER',N'918800620001',NULL,N'father_stu_1262@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (124,62,N'Sunita Sanyal',N'MOTHER',N'918800620002',NULL,N'mother_stu_1262@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (125,63,N'Ramesh Mittal',N'FATHER',N'918800630001',NULL,N'father_stu_1263@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (126,63,N'Sunita Mittal',N'MOTHER',N'918800630002',NULL,N'mother_stu_1263@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (127,64,N'Ramesh Agarwal',N'FATHER',N'918800640001',NULL,N'father_stu_1264@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (128,64,N'Sunita Agarwal',N'MOTHER',N'918800640002',NULL,N'mother_stu_1264@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (129,65,N'Ramesh Kaushik',N'FATHER',N'918800650001',NULL,N'father_stu_1265@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (130,65,N'Sunita Kaushik',N'MOTHER',N'918800650002',NULL,N'mother_stu_1265@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (131,66,N'Ramesh Trehan',N'FATHER',N'918800660001',NULL,N'father_stu_1266@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (132,66,N'Sunita Trehan',N'MOTHER',N'918800660002',NULL,N'mother_stu_1266@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (133,67,N'Ramesh Kashyap',N'FATHER',N'918800670001',NULL,N'father_stu_1267@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (134,67,N'Sunita Kashyap',N'MOTHER',N'918800670002',NULL,N'mother_stu_1267@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (135,68,N'Ramesh Narayanan',N'FATHER',N'918800680001',NULL,N'father_stu_1268@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (136,68,N'Sunita Narayanan',N'MOTHER',N'918800680002',NULL,N'mother_stu_1268@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (137,69,N'Ramesh Naidu',N'FATHER',N'918800690001',NULL,N'father_stu_1269@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (138,69,N'Sunita Naidu',N'MOTHER',N'918800690002',NULL,N'mother_stu_1269@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (139,70,N'Ramesh Ghai',N'FATHER',N'918800700001',NULL,N'father_stu_1270@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (140,70,N'Sunita Ghai',N'MOTHER',N'918800700002',NULL,N'mother_stu_1270@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (141,71,N'Ramesh Singh',N'FATHER',N'918800710001',NULL,N'father_stu_1271@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (142,71,N'Sunita Singh',N'MOTHER',N'918800710002',NULL,N'mother_stu_1271@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (143,72,N'Ramesh Kaushik',N'FATHER',N'918800720001',NULL,N'father_stu_1272@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (144,72,N'Sunita Kaushik',N'MOTHER',N'918800720002',NULL,N'mother_stu_1272@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (145,73,N'Ramesh Mishra',N'FATHER',N'918800730001',NULL,N'father_stu_1273@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (146,73,N'Sunita Mishra',N'MOTHER',N'918800730002',NULL,N'mother_stu_1273@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (147,74,N'Ramesh Bedi',N'FATHER',N'918800740001',NULL,N'father_stu_1274@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (148,74,N'Sunita Bedi',N'MOTHER',N'918800740002',NULL,N'mother_stu_1274@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (149,75,N'Ramesh Pillai',N'FATHER',N'918800750001',NULL,N'father_stu_1275@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (150,75,N'Sunita Pillai',N'MOTHER',N'918800750002',NULL,N'mother_stu_1275@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (151,76,N'Ramesh Pai',N'FATHER',N'918800760001',NULL,N'father_stu_1276@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (152,76,N'Sunita Pai',N'MOTHER',N'918800760002',NULL,N'mother_stu_1276@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (153,77,N'Ramesh Raghavan',N'FATHER',N'918800770001',NULL,N'father_stu_1277@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (154,77,N'Sunita Raghavan',N'MOTHER',N'918800770002',NULL,N'mother_stu_1277@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (155,78,N'Ramesh Sidhu',N'FATHER',N'918800780001',NULL,N'father_stu_1278@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (156,78,N'Sunita Sidhu',N'MOTHER',N'918800780002',NULL,N'mother_stu_1278@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (157,79,N'Ramesh Bhatia',N'FATHER',N'918800790001',NULL,N'father_stu_1279@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (158,79,N'Sunita Bhatia',N'MOTHER',N'918800790002',NULL,N'mother_stu_1279@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (159,80,N'Ramesh Viswanathan',N'FATHER',N'918800800001',NULL,N'father_stu_1280@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (160,80,N'Sunita Viswanathan',N'MOTHER',N'918800800002',NULL,N'mother_stu_1280@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (161,81,N'Ramesh Solanki',N'FATHER',N'918800810001',NULL,N'father_stu_1281@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (162,81,N'Sunita Solanki',N'MOTHER',N'918800810002',NULL,N'mother_stu_1281@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (163,82,N'Ramesh Bansal',N'FATHER',N'918800820001',NULL,N'father_stu_1282@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (164,82,N'Sunita Bansal',N'MOTHER',N'918800820002',NULL,N'mother_stu_1282@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (165,83,N'Ramesh Ganesan',N'FATHER',N'918800830001',NULL,N'father_stu_1283@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (166,83,N'Sunita Ganesan',N'MOTHER',N'918800830002',NULL,N'mother_stu_1283@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (167,84,N'Ramesh Agarwal',N'FATHER',N'918800840001',NULL,N'father_stu_1284@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (168,84,N'Sunita Agarwal',N'MOTHER',N'918800840002',NULL,N'mother_stu_1284@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (169,85,N'Ramesh Sethi',N'FATHER',N'918800850001',NULL,N'father_stu_1285@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (170,85,N'Sunita Sethi',N'MOTHER',N'918800850002',NULL,N'mother_stu_1285@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (171,86,N'Ramesh Kansal',N'FATHER',N'918800860001',NULL,N'father_stu_1286@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (172,86,N'Sunita Kansal',N'MOTHER',N'918800860002',NULL,N'mother_stu_1286@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (173,87,N'Ramesh Jha',N'FATHER',N'918800870001',NULL,N'father_stu_1287@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (174,87,N'Sunita Jha',N'MOTHER',N'918800870002',NULL,N'mother_stu_1287@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (175,88,N'Ramesh Joshi',N'FATHER',N'918800880001',NULL,N'father_stu_1288@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (176,88,N'Sunita Joshi',N'MOTHER',N'918800880002',NULL,N'mother_stu_1288@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (177,89,N'Ramesh Ganesan',N'FATHER',N'918800890001',NULL,N'father_stu_1289@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (178,89,N'Sunita Ganesan',N'MOTHER',N'918800890002',NULL,N'mother_stu_1289@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (179,90,N'Ramesh Dubey',N'FATHER',N'918800900001',NULL,N'father_stu_1290@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (180,90,N'Sunita Dubey',N'MOTHER',N'918800900002',NULL,N'mother_stu_1290@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (181,91,N'Ramesh Narang',N'FATHER',N'918800910001',NULL,N'father_stu_1291@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (182,91,N'Sunita Narang',N'MOTHER',N'918800910002',NULL,N'mother_stu_1291@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (183,92,N'Ramesh Mehra',N'FATHER',N'918800920001',NULL,N'father_stu_1292@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (184,92,N'Sunita Mehra',N'MOTHER',N'918800920002',NULL,N'mother_stu_1292@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (185,93,N'Ramesh Acharya',N'FATHER',N'918800930001',NULL,N'father_stu_1293@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (186,93,N'Sunita Acharya',N'MOTHER',N'918800930002',NULL,N'mother_stu_1293@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (187,94,N'Ramesh Singhal',N'FATHER',N'918800940001',NULL,N'father_stu_1294@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (188,94,N'Sunita Singhal',N'MOTHER',N'918800940002',NULL,N'mother_stu_1294@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (189,95,N'Ramesh Bhatnagar',N'FATHER',N'918800950001',NULL,N'father_stu_1295@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (190,95,N'Sunita Bhatnagar',N'MOTHER',N'918800950002',NULL,N'mother_stu_1295@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (191,96,N'Ramesh Sharma',N'FATHER',N'918800960001',NULL,N'father_stu_1296@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (192,96,N'Sunita Sharma',N'MOTHER',N'918800960002',NULL,N'mother_stu_1296@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (193,97,N'Ramesh Sastry',N'FATHER',N'918800970001',NULL,N'father_stu_1297@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (194,97,N'Sunita Sastry',N'MOTHER',N'918800970002',NULL,N'mother_stu_1297@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (195,98,N'Ramesh Gill',N'FATHER',N'918800980001',NULL,N'father_stu_1298@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (196,98,N'Sunita Gill',N'MOTHER',N'918800980002',NULL,N'mother_stu_1298@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (197,99,N'Ramesh Bhatnagar',N'FATHER',N'918800990001',NULL,N'father_stu_1299@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (198,99,N'Sunita Bhatnagar',N'MOTHER',N'918800990002',NULL,N'mother_stu_1299@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (199,100,N'Ramesh Sodhi',N'FATHER',N'918801000001',NULL,N'father_stu_1300@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (200,100,N'Sunita Sodhi',N'MOTHER',N'918801000002',NULL,N'mother_stu_1300@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (201,101,N'Ramesh Bose',N'FATHER',N'918801010001',NULL,N'father_stu_1301@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (202,101,N'Sunita Bose',N'MOTHER',N'918801010002',NULL,N'mother_stu_1301@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (203,102,N'Ramesh Khanna',N'FATHER',N'918801020001',NULL,N'father_stu_1302@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (204,102,N'Sunita Khanna',N'MOTHER',N'918801020002',NULL,N'mother_stu_1302@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (205,103,N'Ramesh Gowda',N'FATHER',N'918801030001',NULL,N'father_stu_1303@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (206,103,N'Sunita Gowda',N'MOTHER',N'918801030002',NULL,N'mother_stu_1303@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (207,104,N'Ramesh Varma',N'FATHER',N'918801040001',NULL,N'father_stu_1304@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (208,104,N'Sunita Varma',N'MOTHER',N'918801040002',NULL,N'mother_stu_1304@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (209,105,N'Ramesh Garg',N'FATHER',N'918801050001',NULL,N'father_stu_1305@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (210,105,N'Sunita Garg',N'MOTHER',N'918801050002',NULL,N'mother_stu_1305@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (211,106,N'Ramesh Kumar',N'FATHER',N'918801060001',NULL,N'father_stu_1306@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (212,106,N'Sunita Kumar',N'MOTHER',N'918801060002',NULL,N'mother_stu_1306@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (213,107,N'Ramesh Dutta',N'FATHER',N'918801070001',NULL,N'father_stu_1307@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (214,107,N'Sunita Dutta',N'MOTHER',N'918801070002',NULL,N'mother_stu_1307@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (215,108,N'Ramesh Awasthi',N'FATHER',N'918801080001',NULL,N'father_stu_1308@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (216,108,N'Sunita Awasthi',N'MOTHER',N'918801080002',NULL,N'mother_stu_1308@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (217,109,N'Ramesh Sengupta',N'FATHER',N'918801090001',NULL,N'father_stu_1309@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (218,109,N'Sunita Sengupta',N'MOTHER',N'918801090002',NULL,N'mother_stu_1309@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (219,110,N'Ramesh Kohli',N'FATHER',N'918801100001',NULL,N'father_stu_1310@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (220,110,N'Sunita Kohli',N'MOTHER',N'918801100002',NULL,N'mother_stu_1310@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (221,111,N'Ramesh Gupta',N'FATHER',N'918801110001',NULL,N'father_stu_1311@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (222,111,N'Sunita Gupta',N'MOTHER',N'918801110002',NULL,N'mother_stu_1311@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (223,112,N'Ramesh Saini',N'FATHER',N'918801120001',NULL,N'father_stu_1312@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (224,112,N'Sunita Saini',N'MOTHER',N'918801120002',NULL,N'mother_stu_1312@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (225,113,N'Ramesh Bedi',N'FATHER',N'918801130001',NULL,N'father_stu_1313@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (226,113,N'Sunita Bedi',N'MOTHER',N'918801130002',NULL,N'mother_stu_1313@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (227,114,N'Ramesh Narayanan',N'FATHER',N'918801140001',NULL,N'father_stu_1314@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (228,114,N'Sunita Narayanan',N'MOTHER',N'918801140002',NULL,N'mother_stu_1314@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (229,115,N'Ramesh Bhardwaj',N'FATHER',N'918801150001',NULL,N'father_stu_1315@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (230,115,N'Sunita Bhardwaj',N'MOTHER',N'918801150002',NULL,N'mother_stu_1315@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (231,116,N'Ramesh Iyer',N'FATHER',N'918801160001',NULL,N'father_stu_1316@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (232,116,N'Sunita Iyer',N'MOTHER',N'918801160002',NULL,N'mother_stu_1316@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (233,117,N'Ramesh Shukla',N'FATHER',N'918801170001',NULL,N'father_stu_1317@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (234,117,N'Sunita Shukla',N'MOTHER',N'918801170002',NULL,N'mother_stu_1317@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (235,118,N'Ramesh Grewal',N'FATHER',N'918801180001',NULL,N'father_stu_1318@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (236,118,N'Sunita Grewal',N'MOTHER',N'918801180002',NULL,N'mother_stu_1318@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (237,119,N'Ramesh Singhal',N'FATHER',N'918801190001',NULL,N'father_stu_1319@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (238,119,N'Sunita Singhal',N'MOTHER',N'918801190002',NULL,N'mother_stu_1319@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (239,120,N'Ramesh Walia',N'FATHER',N'918801200001',NULL,N'father_stu_1320@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (240,120,N'Sunita Walia',N'MOTHER',N'918801200002',NULL,N'mother_stu_1320@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (241,121,N'Ramesh Grover',N'FATHER',N'918801210001',NULL,N'father_stu_1321@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (242,121,N'Sunita Grover',N'MOTHER',N'918801210002',NULL,N'mother_stu_1321@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (243,122,N'Ramesh Mukherjee',N'FATHER',N'918801220001',NULL,N'father_stu_1322@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (244,122,N'Sunita Mukherjee',N'MOTHER',N'918801220002',NULL,N'mother_stu_1322@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (245,123,N'Ramesh Tiwari',N'FATHER',N'918801230001',NULL,N'father_stu_1323@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (246,123,N'Sunita Tiwari',N'MOTHER',N'918801230002',NULL,N'mother_stu_1323@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (247,124,N'Ramesh Venkatesh',N'FATHER',N'918801240001',NULL,N'father_stu_1324@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (248,124,N'Sunita Venkatesh',N'MOTHER',N'918801240002',NULL,N'mother_stu_1324@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (249,125,N'Ramesh Chaudhary',N'FATHER',N'918801250001',NULL,N'father_stu_1325@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (250,125,N'Sunita Chaudhary',N'MOTHER',N'918801250002',NULL,N'mother_stu_1325@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (251,126,N'Ramesh Hegde',N'FATHER',N'918801260001',NULL,N'father_stu_1326@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (252,126,N'Sunita Hegde',N'MOTHER',N'918801260002',NULL,N'mother_stu_1326@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (253,127,N'Ramesh Venkataraman',N'FATHER',N'918801270001',NULL,N'father_stu_1327@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (254,127,N'Sunita Venkataraman',N'MOTHER',N'918801270002',NULL,N'mother_stu_1327@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (255,128,N'Ramesh Malhotra',N'FATHER',N'918801280001',NULL,N'father_stu_1328@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (256,128,N'Sunita Malhotra',N'MOTHER',N'918801280002',NULL,N'mother_stu_1328@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (257,129,N'Ramesh Khanna',N'FATHER',N'918801290001',NULL,N'father_stu_1329@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (258,129,N'Sunita Khanna',N'MOTHER',N'918801290002',NULL,N'mother_stu_1329@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (259,130,N'Ramesh Mehta',N'FATHER',N'918801300001',NULL,N'father_stu_1330@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (260,130,N'Sunita Mehta',N'MOTHER',N'918801300002',NULL,N'mother_stu_1330@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (261,131,N'Ramesh Kulshrestha',N'FATHER',N'918801310001',NULL,N'father_stu_1331@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (262,131,N'Sunita Kulshrestha',N'MOTHER',N'918801310002',NULL,N'mother_stu_1331@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (263,132,N'Ramesh Patel',N'FATHER',N'918801320001',NULL,N'father_stu_1332@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (264,132,N'Sunita Patel',N'MOTHER',N'918801320002',NULL,N'mother_stu_1332@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (265,133,N'Ramesh Uppal',N'FATHER',N'918801330001',NULL,N'father_stu_1333@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (266,133,N'Sunita Uppal',N'MOTHER',N'918801330002',NULL,N'mother_stu_1333@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (267,134,N'Ramesh Sandhu',N'FATHER',N'918801340001',NULL,N'father_stu_1334@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (268,134,N'Sunita Sandhu',N'MOTHER',N'918801340002',NULL,N'mother_stu_1334@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (269,135,N'Ramesh Upadhyay',N'FATHER',N'918801350001',NULL,N'father_stu_1335@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (270,135,N'Sunita Upadhyay',N'MOTHER',N'918801350002',NULL,N'mother_stu_1335@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (271,136,N'Ramesh Bose',N'FATHER',N'918801360001',NULL,N'father_stu_1336@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (272,136,N'Sunita Bose',N'MOTHER',N'918801360002',NULL,N'mother_stu_1336@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (273,137,N'Ramesh Pathak',N'FATHER',N'918801370001',NULL,N'father_stu_1337@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (274,137,N'Sunita Pathak',N'MOTHER',N'918801370002',NULL,N'mother_stu_1337@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (275,138,N'Ramesh Ojha',N'FATHER',N'918801380001',NULL,N'father_stu_1338@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (276,138,N'Sunita Ojha',N'MOTHER',N'918801380002',NULL,N'mother_stu_1338@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (277,139,N'Ramesh Ganguly',N'FATHER',N'918801390001',NULL,N'father_stu_1339@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (278,139,N'Sunita Ganguly',N'MOTHER',N'918801390002',NULL,N'mother_stu_1339@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (279,140,N'Ramesh Bakshi',N'FATHER',N'918801400001',NULL,N'father_stu_1340@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (280,140,N'Sunita Bakshi',N'MOTHER',N'918801400002',NULL,N'mother_stu_1340@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (281,141,N'Ramesh Bhowmick',N'FATHER',N'918801410001',NULL,N'father_stu_1341@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (282,141,N'Sunita Bhowmick',N'MOTHER',N'918801410002',NULL,N'mother_stu_1341@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (283,142,N'Ramesh Choudhury',N'FATHER',N'918801420001',NULL,N'father_stu_1342@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (284,142,N'Sunita Choudhury',N'MOTHER',N'918801420002',NULL,N'mother_stu_1342@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (285,143,N'Ramesh Deshmukh',N'FATHER',N'918801430001',NULL,N'father_stu_1343@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (286,143,N'Sunita Deshmukh',N'MOTHER',N'918801430002',NULL,N'mother_stu_1343@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (287,144,N'Ramesh Bhatnagar',N'FATHER',N'918801440001',NULL,N'father_stu_1344@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (288,144,N'Sunita Bhatnagar',N'MOTHER',N'918801440002',NULL,N'mother_stu_1344@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (289,145,N'Ramesh Raman',N'FATHER',N'918801450001',NULL,N'father_stu_1345@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (290,145,N'Sunita Raman',N'MOTHER',N'918801450002',NULL,N'mother_stu_1345@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (291,146,N'Ramesh Krishnan',N'FATHER',N'918801460001',NULL,N'father_stu_1346@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (292,146,N'Sunita Krishnan',N'MOTHER',N'918801460002',NULL,N'mother_stu_1346@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (293,147,N'Ramesh Tripathi',N'FATHER',N'918801470001',NULL,N'father_stu_1347@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (294,147,N'Sunita Tripathi',N'MOTHER',N'918801470002',NULL,N'mother_stu_1347@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (295,148,N'Ramesh Kumar',N'FATHER',N'918801480001',NULL,N'father_stu_1348@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (296,148,N'Sunita Kumar',N'MOTHER',N'918801480002',NULL,N'mother_stu_1348@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (297,149,N'Ramesh Bhattacharya',N'FATHER',N'918801490001',NULL,N'father_stu_1349@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (298,149,N'Sunita Bhattacharya',N'MOTHER',N'918801490002',NULL,N'mother_stu_1349@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (299,150,N'Ramesh Walia',N'FATHER',N'918801500001',NULL,N'father_stu_1350@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (300,150,N'Sunita Walia',N'MOTHER',N'918801500002',NULL,N'mother_stu_1350@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (301,151,N'Ramesh Shukla',N'FATHER',N'918801510001',NULL,N'father_stu_1351@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (302,151,N'Sunita Shukla',N'MOTHER',N'918801510002',NULL,N'mother_stu_1351@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (303,152,N'Ramesh Lamba',N'FATHER',N'918801520001',NULL,N'father_stu_1352@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (304,152,N'Sunita Lamba',N'MOTHER',N'918801520002',NULL,N'mother_stu_1352@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (305,153,N'Ramesh Kumar',N'FATHER',N'918801530001',NULL,N'father_stu_1353@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (306,153,N'Sunita Kumar',N'MOTHER',N'918801530002',NULL,N'mother_stu_1353@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (307,154,N'Ramesh Tiwari',N'FATHER',N'918801540001',NULL,N'father_stu_1354@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (308,154,N'Sunita Tiwari',N'MOTHER',N'918801540002',NULL,N'mother_stu_1354@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (309,155,N'Ramesh Malik',N'FATHER',N'918801550001',NULL,N'father_stu_1355@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (310,155,N'Sunita Malik',N'MOTHER',N'918801550002',NULL,N'mother_stu_1355@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (311,156,N'Ramesh Saini',N'FATHER',N'918801560001',NULL,N'father_stu_1356@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (312,156,N'Sunita Saini',N'MOTHER',N'918801560002',NULL,N'mother_stu_1356@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (313,157,N'Ramesh Ghosh',N'FATHER',N'918801570001',NULL,N'father_stu_1357@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (314,157,N'Sunita Ghosh',N'MOTHER',N'918801570002',NULL,N'mother_stu_1357@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (315,158,N'Ramesh Dutta',N'FATHER',N'918801580001',NULL,N'father_stu_1358@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (316,158,N'Sunita Dutta',N'MOTHER',N'918801580002',NULL,N'mother_stu_1358@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (317,159,N'Ramesh Mukherjee',N'FATHER',N'918801590001',NULL,N'father_stu_1359@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (318,159,N'Sunita Mukherjee',N'MOTHER',N'918801590002',NULL,N'mother_stu_1359@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (319,160,N'Ramesh Dutta',N'FATHER',N'918801600001',NULL,N'father_stu_1360@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (320,160,N'Sunita Dutta',N'MOTHER',N'918801600002',NULL,N'mother_stu_1360@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (321,161,N'Ramesh Viswanathan',N'FATHER',N'918801610001',NULL,N'father_stu_1361@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (322,161,N'Sunita Viswanathan',N'MOTHER',N'918801610002',NULL,N'mother_stu_1361@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (323,162,N'Ramesh Reddy',N'FATHER',N'918801620001',NULL,N'father_stu_1362@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (324,162,N'Sunita Reddy',N'MOTHER',N'918801620002',NULL,N'mother_stu_1362@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (325,163,N'Ramesh Bhatia',N'FATHER',N'918801630001',NULL,N'father_stu_1363@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (326,163,N'Sunita Bhatia',N'MOTHER',N'918801630002',NULL,N'mother_stu_1363@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (327,164,N'Ramesh Bhat',N'FATHER',N'918801640001',NULL,N'father_stu_1364@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (328,164,N'Sunita Bhat',N'MOTHER',N'918801640002',NULL,N'mother_stu_1364@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (329,165,N'Ramesh Chauhan',N'FATHER',N'918801650001',NULL,N'father_stu_1365@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (330,165,N'Sunita Chauhan',N'MOTHER',N'918801650002',NULL,N'mother_stu_1365@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (331,166,N'Ramesh Raghavan',N'FATHER',N'918801660001',NULL,N'father_stu_1366@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (332,166,N'Sunita Raghavan',N'MOTHER',N'918801660002',NULL,N'mother_stu_1366@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (333,167,N'Ramesh Kashyap',N'FATHER',N'918801670001',NULL,N'father_stu_1367@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (334,167,N'Sunita Kashyap',N'MOTHER',N'918801670002',NULL,N'mother_stu_1367@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (335,168,N'Ramesh Srinivasan',N'FATHER',N'918801680001',NULL,N'father_stu_1368@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (336,168,N'Sunita Srinivasan',N'MOTHER',N'918801680002',NULL,N'mother_stu_1368@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (337,169,N'Ramesh Menon',N'FATHER',N'918801690001',NULL,N'father_stu_1369@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (338,169,N'Sunita Menon',N'MOTHER',N'918801690002',NULL,N'mother_stu_1369@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (339,170,N'Ramesh Chawla',N'FATHER',N'918801700001',NULL,N'father_stu_1370@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (340,170,N'Sunita Chawla',N'MOTHER',N'918801700002',NULL,N'mother_stu_1370@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (341,171,N'Ramesh Ganesan',N'FATHER',N'918801710001',NULL,N'father_stu_1371@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (342,171,N'Sunita Ganesan',N'MOTHER',N'918801710002',NULL,N'mother_stu_1371@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (343,172,N'Ramesh Sastry',N'FATHER',N'918801720001',NULL,N'father_stu_1372@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (344,172,N'Sunita Sastry',N'MOTHER',N'918801720002',NULL,N'mother_stu_1372@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (345,173,N'Ramesh Sen',N'FATHER',N'918801730001',NULL,N'father_stu_1373@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (346,173,N'Sunita Sen',N'MOTHER',N'918801730002',NULL,N'mother_stu_1373@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (347,174,N'Ramesh Bajwa',N'FATHER',N'918801740001',NULL,N'father_stu_1374@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (348,174,N'Sunita Bajwa',N'MOTHER',N'918801740002',NULL,N'mother_stu_1374@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (349,175,N'Ramesh Viswanathan',N'FATHER',N'918801750001',NULL,N'father_stu_1375@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (350,175,N'Sunita Viswanathan',N'MOTHER',N'918801750002',NULL,N'mother_stu_1375@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (351,176,N'Ramesh Ghai',N'FATHER',N'918801760001',NULL,N'father_stu_1376@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (352,176,N'Sunita Ghai',N'MOTHER',N'918801760002',NULL,N'mother_stu_1376@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (353,177,N'Ramesh Sundaram',N'FATHER',N'918801770001',NULL,N'father_stu_1377@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (354,177,N'Sunita Sundaram',N'MOTHER',N'918801770002',NULL,N'mother_stu_1377@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (355,178,N'Ramesh Malhotra',N'FATHER',N'918801780001',NULL,N'father_stu_1378@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (356,178,N'Sunita Malhotra',N'MOTHER',N'918801780002',NULL,N'mother_stu_1378@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (357,179,N'Ramesh Gupta',N'FATHER',N'918801790001',NULL,N'father_stu_1379@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (358,179,N'Sunita Gupta',N'MOTHER',N'918801790002',NULL,N'mother_stu_1379@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (359,180,N'Ramesh Chaudhary',N'FATHER',N'918801800001',NULL,N'father_stu_1380@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (360,180,N'Sunita Chaudhary',N'MOTHER',N'918801800002',NULL,N'mother_stu_1380@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (361,181,N'Ramesh Tandon',N'FATHER',N'918801810001',NULL,N'father_stu_1381@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (362,181,N'Sunita Tandon',N'MOTHER',N'918801810002',NULL,N'mother_stu_1381@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (363,182,N'Ramesh Swaminathan',N'FATHER',N'918801820001',NULL,N'father_stu_1382@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (364,182,N'Sunita Swaminathan',N'MOTHER',N'918801820002',NULL,N'mother_stu_1382@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (365,183,N'Ramesh Shukla',N'FATHER',N'918801830001',NULL,N'father_stu_1383@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (366,183,N'Sunita Shukla',N'MOTHER',N'918801830002',NULL,N'mother_stu_1383@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (367,184,N'Ramesh Dhillon',N'FATHER',N'918801840001',NULL,N'father_stu_1384@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (368,184,N'Sunita Dhillon',N'MOTHER',N'918801840002',NULL,N'mother_stu_1384@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (369,185,N'Ramesh Deshmukh',N'FATHER',N'918801850001',NULL,N'father_stu_1385@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (370,185,N'Sunita Deshmukh',N'MOTHER',N'918801850002',NULL,N'mother_stu_1385@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (371,186,N'Ramesh Sodhi',N'FATHER',N'918801860001',NULL,N'father_stu_1386@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (372,186,N'Sunita Sodhi',N'MOTHER',N'918801860002',NULL,N'mother_stu_1386@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (373,187,N'Ramesh Narang',N'FATHER',N'918801870001',NULL,N'father_stu_1387@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (374,187,N'Sunita Narang',N'MOTHER',N'918801870002',NULL,N'mother_stu_1387@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (375,188,N'Ramesh Ananthakrishnan',N'FATHER',N'918801880001',NULL,N'father_stu_1388@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (376,188,N'Sunita Ananthakrishnan',N'MOTHER',N'918801880002',NULL,N'mother_stu_1388@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (377,189,N'Ramesh Kumar',N'FATHER',N'918801890001',NULL,N'father_stu_1389@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (378,189,N'Sunita Kumar',N'MOTHER',N'918801890002',NULL,N'mother_stu_1389@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (379,190,N'Ramesh Sastry',N'FATHER',N'918801900001',NULL,N'father_stu_1390@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (380,190,N'Sunita Sastry',N'MOTHER',N'918801900002',NULL,N'mother_stu_1390@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (381,191,N'Ramesh Solanki',N'FATHER',N'918801910001',NULL,N'father_stu_1391@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (382,191,N'Sunita Solanki',N'MOTHER',N'918801910002',NULL,N'mother_stu_1391@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (383,192,N'Ramesh Trehan',N'FATHER',N'918801920001',NULL,N'father_stu_1392@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (384,192,N'Sunita Trehan',N'MOTHER',N'918801920002',NULL,N'mother_stu_1392@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (385,193,N'Ramesh Shetty',N'FATHER',N'918801930001',NULL,N'father_stu_1393@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (386,193,N'Sunita Shetty',N'MOTHER',N'918801930002',NULL,N'mother_stu_1393@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (387,194,N'Ramesh Bedi',N'FATHER',N'918801940001',NULL,N'father_stu_1394@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (388,194,N'Sunita Bedi',N'MOTHER',N'918801940002',NULL,N'mother_stu_1394@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (389,195,N'Ramesh Vaidya',N'FATHER',N'918801950001',NULL,N'father_stu_1395@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (390,195,N'Sunita Vaidya',N'MOTHER',N'918801950002',NULL,N'mother_stu_1395@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (391,196,N'Ramesh Prasad',N'FATHER',N'918801960001',NULL,N'father_stu_1396@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (392,196,N'Sunita Prasad',N'MOTHER',N'918801960002',NULL,N'mother_stu_1396@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (393,197,N'Ramesh Pandey',N'FATHER',N'918801970001',NULL,N'father_stu_1397@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (394,197,N'Sunita Pandey',N'MOTHER',N'918801970002',NULL,N'mother_stu_1397@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (395,198,N'Ramesh Trehan',N'FATHER',N'918801980001',NULL,N'father_stu_1398@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (396,198,N'Sunita Trehan',N'MOTHER',N'918801980002',NULL,N'mother_stu_1398@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (397,199,N'Ramesh Joshi',N'FATHER',N'918801990001',NULL,N'father_stu_1399@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (398,199,N'Sunita Joshi',N'MOTHER',N'918801990002',NULL,N'mother_stu_1399@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (399,200,N'Ramesh Sachdeva',N'FATHER',N'918802000001',NULL,N'father_stu_1400@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (400,200,N'Sunita Sachdeva',N'MOTHER',N'918802000002',NULL,N'mother_stu_1400@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (401,201,N'Ramesh Ghosh',N'FATHER',N'918802010001',NULL,N'father_stu_1401@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (402,201,N'Sunita Ghosh',N'MOTHER',N'918802010002',NULL,N'mother_stu_1401@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (403,202,N'Ramesh Das',N'FATHER',N'918802020001',NULL,N'father_stu_1402@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (404,202,N'Sunita Das',N'MOTHER',N'918802020002',NULL,N'mother_stu_1402@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (405,203,N'Ramesh Sanyal',N'FATHER',N'918802030001',NULL,N'father_stu_1403@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (406,203,N'Sunita Sanyal',N'MOTHER',N'918802030002',NULL,N'mother_stu_1403@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (407,204,N'Ramesh Srinivasan',N'FATHER',N'918802040001',NULL,N'father_stu_1404@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (408,204,N'Sunita Srinivasan',N'MOTHER',N'918802040002',NULL,N'mother_stu_1404@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (409,205,N'Ramesh Sethi',N'FATHER',N'918802050001',NULL,N'father_stu_1405@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (410,205,N'Sunita Sethi',N'MOTHER',N'918802050002',NULL,N'mother_stu_1405@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (411,206,N'Ramesh Vaidya',N'FATHER',N'918802060001',NULL,N'father_stu_1406@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (412,206,N'Sunita Vaidya',N'MOTHER',N'918802060002',NULL,N'mother_stu_1406@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (413,207,N'Ramesh Shetty',N'FATHER',N'918802070001',NULL,N'father_stu_1407@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (414,207,N'Sunita Shetty',N'MOTHER',N'918802070002',NULL,N'mother_stu_1407@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (415,208,N'Ramesh Mahajan',N'FATHER',N'918802080001',NULL,N'father_stu_1408@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (416,208,N'Sunita Mahajan',N'MOTHER',N'918802080002',NULL,N'mother_stu_1408@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (417,209,N'Ramesh Khatri',N'FATHER',N'918802090001',NULL,N'father_stu_1409@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (418,209,N'Sunita Khatri',N'MOTHER',N'918802090002',NULL,N'mother_stu_1409@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (419,210,N'Ramesh Pandey',N'FATHER',N'918802100001',NULL,N'father_stu_1410@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (420,210,N'Sunita Pandey',N'MOTHER',N'918802100002',NULL,N'mother_stu_1410@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (421,211,N'Ramesh Goel',N'FATHER',N'918802110001',NULL,N'father_stu_1411@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (422,211,N'Sunita Goel',N'MOTHER',N'918802110002',NULL,N'mother_stu_1411@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (423,212,N'Ramesh Pai',N'FATHER',N'918802120001',NULL,N'father_stu_1412@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (424,212,N'Sunita Pai',N'MOTHER',N'918802120002',NULL,N'mother_stu_1412@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (425,213,N'Ramesh Chopra',N'FATHER',N'918802130001',NULL,N'father_stu_1413@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (426,213,N'Sunita Chopra',N'MOTHER',N'918802130002',NULL,N'mother_stu_1413@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (427,214,N'Ramesh Nigam',N'FATHER',N'918802140001',NULL,N'father_stu_1414@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (428,214,N'Sunita Nigam',N'MOTHER',N'918802140002',NULL,N'mother_stu_1414@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (429,215,N'Ramesh Sandhu',N'FATHER',N'918802150001',NULL,N'father_stu_1415@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (430,215,N'Sunita Sandhu',N'MOTHER',N'918802150002',NULL,N'mother_stu_1415@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (431,216,N'Ramesh Nambiar',N'FATHER',N'918802160001',NULL,N'father_stu_1416@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (432,216,N'Sunita Nambiar',N'MOTHER',N'918802160002',NULL,N'mother_stu_1416@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (433,217,N'Ramesh Lamba',N'FATHER',N'918802170001',NULL,N'father_stu_1417@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (434,217,N'Sunita Lamba',N'MOTHER',N'918802170002',NULL,N'mother_stu_1417@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (435,218,N'Ramesh Reddy',N'FATHER',N'918802180001',NULL,N'father_stu_1418@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (436,218,N'Sunita Reddy',N'MOTHER',N'918802180002',NULL,N'mother_stu_1418@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (437,219,N'Ramesh Anand',N'FATHER',N'918802190001',NULL,N'father_stu_1419@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (438,219,N'Sunita Anand',N'MOTHER',N'918802190002',NULL,N'mother_stu_1419@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (439,220,N'Ramesh Grover',N'FATHER',N'918802200001',NULL,N'father_stu_1420@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (440,220,N'Sunita Grover',N'MOTHER',N'918802200002',NULL,N'mother_stu_1420@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (441,221,N'Ramesh Bhat',N'FATHER',N'918802210001',NULL,N'father_stu_1421@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (442,221,N'Sunita Bhat',N'MOTHER',N'918802210002',NULL,N'mother_stu_1421@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (443,222,N'Ramesh Mathur',N'FATHER',N'918802220001',NULL,N'father_stu_1422@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (444,222,N'Sunita Mathur',N'MOTHER',N'918802220002',NULL,N'mother_stu_1422@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (445,223,N'Ramesh Solanki',N'FATHER',N'918802230001',NULL,N'father_stu_1423@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (446,223,N'Sunita Solanki',N'MOTHER',N'918802230002',NULL,N'mother_stu_1423@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (447,224,N'Ramesh Parmar',N'FATHER',N'918802240001',NULL,N'father_stu_1424@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (448,224,N'Sunita Parmar',N'MOTHER',N'918802240002',NULL,N'mother_stu_1424@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (449,225,N'Ramesh Dwivedi',N'FATHER',N'918802250001',NULL,N'father_stu_1425@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (450,225,N'Sunita Dwivedi',N'MOTHER',N'918802250002',NULL,N'mother_stu_1425@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (451,226,N'Ramesh Chatterjee',N'FATHER',N'918802260001',NULL,N'father_stu_1426@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (452,226,N'Sunita Chatterjee',N'MOTHER',N'918802260002',NULL,N'mother_stu_1426@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (453,227,N'Ramesh Ojha',N'FATHER',N'918802270001',NULL,N'father_stu_1427@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (454,227,N'Sunita Ojha',N'MOTHER',N'918802270002',NULL,N'mother_stu_1427@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (455,228,N'Ramesh Asthana',N'FATHER',N'918802280001',NULL,N'father_stu_1428@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (456,228,N'Sunita Asthana',N'MOTHER',N'918802280002',NULL,N'mother_stu_1428@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (457,229,N'Ramesh Sanyal',N'FATHER',N'918802290001',NULL,N'father_stu_1429@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (458,229,N'Sunita Sanyal',N'MOTHER',N'918802290002',NULL,N'mother_stu_1429@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (459,230,N'Ramesh Thakur',N'FATHER',N'918802300001',NULL,N'father_stu_1430@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (460,230,N'Sunita Thakur',N'MOTHER',N'918802300002',NULL,N'mother_stu_1430@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (461,231,N'Ramesh Sen',N'FATHER',N'918802310001',NULL,N'father_stu_1431@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (462,231,N'Sunita Sen',N'MOTHER',N'918802310002',NULL,N'mother_stu_1431@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (463,232,N'Ramesh Anand',N'FATHER',N'918802320001',NULL,N'father_stu_1432@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (464,232,N'Sunita Anand',N'MOTHER',N'918802320002',NULL,N'mother_stu_1432@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (465,233,N'Ramesh Subramanian',N'FATHER',N'918802330001',NULL,N'father_stu_1433@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (466,233,N'Sunita Subramanian',N'MOTHER',N'918802330002',NULL,N'mother_stu_1433@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (467,234,N'Ramesh Thakur',N'FATHER',N'918802340001',NULL,N'father_stu_1434@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (468,234,N'Sunita Thakur',N'MOTHER',N'918802340002',NULL,N'mother_stu_1434@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (469,235,N'Ramesh Varma',N'FATHER',N'918802350001',NULL,N'father_stu_1435@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (470,235,N'Sunita Varma',N'MOTHER',N'918802350002',NULL,N'mother_stu_1435@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (471,236,N'Ramesh Iyer',N'FATHER',N'918802360001',NULL,N'father_stu_1436@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (472,236,N'Sunita Iyer',N'MOTHER',N'918802360002',NULL,N'mother_stu_1436@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (473,237,N'Ramesh Majumdar',N'FATHER',N'918802370001',NULL,N'father_stu_1437@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (474,237,N'Sunita Majumdar',N'MOTHER',N'918802370002',NULL,N'mother_stu_1437@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (475,238,N'Ramesh Khanna',N'FATHER',N'918802380001',NULL,N'father_stu_1438@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (476,238,N'Sunita Khanna',N'MOTHER',N'918802380002',NULL,N'mother_stu_1438@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (477,239,N'Ramesh Ojha',N'FATHER',N'918802390001',NULL,N'father_stu_1439@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (478,239,N'Sunita Ojha',N'MOTHER',N'918802390002',NULL,N'mother_stu_1439@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (479,240,N'Ramesh Sandhu',N'FATHER',N'918802400001',NULL,N'father_stu_1440@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (480,240,N'Sunita Sandhu',N'MOTHER',N'918802400002',NULL,N'mother_stu_1440@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (481,241,N'Ramesh Upadhyay',N'FATHER',N'918802410001',NULL,N'father_stu_1441@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (482,241,N'Sunita Upadhyay',N'MOTHER',N'918802410002',NULL,N'mother_stu_1441@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (483,242,N'Ramesh Srivastava',N'FATHER',N'918802420001',NULL,N'father_stu_1442@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (484,242,N'Sunita Srivastava',N'MOTHER',N'918802420002',NULL,N'mother_stu_1442@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (485,243,N'Ramesh Singh',N'FATHER',N'918802430001',NULL,N'father_stu_1443@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (486,243,N'Sunita Singh',N'MOTHER',N'918802430002',NULL,N'mother_stu_1443@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (487,244,N'Ramesh Sundaram',N'FATHER',N'918802440001',NULL,N'father_stu_1444@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (488,244,N'Sunita Sundaram',N'MOTHER',N'918802440002',NULL,N'mother_stu_1444@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (489,245,N'Ramesh Joshi',N'FATHER',N'918802450001',NULL,N'father_stu_1445@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (490,245,N'Sunita Joshi',N'MOTHER',N'918802450002',NULL,N'mother_stu_1445@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (491,246,N'Ramesh Yadav',N'FATHER',N'918802460001',NULL,N'father_stu_1446@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (492,246,N'Sunita Yadav',N'MOTHER',N'918802460002',NULL,N'mother_stu_1446@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (493,247,N'Ramesh Roy',N'FATHER',N'918802470001',NULL,N'father_stu_1447@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (494,247,N'Sunita Roy',N'MOTHER',N'918802470002',NULL,N'mother_stu_1447@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (495,248,N'Ramesh Saxena',N'FATHER',N'918802480001',NULL,N'father_stu_1448@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (496,248,N'Sunita Saxena',N'MOTHER',N'918802480002',NULL,N'mother_stu_1448@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (497,249,N'Ramesh Saini',N'FATHER',N'918802490001',NULL,N'father_stu_1449@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (498,249,N'Sunita Saini',N'MOTHER',N'918802490002',NULL,N'mother_stu_1449@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (499,250,N'Ramesh Chawla',N'FATHER',N'918802500001',NULL,N'father_stu_1450@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (500,250,N'Sunita Chawla',N'MOTHER',N'918802500002',NULL,N'mother_stu_1450@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (501,251,N'Ramesh Grover',N'FATHER',N'918802510001',NULL,N'father_stu_1451@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (502,251,N'Sunita Grover',N'MOTHER',N'918802510002',NULL,N'mother_stu_1451@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (503,252,N'Ramesh Rajput',N'FATHER',N'918802520001',NULL,N'father_stu_1452@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (504,252,N'Sunita Rajput',N'MOTHER',N'918802520002',NULL,N'mother_stu_1452@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (505,253,N'Ramesh Singhal',N'FATHER',N'918802530001',NULL,N'father_stu_1453@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (506,253,N'Sunita Singhal',N'MOTHER',N'918802530002',NULL,N'mother_stu_1453@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (507,254,N'Ramesh Gowda',N'FATHER',N'918802540001',NULL,N'father_stu_1454@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (508,254,N'Sunita Gowda',N'MOTHER',N'918802540002',NULL,N'mother_stu_1454@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (509,255,N'Ramesh Balakrishnan',N'FATHER',N'918802550001',NULL,N'father_stu_1455@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (510,255,N'Sunita Balakrishnan',N'MOTHER',N'918802550002',NULL,N'mother_stu_1455@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (511,256,N'Ramesh Goswami',N'FATHER',N'918802560001',NULL,N'father_stu_1456@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (512,256,N'Sunita Goswami',N'MOTHER',N'918802560002',NULL,N'mother_stu_1456@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (513,257,N'Ramesh Choudhury',N'FATHER',N'918802570001',NULL,N'father_stu_1457@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (514,257,N'Sunita Choudhury',N'MOTHER',N'918802570002',NULL,N'mother_stu_1457@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (515,258,N'Ramesh Bhardwaj',N'FATHER',N'918802580001',NULL,N'father_stu_1458@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (516,258,N'Sunita Bhardwaj',N'MOTHER',N'918802580002',NULL,N'mother_stu_1458@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (517,259,N'Ramesh Gupta',N'FATHER',N'918802590001',NULL,N'father_stu_1459@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (518,259,N'Sunita Gupta',N'MOTHER',N'918802590002',NULL,N'mother_stu_1459@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (519,260,N'Ramesh Madan',N'FATHER',N'918802600001',NULL,N'father_stu_1460@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (520,260,N'Sunita Madan',N'MOTHER',N'918802600002',NULL,N'mother_stu_1460@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (521,261,N'Ramesh Gowda',N'FATHER',N'918802610001',NULL,N'father_stu_1461@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (522,261,N'Sunita Gowda',N'MOTHER',N'918802610002',NULL,N'mother_stu_1461@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (523,262,N'Ramesh Walia',N'FATHER',N'918802620001',NULL,N'father_stu_1462@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (524,262,N'Sunita Walia',N'MOTHER',N'918802620002',NULL,N'mother_stu_1462@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (525,263,N'Ramesh Reddy',N'FATHER',N'918802630001',NULL,N'father_stu_1463@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (526,263,N'Sunita Reddy',N'MOTHER',N'918802630002',NULL,N'mother_stu_1463@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (527,264,N'Ramesh Tripathi',N'FATHER',N'918802640001',NULL,N'father_stu_1464@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (528,264,N'Sunita Tripathi',N'MOTHER',N'918802640002',NULL,N'mother_stu_1464@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (529,265,N'Ramesh Sethi',N'FATHER',N'918802650001',NULL,N'father_stu_1465@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (530,265,N'Sunita Sethi',N'MOTHER',N'918802650002',NULL,N'mother_stu_1465@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (531,266,N'Ramesh Mittal',N'FATHER',N'918802660001',NULL,N'father_stu_1466@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (532,266,N'Sunita Mittal',N'MOTHER',N'918802660002',NULL,N'mother_stu_1466@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (533,267,N'Ramesh Dubey',N'FATHER',N'918802670001',NULL,N'father_stu_1467@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (534,267,N'Sunita Dubey',N'MOTHER',N'918802670002',NULL,N'mother_stu_1467@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (535,268,N'Ramesh Bhat',N'FATHER',N'918802680001',NULL,N'father_stu_1468@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (536,268,N'Sunita Bhat',N'MOTHER',N'918802680002',NULL,N'mother_stu_1468@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (537,269,N'Ramesh Venkatesh',N'FATHER',N'918802690001',NULL,N'father_stu_1469@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (538,269,N'Sunita Venkatesh',N'MOTHER',N'918802690002',NULL,N'mother_stu_1469@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (539,270,N'Ramesh Swaminathan',N'FATHER',N'918802700001',NULL,N'father_stu_1470@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (540,270,N'Sunita Swaminathan',N'MOTHER',N'918802700002',NULL,N'mother_stu_1470@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (541,271,N'Ramesh Nambiar',N'FATHER',N'918802710001',NULL,N'father_stu_1471@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (542,271,N'Sunita Nambiar',N'MOTHER',N'918802710002',NULL,N'mother_stu_1471@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (543,272,N'Ramesh Pandey',N'FATHER',N'918802720001',NULL,N'father_stu_1472@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (544,272,N'Sunita Pandey',N'MOTHER',N'918802720002',NULL,N'mother_stu_1472@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (545,273,N'Ramesh Madan',N'FATHER',N'918802730001',NULL,N'father_stu_1473@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (546,273,N'Sunita Madan',N'MOTHER',N'918802730002',NULL,N'mother_stu_1473@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (547,274,N'Ramesh Kohli',N'FATHER',N'918802740001',NULL,N'father_stu_1474@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (548,274,N'Sunita Kohli',N'MOTHER',N'918802740002',NULL,N'mother_stu_1474@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (549,275,N'Ramesh Mathur',N'FATHER',N'918802750001',NULL,N'father_stu_1475@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (550,275,N'Sunita Mathur',N'MOTHER',N'918802750002',NULL,N'mother_stu_1475@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (551,276,N'Ramesh Mehra',N'FATHER',N'918802760001',NULL,N'father_stu_1476@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (552,276,N'Sunita Mehra',N'MOTHER',N'918802760002',NULL,N'mother_stu_1476@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (553,277,N'Ramesh Pai',N'FATHER',N'918802770001',NULL,N'father_stu_1477@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (554,277,N'Sunita Pai',N'MOTHER',N'918802770002',NULL,N'mother_stu_1477@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (555,278,N'Ramesh Nigam',N'FATHER',N'918802780001',NULL,N'father_stu_1478@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (556,278,N'Sunita Nigam',N'MOTHER',N'918802780002',NULL,N'mother_stu_1478@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (557,279,N'Ramesh Bhowmick',N'FATHER',N'918802790001',NULL,N'father_stu_1479@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (558,279,N'Sunita Bhowmick',N'MOTHER',N'918802790002',NULL,N'mother_stu_1479@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (559,280,N'Ramesh Banerjee',N'FATHER',N'918802800001',NULL,N'father_stu_1480@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (560,280,N'Sunita Banerjee',N'MOTHER',N'918802800002',NULL,N'mother_stu_1480@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (561,281,N'Ramesh Rathore',N'FATHER',N'918802810001',NULL,N'father_stu_1481@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (562,281,N'Sunita Rathore',N'MOTHER',N'918802810002',NULL,N'mother_stu_1481@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (563,282,N'Ramesh Mathur',N'FATHER',N'918802820001',NULL,N'father_stu_1482@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (564,282,N'Sunita Mathur',N'MOTHER',N'918802820002',NULL,N'mother_stu_1482@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (565,283,N'Ramesh Kulkarni',N'FATHER',N'918802830001',NULL,N'father_stu_1483@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (566,283,N'Sunita Kulkarni',N'MOTHER',N'918802830002',NULL,N'mother_stu_1483@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (567,284,N'Ramesh Ganguly',N'FATHER',N'918802840001',NULL,N'father_stu_1484@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (568,284,N'Sunita Ganguly',N'MOTHER',N'918802840002',NULL,N'mother_stu_1484@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (569,285,N'Ramesh Deshmukh',N'FATHER',N'918802850001',NULL,N'father_stu_1485@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (570,285,N'Sunita Deshmukh',N'MOTHER',N'918802850002',NULL,N'mother_stu_1485@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (571,286,N'Ramesh Kapoor',N'FATHER',N'918802860001',NULL,N'father_stu_1486@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (572,286,N'Sunita Kapoor',N'MOTHER',N'918802860002',NULL,N'mother_stu_1486@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (573,287,N'Ramesh Gautam',N'FATHER',N'918802870001',NULL,N'father_stu_1487@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (574,287,N'Sunita Gautam',N'MOTHER',N'918802870002',NULL,N'mother_stu_1487@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (575,288,N'Ramesh Talwar',N'FATHER',N'918802880001',NULL,N'father_stu_1488@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (576,288,N'Sunita Talwar',N'MOTHER',N'918802880002',NULL,N'mother_stu_1488@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (577,289,N'Ramesh Subramanian',N'FATHER',N'918802890001',NULL,N'father_stu_1489@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (578,289,N'Sunita Subramanian',N'MOTHER',N'918802890002',NULL,N'mother_stu_1489@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (579,290,N'Ramesh Munjal',N'FATHER',N'918802900001',NULL,N'father_stu_1490@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (580,290,N'Sunita Munjal',N'MOTHER',N'918802900002',NULL,N'mother_stu_1490@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (581,291,N'Ramesh Banerjee',N'FATHER',N'918802910001',NULL,N'father_stu_1491@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (582,291,N'Sunita Banerjee',N'MOTHER',N'918802910002',NULL,N'mother_stu_1491@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (583,292,N'Ramesh Nambiar',N'FATHER',N'918802920001',NULL,N'father_stu_1492@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (584,292,N'Sunita Nambiar',N'MOTHER',N'918802920002',NULL,N'mother_stu_1492@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (585,293,N'Ramesh Garg',N'FATHER',N'918802930001',NULL,N'father_stu_1493@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (586,293,N'Sunita Garg',N'MOTHER',N'918802930002',NULL,N'mother_stu_1493@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (587,294,N'Ramesh Raju',N'FATHER',N'918802940001',NULL,N'father_stu_1494@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (588,294,N'Sunita Raju',N'MOTHER',N'918802940002',NULL,N'mother_stu_1494@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (589,295,N'Ramesh Nair',N'FATHER',N'918802950001',NULL,N'father_stu_1495@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (590,295,N'Sunita Nair',N'MOTHER',N'918802950002',NULL,N'mother_stu_1495@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (591,296,N'Ramesh Shetty',N'FATHER',N'918802960001',NULL,N'father_stu_1496@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (592,296,N'Sunita Shetty',N'MOTHER',N'918802960002',NULL,N'mother_stu_1496@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (593,297,N'Ramesh Mukherjee',N'FATHER',N'918802970001',NULL,N'father_stu_1497@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (594,297,N'Sunita Mukherjee',N'MOTHER',N'918802970002',NULL,N'mother_stu_1497@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (595,298,N'Ramesh Mishra',N'FATHER',N'918802980001',NULL,N'father_stu_1498@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (596,298,N'Sunita Mishra',N'MOTHER',N'918802980002',NULL,N'mother_stu_1498@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (597,299,N'Ramesh Chakraborty',N'FATHER',N'918802990001',NULL,N'father_stu_1499@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (598,299,N'Sunita Chakraborty',N'MOTHER',N'918802990002',NULL,N'mother_stu_1499@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (599,300,N'Ramesh Rajput',N'FATHER',N'918803000001',NULL,N'father_stu_1500@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (600,300,N'Sunita Rajput',N'MOTHER',N'918803000002',NULL,N'mother_stu_1500@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (601,301,N'Ramesh Kashyap',N'FATHER',N'918803010001',NULL,N'father_stu_1501@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (602,301,N'Sunita Kashyap',N'MOTHER',N'918803010002',NULL,N'mother_stu_1501@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (603,302,N'Ramesh Chakraborty',N'FATHER',N'918803020001',NULL,N'father_stu_1502@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (604,302,N'Sunita Chakraborty',N'MOTHER',N'918803020002',NULL,N'mother_stu_1502@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (605,303,N'Ramesh Pillai',N'FATHER',N'918803030001',NULL,N'father_stu_1503@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (606,303,N'Sunita Pillai',N'MOTHER',N'918803030002',NULL,N'mother_stu_1503@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (607,304,N'Ramesh Anand',N'FATHER',N'918803040001',NULL,N'father_stu_1504@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (608,304,N'Sunita Anand',N'MOTHER',N'918803040002',NULL,N'mother_stu_1504@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (609,305,N'Ramesh Bhattacharya',N'FATHER',N'918803050001',NULL,N'father_stu_1505@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (610,305,N'Sunita Bhattacharya',N'MOTHER',N'918803050002',NULL,N'mother_stu_1505@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (611,306,N'Ramesh Srivastava',N'FATHER',N'918803060001',NULL,N'father_stu_1506@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (612,306,N'Sunita Srivastava',N'MOTHER',N'918803060002',NULL,N'mother_stu_1506@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (613,307,N'Ramesh Khatri',N'FATHER',N'918803070001',NULL,N'father_stu_1507@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (614,307,N'Sunita Khatri',N'MOTHER',N'918803070002',NULL,N'mother_stu_1507@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (615,308,N'Ramesh Mittal',N'FATHER',N'918803080001',NULL,N'father_stu_1508@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (616,308,N'Sunita Mittal',N'MOTHER',N'918803080002',NULL,N'mother_stu_1508@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (617,309,N'Ramesh Suri',N'FATHER',N'918803090001',NULL,N'father_stu_1509@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (618,309,N'Sunita Suri',N'MOTHER',N'918803090002',NULL,N'mother_stu_1509@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (619,310,N'Ramesh Ananthakrishnan',N'FATHER',N'918803100001',NULL,N'father_stu_1510@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (620,310,N'Sunita Ananthakrishnan',N'MOTHER',N'918803100002',NULL,N'mother_stu_1510@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (621,311,N'Ramesh Majumdar',N'FATHER',N'918803110001',NULL,N'father_stu_1511@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (622,311,N'Sunita Majumdar',N'MOTHER',N'918803110002',NULL,N'mother_stu_1511@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (623,312,N'Ramesh Jha',N'FATHER',N'918803120001',NULL,N'father_stu_1512@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (624,312,N'Sunita Jha',N'MOTHER',N'918803120002',NULL,N'mother_stu_1512@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (625,313,N'Ramesh Raman',N'FATHER',N'918803130001',NULL,N'father_stu_1513@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (626,313,N'Sunita Raman',N'MOTHER',N'918803130002',NULL,N'mother_stu_1513@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (627,314,N'Ramesh Sodhi',N'FATHER',N'918803140001',NULL,N'father_stu_1514@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (628,314,N'Sunita Sodhi',N'MOTHER',N'918803140002',NULL,N'mother_stu_1514@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (629,315,N'Ramesh Roy',N'FATHER',N'918803150001',NULL,N'father_stu_1515@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (630,315,N'Sunita Roy',N'MOTHER',N'918803150002',NULL,N'mother_stu_1515@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (631,316,N'Ramesh Bansal',N'FATHER',N'918803160001',NULL,N'father_stu_1516@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (632,316,N'Sunita Bansal',N'MOTHER',N'918803160002',NULL,N'mother_stu_1516@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (633,317,N'Ramesh Vashist',N'FATHER',N'918803170001',NULL,N'father_stu_1517@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (634,317,N'Sunita Vashist',N'MOTHER',N'918803170002',NULL,N'mother_stu_1517@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (635,318,N'Ramesh Bajwa',N'FATHER',N'918803180001',NULL,N'father_stu_1518@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (636,318,N'Sunita Bajwa',N'MOTHER',N'918803180002',NULL,N'mother_stu_1518@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (637,319,N'Ramesh Krishnan',N'FATHER',N'918803190001',NULL,N'father_stu_1519@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (638,319,N'Sunita Krishnan',N'MOTHER',N'918803190002',NULL,N'mother_stu_1519@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (639,320,N'Ramesh Somayaji',N'FATHER',N'918803200001',NULL,N'father_stu_1520@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (640,320,N'Sunita Somayaji',N'MOTHER',N'918803200002',NULL,N'mother_stu_1520@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (641,321,N'Ramesh Rathore',N'FATHER',N'918803210001',NULL,N'father_stu_1521@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (642,321,N'Sunita Rathore',N'MOTHER',N'918803210002',NULL,N'mother_stu_1521@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (643,322,N'Ramesh Upadhyay',N'FATHER',N'918803220001',NULL,N'father_stu_1522@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (644,322,N'Sunita Upadhyay',N'MOTHER',N'918803220002',NULL,N'mother_stu_1522@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (645,323,N'Ramesh Nair',N'FATHER',N'918803230001',NULL,N'father_stu_1523@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (646,323,N'Sunita Nair',N'MOTHER',N'918803230002',NULL,N'mother_stu_1523@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (647,324,N'Ramesh Raman',N'FATHER',N'918803240001',NULL,N'father_stu_1524@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (648,324,N'Sunita Raman',N'MOTHER',N'918803240002',NULL,N'mother_stu_1524@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (649,325,N'Ramesh Bhowmick',N'FATHER',N'918803250001',NULL,N'father_stu_1525@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (650,325,N'Sunita Bhowmick',N'MOTHER',N'918803250002',NULL,N'mother_stu_1525@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (651,326,N'Ramesh Nagpal',N'FATHER',N'918803260001',NULL,N'father_stu_1526@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (652,326,N'Sunita Nagpal',N'MOTHER',N'918803260002',NULL,N'mother_stu_1526@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (653,327,N'Ramesh Mehra',N'FATHER',N'918803270001',NULL,N'father_stu_1527@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (654,327,N'Sunita Mehra',N'MOTHER',N'918803270002',NULL,N'mother_stu_1527@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (655,328,N'Ramesh Chauhan',N'FATHER',N'918803280001',NULL,N'father_stu_1528@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (656,328,N'Sunita Chauhan',N'MOTHER',N'918803280002',NULL,N'mother_stu_1528@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (657,329,N'Ramesh Deshmukh',N'FATHER',N'918803290001',NULL,N'father_stu_1529@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (658,329,N'Sunita Deshmukh',N'MOTHER',N'918803290002',NULL,N'mother_stu_1529@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (659,330,N'Ramesh Singh',N'FATHER',N'918803300001',NULL,N'father_stu_1530@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (660,330,N'Sunita Singh',N'MOTHER',N'918803300002',NULL,N'mother_stu_1530@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (661,331,N'Ramesh Nair',N'FATHER',N'918803310001',NULL,N'father_stu_1531@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (662,331,N'Sunita Nair',N'MOTHER',N'918803310002',NULL,N'mother_stu_1531@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (663,332,N'Ramesh Menon',N'FATHER',N'918803320001',NULL,N'father_stu_1532@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (664,332,N'Sunita Menon',N'MOTHER',N'918803320002',NULL,N'mother_stu_1532@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (665,333,N'Ramesh Sachdeva',N'FATHER',N'918803330001',NULL,N'father_stu_1533@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (666,333,N'Sunita Sachdeva',N'MOTHER',N'918803330002',NULL,N'mother_stu_1533@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (667,334,N'Ramesh Saxena',N'FATHER',N'918803340001',NULL,N'father_stu_1534@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (668,334,N'Sunita Saxena',N'MOTHER',N'918803340002',NULL,N'mother_stu_1534@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (669,335,N'Ramesh Prasad',N'FATHER',N'918803350001',NULL,N'father_stu_1535@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (670,335,N'Sunita Prasad',N'MOTHER',N'918803350002',NULL,N'mother_stu_1535@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (671,336,N'Ramesh Kulkarni',N'FATHER',N'918803360001',NULL,N'father_stu_1536@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (672,336,N'Sunita Kulkarni',N'MOTHER',N'918803360002',NULL,N'mother_stu_1536@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (673,337,N'Ramesh Rao',N'FATHER',N'918803370001',NULL,N'father_stu_1537@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (674,337,N'Sunita Rao',N'MOTHER',N'918803370002',NULL,N'mother_stu_1537@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (675,338,N'Ramesh Mitra',N'FATHER',N'918803380001',NULL,N'father_stu_1538@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (676,338,N'Sunita Mitra',N'MOTHER',N'918803380002',NULL,N'mother_stu_1538@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (677,339,N'Ramesh Saxena',N'FATHER',N'918803390001',NULL,N'father_stu_1539@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (678,339,N'Sunita Saxena',N'MOTHER',N'918803390002',NULL,N'mother_stu_1539@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (679,340,N'Ramesh Khatri',N'FATHER',N'918803400001',NULL,N'father_stu_1540@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (680,340,N'Sunita Khatri',N'MOTHER',N'918803400002',NULL,N'mother_stu_1540@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (681,341,N'Ramesh Mishra',N'FATHER',N'918803410001',NULL,N'father_stu_1541@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (682,341,N'Sunita Mishra',N'MOTHER',N'918803410002',NULL,N'mother_stu_1541@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (683,342,N'Ramesh Balakrishnan',N'FATHER',N'918803420001',NULL,N'father_stu_1542@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (684,342,N'Sunita Balakrishnan',N'MOTHER',N'918803420002',NULL,N'mother_stu_1542@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (685,343,N'Ramesh Kaushik',N'FATHER',N'918803430001',NULL,N'father_stu_1543@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (686,343,N'Sunita Kaushik',N'MOTHER',N'918803430002',NULL,N'mother_stu_1543@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (687,344,N'Ramesh Chatterjee',N'FATHER',N'918803440001',NULL,N'father_stu_1544@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (688,344,N'Sunita Chatterjee',N'MOTHER',N'918803440002',NULL,N'mother_stu_1544@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (689,345,N'Ramesh Gill',N'FATHER',N'918803450001',NULL,N'father_stu_1545@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (690,345,N'Sunita Gill',N'MOTHER',N'918803450002',NULL,N'mother_stu_1545@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (691,346,N'Ramesh Mahajan',N'FATHER',N'918803460001',NULL,N'father_stu_1546@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (692,346,N'Sunita Mahajan',N'MOTHER',N'918803460002',NULL,N'mother_stu_1546@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (693,347,N'Ramesh Subramanian',N'FATHER',N'918803470001',NULL,N'father_stu_1547@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (694,347,N'Sunita Subramanian',N'MOTHER',N'918803470002',NULL,N'mother_stu_1547@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (695,348,N'Ramesh Bhatia',N'FATHER',N'918803480001',NULL,N'father_stu_1548@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (696,348,N'Sunita Bhatia',N'MOTHER',N'918803480002',NULL,N'mother_stu_1548@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (697,349,N'Ramesh Dwivedi',N'FATHER',N'918803490001',NULL,N'father_stu_1549@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (698,349,N'Sunita Dwivedi',N'MOTHER',N'918803490002',NULL,N'mother_stu_1549@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (699,350,N'Ramesh Malik',N'FATHER',N'918803500001',NULL,N'father_stu_1550@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (700,350,N'Sunita Malik',N'MOTHER',N'918803500002',NULL,N'mother_stu_1550@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (701,351,N'Ramesh Krishnan',N'FATHER',N'918803510001',NULL,N'father_stu_1551@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (702,351,N'Sunita Krishnan',N'MOTHER',N'918803510002',NULL,N'mother_stu_1551@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (703,352,N'Ramesh Acharya',N'FATHER',N'918803520001',NULL,N'father_stu_1552@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (704,352,N'Sunita Acharya',N'MOTHER',N'918803520002',NULL,N'mother_stu_1552@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (705,353,N'Ramesh Nair',N'FATHER',N'918803530001',NULL,N'father_stu_1553@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (706,353,N'Sunita Nair',N'MOTHER',N'918803530002',NULL,N'mother_stu_1553@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (707,354,N'Ramesh Ghosh',N'FATHER',N'918803540001',NULL,N'father_stu_1554@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (708,354,N'Sunita Ghosh',N'MOTHER',N'918803540002',NULL,N'mother_stu_1554@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (709,355,N'Ramesh Awasthi',N'FATHER',N'918803550001',NULL,N'father_stu_1555@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (710,355,N'Sunita Awasthi',N'MOTHER',N'918803550002',NULL,N'mother_stu_1555@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (711,356,N'Ramesh Mehta',N'FATHER',N'918803560001',NULL,N'father_stu_1556@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (712,356,N'Sunita Mehta',N'MOTHER',N'918803560002',NULL,N'mother_stu_1556@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (713,357,N'Ramesh Madan',N'FATHER',N'918803570001',NULL,N'father_stu_1557@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (714,357,N'Sunita Madan',N'MOTHER',N'918803570002',NULL,N'mother_stu_1557@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (715,358,N'Ramesh Dhillon',N'FATHER',N'918803580001',NULL,N'father_stu_1558@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (716,358,N'Sunita Dhillon',N'MOTHER',N'918803580002',NULL,N'mother_stu_1558@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (717,359,N'Ramesh Nagpal',N'FATHER',N'918803590001',NULL,N'father_stu_1559@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (718,359,N'Sunita Nagpal',N'MOTHER',N'918803590002',NULL,N'mother_stu_1559@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (719,360,N'Ramesh Agarwal',N'FATHER',N'918803600001',NULL,N'father_stu_1560@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (720,360,N'Sunita Agarwal',N'MOTHER',N'918803600002',NULL,N'mother_stu_1560@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (721,361,N'Ramesh Chowdary',N'FATHER',N'918803610001',NULL,N'father_stu_1561@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (722,361,N'Sunita Chowdary',N'MOTHER',N'918803610002',NULL,N'mother_stu_1561@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (723,362,N'Ramesh Goswami',N'FATHER',N'918803620001',NULL,N'father_stu_1562@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (724,362,N'Sunita Goswami',N'MOTHER',N'918803620002',NULL,N'mother_stu_1562@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (725,363,N'Ramesh Sidhu',N'FATHER',N'918803630001',NULL,N'father_stu_1563@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (726,363,N'Sunita Sidhu',N'MOTHER',N'918803630002',NULL,N'mother_stu_1563@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (727,364,N'Ramesh Raju',N'FATHER',N'918803640001',NULL,N'father_stu_1564@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (728,364,N'Sunita Raju',N'MOTHER',N'918803640002',NULL,N'mother_stu_1564@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (729,365,N'Ramesh Das',N'FATHER',N'918803650001',NULL,N'father_stu_1565@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (730,365,N'Sunita Das',N'MOTHER',N'918803650002',NULL,N'mother_stu_1565@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (731,366,N'Ramesh Rao',N'FATHER',N'918803660001',NULL,N'father_stu_1566@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (732,366,N'Sunita Rao',N'MOTHER',N'918803660002',NULL,N'mother_stu_1566@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (733,367,N'Ramesh Menon',N'FATHER',N'918803670001',NULL,N'father_stu_1567@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (734,367,N'Sunita Menon',N'MOTHER',N'918803670002',NULL,N'mother_stu_1567@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (735,368,N'Ramesh Chawla',N'FATHER',N'918803680001',NULL,N'father_stu_1568@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (736,368,N'Sunita Chawla',N'MOTHER',N'918803680002',NULL,N'mother_stu_1568@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (737,369,N'Ramesh Chopra',N'FATHER',N'918803690001',NULL,N'father_stu_1569@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (738,369,N'Sunita Chopra',N'MOTHER',N'918803690002',NULL,N'mother_stu_1569@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (739,370,N'Ramesh Parmar',N'FATHER',N'918803700001',NULL,N'father_stu_1570@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (740,370,N'Sunita Parmar',N'MOTHER',N'918803700002',NULL,N'mother_stu_1570@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (741,371,N'Ramesh Patel',N'FATHER',N'918803710001',NULL,N'father_stu_1571@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (742,371,N'Sunita Patel',N'MOTHER',N'918803710002',NULL,N'mother_stu_1571@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (743,372,N'Ramesh Kapoor',N'FATHER',N'918803720001',NULL,N'father_stu_1572@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (744,372,N'Sunita Kapoor',N'MOTHER',N'918803720002',NULL,N'mother_stu_1572@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (745,373,N'Ramesh Sundaram',N'FATHER',N'918803730001',NULL,N'father_stu_1573@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (746,373,N'Sunita Sundaram',N'MOTHER',N'918803730002',NULL,N'mother_stu_1573@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (747,374,N'Ramesh Garg',N'FATHER',N'918803740001',NULL,N'father_stu_1574@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (748,374,N'Sunita Garg',N'MOTHER',N'918803740002',NULL,N'mother_stu_1574@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (749,375,N'Ramesh Roy',N'FATHER',N'918803750001',NULL,N'father_stu_1575@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (750,375,N'Sunita Roy',N'MOTHER',N'918803750002',NULL,N'mother_stu_1575@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (751,376,N'Ramesh Gautam',N'FATHER',N'918803760001',NULL,N'father_stu_1576@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (752,376,N'Sunita Gautam',N'MOTHER',N'918803760002',NULL,N'mother_stu_1576@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (753,377,N'Ramesh Thakur',N'FATHER',N'918803770001',NULL,N'father_stu_1577@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (754,377,N'Sunita Thakur',N'MOTHER',N'918803770002',NULL,N'mother_stu_1577@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (755,378,N'Ramesh Yadav',N'FATHER',N'918803780001',NULL,N'father_stu_1578@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (756,378,N'Sunita Yadav',N'MOTHER',N'918803780002',NULL,N'mother_stu_1578@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (757,379,N'Ramesh Tripathi',N'FATHER',N'918803790001',NULL,N'father_stu_1579@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (758,379,N'Sunita Tripathi',N'MOTHER',N'918803790002',NULL,N'mother_stu_1579@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (759,380,N'Ramesh Goel',N'FATHER',N'918803800001',NULL,N'father_stu_1580@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (760,380,N'Sunita Goel',N'MOTHER',N'918803800002',NULL,N'mother_stu_1580@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (761,381,N'Ramesh Grewal',N'FATHER',N'918803810001',NULL,N'father_stu_1581@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (762,381,N'Sunita Grewal',N'MOTHER',N'918803810002',NULL,N'mother_stu_1581@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (763,382,N'Ramesh Reddy',N'FATHER',N'918803820001',NULL,N'father_stu_1582@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (764,382,N'Sunita Reddy',N'MOTHER',N'918803820002',NULL,N'mother_stu_1582@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (765,383,N'Ramesh Yadav',N'FATHER',N'918803830001',NULL,N'father_stu_1583@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (766,383,N'Sunita Yadav',N'MOTHER',N'918803830002',NULL,N'mother_stu_1583@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (767,384,N'Ramesh Malik',N'FATHER',N'918803840001',NULL,N'father_stu_1584@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (768,384,N'Sunita Malik',N'MOTHER',N'918803840002',NULL,N'mother_stu_1584@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (769,385,N'Ramesh Gill',N'FATHER',N'918803850001',NULL,N'father_stu_1585@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (770,385,N'Sunita Gill',N'MOTHER',N'918803850002',NULL,N'mother_stu_1585@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (771,386,N'Ramesh Hegde',N'FATHER',N'918803860001',NULL,N'father_stu_1586@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (772,386,N'Sunita Hegde',N'MOTHER',N'918803860002',NULL,N'mother_stu_1586@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (773,387,N'Ramesh Ganguly',N'FATHER',N'918803870001',NULL,N'father_stu_1587@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (774,387,N'Sunita Ganguly',N'MOTHER',N'918803870002',NULL,N'mother_stu_1587@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (775,388,N'Ramesh Munjal',N'FATHER',N'918803880001',NULL,N'father_stu_1588@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (776,388,N'Sunita Munjal',N'MOTHER',N'918803880002',NULL,N'mother_stu_1588@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (777,389,N'Ramesh Choudhury',N'FATHER',N'918803890001',NULL,N'father_stu_1589@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (778,389,N'Sunita Choudhury',N'MOTHER',N'918803890002',NULL,N'mother_stu_1589@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (779,390,N'Ramesh Chatterjee',N'FATHER',N'918803900001',NULL,N'father_stu_1590@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (780,390,N'Sunita Chatterjee',N'MOTHER',N'918803900002',NULL,N'mother_stu_1590@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (781,391,N'Ramesh Pillai',N'FATHER',N'918803910001',NULL,N'father_stu_1591@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (782,391,N'Sunita Pillai',N'MOTHER',N'918803910002',NULL,N'mother_stu_1591@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (783,392,N'Ramesh Srinivasan',N'FATHER',N'918803920001',NULL,N'father_stu_1592@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (784,392,N'Sunita Srinivasan',N'MOTHER',N'918803920002',NULL,N'mother_stu_1592@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1),
      (785,393,N'Ramesh Asthana',N'FATHER',N'918803930001',NULL,N'father_stu_1593@parentmail.com',N'Civil Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (786,393,N'Sunita Asthana',N'MOTHER',N'918803930002',NULL,N'mother_stu_1593@parentmail.com',N'Medical Practitioner',N'Professional Services',1,0,1,1,1,1),
      (787,394,N'Ramesh Tandon',N'FATHER',N'918803940001',NULL,N'father_stu_1594@parentmail.com',N'Banking Manager',N'Corporate Sector',1,1,1,1,1,1),
      (788,394,N'Sunita Tandon',N'MOTHER',N'918803940002',NULL,N'mother_stu_1594@parentmail.com',N'Educator',N'Professional Services',1,0,1,1,1,1),
      (789,395,N'Ramesh Uppal',N'FATHER',N'918803950001',NULL,N'father_stu_1595@parentmail.com',N'Chartered Accountant',N'Corporate Sector',1,1,1,1,1,1),
      (790,395,N'Sunita Uppal',N'MOTHER',N'918803950002',NULL,N'mother_stu_1595@parentmail.com',N'Senior Banking Officer',N'Professional Services',1,0,1,1,1,1),
      (791,396,N'Ramesh Varma',N'FATHER',N'918803960001',NULL,N'father_stu_1596@parentmail.com',N'Doctor',N'Corporate Sector',1,1,1,1,1,1),
      (792,396,N'Sunita Varma',N'MOTHER',N'918803960002',NULL,N'mother_stu_1596@parentmail.com',N'HR Director',N'Professional Services',1,0,1,1,1,1),
      (793,397,N'Ramesh Swaminathan',N'FATHER',N'918803970001',NULL,N'father_stu_1597@parentmail.com',N'Business Owner',N'Corporate Sector',1,1,1,1,1,1),
      (794,397,N'Sunita Swaminathan',N'MOTHER',N'918803970002',NULL,N'mother_stu_1597@parentmail.com',N'Scientist',N'Professional Services',1,0,1,1,1,1),
      (795,398,N'Ramesh Pathak',N'FATHER',N'918803980001',NULL,N'father_stu_1598@parentmail.com',N'Government Officer',N'Corporate Sector',1,1,1,1,1,1),
      (796,398,N'Sunita Pathak',N'MOTHER',N'918803980002',NULL,N'mother_stu_1598@parentmail.com',N'Entrepreneur',N'Professional Services',1,0,1,1,1,1),
      (797,399,N'Ramesh Pandey',N'FATHER',N'918803990001',NULL,N'father_stu_1599@parentmail.com',N'Professor',N'Corporate Sector',1,1,1,1,1,1),
      (798,399,N'Sunita Pandey',N'MOTHER',N'918803990002',NULL,N'mother_stu_1599@parentmail.com',N'Financial Analyst',N'Professional Services',1,0,1,1,1,1),
      (799,400,N'Ramesh Chowdary',N'FATHER',N'918804000001',NULL,N'father_stu_1600@parentmail.com',N'Software Engineer',N'Corporate Sector',1,1,1,1,1,1),
      (800,400,N'Sunita Chowdary',N'MOTHER',N'918804000002',NULL,N'mother_stu_1600@parentmail.com',N'Software Architect',N'Professional Services',1,0,1,1,1,1);

    SET IDENTITY_INSERT student_schema.student_guardian OFF;

    /* ============================================================
       4.3 ALUMNI PROFILES & STORIES (Verified 10th Class Graduates)
       ============================================================ */
    SET IDENTITY_INSERT alumni_schema.alumni_profile ON;
    INSERT INTO alumni_schema.alumni_profile
      (alumni_id,school_id,branch_id,academic_year_id,class_id,section_id,student_id,passout_batch_year,
       current_role,organisation_name,industry_name,location_city,location_country,
       linkedin_profile_url,verification_status,verified_at,verified_by,profile_photo_url,
       is_active,created_by)
    VALUES
      (1,1,1,101,10,19,401,2025,N'Senior Software Engineer',N'Google',N'Technology & Cloud',N'Bengaluru',N'India',N'https://linkedin.com/in/alumni-google',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_1.jpg',1,1),
      (2,1,1,101,10,19,402,2025,N'Machine Learning Engineer',N'Microsoft',N'Artificial Intelligence',N'Hyderabad',N'India',N'https://linkedin.com/in/alumni-msft',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_2.jpg',1,1),
      (3,1,1,101,10,19,403,2025,N'Robotics Systems Engineer',N'ISRO',N'Aerospace Engineering',N'Bengaluru',N'India',N'https://linkedin.com/in/alumni-isro',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_3.jpg',1,1),
      (4,1,1,101,10,19,404,2025,N'Senior Cloud Architect',N'Amazon Web Services',N'Cloud Computing',N'Hyderabad',N'India',N'https://linkedin.com/in/alumni-aws',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_4.jpg',1,1),
      (5,1,1,101,10,19,405,2025,N'Cybersecurity Research Lead',N'Tata Consultancy Services',N'Information Security',N'Pune',N'India',N'https://linkedin.com/in/alumni-tcs',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_5.jpg',1,1),
      (6,1,1,101,10,20,406,2025,N'Lead Systems Architect',N'Zoho Corporation',N'Enterprise SaaS',N'Chennai',N'India',N'https://linkedin.com/in/alumni-zoho',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_6.jpg',1,1),
      (7,1,1,101,10,20,407,2025,N'Postdoctoral Research Scholar',N'IIT Madras',N'Quantum Computing',N'Chennai',N'India',N'https://linkedin.com/in/alumni-iitm',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_7.jpg',1,1),
      (8,1,1,101,10,20,408,2025,N'Resident Physician',N'AIIMS',N'Healthcare & Medicine',N'New Delhi',N'India',N'https://linkedin.com/in/alumni-aiims',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_8.jpg',1,1),
      (9,1,1,101,10,20,409,2025,N'Data Science Director',N'Flipkart',N'E-Commerce & Analytics',N'Bengaluru',N'India',N'https://linkedin.com/in/alumni-flipkart',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_9.jpg',1,1),
      (10,1,1,101,10,20,410,2025,N'Product Design Lead',N'Adobe',N'Digital Media',N'Noida',N'India',N'https://linkedin.com/in/alumni-adobe',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_10.jpg',1,1),
      (11,1,2,101,20,39,411,2025,N'Embedded Systems Engineer',N'Qualcomm',N'Semiconductors',N'Hyderabad',N'India',N'https://linkedin.com/in/alumni-qualcomm',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_11.jpg',1,1),
      (12,1,2,101,20,39,412,2025,N'Aerospace Dynamics Lead',N'DRDO',N'Defense Research',N'Hyderabad',N'India',N'https://linkedin.com/in/alumni-drdo',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_12.jpg',1,1),
      (13,1,2,101,20,39,413,2025,N'Biomedical Device Architect',N'Siemens Healthineers',N'Healthcare Tech',N'Bengaluru',N'India',N'https://linkedin.com/in/alumni-siemens',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_13.jpg',1,1),
      (14,1,2,101,20,39,414,2025,N'Quantitative Financial Analyst',N'Goldman Sachs',N'Investment Banking',N'Bengaluru',N'India',N'https://linkedin.com/in/alumni-gs',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_14.jpg',1,1),
      (15,1,2,101,20,39,415,2025,N'Blockchain Protocol Architect',N'Polygon Labs',N'Web3 Infrastructure',N'Bengaluru',N'India',N'https://linkedin.com/in/alumni-polygon',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_15.jpg',1,1),
      (16,1,2,101,20,40,416,2025,N'Renewable Energy Consultant',N'Tata Power Solar',N'Clean Energy',N'Mumbai',N'India',N'https://linkedin.com/in/alumni-tatapower',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_16.jpg',1,1),
      (17,1,2,101,20,40,417,2025,N'Senior Autonomous Vehicle Eng',N'Ola Electric',N'Electric Mobility',N'Bengaluru',N'India',N'https://linkedin.com/in/alumni-ola',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_17.jpg',1,1),
      (18,1,2,101,20,40,418,2025,N'AI Ethics & Governance Fellow',N'NITI Aayog',N'Public Policy & AI',N'New Delhi',N'India',N'https://linkedin.com/in/alumni-niti',N'VERIFIED','2026-01-15T10:00:00',1,N'https://images.schoolname.edu/alumni/profile_18.jpg',1,1),
      (19,1,2,101,20,40,419,2025,N'Full Stack Lead Engineer',N'Swiggy',N'Consumer Tech',N'Bengaluru',N'India',N'https://linkedin.com/in/alumni-swiggy',N'PENDING',NULL,NULL,N'https://images.schoolname.edu/alumni/profile_19.jpg',1,1),
      (20,1,2,101,20,40,420,2025,N'Clinical Research Specialist',N'Dr. Reddys Laboratories',N'Pharmaceuticals',N'Hyderabad',N'India',N'https://linkedin.com/in/alumni-drreddys',N'PENDING',NULL,NULL,N'https://images.schoolname.edu/alumni/profile_20.jpg',1,1);

    SET IDENTITY_INSERT alumni_schema.alumni_profile OFF;

    SET IDENTITY_INSERT alumni_schema.alumni_story ON;
    INSERT INTO alumni_schema.alumni_story
      (alumni_story_id,school_id,branch_id,alumni_id,story_title,story_content,is_published,created_by)
    VALUES
      (1,1,1,1,N'From Classroom to Google: Engineering at Global Scale',N'Reflecting on my early coding projects in the school computer lab that shaped my journey into distributed systems.',1,1),
      (2,1,1,2,N'Pioneering Machine Learning Models at Microsoft',N'How foundational math instruction helped inspire my passion for neural networks and large language models.',1,1),
      (3,1,1,3,N'Reaching the Stars: Designing Robotics for ISRO',N'Participating in school science exhibitions laid the groundwork for my career in spacecraft systems design.',1,1),
      (4,1,2,4,N'Architecting High-Scale Cloud Systems at AWS',N'Problem-solving discipline and teamwork nurtured in school athletics provided the endurance for tech leadership.',1,1),
      (5,1,2,5,N'Safeguarding Critical Infrastructure Through Cybersecurity',N'Analytical thinking fostered by my teachers inspired me to protect digital applications from emerging threats.',1,1),
      (6,1,2,6,N'Building World-Class Enterprise SaaS at Zoho',N'From school science projects to creating scalable software used by millions across the globe.',1,1);
    SET IDENTITY_INSERT alumni_schema.alumni_story OFF;

    /* ============================================================
       5. EXAMS, SCHEDULES & RESULTS
       Includes completed Mid Term Assessment (Aug 2026) and upcoming
       Periodic Assessment 2 (starting Oct 8, 2026) for School 1, Branch 1.
       ============================================================ */
    SET IDENTITY_INSERT management_schema.exam ON;
    -- 5A. Completed Mid Term Assessment 2026 (All 40 Sections)
    INSERT INTO management_schema.exam
      (exam_id,school_id,branch_id,academic_year_id,class_id,section_id,
       exam_name,exam_category,start_date,end_date,status,is_active,created_by)
    SELECT
      sec.section_id,
      1,
      CASE WHEN sec.class_id <= 10 THEN 1 ELSE 2 END,
      1,
      sec.class_id,
      sec.section_id,
      N'Mid Term Assessment 2026',
      N'MID_TERM',
      '2026-08-10',
      '2026-08-16',
      N'COMPLETED',
      1,
      1
    FROM management_schema.section sec;

    -- 5B. Upcoming Periodic Assessment 2 - 2026 (School 1, Branch 1: Sections 1..20, starting tomorrow 2026-10-08)
    INSERT INTO management_schema.exam
      (exam_id,school_id,branch_id,academic_year_id,class_id,section_id,
       exam_name,exam_category,start_date,end_date,status,is_active,created_by)
    SELECT
      40 + sec.section_id,
      1,
      1,
      1,
      sec.class_id,
      sec.section_id,
      N'Periodic Assessment 2 - 2026',
      N'PERIODIC_TEST',
      '2026-10-08',
      '2026-10-14',
      N'PUBLISHED',
      1,
      1
    FROM management_schema.section sec
    WHERE sec.class_id <= 10;
    SET IDENTITY_INSERT management_schema.exam OFF;

    SET IDENTITY_INSERT management_schema.exam_schedule ON;
    -- 5C. Schedules for Mid Term Assessment 2026 (Schedules 1..240)
    INSERT INTO management_schema.exam_schedule
      (exam_schedule_id,exam_id,school_id,branch_id,academic_year_id,class_id,section_id,
       subject_id,teacher_id,exam_date,start_time,end_time,max_marks,pass_marks,status,is_active,created_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY e.exam_id, s.subject_id),
      e.exam_id,1,e.branch_id,1,e.class_id,e.section_id,
      s.subject_id,
      tsa.teacher_id,
      DATEADD(DAY, s.subject_id - 1, '2026-08-10'),
      '09:00',
      '11:00',
      100,
      40,
      N'COMPLETED',
      1,
      1
    FROM management_schema.exam e
    CROSS JOIN management_schema.subject s
    JOIN teachers_schema.teacher_subject_assignment tsa
      ON tsa.section_id = e.section_id
     AND tsa.subject_id = s.subject_id
     AND tsa.is_active = 1
    WHERE e.exam_name = N'Mid Term Assessment 2026';

    -- 5D. Schedules for Upcoming Periodic Assessment 2 - 2026 (Schedules 241..360, starting tomorrow 2026-10-08)
    INSERT INTO management_schema.exam_schedule
      (exam_schedule_id,exam_id,school_id,branch_id,academic_year_id,class_id,section_id,
       subject_id,teacher_id,exam_date,start_time,end_time,max_marks,pass_marks,status,is_active,created_by)
    SELECT
      240 + ROW_NUMBER() OVER (ORDER BY e.exam_id, s.subject_id),
      e.exam_id,1,1,1,e.class_id,e.section_id,
      s.subject_id,
      tsa.teacher_id,
      CASE s.subject_id
          WHEN 1 THEN '2026-10-08' -- Thursday: English
          WHEN 2 THEN '2026-10-09' -- Friday:   Mathematics
          WHEN 3 THEN '2026-10-10' -- Saturday: Science
          WHEN 4 THEN '2026-10-12' -- Monday:   Social Science (Sunday 11th skipped)
          WHEN 5 THEN '2026-10-13' -- Tuesday:  Computer Science
          WHEN 6 THEN '2026-10-14' -- Wednesday:Physical Education
      END,
      '09:30',
      '11:30',
      50.00,
      20.00,
      N'SCHEDULED',
      1,
      1
    FROM management_schema.exam e
    CROSS JOIN management_schema.subject s
    JOIN teachers_schema.teacher_subject_assignment tsa
      ON tsa.section_id = e.section_id
     AND tsa.subject_id = s.subject_id
     AND tsa.is_active = 1
    WHERE e.exam_name = N'Periodic Assessment 2 - 2026';
    SET IDENTITY_INSERT management_schema.exam_schedule OFF;

    SET IDENTITY_INSERT student_schema.exam_result ON;
    INSERT INTO student_schema.exam_result
      (exam_result_id,exam_schedule_id,school_id,branch_id,academic_year_id,class_id,section_id,
       student_id,marks_obtained,result_status,grade,rank_in_class,remarks,published_at,is_active,created_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY es.exam_schedule_id, st.student_id),
      es.exam_schedule_id,1,st.branch_id,1,st.class_id,st.section_id,
      st.student_id,
      CASE
        WHEN (st.student_id + es.exam_schedule_id) % 23 = 0 THEN NULL
        ELSE CAST(60 + ((st.student_id * 7 + es.exam_schedule_id * 3) % 38) AS DECIMAL(6,2))
      END,
      CASE
        WHEN (st.student_id + es.exam_schedule_id) % 23 = 0 THEN N'ABSENT'
        WHEN (60 + ((st.student_id * 7 + es.exam_schedule_id * 3) % 38)) < 40 THEN N'FAIL'
        ELSE N'PASS'
      END,
      CASE
        WHEN (st.student_id + es.exam_schedule_id) % 23 = 0 THEN NULL
        WHEN (60 + ((st.student_id * 7 + es.exam_schedule_id * 3) % 38)) >= 90 THEN N'A+'
        WHEN (60 + ((st.student_id * 7 + es.exam_schedule_id * 3) % 38)) >= 80 THEN N'A'
        WHEN (60 + ((st.student_id * 7 + es.exam_schedule_id * 3) % 38)) >= 70 THEN N'B+'
        WHEN (60 + ((st.student_id * 7 + es.exam_schedule_id * 3) % 38)) >= 60 THEN N'B'
        ELSE N'C'
      END,
      CASE WHEN (st.student_id + es.exam_schedule_id) % 23 = 0 THEN NULL ELSE ((st.student_id - 1) % 10) + 1 END,
      CASE WHEN (st.student_id + es.exam_schedule_id) % 23 = 0 THEN N'Absent on examination day' ELSE N'Satisfactory performance' END,
      '2026-08-20T10:00:00',
      1,
      1
    FROM management_schema.exam_schedule es
    JOIN student_schema.student st ON st.section_id = es.section_id AND st.student_status = N'ACTIVE'
    WHERE es.status = N'COMPLETED';
    SET IDENTITY_INSERT student_schema.exam_result OFF;

    /* ============================================================
       6. ASSESSMENTS & RESULTS (Project Work, Slip Test, Quiz)
       ============================================================ */
    SET IDENTITY_INSERT teachers_schema.assessment ON;
    INSERT INTO teachers_schema.assessment
      (assessment_id,school_id,academic_year_id,branch_id,class_id,section_id,subject_id,teacher_id,
       title,assessment_type,assessment_date,max_marks,is_active,created_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY sec.section_id, s.subject_id),
      1,1,
      CASE WHEN sec.class_id <= 10 THEN 1 ELSE 2 END,
      sec.class_id,sec.section_id,s.subject_id,
      tsa.teacher_id,
      CONCAT(s.subject_name, CASE (sec.section_id + s.subject_id) % 3
        WHEN 0 THEN N' Slip Test 1'
        WHEN 1 THEN N' Quiz 1'
        ELSE N' Project Work' END),
      CASE (sec.section_id + s.subject_id) % 3
        WHEN 0 THEN N'SLIP_TEST'
        WHEN 1 THEN N'QUIZ'
        ELSE N'PROJECT_WORK' END,
      '2026-08-24',
      CASE (sec.section_id + s.subject_id) % 3 WHEN 2 THEN 50.00 ELSE 25.00 END,
      1,1
    FROM management_schema.section sec
    CROSS JOIN management_schema.subject s
    JOIN teachers_schema.teacher_subject_assignment tsa
      ON tsa.section_id = sec.section_id
     AND tsa.subject_id = s.subject_id
     AND tsa.is_active = 1;
    SET IDENTITY_INSERT teachers_schema.assessment OFF;

    SET IDENTITY_INSERT student_schema.assessment_result ON;
    INSERT INTO student_schema.assessment_result
      (assessment_result_id,assessment_id,school_id,branch_id,academic_year_id,class_id,section_id,
       student_id,marks_obtained,grade,remarks,graded_at,graded_by,is_active,created_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY a.assessment_id, st.student_id),
      a.assessment_id,1,a.branch_id,1,a.class_id,a.section_id,st.student_id,
      CASE WHEN (st.student_id + a.assessment_id) % 19 = 0 THEN NULL
           ELSE CAST(16 + ((st.student_id + a.assessment_id) % 9) AS DECIMAL(6,2)) END,
      CASE WHEN (st.student_id + a.assessment_id) % 19 = 0 THEN NULL
           WHEN 16 + ((st.student_id + a.assessment_id) % 9) >= 22 THEN N'A+'
           WHEN 16 + ((st.student_id + a.assessment_id) % 9) >= 19 THEN N'A'
           ELSE N'B' END,
      CASE WHEN (st.student_id + a.assessment_id) % 19 = 0 THEN N'Absent for assessment'
           ELSE N'Demonstrated good grasp of concepts' END,
      CASE WHEN (st.student_id + a.assessment_id) % 19 = 0 THEN NULL ELSE '2026-08-28T09:00:00' END,
      CASE WHEN (st.student_id + a.assessment_id) % 19 = 0 THEN NULL ELSE t.user_id END,
      1,1
    FROM teachers_schema.assessment a
    JOIN teachers_schema.teacher t ON t.teacher_id = a.teacher_id
    JOIN student_schema.student st
      ON st.section_id = a.section_id AND st.student_status = N'ACTIVE';
    SET IDENTITY_INSERT student_schema.assessment_result OFF;

    /* ============================================================
       6.1. STUDENT EXAM PERFORMANCE (400 Active Students Summary)
       ============================================================ */
    ;WITH ExamLevelSummary AS (
        SELECT
            er.student_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            es.exam_id,
            SUM(er.marks_obtained) AS exam_marks_obtained,
            SUM(es.max_marks) AS exam_total_max_marks,
            CAST(
                SUM(er.marks_obtained) * 100.0 / NULLIF(SUM(es.max_marks), 0)
                AS DECIMAL(5, 2)
            ) AS exam_percentage
        FROM student_schema.exam_result er
        INNER JOIN student_schema.student st
            ON st.student_id = er.student_id
        INNER JOIN management_schema.exam_schedule es
            ON es.exam_schedule_id = er.exam_schedule_id
        WHERE er.is_active = 1
          AND er.result_status <> N'ABSENT'
          AND er.marks_obtained IS NOT NULL
          AND es.max_marks > 0
        GROUP BY
            er.student_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            es.exam_id
    ),
    StudentExamAggregates AS (
        SELECT
            els.student_id,
            els.academic_year_id,
            els.class_id,
            els.section_id,
            COUNT(DISTINCT els.exam_id) AS total_exams_count,
            CAST(AVG(els.exam_percentage) AS DECIMAL(5, 2)) AS overall_percentage
        FROM ExamLevelSummary els
        GROUP BY
            els.student_id,
            els.academic_year_id,
            els.class_id,
            els.section_id
    ),
    AssessmentAggregates AS (
        SELECT
            ar.student_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            COUNT(DISTINCT a.assessment_id) AS total_exams_count,
            CAST(
                AVG(ar.marks_obtained * 100.0 / NULLIF(a.max_marks, 0))
                AS DECIMAL(5, 2)
            ) AS overall_percentage
        FROM student_schema.assessment_result ar
        INNER JOIN student_schema.student st
            ON st.student_id = ar.student_id
        INNER JOIN teachers_schema.assessment a
            ON a.assessment_id = ar.assessment_id
        WHERE ar.marks_obtained IS NOT NULL
          AND a.max_marks > 0
          AND ar.student_id NOT IN (SELECT student_id FROM StudentExamAggregates)
        GROUP BY
            ar.student_id,
            st.academic_year_id,
            st.class_id,
            st.section_id
    ),
    CombinedPerformanceSource AS (
        SELECT * FROM StudentExamAggregates
        UNION ALL
        SELECT * FROM AssessmentAggregates
    )
    INSERT INTO student_schema.student_exam_performance
      (student_id, academic_year_id, class_id, section_id, total_exams_count, overall_percentage, created_at, updated_at)
    SELECT
      src.student_id,
      src.academic_year_id,
      src.class_id,
      src.section_id,
      src.total_exams_count,
      src.overall_percentage,
      SYSUTCDATETIME(),
      SYSUTCDATETIME()
    FROM CombinedPerformanceSource src;

    /* Note: Homework & student homework status are generated below in Section 9B, directly tied to the 2-week active timetable periods */

    /* ============================================================
       8. ANNOUNCEMENTS (Central & North Campuses)
       ============================================================ */
    SET IDENTITY_INSERT management_schema.announcement ON;
    INSERT INTO management_schema.announcement
      (announcement_id,school_id,branch_id,academic_year_id,announcement_type,sub_category,title,description,
       target_audience,registration_url,start_date,end_date,publish_at,status,is_active,created_by)
    VALUES
      (1,1,1,1,N'EVENT',N'CULTURAL',N'Independence Day Grand Assembly',N'Flag hoisting ceremony, cultural choir performances, and speech competitions at Central Campus.', N'ALL', N'https://events.schoolname.edu/independence-day-2026', '2026-08-15','2026-08-15','2026-08-10T09:00:00',N'PUBLISHED',1,1),
      (2,1,1,1,N'NOTICE',N'STUDENT_INSTRUCTIONS',N'Term-1 Parent Teacher Conference Schedule',N'Parent-Teacher meetings for Classes 1 through 10. Time slots published on parent portal.', N'PARENTS', NULL, '2026-09-05','2026-09-05','2026-08-25T09:00:00',N'PUBLISHED',1,1),
      (3,1,2,1,N'EVENT',N'CULTURAL',N'Inter-School Science & Innovation Expo',N'Annual Science & Technology exhibition at North Campus with robotics and environmental displays.', N'STUDENTS', N'https://events.schoolname.edu/science-expo-2026', '2026-09-12','2026-09-12','2026-08-28T09:00:00',N'PUBLISHED',1,1),
      (4,1,2,1,N'ACADEMIC',N'EXAMS',N'Mid-Term Assessment Instructions & Code of Conduct',N'Mandatory examination instructions, seating guidelines, and permitted stationary list.', N'STUDENTS', NULL, '2026-09-01','2026-09-10','2026-08-29T09:00:00',N'PUBLISHED',1,1),
      (5,1,1,1,N'EVENT',N'ALUMNI_EVENTS',N'Alumni Career Mentorship: Tech & Engineering Horizons',N'Distinguished alumni from Google, Microsoft, and ISRO host specialized career guidance sessions.', N'ALL', N'https://events.schoolname.edu/alumni-mentorship', '2026-10-15','2026-10-15','2026-10-01T09:00:00',N'PUBLISHED',1,1),
      (6,1,1,1,N'ACADEMIC',N'TIMETABLE',N'Master Academic Timetable for All Classes Published',N'Weekly academic timetable with laboratory and sports allocations now accessible in school app.', N'ALL', NULL, '2026-08-10','2026-08-10','2026-08-01T09:00:00',N'PUBLISHED',1,1),
      (7,1,2,1,N'ACADEMIC',N'SYLLABUS',N'Curriculum Syllabus & Project Evaluation Guidelines',N'Subject syllabi and practical rubrics for the upcoming academic cycle across Classes 1-10.', N'STUDENTS', NULL, '2026-08-12','2026-08-12','2026-08-05T09:00:00',N'PUBLISHED',1,1),
      (8,1,2,1,N'EVENT',N'SPORTS',N'Annual Inter-Branch Athletics Championship',N'Track events, football, basketball, and yoga championships between Central and North campuses.', N'ALL', N'https://events.schoolname.edu/sports-championship-2026', '2026-11-05','2026-11-07','2026-10-20T09:00:00',N'PUBLISHED',1,1),
      (9,1,1,1,N'EVENT',N'SPORTS',N'Annual Inter-School Athletics Championship 2026',N'Track and field events including 100m sprint, relay, long jump, shot put, and hurdles.', N'ALL', N'https://events.schoolname.edu/athletics-2026', '2026-08-15','2026-08-16','2026-08-01T09:00:00',N'PUBLISHED',1,1),
      (10,1,1,1,N'EVENT',N'SPORTS',N'Intra-School Cricket Tournament 2026',N'Branch vs Branch cricket championship. Open to Class 6 to Class 10 students.', N'ALL', N'https://events.schoolname.edu/cricket-2026', '2026-09-05','2026-09-07','2026-08-20T09:00:00',N'PUBLISHED',1,1),
      (11,1,2,1,N'EVENT',N'SPORTS',N'Kabaddi & Kho-Kho District Trials 2026',N'Selection trials for district-level Kabaddi and Kho-Kho competitions.', N'STUDENTS', NULL, '2026-09-20','2026-09-20','2026-09-05T09:00:00',N'PUBLISHED',1,1),
      (12,1,2,1,N'EVENT',N'SPORTS',N'Basketball & Volleyball Friendly Series 2026',N'Friendly inter-section Basketball and Volleyball matches across both branches.', N'STUDENTS', NULL, '2026-10-10','2026-10-11','2026-09-25T09:00:00',N'PUBLISHED',1,1),
      (13,1,1,1,N'EVENT',N'CULTURAL',N'Annual Classical & Folk Dance Showcase',N'Celebrating classical and folk dances of India with solo and group choreographies.', N'ALL', N'https://events.schoolname.edu/dance-showcase', '2026-08-22','2026-08-22','2026-08-05T09:00:00',N'PUBLISHED',1,1),
      (14,1,1,1,N'EVENT',N'CULTURAL',N'Inter-House Music Competition & Choir Gala',N'Vocal and instrumental musical presentations across Western and Indian Classical traditions.', N'ALL', N'https://events.schoolname.edu/music-gala', '2026-08-29','2026-08-29','2026-08-12T09:00:00',N'PUBLISHED',1,1),
      (15,1,2,1,N'EVENT',N'CULTURAL',N'Fine Arts, Painting & Sculpture Exhibition',N'Original canvases, watercolor studies, clay sculptures, and digital art portfolios.', N'ALL', N'https://events.schoolname.edu/fine-arts-expo', '2026-09-19','2026-09-19','2026-09-01T09:00:00',N'PUBLISHED',1,1),
      (16,1,2,1,N'EVENT',N'CULTURAL',N'Annual Shakespeare & Modern Theatre Festival',N'Dramatic monologues, one-act adaptations, and stagecraft showcases.', N'ALL', N'https://events.schoolname.edu/theatre-fest', '2026-10-03','2026-10-03','2026-09-15T09:00:00',N'PUBLISHED',1,1);
    SET IDENTITY_INSERT management_schema.announcement OFF;

    /* ============================================================
       9. MASTER TIMETABLES & TIMETABLE PERIODS (40 Sections)
       Mon-Sat (6 days) x 10 slots x 2 weeks = 120 periods per section
       Total Timetable Periods: 40 x 120 = 4,800 periods
       Dates: This Monday through end of second Saturday (dynamic)
       ============================================================ */
    SET IDENTITY_INSERT management_schema.timetable ON;
    INSERT INTO management_schema.timetable
      (timetable_id,school_id,branch_id,academic_year_id,class_id,section_id,
       timetable_name,status,is_active,created_by)
    SELECT
      sec.section_id,
      1,
      CASE WHEN sec.class_id <= 10 THEN 1 ELSE 2 END,
      1,
      sec.class_id,
      sec.section_id,
      CONCAT(N'2026-2027 ', c.class_name, N' - Section ', sec.section_name),
      N'ACTIVE',
      1,
      1
    FROM management_schema.section sec
    JOIN management_schema.school_class c ON c.class_id = sec.class_id;
    SET IDENTITY_INSERT management_schema.timetable OFF;

    /* Compute the Monday of the current week (ISO Mon=2 in SQL Server DATEFIRST=7 default) */
    DECLARE @TimetableMonday DATE;
    SET @TimetableMonday = CAST(
        DATEADD(DAY,
            CASE DATEPART(WEEKDAY, GETDATE())
                WHEN 1 THEN -6  -- Sunday  -> prev Monday
                WHEN 2 THEN  0  -- Monday  -> today
                WHEN 3 THEN -1  -- Tuesday -> yesterday
                WHEN 4 THEN -2
                WHEN 5 THEN -3
                WHEN 6 THEN -4
                WHEN 7 THEN -5  -- Saturday -> prev Monday
            END,
            CAST(GETDATE() AS DATE)
        ) AS DATE
    );

    SET IDENTITY_INSERT management_schema.timetable_period ON;
    ;WITH D AS
    (
      /* 12 school days: Mon-Sat of Week 1 (day_no 0..5) + Mon-Sat of Week 2 (day_no 6..11) */
      SELECT 0  day_no, @TimetableMonday                  period_date UNION ALL
      SELECT 1,  DATEADD(DAY,  1, @TimetableMonday) UNION ALL
      SELECT 2,  DATEADD(DAY,  2, @TimetableMonday) UNION ALL
      SELECT 3,  DATEADD(DAY,  3, @TimetableMonday) UNION ALL
      SELECT 4,  DATEADD(DAY,  4, @TimetableMonday) UNION ALL
      SELECT 5,  DATEADD(DAY,  5, @TimetableMonday) UNION ALL  -- Sat Week 1
      SELECT 6,  DATEADD(DAY,  7, @TimetableMonday) UNION ALL  -- Mon Week 2
      SELECT 7,  DATEADD(DAY,  8, @TimetableMonday) UNION ALL
      SELECT 8,  DATEADD(DAY,  9, @TimetableMonday) UNION ALL
      SELECT 9,  DATEADD(DAY, 10, @TimetableMonday) UNION ALL
      SELECT 10, DATEADD(DAY, 11, @TimetableMonday) UNION ALL
      SELECT 11, DATEADD(DAY, 12, @TimetableMonday)             -- Sat Week 2
    ),
    P AS
    (
      SELECT 1  period_number, N'Period 1'          period_name, CAST('08:30' AS TIME) start_time, CAST('09:15' AS TIME) end_time, N'CLASS' period_type, 1 subject_id UNION ALL
      SELECT 2,  N'Period 2',          '09:15', '10:00', N'CLASS', 2 UNION ALL
      SELECT 3,  N'Morning Break',     '10:00', '10:15', N'BREAK', NULL UNION ALL
      SELECT 4,  N'Period 3',          '10:15', '11:00', N'CLASS', 3 UNION ALL
      SELECT 5,  N'Period 4',          '11:00', '11:45', N'CLASS', 4 UNION ALL
      SELECT 6,  N'Lunch Break',       '11:45', '12:30', N'LUNCH', NULL UNION ALL
      SELECT 7,  N'Period 5',          '12:30', '13:15', N'CLASS', 5 UNION ALL
      SELECT 8,  N'Period 6',          '13:15', '14:00', N'CLASS', 6 UNION ALL
      SELECT 9,  N'Afternoon Break',   '14:00', '14:15', N'BREAK', NULL UNION ALL
      SELECT 10, N'Period 7',          '14:15', '15:00', N'CLASS', 1
    ),
    PeriodsGrid AS
    (
      SELECT
        ((tt.timetable_id - 1) * 120) + (d.day_no * 10) + p.period_number AS timetable_period_id,
        tt.timetable_id,
        tt.school_id,
        tt.branch_id,
        tt.class_id,
        tt.section_id,
        d.day_no,
        d.period_date,
        p.period_number,
        CASE 
          WHEN tt.school_id = 1 AND tt.branch_id = 1 AND tt.class_id = 1 AND tt.section_id = 1 AND p.period_number = 10 AND d.day_no IN (2, 5, 8) 
            THEN N'Period 7 (Science)'
          ELSE p.period_name 
        END AS period_name,
        p.start_time,
        p.end_time,
        p.period_type,
        CASE 
          WHEN p.period_type <> N'CLASS' THEN NULL
          WHEN tt.school_id = 1 AND tt.branch_id = 1 AND tt.class_id = 1 AND tt.section_id = 1 AND p.period_number = 10 AND d.day_no IN (2, 5, 8) 
            THEN 3
          ELSE p.subject_id 
        END AS effective_subject_id,
        CASE 
          WHEN p.period_type IN (N'BREAK', N'LUNCH') THEN p.period_name
          WHEN tt.school_id = 1 AND tt.branch_id = 1 AND tt.class_id = 1 AND tt.section_id = 1 AND p.period_number = 10 AND d.day_no IN (2, 5, 8)
            THEN N'Science Laboratory & Practice'
          ELSE NULL 
        END AS activity_name
      FROM management_schema.timetable tt
      CROSS JOIN D d
      CROSS JOIN P p
    )
    INSERT INTO management_schema.timetable_period
      (timetable_period_id,timetable_id,period_date,period_number,period_name,start_time,end_time,
       period_type,subject_id,subject_topic,teacher_id,room_name,activity_name,is_active,created_by)
    SELECT
      pg.timetable_period_id,
      pg.timetable_id,
      pg.period_date,
      pg.period_number,
      pg.period_name,
      pg.start_time,
      pg.end_time,
      pg.period_type,
      pg.effective_subject_id,
      CASE WHEN pg.period_type = N'CLASS' THEN
        CASE 
          /* For Science (Subject 3), map Section 1 ONLY (Central Class 1 Sec A: school_id=1, branch_id=1, class_id=1, section_id=1) */
          WHEN pg.effective_subject_id = 3 AND pg.school_id = 1 AND pg.branch_id = 1 AND pg.class_id = 1 AND pg.section_id = 1 THEN
            CASE 
              WHEN pg.day_no = 0  AND pg.period_number = 4  THEN N'Living Things'
              WHEN pg.day_no = 1  AND pg.period_number = 4  THEN N'Non-Living Things'
              WHEN pg.day_no = 2  AND pg.period_number = 4  THEN N'Characteristics of Living Things'
              WHEN pg.day_no = 2  AND pg.period_number = 10 THEN N'Needs of Living Things'
              WHEN pg.day_no = 3  AND pg.period_number = 4  THEN N'Living and Non-Living Things Around Us'
              WHEN pg.day_no = 4  AND pg.period_number = 4  THEN N'Parts of a Plant'
              WHEN pg.day_no = 5  AND pg.period_number = 4  THEN N'Roots'
              WHEN pg.day_no = 5  AND pg.period_number = 10 THEN N'Stem'
              WHEN pg.day_no = 6  AND pg.period_number = 4  THEN N'Leaves'
              WHEN pg.day_no = 7  AND pg.period_number = 4  THEN N'Flowers, Fruits and Seeds'
              WHEN pg.day_no = 8  AND pg.period_number = 4  THEN N'Our Surroundings'
              WHEN pg.day_no = 8  AND pg.period_number = 10 THEN N'Air Around Us'
              WHEN pg.day_no = 9  AND pg.period_number = 4  THEN N'Water Around Us'
              WHEN pg.day_no = 10 AND pg.period_number = 4  THEN N'Clean and Safe Environment'
              WHEN pg.day_no = 11 AND pg.period_number = 4  THEN N'Protecting Our Environment'
              ELSE N'Living Things'
            END
          ELSE
            CASE (pg.day_no % 6) /* rotate topics across 6 school days */
              WHEN 0 THEN
                CASE pg.effective_subject_id
                  WHEN 1 THEN N'English Literature & Comprehension'
                  WHEN 2 THEN N'Mathematics: Linear Equations & Algebra'
                  WHEN 3 THEN N'Science: Cell Biology & Mechanics'
                  WHEN 4 THEN N'Social Science: Indian Federal Constitution'
                  WHEN 5 THEN N'Computer Science: Algorithms & Python Programming'
                  WHEN 6 THEN N'Physical Education: Athletics & Team Sports'
                  ELSE N'Revision & Discussion'
                END
              WHEN 1 THEN
                CASE pg.effective_subject_id
                  WHEN 1 THEN N'Reading Comprehension & Prose Analysis'
                  WHEN 2 THEN N'Geometry: Triangles & Constructions'
                  WHEN 3 THEN N'Science: Light, Sound & Wave Motion'
                  WHEN 4 THEN N'Social Science: Medieval India & Mughal Empire'
                  WHEN 5 THEN N'Computer Science: Functions & Modules in Python'
                  WHEN 6 THEN N'Physical Education: Yoga & Flexibility Training'
                  ELSE N'Topic Review & Q&A'
                END
              WHEN 2 THEN
                CASE pg.effective_subject_id
                  WHEN 1 THEN N'Grammar: Tenses, Active & Passive Voice'
                  WHEN 2 THEN N'Mathematics: Percentages & Profit-Loss'
                  WHEN 3 THEN N'Science: Chemical Reactions & Compounds'
                  WHEN 4 THEN N'Social Science: Natural Resources & Conservation'
                  WHEN 5 THEN N'Computer Science: Web Basics & HTML5'
                  WHEN 6 THEN N'Physical Education: Cricket & Team Games'
                  ELSE N'Worksheet & Practice'
                END
              WHEN 3 THEN
                CASE pg.effective_subject_id
                  WHEN 1 THEN N'Essay Writing & Creative Composition'
                  WHEN 2 THEN N'Mathematics: Mensuration & Area Calculations'
                  WHEN 3 THEN N'Science: Animal Kingdom & Classification'
                  WHEN 4 THEN N'Social Science: Climate & Weather Patterns'
                  WHEN 5 THEN N'Computer Science: Spreadsheets & Data Tables'
                  WHEN 6 THEN N'Physical Education: Athletics & Sprint Training'
                  ELSE N'Unit Test Preparation'
                END
              WHEN 4 THEN
                CASE pg.effective_subject_id
                  WHEN 1 THEN N'Poetry Analysis & Literary Devices'
                  WHEN 2 THEN N'Mathematics: Statistics & Data Interpretation'
                  WHEN 3 THEN N'Science: Human Body Systems & Health'
                  WHEN 4 THEN N'Social Science: Democracy & Elections'
                  WHEN 5 THEN N'Computer Science: Databases & SQL Basics'
                  WHEN 6 THEN N'Physical Education: Badminton & Racket Sports'
                  ELSE N'Revision & Discussion'
                END
              ELSE /* day 5 = Saturday */
                CASE pg.effective_subject_id
                  WHEN 1 THEN N'Speaking Skills & Public Presentation'
                  WHEN 2 THEN N'Mathematics: Number Systems & Rational Numbers'
                  WHEN 3 THEN N'Science: Environment & Ecosystem'
                  WHEN 4 THEN N'Social Science: Industries & Economic Development'
                  WHEN 5 THEN N'Computer Science: Cybersecurity & Digital Safety'
                  WHEN 6 THEN N'Physical Education: Kabaddi & Kho-Kho'
                  ELSE N'Weekly Recap & Review'
                END
            END
        END
        ELSE NULL
      END,
      CASE WHEN pg.period_type = N'CLASS' THEN tsa.teacher_id ELSE NULL END,
      CASE WHEN pg.period_type = N'CLASS' THEN CONCAT(N'Room-', RIGHT(N'00' + CAST(pg.section_id AS NVARCHAR(2)), 2)) ELSE NULL END,
      pg.activity_name,
      1,
      1
    FROM PeriodsGrid pg
    LEFT JOIN teachers_schema.teacher_subject_assignment tsa
      ON tsa.section_id = pg.section_id
     AND tsa.subject_id = pg.effective_subject_id
     AND tsa.is_active = 1;
    SET IDENTITY_INSERT management_schema.timetable_period OFF;

    /* ============================================================
       9B. HOMEWORK & STUDENT HOMEWORK STATUS (2-WEEK TIMETABLE BASED)
       Derived directly from the 2-week active timetable periods.
       Includes authoritative Science curriculum topics (Living Things,
       Plants, Environment).
       ============================================================ */
    SET IDENTITY_INSERT teachers_schema.homework ON;
    INSERT INTO teachers_schema.homework
      (homework_id, school_id, academic_year_id, branch_id, class_id, section_id,
       subject_id, teacher_id, homework_type, title, description, priority_level,
       assigned_at, deadline_at, status, estimated_minutes, published_at,
       is_active, created_at, created_by, updated_at, updated_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY tp.period_date, tp.timetable_id, tp.period_number),
      tt.school_id,
      tt.academic_year_id,
      tt.branch_id,
      tt.class_id,
      tt.section_id,
      tp.subject_id,
      ISNULL(tp.teacher_id, tsa.teacher_id),
      CASE WHEN tp.subject_id = 1 THEN N'READING' ELSE N'HOMEWORK' END,
      CASE 
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Living Things' 
          THEN N'Science - Living Things: Identification & Characteristics'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Non-Living Things' 
          THEN N'Science - Non-Living Things: Properties & Surrounding Objects'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Characteristics of Living Things' 
          THEN N'Science - Characteristics of Life: Growth & Movement'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Needs of Living Things' 
          THEN N'Science - Basic Needs of Living Organisms: Food & Air'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Living and Non-Living Things Around Us' 
          THEN N'Science - Classification: Living vs Non-Living Things'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Parts of a Plant' 
          THEN N'Science - Parts of a Plant: Diagram & Identification'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Roots' 
          THEN N'Science - Plant Roots: Absorption & Soil Anchorage'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Stem' 
          THEN N'Science - Plant Stem: Support & Water Transport'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Leaves' 
          THEN N'Science - Leaves: Photosynthesis & Food Making'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Flowers, Fruits and Seeds' 
          THEN N'Science - Flowers, Fruits & Seeds: Plant Life Cycle'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Our Surroundings' 
          THEN N'Science - Our Environment: Natural vs Human-Made Surroundings'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Air Around Us' 
          THEN N'Science - Air Around Us: Importance & Respiration'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Water Around Us' 
          THEN N'Science - Water Around Us: Sources & Conservation'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Clean and Safe Environment' 
          THEN N'Science - Clean and Safe Environment: Healthy Practices'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Protecting Our Environment' 
          THEN N'Science - Protecting Our Environment: Nature & Tree Planting'
        ELSE 
          CONCAT(sub.subject_name, N' - ', tp.subject_topic, N' Assignment')
      END,
      CASE 
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Living Things' 
          THEN N'Identify living things and describe basic characteristics of life from Chapter 1. Complete exercise 1.1 in your notebook.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Non-Living Things' 
          THEN N'Differentiate between living and non-living things in your daily surroundings. List 10 non-living objects with reasons.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Characteristics of Living Things' 
          THEN N'Explain common characteristics that distinguish living organisms including growth, respiration, and movement.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Needs of Living Things' 
          THEN N'Describe the basic needs of plants, animals, and humans for survival and growth. Complete exercise 1.4.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Living and Non-Living Things Around Us' 
          THEN N'Classify common objects in the school and home environment as living or non-living in the provided chart.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Parts of a Plant' 
          THEN N'Identify major parts of a plant and describe their basic functions. Draw and label a neat plant diagram.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Roots' 
          THEN N'Explain how roots help plants absorb water from the soil and remain firmly anchored. Answer review questions 2.2.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Stem' 
          THEN N'Describe the basic functions of a plant stem in carrying water and nutrients to leaves and flowers.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Leaves' 
          THEN N'Explain the role of green leaves in preparing food for the plant using sunlight, water, and air.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Flowers, Fruits and Seeds' 
          THEN N'Identify flowers, fruits, and seeds and describe their basic roles in plant reproduction and seed dispersal.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Our Surroundings' 
          THEN N'Identify important natural and human-made elements in our surroundings and describe actions to keep them clean.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Air Around Us' 
          THEN N'Explain why fresh air is essential for living organisms and write three ways to reduce air pollution around us.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Water Around Us' 
          THEN N'Identify water sources around us, common household uses, and simple habits to conserve clean water.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Clean and Safe Environment' 
          THEN N'Describe habits to maintain classroom and home cleanliness, proper waste segregation, and healthy surroundings.'
        WHEN tp.subject_id = 3 AND tp.subject_topic = N'Protecting Our Environment' 
          THEN N'List five practical actions young learners can take to care for plants, conserve resources, and protect nature.'
        ELSE 
          CONCAT(N'Complete textbook chapter exercises and review questions on "', tp.subject_topic, N'" in your subject notebook.')
      END,
      CASE WHEN tp.subject_id IN (2, 3) THEN N'HIGH' ELSE N'MEDIUM' END,
      DATEADD(HOUR, 15, CAST(tp.period_date AS DATETIME2(0))),
      CASE 
        WHEN (DATEDIFF(DAY, '1900-01-01', tp.period_date) % 7) = 5 
        THEN DATEADD(HOUR, 18, CAST(DATEADD(DAY, 2, tp.period_date) AS DATETIME2(0)))
        ELSE DATEADD(HOUR, 18, CAST(DATEADD(DAY, 1, tp.period_date) AS DATETIME2(0)))
      END,
      N'PUBLISHED',
      CASE tp.subject_id WHEN 2 THEN 45 WHEN 3 THEN 40 WHEN 5 THEN 35 ELSE 30 END,
      DATEADD(HOUR, 15, CAST(tp.period_date AS DATETIME2(0))),
      1,
      DATEADD(HOUR, 15, CAST(tp.period_date AS DATETIME2(0))),
      ISNULL(t.user_id, 1),
      DATEADD(HOUR, 15, CAST(tp.period_date AS DATETIME2(0))),
      ISNULL(t.user_id, 1)
    FROM management_schema.timetable_period tp
    JOIN management_schema.timetable tt ON tt.timetable_id = tp.timetable_id
    JOIN management_schema.subject sub ON sub.subject_id = tp.subject_id
    LEFT JOIN teachers_schema.teacher_subject_assignment tsa 
      ON tsa.section_id = tt.section_id AND tsa.subject_id = tp.subject_id AND tsa.is_active = 1
    LEFT JOIN teachers_schema.teacher t 
      ON t.teacher_id = ISNULL(tp.teacher_id, tsa.teacher_id)
    WHERE tp.period_type = N'CLASS'
      AND (
        tp.period_number IN (1, 2, 4, 5, 7)
        OR (tt.school_id = 1 AND tt.branch_id = 1 AND tt.class_id = 1 AND tt.section_id = 1 AND tp.period_number = 10 AND tp.subject_id = 3)
      );
    SET IDENTITY_INSERT teachers_schema.homework OFF;

    /* Student submissions for each 2-week timetable homework */
    DECLARE @Now DATETIME2(0) = SYSUTCDATETIME();

    SET IDENTITY_INSERT student_schema.homework_status ON;
    INSERT INTO student_schema.homework_status
      (homework_status_id, homework_id, school_id, branch_id, academic_year_id,
       class_id, section_id, student_id, submission_status, submitted_at,
       submission_timing, remarks, is_active, created_at, created_by, updated_at, updated_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY h.homework_id, st.student_id),
      h.homework_id,
      h.school_id,
      h.branch_id,
      h.academic_year_id,
      h.class_id,
      h.section_id,
      st.student_id,
      CASE 
        WHEN h.deadline_at < @Now THEN
          CASE WHEN (h.homework_id + st.student_id) % 10 = 0 THEN N'NOT_SUBMITTED' ELSE N'SUBMITTED' END
        WHEN h.assigned_at <= @Now AND h.deadline_at >= @Now THEN
          CASE WHEN (h.homework_id + st.student_id) % 3 = 0 THEN N'SUBMITTED' ELSE N'NOT_SUBMITTED' END
        ELSE N'NOT_SUBMITTED'
      END,
      CASE 
        WHEN h.deadline_at < @Now THEN
          CASE 
            WHEN (h.homework_id + st.student_id) % 10 = 0 THEN NULL
            WHEN (h.homework_id + st.student_id) % 10 = 1 THEN DATEADD(HOUR, 2, h.deadline_at)
            ELSE DATEADD(HOUR, 4, h.assigned_at)
          END
        WHEN h.assigned_at <= @Now AND h.deadline_at >= @Now THEN
          CASE 
            WHEN (h.homework_id + st.student_id) % 3 = 0 THEN DATEADD(MINUTE, 90, h.assigned_at)
            ELSE NULL
          END
        ELSE NULL
      END,
      CASE 
        WHEN h.deadline_at < @Now THEN
          CASE 
            WHEN (h.homework_id + st.student_id) % 10 = 0 THEN NULL
            WHEN (h.homework_id + st.student_id) % 10 = 1 THEN N'LATE'
            ELSE N'ON_TIME'
          END
        WHEN h.assigned_at <= @Now AND h.deadline_at >= @Now THEN
          CASE 
            WHEN (h.homework_id + st.student_id) % 3 = 0 THEN N'ON_TIME'
            ELSE NULL
          END
        ELSE NULL
      END,
      CASE 
        WHEN h.deadline_at < @Now THEN
          CASE 
            WHEN (h.homework_id + st.student_id) % 10 = 0 THEN N'Pending student submission'
            WHEN (h.homework_id + st.student_id) % 10 = 1 THEN N'Late submission approved by teacher'
            ELSE N'Complete and neatly submitted'
          END
        WHEN h.assigned_at <= @Now AND h.deadline_at >= @Now THEN
          CASE 
            WHEN (h.homework_id + st.student_id) % 3 = 0 THEN N'Submitted on time'
            ELSE N'Work in progress'
          END
        ELSE N'Scheduled assignment'
      END,
      1,
      h.assigned_at,
      h.created_by,
      h.assigned_at,
      h.created_by
    FROM teachers_schema.homework h
    JOIN student_schema.student st 
      ON st.section_id = h.section_id AND st.student_status = N'ACTIVE';
    SET IDENTITY_INSERT student_schema.homework_status OFF;

    /* ============================================================
       10. STUDENT ATTENDANCE (Period 1 of each school day, all 12 days, all active students)
       ============================================================ */
    SET IDENTITY_INSERT student_schema.student_attendance ON;
    INSERT INTO student_schema.student_attendance
      (student_attendance_id,school_id,branch_id,academic_year_id,class_id,section_id,student_id,
       timetable_id,timetable_period_id,attendance_date,subject_id,teacher_id,period_number,
       start_time,end_time,attendance_status,recorded_at,recorded_by,is_active,created_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY st.student_id, tp.timetable_period_id),
      1,st.branch_id,1,st.class_id,st.section_id,st.student_id,
      tp.timetable_id,tp.timetable_period_id,tp.period_date,tp.subject_id,tp.teacher_id,
      tp.period_number,tp.start_time,tp.end_time,
      CASE WHEN (st.student_id + DATEDIFF(DAY, @TimetableMonday, tp.period_date)) % 17 = 0
           THEN N'ABSENT' ELSE N'PRESENT' END,
      DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), tp.start_time), CAST(tp.period_date AS DATETIME2)),
      1,1,1
    FROM student_schema.student st
    JOIN management_schema.timetable_period tp
      ON tp.timetable_id = st.section_id
     AND tp.period_number = 1
     AND tp.period_type = N'CLASS'
    WHERE st.student_status = N'ACTIVE';
    SET IDENTITY_INSERT student_schema.student_attendance OFF;

    /* ============================================================
       11. STUDENT LEAVE & HOLIDAYS
       ============================================================ */
    SET IDENTITY_INSERT student_schema.student_leave ON;
    INSERT INTO student_schema.student_leave
      (student_leave_id,school_id,branch_id,academic_year_id,class_id,section_id,student_id,
       leave_type,duration_type,duration,half_day_session,start_date,end_date,reason,status,applied_at,
       reviewed_at,reviewed_by,review_remarks,is_active,created_by)
    SELECT
      st.student_id,1,st.branch_id,1,st.class_id,st.section_id,st.student_id,
      CASE WHEN st.student_id % 2 = 0 THEN N'PERSONAL' ELSE N'SICK' END,
      N'FULL_DAY',1.00,NULL,
      DATEADD(DAY, (st.student_id % 5) + 1, '2026-09-01'),
      DATEADD(DAY, (st.student_id % 5) + 1, '2026-09-01'),
      CASE WHEN st.student_id % 2 = 0 THEN N'Family wedding ceremony' ELSE N'Fever and physician-advised rest' END,
      CASE WHEN st.student_id % 3 = 0 THEN N'PENDING' ELSE N'APPROVED' END,
      '2026-08-28T12:00:00',
      CASE WHEN st.student_id % 3 = 0 THEN NULL ELSE '2026-08-29T10:00:00' END,
      CASE WHEN st.student_id % 3 = 0 THEN NULL ELSE class_teacher.user_id END,
      CASE WHEN st.student_id % 3 = 0 THEN NULL ELSE N'Approved by Section Class Teacher' END,
      1,
      st.user_id
    FROM student_schema.student st
    JOIN teachers_schema.section_class_teacher_assignment cta
      ON cta.section_id = st.section_id
     AND cta.is_active = 1
    JOIN teachers_schema.teacher class_teacher
      ON class_teacher.teacher_id = cta.teacher_id
    WHERE st.student_id <= 40;  -- 1 leave application per section
    SET IDENTITY_INSERT student_schema.student_leave OFF;

    /* Student Leave History */
    IF OBJECT_ID(N'student_schema.student_leave_status_history', N'U') IS NOT NULL
    BEGIN
        INSERT INTO student_schema.student_leave_status_history
            (student_leave_id, old_status, new_status, changed_by, changed_at, remarks)
        SELECT student_leave_id, N'PENDING', status, reviewed_by, reviewed_at, review_remarks
        FROM student_schema.student_leave
        WHERE status IN (N'APPROVED', N'REJECTED') AND reviewed_by IS NOT NULL;
    END;

    SET IDENTITY_INSERT management_schema.holiday ON;
    INSERT INTO management_schema.holiday
      (holiday_id,school_id,branch_id,academic_year_id,holiday_type,holiday_name,description,
       start_date,end_date,is_active,created_by)
    VALUES
      (1,1,1,1,N'FESTIVAL',N'Ganesh Chaturthi',N'School festival holiday.','2026-09-02','2026-09-02',1,1),
      (2,1,2,1,N'FESTIVAL',N'Ganesh Chaturthi',N'School festival holiday.','2026-09-02','2026-09-02',1,1),
      (3,1,1,1,N'NATIONAL',N'Gandhi Jayanti',N'National holiday.','2026-10-02','2026-10-02',1,1),
      (4,1,2,1,N'NATIONAL',N'Gandhi Jayanti',N'National holiday.','2026-10-02','2026-10-02',1,1),
      (5,1,1,1,N'FESTIVAL',N'Diwali Festival',N'Deepavali holidays.','2026-11-08','2026-11-10',1,1),
      (6,1,2,1,N'FESTIVAL',N'Diwali Festival',N'Deepavali holidays.','2026-11-08','2026-11-10',1,1);
    SET IDENTITY_INSERT management_schema.holiday OFF;

    /* ============================================================
       12. GRIEVANCES & GRIEVANCE HISTORY (40 Realistic Student Records)
       ============================================================ */
    SET IDENTITY_INSERT management_schema.grievance_department ON;
    INSERT INTO management_schema.grievance_department
      (department_id, school_id, branch_id, responsible_user_id, is_active, created_at, created_by, updated_at, updated_by)
    VALUES
      (1, 1, 1, 1, 1, '2026-04-01T08:00:00', 1, '2026-04-01T08:00:00', 1),
      (2, 1, 2, 1, 1, '2026-04-01T08:00:00', 1, '2026-04-01T08:00:00', 1),
      (3, 1, NULL, 1, 1, '2026-04-01T08:00:00', 1, '2026-04-01T08:00:00', 1);
    SET IDENTITY_INSERT management_schema.grievance_department OFF;

    SET IDENTITY_INSERT student_schema.grievance ON;
    INSERT INTO student_schema.grievance
      (grievance_id,grievance_number,school_id,branch_id,academic_year_id,class_id,section_id,student_id,department_id,
       title,category,priority_level,incident_date,location,description,status,submitted_at,
       assigned_to,is_active,created_by)
    SELECT
      st.student_id,
      CONCAT(N'GRV-2026-', st.student_id),
      1, st.branch_id, 1, st.class_id, st.section_id, st.student_id,
      CASE WHEN st.branch_id = 1 THEN 1 ELSE 2 END,
      CASE (st.student_id - 1) % 10
        WHEN 0 THEN N'Math assignment formula clarification'
        WHEN 1 THEN N'Morning bus pickup delay inquiry'
        WHEN 2 THEN N'Physics lab apparatus shortage'
        WHEN 3 THEN N'Hostel hot water supply disruption'
        WHEN 4 THEN N'Term 1 fee receipt reconciliation'
        WHEN 5 THEN N'Classroom projector bulb flickering'
        WHEN 6 THEN N'Harassment report near cafeteria'
        WHEN 7 THEN N'Library card scanner issue'
        WHEN 8 THEN N'Bus air conditioning maintenance'
        ELSE N'Chemistry lab reagent replenishment'
      END,
      CASE (st.student_id - 1) % 10
        WHEN 0 THEN N'ACADEMIC'
        WHEN 1 THEN N'TRANSPORT'
        WHEN 2 THEN N'ACADEMIC'
        WHEN 3 THEN N'HOSTEL'
        WHEN 4 THEN N'FEE'
        WHEN 5 THEN N'FACILITIES'
        WHEN 6 THEN N'BULLYING'
        WHEN 7 THEN N'STAFF_BEHAVIOR'
        WHEN 8 THEN N'TRANSPORT'
        ELSE N'ACADEMIC'
      END,
      CASE (st.student_id - 1) % 10
        WHEN 0 THEN N'LOW'
        WHEN 1 THEN N'MEDIUM'
        WHEN 2 THEN N'HIGH'
        WHEN 3 THEN N'HIGH'
        WHEN 4 THEN N'MEDIUM'
        WHEN 5 THEN N'LOW'
        WHEN 6 THEN N'HIGH'
        WHEN 7 THEN N'LOW'
        WHEN 8 THEN N'MEDIUM'
        ELSE N'MEDIUM'
      END,
      '2026-08-10',
      CASE (st.student_id - 1) % 10
        WHEN 0 THEN N'Classroom 101'
        WHEN 1 THEN N'Main Gate Stop'
        WHEN 2 THEN N'Physics Lab 2'
        WHEN 3 THEN N'Hostel Block B Wing 1'
        WHEN 4 THEN N'Accounts Desk'
        WHEN 5 THEN N'Classroom 204'
        WHEN 6 THEN N'Cafeteria Corridor'
        WHEN 7 THEN N'Central Library'
        WHEN 8 THEN N'Bus #102'
        ELSE N'Chemistry Lab 1'
      END,
      CASE (st.student_id - 1) % 10
        WHEN 0 THEN N'Student requested detailed clarification on quadratic formula problem set.'
        WHEN 1 THEN N'Bus arrived 20 minutes late due to unexpected road diversion.'
        WHEN 2 THEN N'Not enough vernier calipers available during period 3 lab session.'
        WHEN 3 THEN N'Solar heater pump failed on 2nd floor bathrooms early morning.'
        WHEN 4 THEN N'Receipt shows discrepancy in tuition discount deduction.'
        WHEN 5 THEN N'Projector screen dims and flickers during computer science lectures.'
        WHEN 6 THEN N'Senior students making inappropriate remarks during lunch break.'
        WHEN 7 THEN N'Barcode scanner failed to register book borrowing transaction.'
        WHEN 8 THEN N'Air conditioner vents blowing warm air on afternoon return trip.'
        ELSE N'Dilute hydrochloric acid bottles empty before scheduled practical test.'
      END,
      CASE
        WHEN st.student_id <= 25 THEN N'RESOLVED'
        WHEN st.student_id <= 35 THEN N'UNDER_REVIEW'
        ELSE N'SUBMITTED'
      END,
      '2026-08-10T09:30:00',
      CASE WHEN st.student_id >= 36 THEN NULL ELSE 2 END,
      1,
      st.user_id
    FROM student_schema.student st
    WHERE st.student_id BETWEEN 1 AND 40;

    SET IDENTITY_INSERT student_schema.grievance OFF;

    SET IDENTITY_INSERT student_schema.grievance_history ON;
    INSERT INTO student_schema.grievance_history
      (grievance_history_id,grievance_id,submitted_by,submitted_at,assigned_to,reviewed_at,resolved_at,updated_at)
    SELECT
      g.grievance_id,
      g.grievance_id,
      st.user_id,
      g.submitted_at,
      g.assigned_to,
      CASE WHEN g.status IN (N'UNDER_REVIEW', N'RESOLVED') THEN '2026-08-11T11:00:00' ELSE NULL END,
      CASE WHEN g.status = N'RESOLVED' THEN '2026-08-12T15:00:00' ELSE NULL END,
      '2026-08-12T15:00:00'
    FROM student_schema.grievance g
    JOIN student_schema.student st ON st.student_id = g.student_id;
    SET IDENTITY_INSERT student_schema.grievance_history OFF;

    /* ============================================================
       13. LIBRARY (100 Titles, 400 Copies, 80 Circulation Borrows)
       50 Titles Central Campus, 50 Titles North Campus
       4 Copies per Title with Distinct Barcodes
       ============================================================ */
    SET IDENTITY_INSERT library_schema.library_book ON;
    INSERT INTO library_schema.library_book
      (book_id,school_id,branch_id,title,author,subject,category,language,edition,
       description,total_copies,available_copies,is_active,created_by)
    VALUES
      -- Central Campus Books (1 to 50)
      (1,1,1,N'English Grammar & Writing Essentials',N'R. Sharma',N'English',N'Academic',N'English',N'4th',N'Comprehensive grammar guide.',4,4,1,1),
      (2,1,1,N'English Literature: Anthology of Modern Verse',N'M. Thomas',N'English',N'Literature',N'English',N'2nd',N'Prose and poetry selections.',4,4,1,1),
      (3,1,1,N'Mathematics Foundations & Problem Solving',N'A. Rao',N'Mathematics',N'Academic',N'English',N'5th',N'Algebra, geometry, arithmetic.',4,4,1,1),
      (4,1,1,N'Higher Secondary Geometry Masterclass',N'S. Gupta',N'Mathematics',N'Academic',N'English',N'3rd',N'Theorems and geometric constructions.',4,4,1,1),
      (5,1,1,N'General Science Explorer: Physics & Chemistry',N'M. Iyer',N'Science',N'Academic',N'English',N'4th',N'Core physics and chemistry principles.',4,4,1,1),
      (6,1,1,N'Living Science: Biology & Ecology Guide',N'N. Reddy',N'Science',N'Academic',N'English',N'3rd',N'Plant and animal biology.',4,4,1,1),
      (7,1,1,N'Social Science Atlas & Global History',N'K. Menon',N'Social Science',N'Reference',N'English',N'2nd',N'Maps, geography, and world history.',4,4,1,1),
      (8,1,1,N'Indian Constitutional Framework & Civics',N'V. Singh',N'Social Science',N'Academic',N'English',N'3rd',N'Parliamentary and governance systems.',4,4,1,1),
      (9,1,1,N'Python Programming for High School Students',N'P. Nair',N'Computer Science',N'Academic',N'English',N'2nd',N'Hands-on coding with Python.',4,4,1,1),
      (10,1,1,N'Algorithms & Data Structures in Practice',N'P. Nair',N'Computer Science',N'Projects',N'English',N'1st',N'Sorting, searching, and logic.',4,4,1,1),
      (11,1,1,N'Environmental Studies & Sustainability',N'B. Patel',N'Science',N'Reference',N'English',N'1st',N'Ecology and natural resources.',4,4,1,1),
      (12,1,1,N'World History & Civilization Milestones',N'R. Mukherjee',N'Social Science',N'Reference',N'English',N'2nd',N'Industrial revolution and modern history.',4,4,1,1),
      (13,1,1,N'Physical Fitness, Yoga & Health Sciences',N'D. Kumar',N'Physical Education',N'Wellness',N'English',N'1st',N'Exercise physiology and nutrition.',4,4,1,1),
      (14,1,1,N'Creative Writing & Public Speaking Mastery',N'A. Sen',N'English',N'Literature',N'English',N'1st',N'Essays, speeches, and debates.',4,4,1,1),
      (15,1,1,N'Mathematics Olympiad Challenge Problems',N'A. Rao',N'Mathematics',N'Competitive',N'English',N'2nd',N'Advanced competition exercises.',4,4,1,1),
      (16,1,1,N'Malgudi Days & Other Classic Stories',N'R.K. Narayan',N'English',N'Fiction',N'English',N'3rd',N'Heartwarming short stories of South Indian town life.',4,4,1,1),
      (17,1,1,N'The Room on the Roof & Himalayan Tales',N'Ruskin Bond',N'English',N'Literature',N'English',N'2nd',N'Award-winning novel of youth and friendship in the hills.',4,4,1,1),
      (18,1,1,N'Vedic Mathematics & Fast Mental Calculations',N'B.K. Tirthaji',N'Mathematics',N'Academic',N'English',N'4th',N'Ancient mental math techniques and rapid shortcuts.',4,4,1,1),
      (19,1,1,N'Astronomy & The Wonders of the Universe',N'C. Sagan',N'Science',N'Reference',N'English',N'2nd',N'Cosmology, solar system, planets and galaxies.',4,4,1,1),
      (20,1,1,N'Robotics & Artificial Intelligence for Beginners',N'P. Nair',N'Computer Science',N'Academic',N'English',N'1st',N'Introductory sensor programming and robotic logic.',4,4,1,1),
      (21,1,1,N'Ancient Indian History & Cultural Heritage',N'R.S. Sharma',N'Social Science',N'Academic',N'English',N'3rd',N'Indus Valley civilization to the Gupta Golden Age.',4,4,1,1),
      (22,1,1,N'World Geography, Weather & Climate Systems',N'K. Menon',N'Social Science',N'Reference',N'English',N'2nd',N'Atmospheric science, landforms, oceans and biomes.',4,4,1,1),
      (23,1,1,N'Web Development: HTML5, CSS3 & JavaScript',N'P. Nair',N'Computer Science',N'Projects',N'English',N'2nd',N'Modern frontend design and interactive web scripting.',4,4,1,1),
      (24,1,1,N'Cell Biology & Human Anatomy Explorer',N'N. Reddy',N'Science',N'Academic',N'English',N'3rd',N'Organ systems, cellular structures and genetic basics.',4,4,1,1),
      (25,1,1,N'Wings of Fire: An Autobiography',N'A.P.J. Abdul Kalam',N'Biography',N'Inspirational',N'English',N'5th',N'Life journey of India''s Missile Man and President.',4,4,1,1),
      (26,1,1,N'The Discovery of India',N'Jawaharlal Nehru',N'History',N'Reference',N'English',N'4th',N'Cultural and philosophical synthesis of India''s history.',4,4,1,1),
      (27,1,1,N'Shakespearean Plays: Tales & Adaptations',N'C. Lamb',N'English',N'Literature',N'English',N'3rd',N'Classic adaptations of Hamlet, Macbeth and Tempest.',4,4,1,1),
      (28,1,1,N'Fun with Puzzles, Logic & Reasoning',N'Shakuntala Devi',N'Mathematics',N'Competitive',N'English',N'2nd',N'Mathematical puzzles, brain teasers and lateral thinking.',4,4,1,1),
      (29,1,1,N'Chemistry Around Us: Daily Life Experiments',N'M. Iyer',N'Science',N'Laboratory',N'English',N'1st',N'Safe kitchen chemistry and observable chemical principles.',4,4,1,1),
      (30,1,1,N'Environmental Conservation & Green Energy',N'B. Patel',N'Science',N'Reference',N'English',N'2nd',N'Renewable solar, wind power and waste reduction methods.',4,4,1,1),
      (31,1,1,N'Cybersecurity, Privacy & Safe Internet Practices',N'P. Nair',N'Computer Science',N'Technology',N'English',N'1st',N'Digital citizenship, password security and cyber laws.',4,4,1,1),
      (32,1,1,N'Indian Classical Music & Performing Arts',N'V. Bhatkhande',N'Arts',N'Culture',N'English',N'2nd',N'Ragas, talas, instruments and musical traditions.',4,4,1,1),
      (33,1,1,N'Visual Arts, Sketching & Color Composition',N'S. Gujral',N'Arts',N'Creative',N'English',N'1st',N'Perspective drawing, shading and watercolor techniques.',4,4,1,1),
      (34,1,1,N'Cricket Coaching Manual & Sporting Ethics',N'R. Shastri',N'Physical Education',N'Sports',N'English',N'2nd',N'Batting techniques, bowling strategies and teamwork.',4,4,1,1),
      (35,1,1,N'Track & Field Athletics: Training Principles',N'D. Kumar',N'Physical Education',N'Sports',N'English',N'1st',N'Sprinting mechanics, endurance conditioning and field events.',4,4,1,1),
      (36,1,1,N'Encyclopedia of Science & Nature',N'DK Publishing',N'Science',N'Reference',N'English',N'5th',N'Visual encyclopedia covering physics, nature and space.',4,4,1,1),
      (37,1,1,N'World Atlas & Geopolitical Cartography',N'National Geographic',N'Social Science',N'Reference',N'English',N'8th',N'Authoritative cartographic reference and country profiles.',4,4,1,1),
      (38,1,1,N'Essential Hindi Vyakaran & Nibandh Sangrah',N'M.P. Sharma',N'Languages',N'Academic',N'Hindi',N'4th',N'Comprehensive Hindi grammar rules and essay patterns.',4,4,1,1),
      (39,1,1,N'French for Young Learners: Level 1',N'C. Dubois',N'Languages',N'Academic',N'French',N'1st',N'Basic vocabulary, greetings and conversational dialogue.',4,4,1,1),
      (40,1,1,N'Sanskrit Prathama: Basics of Devanagari Script',N'K. Shastri',N'Languages',N'Academic',N'Sanskrit',N'2nd',N'Subhashitas, declensions and introductory Sanskrit prose.',4,4,1,1),
      (41,1,1,N'Swami and Friends: Adventures in Malgudi',N'R.K. Narayan',N'English',N'Fiction',N'English',N'4th',N'Delightful adventures of Swami and his friends in Malgudi.',4,4,1,1),
      (42,1,1,N'Gitanjali: Song Offerings & Poems',N'Rabindranath Tagore',N'Literature',N'Poetry',N'English',N'3rd',N'Nobel Prize winning collection of spiritual and lyrical poetry.',4,4,1,1),
      (43,1,1,N'Advanced Algebra & Polynomial Equations',N'S. Gupta',N'Mathematics',N'Academic',N'English',N'3rd',N'Quadratic equations, polynomials, inequalities and binomial theorem.',4,4,1,1),
      (44,1,1,N'Modern Biology & Genetics Essentials',N'N. Reddy',N'Science',N'Academic',N'English',N'2nd',N'Cell division, heredity, genetics and evolutionary biology.',4,4,1,1),
      (45,1,1,N'Organic Chemistry: Structure and Mechanism',N'M. Iyer',N'Science',N'Academic',N'English',N'3rd',N'Hydrocarbons, functional groups and organic chemical reactions.',4,4,1,1),
      (46,1,1,N'Indian Polity & Constitutional Governance',N'M. Laxmikanth',N'Social Science',N'Reference',N'English',N'6th',N'Comprehensive handbook on Indian constitution, parliament and laws.',4,4,1,1),
      (47,1,1,N'Modern World History: Renaissance to Cold War',N'Norman Lowe',N'Social Science',N'Academic',N'English',N'5th',N'Global conflicts, revolutions and 20th-century world affairs.',4,4,1,1),
      (48,1,1,N'Artificial Intelligence & Machine Learning Primer',N'P. Nair',N'Computer Science',N'Technology',N'English',N'1st',N'Neural networks, computer vision and conversational AI basics.',4,4,1,1),
      (49,1,1,N'Tinkle Double Digest: Folk Tales & Comics',N'Anant Pai',N'Comics',N'Children',N'English',N'1st',N'Engaging moral stories, folktales and illustrated adventure comics.',4,4,1,1),
      (50,1,1,N'Chess Openings, Tactics & Endgame Strategies',N'V. Anand',N'Physical Education',N'Sports',N'English',N'2nd',N'Positional play, strategic calculation and classic grandmaster games.',4,4,1,1),

      -- North Campus Books (51 to 100)
      (51,1,2,N'Modern English Composition & Style',N'R. Sharma',N'English',N'Academic',N'English',N'3rd',N'Essay writing and syntax rules.',4,4,1,1),
      (52,1,2,N'Classic Stories & Play Reader',N'M. Thomas',N'English',N'Literature',N'English',N'1st',N'Drama and narrative anthologies.',4,4,1,1),
      (53,1,2,N'Algebra and Trigonometry for Middle School',N'A. Rao',N'Mathematics',N'Academic',N'English',N'4th',N'Functions and algebraic methods.',4,4,1,1),
      (54,1,2,N'Coordinate Geometry & Vectors Workbook',N'S. Gupta',N'Mathematics',N'Academic',N'English',N'2nd',N'Practical plotting and proofs.',4,4,1,1),
      (55,1,2,N'Applied Physics Lab Manual & Notes',N'M. Iyer',N'Science',N'Laboratory',N'English',N'3rd',N'Optics, electricity and mechanics experiments.',4,4,1,1),
      (56,1,2,N'Chemistry In Action: Molecules to Reactions',N'M. Iyer',N'Science',N'Academic',N'English',N'2nd',N'Inorganic and organic chemistry fundamentals.',4,4,1,1),
      (57,1,2,N'Human Geography & Resource Management',N'K. Menon',N'Social Science',N'Academic',N'English',N'3rd',N'Demographics, climate and agriculture.',4,4,1,1),
      (58,1,2,N'Democratic Politics & Contemporary Issues',N'V. Singh',N'Social Science',N'Academic',N'English',N'2nd',N'Electoral politics and human rights.',4,4,1,1),
      (59,1,2,N'Web Development with Python & Django',N'P. Nair',N'Computer Science',N'Projects',N'English',N'2nd',N'Backend server development and database routing.',4,4,1,1),
      (60,1,2,N'Database Design & SQL Fundamentals',N'P. Nair',N'Computer Science',N'Academic',N'English',N'1st',N'Relational schemas and queries.',4,4,1,1),
      (61,1,2,N'Wildlife Biology & Biodiversity of India',N'N. Reddy',N'Science',N'Reference',N'English',N'1st',N'Flora, fauna and conservation reserves.',4,4,1,1),
      (62,1,2,N'Modern Indian History: Freedom Movement',N'R. Mukherjee',N'Social Science',N'Academic',N'English',N'3rd',N'From 1857 to Indian independence.',4,4,1,1),
      (63,1,2,N'Sports Physiology & Athletic Conditioning',N'D. Kumar',N'Physical Education',N'Wellness',N'English',N'2nd',N'Cardio training and sports ethics.',4,4,1,1),
      (64,1,2,N'Debating Essentials & Persuasive Logic',N'A. Sen',N'English',N'Literature',N'English',N'1st',N'Rhetoric and parliamentary debate skills.',4,4,1,1),
      (65,1,2,N'Competitive Science Quiz & Model Questions',N'M. Iyer',N'Science',N'Competitive',N'English',N'1st',N'National science talent search questions.',4,4,1,1),
      (66,1,2,N'Animal Farm & Selected Essays',N'George Orwell',N'English',N'Fiction',N'English',N'4th',N'Classic political allegory and prose essays.',4,4,1,1),
      (67,1,2,N'Great Expectations & Victorian Tales',N'Charles Dickens',N'English',N'Literature',N'English',N'3rd',N'Masterpiece of Victorian fiction and social critique.',4,4,1,1),
      (68,1,2,N'Calculus Concepts & Intuitive Methods',N'S. Gupta',N'Mathematics',N'Academic',N'English',N'2nd',N'Limits, derivatives, rates of change and curve sketching.',4,4,1,1),
      (69,1,2,N'Probability, Statistics & Data Literacy',N'A. Rao',N'Mathematics',N'Academic',N'English',N'3rd',N'Distributions, mean, median, variance and sample spaces.',4,4,1,1),
      (70,1,2,N'Space Exploration & Rocket Science Essentials',N'M. Iyer',N'Science',N'Reference',N'English',N'1st',N'ISRO, NASA missions, propulsion and satellite orbits.',4,4,1,1),
      (71,1,2,N'Genetics, Evolution & Origin of Species',N'N. Reddy',N'Science',N'Academic',N'English',N'2nd',N'Mendelian inheritance, DNA structure and natural selection.',4,4,1,1),
      (72,1,2,N'Indian Economy & Sustainable Development',N'V. Singh',N'Social Science',N'Academic',N'English',N'3rd',N'Monetary policy, agricultural sector and infrastructure.',4,4,1,1),
      (73,1,2,N'Global Disasters, Geology & Plate Tectonics',N'K. Menon',N'Social Science',N'Reference',N'English',N'2nd',N'Earthquakes, volcanoes, tsunamis and crustal movement.',4,4,1,1),
      (74,1,2,N'Cloud Computing & Internet of Things (IoT)',N'P. Nair',N'Computer Science',N'Technology',N'English',N'1st',N'Smart devices, cloud infrastructure and automation.',4,4,1,1),
      (75,1,2,N'Python for Data Science & Visualization',N'P. Nair',N'Computer Science',N'Academic',N'English',N'2nd',N'NumPy, pandas, Matplotlib and data analytics basics.',4,4,1,1),
      (76,1,2,N'The Story of My Experiments with Truth',N'M.K. Gandhi',N'Biography',N'Inspirational',N'English',N'6th',N'Autobiographical reflections on truth and non-violence.',4,4,1,1),
      (77,1,2,N'Madame Curie: A Biography of Scientific Genius',N'E. Curie',N'Biography',N'Inspirational',N'English',N'2nd',N'Inspiring story of pioneering discoveries in radioactivity.',4,4,1,1),
      (78,1,2,N'The Man Who Knew Infinity: Ramanujan',N'R. Kanigel',N'Biography',N'Inspirational',N'English',N'3rd',N'Extraordinary life of mathematical genius Srinivasa Ramanujan.',4,4,1,1),
      (79,1,2,N'National Science Olympiad Practice Workbook',N'MTG Editorial',N'Science',N'Competitive',N'English',N'4th',N'Olympiad mock tests and comprehensive solutions.',4,4,1,1),
      (80,1,2,N'Mathematical Puzzles & Paradoxes',N'Martin Gardner',N'Mathematics',N'Competitive',N'English',N'3rd',N'Classic recreational mathematics and recreational logic.',4,4,1,1),
      (81,1,2,N'Environmental Pollution & Climate Solutions',N'B. Patel',N'Science',N'Reference',N'English',N'2nd',N'Global warming, carbon footprints and conservation treaties.',4,4,1,1),
      (82,1,2,N'Renewable Energy: Solar, Wind & Hydro Systems',N'B. Patel',N'Science',N'Technology',N'English',N'1st',N'Clean energy engineering and future sustainable grids.',4,4,1,1),
      (83,1,2,N'Dramatic Theatre: Script Writing & Acting',N'A. Sen',N'Arts',N'Creative',N'English',N'1st',N'Stagecraft, character development and voice projection.',4,4,1,1),
      (84,1,2,N'Badminton Strategy & Match Preparation',N'P. Gopichand',N'Physical Education',N'Sports',N'English',N'2nd',N'Court movement, shot selection and match psychology.',4,4,1,1),
      (85,1,2,N'Football Tactics, Drills & Physical Fitness',N'D. Kumar',N'Physical Education',N'Sports',N'English',N'1st',N'Passing drills, defensive formations and athletic stamina.',4,4,1,1),
      (86,1,2,N'First Aid, Emergency Care & School Safety',N'Red Cross Society',N'Health',N'Wellness',N'English',N'3rd',N'CPR, bandaging, emergency response and campus safety.',4,4,1,1),
      (87,1,2,N'Children''s Illustrated History Encyclopedia',N'DK Publishing',N'History',N'Reference',N'English',N'4th',N'Visual timeline of global empires, wars and inventions.',4,4,1,1),
      (88,1,2,N'Oxford School Dictionary & Thesaurus',N'Oxford Univ Press',N'Reference',N'Reference',N'English',N'7th',N'Authoritative English dictionary and vocabulary reference.',4,4,1,1),
      (89,1,2,N'Hindi Sahitya: Kahaniyan & Kavitaen',N'Premchand',N'Languages',N'Literature',N'Hindi',N'3rd',N'Masterpieces of classic Hindi narrative storytelling.',4,4,1,1),
      (90,1,2,N'General Knowledge Yearbook & Quiz Digest',N'Manorama',N'General Knowledge',N'Competitive',N'English',N'2026',N'Current affairs, world records, science and trivia digest.',4,4,1,1),
      (91,1,2,N'Panchatantra: Timeless Moral Fables',N'Vishnu Sharma',N'Literature',N'Children',N'English',N'3rd',N'Illustrated fables imparting practical wisdom and ethical leadership.',4,4,1,2),
      (92,1,2,N'The Blue Umbrella & Other Stories',N'Ruskin Bond',N'English',N'Fiction',N'English',N'2nd',N'Heartwarming novella set in Garhwal hills highlighting kindness and simplicity.',4,4,1,2),
      (93,1,2,N'Discrete Mathematics and Combinatorics',N'A. Rao',N'Mathematics',N'Academic',N'English',N'2nd',N'Graph theory, permutations, mathematical induction and boolean algebra.',4,4,1,2),
      (94,1,2,N'Optics and Modern Physics Essentials',N'M. Iyer',N'Science',N'Academic',N'English',N'3rd',N'Wave optics, lasers, quantum phenomena and nuclear physics introduction.',4,4,1,2),
      (95,1,2,N'Physical Chemistry Principles & Calculations',N'M. Iyer',N'Science',N'Academic',N'English',N'2nd',N'Thermodynamics, chemical kinetics, equilibrium and electrochemistry.',4,4,1,2),
      (96,1,2,N'Indian Art, Architecture & World Heritage Sites',N'E.B. Havell',N'Social Science',N'Culture',N'English',N'1st',N'Temple architecture, Mughal monuments and UNESCO heritage sites in India.',4,4,1,2),
      (97,1,2,N'Disaster Management & Community Resilience',N'NDMA India',N'Social Science',N'Reference',N'English',N'2nd',N'Flood management, cyclone preparedness and school safety emergency drills.',4,4,1,2),
      (98,1,2,N'App Development with Flutter & Dart',N'P. Nair',N'Computer Science',N'Projects',N'English',N'1st',N'Cross-platform mobile UI design, state management and API integration.',4,4,1,2),
      (99,1,2,N'Amar Chitra Katha: Heroes of Ancient India',N'Anant Pai',N'History',N'Comics',N'English',N'1st',N'Graphic biographical tales of historical rulers, philosophers and scholars.',4,4,1,2),
      (100,1,2,N'Yoga Therapy & Adolescent Mental Health',N'B.K.S. Iyengar',N'Physical Education',N'Wellness',N'English',N'4th',N'Asanas, pranayama, stress reduction and mindfulness for students.',4,4,1,2);
    SET IDENTITY_INSERT library_schema.library_book OFF;

    /* 4 Copies per book (100 * 4 = 400 physical copies) */
    SET IDENTITY_INSERT library_schema.library_book_copy ON;
    INSERT INTO library_schema.library_book_copy
      (book_copy_id,book_id,school_id,branch_id,copy_number,barcode,copy_status,is_active,created_by)
    SELECT
      (b.book_id - 1) * 4 + x.copy_no,
      b.book_id,
      b.school_id,
      b.branch_id,
      x.copy_no,
      CONCAT(N'BK-', RIGHT(N'000' + CAST(b.book_id AS NVARCHAR(3)), 3), N'-C', x.copy_no),
      N'AVAILABLE',
      1,
      1
    FROM library_schema.library_book b
    CROSS JOIN (SELECT 1 copy_no UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) x;
    SET IDENTITY_INSERT library_schema.library_book_copy OFF;

    /* 80 circulation borrow records:
       Central Campus students 1..40 borrow Central Campus books (1..40)
       North Campus students 201..240 borrow North Campus books (51..90)
       UX_library_book_borrow_active_copy allows only one ACTIVE or OVERDUE loan per copy. */
    SET IDENTITY_INSERT library_schema.library_book_borrow ON;
    INSERT INTO library_schema.library_book_borrow
      (borrow_id,school_id,branch_id,academic_year_id,student_id,class_id,section_id,book_id,book_copy_id,borrow_status,
       borrowed_at,due_date,returned_at,issued_by,returned_to,is_active)
    -- Central branch borrows (students 1..40)
    SELECT
      st.student_id,
      1,
      st.branch_id,
      1,
      st.student_id,
      st.class_id,
      st.section_id,
      st.student_id,                              -- book_id 1..40 (Central)
      (st.student_id - 1) * 4 + 1,                -- Copy 1 of that book
      CASE WHEN st.student_id % 3 = 0 THEN N'RETURNED'
           WHEN st.student_id % 3 = 1 THEN N'ACTIVE'
           ELSE N'OVERDUE' END,
      DATEADD(DAY, -(st.student_id % 12 + 3), CAST('2026-08-31T10:00:00' AS DATETIME2)),
      DATEADD(DAY, 14, DATEADD(DAY, -(st.student_id % 12 + 3), CAST('2026-08-31T10:00:00' AS DATE))),
      CASE WHEN st.student_id % 3 = 0 THEN DATEADD(DAY, -1, CAST('2026-08-31T10:00:00' AS DATETIME2)) ELSE NULL END,
      18,
      CASE WHEN st.student_id % 3 = 0 THEN 18 ELSE NULL END,
      1
    FROM student_schema.student st
    WHERE st.student_id BETWEEN 1 AND 40
    UNION ALL
    -- North branch borrows (students 201..240)
    SELECT
      40 + (st.student_id - 200),
      1,
      st.branch_id,
      1,
      st.student_id,
      st.class_id,
      st.section_id,
      50 + (st.student_id - 200),                 -- book_id 51..90 (North)
      (50 + (st.student_id - 200) - 1) * 4 + 1,   -- Copy 1 of that book
      CASE WHEN st.student_id % 3 = 0 THEN N'RETURNED'
           WHEN st.student_id % 3 = 1 THEN N'ACTIVE'
           ELSE N'OVERDUE' END,
      DATEADD(DAY, -(st.student_id % 12 + 3), CAST('2026-08-31T10:00:00' AS DATETIME2)),
      DATEADD(DAY, 14, DATEADD(DAY, -(st.student_id % 12 + 3), CAST('2026-08-31T10:00:00' AS DATE))),
      CASE WHEN st.student_id % 3 = 0 THEN DATEADD(DAY, -1, CAST('2026-08-31T10:00:00' AS DATETIME2)) ELSE NULL END,
      18,
      CASE WHEN st.student_id % 3 = 0 THEN 18 ELSE NULL END,
      1
    FROM student_schema.student st
    WHERE st.student_id BETWEEN 201 AND 240;
    SET IDENTITY_INSERT library_schema.library_book_borrow OFF;

    /* Synchronize book copy statuses */
    UPDATE bc
       SET copy_status = CASE WHEN EXISTS
           (SELECT 1 FROM library_schema.library_book_borrow bb
            WHERE bb.book_copy_id = bc.book_copy_id AND bb.is_active = 1
              AND bb.borrow_status IN (N'ACTIVE', N'OVERDUE'))
           THEN N'BORROWED' ELSE N'AVAILABLE' END
    FROM library_schema.library_book_copy bc;

    UPDATE b
       SET total_copies = 4,
           available_copies = ISNULL((
           SELECT COUNT(*)
           FROM library_schema.library_book_copy bc
           WHERE bc.book_id = b.book_id AND bc.is_active = 1 AND bc.copy_status = N'AVAILABLE'
       ), 0)
    FROM library_schema.library_book b;

    /* ============================================================
       14. TRANSPORT (4 Buses, 8 Staff, 8 Master Routes, 24 Stops, 8 Trips)
       Transport Staff Mapped to Users mgt_1207..mgt_1214
       ============================================================ */
    SET IDENTITY_INSERT transport_schema.vehicle ON;
    INSERT INTO transport_schema.vehicle
      (vehicle_id,school_id,branch_id,vehicle_number,vehicle_name,capacity,status,vehicle_health,is_active,created_by)
    VALUES
      (1,1,1,N'TG-01-AB-1001',N'Central Campus Bus A',50,N'ACTIVE',N'EXCELLENT',1,1),
      (2,1,1,N'TG-01-AB-1002',N'Central Campus Bus B',50,N'ACTIVE',N'GOOD',1,1),
      (3,1,2,N'TG-02-AB-2001',N'North Campus Bus A',50,N'ACTIVE',N'GOOD',1,1),
      (4,1,2,N'TG-02-AB-2002',N'North Campus Bus B',50,N'ACTIVE',N'NEEDS_SERVICE',1,1);
    SET IDENTITY_INSERT transport_schema.vehicle OFF;

    SET IDENTITY_INSERT transport_schema.staff ON;
    INSERT INTO transport_schema.staff
      (staff_id,school_id,branch_id,user_id,staff_name,staff_type,experience,mobile_number,license_number,
       license_expiry_date,status,is_active,created_by)
    VALUES
      (1,1,1,7,N'Ravi Kumar',N'DRIVER',12,N'919800000001',N'TS-DRV-1001','2028-12-31',N'ACTIVE',1,1),
      (2,1,1,8,N'Suresh Naidu',N'DRIVER',9,N'919800000002',N'TS-DRV-1002','2028-12-31',N'ACTIVE',1,1),
      (3,1,2,9,N'Vijay Reddy',N'DRIVER',14,N'919800000003',N'TS-DRV-2001','2028-12-31',N'ACTIVE',1,1),
      (4,1,2,10,N'Prakash Rao',N'DRIVER',8,N'919800000004',N'TS-DRV-2002','2028-12-31',N'ACTIVE',1,1),
      (5,1,1,11,N'Mohan Rao',N'ATTENDANT',5,N'919800000005',NULL,NULL,N'ACTIVE',1,1),
      (6,1,1,12,N'Karthik Rao',N'ATTENDANT',4,N'919800000006',NULL,NULL,N'ACTIVE',1,1),
      (7,1,2,13,N'Imran Ali',N'ATTENDANT',6,N'919800000007',NULL,NULL,N'ACTIVE',1,1),
      (8,1,2,14,N'Anil Kumar',N'ATTENDANT',3,N'919800000008',NULL,NULL,N'ACTIVE',1,1);
    SET IDENTITY_INSERT transport_schema.staff OFF;

    SET IDENTITY_INSERT transport_schema.vehicle_route ON;
    INSERT INTO transport_schema.vehicle_route
      (vehicle_route_id,school_id,branch_id,vehicle_id,route_code,route_name,route_type,
       status,effective_from,effective_to,is_active,created_by)
    VALUES
      (1,1,1,1,N'BR1-PU1',N'Central Route 1 Morning Pickup',N'PICKUP',N'ACTIVE','2026-04-01',NULL,1,1),
      (2,1,1,1,N'BR1-DR1',N'Central Route 1 Afternoon Drop',  N'DROP',  N'ACTIVE','2026-04-01',NULL,1,1),
      (3,1,1,2,N'BR1-PU2',N'Central Route 2 Morning Pickup',N'PICKUP',N'ACTIVE','2026-04-01',NULL,1,1),
      (4,1,1,2,N'BR1-DR2',N'Central Route 2 Afternoon Drop',  N'DROP',  N'ACTIVE','2026-04-01',NULL,1,1),
      (5,1,2,3,N'BR2-PU1',N'North Route 1 Morning Pickup',  N'PICKUP',N'ACTIVE','2026-04-01',NULL,1,1),
      (6,1,2,3,N'BR2-DR1',N'North Route 1 Afternoon Drop',  N'DROP',  N'ACTIVE','2026-04-01',NULL,1,1),
      (7,1,2,4,N'BR2-PU2',N'North Route 2 Morning Pickup',  N'PICKUP',N'ACTIVE','2026-04-01',NULL,1,1),
      (8,1,2,4,N'BR2-DR2',N'North Route 2 Afternoon Drop',  N'DROP',  N'ACTIVE','2026-04-01',NULL,1,1);
    SET IDENTITY_INSERT transport_schema.vehicle_route OFF;

    SET IDENTITY_INSERT transport_schema.vehicle_route_stop ON;
    INSERT INTO transport_schema.vehicle_route_stop
      (route_stop_id,vehicle_route_id,stop_sequence,stop_name,stop_address,
       planned_arrival_time,planned_departure_time,is_active,created_by)
    VALUES
      -- Route 1: Central Route 1 Morning Pickup
      (101,1,1,N'Jubilee Hills Check Post', N'Road No 36, Jubilee Hills', '07:10','07:12',1,1),
      (102,1,2,N'Madhapur Metro Station',   N'Hitec City Main Road',      '07:25','07:27',1,1),
      (103,1,3,N'Central Campus Gate',     N'Campus Main Entrance',       '08:05','08:10',1,1),
      -- Route 2: Central Route 1 Afternoon Drop
      (104,2,1,N'Central Campus Gate',     N'Campus Main Entrance',       '15:10','15:12',1,1),
      (105,2,2,N'Madhapur Metro Station',   N'Hitec City Main Road',      '15:35','15:37',1,1),
      (106,2,3,N'Jubilee Hills Check Post', N'Road No 36, Jubilee Hills', '15:50','15:52',1,1),
      -- Route 3: Central Route 2 Morning Pickup
      (107,3,1,N'Banjara Hills Care Hospital', N'Road No 1, Banjara Hills','07:10','07:12',1,1),
      (108,3,2,N'Somajiguda Circle',        N'Raj Bhavan Road',           '07:25','07:27',1,1),
      (109,3,3,N'Central Campus Gate',     N'Campus Main Entrance',       '08:05','08:10',1,1),
      -- Route 4: Central Route 2 Afternoon Drop
      (110,4,1,N'Central Campus Gate',     N'Campus Main Entrance',       '15:10','15:12',1,1),
      (111,4,2,N'Somajiguda Circle',        N'Raj Bhavan Road',           '15:35','15:37',1,1),
      (112,4,3,N'Banjara Hills Care Hospital', N'Road No 1, Banjara Hills','15:50','15:52',1,1),
      -- Route 5: North Route 1 Morning Pickup
      (201,5,1,N'Secunderabad Clock Tower', N'MG Road, Secunderabad',     '07:10','07:12',1,1),
      (202,5,2,N'Paradise Circle',          N'Airport Road',              '07:25','07:27',1,1),
      (203,5,3,N'North Campus Gate',        N'North Campus Entrance',     '08:05','08:10',1,1),
      -- Route 6: North Route 1 Afternoon Drop
      (204,6,1,N'North Campus Gate',        N'North Campus Entrance',     '15:10','15:12',1,1),
      (205,6,2,N'Paradise Circle',          N'Airport Road',              '15:35','15:37',1,1),
      (206,6,3,N'Secunderabad Clock Tower', N'MG Road, Secunderabad',     '15:50','15:52',1,1),
      -- Route 7: North Route 2 Morning Pickup
      (207,7,1,N'Trimulgherry Cross Road',  N'Military Area Junction',    '07:10','07:12',1,1),
      (208,7,2,N'Karkhana Main Road',       N'APHB Colony Road',          '07:25','07:27',1,1),
      (209,7,3,N'North Campus Gate',        N'North Campus Entrance',     '08:05','08:10',1,1),
      -- Route 8: North Route 2 Afternoon Drop
      (210,8,1,N'North Campus Gate',        N'North Campus Entrance',     '15:10','15:12',1,1),
      (211,8,2,N'Karkhana Main Road',       N'APHB Colony Road',          '15:35','15:37',1,1),
      (212,8,3,N'Trimulgherry Cross Road',  N'Military Area Junction',    '15:50','15:52',1,1);
    SET IDENTITY_INSERT transport_schema.vehicle_route_stop OFF;

    SET IDENTITY_INSERT transport_schema.trip ON;
    INSERT INTO transport_schema.trip
      (trip_id,school_id,branch_id,vehicle_id,vehicle_route_id,driver_id,driver_type_enforcer,
       trip_date,trip_type,planned_start_time,actual_start_at,planned_destination_time,actual_destination_at,
       delay_minutes,status,is_active,created_by)
    VALUES
      (1,1,1,1,1,1,N'DRIVER','2026-08-29',N'PICKUP','07:00','2026-08-29T07:03:00','08:10','2026-08-29T08:13:00',3,N'COMPLETED',1,1),
      (2,1,1,1,2,1,N'DRIVER','2026-08-29',N'DROP',  '15:00','2026-08-29T15:02:00','15:55','2026-08-29T15:58:00',3,N'COMPLETED',1,1),
      (3,1,1,2,3,2,N'DRIVER','2026-08-29',N'PICKUP','07:00','2026-08-29T07:01:00','08:10','2026-08-29T08:12:00',2,N'COMPLETED',1,1),
      (4,1,1,2,4,2,N'DRIVER','2026-08-29',N'DROP',  '15:00','2026-08-29T15:04:00','15:55','2026-08-29T15:59:00',4,N'COMPLETED',1,1),
      (5,1,2,3,5,3,N'DRIVER','2026-08-29',N'PICKUP','07:00','2026-08-29T07:02:00','08:10','2026-08-29T08:11:00',1,N'COMPLETED',1,1),
      (6,1,2,3,6,3,N'DRIVER','2026-08-29',N'DROP',  '15:00','2026-08-29T15:01:00','15:55','2026-08-29T15:56:00',1,N'COMPLETED',1,1),
      (7,1,2,4,7,4,N'DRIVER','2026-08-29',N'PICKUP','07:00','2026-08-29T07:05:00','08:10','2026-08-29T08:14:00',4,N'COMPLETED',1,1),
      (8,1,2,4,8,4,N'DRIVER','2026-08-29',N'DROP',  '15:00','2026-08-29T15:03:00','15:55','2026-08-29T15:57:00',2,N'COMPLETED',1,1);
    SET IDENTITY_INSERT transport_schema.trip OFF;

    SET IDENTITY_INSERT transport_schema.trip_stop ON;
    INSERT INTO transport_schema.trip_stop
      (trip_stop_id,trip_id,vehicle_route_id,route_stop_id,stop_sequence,planned_arrival_at,
       actual_arrival_at,actual_departure_at,delay_minutes,status)
    SELECT
      ROW_NUMBER() OVER (ORDER BY t.trip_id, vrs.stop_sequence),
      t.trip_id,
      vrs.vehicle_route_id,
      vrs.route_stop_id,
      vrs.stop_sequence,
      DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), vrs.planned_arrival_time), CAST(t.trip_date AS DATETIME2(0))),
      DATEADD(MINUTE, 2, DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), vrs.planned_arrival_time), CAST(t.trip_date AS DATETIME2(0)))),
      DATEADD(MINUTE, 4, DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), vrs.planned_arrival_time), CAST(t.trip_date AS DATETIME2(0)))),
      2,
      N'DEPARTED'
    FROM transport_schema.trip t
    JOIN transport_schema.vehicle_route_stop vrs
      ON vrs.vehicle_route_id = t.vehicle_route_id;
    SET IDENTITY_INSERT transport_schema.trip_stop OFF;

    SET IDENTITY_INSERT transport_schema.speed_measurement ON;
    INSERT INTO transport_schema.speed_measurement
      (speed_measurement_id,trip_id,vehicle_id,recorded_at,speed_kmh)
    SELECT
      ROW_NUMBER() OVER (ORDER BY t.trip_id, n.n),
      t.trip_id,
      t.vehicle_id,
      DATEADD(MINUTE, n.n * 10, CAST('2026-08-29T07:10:00' AS DATETIME2(0))),
      CAST(25.0 + (t.trip_id * 3 + n.n * 4) % 25 AS DECIMAL(6,2))
    FROM transport_schema.trip t
    CROSS JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3) n;
    SET IDENTITY_INSERT transport_schema.speed_measurement OFF;

    /* Transport Assignments: ALL 320 DAY SCHOLARS mapped to route stops */
    SET IDENTITY_INSERT student_schema.transport_assignment ON;
    INSERT INTO student_schema.transport_assignment
      (transport_assignment_id,school_id,branch_id,academic_year_id,class_id,section_id,student_id,
       vehicle_route_id,pickup_route_stop_id,drop_route_stop_id,estimated_pickup_time,estimated_drop_time,
       effective_from,effective_to,status,is_active,created_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY st.student_id),
      1,
      st.branch_id,
      1,
      st.class_id,
      st.section_id,
      st.student_id,
      CASE WHEN st.branch_id = 1 THEN
        CASE WHEN st.student_id % 2 = 1 THEN 1 ELSE 3 END
      ELSE
        CASE WHEN st.student_id % 2 = 1 THEN 5 ELSE 7 END
      END AS vehicle_route_id,
      CASE WHEN st.branch_id = 1 THEN
        CASE WHEN st.student_id % 2 = 1 THEN 101 ELSE 107 END
      ELSE
        CASE WHEN st.student_id % 2 = 1 THEN 201 ELSE 207 END
      END AS pickup_route_stop_id,
      CASE WHEN st.branch_id = 1 THEN
        CASE WHEN st.student_id % 2 = 1 THEN 103 ELSE 109 END
      ELSE
        CASE WHEN st.student_id % 2 = 1 THEN 203 ELSE 209 END
      END AS drop_route_stop_id,
      '07:15',
      '08:05',
      '2026-04-01',
      NULL,
      N'ACTIVE',
      1,
      1
    FROM student_schema.student st
    WHERE st.residency_type = N'DAY_SCHOLAR' AND st.student_status = N'ACTIVE';
    SET IDENTITY_INSERT student_schema.transport_assignment OFF;

    SET IDENTITY_INSERT student_schema.transport_change_request ON;
    INSERT INTO student_schema.transport_change_request
      (transport_change_request_id,transport_assignment_id,school_id,branch_id,student_id,request_type,
       current_vehicle_route_id,requested_vehicle_route_id,current_pickup_stop_id,requested_pickup_stop_id,
       current_drop_stop_id,requested_drop_stop_id,effective_date,return_date,reason,status,
       reviewed_by,reviewed_at,is_active,created_by)
    SELECT
      ta.transport_assignment_id,
      ta.transport_assignment_id,
      ta.school_id,
      ta.branch_id,
      ta.student_id,
      N'PERMANENT',
      ta.vehicle_route_id,
      ta.vehicle_route_id,
      ta.pickup_route_stop_id,
      CASE WHEN ta.pickup_route_stop_id IN (101, 107) THEN ta.pickup_route_stop_id + 1 ELSE ta.pickup_route_stop_id END,
      ta.drop_route_stop_id,
      ta.drop_route_stop_id,
      '2026-09-01',
      NULL,
      N'Family shifted residential address.',
      N'APPROVED',
      1,
      '2026-08-30T10:00:00',
      1,
      st.user_id
    FROM student_schema.transport_assignment ta
    JOIN student_schema.student st ON st.student_id = ta.student_id
    WHERE ta.transport_assignment_id <= 4;
    SET IDENTITY_INSERT student_schema.transport_change_request OFF;

    /* ============================================================
       15. FINANCE (Fee Structures for 20 Classes, 400 Student Records & Txns)
       ============================================================ */
    SET IDENTITY_INSERT finance_schema.fee_structure_term ON;
    INSERT INTO finance_schema.fee_structure_term
      (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id,
       total_amount, term1_amount, term2_amount, term3_amount,
       term1_due_date, term2_due_date, term3_due_date,
       status, is_active, created_by)
    SELECT
      c.class_id,
      1,
      CASE WHEN c.class_id <= 10 THEN 1 ELSE 2 END,
      1,
      c.class_id,
      CASE
        WHEN c.display_order <= 5 THEN 60000.00
        WHEN c.display_order <= 8 THEN 75000.00
        ELSE 90000.00
      END,
      CASE
        WHEN c.display_order <= 5 THEN 20000.00
        WHEN c.display_order <= 8 THEN 25000.00
        ELSE 30000.00
      END,
      CASE
        WHEN c.display_order <= 5 THEN 20000.00
        WHEN c.display_order <= 8 THEN 25000.00
        ELSE 30000.00
      END,
      CASE
        WHEN c.display_order <= 5 THEN 20000.00
        WHEN c.display_order <= 8 THEN 25000.00
        ELSE 30000.00
      END,
      '2026-06-30', '2026-10-31', '2027-01-31',
      N'ACTIVE', 1, 1
    FROM management_schema.school_class c;
    SET IDENTITY_INSERT finance_schema.fee_structure_term OFF;

    SET IDENTITY_INSERT finance_schema.student_fee_record ON;
    ;WITH StudentFeeCalc AS (
        SELECT
            st.student_id,
            st.school_id,
            st.branch_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            st.residency_type,
            fs.fee_structure_term_id,

            -- Scholarship: 5,000 for every 10th student
            CASE WHEN st.student_id % 10 = 0 THEN CAST(5000.00 AS DECIMAL(12,2)) ELSE CAST(0.00 AS DECIMAL(12,2)) END AS schol_amt,

            -- Other Fee: 3,000 applicable to every student
            CAST(3000.00 AS DECIMAL(12,2)) AS oth_amt,
            CASE
                WHEN st.student_id % 4 IN (1, 2) THEN CAST(3000.00 AS DECIMAL(12,2))
                WHEN st.student_id % 4 = 3 THEN CAST(1500.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS oth_paid,

            -- Term 1 Tuition
            fs.term1_amount AS t1_tui_amt,
            CASE
                WHEN st.student_id % 4 IN (1, 3) THEN fs.term1_amount
                /* Full payers with a scholarship must not pay more than the net fee. */
                WHEN st.student_id % 4 = 2 THEN fs.term1_amount
                    - CASE WHEN st.student_id % 10 = 0 THEN CAST(5000.00 AS DECIMAL(12,2)) ELSE CAST(0.00 AS DECIMAL(12,2)) END
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t1_tui_paid,

            -- Term 1 Residency: HOSTELLER = 15,000; DAY_SCHOLAR = 5,000
            CASE WHEN st.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2)) ELSE CAST(5000.00 AS DECIMAL(12,2)) END AS t1_res_amt,
            CASE WHEN st.student_id % 4 IN (1, 2, 3) THEN
                (CASE WHEN st.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2)) ELSE CAST(5000.00 AS DECIMAL(12,2)) END)
            ELSE CAST(0.00 AS DECIMAL(12,2)) END AS t1_res_paid,

            -- Term 2 Tuition
            fs.term2_amount AS t2_tui_amt,
            CASE WHEN st.student_id % 4 = 2 THEN fs.term2_amount
                 WHEN st.student_id % 4 = 3 THEN CAST(10000.00 AS DECIMAL(12,2))
                 ELSE CAST(0.00 AS DECIMAL(12,2)) END AS t2_tui_paid,

            -- Term 2 Residency
            CASE WHEN st.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2)) ELSE CAST(5000.00 AS DECIMAL(12,2)) END AS t2_res_amt,
            CASE WHEN st.student_id % 4 = 2 THEN
                (CASE WHEN st.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2)) ELSE CAST(5000.00 AS DECIMAL(12,2)) END)
            ELSE CAST(0.00 AS DECIMAL(12,2)) END AS t2_res_paid,

            -- Term 3 Tuition
            fs.term3_amount AS t3_tui_amt,
            CASE WHEN st.student_id % 4 = 2 THEN fs.term3_amount ELSE CAST(0.00 AS DECIMAL(12,2)) END AS t3_tui_paid,

            -- Term 3 Residency
            CASE WHEN st.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2)) ELSE CAST(5000.00 AS DECIMAL(12,2)) END AS t3_res_amt,
            CASE WHEN st.student_id % 4 = 2 THEN
                (CASE WHEN st.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2)) ELSE CAST(5000.00 AS DECIMAL(12,2)) END)
            ELSE CAST(0.00 AS DECIMAL(12,2)) END AS t3_res_paid
        FROM student_schema.student st
        JOIN finance_schema.fee_structure_term fs
          ON fs.class_id = st.class_id
         AND fs.branch_id = st.branch_id
        WHERE st.student_status = N'ACTIVE'
    )
    INSERT INTO finance_schema.student_fee_record
    (
        student_fee_record_id, fee_structure_term_id, school_id, branch_id, academic_year_id, class_id, section_id, student_id,
        residency_type,
        term1_tuition_amount, term1_tuition_paid, term1_tuition_balance, term1_tuition_status,
        term1_residency_amount, term1_residency_paid, term1_residency_balance, term1_residency_status,
        term1_total_amount, term1_total_paid, term1_total_balance, term1_status,
        term2_tuition_amount, term2_tuition_paid, term2_tuition_balance, term2_tuition_status,
        term2_residency_amount, term2_residency_paid, term2_residency_balance, term2_residency_status,
        term2_total_amount, term2_total_paid, term2_total_balance, term2_status,
        term3_tuition_amount, term3_tuition_paid, term3_tuition_balance, term3_tuition_status,
        term3_residency_amount, term3_residency_paid, term3_residency_balance, term3_residency_status,
        term3_total_amount, term3_total_paid, term3_total_balance, term3_status,
        other_fee_amount, other_fee_paid, other_fee_balance, other_fee_status,
        scholarship_amount, total_fee_amount, total_paid_amount, total_balance_amount, overall_status,
        is_active, created_by
    )
    SELECT
        c.student_id,
        c.fee_structure_term_id, 1, c.branch_id, 1, c.class_id, c.section_id, c.student_id,
        c.residency_type,
        c.t1_tui_amt, c.t1_tui_paid, (c.t1_tui_amt - c.t1_tui_paid),
        CASE WHEN c.t1_tui_paid = 0 THEN N'PENDING' WHEN c.t1_tui_paid = c.t1_tui_amt THEN N'PAID' ELSE N'PARTIAL' END,
        c.t1_res_amt, c.t1_res_paid, (c.t1_res_amt - c.t1_res_paid),
        CASE WHEN c.t1_res_paid = 0 THEN N'PENDING' WHEN c.t1_res_paid = c.t1_res_amt THEN N'PAID' ELSE N'PARTIAL' END,
        (c.t1_tui_amt + c.t1_res_amt), (c.t1_tui_paid + c.t1_res_paid), ((c.t1_tui_amt + c.t1_res_amt) - (c.t1_tui_paid + c.t1_res_paid)),
        CASE WHEN (c.t1_tui_paid + c.t1_res_paid) = 0 THEN N'PENDING' WHEN (c.t1_tui_paid + c.t1_res_paid) = (c.t1_tui_amt + c.t1_res_amt) THEN N'PAID' ELSE N'PARTIAL' END,

        c.t2_tui_amt, c.t2_tui_paid, (c.t2_tui_amt - c.t2_tui_paid),
        CASE WHEN c.t2_tui_paid = 0 THEN N'PENDING' WHEN c.t2_tui_paid = c.t2_tui_amt THEN N'PAID' ELSE N'PARTIAL' END,
        c.t2_res_amt, c.t2_res_paid, (c.t2_res_amt - c.t2_res_paid),
        CASE WHEN c.t2_res_paid = 0 THEN N'PENDING' WHEN c.t2_res_paid = c.t2_res_amt THEN N'PAID' ELSE N'PARTIAL' END,
        (c.t2_tui_amt + c.t2_res_amt), (c.t2_tui_paid + c.t2_res_paid), ((c.t2_tui_amt + c.t2_res_amt) - (c.t2_tui_paid + c.t2_res_paid)),
        CASE WHEN (c.t2_tui_paid + c.t2_res_paid) = 0 THEN N'PENDING' WHEN (c.t2_tui_paid + c.t2_res_paid) = (c.t2_tui_amt + c.t2_res_amt) THEN N'PAID' ELSE N'PARTIAL' END,

        c.t3_tui_amt, c.t3_tui_paid, (c.t3_tui_amt - c.t3_tui_paid),
        CASE WHEN c.t3_tui_paid = 0 THEN N'PENDING' WHEN c.t3_tui_paid = c.t3_tui_amt THEN N'PAID' ELSE N'PARTIAL' END,
        c.t3_res_amt, c.t3_res_paid, (c.t3_res_amt - c.t3_res_paid),
        CASE WHEN c.t3_res_paid = 0 THEN N'PENDING' WHEN c.t3_res_paid = c.t3_res_amt THEN N'PAID' ELSE N'PARTIAL' END,
        (c.t3_tui_amt + c.t3_res_amt), (c.t3_tui_paid + c.t3_res_paid), ((c.t3_tui_amt + c.t3_res_amt) - (c.t3_tui_paid + c.t3_res_paid)),
        CASE WHEN (c.t3_tui_paid + c.t3_res_paid) = 0 THEN N'PENDING' WHEN (c.t3_tui_paid + c.t3_res_paid) = (c.t3_tui_amt + c.t3_res_amt) THEN N'PAID' ELSE N'PARTIAL' END,

        c.oth_amt, c.oth_paid, (c.oth_amt - c.oth_paid),
        CASE WHEN c.oth_paid = 0 THEN N'PENDING' WHEN c.oth_paid = c.oth_amt THEN N'PAID' ELSE N'PARTIAL' END,

        c.schol_amt,
        (((c.t1_tui_amt + c.t1_res_amt) + (c.t2_tui_amt + c.t2_res_amt) + (c.t3_tui_amt + c.t3_res_amt) + c.oth_amt) - c.schol_amt),
        ((c.t1_tui_paid + c.t1_res_paid) + (c.t2_tui_paid + c.t2_res_paid) + (c.t3_tui_paid + c.t3_res_paid) + c.oth_paid),
        ((((c.t1_tui_amt + c.t1_res_amt) + (c.t2_tui_amt + c.t2_res_amt) + (c.t3_tui_amt + c.t3_res_amt) + c.oth_amt) - c.schol_amt) -
         ((c.t1_tui_paid + c.t1_res_paid) + (c.t2_tui_paid + c.t2_res_paid) + (c.t3_tui_paid + c.t3_res_paid) + c.oth_paid)),
        CASE
            WHEN ((c.t1_tui_paid + c.t1_res_paid) + (c.t2_tui_paid + c.t2_res_paid) + (c.t3_tui_paid + c.t3_res_paid) + c.oth_paid) = 0 THEN N'PENDING'
            WHEN ((c.t1_tui_paid + c.t1_res_paid) + (c.t2_tui_paid + c.t2_res_paid) + (c.t3_tui_paid + c.t3_res_paid) + c.oth_paid) =
                 (((c.t1_tui_amt + c.t1_res_amt) + (c.t2_tui_amt + c.t2_res_amt) + (c.t3_tui_amt + c.t3_res_amt) + c.oth_amt) - c.schol_amt) THEN N'PAID'
            ELSE N'PARTIAL' END,
        1, 1
    FROM StudentFeeCalc c;
    SET IDENTITY_INSERT finance_schema.student_fee_record OFF;

    SET IDENTITY_INSERT finance_schema.fee_payment_transaction ON;
    ;WITH AllPayments AS (
        SELECT f.student_fee_record_id, 1 AS school_id, f.branch_id, 1 AS academic_year_id, f.student_id, f.class_id, f.section_id,
            N'TUITION' AS fee_type, CAST(1 AS TINYINT) AS term_number, f.term1_tuition_paid AS amount,
            N'ONLINE' AS payment_method, N'RAZORPAY' AS payment_gateway,
            CONCAT(N'pay_rzp_t1_', RIGHT(CONCAT(N'0000', CAST(f.student_id AS NVARCHAR(4))), 4)) AS gateway_transaction_id,
            CONCAT(N'UTR-42890', RIGHT(CONCAT(N'000000', CAST(f.student_id * 1111 AS NVARCHAR(20))), 6)) AS transaction_reference,
            '2026-05-10T10:30:00' AS paid_at
        FROM finance_schema.student_fee_record f WHERE f.term1_tuition_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'HOSTEL', 1, f.term1_residency_paid,
            N'BANK_TRANSFER', NULL, NULL,
            CONCAT(N'NEFT-HDFC-', RIGHT(CONCAT(N'000000', CAST(f.student_id * 2222 AS NVARCHAR(20))), 6)),
            '2026-05-11T11:15:00'
        FROM finance_schema.student_fee_record f WHERE f.residency_type = N'HOSTELLER' AND f.term1_residency_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'TRANSPORT', 1, f.term1_residency_paid,
            N'UPI', NULL, NULL,
            CONCAT(N'UTR-42891', RIGHT(CONCAT(N'000000', CAST(f.student_id * 3333 AS NVARCHAR(20))), 6)),
            '2026-05-12T09:00:00'
        FROM finance_schema.student_fee_record f WHERE f.residency_type = N'DAY_SCHOLAR' AND f.term1_residency_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'TUITION', 2, f.term2_tuition_paid,
            N'CARD', N'HDFC_PG',
            CONCAT(N'pg_hdfc_t2_', RIGHT(CONCAT(N'0000', CAST(f.student_id AS NVARCHAR(4))), 4)),
            CONCAT(N'AUTH-CODE-', RIGHT(CONCAT(N'000000', CAST(f.student_id * 4444 AS NVARCHAR(20))), 6)),
            '2026-09-15T14:20:00'
        FROM finance_schema.student_fee_record f WHERE f.term2_tuition_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'HOSTEL', 2, f.term2_residency_paid,
            N'BANK_TRANSFER', NULL, NULL,
            CONCAT(N'RTGS-SBI-', RIGHT(CONCAT(N'000000', CAST(f.student_id * 5555 AS NVARCHAR(20))), 6)),
            '2026-09-16T15:00:00'
        FROM finance_schema.student_fee_record f WHERE f.residency_type = N'HOSTELLER' AND f.term2_residency_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'TRANSPORT', 2, f.term2_residency_paid,
            N'UPI', NULL, NULL,
            CONCAT(N'UTR-42892', RIGHT(CONCAT(N'000000', CAST(f.student_id * 6666 AS NVARCHAR(20))), 6)),
            '2026-09-17T12:10:00'
        FROM finance_schema.student_fee_record f WHERE f.residency_type = N'DAY_SCHOLAR' AND f.term2_residency_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'TUITION', 3, f.term3_tuition_paid,
            N'ONLINE', N'RAZORPAY',
            CONCAT(N'pay_rzp_t3_', RIGHT(CONCAT(N'0000', CAST(f.student_id AS NVARCHAR(4))), 4)),
            CONCAT(N'REF-TXN-T3-', CAST(f.student_id AS NVARCHAR(4))),
            '2027-01-10T16:00:00'
        FROM finance_schema.student_fee_record f WHERE f.term3_tuition_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'HOSTEL', 3, f.term3_residency_paid,
            N'BANK_TRANSFER', NULL, NULL,
            CONCAT(N'NEFT-ICICI-', RIGHT(CONCAT(N'000000', CAST(f.student_id * 7777 AS NVARCHAR(20))), 6)),
            '2027-01-11T16:30:00'
        FROM finance_schema.student_fee_record f WHERE f.residency_type = N'HOSTELLER' AND f.term3_residency_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'TRANSPORT', 3, f.term3_residency_paid,
            N'UPI', NULL, NULL,
            CONCAT(N'UTR-42893', RIGHT(CONCAT(N'000000', CAST(f.student_id * 8888 AS NVARCHAR(20))), 6)),
            '2027-01-12T17:00:00'
        FROM finance_schema.student_fee_record f WHERE f.residency_type = N'DAY_SCHOLAR' AND f.term3_residency_paid > 0
        UNION ALL
        SELECT f.student_fee_record_id, 1, f.branch_id, 1, f.student_id, f.class_id, f.section_id,
            N'OTHER', NULL, f.other_fee_paid,
            N'CHEQUE', NULL, NULL,
            CONCAT(N'CHQ-', RIGHT(CONCAT(N'000000', CAST(700000 + f.student_id AS NVARCHAR(20))), 6)),
            '2026-06-01T10:00:00'
        FROM finance_schema.student_fee_record f WHERE f.other_fee_paid > 0
    )
    INSERT INTO finance_schema.fee_payment_transaction
    (
        fee_payment_transaction_id, student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id,
        fee_type, term_number, transaction_type, amount,
        receipt_number, payment_method, payment_gateway, gateway_transaction_id, transaction_reference,
        parent_transaction_id, remarks, paid_at, created_by
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY p.student_id, p.term_number, p.fee_type),
        p.student_fee_record_id, 1, p.branch_id, 1, p.student_id, p.class_id, p.section_id,
        p.fee_type, p.term_number, N'PAYMENT', p.amount,
        CONCAT(N'FEE-2026-', RIGHT(CONCAT(N'000000', CAST(ROW_NUMBER() OVER (ORDER BY p.student_id, p.term_number, p.fee_type) AS NVARCHAR(20))), 6)),
        p.payment_method, p.payment_gateway, p.gateway_transaction_id, p.transaction_reference,
        NULL,
        N'Verified fee collection transaction',
        p.paid_at,
        15 -- Chief Financial Officer
    FROM AllPayments p;
    SET IDENTITY_INSERT finance_schema.fee_payment_transaction OFF;

    /* ============================================================
       16. STUDENT ACHIEVEMENTS (40 Honors across sections)
       ============================================================ */
    SET IDENTITY_INSERT student_schema.student_achievement ON;
    INSERT INTO student_schema.student_achievement
      (achievement_id,school_id,branch_id,student_id,achievement_title,category,description,
       achievement_place,achievement_level,date_issued,certificate_url,is_active,created_by)
    SELECT
      st.student_id,
      1,
      st.branch_id,
      st.student_id,
      CASE WHEN st.student_id % 3 = 0 THEN N'National Cyber Olympiad Gold Medal'
           WHEN st.student_id % 3 = 1 THEN N'State Science Model Fair First Prize'
           ELSE N'Inter-School Mathematics Quiz Championship' END,
      CASE WHEN st.student_id % 3 = 0 THEN N'TECHNOLOGY'
           WHEN st.student_id % 3 = 1 THEN N'SCIENCE'
           ELSE N'ACADEMICS' END,
      N'Recognized for exceptional academic and competitive excellence.',
      N'Auditorium',
      N'STATE',
      '2026-08-18',
      CONCAT(N'https://certificates.schoolname.edu/achievements/', st.student_id, N'.pdf'),
      1,
      1
    FROM student_schema.student st
    WHERE st.student_id <= 40;
    SET IDENTITY_INSERT student_schema.student_achievement OFF;

    /* ============================================================
       16.1. STUDENT PERSONALITY DEVELOPMENT (400 Active Students)
       ============================================================ */
    ;WITH ClassTeacherSource AS (
        SELECT
            st.student_id,
            st.school_id,
            st.branch_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            scta.teacher_id AS class_teacher_id,
            t.user_id AS teacher_user_id
        FROM student_schema.student st
        INNER JOIN teachers_schema.section_class_teacher_assignment scta
            ON scta.school_id = st.school_id
           AND scta.branch_id = st.branch_id
           AND scta.academic_year_id = st.academic_year_id
           AND scta.class_id = st.class_id
           AND scta.section_id = st.section_id
           AND scta.is_active = 1
        LEFT JOIN teachers_schema.teacher t
            ON t.teacher_id = scta.teacher_id
        WHERE st.student_status = N'ACTIVE'
    )
    INSERT INTO student_schema.student_personality_development
    (
        school_id, branch_id, academic_year_id, class_id, section_id,
        student_id, class_teacher_id,
        leadership_rating, communication_rating, collaboration_rating,
        responsibility_rating, overall_rating,
        is_active, created_at, created_by, updated_at, updated_by
    )
    SELECT
        cts.school_id, cts.branch_id, cts.academic_year_id, cts.class_id, cts.section_id,
        cts.student_id, cts.class_teacher_id,
        CAST(3.20 + ((cts.student_id * 13) % 17) * 0.10 AS DECIMAL(3, 2)),
        CAST(3.50 + ((cts.student_id * 7) % 15) * 0.10 AS DECIMAL(3, 2)),
        CAST(3.00 + ((cts.student_id * 19) % 19) * 0.10 AS DECIMAL(3, 2)),
        CAST(3.40 + ((cts.student_id * 23) % 15) * 0.10 AS DECIMAL(3, 2)),
        CAST(3.50 + ((cts.student_id * 11) % 14) * 0.10 AS DECIMAL(3, 2)),
        1,
        SYSUTCDATETIME(),
        COALESCE(cts.teacher_user_id, 1),
        SYSUTCDATETIME(),
        COALESCE(cts.teacher_user_id, 1)
    FROM ClassTeacherSource cts;

    /* ============================================================
       16.2. STUDENT PERSONALITY DEVELOPMENT REVIEW (Subject Teachers)
       ============================================================ */
    ;WITH SubjectReviewTemplate AS (
        SELECT * FROM (VALUES
            (N'LEADERSHIP_RATING', N'Mathematics', 5, N'Demonstrates exemplary leadership by leading math olympiad study groups and mentoring peers.'),
            (N'LEADERSHIP_RATING', N'Science',     4, N'Takes initiative as lead investigator during physics and chemistry laboratory investigations.'),
            (N'COMMUNICATION_RATING', N'English',  5, N'Exceptional articulation in persuasive essays, creative literary expression, and elocution.'),
            (N'COMMUNICATION_RATING', N'Social Science', 4, N'Articulates historical causes and modern geopolitical concepts with remarkable clarity.'),
            (N'COLLABORATION_RATING', N'Science',  5, N'Outstanding team player in experimental modules; actively shares bench responsibilities.'),
            (N'RESPONSIBILITY_RATING', N'Mathematics', 5, N'Consistently submits analytical problem sets well ahead of deadlines; high personal discipline.')
        ) AS v(category_type, subject_name, rating_score, review_text)
    ),
    EligibleReviews AS (
        SELECT
            st.student_id,
            st.school_id,
            st.branch_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            tsa.teacher_id,
            tsa.subject_id,
            srt.category_type,
            srt.rating_score,
            srt.review_text,
            t.user_id AS teacher_user_id,
            CAST(DATEADD(DAY, -((st.student_id * 3) % 30), '2026-09-15') AS DATE) AS review_date,
            ROW_NUMBER() OVER (
                PARTITION BY st.student_id, tsa.subject_id, tsa.teacher_id, srt.category_type, CAST(DATEADD(DAY, -((st.student_id * 3) % 30), '2026-09-15') AS DATE)
                ORDER BY tsa.teacher_subject_assignment_id
            ) AS rn
        FROM student_schema.student st
        CROSS JOIN SubjectReviewTemplate srt
        INNER JOIN management_schema.subject sub
            ON sub.subject_name = srt.subject_name AND sub.is_active = 1
        INNER JOIN teachers_schema.teacher_subject_assignment tsa
            ON tsa.subject_id = sub.subject_id
           AND tsa.school_id = st.school_id
           AND tsa.branch_id = st.branch_id
           AND tsa.class_id = st.class_id
           AND tsa.section_id = st.section_id
           AND tsa.is_active = 1
        LEFT JOIN teachers_schema.teacher t ON t.teacher_id = tsa.teacher_id
        WHERE st.student_status = N'ACTIVE'
    )
    INSERT INTO student_schema.student_personality_development_review
    (
        school_id, branch_id, academic_year_id, class_id, section_id,
        student_id, teacher_id, subject_id,
        category_type, rating, review, review_date,
        is_active, created_at, created_by, updated_at, updated_by
    )
    SELECT
        er.school_id, er.branch_id, er.academic_year_id, er.class_id, er.section_id,
        er.student_id, er.teacher_id, er.subject_id,
        er.category_type, er.rating_score, er.review_text, er.review_date,
        1, SYSUTCDATETIME(), COALESCE(er.teacher_user_id, 1), SYSUTCDATETIME(), COALESCE(er.teacher_user_id, 1)
    FROM EligibleReviews er
    WHERE er.rn = 1;

    /* ============================================================
       16.3. STUDENT CULTURAL PARTICIPATION (Dance, Drama, Music, Arts)
       ============================================================ */
    ;WITH CulturalAnnouncements AS (
        SELECT
            announcement_id,
            title AS event_name,
            sub_category,
            start_date AS event_date,
            branch_id,
            ROW_NUMBER() OVER (ORDER BY announcement_id) AS ann_rn
        FROM management_schema.announcement
        WHERE sub_category = N'CULTURAL'
    ),
    StudentCulturalSelection AS (
        SELECT
            st.student_id,
            st.school_id,
            st.branch_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            scta.teacher_id,
            ca.announcement_id,
            ca.event_name,
            ca.event_date,
            ROW_NUMBER() OVER (
                PARTITION BY st.student_id, ca.announcement_id
                ORDER BY st.student_id
            ) AS deduplication_rn
        FROM student_schema.student st
        INNER JOIN teachers_schema.section_class_teacher_assignment scta
            ON scta.section_id = st.section_id AND scta.is_active = 1
        CROSS JOIN CulturalAnnouncements ca
        WHERE st.student_status = N'ACTIVE'
          AND ((st.student_id % 6) + 1) = ca.ann_rn
    )
    INSERT INTO student_schema.student_cultural_participation
    (
        student_id, school_id, branch_id, academic_year_id, class_id, section_id,
        announcement_id, event_name, teacher_id,
        category, role_involvement, result, participation_status, participation_date,
        is_active, created_at, updated_at
    )
    SELECT
        scs.student_id, scs.school_id, scs.branch_id, scs.academic_year_id, scs.class_id, scs.section_id,
        scs.announcement_id, scs.event_name, scs.teacher_id,
        CASE
            WHEN scs.event_name LIKE N'%Dance%' THEN N'PERFORMING_ARTS'
            WHEN scs.event_name LIKE N'%Music%' OR scs.event_name LIKE N'%Choir%' THEN N'MUSIC'
            WHEN scs.event_name LIKE N'%Arts%' OR scs.event_name LIKE N'%Painting%' THEN N'VISUAL_ARTS'
            WHEN scs.event_name LIKE N'%Theatre%' OR scs.event_name LIKE N'%Assembly%' THEN N'PERFORMING_ARTS'
            ELSE N'CULTURAL_ACTIVITIES'
        END,
        CASE (scs.student_id % 4)
            WHEN 0 THEN N'PARTICIPANT'
            WHEN 1 THEN N'VOCALIST'
            WHEN 2 THEN N'DANCER'
            ELSE N'ACTOR'
        END,
        CASE (scs.student_id % 5)
            WHEN 0 THEN N'FIRST_PLACE'
            WHEN 1 THEN N'SECOND_PLACE'
            WHEN 2 THEN N'THIRD_PLACE'
            WHEN 3 THEN N'SPECIAL_MENTION'
            ELSE N'PARTICIPATED'
        END,
        N'PARTICIPATED',
        scs.event_date,
        1,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    FROM StudentCulturalSelection scs
    WHERE scs.deduplication_rn = 1;

    /* ============================================================
       16.4. SPORTS HISTORY (Athletics, Cricket, Basketball, Indoor)
       ============================================================ */
    ;WITH SportsAnnouncements AS (
        SELECT
            announcement_id,
            title,
            start_date,
            ROW_NUMBER() OVER (ORDER BY announcement_id) AS sp_rn
        FROM management_schema.announcement
        WHERE sub_category = N'SPORTS'
    ),
    SportEventsCatalog AS (
        SELECT * FROM (VALUES
            (1, 'Athletics',   'TRACK_AND_FIELD', '100m Sprint Championship', '2026-08-15'),
            (2, 'Athletics',   'TRACK_AND_FIELD', 'Long Jump Championship',    '2026-08-15'),
            (3, 'Cricket',     'TEAM',            'Intra-School Cricket Match','2026-09-05'),
            (4, 'Kabaddi',     'TEAM',            'District Selection Trials', '2026-09-20'),
            (5, 'Basketball',  'TEAM',            'Inter-Section Friendly Match','2026-10-10'),
            (6, 'Badminton',   'INDIVIDUAL',      'Badminton Championship',    '2026-07-20'),
            (7, 'Chess',       'INDOOR',          'Inter-Class Chess Tourney', '2026-08-05'),
            (8, 'Swimming',    'INDIVIDUAL',      'Annual Swimming Gala',      '2026-08-10')
        ) AS v(event_catalog_id, sport_name, sport_category, activity_name, event_date)
    ),
    SportCandidates AS (
        SELECT
            st.student_id,
            st.school_id,
            st.branch_id,
            st.class_id,
            st.section_id,
            sec.sport_name,
            sec.sport_category,
            sec.activity_name,
            CAST(sec.event_date AS DATE) AS activity_date,
            sa.announcement_id,
            CASE (st.student_id % 4)
                WHEN 0 THEN '1st Place'
                WHEN 1 THEN '2nd Place'
                WHEN 2 THEN 'Winner'
                ELSE 'Participated'
            END AS result,
            ROW_NUMBER() OVER (
                PARTITION BY st.student_id, sec.sport_name, CAST(sec.event_date AS DATE)
                ORDER BY st.student_id
            ) AS rn
        FROM student_schema.student st
        CROSS JOIN SportEventsCatalog sec
        LEFT JOIN SportsAnnouncements sa ON sa.sp_rn = ((sec.event_catalog_id % 5) + 1)
        WHERE st.student_status = N'ACTIVE'
          AND ((st.student_id % 8) + 1) = sec.event_catalog_id
    )
    INSERT INTO sports_schema.student_sport_history
    (
        student_id, school_id, branch_id, class_id, section_id,
        sport_name, announcement_id, activity_date, activity_name,
        result, created_at, created_by, updated_at, updated_by,
        sport_category
    )
    SELECT
        sc.student_id, sc.school_id, sc.branch_id, sc.class_id, sc.section_id,
        sc.sport_name, sc.announcement_id, sc.activity_date, sc.activity_name,
        sc.result, SYSUTCDATETIME(), 1, SYSUTCDATETIME(), 1,
        sc.sport_category
    FROM SportCandidates sc
    WHERE sc.rn = 1;

    /* ============================================================
       17. FINAL RIGOROUS VERIFICATION & INTEGRITY CHECKS
       ============================================================ */

    /* 1. Entity Count Sanity Checks */
    IF (SELECT COUNT(*) FROM management_schema.school) <> 1 THROW 51000, 'Expected exactly 1 school.', 1;
    IF (SELECT COUNT(*) FROM management_schema.branch) <> 2 THROW 51000, 'Expected exactly 2 branches.', 1;
    IF (SELECT COUNT(*) FROM management_schema.school_class) <> 20 THROW 51000, 'Expected exactly 20 class instances (1-10 in each branch).', 1;
    IF (SELECT COUNT(*) FROM management_schema.section) <> 40 THROW 51000, 'Expected exactly 40 sections (A & B per class).', 1;
    IF (SELECT COUNT(*) FROM student_schema.student WHERE student_status = N'ACTIVE') <> 400 THROW 51000, 'Expected exactly 400 active students.', 1;
    IF (SELECT COUNT(*) FROM student_schema.student WHERE student_status = N'GRADUATED') <> 20 THROW 51000, 'Expected exactly 20 graduated alumni students in student master.', 1;
    IF (SELECT COUNT(*) FROM teachers_schema.teacher) <> 80 THROW 51000, 'Expected exactly 80 teachers.', 1;
    IF (SELECT COUNT(*) FROM teachers_schema.section_class_teacher_assignment WHERE is_active = 1) <> 40 THROW 51000, 'Expected exactly 40 class-teacher assignments.', 1;
    IF (SELECT COUNT(*) FROM management_schema.timetable) <> 40 THROW 51000, 'Expected exactly 40 timetables.', 1;
    IF (SELECT COUNT(*) FROM management_schema.timetable_period) <> 4800 THROW 51000, 'Expected exactly 4,800 timetable periods (40 sections x 12 days x 10 slots).', 1;

    /* 2. Section Student Distribution (Exactly 10 students per section) */
    IF EXISTS (
      SELECT sec.section_id
      FROM management_schema.section sec
      LEFT JOIN student_schema.student st ON st.section_id = sec.section_id AND st.student_status = N'ACTIVE'
      GROUP BY sec.section_id
      HAVING COUNT(st.student_id) <> 10
    ) THROW 51000, 'Every section must contain exactly 10 active students.', 1;

    /* 3. Class Teacher Uniqueness (Exactly one active class teacher per section, no teacher assigned twice) */
    IF EXISTS (
      SELECT section_id
      FROM teachers_schema.section_class_teacher_assignment
      WHERE is_active = 1
      GROUP BY section_id
      HAVING COUNT(*) <> 1
    ) THROW 51000, 'Section class teacher uniqueness check failed.', 1;

    IF EXISTS (
      SELECT teacher_id
      FROM teachers_schema.section_class_teacher_assignment
      WHERE is_active = 1
      GROUP BY teacher_id
      HAVING COUNT(*) > 1
    ) THROW 51000, 'Teacher class-teacher exclusivity check failed.', 1;

    /* 4. Email Standard Compliance */
    IF EXISTS (
      SELECT 1 FROM security_schema.users
      WHERE user_type = N'STUDENT' AND email_address NOT LIKE N'stu_%@schoolname.edu'
    ) THROW 51000, 'Student email standard validation failed: must match stu_XXXX@schoolname.edu', 1;

    IF EXISTS (
      SELECT 1 FROM security_schema.users
      WHERE user_type = N'TEACHER' AND email_address NOT LIKE N'tch_%@schoolname.edu'
    ) THROW 51000, 'Teacher email standard validation failed: must match tch_XXXX@schoolname.edu', 1;

    IF EXISTS (
      SELECT 1 FROM security_schema.users
      WHERE user_type IN (N'ADMIN', N'PRINCIPAL', N'VICE_PRINCIPAL', N'TRANSPORT', N'FINANCE', N'LIBRARIAN')
        AND email_address NOT LIKE N'mgt_%@schoolname.edu'
    ) THROW 51000, 'Management email standard validation failed: must match mgt_XXXX@schoolname.edu', 1;

    /* 5. User-to-Domain Mapping Consistency */
    IF EXISTS (
      SELECT 1 FROM student_schema.student s
      JOIN security_schema.users u ON u.user_id = s.user_id
      WHERE s.email_address <> u.email_address
    ) THROW 51000, 'Student email address does not match user account email.', 1;

    IF EXISTS (
      SELECT 1 FROM teachers_schema.teacher t
      JOIN security_schema.users u ON u.user_id = t.user_id
      WHERE t.email_address <> u.email_address
    ) THROW 51000, 'Teacher email address does not match user account email.', 1;

    /* 6. Alumni Academic Year Scope Check (Must be before current academic year, is_current = 0) */
    IF EXISTS (
      SELECT 1 FROM student_schema.student s
      JOIN management_schema.academic_year ay ON ay.academic_year_id = s.academic_year_id
      WHERE s.student_status = N'GRADUATED' AND ay.is_current <> 0
    ) THROW 51000, 'Alumni students must belong to a past academic year (is_current = 0).', 1;

    /* 7. Transport Assignment Integrity: Only DAY_SCHOLAR, 0 HOSTELLER */
    IF EXISTS (
      SELECT 1 FROM student_schema.transport_assignment ta
      JOIN student_schema.student st ON st.student_id = ta.student_id
      WHERE st.residency_type = N'HOSTELLER'
    ) THROW 51000, 'Hosteller must not have transport assignment.', 1;

    /* 8. Finance Reconciliation: Payment sum equals total_paid_amount */
    IF EXISTS (
      SELECT f.student_fee_record_id, f.total_paid_amount,
             ISNULL(SUM(CASE WHEN t.transaction_type = N'PAYMENT' THEN t.amount ELSE -t.amount END), 0) txn_sum
      FROM finance_schema.student_fee_record f
      LEFT JOIN finance_schema.fee_payment_transaction t
        ON t.student_fee_record_id = f.student_fee_record_id
      GROUP BY f.student_fee_record_id, f.total_paid_amount
      HAVING ABS(f.total_paid_amount - SUM(CASE
            WHEN t.transaction_type = N'PAYMENT' THEN t.amount
            WHEN t.transaction_type IS NOT NULL THEN -t.amount
            ELSE 0 END)) > 0.01
    ) THROW 51000, 'Finance transaction reconciliation failed.', 1;

    /* 9. Application table coverage: Verify every table in all 8 schemas contains rows */
    DECLARE @ValidationTableName SYSNAME, @ValidationSchemaName SYSNAME, @ValidationSql NVARCHAR(MAX), @ValidationRowCount BIGINT;
    DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name,t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id=t.schema_id
    WHERE CONCAT(s.name, N'.', t.name) IN (
        N'security_schema.users',
        N'security_schema.user_login_attempt',
        N'security_schema.schema_version',
        N'management_schema.school',
        N'management_schema.branch',
        N'management_schema.academic_year',
        N'management_schema.school_class',
        N'management_schema.section',
        N'management_schema.subject',
        N'management_schema.class_subject',
        N'management_schema.exam',
        N'management_schema.exam_schedule',
        N'management_schema.announcement',
        N'management_schema.timetable',
        N'management_schema.timetable_period',
        N'management_schema.holiday',
        N'management_schema.grievance_department',
        N'teachers_schema.teacher',
        N'teachers_schema.section_class_teacher_assignment',
        N'teachers_schema.teacher_subject_assignment',
        N'teachers_schema.assessment',
        N'teachers_schema.homework',
        N'student_schema.student',
        N'student_schema.student_guardian',
        N'student_schema.exam_result',
        N'student_schema.assessment_result',
        N'student_schema.homework_status',
        N'student_schema.student_attendance',
        N'student_schema.student_leave',
        N'student_schema.grievance',
        N'student_schema.grievance_history',
        N'student_schema.transport_assignment',
        N'student_schema.transport_change_request',
        N'student_schema.student_achievement',
        N'library_schema.library_book',
        N'library_schema.library_book_copy',
        N'library_schema.library_book_borrow',
        N'transport_schema.vehicle',
        N'transport_schema.staff',
        N'transport_schema.vehicle_route',
        N'transport_schema.vehicle_route_stop',
        N'transport_schema.trip',
        N'transport_schema.trip_stop',
        N'transport_schema.speed_measurement',
        N'finance_schema.fee_structure_term',
        N'finance_schema.student_fee_record',
        N'finance_schema.fee_payment_transaction',
        N'student_schema.student_leave_status_history',
        N'student_schema.student_exam_performance',
        N'student_schema.student_personality_development',
        N'student_schema.student_personality_development_review',
        N'student_schema.student_cultural_participation',
        N'sports_schema.student_sport_history',
        N'alumni_schema.alumni_profile',
        N'alumni_schema.alumni_story'
    )
    ORDER BY s.name,t.name;

    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @ValidationSchemaName,@ValidationTableName;
    WHILE @@FETCH_STATUS=0
    BEGIN
      SET @ValidationRowCount=0;
      SET @ValidationSql=N'SELECT @RC=COUNT_BIG(*) FROM '+QUOTENAME(@ValidationSchemaName)+N'.'+QUOTENAME(@ValidationTableName)+N';';
      EXEC sys.sp_executesql @ValidationSql,N'@RC BIGINT OUTPUT',@RC=@ValidationRowCount OUTPUT;
      IF @ValidationRowCount=0
      BEGIN
        DECLARE @err_empty NVARCHAR(250) = CONCAT(N'Thinkigen table is empty after seeding: ', @ValidationSchemaName, N'.', @ValidationTableName);
        CLOSE table_cursor; DEALLOCATE table_cursor;
        THROW 51000, @err_empty, 1;
      END;
      FETCH NEXT FROM table_cursor INTO @ValidationSchemaName,@ValidationTableName;
    END;
    CLOSE table_cursor; DEALLOCATE table_cursor;

    PRINT '============================================================';
    PRINT 'THINKIGEN REALISTIC MOCK DATA V23 SEED COMPLETED SUCCESSFULLY';
    PRINT '============================================================';
    PRINT 'School       : 1 (Thinkigen International School)';
    PRINT 'Branches     : 2 (Central Campus, North Campus)';
    PRINT 'Classes      : 20 (Classes 1-10 in Central, Classes 1-10 in North)';
    PRINT 'Sections     : 40 (Sections A and B per class)';
    PRINT 'Students     : 400 Active Students (10 per section; stu_1201..stu_1600@schoolname.edu)';
    PRINT 'Alumni       : 20 Graduated Class 10 Students (stu_1601..stu_1620@schoolname.edu)';
    PRINT 'Teachers     : 80 Teachers (40 Central, 40 North; tch_1201..tch_1280@schoolname.edu)';
    PRINT 'Class Teach  : 40 Dedicated Class Teachers (1 per section)';
    PRINT 'Management   : 21 Staff (Admin, Principal, Transport, Finance, Library; mgt_1201..mgt_1221@schoolname.edu)';
    PRINT 'Guardians    : 800 Parent Records (Father & Mother per active student)';
    PRINT 'Timetable    : 4,800 periods (40 sections x 12 school days x 10 slots, Mon-Sat x 2 weeks from current Monday)';
    PRINT 'Homework     : 2,400 assignments (40 sections x 12 school days x 5 core subjects, 24,000 student submissions)';
    PRINT 'Finance      : Reconciled fees, terms, and transactions across all active students';
    PRINT 'Library      : 100 catalog titles, 400 copies, 80 circulation records (Central & North)';
    PRINT 'Email Standard: STRICTLY stu_XXXX@, tch_XXXX@, mgt_XXXX@schoolname.edu';
    PRINT '============================================================';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
