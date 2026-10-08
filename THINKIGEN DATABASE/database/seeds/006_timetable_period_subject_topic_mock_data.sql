/*
    Script:    006_timetable_period_subject_topic_mock_data.sql
    Module:    008_timetable.sql / management_schema.timetable_period
    Purpose:   Populate realistic, curriculum-aligned lesson topics (subject_topic)
               on existing timetable_period records based on subject_id.

    Features:
    - Zero destructive actions: updates only `subject_topic` and audit `updated_at`.
    - Preserves all existing IDs, timetable structures, dates, times, and teacher assignments.
    - Joins directly with `management_schema.subject` using `subject_id`.
    - Assigns varied, grade-appropriate academic chapter/lesson topics for CLASS periods.
    - Ensures non-CLASS slots (BREAK, LUNCH, ACTIVITY, FREE) remain NULL.
    - Idempotent: can be executed multiple times safely.
*/

SET NOCOUNT ON;
GO

PRINT N'Updating subject_topic for existing management_schema.timetable_period records...';

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Ensure subject_topic column exists
    IF COL_LENGTH(N'management_schema.timetable_period', N'subject_topic') IS NULL
    BEGIN
        ALTER TABLE management_schema.timetable_period
            ADD subject_topic NVARCHAR(200) NULL;
        PRINT N'Added missing subject_topic column to management_schema.timetable_period.';
    END;

    -- 2. Update subject_topic on CLASS periods by joining with management_schema.subject
    UPDATE tp
    SET tp.subject_topic = CASE
        -- =========================================================================
        -- Mathematics
        -- =========================================================================
        WHEN s.subject_code = N'MAT' OR UPPER(s.subject_name) LIKE N'%MATH%'
            THEN CASE (DATEPART(DAY, tp.period_date) + tp.period_number + tp.timetable_id) % 8
                WHEN 0 THEN N'Algebra Ex 3.1 - Linear Equations'
                WHEN 1 THEN N'Algebra Ex 3.2 - Elimination Method'
                WHEN 2 THEN N'Quadratic Polynomials Ex 2.3'
                WHEN 3 THEN N'Arithmetic Progressions Ex 5.2'
                WHEN 4 THEN N'Trigonometric Ratios & Identities'
                WHEN 5 THEN N'Coordinate Geometry & Distance Formula'
                WHEN 6 THEN N'Triangles & Similarity Theorems'
                ELSE N'Surface Areas and Volumes Ex 13.1'
            END

        -- =========================================================================
        -- Science (Physics / Chemistry / Biology)
        -- =========================================================================
        WHEN s.subject_code = N'SCI' OR UPPER(s.subject_name) LIKE N'%SCIENCE%'
            THEN CASE (DATEPART(DAY, tp.period_date) + tp.period_number + tp.timetable_id) % 8
                WHEN 0 THEN N'Plant Cell Biology & Organelles'
                WHEN 1 THEN N'Newton''s Laws of Motion & Momentum'
                WHEN 2 THEN N'Chemical Reactions & Equations'
                WHEN 3 THEN N'Acids, Bases and Salts Ex 2.1'
                WHEN 4 THEN N'Structure of the Atom & Bohr Model'
                WHEN 5 THEN N'Electricity & Ohm''s Law Verification'
                WHEN 6 THEN N'Life Processes: Nutrition & Respiration'
                ELSE N'Light: Reflection & Spherical Mirrors'
            END

        -- =========================================================================
        -- English
        -- =========================================================================
        WHEN s.subject_code = N'ENG' OR UPPER(s.subject_name) LIKE N'%ENGLISH%'
            THEN CASE (DATEPART(DAY, tp.period_date) + tp.period_number + tp.timetable_id) % 7
                WHEN 0 THEN N'Poetry Analysis & Rhyme Schemes'
                WHEN 1 THEN N'Active & Passive Voice Mastery'
                WHEN 2 THEN N'Formal Letter & Analytical Paragraphs'
                WHEN 3 THEN N'Direct & Indirect Speech Practice'
                WHEN 4 THEN N'Prose: The Hundred Dresses Analysis'
                WHEN 5 THEN N'Reading Comprehension & Critical Thinking'
                ELSE N'Grammar: Subject-Verb Concord'
            END

        -- =========================================================================
        -- Social Science / History / Civics / Geography
        -- =========================================================================
        WHEN s.subject_code = N'SST' OR UPPER(s.subject_name) LIKE N'%SOCIAL%'
            THEN CASE (DATEPART(DAY, tp.period_date) + tp.period_number + tp.timetable_id) % 6
                WHEN 0 THEN N'Indian Freedom Struggle (1857-1947)'
                WHEN 1 THEN N'Indian Federal Constitution & Rights'
                WHEN 2 THEN N'Major Soil Types & Agriculture in India'
                WHEN 3 THEN N'Nationalism in Europe & Italian Unification'
                WHEN 4 THEN N'Water Resources & Multipurpose Dams'
                ELSE N'Democratic Politics & Power Sharing'
            END

        -- =========================================================================
        -- Computer Science / Information Technology
        -- =========================================================================
        WHEN s.subject_code IN (N'CSC', N'CS', N'IT') OR UPPER(s.subject_name) LIKE N'%COMPUTER%'
            THEN CASE (DATEPART(DAY, tp.period_date) + tp.period_number + tp.timetable_id) % 5
                WHEN 0 THEN N'Python Functions & Loops'
                WHEN 1 THEN N'Relational Database & SQL Queries'
                WHEN 2 THEN N'Data Structures: Lists & Dictionaries'
                WHEN 3 THEN N'Conditionals & Algorithmic Logic'
                ELSE N'Computer Networks & Cybersecurity'
            END

        -- =========================================================================
        -- Physical Education
        -- =========================================================================
        WHEN s.subject_code = N'PE' OR UPPER(s.subject_name) LIKE N'%PHYSICAL%'
            THEN CASE (DATEPART(DAY, tp.period_date) + tp.period_number + tp.timetable_id) % 4
                WHEN 0 THEN N'Athletics & 100m Sprint Training'
                WHEN 1 THEN N'Yoga Asanas & Team Coordination'
                WHEN 2 THEN N'Basketball Dribbling & Passing Drills'
                ELSE N'Fitness Assessment & Endurance Training'
            END

        -- =========================================================================
        -- Fallback for any other subject
        -- =========================================================================
        ELSE CONCAT(s.subject_name, N' - Chapter Overview & Problem Set')
    END,
    tp.updated_at = SYSUTCDATETIME()
    FROM management_schema.timetable_period tp
    INNER JOIN management_schema.subject s ON s.subject_id = tp.subject_id
    WHERE tp.period_type = N'CLASS'
      AND tp.subject_id IS NOT NULL;

    DECLARE @UpdatedClassCount INT = @@ROWCOUNT;

    -- 3. Explicitly ensure non-CLASS slots remain NULL for data integrity
    UPDATE management_schema.timetable_period
    SET subject_topic = NULL
    WHERE period_type <> N'CLASS'
      AND subject_topic IS NOT NULL;

    COMMIT TRANSACTION;

    PRINT CONCAT(N'SUCCESS: Successfully updated subject_topic on ', @UpdatedClassCount, N' CLASS timetable periods.');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO

-- 4. Verification Report
SELECT
    s.subject_code,
    s.subject_name,
    COUNT(tp.timetable_period_id) AS total_class_periods,
    COUNT(tp.subject_topic) AS periods_with_topic,
    MIN(tp.subject_topic) AS sample_topic_1,
    MAX(tp.subject_topic) AS sample_topic_2
FROM management_schema.timetable_period tp
INNER JOIN management_schema.subject s ON s.subject_id = tp.subject_id
WHERE tp.period_type = N'CLASS'
GROUP BY s.subject_code, s.subject_name
ORDER BY s.subject_code;
GO
