/*
================================================================================
SCRIPT:        014_timetable_section1_two_weeks_mock_data.sql
MODULE:        008_timetable.sql / management_schema.timetable & timetable_period
PURPOSE:       Replace existing mock data for timetable creation for:
               - school_id  = 1
               - branch_id  = 1
               - class_id   = 1 (Class 8 - Central)
               - section_id = 1 (Section A)
               - subject_id = 3 (Science) mapped strictly to MongoDB syllabus topics
DATE RANGE:    From TODAY (GETDATE()) for UP TO 2 WEEKS (12 active school days)
SYLLABUS:      Matches MongoDB document ObjectId('6aac66594e7af2080aa3fcc1')
               * sci_ch_001 (The Living World)        -> Topics 1.1 to 1.5
               * sci_ch_002 (Plants Around Us)        -> Topics 2.1 to 2.5
               * sci_ch_003 (Animals and Habitats)    -> Topics 3.1 to 3.5
OVERALL DATES: Replaces dates across ALL timetable-related tables in the database:
               1. management_schema.timetable
               2. management_schema.timetable_period
               3. student_schema.student_attendance
================================================================================
*/

USE [ERP_TEST];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================================';
PRINT N'Seeding 2-week timetable mock data with MongoDB syllabus topics & overall dates...';
PRINT N'================================================================================';

BEGIN TRANSACTION;

BEGIN TRY
    DECLARE @SchoolId  BIGINT = 1;
    DECLARE @BranchId  BIGINT = 1;
    DECLARE @ClassId   BIGINT = 1;
    DECLARE @SectionId BIGINT = 1;
    DECLARE @Today     DATE   = CAST(GETDATE() AS DATE);

    DECLARE @AcademicYearId BIGINT;
    SELECT TOP 1 @AcademicYearId = academic_year_id
    FROM management_schema.academic_year
    WHERE school_id = @SchoolId AND is_current = 1 AND is_active = 1
    ORDER BY academic_year_id DESC;

    IF @AcademicYearId IS NULL
    BEGIN
        SELECT TOP 1 @AcademicYearId = academic_year_id
        FROM management_schema.academic_year
        WHERE school_id = @SchoolId AND is_active = 1
        ORDER BY academic_year_id DESC;
    END;

    IF @AcademicYearId IS NULL
        THROW 50005, N'No active academic year found for school_id = 1.', 1;

    DECLARE @AdminUserId BIGINT;
    SELECT TOP 1 @AdminUserId = user_id
    FROM security_schema.users
    WHERE user_type = N'ADMIN' AND is_active = 1
    ORDER BY user_id ASC;

    IF @AdminUserId IS NULL
        SELECT TOP 1 @AdminUserId = user_id FROM security_schema.users WHERE is_active = 1 ORDER BY user_id ASC;
    IF @AdminUserId IS NULL SET @AdminUserId = 1;

    -- Resolve Teachers for Section 1
    DECLARE @Tchr_English BIGINT, @Tchr_Math BIGINT, @Tchr_Science BIGINT, @Tchr_SST BIGINT, @Tchr_CSC BIGINT, @Tchr_PE BIGINT;

    SELECT @Tchr_English = teacher_id FROM teachers_schema.teacher_subject_assignment WHERE section_id = @SectionId AND subject_id = 1 AND is_active = 1;
    SELECT @Tchr_Math    = teacher_id FROM teachers_schema.teacher_subject_assignment WHERE section_id = @SectionId AND subject_id = 2 AND is_active = 1;
    SELECT @Tchr_Science = teacher_id FROM teachers_schema.teacher_subject_assignment WHERE section_id = @SectionId AND subject_id = 3 AND is_active = 1;
    SELECT @Tchr_SST     = teacher_id FROM teachers_schema.teacher_subject_assignment WHERE section_id = @SectionId AND subject_id = 4 AND is_active = 1;
    SELECT @Tchr_CSC     = teacher_id FROM teachers_schema.teacher_subject_assignment WHERE section_id = @SectionId AND subject_id = 5 AND is_active = 1;
    SELECT @Tchr_PE      = teacher_id FROM teachers_schema.teacher_subject_assignment WHERE section_id = @SectionId AND subject_id = 6 AND is_active = 1;

    IF @Tchr_Science IS NULL
        SELECT TOP 1 @Tchr_Science = teacher_id FROM teachers_schema.teacher WHERE school_id = @SchoolId AND branch_id = @BranchId AND is_active = 1 ORDER BY teacher_id ASC;
    IF @Tchr_English IS NULL SET @Tchr_English = @Tchr_Science;
    IF @Tchr_CSC IS NULL     SET @Tchr_CSC     = @Tchr_Science;

    IF @Tchr_Math IS NULL
        SELECT TOP 1 @Tchr_Math = teacher_id FROM teachers_schema.teacher WHERE school_id = @SchoolId AND branch_id = @BranchId AND teacher_id <> @Tchr_Science AND is_active = 1 ORDER BY teacher_id ASC;
    IF @Tchr_Math IS NULL    SET @Tchr_Math    = @Tchr_Science;
    IF @Tchr_SST IS NULL     SET @Tchr_SST     = @Tchr_Math;
    IF @Tchr_PE IS NULL      SET @Tchr_PE      = @Tchr_Math;

    -- Fail-safe fallbacks: ensure teacher IDs are never NULL
    IF @Tchr_Science IS NULL SET @Tchr_Science = 3;
    IF @Tchr_Math    IS NULL SET @Tchr_Math    = 2;
    IF @Tchr_English IS NULL SET @Tchr_English = 1;
    IF @Tchr_SST     IS NULL SET @Tchr_SST     = 4;
    IF @Tchr_CSC     IS NULL SET @Tchr_CSC     = 5;
    IF @Tchr_PE      IS NULL SET @Tchr_PE      = 6;

    -- -------------------------------------------------------------------------
    -- 1. Dynamic 2-Week Calendar Starting from TODAY (skipping Sundays)
    -- -------------------------------------------------------------------------
    CREATE TABLE #Cal (day_index INT PRIMARY KEY, period_date DATE NOT NULL);

    ;WITH Numbers AS
    (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
        SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL
        SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL
        SELECT 20
    ),
    CandidateDates AS (SELECT DATEADD(DAY, n, @Today) AS cal_date FROM Numbers),
    FilteredDays AS
    (
        SELECT cal_date, ROW_NUMBER() OVER (ORDER BY cal_date ASC) AS day_index
        FROM CandidateDates
        WHERE (DATEDIFF(DAY, '1900-01-07', cal_date) % 7 + 7) % 7 <> 0
    )
    INSERT INTO #Cal (day_index, period_date)
    SELECT day_index, cal_date FROM FilteredDays WHERE day_index <= 12;

    DECLARE @MinDate DATE = (SELECT MIN(period_date) FROM #Cal);
    DECLARE @MaxDate DATE = (SELECT MAX(period_date) FROM #Cal);

    PRINT CONCAT(N'2-Week Timetable Range: ', CONVERT(VARCHAR(10), @MinDate, 120), N' to ', CONVERT(VARCHAR(10), @MaxDate, 120), N' (12 School Days from Today)');

    -- -------------------------------------------------------------------------
    -- 2. Timetable Header for Section 1
    -- -------------------------------------------------------------------------
    DECLARE @TimetableId BIGINT;
    SELECT @TimetableId = timetable_id
    FROM management_schema.timetable
    WHERE school_id = @SchoolId AND branch_id = @BranchId AND academic_year_id = @AcademicYearId AND class_id = @ClassId AND section_id = @SectionId;

    DECLARE @Title NVARCHAR(150) = CONCAT(N'2026-2027 Class 8 - Central - Section A Timetable (', CONVERT(VARCHAR(10), @MinDate, 120), N' to ', CONVERT(VARCHAR(10), @MaxDate, 120), N')');

    IF @TimetableId IS NULL
    BEGIN
        INSERT INTO management_schema.timetable
            (school_id, branch_id, academic_year_id, class_id, section_id,
             timetable_name, status, is_active, created_at, created_by, updated_at, updated_by)
        VALUES
            (@SchoolId, @BranchId, @AcademicYearId, @ClassId, @SectionId,
             @Title, N'ACTIVE', 1, SYSUTCDATETIME(), @AdminUserId, SYSUTCDATETIME(), @AdminUserId);
        SET @TimetableId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE management_schema.timetable
        SET status = N'ACTIVE', is_active = 1, timetable_name = @Title,
            updated_at = SYSUTCDATETIME(), updated_by = @AdminUserId
        WHERE timetable_id = @TimetableId;
    END;

    -- Clean referencing attendance & existing periods for Section 1
    DELETE FROM student_schema.student_attendance
    WHERE timetable_id = @TimetableId
       OR timetable_period_id IN (
           SELECT timetable_period_id FROM management_schema.timetable_period WHERE timetable_id = @TimetableId
       );

    DELETE FROM management_schema.timetable_period WHERE timetable_id = @TimetableId;

    -- -------------------------------------------------------------------------
    -- 3. Grid for Section 1 (84 Periods, 15 MongoDB Syllabus Topics for Science)
    -- -------------------------------------------------------------------------
    CREATE TABLE #Grid
    (
        day_index     INT NOT NULL,
        period_number TINYINT NOT NULL,
        period_name   NVARCHAR(50) NOT NULL,
        start_time    TIME(0) NOT NULL,
        end_time      TIME(0) NOT NULL,
        period_type   NVARCHAR(30) NOT NULL,
        subject_id    BIGINT NOT NULL,
        teacher_id    BIGINT NOT NULL,
        subject_topic NVARCHAR(200) NOT NULL,
        room_name     NVARCHAR(150) NOT NULL,
        activity_name NVARCHAR(150) NOT NULL
    );

    -- WEEK 1
    INSERT INTO #Grid VALUES
    (1, 1, N'Period 1', '08:30', '09:15', N'CLASS', 3, @Tchr_Science, N'Living Things', N'Science Lab 1', N'Identifying Living Things & Characteristics of Life'),
    (1, 2, N'Period 2', '09:15', '10:00', N'CLASS', 2, @Tchr_Math,    N'Linear Equations in Two Variables - Graphical Method', N'Room-101', N'Theory Lecture & Problem Solving'),
    (1, 3, N'Period 3', '10:15', '11:00', N'CLASS', 1, @Tchr_English, N'Poetry Analysis & Rhyme Scheme Exploration', N'Room-101', N'Poem Recitation & Textual Discussion'),
    (1, 4, N'Period 4', '11:00', '11:45', N'CLASS', 4, @Tchr_SST,     N'Indian Freedom Struggle (1857-1947) - First War', N'Room-101', N'Historical Timeline & Primary Source Review'),
    (1, 5, N'Period 5', '12:30', '13:15', N'CLASS', 5, @Tchr_CSC,     N'Python Programming: Loops & Conditional Logic', N'Computer Lab 1', N'Hands-on Code Practice & Debugging'),
    (1, 6, N'Period 6', '13:15', '14:00', N'CLASS', 2, @Tchr_Math,    N'Linear Equations Elimination Method Practice', N'Room-101', N'Problem Solving on Board'),
    (1, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Athletics & Track Sprint Coordination', N'Sports Ground', N'Sprint Drills & Physical Conditioning'),

    (2, 1, N'Period 1', '08:30', '09:15', N'CLASS', 2, @Tchr_Math,    N'Algebraic Identities: (a+b)^2 and (a-b)^2', N'Room-101', N'Derivation & Algebraic Expansion Drills'),
    (2, 2, N'Period 2', '09:15', '10:00', N'CLASS', 1, @Tchr_English, N'Active and Passive Voice Transformation Rules', N'Room-101', N'Grammar Practice & Sentence Conversion'),
    (2, 3, N'Period 3', '10:15', '11:00', N'CLASS', 5, @Tchr_CSC,     N'Relational Database & SQL SELECT Syntax', N'Computer Lab 1', N'Database Table Queries & Hands-on Lab'),
    (2, 4, N'Period 4', '11:00', '11:45', N'CLASS', 3, @Tchr_Science, N'Non-Living Things', N'Science Lab 1', N'Differentiating Between Living and Non-Living Objects'),
    (2, 5, N'Period 5', '12:30', '13:15', N'CLASS', 4, @Tchr_SST,     N'Indian Constitution & Fundamental Rights Overview', N'Room-101', N'Civics Case Study & Group Discussion'),
    (2, 6, N'Period 6', '13:15', '14:00', N'CLASS', 2, @Tchr_Math,    N'Polynomials: Factoring Quadratic Expressions', N'Room-101', N'Step-by-Step Problem Solving on Board'),
    (2, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Yoga Asanas, Breathing & Core Balance', N'Indoor Gymnasium', N'Flexibility & Mindfulness Exercises'),

    (3, 1, N'Period 1', '08:30', '09:15', N'CLASS', 4, @Tchr_SST,     N'Major Soil Types of India & Agricultural Impact', N'Room-101', N'Geographical Map Work & Crop Mapping'),
    (3, 2, N'Period 2', '09:15', '10:00', N'CLASS', 3, @Tchr_Science, N'Characteristics of Living Things', N'Science Lab 1', N'Growth, Movement, Breathing and Feeding in Living Beings'),
    (3, 3, N'Period 3', '10:15', '11:00', N'CLASS', 2, @Tchr_Math,    N'Coordinate Geometry: Plotting on Cartesian Plane', N'Room-101', N'Graph Paper Plotting Exercises'),
    (3, 4, N'Period 4', '11:00', '11:45', N'CLASS', 1, @Tchr_English, N'Formal Letter Writing - Editorial & Inquiries', N'Room-101', N'Composition Structure & Peer Drafting'),
    (3, 5, N'Period 5', '12:30', '13:15', N'CLASS', 5, @Tchr_CSC,     N'Python Data Structures: Working with Lists', N'Computer Lab 1', N'Algorithm Design & List Methods'),
    (3, 6, N'Period 6', '13:15', '14:00', N'CLASS', 3, @Tchr_Science, N'Needs of Living Things', N'Science Lab 1', N'Exploring Food, Water, Air and Shelter as Essential Needs'),
    (3, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Football Passing Drills & Field Positioning', N'Sports Ground', N'Ball Control & Team Coordination'),

    (4, 1, N'Period 1', '08:30', '09:15', N'CLASS', 1, @Tchr_English, N'Reading Comprehension: Unseen Prose Analysis', N'Room-101', N'Critical Text Reading & Vocabulary Expansion'),
    (4, 2, N'Period 2', '09:15', '10:00', N'CLASS', 2, @Tchr_Math,    N'Arithmetic Progressions: Finding the Nth Term', N'Room-101', N'Formula Application & Number Series'),
    (4, 3, N'Period 3', '10:15', '11:00', N'CLASS', 4, @Tchr_SST,     N'The Revolt of 1857: Key Centres & Leaders', N'Room-101', N'Audio-Visual Documentary Review'),
    (4, 4, N'Period 4', '11:00', '11:45', N'CLASS', 5, @Tchr_CSC,     N'SQL Clauses: WHERE, ORDER BY, and LIMIT', N'Computer Lab 1', N'Database Query Optimization Lab'),
    (4, 5, N'Period 5', '12:30', '13:15', N'CLASS', 3, @Tchr_Science, N'Living and Non-Living Things Around Us', N'Science Lab 1', N'Classifying Natural vs Man-made Objects in Surroundings'),
    (4, 6, N'Period 6', '13:15', '14:00', N'CLASS', 2, @Tchr_Math,    N'Sum of First N Terms in Arithmetic Progression', N'Room-101', N'Equation Derivations & Board Exercises'),
    (4, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Basketball Dribbling & Free Throw Technique', N'Basketball Court', N'Target Shooting & Agility Drills'),

    (5, 1, N'Period 1', '08:30', '09:15', N'CLASS', 3, @Tchr_Science, N'Parts of a Plant', N'Science Lab 1', N'Observing Plant Structure: Root, Stem, Leaf, Flower, Fruit'),
    (5, 2, N'Period 2', '09:15', '10:00', N'CLASS', 2, @Tchr_Math,    N'Surface Areas & Volumes of Cubes and Cuboids', N'Room-101', N'3D Geometric Solids & Measurement Problems'),
    (5, 3, N'Period 3', '10:15', '11:00', N'CLASS', 1, @Tchr_English, N'Direct and Indirect Speech Conversion Rules', N'Room-101', N'Dialogue Transcription & Grammar Worksheet'),
    (5, 4, N'Period 4', '11:00', '11:45', N'CLASS', 4, @Tchr_SST,     N'Judiciary System in India - Supreme & High Courts', N'Room-101', N'Mock Parliament & Judicial Flowcharting'),
    (5, 5, N'Period 5', '12:30', '13:15', N'CLASS', 5, @Tchr_CSC,     N'Python Dictionary Manipulation & Key-Value Pairs', N'Computer Lab 1', N'Student Record Dictionary Project'),
    (5, 6, N'Period 6', '13:15', '14:00', N'CLASS', 2, @Tchr_Math,    N'Word Problems on Speed, Distance & Time Equations', N'Room-101', N'Applied Algebraic Problem Solving'),
    (5, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Cricket Fielding Drills & Wicket Keeping Practice', N'Sports Ground', N'Reflex Catching & Team Match'),

    (6, 1, N'Period 1', '08:30', '09:15', N'CLASS', 2, @Tchr_Math,    N'Triangles: Congruence Criteria SAS and SSS', N'Room-101', N'Geometric Theorem Proofs & Compass Construction'),
    (6, 2, N'Period 2', '09:15', '10:00', N'CLASS', 1, @Tchr_English, N'Essay Writing: Descriptive Narrative Composition', N'Room-101', N'Essay Drafting & Paragraph Coherence'),
    (6, 3, N'Period 3', '10:15', '11:00', N'CLASS', 3, @Tchr_Science, N'Roots', N'Science Lab 1', N'Functions of Roots: Absorption of Water & Anchorage'),
    (6, 4, N'Period 4', '11:00', '11:45', N'CLASS', 4, @Tchr_SST,     N'Minerals and Power Resources - Conservation Methods', N'Room-101', N'Resource Mapping & Sustainability Seminar'),
    (6, 5, N'Period 5', '12:30', '13:15', N'CLASS', 5, @Tchr_CSC,     N'Cyber Safety, Ethics & Safe Browsing Standards', N'Computer Lab 1', N'Digital Security Presentation & Quiz'),
    (6, 6, N'Period 6', '13:15', '14:00', N'CLASS', 3, @Tchr_Science, N'Stem', N'Science Lab 1', N'Stem Functions: Support & Transport of Water and Nutrients'),
    (6, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Inter-House Team Games & Sportsmanship Exercises', N'Sports Ground', N'Friendly Tournament & Team Debrief');

    -- WEEK 2
    INSERT INTO #Grid VALUES
    (7, 1, N'Period 1', '08:30', '09:15', N'CLASS', 3, @Tchr_Science, N'Leaves', N'Science Lab 1', N'Leaf Functions: Food Preparation (Photosynthesis) & Breathing'),
    (7, 2, N'Period 2', '09:15', '10:00', N'CLASS', 2, @Tchr_Math,    N'Linear Inequalities & Number Line Representation', N'Room-101', N'Board Demonstration & Worksheet Practice'),
    (7, 3, N'Period 3', '10:15', '11:00', N'CLASS', 1, @Tchr_English, N'Short Story Analysis: Character Motivation & Plot', N'Room-101', N'Literary Appreciation & Critical Writing'),
    (7, 4, N'Period 4', '11:00', '11:45', N'CLASS', 4, @Tchr_SST,     N'Colonialism and Tribal Societies - Birsa Munda Movement', N'Room-101', N'Historical Source Analysis & Lecture'),
    (7, 5, N'Period 5', '12:30', '13:15', N'CLASS', 5, @Tchr_CSC,     N'Python Functions: Defining def & Return Values', N'Computer Lab 1', N'Modular Function Coding & Exercises'),
    (7, 6, N'Period 6', '13:15', '14:00', N'CLASS', 2, @Tchr_Math,    N'Inequalities Word Problems & Range Solving', N'Room-101', N'Analytical Mathematics Drills'),
    (7, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'High Jump & Long Jump Technique Training', N'Sports Ground', N'Approach Run, Takeoff & Landing Form'),

    (8, 1, N'Period 1', '08:30', '09:15', N'CLASS', 2, @Tchr_Math,    N'Quadratic Equations: Factorization & Roots Solution', N'Room-101', N'Algebraic Equation Solving & Homework Review'),
    (8, 2, N'Period 2', '09:15', '10:00', N'CLASS', 1, @Tchr_English, N'Subject-Verb Concord: Singular vs Plural Agreements', N'Room-101', N'Error Spotting & Grammar Drills'),
    (8, 3, N'Period 3', '10:15', '11:00', N'CLASS', 5, @Tchr_CSC,     N'SQL Aggregate Functions: COUNT, SUM, AVG, MAX', N'Computer Lab 1', N'Database Aggregation Queries Lab'),
    (8, 4, N'Period 4', '11:00', '11:45', N'CLASS', 3, @Tchr_Science, N'Flowers, Fruits and Seeds', N'Science Lab 1', N'Role of Flowers, Fruit Formation and Seed Germination'),
    (8, 5, N'Period 5', '12:30', '13:15', N'CLASS', 4, @Tchr_SST,     N'Understanding Secularism in the Indian Context', N'Room-101', N'Constitutional Articles Review & Discussion'),
    (8, 6, N'Period 6', '13:15', '14:00', N'CLASS', 2, @Tchr_Math,    N'Pythagoras Theorem & Practical Right Triangle Problems', N'Room-101', N'Proof Demonstration & Geometric Calculations'),
    (8, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Volleyball Underarm Pass & Serving Mechanics', N'Volleyball Court', N'Ball Control Rallies & Court Rotation'),

    (9, 1, N'Period 1', '08:30', '09:15', N'CLASS', 4, @Tchr_SST,     N'Industries: Classification, Raw Materials & Locations', N'Room-101', N'Industrial Cluster Mapping of India'),
    (9, 2, N'Period 2', '09:15', '10:00', N'CLASS', 3, @Tchr_Science, N'Our Surroundings', N'Science Lab 1', N'Components of the Environment and Importance of Clean Surroundings'),
    (9, 3, N'Period 3', '10:15', '11:00', N'CLASS', 2, @Tchr_Math,    N'Data Handling: Organizing Frequency Distribution Tables', N'Room-101', N'Bar Graph & Histogram Drawing'),
    (9, 4, N'Period 4', '11:00', '11:45', N'CLASS', 1, @Tchr_English, N'Notice Writing: Official School Notices & Circulars', N'Room-101', N'Box Format Construction & Peer Review'),
    (9, 5, N'Period 5', '12:30', '13:15', N'CLASS', 5, @Tchr_CSC,     N'Python Strings: Slicing, Concatenation & Built-ins', N'Computer Lab 1', N'Text Processing Programs Development'),
    (9, 6, N'Period 6', '13:15', '14:00', N'CLASS', 3, @Tchr_Science, N'Air Around Us', N'Science Lab 1', N'Properties and Importance of Air for Living Things'),
    (9, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Badminton Footwork, Grip & Overhead Clear', N'Badminton Court', N'Singles Rallies & Shadow Badminton Drills'),

    (10, 1, N'Period 1', '08:30', '09:15', N'CLASS', 1, @Tchr_English, N'Reported Speech: Changing Questions and Imperatives', N'Room-101', N'Dialogue to Report Conversion Practice'),
    (10, 2, N'Period 2', '09:15', '10:00', N'CLASS', 2, @Tchr_Math,    N'Probability Basics: Sample Space & Single Event Odds', N'Room-101', N'Dice and Coin Experiment Calculations'),
    (10, 3, N'Period 3', '10:15', '11:00', N'CLASS', 4, @Tchr_SST,     N'Parliament and the Making of Laws in Democracy', N'Room-101', N'Bill to Act Process Simulation'),
    (10, 4, N'Period 4', '11:00', '11:45', N'CLASS', 5, @Tchr_CSC,     N'Database Primary Keys & Foreign Keys in SQL', N'Computer Lab 1', N'Schema Table Design & Constraints Practice'),
    (10, 5, N'Period 5', '12:30', '13:15', N'CLASS', 3, @Tchr_Science, N'Water Around Us', N'Science Lab 1', N'Sources, Uses and Conservation of Clean Water'),
    (10, 6, N'Period 6', '13:15', '14:00', N'CLASS', 2, @Tchr_Math,    N'Compound Events & Probability Sample Sets', N'Room-101', N'Step-by-Step Probability Solutions'),
    (10, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Table Tennis Serve, Topspin & Forehand Drive', N'Indoor Gymnasium', N'Multi-ball Practice & Table Tennis Drills'),

    (11, 1, N'Period 1', '08:30', '09:15', N'CLASS', 3, @Tchr_Science, N'Clean and Safe Environment', N'Science Lab 1', N'Waste Disposal, Cleanliness and Healthy Living Practices'),
    (11, 2, N'Period 2', '09:15', '10:00', N'CLASS', 2, @Tchr_Math,    N'Circles: Circumference & Area Formula Applications', N'Room-101', N'Sector and Segment Calculations'),
    (11, 3, N'Period 3', '10:15', '11:00', N'CLASS', 1, @Tchr_English, N'Idioms & Phrasal Verbs in Everyday Communication', N'Room-101', N'Contextual Sentence Making & Quiz'),
    (11, 4, N'Period 4', '11:00', '11:45', N'CLASS', 4, @Tchr_SST,     N'Human Resources: Population Density & Distribution', N'Room-101', N'Demographic Pyramids & Statistical Graphs'),
    (11, 5, N'Period 5', '12:30', '13:15', N'CLASS', 5, @Tchr_CSC,     N'Python Project: Mini Calculator with User Input', N'Computer Lab 1', N'End-to-End Programming Assignment'),
    (11, 6, N'Period 6', '13:15', '14:00', N'CLASS', 2, @Tchr_Math,    N'Mensuration: Cylinder Surface Area & Volume Exercises', N'Room-101', N'Problem Solving & Formula Application'),
    (11, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Kabaddi Stances, Raiding Strategy & Cant Practice', N'Sports Ground', N'Raiding Drills & Team Defense Tactics'),

    (12, 1, N'Period 1', '08:30', '09:15', N'CLASS', 2, @Tchr_Math,    N'Exponents and Powers: Laws of Exponents & Standard Form', N'Room-101', N'Scientific Notation & Numerical Drills'),
    (12, 2, N'Period 2', '09:15', '10:00', N'CLASS', 1, @Tchr_English, N'Debate & Public Speaking: Persuasive Arguments', N'Room-101', N'Classroom Debate on Technology in Learning'),
    (12, 3, N'Period 3', '10:15', '11:00', N'CLASS', 3, @Tchr_Science, N'Protecting Our Environment', N'Science Lab 1', N'Planting Trees, Reducing Plastic and Protecting Nature'),
    (12, 4, N'Period 4', '11:00', '11:45', N'CLASS', 4, @Tchr_SST,     N'Marginalisation & Social Justice in Contemporary India', N'Room-101', N'Case Studies Review & Analytical Essay'),
    (12, 5, N'Period 5', '12:30', '13:15', N'CLASS', 5, @Tchr_CSC,     N'Database Mini-Project: Student Marks Records', N'Computer Lab 1', N'SQL Database Project Evaluation'),
    (12, 6, N'Period 6', '13:15', '14:00', N'CLASS', 1, @Tchr_English, N'Creative Writing: Environmental Narrative Composition', N'Room-101', N'Story Writing & Class Presentation'),
    (12, 7, N'Period 7', '14:15', '15:00', N'CLASS', 6, @Tchr_PE,      N'Fortnightly Physical Fitness Test & Shuttle Run', N'Sports Ground', N'Endurance Assessment & Fitness Tracking');

    -- Insert Section 1 Periods
    INSERT INTO management_schema.timetable_period
    (
        timetable_id, period_date, period_number, period_name, start_time, end_time,
        period_type, subject_id, subject_topic, teacher_id, room_name, activity_name,
        is_active, created_at, created_by, updated_at, updated_by
    )
    SELECT
        @TimetableId, c.period_date, g.period_number, g.period_name, g.start_time, g.end_time,
        g.period_type, g.subject_id, g.subject_topic, g.teacher_id, g.room_name, g.activity_name,
        1, SYSUTCDATETIME(), @AdminUserId, SYSUTCDATETIME(), @AdminUserId
    FROM #Grid g
    JOIN #Cal c ON c.day_index = g.day_index
    ORDER BY c.period_date, g.period_number;

    -- Synchronize attendance for Section 1
    INSERT INTO student_schema.student_attendance
    (
        school_id, branch_id, academic_year_id, class_id, section_id, student_id,
        timetable_id, timetable_period_id, attendance_date, subject_id, teacher_id,
        period_number, start_time, end_time, attendance_status, recorded_at, recorded_by,
        is_active, created_at, created_by, updated_at, updated_by
    )
    SELECT
        st.school_id, st.branch_id, st.academic_year_id, st.class_id, st.section_id, st.student_id,
        tp.timetable_id, tp.timetable_period_id, tp.period_date, tp.subject_id, tp.teacher_id,
        tp.period_number, tp.start_time, tp.end_time,
        CASE WHEN (st.student_id + tp.period_number + DATEDIFF(DAY, @Today, tp.period_date)) % 19 = 0
             THEN N'ABSENT' ELSE N'PRESENT' END,
        DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), tp.start_time), CAST(tp.period_date AS DATETIME2)),
        @AdminUserId, 1, SYSUTCDATETIME(), @AdminUserId, SYSUTCDATETIME(), @AdminUserId
    FROM student_schema.student st
    CROSS JOIN management_schema.timetable_period tp
    WHERE st.section_id = @SectionId
      AND st.class_id = @ClassId
      AND st.is_active = 1
      AND tp.timetable_id = @TimetableId
      AND tp.period_type = N'CLASS';

    -- -------------------------------------------------------------------------
    -- 4. OVERALL TIMETABLE TABLES DATE REPLACEMENT:
    --    Replace dates for ALL other sections across:
    --    - management_schema.timetable_period
    --    - student_schema.student_attendance
    --    - management_schema.timetable
    --    so that the ENTIRE database is aligned from TODAY up to 2 WEEKS!
    -- -------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM management_schema.timetable_period WHERE timetable_id <> @TimetableId)
    BEGIN
        PRINT N'Replacing dates across overall timetable-related tables for all other sections...';

        -- Map distinct old dates of other sections to the new calendar days (skipping Sundays)
        ;WITH DistinctOldDates AS
        (
            SELECT DISTINCT period_date
            FROM management_schema.timetable_period
            WHERE timetable_id <> @TimetableId
        ),
        OldDateMapping AS
        (
            SELECT 
                d.period_date AS old_date,
                c.period_date AS new_date
            FROM (
                SELECT period_date, ROW_NUMBER() OVER (ORDER BY period_date ASC) AS rn
                FROM DistinctOldDates
            ) d
            JOIN #Cal c ON c.day_index = d.rn
        )
        -- Update period_date for all other sections
        UPDATE tp
        SET tp.period_date = m.new_date,
            tp.updated_at = SYSUTCDATETIME(),
            tp.updated_by = @AdminUserId
        FROM management_schema.timetable_period tp
        JOIN OldDateMapping m ON m.old_date = tp.period_date
        WHERE tp.timetable_id <> @TimetableId;

        -- Update attendance_date & recorded_at for all other sections
        UPDATE sa
        SET sa.attendance_date = tp.period_date,
            sa.recorded_at = DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), tp.start_time), CAST(tp.period_date AS DATETIME2)),
            sa.updated_at = SYSUTCDATETIME(),
            sa.updated_by = @AdminUserId
        FROM student_schema.student_attendance sa
        JOIN management_schema.timetable_period tp ON tp.timetable_period_id = sa.timetable_period_id
        WHERE sa.timetable_id <> @TimetableId;

        -- Update timetable master name and audit timestamps for all other sections
        UPDATE tt
        SET tt.timetable_name = CONCAT(
                SUBSTRING(tt.timetable_name, 1, CASE WHEN CHARINDEX(N' (', tt.timetable_name) > 0 THEN CHARINDEX(N' (', tt.timetable_name) - 1 ELSE LEN(tt.timetable_name) END),
                N' (', CONVERT(VARCHAR(10), @MinDate, 120), N' to ', CONVERT(VARCHAR(10), @MaxDate, 120), N')'
            ),
            tt.updated_at = SYSUTCDATETIME(),
            tt.updated_by = @AdminUserId
        FROM management_schema.timetable tt
        WHERE tt.timetable_id <> @TimetableId;

        PRINT N'Successfully updated dates across all other sections in timetable and attendance tables.';
    END;

    DROP TABLE #Cal;
    DROP TABLE #Grid;

    COMMIT TRANSACTION;
    PRINT N'================================================================================';
    PRINT N'Successfully replaced all dates for overall timetable-related tables from today to 2 weeks!';
    PRINT N'================================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'tempdb..#Cal') IS NOT NULL DROP TABLE #Cal;
    IF OBJECT_ID(N'tempdb..#Grid') IS NOT NULL DROP TABLE #Grid;
    THROW;
END CATCH;
GO
