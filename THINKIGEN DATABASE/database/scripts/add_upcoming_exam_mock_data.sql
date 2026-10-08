/*
    Script: add_upcoming_exam_mock_data.sql
    Purpose: Add mock data for upcoming Periodic Assessment 2 starting from tomorrow (2026-10-08)
             specifically for School 1, Branch 1 (Sections 1..20, Classes 1..10).
    Status: PUBLISHED (Exam), SCHEDULED (Exam Schedules).
    Teacher assignment: Strictly 1 specialized teacher per subject.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================================';
PRINT N'CREATING MOCK DATA FOR UPCOMING EXAM STARTING TOMORROW (2026-10-08)';
PRINT N'Target: School 1, Branch 1 (Central Campus, Sections 1..20)';
PRINT N'================================================================================';
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Determine Starting IDs
    DECLARE @MaxExamId BIGINT;
    SELECT @MaxExamId = ISNULL(MAX(exam_id), 0) FROM management_schema.exam;

    DECLARE @MaxScheduleId BIGINT;
    SELECT @MaxScheduleId = ISNULL(MAX(exam_schedule_id), 0) FROM management_schema.exam_schedule;

    PRINT CONCAT(N'Current Max exam_id: ', @MaxExamId, N', Max exam_schedule_id: ', @MaxScheduleId);

    -- Check if this exam already exists for School 1, Branch 1
    IF EXISTS (
        SELECT 1 
        FROM management_schema.exam 
        WHERE school_id = 1 AND branch_id = 1 AND exam_name = N'Periodic Assessment 2 - 2026'
    )
    BEGIN
        PRINT N'Periodic Assessment 2 - 2026 already exists for School 1, Branch 1. Removing previous entries before re-inserting...';
        
        DELETE es
        FROM management_schema.exam_schedule es
        JOIN management_schema.exam e ON e.exam_id = es.exam_id
        WHERE e.school_id = 1 AND e.branch_id = 1 AND e.exam_name = N'Periodic Assessment 2 - 2026';

        DELETE FROM management_schema.exam
        WHERE school_id = 1 AND branch_id = 1 AND exam_name = N'Periodic Assessment 2 - 2026';
    END;

    -- Recalculate max IDs
    SELECT @MaxExamId = ISNULL(MAX(exam_id), 0) FROM management_schema.exam;
    SELECT @MaxScheduleId = ISNULL(MAX(exam_schedule_id), 0) FROM management_schema.exam_schedule;

    -- 2. INSERT INTO management_schema.exam
    -- 20 sections in Branch 1 (Central Campus)
    SET IDENTITY_INSERT management_schema.exam ON;

    INSERT INTO management_schema.exam
      (exam_id, school_id, branch_id, academic_year_id, class_id, section_id,
       exam_name, exam_category, start_date, end_date, status, is_active, created_by)
    SELECT
      @MaxExamId + ROW_NUMBER() OVER (ORDER BY sec.section_id),
      1,                                              -- school_id
      1,                                              -- branch_id
      1,                                              -- academic_year_id
      sec.class_id,
      sec.section_id,
      N'Periodic Assessment 2 - 2026',                -- exam_name
      N'PERIODIC_TEST',                               -- exam_category
      CAST('2026-10-08' AS DATE),                     -- start_date: Tomorrow
      CAST('2026-10-14' AS DATE),                     -- end_date: Next Wednesday
      N'PUBLISHED',                                   -- status: PUBLISHED
      1,                                              -- is_active
      1                                               -- created_by
    FROM management_schema.section sec
    WHERE sec.class_id <= 10;                         -- Branch 1 sections (1..20)

    PRINT CONCAT(N'Inserted exams in management_schema.exam: ', @@ROWCOUNT);
    SET IDENTITY_INSERT management_schema.exam OFF;

    -- 3. INSERT INTO management_schema.exam_schedule
    -- 6 subjects per section across 20 sections = 120 schedules
    SET IDENTITY_INSERT management_schema.exam_schedule ON;

    INSERT INTO management_schema.exam_schedule
      (exam_schedule_id, exam_id, school_id, branch_id, academic_year_id, class_id, section_id,
       subject_id, teacher_id, exam_date, start_time, end_time, max_marks, pass_marks, status, is_active, created_by)
    SELECT
      @MaxScheduleId + ROW_NUMBER() OVER (ORDER BY e.exam_id, s.subject_id),
      e.exam_id,
      e.school_id,
      e.branch_id,
      e.academic_year_id,
      e.class_id,
      e.section_id,
      s.subject_id,
      tsa.teacher_id,
      -- Exam dates starting from tomorrow (2026-10-08), skipping Sunday (2026-10-11):
      CASE s.subject_id
          WHEN 1 THEN CAST('2026-10-08' AS DATE) -- Thursday: English
          WHEN 2 THEN CAST('2026-10-09' AS DATE) -- Friday:   Mathematics
          WHEN 3 THEN CAST('2026-10-10' AS DATE) -- Saturday: Science
          WHEN 4 THEN CAST('2026-10-12' AS DATE) -- Monday:   Social Science (Sunday 11th skipped)
          WHEN 5 THEN CAST('2026-10-13' AS DATE) -- Tuesday:  Computer Science
          WHEN 6 THEN CAST('2026-10-14' AS DATE) -- Wednesday:Physical Education
      END,
      CAST('09:30' AS TIME(0)),
      CAST('11:30' AS TIME(0)),
      50.00,                                         -- max_marks: 50
      20.00,                                         -- pass_marks: 20
      N'SCHEDULED',                                  -- status: SCHEDULED
      1,                                             -- is_active
      1                                              -- created_by
    FROM management_schema.exam e
    CROSS JOIN management_schema.subject s
    JOIN teachers_schema.teacher_subject_assignment tsa
      ON tsa.section_id = e.section_id
     AND tsa.subject_id = s.subject_id
     AND tsa.is_active = 1
    WHERE e.exam_name = N'Periodic Assessment 2 - 2026'
      AND e.school_id = 1
      AND e.branch_id = 1;

    PRINT CONCAT(N'Inserted exam schedules in management_schema.exam_schedule: ', @@ROWCOUNT);
    SET IDENTITY_INSERT management_schema.exam_schedule OFF;

    COMMIT TRANSACTION;
    PRINT N'Successfully created mock data for upcoming exams starting tomorrow!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'management_schema.exam') IS NOT NULL
        BEGIN TRY SET IDENTITY_INSERT management_schema.exam OFF; END TRY BEGIN CATCH END CATCH;
    IF OBJECT_ID(N'management_schema.exam_schedule') IS NOT NULL
        BEGIN TRY SET IDENTITY_INSERT management_schema.exam_schedule OFF; END TRY BEGIN CATCH END CATCH;
    PRINT CONCAT(N'Error: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO
