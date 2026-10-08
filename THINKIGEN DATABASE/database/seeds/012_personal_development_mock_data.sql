/*
    Script:    012_personal_development_mock_data.sql
    Module:    022_personal_development / student_schema
    Purpose:   Self-contained, bulletproof mock data and validation queries for:
               1. student_schema.student_personality_development (Class Teacher ratings)
               2. student_schema.student_personality_development_review (Subject Teacher reviews)

    Fixes applied:
    - Auto-creates target tables if not already executed via migration.
    - Uses EXACT subject matching (s.subject_name = srt.subject_name) to prevent
      partial LIKE overlap between 'Science', 'Social Science', and 'Computer Science'.
    - Enforces window-function deduplication on unique constraints:
      * UQ_student_personality_dev_student_year (student_id, academic_year_id)
      * UQ_student_personality_dev_rev_session (student_id, subject_id, teacher_id, review_date)
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Seeding Mock Data for Personal Development Module...';
PRINT N'========================================================================';

-- =============================================================================
-- 0. DEFENSIVE DDL: ENSURE TARGET TABLES EXIST
-- =============================================================================
IF OBJECT_ID(N'student_schema.student_personality_development', N'U') IS NULL
BEGIN
    PRINT N'Creating student_schema.student_personality_development table...';
    CREATE TABLE student_schema.student_personality_development
    (
        personality_development_id BIGINT          NOT NULL IDENTITY(1, 1),
        school_id                  BIGINT          NOT NULL,
        branch_id                  BIGINT          NOT NULL,
        academic_year_id           BIGINT          NOT NULL,
        class_id                   BIGINT          NOT NULL,
        section_id                 BIGINT          NOT NULL,
        student_id                 BIGINT          NOT NULL,
        class_teacher_id           BIGINT          NOT NULL,
        leadership_rating          DECIMAL(3, 2)   NULL,
        communication_rating       DECIMAL(3, 2)   NULL,
        collaboration_rating       DECIMAL(3, 2)   NULL,
        responsibility_rating      DECIMAL(3, 2)   NULL,
        overall_rating             DECIMAL(3, 2)   NULL,
        is_active                  BIT             NOT NULL CONSTRAINT DF_student_personality_dev_is_active DEFAULT (1),
        created_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_student_personality_dev_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                 BIGINT          NOT NULL,
        updated_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_student_personality_dev_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                 BIGINT          NULL,
        row_version                ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_personality_development PRIMARY KEY CLUSTERED (personality_development_id),
        CONSTRAINT UQ_student_personality_dev_student_year UNIQUE NONCLUSTERED (student_id, academic_year_id),
        CONSTRAINT CK_student_personality_dev_leadership CHECK (leadership_rating IS NULL OR (leadership_rating >= 0.00 AND leadership_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_communication CHECK (communication_rating IS NULL OR (communication_rating >= 0.00 AND communication_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_collaboration CHECK (collaboration_rating IS NULL OR (collaboration_rating >= 0.00 AND collaboration_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_responsibility CHECK (responsibility_rating IS NULL OR (responsibility_rating >= 0.00 AND responsibility_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_overall CHECK (overall_rating IS NULL OR (overall_rating >= 0.00 AND overall_rating <= 5.00)),
        CONSTRAINT FK_student_personality_dev_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_personality_dev_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_personality_dev_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_personality_dev_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_personality_dev_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_personality_dev_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_personality_dev_class_teacher FOREIGN KEY (class_teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_student_personality_dev_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_personality_dev_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;

IF OBJECT_ID(N'student_schema.student_personality_development_review', N'U') IS NULL
BEGIN
    PRINT N'Creating student_schema.student_personality_development_review table...';
    CREATE TABLE student_schema.student_personality_development_review
    (
        personality_review_id      BIGINT          NOT NULL IDENTITY(1, 1),
        school_id                  BIGINT          NOT NULL,
        branch_id                  BIGINT          NOT NULL,
        academic_year_id           BIGINT          NOT NULL,
        class_id                   BIGINT          NOT NULL,
        section_id                 BIGINT          NOT NULL,
        student_id                 BIGINT          NOT NULL,
        teacher_id                 BIGINT          NOT NULL,
        subject_id                 BIGINT          NOT NULL,
        category_type              NVARCHAR(50)    NOT NULL,
        rating                     INT             NOT NULL,
        review                     NVARCHAR(MAX)   NOT NULL,
        review_date                DATE            NOT NULL,
        is_active                  BIT             NOT NULL CONSTRAINT DF_student_personality_dev_rev_is_active DEFAULT (1),
        created_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_student_personality_dev_rev_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                 BIGINT          NOT NULL,
        updated_at                 DATETIME2(0)    NOT NULL CONSTRAINT DF_student_personality_dev_rev_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                 BIGINT          NULL,
        row_version                ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_personality_development_review PRIMARY KEY CLUSTERED (personality_review_id),
        CONSTRAINT UQ_student_personality_dev_rev_session UNIQUE NONCLUSTERED (student_id, subject_id, teacher_id, category_type, review_date),
        CONSTRAINT CK_student_personality_dev_rev_text CHECK (LEN(LTRIM(RTRIM(review))) > 0),
        CONSTRAINT CK_student_personality_dev_rev_category CHECK (category_type IN (
            N'LEADERSHIP_RATING', N'COMMUNICATION_RATING', N'COLLABORATION_RATING', N'RESPONSIBILITY_RATING',
            N'LEADERSHIP', N'COMMUNICATION', N'COLLABORATION', N'RESPONSIBILITY'
        )),
        CONSTRAINT CK_student_personality_dev_rev_rating CHECK (rating >= 1 AND rating <= 5),
        CONSTRAINT FK_student_personality_dev_rev_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_personality_dev_rev_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_personality_dev_rev_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_personality_dev_rev_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_personality_dev_rev_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_personality_dev_rev_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_personality_dev_rev_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_student_personality_dev_rev_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_student_personality_dev_rev_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_personality_dev_rev_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END
ELSE
BEGIN
    IF COL_LENGTH(N'student_schema.student_personality_development_review', N'category_type') IS NULL
    BEGIN
        ALTER TABLE student_schema.student_personality_development_review
            ADD category_type NVARCHAR(50) NOT NULL
                CONSTRAINT DF_student_personality_dev_rev_category DEFAULT (N'COMMUNICATION_RATING') WITH VALUES;
        ALTER TABLE student_schema.student_personality_development_review
            ADD CONSTRAINT CK_student_personality_dev_rev_category CHECK (category_type IN (
                N'LEADERSHIP_RATING', N'COMMUNICATION_RATING', N'COLLABORATION_RATING', N'RESPONSIBILITY_RATING',
                N'LEADERSHIP', N'COMMUNICATION', N'COLLABORATION', N'RESPONSIBILITY'
            ));
    END;

    IF COL_LENGTH(N'student_schema.student_personality_development_review', N'rating') IS NULL
    BEGIN
        ALTER TABLE student_schema.student_personality_development_review
            ADD rating INT NOT NULL
                CONSTRAINT DF_student_personality_dev_rev_rating DEFAULT (4) WITH VALUES;
        ALTER TABLE student_schema.student_personality_development_review
            ADD CONSTRAINT CK_student_personality_dev_rev_rating CHECK (rating >= 1 AND rating <= 5);
    END;
END;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Resolve Admin User ID for Audit
    DECLARE @AdminUserId BIGINT = (SELECT TOP 1 user_id FROM security_schema.users WHERE user_type = N'ADMIN' ORDER BY user_id ASC);
    IF @AdminUserId IS NULL
        SET @AdminUserId = (SELECT TOP 1 user_id FROM security_schema.users ORDER BY user_id ASC);

    IF @AdminUserId IS NULL
    BEGIN
        RAISERROR(N'No users found in security_schema.users. Seed users first.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- =========================================================================
    -- 2. SEED CLASS TEACHER PERSONALITY RATINGS (student_personality_development)
    -- =========================================================================
    ;WITH RawClassTeacherSource AS (
        SELECT
            st.student_id,
            st.school_id,
            st.branch_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            COALESCE(
                teacher_match.teacher_id,
                (SELECT TOP 1 teacher_id FROM teachers_schema.teacher WHERE school_id = st.school_id ORDER BY teacher_id ASC)
            ) AS class_teacher_id
        FROM student_schema.student st
        OUTER APPLY (
            SELECT TOP 1 scta.teacher_id
            FROM teachers_schema.section_class_teacher_assignment scta
            WHERE scta.school_id = st.school_id
              AND scta.branch_id = st.branch_id
              AND scta.academic_year_id = st.academic_year_id
              AND scta.class_id = st.class_id
              AND scta.section_id = st.section_id
              AND scta.is_active = 1
            ORDER BY scta.section_class_teacher_assignment_id DESC
        ) teacher_match
        WHERE st.is_active = 1
    ),
    DeduplicatedClassTeacherSource AS (
        SELECT
            r.*,
            ROW_NUMBER() OVER (
                PARTITION BY r.student_id, r.academic_year_id
                ORDER BY r.student_id ASC
            ) AS rn
        FROM RawClassTeacherSource r
    )
    INSERT INTO student_schema.student_personality_development
    (
        school_id,
        branch_id,
        academic_year_id,
        class_id,
        section_id,
        student_id,
        class_teacher_id,
        leadership_rating,
        communication_rating,
        collaboration_rating,
        responsibility_rating,
        overall_rating,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    SELECT
        cts.school_id,
        cts.branch_id,
        cts.academic_year_id,
        cts.class_id,
        cts.section_id,
        cts.student_id,
        cts.class_teacher_id,
        ratings.leadership_rating,
        ratings.communication_rating,
        ratings.collaboration_rating,
        ratings.responsibility_rating,
        ratings.overall_rating,
        1 AS is_active,
        SYSUTCDATETIME() AS created_at,
        COALESCE(t.user_id, @AdminUserId) AS created_by,
        SYSUTCDATETIME() AS updated_at,
        COALESCE(t.user_id, @AdminUserId) AS updated_by
    FROM DeduplicatedClassTeacherSource cts
    LEFT JOIN teachers_schema.teacher t
        ON t.teacher_id = cts.class_teacher_id
    CROSS APPLY (
        SELECT
            CAST(3.20 + ((cts.student_id * 13) % 17) * 0.10 AS DECIMAL(3, 2)) AS leadership_rating,
            CAST(3.50 + ((cts.student_id * 7) % 15) * 0.10 AS DECIMAL(3, 2)) AS communication_rating,
            CAST(3.00 + ((cts.student_id * 19) % 19) * 0.10 AS DECIMAL(3, 2)) AS collaboration_rating,
            CAST(3.40 + ((cts.student_id * 23) % 15) * 0.10 AS DECIMAL(3, 2)) AS responsibility_rating,
            CAST(3.50 + ((cts.student_id * 11) % 14) * 0.10 AS DECIMAL(3, 2)) AS overall_rating
    ) ratings
    WHERE cts.rn = 1
      AND NOT EXISTS (
        SELECT 1
        FROM student_schema.student_personality_development existing
        WHERE existing.student_id = cts.student_id
          AND existing.academic_year_id = cts.academic_year_id
    );

    DECLARE @DevCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'Seeded student_personality_development rows: ', @DevCount);

    -- =========================================================================
    -- 3. SEED SUBJECT-BASED PERFORMANCE REVIEWS (student_personality_development_review)
    -- =========================================================================
    DECLARE @CategoryReviewCatalog TABLE
    (
        category_type NVARCHAR(50),
        subject_name  NVARCHAR(100),
        rating_score  INT,
        review_text   NVARCHAR(MAX)
    );

    INSERT INTO @CategoryReviewCatalog (category_type, subject_name, rating_score, review_text)
    VALUES
    (N'LEADERSHIP_RATING', N'Mathematics', 5, N'Demonstrates exemplary leadership by leading math olympiad study groups and mentoring peers through complex calculus and proofs.'),
    (N'LEADERSHIP_RATING', N'Science',     4, N'Takes initiative as lead investigator during physics and chemistry laboratory investigations, ensuring strict safety and methodical execution.'),
    (N'LEADERSHIP_RATING', N'Computer Science', 5, N'Spearheads team software projects, coordinates modular coding sprints, and mentors junior students in algorithm optimization.'),
    (N'LEADERSHIP_RATING', N'Social Science', 4, N'Serves as chief delegate in Model UN simulations, steering diplomatic resolutions and inspiring active committee participation.'),
    (N'LEADERSHIP_RATING', N'English',     3, N'Demonstrates growing confidence when moderating parliamentary debates; continues to develop command over group dynamics.'),

    (N'COMMUNICATION_RATING', N'English',     5, N'Exceptional articulation in persuasive essays, creative literary expression, and compelling oratorical delivery during elocution events.'),
    (N'COMMUNICATION_RATING', N'Social Science', 5, N'Articulates historical causes and modern geopolitical concepts with remarkable clarity, precision, and contextual depth.'),
    (N'COMMUNICATION_RATING', N'Science',     4, N'Communicates experimental findings and laboratory hypotheses with structured technical vocabulary and well-drafted summaries.'),
    (N'COMMUNICATION_RATING', N'Mathematics', 4, N'Explains step-by-step problem-solving logic clearly to the class, making complex theorems accessible to peers.'),
    (N'COMMUNICATION_RATING', N'Computer Science', 4, N'Documents codebases cleanly with lucid comments and gives articulate technical walk-throughs of system architecture.'),

    (N'COLLABORATION_RATING', N'Science',     5, N'Outstanding team player in experimental chemistry modules; actively values partner insights and shares bench responsibilities smoothly.'),
    (N'COLLABORATION_RATING', N'Computer Science', 5, N'Contributes effectively to group Git repositories, conducts constructive peer code reviews, and fosters inclusive team morale.'),
    (N'COLLABORATION_RATING', N'Social Science', 4, N'Collaborates enthusiastically on inter-disciplinary history exhibits, respecting diverse viewpoints and harmonizing group efforts.'),
    (N'COLLABORATION_RATING', N'Mathematics', 4, N'Engages productively during collaborative problem sprints, listening attentively to different problem-solving approaches.'),
    (N'COLLABORATION_RATING', N'English',     4, N'Works seamlessly in collaborative play reading and drama adaptations, encouraging shy group members to participate.'),

    (N'RESPONSIBILITY_RATING', N'Mathematics', 5, N'Consistently submits comprehensive analytical homework well ahead of deadlines; demonstrates exceptional personal discipline.'),
    (N'RESPONSIBILITY_RATING', N'Science',     5, N'Exhibits high academic integrity, meticulous maintenance of laboratory record books, and conscientious equipment care.'),
    (N'RESPONSIBILITY_RATING', N'Computer Science', 4, N'Reliably delivers bug-free project submissions, adheres strictly to deadlines, and follows best coding practices.'),
    (N'RESPONSIBILITY_RATING', N'English',     4, N'Shows steady commitment to reading assignments, thorough essay revisions, and dependable classroom preparation.'),
    (N'RESPONSIBILITY_RATING', N'Social Science', 4, N'Takes conscientious ownership of research projects, cross-references primary historical sources, and meets every milestone.');

    ;WITH StudentPool AS (
        SELECT 
            s.student_id,
            s.school_id,
            s.branch_id,
            s.academic_year_id,
            s.class_id,
            s.section_id,
            ROW_NUMBER() OVER (ORDER BY s.student_id ASC) AS student_seq
        FROM student_schema.student s
        WHERE s.is_active = 1
    ),
    SubjectTeacherPool AS (
        SELECT 
            sub.subject_id,
            sub.subject_name,
            sub.school_id,
            COALESCE(
                tsa.teacher_id,
                (SELECT TOP 1 t.teacher_id FROM teachers_schema.teacher t WHERE t.school_id = sub.school_id ORDER BY t.teacher_id ASC),
                (SELECT TOP 1 t.teacher_id FROM teachers_schema.teacher t ORDER BY t.teacher_id ASC)
            ) AS teacher_id
        FROM management_schema.subject sub
        OUTER APPLY (
            SELECT TOP 1 t.teacher_id
            FROM teachers_schema.teacher_subject_assignment tsa
            INNER JOIN teachers_schema.teacher t ON t.teacher_id = tsa.teacher_id
            WHERE tsa.subject_id = sub.subject_id
              AND tsa.is_active = 1
            ORDER BY tsa.teacher_subject_assignment_id ASC
        ) tsa
        WHERE sub.is_active = 1
    ),
    Candidates AS (
        SELECT 
            sp.student_id,
            sp.school_id,
            sp.branch_id,
            sp.academic_year_id,
            sp.class_id,
            sp.section_id,
            stp.teacher_id,
            stp.subject_id,
            cat.category_type,
            CASE 
                WHEN (sp.student_seq + cat.rating_score) % 5 = 0 THEN 5
                WHEN (sp.student_seq + cat.rating_score) % 5 = 1 THEN 4
                WHEN (sp.student_seq + cat.rating_score) % 5 = 2 THEN 3
                WHEN (sp.student_seq + cat.rating_score) % 5 = 3 THEN 4
                ELSE cat.rating_score
            END AS calculated_rating,
            cat.review_text,
            DATEADD(DAY, -((sp.student_seq * 3) % 45), CAST('2026-09-15' AS DATE)) AS review_date,
            ROW_NUMBER() OVER (
                PARTITION BY sp.student_id, stp.subject_id, stp.teacher_id, cat.category_type, CAST('2026-09-15' AS DATE)
                ORDER BY sp.student_id
            ) AS deduplication_rn
        FROM StudentPool sp
        CROSS JOIN @CategoryReviewCatalog cat
        INNER JOIN SubjectTeacherPool stp 
            ON stp.school_id = sp.school_id 
           AND stp.subject_name = cat.subject_name
    )
    INSERT INTO student_schema.student_personality_development_review
    (
        school_id,
        branch_id,
        academic_year_id,
        class_id,
        section_id,
        student_id,
        teacher_id,
        subject_id,
        category_type,
        rating,
        review,
        review_date,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    SELECT 
        c.school_id,
        c.branch_id,
        c.academic_year_id,
        c.class_id,
        c.section_id,
        c.student_id,
        c.teacher_id,
        c.subject_id,
        c.category_type,
        c.calculated_rating,
        c.review_text,
        c.review_date,
        1 AS is_active,
        SYSUTCDATETIME() AS created_at,
        COALESCE(t.user_id, @AdminUserId) AS created_by,
        SYSUTCDATETIME() AS updated_at,
        COALESCE(t.user_id, @AdminUserId) AS updated_by
    FROM Candidates c
    LEFT JOIN teachers_schema.teacher t 
        ON t.teacher_id = c.teacher_id
    WHERE c.deduplication_rn = 1
      AND NOT EXISTS (
          SELECT 1 
          FROM student_schema.student_personality_development_review existing
          WHERE existing.student_id = c.student_id
            AND existing.subject_id = c.subject_id
            AND existing.teacher_id = c.teacher_id
            AND existing.category_type = c.category_type
            AND existing.review_date = c.review_date
      );

    DECLARE @RevCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'Seeded student_personality_development_review rows: ', @RevCount);

    COMMIT TRANSACTION;
    PRINT N'========================================================================';
    PRINT N'Personal Development mock data transaction committed successfully.';
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

-- =============================================================================
-- 4. VALIDATION QUERIES
-- =============================================================================

-- Validation 1: Student Class Teacher Ratings Overview
SELECT TOP 10
    spd.personality_development_id,
    st.admission_number,
    CONCAT(st.first_name, N' ', COALESCE(st.last_name, N'')) AS student_name,
    CONCAT(ct.first_name, N' ', COALESCE(ct.last_name, N'')) AS class_teacher,
    sc.class_name,
    sec.section_name,
    spd.leadership_rating,
    spd.communication_rating,
    spd.collaboration_rating,
    spd.responsibility_rating,
    spd.overall_rating
FROM student_schema.student_personality_development spd
INNER JOIN student_schema.student st ON st.student_id = spd.student_id
INNER JOIN teachers_schema.teacher ct ON ct.teacher_id = spd.class_teacher_id
INNER JOIN management_schema.school_class sc ON sc.class_id = spd.class_id
INNER JOIN management_schema.section sec ON sec.section_id = spd.section_id
ORDER BY spd.student_id;

-- Validation 2: Subject-Based Teacher Reviews for Students
SELECT TOP 15
    spdr.personality_review_id,
    st.admission_number,
    CONCAT(st.first_name, N' ', COALESCE(st.last_name, N'')) AS student_name,
    sub.subject_name,
    spdr.category_type,
    spdr.rating,
    CONCAT(t.first_name, N' ', COALESCE(t.last_name, N'')) AS reviewing_teacher,
    spdr.review_date,
    spdr.review
FROM student_schema.student_personality_development_review spdr
INNER JOIN student_schema.student st ON st.student_id = spdr.student_id
INNER JOIN management_schema.subject sub ON sub.subject_id = spdr.subject_id
INNER JOIN teachers_schema.teacher t ON t.teacher_id = spdr.teacher_id
ORDER BY spdr.student_id, sub.subject_name;

-- Validation 3: Check Constraint Integrity Verification (Should return 0 invalid rows)
SELECT
    personality_development_id,
    student_id,
    leadership_rating,
    communication_rating,
    collaboration_rating,
    responsibility_rating,
    overall_rating
FROM student_schema.student_personality_development
WHERE (leadership_rating < 0.00 OR leadership_rating > 5.00)
   OR (communication_rating < 0.00 OR communication_rating > 5.00)
   OR (collaboration_rating < 0.00 OR collaboration_rating > 5.00)
   OR (responsibility_rating < 0.00 OR responsibility_rating > 5.00)
   OR (overall_rating < 0.00 OR overall_rating > 5.00);
GO
