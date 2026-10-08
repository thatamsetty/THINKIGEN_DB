/*
    SSMS update
    1. Rename students whose login is user_id 201 through 206.
    2. Replace Science topics on timetable_id 1, subject_id 3.
       Topics are applied in period date order. If that timetable has more
       than 15 Science periods, the list repeats.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE student_schema.student
       SET first_name = v.first_name,
           last_name = v.last_name,
           updated_at = SYSUTCDATETIME()
    FROM student_schema.student s
    JOIN (VALUES
        (CAST(201 AS BIGINT), N'Karishma',  N'Shaik'),
        (CAST(202 AS BIGINT), N'Dhamodhar', N'Rao'),
        (CAST(203 AS BIGINT), N'Sita',      N'Ram'),
        (CAST(204 AS BIGINT), N'Krupa',     N'Joseph'),
        (CAST(205 AS BIGINT), N'Jeswanth',  N'Reddy'),
        (CAST(206 AS BIGINT), N'Sravan',    N'Kumar')
    ) v(user_id, first_name, last_name)
      ON v.user_id = s.user_id;

    IF @@ROWCOUNT <> 6
        THROW 51000, 'Expected to update exactly 6 students for user_id 201 through 206.', 1;

    ;WITH ScienceTopics AS (
        SELECT *
        FROM (VALUES
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
            (15, N'Protecting Our Environment')
        ) t(topic_no, subject_topic)
    ),
    SciencePeriods AS (
        SELECT
            timetable_period_id,
            ((ROW_NUMBER() OVER (ORDER BY period_date, period_number, timetable_period_id) - 1) % 15) + 1 AS topic_no
        FROM management_schema.timetable_period
        WHERE timetable_id = 1
          AND subject_id = 3
          AND period_type = N'CLASS'
          AND is_active = 1
    )
    UPDATE tp
       SET subject_topic = st.subject_topic,
           updated_at = SYSUTCDATETIME()
    FROM management_schema.timetable_period tp
    JOIN SciencePeriods sp ON sp.timetable_period_id = tp.timetable_period_id
    JOIN ScienceTopics st ON st.topic_no = sp.topic_no;

    IF @@ROWCOUNT = 0
        THROW 51000, 'No active Science periods were found for timetable_id 1 and subject_id 3.', 1;

    COMMIT TRANSACTION;

    SELECT s.user_id, s.student_id, s.first_name, s.last_name
    FROM student_schema.student s
    WHERE s.user_id BETWEEN 201 AND 206
    ORDER BY s.user_id;

    SELECT tp.timetable_period_id, tp.period_date, tp.period_number, tp.subject_topic
    FROM management_schema.timetable_period tp
    WHERE tp.timetable_id = 1
      AND tp.subject_id = 3
      AND tp.period_type = N'CLASS'
      AND tp.is_active = 1
    ORDER BY tp.period_date, tp.period_number;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
