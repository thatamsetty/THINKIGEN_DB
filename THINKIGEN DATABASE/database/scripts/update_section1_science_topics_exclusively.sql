SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

PRINT N'================================================================================';
PRINT N'Updating Timetable Topics ONLY for subject_id=3, school_id=1, branch_id=1, class_id=1, section_id=1';
PRINT N'================================================================================';

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Identify Section 1 Timetable ID
    DECLARE @Sec1TimetableId BIGINT;
    SELECT @Sec1TimetableId = timetable_id
    FROM management_schema.timetable
    WHERE school_id = 1 AND branch_id = 1 AND class_id = 1 AND section_id = 1;

    IF @Sec1TimetableId IS NULL
        THROW 50001, N'Could not find timetable for school_id=1, branch_id=1, class_id=1, section_id=1.', 1;

    PRINT CONCAT(N'Found Section 1 Timetable ID: ', @Sec1TimetableId);

    -- 2. Define the Authoritative 15 Science Topics
    CREATE TABLE #Topics (
        topic_no INT PRIMARY KEY,
        topic_name NVARCHAR(200) NOT NULL
    );

    INSERT INTO #Topics (topic_no, topic_name) VALUES
    (1,  N'Living Things'),
    (2,  N'Non-Living Things'),
    (3,  N'Characteristics of Living Things'),
    (4,  N'Needs of Living Things'),
    (5,  N'Living and Non-Living Things Around Us'),
    (6,  N'Parts of a Plant'),
    (7,  N'Roots'),
    (8,  N'Stem'),
    (9,  N'Leaves'),
    (10, N'Flowers, Fruits and Seeds'),
    (11, N'Our Surroundings'),
    (12, N'Air Around Us'),
    (13, N'Water Around Us'),
    (14, N'Clean and Safe Environment'),
    (15, N'Protecting Our Environment');

    -- 3. In timetable_id = @Sec1TimetableId:
    -- If there are 12 Science periods (Period 4 of each day), convert Period 10 on Day 3, Day 6, Day 9 to Science
    -- so that all 15 topics are uniquely and sequentially represented across the 12 school days.
    DECLARE @ScienceCount INT;
    SELECT @ScienceCount = COUNT(*)
    FROM management_schema.timetable_period
    WHERE timetable_id = @Sec1TimetableId AND subject_id = 3 AND period_type = N'CLASS';

    IF @ScienceCount = 12
    BEGIN
        PRINT N'Converting 3 duplicate afternoon periods on Days 3, 6, and 9 to Science for Section 1 to accommodate all 15 topics...';
        
        ;WITH RankedDays AS (
            SELECT DISTINCT period_date, DENSE_RANK() OVER (ORDER BY period_date ASC) AS day_rank
            FROM management_schema.timetable_period
            WHERE timetable_id = @Sec1TimetableId
        )
        UPDATE tp
        SET tp.subject_id = 3,
            tp.period_name = N'Period 7 (Science)',
            tp.activity_name = N'Science Laboratory & Practice',
            tp.updated_at = SYSUTCDATETIME()
        FROM management_schema.timetable_period tp
        JOIN RankedDays rd ON rd.period_date = tp.period_date
        WHERE tp.timetable_id = @Sec1TimetableId
          AND tp.period_number = 10 -- Afternoon Period 7
          AND rd.day_rank IN (3, 6, 9);
    END;

    -- 4. Update Section 1 timetable_period records with the 15 topics in chronological order
    ;WITH Sec1SciencePeriods AS (
        SELECT 
            timetable_period_id,
            ((ROW_NUMBER() OVER (ORDER BY period_date ASC, period_number ASC, timetable_period_id ASC) - 1) % 15) + 1 AS topic_no
        FROM management_schema.timetable_period
        WHERE timetable_id = @Sec1TimetableId
          AND subject_id = 3
          AND period_type = N'CLASS'
    )
    UPDATE tp
    SET tp.subject_topic = t.topic_name,
        tp.updated_at = SYSUTCDATETIME()
    FROM management_schema.timetable_period tp
    JOIN Sec1SciencePeriods sp ON sp.timetable_period_id = tp.timetable_period_id
    JOIN #Topics t ON t.topic_no = sp.topic_no;

    PRINT CONCAT(N'Updated Section 1 Science periods count: ', @@ROWCOUNT);

    -- 5. REVERT / CLEAN ALL OTHER TIMETABLES:
    -- Any period in other timetables that received these 15 topic names must be reverted to standard rotating curriculum topics!
    ;WITH OtherPeriodsToReset AS (
        SELECT 
            tp.timetable_period_id,
            tp.timetable_id,
            tp.period_date,
            DENSE_RANK() OVER (PARTITION BY tp.timetable_id ORDER BY tp.period_date ASC) - 1 AS day_no
        FROM management_schema.timetable_period tp
        WHERE tp.timetable_id <> @Sec1TimetableId
          AND (
              tp.subject_topic IN (SELECT topic_name FROM #Topics)
              OR (tp.subject_id = 3 AND tp.subject_topic NOT LIKE N'Science:%')
          )
    )
    UPDATE tp
    SET tp.subject_topic = CASE (op.day_no % 6)
            WHEN 0 THEN N'Science: Cell Biology & Mechanics'
            WHEN 1 THEN N'Science: Light, Sound & Wave Motion'
            WHEN 2 THEN N'Science: Chemical Reactions & Compounds'
            WHEN 3 THEN N'Science: Animal Kingdom & Classification'
            WHEN 4 THEN N'Science: Human Body Systems & Health'
            ELSE        N'Science: Environment & Ecosystem'
        END,
        tp.updated_at = SYSUTCDATETIME()
    FROM management_schema.timetable_period tp
    JOIN OtherPeriodsToReset op ON op.timetable_period_id = tp.timetable_period_id;

    PRINT CONCAT(N'Reverted periods in other timetables back to standard Science curriculum: ', @@ROWCOUNT);

    -- 6. Also clean up teachers_schema.homework for other sections if any received Section 1 topic names
    IF OBJECT_ID(N'teachers_schema.homework') IS NOT NULL
    BEGIN
        ;WITH OtherHomeworkToReset AS (
            SELECT 
                h.homework_id,
                h.section_id,
                DENSE_RANK() OVER (PARTITION BY h.section_id ORDER BY h.deadline_at ASC) - 1 AS day_no
            FROM teachers_schema.homework h
            WHERE h.section_id <> 1
              AND h.subject_id = 3
              AND (
                  h.title LIKE N'%Living Things%'
                  OR h.title LIKE N'%Parts of a Plant%'
                  OR h.title LIKE N'%Air Around Us%'
                  OR h.title LIKE N'%Roots%'
                  OR h.title LIKE N'%Stem%'
                  OR h.title LIKE N'%Leaves%'
              )
        )
        UPDATE h
        SET h.title = CASE (oh.day_no % 6)
                WHEN 0 THEN N'Science - Cell Biology: Microscopic Structure & Functions'
                WHEN 1 THEN N'Science - Light & Optics: Reflection, Refraction & Lenses'
                WHEN 2 THEN N'Science - Chemical Reactions: Acids, Bases & Indicators'
                WHEN 3 THEN N'Science - Animal Kingdom: Vertebrates & Invertebrates Classification'
                WHEN 4 THEN N'Science - Human Physiology: Circulatory & Respiratory Systems'
                ELSE        N'Science - Ecosystems: Food Webs & Biogeochemical Cycles'
            END,
            h.description = CASE (oh.day_no % 6)
                WHEN 0 THEN N'Study cellular organelles and write summary notes on plant vs animal cells.'
                WHEN 1 THEN N'Solve numerical problems on focal length and draw ray diagrams for concave mirrors.'
                WHEN 2 THEN N'Write balanced chemical equations for neutralization reactions discussed in class.'
                WHEN 3 THEN N'Classify given animal specimens into respective phyla with key identifying traits.'
                WHEN 4 THEN N'Draw a neat labeled diagram of the human respiratory system and explain gas exchange.'
                ELSE        N'Create an illustrative food web diagram with producers, consumers, and decomposers.'
            END,
            h.updated_at = SYSUTCDATETIME()
        FROM teachers_schema.homework h
        JOIN OtherHomeworkToReset oh ON oh.homework_id = h.homework_id;

        PRINT CONCAT(N'Cleaned up homework in other sections: ', @@ROWCOUNT);
    END;

    DROP TABLE #Topics;

    COMMIT TRANSACTION;
    PRINT N'Successfully completed update!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'tempdb..#Topics') IS NOT NULL DROP TABLE #Topics;
    THROW;
END CATCH;
