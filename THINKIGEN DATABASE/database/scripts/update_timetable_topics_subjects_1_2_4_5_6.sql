/*
================================================================================
SCRIPT:        update_timetable_topics_subjects_1_2_4_5_6.sql
MODULE:        008_timetable.sql / management_schema.timetable_period & teachers_schema.homework
PURPOSE:       Update timetable period topic names (subject_topic) and associated
               homework records for subjects:
                 - subject_id = 1 : English
                 - subject_id = 2 : Mathematics
                 - subject_id = 4 : Social Science
                 - subject_id = 5 : Computer Science
                 - subject_id = 6 : Physical Education
               
               NOTE: subject_id = 3 (Science) is preserved 100% untouched.

CURRICULUM MAPPING:
  - 5 Subjects
  - 3 Chapters per Subject
  - 3 Topics per Chapter = 9 Topics per Subject (45 Topics total)
  - Assigned sequentially in chronological order (partitioned by timetable & subject)
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================================';
PRINT N'Starting Timetable Topic Names Update for Subjects 1, 2, 4, 5, and 6...';
PRINT N'================================================================================';

BEGIN TRANSACTION;

BEGIN TRY
    -- -------------------------------------------------------------------------
    -- 1. Ensure subject_topic column exists on management_schema.timetable_period
    -- -------------------------------------------------------------------------
    IF COL_LENGTH(N'management_schema.timetable_period', N'subject_topic') IS NULL
    BEGIN
        ALTER TABLE management_schema.timetable_period
            ADD subject_topic NVARCHAR(200) NULL;
        PRINT N'Added missing column subject_topic to management_schema.timetable_period.';
    END;

    -- -------------------------------------------------------------------------
    -- 2. Populate authoritative curriculum topics catalog (9 topics per subject)
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'tempdb..#CurriculumTopics') IS NOT NULL
        DROP TABLE #CurriculumTopics;

    CREATE TABLE #CurriculumTopics (
        subject_id   BIGINT        NOT NULL,
        subject_name NVARCHAR(100) NOT NULL,
        chapter_no   INT           NOT NULL,
        chapter_name NVARCHAR(200) NOT NULL,
        topic_order  INT           NOT NULL, -- Sequential 1..9 per subject
        topic_name   NVARCHAR(200) NOT NULL,
        CONSTRAINT PK_CurriculumTopics PRIMARY KEY (subject_id, topic_order)
    );

    INSERT INTO #CurriculumTopics (subject_id, subject_name, chapter_no, chapter_name, topic_order, topic_name)
    VALUES
        -- =====================================================================
        -- Subject 1: English
        -- =====================================================================
        (1, N'English', 1, N'English Literature & Comprehension', 1, N'Poetry and Prose'),
        (1, N'English', 1, N'English Literature & Comprehension', 2, N'Literary Devices'),
        (1, N'English', 1, N'English Literature & Comprehension', 3, N'Character Analysis'),
        (1, N'English', 2, N'Essay Writing & Creative Composition', 4, N'Essay Structure'),
        (1, N'English', 2, N'Essay Writing & Creative Composition', 5, N'Creative Writing'),
        (1, N'English', 2, N'Essay Writing & Creative Composition', 6, N'Paragraph Development'),
        (1, N'English', 3, N'Grammar: Tenses, Active & Passive Voice', 7, N'Present, Past and Future Tenses'),
        (1, N'English', 3, N'Grammar: Tenses, Active & Passive Voice', 8, N'Active Voice'),
        (1, N'English', 3, N'Grammar: Tenses, Active & Passive Voice', 9, N'Passive Voice'),

        -- =====================================================================
        -- Subject 2: Mathematics
        -- =====================================================================
        (2, N'Mathematics', 1, N'Number Systems & Rational Numbers', 1, N'Natural and Whole Numbers'),
        (2, N'Mathematics', 1, N'Number Systems & Rational Numbers', 2, N'Integers'),
        (2, N'Mathematics', 1, N'Number Systems & Rational Numbers', 3, N'Rational Numbers'),
        (2, N'Mathematics', 2, N'Linear Equations & Algebra', 4, N'Algebraic Expressions'),
        (2, N'Mathematics', 2, N'Linear Equations & Algebra', 5, N'Linear Equations'),
        (2, N'Mathematics', 2, N'Linear Equations & Algebra', 6, N'Polynomials'),
        (2, N'Mathematics', 3, N'Geometry: Triangles & Constructions', 7, N'Types of Triangles'),
        (2, N'Mathematics', 3, N'Geometry: Triangles & Constructions', 8, N'Properties of Triangles'),
        (2, N'Mathematics', 3, N'Geometry: Triangles & Constructions', 9, N'Geometrical Constructions'),

        -- =====================================================================
        -- Subject 4: Social Science
        -- =====================================================================
        (4, N'Social Science', 1, N'Climate & Weather Patterns', 1, N'Climate Zones'),
        (4, N'Social Science', 1, N'Climate & Weather Patterns', 2, N'Weather Patterns'),
        (4, N'Social Science', 1, N'Climate & Weather Patterns', 3, N'Factors Affecting Climate'),
        (4, N'Social Science', 2, N'Democracy & Elections', 4, N'Meaning of Democracy'),
        (4, N'Social Science', 2, N'Democracy & Elections', 5, N'Election Process'),
        (4, N'Social Science', 2, N'Democracy & Elections', 6, N'Role of Citizens'),
        (4, N'Social Science', 3, N'Indian Federal Constitution', 7, N'Constitutional Principles'),
        (4, N'Social Science', 3, N'Indian Federal Constitution', 8, N'Fundamental Rights'),
        (4, N'Social Science', 3, N'Indian Federal Constitution', 9, N'Union and State Government'),

        -- =====================================================================
        -- Subject 5: Computer Science
        -- =====================================================================
        (5, N'Computer Science', 1, N'Algorithms & Python Programming', 1, N'Introduction to Algorithms'),
        (5, N'Computer Science', 1, N'Algorithms & Python Programming', 2, N'Variables and Data Types'),
        (5, N'Computer Science', 1, N'Algorithms & Python Programming', 3, N'Conditional Statements'),
        (5, N'Computer Science', 2, N'Databases & SQL Basics', 4, N'Introduction to Databases'),
        (5, N'Computer Science', 2, N'Databases & SQL Basics', 5, N'SQL SELECT Queries'),
        (5, N'Computer Science', 2, N'Databases & SQL Basics', 6, N'Filtering and Sorting Data'),
        (5, N'Computer Science', 3, N'Cybersecurity & Digital Safety', 7, N'Online Safety'),
        (5, N'Computer Science', 3, N'Cybersecurity & Digital Safety', 8, N'Passwords and Authentication'),
        (5, N'Computer Science', 3, N'Cybersecurity & Digital Safety', 9, N'Recognizing Online Threats'),

        -- =====================================================================
        -- Subject 6: Physical Education
        -- =====================================================================
        (6, N'Physical Education', 1, N'Athletics & Sprint Training', 1, N'Sprint Techniques'),
        (6, N'Physical Education', 1, N'Athletics & Sprint Training', 2, N'Starting and Acceleration'),
        (6, N'Physical Education', 1, N'Athletics & Sprint Training', 3, N'Endurance Training'),
        (6, N'Physical Education', 2, N'Badminton & Racket Sports', 4, N'Racket Grip and Stance'),
        (6, N'Physical Education', 2, N'Badminton & Racket Sports', 5, N'Serving Techniques'),
        (6, N'Physical Education', 2, N'Badminton & Racket Sports', 6, N'Footwork and Court Movement'),
        (6, N'Physical Education', 3, N'Yoga & Flexibility Training', 7, N'Basic Yoga Postures'),
        (6, N'Physical Education', 3, N'Yoga & Flexibility Training', 8, N'Breathing Techniques'),
        (6, N'Physical Education', 3, N'Yoga & Flexibility Training', 9, N'Flexibility Exercises');

    PRINT CONCAT(N'Loaded ', @@ROWCOUNT, N' curriculum topics across subjects 1, 2, 4, 5, and 6.');

    -- -------------------------------------------------------------------------
    -- 3. Update management_schema.timetable_period records chronologically
    --    Assigns topics in 1..9 natural sequence per timetable section
    -- -------------------------------------------------------------------------
    ;WITH RankedPeriods AS (
        SELECT
            tp.timetable_period_id,
            tp.subject_id,
            ((ROW_NUMBER() OVER (
                PARTITION BY tp.timetable_id, tp.subject_id
                ORDER BY tp.period_date ASC, tp.period_number ASC, tp.timetable_period_id ASC
            ) - 1) % 9) + 1 AS topic_order
        FROM management_schema.timetable_period tp
        WHERE tp.period_type = N'CLASS'
          AND tp.subject_id IN (1, 2, 4, 5, 6)
    )
    UPDATE tp
    SET tp.subject_topic = ct.topic_name,
        tp.updated_at = SYSUTCDATETIME()
    FROM management_schema.timetable_period tp
    INNER JOIN RankedPeriods rp
        ON rp.timetable_period_id = tp.timetable_period_id
    INNER JOIN #CurriculumTopics ct
        ON ct.subject_id = rp.subject_id
       AND ct.topic_order = rp.topic_order;

    DECLARE @UpdatedPeriodCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'SUCCESS: Updated subject_topic on ', @UpdatedPeriodCount, N' CLASS timetable periods.');

    -- -------------------------------------------------------------------------
    -- 4. Ensure non-CLASS slots remain NULL for data integrity
    -- -------------------------------------------------------------------------
    UPDATE management_schema.timetable_period
    SET subject_topic = NULL,
        updated_at = SYSUTCDATETIME()
    WHERE period_type <> N'CLASS'
      AND subject_topic IS NOT NULL;

    DECLARE @ClearedNonClassCount INT = @@ROWCOUNT;
    IF @ClearedNonClassCount > 0
        PRINT CONCAT(N'Cleared subject_topic on ', @ClearedNonClassCount, N' non-CLASS periods.');

    -- -------------------------------------------------------------------------
    -- 5. Synchronize teachers_schema.homework if records exist for these subjects
    -- -------------------------------------------------------------------------
    IF OBJECT_ID(N'teachers_schema.homework', N'U') IS NOT NULL
    BEGIN
        ;WITH RankedHomework AS (
            SELECT
                h.homework_id,
                h.subject_id,
                ((ROW_NUMBER() OVER (
                    PARTITION BY h.school_id, h.branch_id, h.academic_year_id, h.class_id, h.section_id, h.subject_id
                    ORDER BY h.assigned_at ASC, h.deadline_at ASC, h.homework_id ASC
                ) - 1) % 9) + 1 AS topic_order
            FROM teachers_schema.homework h
            WHERE h.subject_id IN (1, 2, 4, 5, 6)
        )
        UPDATE h
        SET h.title = CONCAT(s.subject_name, N' - ', ct.topic_name, N' Assignment'),
            h.description = CONCAT(N'Study the concepts covered in "', ct.topic_name, N'". Complete textbook review exercises and notebook practice questions.'),
            h.updated_at = SYSUTCDATETIME()
        FROM teachers_schema.homework h
        INNER JOIN RankedHomework rh
            ON rh.homework_id = h.homework_id
        INNER JOIN #CurriculumTopics ct
            ON ct.subject_id = rh.subject_id
           AND ct.topic_order = rh.topic_order
        INNER JOIN management_schema.subject s
            ON s.subject_id = h.subject_id;

        DECLARE @UpdatedHomeworkCount INT = @@ROWCOUNT;
        PRINT CONCAT(N'SUCCESS: Synchronized ', @UpdatedHomeworkCount, N' teachers_schema.homework titles & descriptions.');
    END;

    COMMIT TRANSACTION;
    PRINT N'================================================================================';
    PRINT N'Transaction committed successfully!';
    PRINT N'================================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    IF OBJECT_ID(N'tempdb..#CurriculumTopics') IS NOT NULL
        DROP TABLE #CurriculumTopics;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT N'ERROR occurred during execution. Transaction rolled back.';
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO

-- -----------------------------------------------------------------------------
-- 6. Audit & Verification Reports
-- -----------------------------------------------------------------------------
PRINT N'';
PRINT N'================================================================================';
PRINT N'VERIFICATION REPORT 1: Period Counts & Distinct Topics per Subject';
PRINT N'================================================================================';

SELECT
    s.subject_id,
    s.subject_code,
    s.subject_name,
    COUNT(tp.timetable_period_id) AS total_class_periods,
    COUNT(tp.subject_topic) AS periods_with_topic,
    COUNT(DISTINCT tp.subject_topic) AS distinct_topics_count,
    MIN(tp.subject_topic) AS sample_topic_min,
    MAX(tp.subject_topic) AS sample_topic_max
FROM management_schema.subject s
LEFT JOIN management_schema.timetable_period tp
    ON tp.subject_id = s.subject_id
   AND tp.period_type = N'CLASS'
WHERE s.subject_id IN (1, 2, 3, 4, 5, 6)
GROUP BY s.subject_id, s.subject_code, s.subject_name
ORDER BY s.subject_id;
GO

PRINT N'';
PRINT N'================================================================================';
PRINT N'VERIFICATION REPORT 2: Distinct Topics in Timetable for Subjects 1, 2, 4, 5, 6';
PRINT N'================================================================================';

SELECT
    tp.subject_id,
    s.subject_name,
    tp.subject_topic,
    COUNT(*) AS period_occurrences
FROM management_schema.timetable_period tp
INNER JOIN management_schema.subject s
    ON s.subject_id = tp.subject_id
WHERE tp.period_type = N'CLASS'
  AND tp.subject_id IN (1, 2, 4, 5, 6)
GROUP BY tp.subject_id, s.subject_name, tp.subject_topic
ORDER BY tp.subject_id, MIN(tp.period_date), MIN(tp.period_number);
GO

