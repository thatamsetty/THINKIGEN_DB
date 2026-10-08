/*
    Script:    007_alumni_directory_10th_passed_out_mock_data.sql
    Module:    020_alumni.sql / alumni_schema
    Purpose:   Realistic Mock Data for Alumni Directory, Alumni Stories, and Alumni Events
               STRICT REQUIREMENT: ONLY FOR 10TH CLASS PASSED-OUT (GRADUATED) STUDENTS.
               EXPLICITLY EXCLUDES ALL RUNNING ACADEMIC YEAR (CURRENTLY ENROLLED) STUDENTS.

    Architecture & Business Rules:
    - Target: Students who completed and passed out of Class 10 in previous academic years.
    - Exclusions: Any student in current running academic year (is_current = 1, e.g. 2026-2027) is strictly excluded.
    - Career Domains: Aligned with Career Explorer (Technology & Analytics, Software Engineering,
      Data Science, Robotics, AI, Cybersecurity).
    - Scope: Preserves multi-tenant school_id and branch_id scope.
    - Idempotent: Can be executed multiple times safely without duplicate key violations.
*/

SET NOCOUNT ON;
GO

PRINT N'========================================================================';
PRINT N'Seeding Alumni Directory Mock Data for 10th Class Passed-Out Students...';
PRINT N'========================================================================';

-- Defensively reset IDENTITY_INSERT for any interrupted prior sessions
BEGIN TRY SET IDENTITY_INSERT management_schema.academic_year OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.school_class OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT management_schema.section OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT security_schema.users OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT student_schema.student OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT alumni_schema.alumni_profile OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT alumni_schema.alumni_story OFF; END TRY BEGIN CATCH END CATCH;

BEGIN TRANSACTION;

BEGIN TRY
    DECLARE @AdminUserId BIGINT = (SELECT TOP 1 user_id FROM security_schema.users ORDER BY user_id);
    IF @AdminUserId IS NULL
        SET @AdminUserId = 1;

    -- =========================================================================
    -- 1. Ensure Past Academic Years Exist (is_current = 0, NOT running year)
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM management_schema.academic_year WHERE year_name = N'2021-2022' AND school_id = 1)
    BEGIN
        SET IDENTITY_INSERT management_schema.academic_year ON;
        INSERT INTO management_schema.academic_year
            (academic_year_id, school_id, year_name, start_date, end_date, is_current, is_active, created_by)
        VALUES
            (101, 1, N'2021-2022', '2021-04-01', '2022-03-31', 0, 1, @AdminUserId),
            (102, 1, N'2022-2023', '2022-04-01', '2023-03-31', 0, 1, @AdminUserId),
            (103, 1, N'2023-2024', '2023-04-01', '2024-03-31', 0, 1, @AdminUserId),
            (104, 1, N'2024-2025', '2024-04-01', '2025-03-31', 0, 1, @AdminUserId),
            (105, 2, N'2022-2023', '2022-04-01', '2023-03-31', 0, 1, @AdminUserId),
            (106, 2, N'2023-2024', '2023-04-01', '2024-03-31', 0, 1, @AdminUserId),
            (107, 2, N'2024-2025', '2024-04-01', '2025-03-31', 0, 1, @AdminUserId);
        SET IDENTITY_INSERT management_schema.academic_year OFF;
        PRINT N'Seeded past academic years (is_current = 0).';
    END;

    -- =========================================================================
    -- 2. Ensure Class 10 Master Records Exist for Branches
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM management_schema.school_class WHERE class_name = N'Class 10 - Central')
    BEGIN
        SET IDENTITY_INSERT management_schema.school_class ON;
        INSERT INTO management_schema.school_class
            (class_id, school_id, class_name, display_order, is_active, created_by)
        VALUES
            (101, 1, N'Class 10 - Central', 10, 1, @AdminUserId),
            (102, 1, N'Class 10 - North',   10, 1, @AdminUserId),
            (103, 2, N'Class 10 - City',    10, 1, @AdminUserId),
            (104, 2, N'Class 10 - Lake',    10, 1, @AdminUserId);
        SET IDENTITY_INSERT management_schema.school_class OFF;

        SET IDENTITY_INSERT management_schema.section ON;
        INSERT INTO management_schema.section (section_id, class_id, section_name, is_active, created_by)
        VALUES
            (101, 101, N'A', 1, @AdminUserId),
            (102, 102, N'A', 1, @AdminUserId),
            (103, 103, N'A', 1, @AdminUserId),
            (104, 104, N'A', 1, @AdminUserId);
        SET IDENTITY_INSERT management_schema.section OFF;
        PRINT N'Seeded Class 10 masters and sections.';
    END;

    -- =========================================================================
    -- 2.5 Ensure User Accounts Exist in security_schema.users for the Students
    --     (Required by UQ_student_user_id & FK_student_user)
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM security_schema.users WHERE user_id = 501)
    BEGIN
        SET IDENTITY_INSERT security_schema.users ON;
        INSERT INTO security_schema.users
            (user_id, email_address, user_type, is_active, password_hash, password_plain_dev, password_set_at, failed_login_count, created_by)
        VALUES
            (501, N'priya.sharma@alumni.thinkigen.edu', N'STUDENT', 1, NULL, N'Test@12345', '2021-04-01T08:00:00', 0, @AdminUserId),
            (502, N'aditya.varma@alumni.thinkigen.edu', N'STUDENT', 1, NULL, N'Test@12345', '2022-04-01T08:00:00', 0, @AdminUserId),
            (503, N'sneha.patel@alumni.thinkigen.edu', N'STUDENT', 1, NULL, N'Test@12345', '2022-04-01T08:00:00', 0, @AdminUserId),
            (504, N'karthik.reddy@alumni.thinkigen.edu', N'STUDENT', 1, NULL, N'Test@12345', '2023-04-01T08:00:00', 0, @AdminUserId),
            (505, N'ananya.gupta@alumni.thinkigen.edu', N'STUDENT', 1, NULL, N'Test@12345', '2023-04-01T08:00:00', 0, @AdminUserId),
            (506, N'rohan.das@alumni.thinkigen.edu', N'STUDENT', 1, NULL, N'Test@12345', '2024-04-01T08:00:00', 0, @AdminUserId),
            (507, N'megha.sen@alumni.thinkigen.edu', N'STUDENT', 1, NULL, N'Test@12345', '2024-04-01T08:00:00', 0, @AdminUserId),
            (508, N'vikram.malhotra@alumni.thinkigen.edu', N'STUDENT', 1, NULL, N'Test@12345', '2025-04-01T08:00:00', 0, @AdminUserId);
        SET IDENTITY_INSERT security_schema.users OFF;
        PRINT N'Seeded user accounts in security_schema.users for alumni students.';
    END;

    -- =========================================================================
    -- 3. Seed 10th Class Passed-Out Students in student_schema.student
    --    (student_status = 'GRADUATED', academic_year_id with is_current = 0)
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM student_schema.student WHERE admission_number = N'ALUMNI-2021-001')
    BEGIN
        SET IDENTITY_INSERT student_schema.student ON;
        INSERT INTO student_schema.student
        (
            student_id, user_id, school_id, branch_id, academic_year_id, class_id, section_id,
            admission_number, roll_number, first_name, last_name, date_of_birth, gender, blood_group,
            nationality, mother_tongue, religion, student_category, admission_date, student_status,
            status_effective_date, mobile_number, email_address, city, state, country, is_active,
            residency_type, created_by
        )
        VALUES
            -- 1. Priya Sharma (Class 10 Passed Out 2021, Central Branch)
            (501, 501, 1, 1, 101, 101, 101, N'ALUMNI-2021-001', N'R-10', N'Priya', N'Sharma', '2005-04-12', N'FEMALE', N'O+', N'Indian', N'Hindi', N'Not Specified', N'GENERAL', '2016-06-10', N'GRADUATED', '2021-03-31', N'9876543201', N'priya.sharma@alumni.thinkigen.edu', N'Hyderabad', N'Telangana', N'India', 1, N'DAY_SCHOLAR', @AdminUserId),
            -- 2. Aditya Varma (Class 10 Passed Out 2022, Central Branch)
            (502, 502, 1, 1, 102, 101, 101, N'ALUMNI-2022-001', N'R-04', N'Aditya', N'Varma', '2006-08-20', N'MALE', N'A+', N'Indian', N'Telugu', N'Not Specified', N'GENERAL', '2017-06-12', N'GRADUATED', '2022-03-31', N'9876543202', N'aditya.varma@alumni.thinkigen.edu', N'Hyderabad', N'Telangana', N'India', 1, N'DAY_SCHOLAR', @AdminUserId),
            -- 3. Sneha Patel (Class 10 Passed Out 2022, North Branch)
            (503, 503, 1, 2, 102, 102, 102, N'ALUMNI-2022-002', N'R-18', N'Sneha', N'Patel', '2006-03-15', N'FEMALE', N'B+', N'Indian', N'Gujarati', N'Not Specified', N'OBC', '2017-06-12', N'GRADUATED', '2022-03-31', N'9876543203', N'sneha.patel@alumni.thinkigen.edu', N'Hyderabad', N'Telangana', N'India', 1, N'HOSTELLER', @AdminUserId),
            -- 4. Karthik Reddy (Class 10 Passed Out 2023, City Branch)
            (504, 504, 2, 3, 106, 103, 103, N'ALUMNI-2023-001', N'R-07', N'Karthik', N'Reddy', '2007-11-28', N'MALE', N'O+', N'Indian', N'Telugu', N'Not Specified', N'GENERAL', '2018-06-15', N'GRADUATED', '2023-03-31', N'9876543204', N'karthik.reddy@alumni.thinkigen.edu', N'Visakhapatnam', N'Andhra Pradesh', N'India', 1, N'DAY_SCHOLAR', @AdminUserId),
            -- 5. Ananya Gupta (Class 10 Passed Out 2023, Lake Branch)
            (505, 505, 2, 4, 106, 104, 104, N'ALUMNI-2023-002', N'R-12', N'Ananya', N'Gupta', '2007-07-09', N'FEMALE', N'AB+', N'Indian', N'Hindi', N'Not Specified', N'GENERAL', '2018-06-15', N'GRADUATED', '2023-03-31', N'9876543205', N'ananya.gupta@alumni.thinkigen.edu', N'Vijayawada', N'Andhra Pradesh', N'India', 1, N'DAY_SCHOLAR', @AdminUserId),
            -- 6. Rohan Das (Class 10 Passed Out 2024, Central Branch)
            (506, 506, 1, 1, 103, 101, 101, N'ALUMNI-2024-001', N'R-22', N'Rohan', N'Das', '2008-01-18', N'MALE', N'B+', N'Indian', N'Bengali', N'Not Specified', N'GENERAL', '2019-06-10', N'GRADUATED', '2024-03-31', N'9876543206', N'rohan.das@alumni.thinkigen.edu', N'Hyderabad', N'Telangana', N'India', 1, N'DAY_SCHOLAR', @AdminUserId),
            -- 7. Megha Sen (Class 10 Passed Out 2024, North Branch)
            (507, 507, 1, 2, 103, 102, 102, N'ALUMNI-2024-002', N'R-15', N'Megha', N'Sen', '2008-05-24', N'FEMALE', N'A+', N'Indian', N'Bengali', N'Not Specified', N'GENERAL', '2019-06-10', N'GRADUATED', '2024-03-31', N'9876543207', N'megha.sen@alumni.thinkigen.edu', N'Hyderabad', N'Telangana', N'India', 1, N'DAY_SCHOLAR', @AdminUserId),
            -- 8. Vikram Malhotra (Class 10 Passed Out 2025, City Branch)
            (508, 508, 2, 3, 107, 103, 103, N'ALUMNI-2025-001', N'R-02', N'Vikram', N'Malhotra', '2009-02-14', N'MALE', N'O-', N'Indian', N'Punjabi', N'Not Specified', N'GENERAL', '2020-06-12', N'GRADUATED', '2025-03-31', N'9876543208', N'vikram.malhotra@alumni.thinkigen.edu', N'Visakhapatnam', N'Andhra Pradesh', N'India', 1, N'HOSTELLER', @AdminUserId);
        SET IDENTITY_INSERT student_schema.student OFF;
        PRINT N'Seeded 8 graduated Class 10 students into student_schema.student.';
    END;

    -- =========================================================================
    -- 4. Seed Alumni Profiles (alumni_schema.alumni_profile)
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM alumni_schema.alumni_profile WHERE alumni_id = 1)
    BEGIN
        SET IDENTITY_INSERT alumni_schema.alumni_profile ON;
        INSERT INTO alumni_schema.alumni_profile
        (
            alumni_id, school_id, branch_id, academic_year_id, class_id, section_id, student_id, passout_batch_year,
            current_role, organisation_name, industry_name, location_city, location_country,
            linkedin_profile_url, verification_status, verified_at, verified_by, profile_photo_url,
            is_active, created_at, created_by
        )
        SELECT
            p.alumni_id,
            s.school_id,
            s.branch_id,
            s.academic_year_id,
            s.class_id,
            s.section_id,
            s.student_id,
            p.passout_batch_year,
            p.current_role,
            p.organisation_name,
            p.industry_name,
            p.location_city,
            p.location_country,
            p.linkedin_profile_url,
            p.verification_status,
            p.verified_at,
            p.verified_by,
            p.profile_photo_url,
            1,
            SYSUTCDATETIME(),
            @AdminUserId
        FROM (
            VALUES
                (1, 501, 2021, N'Senior Software Engineer', N'Google', N'Technology & Analytics', N'Bengaluru', N'India', N'https://www.linkedin.com/in/priya-sharma-tech', N'VERIFIED', CAST('2024-01-15 10:30:00' AS DATETIME2(0)), @AdminUserId, N'https://images.thinkigen.edu/alumni/priya_sharma.jpg'),
                (2, 502, 2022, N'Machine Learning Engineer', N'Microsoft', N'Technology & Analytics', N'Hyderabad', N'India', N'https://www.linkedin.com/in/aditya-varma-ai', N'VERIFIED', CAST('2024-02-10 11:15:00' AS DATETIME2(0)), @AdminUserId, N'https://images.thinkigen.edu/alumni/aditya_varma.jpg'),
                (3, 503, 2022, N'Robotics Systems Engineer', N'ISRO', N'Engineering & Robotics', N'Bengaluru', N'India', N'https://www.linkedin.com/in/sneha-patel-robotics', N'VERIFIED', CAST('2024-03-05 14:00:00' AS DATETIME2(0)), @AdminUserId, N'https://images.thinkigen.edu/alumni/sneha_patel.jpg'),
                (4, 504, 2023, N'Data Scientist', N'Amazon Web Services', N'Data Science & AI', N'Hyderabad', N'India', N'https://www.linkedin.com/in/karthik-reddy-ds', N'VERIFIED', CAST('2024-04-18 09:45:00' AS DATETIME2(0)), @AdminUserId, N'https://images.thinkigen.edu/alumni/karthik_reddy.jpg'),
                (5, 505, 2023, N'Cybersecurity Operations Analyst', N'Tata Consultancy Services', N'Cybersecurity', N'Pune', N'India', N'https://www.linkedin.com/in/ananya-gupta-sec', N'VERIFIED', CAST('2024-05-22 16:20:00' AS DATETIME2(0)), @AdminUserId, N'https://images.thinkigen.edu/alumni/ananya_gupta.jpg'),
                (6, 506, 2024, N'Systems & UI Architect', N'Spicarts Enterprise', N'Software Engineering', N'Hyderabad', N'India', N'https://www.linkedin.com/in/rohan-das-architect', N'VERIFIED', CAST('2024-07-12 12:10:00' AS DATETIME2(0)), @AdminUserId, N'https://images.thinkigen.edu/alumni/rohan_das.jpg'),
                (7, 507, 2024, N'Associate Product Engineer', N'Zoho Corporation', N'Software Development', N'Chennai', N'India', N'https://www.linkedin.com/in/megha-sen-product', N'PENDING', NULL, NULL, N'https://images.thinkigen.edu/alumni/megha_sen.jpg'),
                (8, 508, 2025, N'Computer Science Research Scholar', N'IIT Madras', N'Technology & Research', N'Chennai', N'India', N'https://www.linkedin.com/in/vikram-malhotra-iit', N'VERIFIED', CAST('2025-08-01 15:30:00' AS DATETIME2(0)), @AdminUserId, N'https://images.thinkigen.edu/alumni/vikram_malhotra.jpg')
        ) AS p(alumni_id, student_id, passout_batch_year, current_role, organisation_name, industry_name, location_city, location_country, linkedin_profile_url, verification_status, verified_at, verified_by, profile_photo_url)
        INNER JOIN student_schema.student s ON s.student_id = p.student_id
        INNER JOIN management_schema.academic_year ay ON ay.academic_year_id = s.academic_year_id
        INNER JOIN management_schema.school_class sc ON sc.class_id = s.class_id
        WHERE ay.is_current = 0                       -- STRICT FILTER: NOT running academic year
          AND sc.class_name LIKE N'%Class 10%'        -- STRICT FILTER: ONLY Class 10
          AND s.student_status = N'GRADUATED';        -- STRICT FILTER: Passed-out students
        SET IDENTITY_INSERT alumni_schema.alumni_profile OFF;
        PRINT N'Seeded alumni profiles for verified 10th class passed-out graduates.';
    END;

    -- =========================================================================
    -- 5. Seed Alumni Success Stories (alumni_schema.alumni_story)
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM alumni_schema.alumni_story WHERE story_title LIKE N'%Google%')
    BEGIN
        SET IDENTITY_INSERT alumni_schema.alumni_story ON;
        INSERT INTO alumni_schema.alumni_story
        (
            alumni_story_id, school_id, branch_id, alumni_id, story_title, story_content,
            is_published, created_at, created_by
        )
        VALUES
            (1, 1, 1, 1, N'From High School Robotics to Building Scalable Cloud Systems at Google',
             N'When Priya Sharma passed out of Class 10 in 2021 from Thinkigen Central Branch, she already had a passion for computer science and mathematics. Today, as a Senior Software Engineer at Google Bengaluru, Priya designs cloud infrastructure handling millions of transactions. "My teachers at Thinkigen taught me to break down big problems into first principles. That mindset remains my biggest asset in tech today," shares Priya.',
             1, SYSUTCDATETIME(), @AdminUserId),

            (2, 1, 1, 2, N'How 10th Grade Mathematics Shaped My Path into Machine Learning & AI',
             N'Aditya Varma (Class 10 Batch of 2022) reflects on how linear algebra and statistics introduced during his secondary school years inspired him to pursue Artificial Intelligence. Now an ML Engineer at Microsoft, Aditya develops natural language models: "The foundation I received here made complex algorithms feel intuitive. Never underestimate the power of mastering school mathematics."',
             1, SYSUTCDATETIME(), @AdminUserId),

            (3, 1, 2, 3, N'Building Autonomous Planetary Rovers: An Ambition Sparked in the Physics Lab',
             N'Sneha Patel graduated from Thinkigen North Branch in 2022. Driven by space exploration, she completed her engineering in Mechatronics and joined ISRO as a Robotics Systems Engineer. "Working on actual motor controllers during science exhibitions at Thinkigen showed me that engineering is about creating things that have never existed before."',
             1, SYSUTCDATETIME(), @AdminUserId);
        SET IDENTITY_INSERT alumni_schema.alumni_story OFF;
        PRINT N'Seeded verified alumni success stories.';
    END;

    -- =========================================================================
    -- 6. Seed Alumni Networking & Mentorship Events into Announcements
    --    (management_schema.announcement: EVENT -> ALUMNI_EVENTS)
    -- =========================================================================
    IF NOT EXISTS (SELECT 1 FROM management_schema.announcement WHERE title LIKE N'%Career Explorer%')
    BEGIN
        INSERT INTO management_schema.announcement
        (
            school_id, branch_id, academic_year_id, announcement_type, sub_category,
            title, description, target_audience, registration_url,
            start_date, end_date, publish_at, status, is_active, created_by
        )
        VALUES
            (1, 1, 1, N'EVENT', N'ALUMNI_EVENTS',
             N'Career Explorer: Pathways in Software Engineering & AI',
             N'Career mentorship session led by distinguished alumni Priya Sharma and Aditya Varma.',
             N'ALL', N'https://events.example.com/register?id=career-explorer-alumni',
             '2026-10-15', '2026-10-15', '2026-10-01T09:00:00', N'PUBLISHED', 1, @AdminUserId),

            (1, 1, 1, N'EVENT', N'ALUMNI_EVENTS',
             N'Class 10 Batch 2021 & 2022 5-Year Reunion & Networking Evening',
             N'Grand reunion gathering for alumni batches at the central campus amphitheatre.',
             N'ALL', N'https://events.example.com/register?id=reunion-2026',
             '2026-11-20', '2026-11-20', '2026-10-15T09:00:00', N'PUBLISHED', 1, @AdminUserId),

            (2, 3, 2, N'EVENT', N'ALUMNI_EVENTS',
             N'Annual Distinguished Alumni Leadership Awards',
             N'Celebrating leadership excellence and contributions across industry and research.',
             N'ALL', NULL,
             '2026-12-10', '2026-12-10', '2026-11-01T09:00:00', N'DRAFT', 1, @AdminUserId);
        PRINT N'Seeded alumni events into announcements under EVENT / ALUMNI_EVENTS.';
    END;

    COMMIT TRANSACTION;

    PRINT N'========================================================================';
    PRINT N'SUCCESS: Alumni directory mock data successfully seeded!';
    PRINT N'========================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    BEGIN TRY SET IDENTITY_INSERT management_schema.academic_year OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT management_schema.school_class OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT management_schema.section OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT security_schema.users OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT student_schema.student OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT alumni_schema.alumni_profile OFF; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY SET IDENTITY_INSERT alumni_schema.alumni_story OFF; END TRY BEGIN CATCH END CATCH;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO

-- =============================================================================
-- Verification Query: Shows seeded Alumni Directory with 10th Class Verification
-- =============================================================================
SELECT
    ap.alumni_id,
    CONCAT(s.first_name, N' ', s.last_name) AS alumni_full_name,
    sc.class_name AS graduated_class,
    ay.year_name AS passout_academic_year,
    ay.is_current AS is_running_academic_year,
    ap.passout_batch_year,
    ap.current_role,
    ap.organisation_name,
    ap.industry_name,
    ap.location_city,
    ap.verification_status,
    ap.profile_photo_url
FROM alumni_schema.alumni_profile ap
INNER JOIN student_schema.student s ON s.student_id = ap.student_id
INNER JOIN management_schema.academic_year ay ON ay.academic_year_id = s.academic_year_id
INNER JOIN management_schema.school_class sc ON sc.class_id = s.class_id
ORDER BY ap.passout_batch_year, ap.alumni_id;
GO
