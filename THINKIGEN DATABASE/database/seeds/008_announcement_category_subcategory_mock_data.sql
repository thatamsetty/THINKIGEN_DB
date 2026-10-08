/*
    Script:    008_announcement_category_subcategory_mock_data.sql
    Module:    management_schema.announcement / 007_announcement.sql
    Purpose:   Comprehensive mock data (100+ rows) covering ALL announcement categories
               and mapped sub-categories across all schools, branches, and academic years.
               Extensively covers ALUMNI_EVENTS, SPORTS, CULTURAL, ACADEMIC (EXAMS, SYLLABUS, TIMETABLE),
               and NOTICES (STUDENT_INSTRUCTIONS, OTHER).

    Category to Sub-Category Mappings Enforced:
    ---------------------------------------------------------------------------------------------------
    EVENT      -> ALUMNI_EVENTS (22 rows), SPORTS (18 rows), CULTURAL (18 rows)
    ACADEMIC   -> EXAMS (12 rows), SYLLABUS (10 rows), TIMETABLE (10 rows)
    NOTICE     -> STUDENT_INSTRUCTIONS (10 rows), OTHER (10 rows)
    ---------------------------------------------------------------------------------------------------
    Total Rows : 110 rows (100+ comprehensive realistic announcements)

    Registration URL Configured:
    https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0

    Referential Integrity:
    - Multi-tenant school_id and academic_year_id are dynamically resolved from management_schema.branch.
    - created_by and updated_by are dynamically mapped from real users in security_schema.users.
    - Idempotent: checks for existing titles to avoid duplicate rows upon re-execution.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Seeding 100+ Announcement Rows for All Categories, Sub-Categories & Events...';
PRINT N'========================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    -- =========================================================================
    -- 1. DYNAMIC USER RESOLUTION (ADMIN & TEACHER USERS)
    -- =========================================================================
    DECLARE @AdminUserId1 BIGINT = (SELECT TOP 1 user_id FROM security_schema.users WHERE user_type = N'ADMIN' ORDER BY user_id ASC);
    DECLARE @AdminUserId2 BIGINT = (SELECT TOP 1 user_id FROM security_schema.users WHERE user_type = N'ADMIN' ORDER BY user_id DESC);
    DECLARE @TeacherUserId1 BIGINT = (SELECT TOP 1 user_id FROM security_schema.users WHERE user_type = N'TEACHER' ORDER BY user_id ASC);
    DECLARE @TeacherUserId2 BIGINT = (SELECT TOP 1 user_id FROM security_schema.users WHERE user_type = N'TEACHER' ORDER BY user_id DESC);

    -- Fallback safety if specific roles are absent
    IF @AdminUserId1 IS NULL
        SET @AdminUserId1 = (SELECT TOP 1 user_id FROM security_schema.users ORDER BY user_id ASC);
    IF @AdminUserId2 IS NULL
        SET @AdminUserId2 = @AdminUserId1;
    IF @TeacherUserId1 IS NULL
        SET @TeacherUserId1 = @AdminUserId1;
    IF @TeacherUserId2 IS NULL
        SET @TeacherUserId2 = @AdminUserId2;

    IF @AdminUserId1 IS NULL
    BEGIN
        RAISERROR(N'No user records found in security_schema.users. Seed users first.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    DECLARE @DefaultRegUrl NVARCHAR(2048) = N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0';

    -- =========================================================================
    -- 2. STAGING DATA FOR 110 REALISTIC ANNOUNCEMENTS
    -- =========================================================================
    DECLARE @StagingAnnouncements TABLE
    (
        row_num           INT IDENTITY(1, 1) PRIMARY KEY,
        branch_id         BIGINT NOT NULL,
        announcement_type NVARCHAR(20) NOT NULL,
        sub_category      NVARCHAR(50) NOT NULL,
        title             NVARCHAR(200) NOT NULL,
        description       NVARCHAR(MAX) NOT NULL,
        target_audience   NVARCHAR(100) NOT NULL,
        registration_url  NVARCHAR(2048) NULL,
        start_date        DATE NULL,
        end_date          DATE NULL,
        publish_at        DATETIME2(0) NOT NULL,
        status            NVARCHAR(20) NOT NULL,
        creator_type      NVARCHAR(10) NOT NULL -- 'ADMIN' or 'TEACHER'
    );

    -- =========================================================================
    -- SECTION 1: EVENT -> ALUMNI_EVENTS (22 rows)
    -- =========================================================================
    INSERT INTO @StagingAnnouncements
        (branch_id, announcement_type, sub_category, title, description, target_audience, registration_url, start_date, end_date, publish_at, status, creator_type)
    VALUES
        (1, N'EVENT', N'ALUMNI_EVENTS',
         N'Thinkigen Annual Grand Alumni Homecoming & Gala Dinner 2026',
         N'Join our flagship annual gathering welcoming back alumni from all graduating batches. Evening includes networking dinner, keynote addresses, and campus nostalgia tour.',
         N'ALL', @DefaultRegUrl, '2026-12-20', '2026-12-21', '2026-11-01T09:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'EVENT', N'ALUMNI_EVENTS',
         N'Distinguished Alumni Keynote: Navigating AI and Future Tech Careers',
         N'Fireside chat with alumni leaders working in top tech unicorns and research labs. Ideal for high school seniors exploring computer science.',
         N'ALL', @DefaultRegUrl, '2026-10-15', '2026-10-15', '2026-09-20T10:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'EVENT', N'ALUMNI_EVENTS',
         N'Global Alumni Career Roundtable & Mentorship Clinic',
         N'Virtual and in-person breakout sessions connecting current 10th graders with overseas alumni studying at global universities.',
         N'STUDENTS', @DefaultRegUrl, '2026-11-14', '2026-11-15', '2026-10-10T09:30:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'ALUMNI_EVENTS',
         N'Decennial Reunion Meet: Celebrating the Batch of 2016',
         N'A special 10-year milestone reunion for the Class of 2016. Reconnect with batchmates, former teachers, and honor class memories.',
         N'ALL', @DefaultRegUrl, '2026-12-27', '2026-12-27', '2026-11-15T11:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Angel Investment & Startup Pitch Day',
         N'Showcase of innovative student and young alumni startups pitching before an esteemed panel of alumni angel investors and industry leaders.',
         N'ALL', @DefaultRegUrl, '2027-01-23', '2027-01-24', '2026-12-01T10:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Mentorship Clinic: 1-on-1 Portfolio & Mock Interview Sprints',
         N'Weekend clinic where senior alumni conduct structured technical and HR mock interviews for graduating school students.',
         N'STUDENTS', @DefaultRegUrl, '2026-10-24', '2026-10-25', '2026-10-01T09:00:00', N'PUBLISHED', N'TEACHER'),

        (4, N'EVENT', N'ALUMNI_EVENTS',
         N'Thinkigen Alumni vs Student Council Friendly Cricket Trophy',
         N'The traditional friendly T20 cricket fixture between our alumni all-star XI and the senior school varsity squad. Followed by high tea.',
         N'ALL', @DefaultRegUrl, '2026-11-28', '2026-11-28', '2026-10-25T08:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'EVENT', N'ALUMNI_EVENTS',
         N'Women in Leadership Alumni Summit & Networking Breakfast',
         N'Panel discussion featuring trailblazing women alumni in medicine, engineering, civil administration, and business entrepreneurship.',
         N'ALL', @DefaultRegUrl, '2027-03-08', '2027-03-08', '2027-02-10T09:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'EVENT', N'ALUMNI_EVENTS',
         N'Silicon Valley & Europe Chapters: Overseas Alumni Virtual Connect',
         N'Quarterly digital meet-up for alumni stationed in North America and Europe sharing insights on international admissions and work visas.',
         N'ALL', @DefaultRegUrl, '2026-09-26', '2026-09-26', '2026-09-01T18:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'EVENT', N'ALUMNI_EVENTS',
         N'Civil Services & Public Policy Conclave: Alumni in Governance',
         N'UPSC and State Service rank-holders from Thinkigen alumni pool share preparation strategies and public administration perspectives.',
         N'STUDENTS', @DefaultRegUrl, '2026-11-08', '2026-11-08', '2026-10-15T10:30:00', N'PUBLISHED', N'TEACHER'),

        (2, N'EVENT', N'ALUMNI_EVENTS',
         N'Healthcare & Medical Frontiers: Alumni Doctors & Researchers Panel',
         N'Alumni practicing physicians, surgeons, and medical researchers interact with biology students regarding NEET, MBBS, and research careers.',
         N'ALL', @DefaultRegUrl, '2026-10-31', '2026-10-31', '2026-10-05T11:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Arts & Creative Media Exhibition: Design, Film & Architecture',
         N'Showcasing creative alumni portfolios in architecture, user design, filmmaking, animation, and contemporary writing.',
         N'ALL', @DefaultRegUrl, '2026-12-12', '2026-12-13', '2026-11-20T09:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'ALUMNI_EVENTS',
         N'Silver Jubilee Prep Meet: Planning Milestone Celebrations',
         N'Organizing committee meeting with senior alumni representatives to formulate the 25th anniversary master events calendar.',
         N'ALL', @DefaultRegUrl, '2027-02-06', '2027-02-06', '2027-01-10T15:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Football League: Knockout Derby at Central Stadium',
         N'Weekend 7-a-side football tournament pitching batches against one another in an exhilarating sporting reunion.',
         N'ALL', @DefaultRegUrl, '2026-11-21', '2026-11-22', '2026-10-28T08:30:00', N'PUBLISHED', N'ADMIN'),

        (4, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Scholarship Endowment Launch & Benefactor Luncheon',
         N'Unveiling the Alumni Meritorious Scholarship Fund to sponsor financially underprivileged students for high school education.',
         N'ALL', @DefaultRegUrl, '2027-01-16', '2027-01-16', '2026-12-18T12:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Legal Luminaries: Moot Court Demonstration & Law Careers',
         N'Advocates and corporate legal alumni conduct a simulated moot court demonstration and counsel students on CLAT and legal professions.',
         N'STUDENTS', @DefaultRegUrl, '2026-10-18', '2026-10-18', '2026-09-25T14:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Chapter Hyderabad: Winter Social & Mixer Meet',
         N'Evening networking gathering for alumni residing in Hyderabad. Family and spouses welcome.',
         N'ALL', @DefaultRegUrl, '2026-12-19', '2026-12-19', '2026-11-25T19:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Chapter Bengaluru: Tech & Innovation Breakfast Meetup',
         N'Breakfast networking event hosted in Whitefield for alumni tech founders, engineers, and product strategists.',
         N'ALL', @DefaultRegUrl, '2027-01-09', '2027-01-09', '2026-12-12T08:30:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Young Innovators Award & Fellowship Selection',
         N'Annual felicitation recognizing alumni under 30 who have demonstrated distinguished contributions to science, arts, or social impact.',
         N'ALL', @DefaultRegUrl, '2027-02-27', '2027-02-27', '2027-01-20T10:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Environmentalists & Green Architecture Workshop',
         N'Interactive masterclass on sustainable campus infrastructure, rain-water harvesting, and renewable solar deployment led by alumni specialists.',
         N'ALL', @DefaultRegUrl, '2026-11-07', '2026-11-07', '2026-10-12T09:30:00', N'PUBLISHED', N'TEACHER'),

        (1, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Wall of Honor Unveiling & Presidential Address',
         N'Dedicating the new campus permanent portrait gallery honoring distinguished national awardees and decorated alumni.',
         N'ALL', @DefaultRegUrl, '2027-01-26', '2027-01-26', '2027-01-05T10:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'ALUMNI_EVENTS',
         N'Alumni Teachers Nostalgia Tea: Honoring Retired Educators',
         N'Heartfelt afternoon tea honoring beloved retired school educators hosted jointly by alumni batch representatives.',
         N'ALL', @DefaultRegUrl, '2026-09-05', '2026-09-05', '2026-08-20T15:30:00', N'PUBLISHED', N'ADMIN');

    -- =========================================================================
    -- SECTION 2: EVENT -> SPORTS (18 rows)
    -- =========================================================================
    INSERT INTO @StagingAnnouncements
        (branch_id, announcement_type, sub_category, title, description, target_audience, registration_url, start_date, end_date, publish_at, status, creator_type)
    VALUES
        (1, N'EVENT', N'SPORTS',
         N'Annual Inter-House Track and Field Athletics Championship 2026',
         N'Two days of sprint, relay, long jump, shot put, and hurdle competitions. House points will determine the coveted Championship Trophy.',
         N'ALL', @DefaultRegUrl, '2026-11-19', '2026-11-20', '2026-10-25T08:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'EVENT', N'SPORTS',
         N'Thinkigen Premier Football League: Senior Inter-Class Cup',
         N'Seven-a-side league matches hosted under floodlights. Teams must finalize rosters with the Physical Education department.',
         N'STUDENTS', @DefaultRegUrl, '2026-10-12', '2026-10-16', '2026-09-28T09:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'EVENT', N'SPORTS',
         N'Inter-School Basketball Invitational Tournament (Boys & Girls)',
         N'Hosting 16 regional school teams for a three-day knockout tournament at our Olympic-dimension indoor basketball arena.',
         N'ALL', @DefaultRegUrl, '2026-12-03', '2026-12-05', '2026-11-10T10:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'SPORTS',
         N'District Table Tennis Open: Singles and Doubles Knockout',
         N'Junior and Senior category matches. Official ITTF rules apply. Top performers advance to state qualifiers.',
         N'STUDENTS', @DefaultRegUrl, '2026-09-22', '2026-09-23', '2026-09-05T09:00:00', N'PUBLISHED', N'TEACHER'),

        (3, N'EVENT', N'SPORTS',
         N'Annual Swimming Gala: Freestyle, Butterfly & Medley Relays',
         N'Heats and finals across 50m and 100m categories in our temperature-controlled aquatic centre. Spectator seating open for parents.',
         N'ALL', @DefaultRegUrl, '2026-10-20', '2026-10-21', '2026-10-01T08:30:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'SPORTS',
         N'Grandmasters Interschool Chess Championship: Rapid & Blitz',
         N'Swiss-system 7-round FIDE rated rapid tournament open to all registered school champions.',
         N'STUDENTS', @DefaultRegUrl, '2026-11-06', '2026-11-07', '2026-10-15T09:00:00', N'PUBLISHED', N'TEACHER'),

        (4, N'EVENT', N'SPORTS',
         N'Thinkigen Cricket Championship: Under-16 Inter-Branch Shield',
         N'50-over matches featuring the top elevens from all four campuses. White flannels and turf pitch conditions.',
         N'ALL', @DefaultRegUrl, '2026-12-14', '2026-12-18', '2026-11-20T08:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'EVENT', N'SPORTS',
         N'Badminton Masters Cup: Inter-House Singles and Mixed Doubles',
         N'Fast-paced synthetic indoor badminton showdown. Yonex feather shuttlecocks provided by sports council.',
         N'STUDENTS', @DefaultRegUrl, '2026-10-08', '2026-10-09', '2026-09-20T09:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'EVENT', N'SPORTS',
         N'Taekwondo & Martial Arts Belt Progression Grading Camp',
         N'Grandmaster certified technical sparring, kata forms, and tile breaking evaluations for yellow through black belts.',
         N'STUDENTS', @DefaultRegUrl, '2027-01-30', '2027-01-30', '2027-01-10T09:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'EVENT', N'SPORTS',
         N'Inter-School Volleyball Tournament: Smash Fest 2026',
         N'Regional outdoor volleyball contest. Registered school teams must submit player fitness declarations.',
         N'ALL', @DefaultRegUrl, '2026-11-27', '2026-11-28', '2026-11-05T08:30:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'SPORTS',
         N'Cross-Country 5K & 10K Mini Marathon: Run for Education',
         N'Annual community road race through scenic route surrounding campus. Medals and refreshments for all finishers.',
         N'ALL', @DefaultRegUrl, '2027-02-14', '2027-02-14', '2027-01-15T06:30:00', N'PUBLISHED', N'ADMIN'),

        (4, N'EVENT', N'SPORTS',
         N'Lawn Tennis Open: Junior & Senior Singles Tournament',
         N'Hard court tournament evaluated by certified AITA umpires. Balls and hydration support provided.',
         N'STUDENTS', @DefaultRegUrl, '2026-10-27', '2026-10-29', '2026-10-10T14:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'EVENT', N'SPORTS',
         N'Inter-House Kho-Kho & Kabaddi Traditional Games Fiesta',
         N'Reviving traditional Indian sporting prowess. High-intensity matches on standardized clay courts.',
         N'STUDENTS', @DefaultRegUrl, '2026-12-08', '2026-12-09', '2026-11-20T10:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'EVENT', N'SPORTS',
         N'Archery & Target Shooting Demonstration & Open Trials',
         N'Precision shooting clinic conducted by national medalists. Safety gear and recurve bows provided on-range.',
         N'STUDENTS', @DefaultRegUrl, '2027-01-18', '2027-01-18', '2027-01-02T11:00:00', N'PUBLISHED', N'TEACHER'),

        (3, N'EVENT', N'SPORTS',
         N'Rollerskating & Speed Skating Sprint Challenge',
         N'Ring sprint laps and slalom agility competitions for middle and primary school speedsters.',
         N'STUDENTS', @DefaultRegUrl, '2026-11-12', '2026-11-12', '2026-10-25T15:00:00', N'PUBLISHED', N'TEACHER'),

        (4, N'EVENT', N'SPORTS',
         N'Gymnastics & Aerobics Floor Display and Skill Assessment',
         N'Floor balance routines, vault drills, and synchronized aerobics exhibitions in the fitness auditorium.',
         N'ALL', @DefaultRegUrl, '2027-02-20', '2027-02-20', '2027-02-01T10:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'EVENT', N'SPORTS',
         N'Thinkigen Sports Day Rehearsal & Parade Drill Notice',
         N'Compulsory full-dress march past rehearsals for all house contingents and the school brass band.',
         N'STUDENTS', NULL, '2026-11-17', '2026-11-18', '2026-11-05T07:30:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'SPORTS',
         N'International Yoga Day: Mass Surya Namaskar & Mindfulness Camp',
         N'Sunrise wellness gathering on the main sports ground. Yoga mats provided for all participants.',
         N'ALL', @DefaultRegUrl, '2026-06-21', '2026-06-21', '2026-06-05T06:00:00', N'PUBLISHED', N'ADMIN');

    -- =========================================================================
    -- SECTION 3: EVENT -> CULTURAL (18 rows)
    -- =========================================================================
    INSERT INTO @StagingAnnouncements
        (branch_id, announcement_type, sub_category, title, description, target_audience, registration_url, start_date, end_date, publish_at, status, creator_type)
    VALUES
        (1, N'EVENT', N'CULTURAL',
         N'Nritya Tarang 2026: Inter-House Classical & Contemporary Dance Festival',
         N'Mesmerizing celebration of Bharatanatyam, Kathak, Odissi, and fusion dance choreography in the main auditorium.',
         N'ALL', @DefaultRegUrl, '2026-10-23', '2026-10-24', '2026-10-01T09:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'EVENT', N'CULTURAL',
         N'Rhythm & Blues: Annual Battle of the Student Rock Bands',
         N'Electric evening of live vocal harmonies, lead guitar solos, and percussion performances by high school bands.',
         N'ALL', @DefaultRegUrl, '2026-11-20', '2026-11-20', '2026-11-01T17:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'CULTURAL',
         N'National Theatre Conclave: Inter-School One-Act Drama Festival',
         N'Showcase of powerful student plays exploring contemporary social themes, historical satire, and classical drama.',
         N'ALL', @DefaultRegUrl, '2026-12-10', '2026-12-11', '2026-11-15T10:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'CULTURAL',
         N'Canvas & Soul: Annual Fine Arts & Sculpture Gallery Exhibition',
         N'Featuring curated student oil paintings, watercolor landscapes, clay sculptures, and digital graphic design.',
         N'ALL', @DefaultRegUrl, '2026-11-05', '2026-11-07', '2026-10-18T09:30:00', N'PUBLISHED', N'TEACHER'),

        (3, N'EVENT', N'CULTURAL',
         N'Symphony of Voices: Interschool Choral & Classical Vocal Competition',
         N'Western choir and Indian classical jugalbandi featuring choral ensembles from 12 partner schools.',
         N'ALL', @DefaultRegUrl, '2026-12-18', '2026-12-18', '2026-11-28T14:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'CULTURAL',
         N'Dionysus Literary Conclave: Parliamentary Debate & Model UN Summit',
         N'Three days of rigorous diplomatic discourse, draft resolution lobbying, and parliamentary debating.',
         N'STUDENTS', @DefaultRegUrl, '2026-10-16', '2026-10-18', '2026-09-25T08:30:00', N'PUBLISHED', N'TEACHER'),

        (4, N'EVENT', N'CULTURAL',
         N'Diwali Cultural Carnival: Dandiya, Rangoli & Festive Bazaar',
         N'Vibrant evening of traditional festivities, food kiosks, student handicraft stalls, and garba dance rounds.',
         N'ALL', @DefaultRegUrl, '2026-11-01', '2026-11-01', '2026-10-15T16:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'EVENT', N'CULTURAL',
         N'FilmCraft 2026: Student Short Film & Documentary Screening Gala',
         N'Red carpet premiere of original student short films written, directed, and edited by our media club members.',
         N'ALL', @DefaultRegUrl, '2027-01-22', '2027-01-22', '2027-01-05T17:30:00', N'PUBLISHED', N'ADMIN'),

        (1, N'EVENT', N'CULTURAL',
         N'Thinkigen Winter Wonderland Carnival & Charity Bake Sale',
         N'Fun-filled weekend carnival featuring game stalls, student bake sales, and acoustic live busking performances.',
         N'ALL', @DefaultRegUrl, '2026-12-23', '2026-12-24', '2026-12-05T10:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'CULTURAL',
         N'Classical Instrumental Jugalbandi: Sitar, Flute, Violin & Tabla',
         N'A serene evening of Indian classical ragas performed by student virtuosos and guest maestro instructors.',
         N'ALL', @DefaultRegUrl, '2027-02-12', '2027-02-12', '2027-01-25T18:00:00', N'PUBLISHED', N'TEACHER'),

        (3, N'EVENT', N'CULTURAL',
         N'Folk Heritage of India: Traditional Attire & Regional Song Showcase',
         N'Colorful celebration of India''s diverse regional folk cultures, costumes, and harvest celebration songs.',
         N'ALL', @DefaultRegUrl, '2026-09-25', '2026-09-25', '2026-09-10T10:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'EVENT', N'CULTURAL',
         N'Stand-up Comedy & Theatrical Mime Evening',
         N'Laugh out loud showcase featuring witty observational comedy, improv sketches, and pantomime drama acts.',
         N'ALL', @DefaultRegUrl, '2027-02-05', '2027-02-05', '2027-01-18T16:30:00', N'PUBLISHED', N'TEACHER'),

        (1, N'EVENT', N'CULTURAL',
         N'Kavi Sammelan & Urdu Poetry Mushaira: Verse & Reflection',
         N'Recitations of classical and contemporary verse in Hindi, Urdu, and English by budding student bards.',
         N'ALL', @DefaultRegUrl, '2026-10-09', '2026-10-09', '2026-09-22T15:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'EVENT', N'CULTURAL',
         N'Annual Science & Innovation Expo: Working Models & AI Demos',
         N'Over 100 working STEM exhibits spanning robotics, solar energy, drone flight, and computer vision.',
         N'ALL', @DefaultRegUrl, '2026-11-25', '2026-11-26', '2026-11-05T09:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'EVENT', N'CULTURAL',
         N'Pottery & Ceramic Wheel Crafting Masterclass',
         N'Hands-on clay sculpting workshop guided by master terracotta artisans from the Crafts Council.',
         N'STUDENTS', @DefaultRegUrl, '2027-01-15', '2027-01-16', '2026-12-28T11:00:00', N'PUBLISHED', N'TEACHER'),

        (4, N'EVENT', N'CULTURAL',
         N'Gourmet Junior Chef: Fireless Culinary Innovation Contest',
         N'Appetizer, salad, and dessert assembly challenge focusing on balanced nutrition and plating aesthetics.',
         N'STUDENTS', @DefaultRegUrl, '2026-10-30', '2026-10-30', '2026-10-12T13:30:00', N'PUBLISHED', N'TEACHER'),

        (1, N'EVENT', N'CULTURAL',
         N'Shakespeare in the Garden: Open-Air Amphitheatre Performance',
         N'Dramatic staging of A Midsummer Night''s Dream in the campus open-air courtyard garden.',
         N'ALL', @DefaultRegUrl, '2027-02-26', '2027-02-27', '2027-02-05T18:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'EVENT', N'CULTURAL',
         N'Photography Walk & Monochrome Street Art Contest',
         N'Urban photo-walk exploring heritage architecture and street life, culminating in a gallery competition.',
         N'STUDENTS', @DefaultRegUrl, '2026-12-05', '2026-12-05', '2026-11-18T07:30:00', N'PUBLISHED', N'TEACHER');

    -- =========================================================================
    -- SECTION 4: ACADEMIC -> EXAMS (12 rows)
    -- =========================================================================
    INSERT INTO @StagingAnnouncements
        (branch_id, announcement_type, sub_category, title, description, target_audience, registration_url, start_date, end_date, publish_at, status, creator_type)
    VALUES
        (1, N'ACADEMIC', N'EXAMS',
         N'Mid-Term Summative Examination Schedule & Guidelines',
         N'Official schedule for Class 8, 9 and 10 Mid-Term assessments. Hall tickets will be issued via the student portal.',
         N'STUDENTS', NULL, '2026-09-15', '2026-09-26', '2026-08-25T09:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'ACADEMIC', N'EXAMS',
         N'Board Practical Assessment & Science Lab Examination',
         N'Evaluation of laboratory coursework, notebooks, and viva voce for Class 9 Physics and Chemistry.',
         N'STUDENTS', NULL, '2027-01-10', '2027-01-20', '2026-12-15T09:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'ACADEMIC', N'EXAMS',
         N'Periodic Assessment 1 (PA-1) Timetable & Hall Allocations',
         N'Comprehensive timetable for PA-1 covering core language, mathematics, and social science subjects.',
         N'ALL', NULL, '2026-07-20', '2026-07-25', '2026-07-05T09:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'ACADEMIC', N'EXAMS',
         N'Pre-Board Mock Examination-I Notification for Senior Classes',
         N'Simulated board exam conditions to assess readiness. Detailed question paper blueprint is attached in student resources.',
         N'STUDENTS', NULL, '2026-12-05', '2026-12-18', '2026-11-15T09:00:00', N'PUBLISHED', N'TEACHER'),

        (3, N'ACADEMIC', N'EXAMS',
         N'Diagnostic Aptitude Assessment & Math Olympiad Prelims',
         N'Screening test for the National Mathematical Olympiad and science talent search scholarship.',
         N'STUDENTS', @DefaultRegUrl, '2026-08-28', '2026-08-28', '2026-08-10T10:00:00', N'PUBLISHED', N'TEACHER'),

        (3, N'ACADEMIC', N'EXAMS',
         N'Term-End Cumulative Assessment Schedule (Classes 6 to 9)',
         N'Final institutional written examination datesheet, seating arrangements, and invigilation protocols.',
         N'ALL', NULL, '2027-03-01', '2027-03-15', '2027-02-01T09:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'ACADEMIC', N'EXAMS',
         N'Language Proficiency & Listening Skills (ASL) Examination',
         N'Assessment of Speaking and Listening (ASL) for English and Second Languages in audio-equipped labs.',
         N'STUDENTS', NULL, '2026-11-10', '2026-11-14', '2026-10-25T09:00:00', N'PUBLISHED', N'TEACHER'),

        (4, N'ACADEMIC', N'EXAMS',
         N'Special Remedial Improvement Test for Foundational Concepts',
         N'Targeted re-assessment to support students needing reinforcement in foundational Mathematics and Physics.',
         N'STUDENTS', NULL, '2026-10-28', '2026-10-30', '2026-10-15T09:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'ACADEMIC', N'EXAMS',
         N'Pre-Board Mock Examination-II & Answer Key Review Clinic',
         N'Second series mock examination followed by subject-wise error analysis seminars.',
         N'STUDENTS', NULL, '2027-01-25', '2027-02-05', '2027-01-08T09:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'ACADEMIC', N'EXAMS',
         N'Periodic Assessment 2 (PA-2) Datesheet & Seating Matrix',
         N'Mid-winter diagnostic cycle testing syllabus covered across terms 1 and 2.',
         N'ALL', NULL, '2026-11-16', '2026-11-21', '2026-10-30T09:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'ACADEMIC', N'EXAMS',
         N'National Cyber Olympiad & Coding Assessment Qualifying Round',
         N'Online algorithmic thinking and computing contest held in the senior computer labs.',
         N'STUDENTS', @DefaultRegUrl, '2026-11-04', '2026-11-04', '2026-10-18T11:00:00', N'PUBLISHED', N'TEACHER'),

        (4, N'ACADEMIC', N'EXAMS',
         N'Standardized Reading & Lexile Comprehension Benchmark',
         N'Annual digital literacy assessment measuring reading speed, vocabulary, and textual inference.',
         N'STUDENTS', NULL, '2026-09-08', '2026-09-10', '2026-08-25T10:00:00', N'PUBLISHED', N'TEACHER');

    -- =========================================================================
    -- SECTION 5: ACADEMIC -> SYLLABUS (10 rows)
    -- =========================================================================
    INSERT INTO @StagingAnnouncements
        (branch_id, announcement_type, sub_category, title, description, target_audience, registration_url, start_date, end_date, publish_at, status, creator_type)
    VALUES
        (1, N'ACADEMIC', N'SYLLABUS',
         N'Term-1 Academic Syllabus Completion Target & Revision Roadmap',
         N'Detailed chapter breakdown and subject-wise milestone dates for completing Term-1 curriculum ahead of exams.',
         N'ALL', NULL, '2026-08-01', '2026-09-10', '2026-07-28T09:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'ACADEMIC', N'SYLLABUS',
         N'Science Lab Manual & Experiment Coursework Syllabus 2026-27',
         N'Prescribed practical exercises, chemical apparatus handling guides, and project requirements for Classes 8 through 10.',
         N'STUDENTS', NULL, '2026-06-15', '2027-02-28', '2026-06-10T10:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'ACADEMIC', N'SYLLABUS',
         N'Term-2 Comprehensive Curriculum Outline & Recommended Readings',
         N'Updated reference textbook chapters, supplementary video modules, and practice assignments for the second semester.',
         N'ALL', NULL, '2026-10-15', '2027-02-20', '2026-10-01T09:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'ACADEMIC', N'SYLLABUS',
         N'Computer Science & Applied Coding Curriculum: Python & SQL Modules',
         N'Hands-on lab syllabus covering data structures, relational queries, and introductory machine learning principles.',
         N'STUDENTS', NULL, '2026-07-01', '2027-01-15', '2026-06-25T11:00:00', N'PUBLISHED', N'TEACHER'),

        (3, N'ACADEMIC', N'SYLLABUS',
         N'Social Sciences Historical Case Studies & Map Work Syllabus',
         N'Detailed guidelines on prescribed map plotting, constitution case studies, and environmental sustainability assignments.',
         N'STUDENTS', NULL, '2026-08-15', '2026-12-10', '2026-08-05T09:00:00', N'PUBLISHED', N'TEACHER'),

        (3, N'ACADEMIC', N'SYLLABUS',
         N'Fine Arts & Vocational Skill Courses Syllabus Booklet',
         N'Elective module curriculum outlines for Robotics, Financial Literacy, Commercial Art, and Horticulture.',
         N'ALL', NULL, '2026-06-20', '2027-02-15', '2026-06-12T09:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'ACADEMIC', N'SYLLABUS',
         N'Advanced Mathematics Enrichment Syllabus for Gifted Learners',
         N'Accelerated module covering number theory, combinatorial problem solving, and analytical coordinate geometry.',
         N'STUDENTS', NULL, '2026-09-01', '2027-01-30', '2026-08-20T10:00:00', N'PUBLISHED', N'TEACHER'),

        (4, N'ACADEMIC', N'SYLLABUS',
         N'Hindi & Sanskrit Literature Poetry Analysis & Grammar Syllabus',
         N'Grammar rule books, sandhi samasa breakdown, and textbook poetry prose analysis breakdown for the academic session.',
         N'STUDENTS', NULL, '2026-07-10', '2026-11-30', '2026-06-30T09:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'ACADEMIC', N'SYLLABUS',
         N'Environmental Studies Fieldwork & Ecosystem Assessment Syllabus',
         N'Practical bio-diversity surveys, composting experiments, and local water body analysis criteria.',
         N'STUDENTS', NULL, '2026-09-15', '2026-12-15', '2026-09-01T09:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'ACADEMIC', N'SYLLABUS',
         N'Physical Health Education & Sports Theory Syllabus',
         N'Nutrition science, human physiology fundamentals, and sports rule books for physical education coursework.',
         N'ALL', NULL, '2026-07-05', '2027-02-15', '2026-06-20T10:00:00', N'PUBLISHED', N'ADMIN');

    -- =========================================================================
    -- SECTION 6: ACADEMIC -> TIMETABLE (10 rows)
    -- =========================================================================
    INSERT INTO @StagingAnnouncements
        (branch_id, announcement_type, sub_category, title, description, target_audience, registration_url, start_date, end_date, publish_at, status, creator_type)
    VALUES
        (1, N'ACADEMIC', N'TIMETABLE',
         N'Updated Master Class Timetable for Academic Session 2026-27',
         N'Revised period allocations, lab hours, and teacher assignments. Effective Monday onwards for all sections.',
         N'ALL', NULL, '2026-06-15', '2027-03-31', '2026-06-10T09:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'ACADEMIC', N'TIMETABLE',
         N'Science Laboratory Practical Rotation Schedule (Term-1)',
         N'Bi-weekly laboratory batch distribution for Physics, Chemistry, and Biology experiments.',
         N'STUDENTS', NULL, '2026-07-01', '2026-10-31', '2026-06-25T10:00:00', N'PUBLISHED', N'TEACHER'),

        (2, N'ACADEMIC', N'TIMETABLE',
         N'Zero-Period Remedial and Doubt-Clearing Class Schedule',
         N'Special morning zero-period timings (07:45 AM - 08:30 AM) for personalized academic support in Math and Science.',
         N'ALL', NULL, '2026-08-01', '2026-12-15', '2026-07-25T09:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'ACADEMIC', N'TIMETABLE',
         N'Winter Term Revised School Timings & Assembly Routine',
         N'In observance of winter fog conditions, morning school timings are adjusted by 30 minutes effective next week.',
         N'ALL', NULL, '2026-11-15', '2027-01-31', '2026-11-05T09:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'ACADEMIC', N'TIMETABLE',
         N'Computer Lab & Robotics Workshop Schedule for Middle School',
         N'Class-wise terminal allocations for Scratch programming, CAD design, and Lego Mindstorms robotics kits.',
         N'STUDENTS', NULL, '2026-07-15', '2026-11-30', '2026-07-05T09:00:00', N'PUBLISHED', N'TEACHER'),

        (3, N'ACADEMIC', N'TIMETABLE',
         N'Library Reading Hour & Literary Circle Weekly Allocations',
         N'Designated reading periods for each section to access reference stacks and digital eBook portals.',
         N'ALL', NULL, '2026-06-20', '2027-03-20', '2026-06-15T11:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'ACADEMIC', N'TIMETABLE',
         N'Saturday Co-Curricular Club Activity Rotations (Term-1)',
         N'Activity schedule for Debate, Astronomy, Western Music, Classical Dance, and Eco-Warriors clubs.',
         N'ALL', NULL, '2026-07-01', '2026-10-31', '2026-06-22T09:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'ACADEMIC', N'TIMETABLE',
         N'Senior Secondary Intensive Board Preparation Schedule',
         N'Dedicated question paper solving, speed writing, and masterclass sessions scheduled every alternate Saturday.',
         N'STUDENTS', NULL, '2026-12-01', '2027-02-15', '2026-11-20T10:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'ACADEMIC', N'TIMETABLE',
         N'Physical Education & Outdoor Field Rotation Master Timetable',
         N'Structured usage of the football ground, running track, and synthetic basketball courts by class tiers.',
         N'ALL', NULL, '2026-07-01', '2027-02-28', '2026-06-25T08:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'ACADEMIC', N'TIMETABLE',
         N'Counseling & Career Guidance Group Discussion Schedule',
         N'Weekly psychologist and counselor group interaction calendar for Class 9 and 10 students.',
         N'STUDENTS', NULL, '2026-08-10', '2026-12-10', '2026-07-30T10:30:00', N'PUBLISHED', N'TEACHER');

    -- =========================================================================
    -- SECTION 7: NOTICE -> STUDENT_INSTRUCTIONS (10 rows)
    -- =========================================================================
    INSERT INTO @StagingAnnouncements
        (branch_id, announcement_type, sub_category, title, description, target_audience, registration_url, start_date, end_date, publish_at, status, creator_type)
    VALUES
        (1, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Mandatory Laboratory Safety Code and Apron Compliance Policy',
         N'All students entering science laboratories must wear lab aprons and safety goggles. Solvents must be handled only under teacher supervision.',
         N'STUDENTS', NULL, '2026-06-15', '2027-03-31', '2026-06-10T09:00:00', N'PUBLISHED', N'TEACHER'),

        (1, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Campus Smart-Card & RFID Identity Badge Guidelines',
         N'Students must visibly display their RFID smart badge at all times for gate entry, bus boarding, and library circulation.',
         N'ALL', NULL, '2026-06-01', '2027-03-31', '2026-05-25T09:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Digital Device Usage & Responsible AI Policy on School Network',
         N'Guidelines for acceptable use of school tablets, computer labs, and campus Wi-Fi. AI tools must be cited transparently.',
         N'STUDENTS', NULL, '2026-07-01', '2027-03-31', '2026-06-20T10:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Bus Commuter Code of Conduct & Transit Safety Regulations',
         N'Safety protocols for boarding, deboarding, emergency alarm usage, and respectful etiquette toward bus drivers and attendants.',
         N'ALL', NULL, '2026-06-05', '2027-03-31', '2026-05-30T09:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'School Uniform & Personal Grooming Standards for Academic Year',
         N'Comprehensive dress code regulations for regular weekdays, Wednesday sports kits, and winter blazers.',
         N'ALL', NULL, '2026-06-01', '2027-03-31', '2026-05-20T09:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Library Book Borrowing, Late Return Fines & Digital Stacks Access',
         N'Procedures for checking out up to 3 titles for two weeks. Overdue policies and credentials for digital research journals.',
         N'STUDENTS', NULL, '2026-06-15', '2027-03-31', '2026-06-08T11:00:00', N'PUBLISHED', N'TEACHER'),

        (4, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Cafeteria Hygiene, Healthy Nutrition Policy & Cashless Smart Pay',
         N'Nutritional standards for packed lunches and instructions on topping up student smart ID balance for hot lunches.',
         N'ALL', NULL, '2026-06-10', '2027-03-31', '2026-06-02T09:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Emergency Evacuation Drill & Fire Safety Protocol Instructions',
         N'Escape route maps, muster station designations on sports field, and dos & don''ts during alarm activations.',
         N'ALL', NULL, '2026-08-01', '2026-08-31', '2026-07-25T09:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Zero-Tolerance Anti-Bullying and Peer Harmony Guidelines',
         N'Safeguarding committee contacts, anonymous grievance drop-boxes, and peer support counseling resources.',
         N'ALL', NULL, '2026-06-01', '2027-03-31', '2026-05-28T09:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'NOTICE', N'STUDENT_INSTRUCTIONS',
         N'Examination Hall Integrity & Prohibited Articles Protocol',
         N'Strict prohibition of electronic smartwatches, programmable calculators, or handwritten chits inside examination halls.',
         N'STUDENTS', NULL, '2026-09-01', '2027-03-15', '2026-08-20T09:30:00', N'PUBLISHED', N'ADMIN');

    -- =========================================================================
    -- SECTION 8: NOTICE -> OTHER (10 rows)
    -- =========================================================================
    INSERT INTO @StagingAnnouncements
        (branch_id, announcement_type, sub_category, title, description, target_audience, registration_url, start_date, end_date, publish_at, status, creator_type)
    VALUES
        (1, N'NOTICE', N'OTHER',
         N'Annual Student Comprehensive Medical, Dental & Eye Screening Camp',
         N'Qualified pediatricians, dentists, and optometrists conducting routine health checkups. Individual medical report cards sent to parents.',
         N'ALL', @DefaultRegUrl, '2026-09-21', '2026-09-24', '2026-09-01T09:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'NOTICE', N'OTHER',
         N'Campus Lost and Found Quarterly Reclaim and Clearance Drive',
         N'Water bottles, blazers, spectacles, and textbooks collected over the term are displayed in the administrative atrium for claims.',
         N'ALL', NULL, '2026-10-28', '2026-10-30', '2026-10-15T10:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'NOTICE', N'OTHER',
         N'Green Campus Tree Plantation & Urban Gardening Initiative',
         N'Students and teachers planting 500 indigenous saplings across the campus perimeter. Seedlings sponsored by the Eco Club.',
         N'ALL', @DefaultRegUrl, '2026-08-15', '2026-08-15', '2026-08-01T08:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'NOTICE', N'OTHER',
         N'Voluntary Blood Donation & Community Health Outreach Drive',
         N'In association with the Red Cross Society. Parents, alumni, and staff members are invited to donate and save lives.',
         N'ALL', @DefaultRegUrl, '2026-11-21', '2026-11-21', '2026-11-01T09:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'NOTICE', N'OTHER',
         N'Old Books, Toys and Winter Apparel Donation for Underprivileged Schools',
         N'Annual student council community drive collecting gently used storybooks, stationery, and warm woolens for rural schools.',
         N'ALL', @DefaultRegUrl, '2026-12-15', '2026-12-22', '2026-12-01T09:00:00', N'PUBLISHED', N'ADMIN'),

        (3, N'NOTICE', N'OTHER',
         N'Parent-Teacher Executive Council (PTA) General Body Meeting',
         N'Discussing campus safety infrastructure, transport expansion, and academic enrichment initiatives in the school auditorium.',
         N'ALL', @DefaultRegUrl, '2026-09-19', '2026-09-19', '2026-09-05T10:30:00', N'PUBLISHED', N'ADMIN'),

        (4, N'NOTICE', N'OTHER',
         N'Campus Solar Rooftop Project & Carbon Footprint Milestone',
         N'School achieves 65% renewable energy transition with our newly commissioned 120kW rooftop solar array. Special assembly presentation.',
         N'ALL', NULL, '2026-10-05', '2026-10-05', '2026-09-25T09:00:00', N'PUBLISHED', N'ADMIN'),

        (4, N'NOTICE', N'OTHER',
         N'Cyber Safety & Digital Wellbeing Awareness Workshop for Parents',
         N'Cybercrime cell experts guiding parents on managing screen time, social media privacy settings, and gaming addiction signs.',
         N'ALL', @DefaultRegUrl, '2026-11-07', '2026-11-07', '2026-10-20T11:00:00', N'PUBLISHED', N'ADMIN'),

        (1, N'NOTICE', N'OTHER',
         N'Clean Campus Clean City: Swachhata Pakhwada Community March',
         N'Student volunteers leading clean-up and plastic-free advocacy rally in neighborhood market areas.',
         N'ALL', @DefaultRegUrl, '2026-10-02', '2026-10-02', '2026-09-18T08:00:00', N'PUBLISHED', N'ADMIN'),

        (2, N'NOTICE', N'OTHER',
         N'National Science Day Celebrations: Planetarium Mobile Dome Visit',
         N'Immersive 360-degree astronomy show inside an inflatable planetarium dome set up in the indoor gymnasium.',
         N'ALL', @DefaultRegUrl, '2027-02-28', '2027-02-28', '2027-02-10T09:00:00', N'PUBLISHED', N'ADMIN');

    -- =========================================================================
    -- 3. INSERT STAGED ANNOUNCEMENTS INTO management_schema.announcement
    -- =========================================================================
    INSERT INTO management_schema.announcement
    (
        school_id,
        branch_id,
        academic_year_id,
        announcement_type,
        sub_category,
        title,
        description,
        target_audience,
        registration_url,
        start_date,
        end_date,
        publish_at,
        status,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    SELECT
        b.school_id,
        s.branch_id,
        COALESCE(curr_ay.academic_year_id, any_ay.academic_year_id, 1) AS academic_year_id,
        s.announcement_type,
        s.sub_category,
        s.title,
        s.description,
        s.target_audience,
        s.registration_url,
        s.start_date,
        s.end_date,
        s.publish_at,
        s.status,
        1 AS is_active,
        s.publish_at AS created_at,
        CASE WHEN s.creator_type = N'ADMIN' THEN @AdminUserId1 ELSE @TeacherUserId1 END AS created_by,
        s.publish_at AS updated_at,
        CASE WHEN s.creator_type = N'ADMIN' THEN @AdminUserId2 ELSE @TeacherUserId2 END AS updated_by
    FROM @StagingAnnouncements s
    INNER JOIN management_schema.branch b
        ON b.branch_id = s.branch_id
    OUTER APPLY (
        SELECT TOP 1 ay.academic_year_id
        FROM management_schema.academic_year ay
        WHERE ay.school_id = b.school_id
          AND ay.is_current = 1
        ORDER BY ay.academic_year_id DESC
    ) curr_ay
    OUTER APPLY (
        SELECT TOP 1 ay.academic_year_id
        FROM management_schema.academic_year ay
        WHERE ay.school_id = b.school_id
        ORDER BY ay.academic_year_id DESC
    ) any_ay
    WHERE NOT EXISTS (
        SELECT 1
        FROM management_schema.announcement existing
        WHERE existing.title = s.title
    );

    DECLARE @InsertedCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'Successfully processed announcements. New rows inserted: ', @InsertedCount);

    -- =========================================================================
    -- 4. VERIFICATION BREAKDOWN BY CATEGORY & SUB-CATEGORY (SSMS OUTPUT)
    -- =========================================================================
    SELECT
        announcement_type,
        sub_category,
        COUNT(*) AS total_announcements,
        COUNT(registration_url) AS with_registration_url,
        MIN(publish_at) AS earliest_published,
        MAX(publish_at) AS latest_published
    FROM management_schema.announcement
    GROUP BY announcement_type, sub_category
    ORDER BY announcement_type, sub_category;

    SELECT
        COUNT(*) AS grand_total_announcements,
        COUNT(DISTINCT branch_id) AS branches_covered,
        COUNT(CASE WHEN sub_category = N'ALUMNI_EVENTS' THEN 1 END) AS total_alumni_events,
        COUNT(CASE WHEN sub_category = N'SPORTS' THEN 1 END) AS total_sports_events,
        COUNT(CASE WHEN sub_category = N'CULTURAL' THEN 1 END) AS total_cultural_events,
        COUNT(registration_url) AS total_with_registration_url
    FROM management_schema.announcement;

    COMMIT TRANSACTION;
    PRINT N'========================================================================';
    PRINT N'Announcement mock data seeding transaction committed successfully.';
    PRINT N'========================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO
