/*
    Script:    update_student_personality_development_review_add_category_and_rating.sql
    Module:    student_schema.student_personality_development_review
    Purpose:   1. Add columns 'category_type' and 'rating' to student_personality_development_review.
               2. Enforce CHECK constraints:
                  - category_type: LEADERSHIP_RATING, COMMUNICATION_RATING, COLLABORATION_RATING, RESPONSIBILITY_RATING (and aliases)
                  - rating: INT between 1 and 5 (1, 2, 3, 4, 5)
               3. Update unique constraint and covering indexes.
               4. Populate/seed 50+ realistic rows with perfect mappings across subjects, categories, ratings, and reviews.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'1. Updating student_personality_development_review Schema...';
PRINT N'========================================================================';

-- -----------------------------------------------------------------------------
-- 1. Ensure Table Exists
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'student_schema.student_personality_development_review', N'U') IS NULL
BEGIN
    PRINT N'Table does not exist. Creating student_schema.student_personality_development_review...';
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
        CONSTRAINT UQ_student_personality_dev_rev_session UNIQUE NONCLUSTERED
            (student_id, subject_id, teacher_id, category_type, review_date),

        CONSTRAINT CK_student_personality_dev_rev_text
            CHECK (LEN(LTRIM(RTRIM(review))) > 0),

        CONSTRAINT CK_student_personality_dev_rev_category
            CHECK (category_type IN (
                N'LEADERSHIP_RATING', N'COMMUNICATION_RATING', N'COLLABORATION_RATING', N'RESPONSIBILITY_RATING',
                N'LEADERSHIP', N'COMMUNICATION', N'COLLABORATION', N'RESPONSIBILITY'
            )),

        CONSTRAINT CK_student_personality_dev_rev_rating
            CHECK (rating >= 1 AND rating <= 5),

        CONSTRAINT FK_student_personality_dev_rev_school
            FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_personality_dev_rev_branch
            FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_personality_dev_rev_academic_year
            FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_personality_dev_rev_class
            FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_personality_dev_rev_section
            FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_personality_dev_rev_student
            FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_personality_dev_rev_teacher
            FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_student_personality_dev_rev_subject
            FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_student_personality_dev_rev_created_by
            FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_personality_dev_rev_updated_by
            FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
    PRINT N'Created table student_schema.student_personality_development_review successfully.';
END
ELSE
BEGIN
    PRINT N'Table student_schema.student_personality_development_review exists. Checking columns...';

    -- 1A. Add category_type column if missing
    IF COL_LENGTH(N'student_schema.student_personality_development_review', N'category_type') IS NULL
    BEGIN
        PRINT N'Adding category_type column...';
        ALTER TABLE student_schema.student_personality_development_review
            ADD category_type NVARCHAR(50) NOT NULL
                CONSTRAINT DF_student_personality_dev_rev_category DEFAULT (N'COMMUNICATION_RATING') WITH VALUES;

        ALTER TABLE student_schema.student_personality_development_review
            ADD CONSTRAINT CK_student_personality_dev_rev_category
                CHECK (category_type IN (
                    N'LEADERSHIP_RATING', N'COMMUNICATION_RATING', N'COLLABORATION_RATING', N'RESPONSIBILITY_RATING',
                    N'LEADERSHIP', N'COMMUNICATION', N'COLLABORATION', N'RESPONSIBILITY'
                ));
        PRINT N'Added category_type column and check constraint.';
    END
    ELSE
    BEGIN
        PRINT N'Column category_type already exists.';
    END;

    -- 1B. Add rating column if missing
    IF COL_LENGTH(N'student_schema.student_personality_development_review', N'rating') IS NULL
    BEGIN
        PRINT N'Adding rating column...';
        ALTER TABLE student_schema.student_personality_development_review
            ADD rating INT NOT NULL
                CONSTRAINT DF_student_personality_dev_rev_rating DEFAULT (4) WITH VALUES;

        ALTER TABLE student_schema.student_personality_development_review
            ADD CONSTRAINT CK_student_personality_dev_rev_rating
                CHECK (rating >= 1 AND rating <= 5);
        PRINT N'Added rating column and check constraint.';
    END
    ELSE
    BEGIN
        PRINT N'Column rating already exists.';
    END;

    -- 1C. Upgrade unique constraint UQ_student_personality_dev_rev_session to include category_type
    IF EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'UQ_student_personality_dev_rev_session'
          AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
    )
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM sys.index_columns ic
            INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
              AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'UQ_student_personality_dev_rev_session', 'IndexId')
              AND c.name = N'category_type'
        )
        BEGIN
            PRINT N'Upgrading unique constraint UQ_student_personality_dev_rev_session...';
            ALTER TABLE student_schema.student_personality_development_review
                DROP CONSTRAINT UQ_student_personality_dev_rev_session;

            ALTER TABLE student_schema.student_personality_development_review
                ADD CONSTRAINT UQ_student_personality_dev_rev_session UNIQUE NONCLUSTERED
                    (student_id, subject_id, teacher_id, category_type, review_date);
            PRINT N'Upgraded unique constraint UQ_student_personality_dev_rev_session.';
        END;
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- 2. Update Indexes to Include category_type and rating
-- -----------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
          AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'IX_student_personality_dev_rev_student_year', 'IndexId')
          AND c.name = N'category_type'
    )
    BEGIN
        DROP INDEX IX_student_personality_dev_rev_student_year 
            ON student_schema.student_personality_development_review;
    END;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_student_year
        ON student_schema.student_personality_development_review (student_id, academic_year_id)
        INCLUDE (subject_id, teacher_id, category_type, rating, review_date)
        WHERE is_active = 1;
    PRINT N'Updated index IX_student_personality_dev_rev_student_year.';
END;
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_subject_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
          AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'IX_student_personality_dev_rev_student_subject_year', 'IndexId')
          AND c.name = N'category_type'
    )
    BEGIN
        DROP INDEX IX_student_personality_dev_rev_student_subject_year 
            ON student_schema.student_personality_development_review;
    END;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_subject_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_student_subject_year
        ON student_schema.student_personality_development_review (student_id, subject_id, academic_year_id)
        INCLUDE (teacher_id, category_type, rating, review_date)
        WHERE is_active = 1;
    PRINT N'Updated index IX_student_personality_dev_rev_student_subject_year.';
END;
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_teacher_subject'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
          AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'IX_student_personality_dev_rev_teacher_subject', 'IndexId')
          AND c.name = N'category_type'
    )
    BEGIN
        DROP INDEX IX_student_personality_dev_rev_teacher_subject 
            ON student_schema.student_personality_development_review;
    END;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_teacher_subject'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_teacher_subject
        ON student_schema.student_personality_development_review (teacher_id, subject_id, review_date)
        INCLUDE (student_id, category_type, rating)
        WHERE is_active = 1;
    PRINT N'Updated index IX_student_personality_dev_rev_teacher_subject.';
END;
GO

-- =============================================================================
-- 3. SEED 50+ ROWS OF MOCK DATA WITH PERFECT MAPPINGS
-- =============================================================================
PRINT N'========================================================================';
PRINT N'2. Seeding 50+ Reviews with Category Types & Ratings (1 to 5)...';
PRINT N'========================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @AdminUserId BIGINT = (SELECT TOP 1 user_id FROM security_schema.users WHERE user_type = N'ADMIN' ORDER BY user_id ASC);
    IF @AdminUserId IS NULL
        SET @AdminUserId = (SELECT TOP 1 user_id FROM security_schema.users ORDER BY user_id ASC);

    -- Category Templates with Perfect Mappings
    DECLARE @CategoryReviewCatalog TABLE
    (
        category_type NVARCHAR(50),
        subject_name  NVARCHAR(100),
        rating_score  INT,
        review_text   NVARCHAR(MAX)
    );

    INSERT INTO @CategoryReviewCatalog (category_type, subject_name, rating_score, review_text)
    VALUES
    -- Leadership Rating Mappings
    (N'LEADERSHIP_RATING', N'Mathematics', 5, N'Demonstrates exemplary leadership by leading math olympiad study groups and mentoring peers through complex calculus and proofs.'),
    (N'LEADERSHIP_RATING', N'Science',     4, N'Takes initiative as lead investigator during physics and chemistry laboratory investigations, ensuring strict safety and methodical execution.'),
    (N'LEADERSHIP_RATING', N'Computer Science', 5, N'Spearheads team software projects, coordinates modular coding sprints, and mentors junior students in algorithm optimization.'),
    (N'LEADERSHIP_RATING', N'Social Science', 4, N'Serves as chief delegate in Model UN simulations, steering diplomatic resolutions and inspiring active committee participation.'),
    (N'LEADERSHIP_RATING', N'English',     3, N'Demonstrates growing confidence when moderating parliamentary debates; continues to develop command over group dynamics.'),

    -- Communication Rating Mappings
    (N'COMMUNICATION_RATING', N'English',     5, N'Exceptional articulation in persuasive essays, creative literary expression, and compelling oratorical delivery during elocution events.'),
    (N'COMMUNICATION_RATING', N'Social Science', 5, N'Articulates historical causes and modern geopolitical concepts with remarkable clarity, precision, and contextual depth.'),
    (N'COMMUNICATION_RATING', N'Science',     4, N'Communicates experimental findings and laboratory hypotheses with structured technical vocabulary and well-drafted summaries.'),
    (N'COMMUNICATION_RATING', N'Mathematics', 4, N'Explains step-by-step problem-solving logic clearly to the class, making complex theorems accessible to peers.'),
    (N'COMMUNICATION_RATING', N'Computer Science', 4, N'Documents codebases cleanly with lucid comments and gives articulate technical walk-throughs of system architecture.'),

    -- Collaboration Rating Mappings
    (N'COLLABORATION_RATING', N'Science',     5, N'Outstanding team player in experimental chemistry modules; actively values partner insights and shares bench responsibilities smoothly.'),
    (N'COLLABORATION_RATING', N'Computer Science', 5, N'Contributes effectively to group Git repositories, conducts constructive peer code reviews, and fosters inclusive team morale.'),
    (N'COLLABORATION_RATING', N'Social Science', 4, N'Collaborates enthusiastically on inter-disciplinary history exhibits, respecting diverse viewpoints and harmonizing group efforts.'),
    (N'COLLABORATION_RATING', N'Mathematics', 4, N'Engages productively during collaborative problem sprints, listening attentively to different problem-solving approaches.'),
    (N'COLLABORATION_RATING', N'English',     4, N'Works seamlessly in collaborative play reading and drama adaptations, encouraging shy group members to participate.'),

    -- Responsibility Rating Mappings
    (N'RESPONSIBILITY_RATING', N'Mathematics', 5, N'Consistently submits comprehensive analytical homework well ahead of deadlines; demonstrates exceptional personal discipline.'),
    (N'RESPONSIBILITY_RATING', N'Science',     5, N'Exhibits high academic integrity, meticulous maintenance of laboratory record books, and conscientious equipment care.'),
    (N'RESPONSIBILITY_RATING', N'Computer Science', 4, N'Reliably delivers bug-free project submissions, adheres strictly to deadlines, and follows best coding practices.'),
    (N'RESPONSIBILITY_RATING', N'English',     4, N'Shows steady commitment to reading assignments, thorough essay revisions, and dependable classroom preparation.'),
    (N'RESPONSIBILITY_RATING', N'Social Science', 4, N'Takes conscientious ownership of research projects, cross-references primary historical sources, and meets every milestone.');

    -- Generate Cartesian permutations for all active students with subjects & categories
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
            -- Slight variation in rating (1-5) based on student sequence while keeping it realistic
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

    DECLARE @InsertedCount INT = @@ROWCOUNT;
    COMMIT TRANSACTION;

    PRINT N'========================================================================';
    PRINT CONCAT(N'SUCCESS: Seeded ', @InsertedCount, N' new reviews with category_type and ratings.');
    PRINT N'========================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    DECLARE @ErrLine INT = ERROR_LINE();

    PRINT CONCAT(N'ERROR on line ', @ErrLine, N': ', @ErrMsg);
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO

-- =============================================================================
-- 4. VERIFICATION AUDIT QUERIES
-- =============================================================================
PRINT N'';
PRINT N'------------------------------------------------------------------------';
PRINT N'AUDIT REPORT: student_personality_development_review';
PRINT N'------------------------------------------------------------------------';

-- A. Total row count & target check (>= 50 rows)
SELECT 
    COUNT(1) AS total_review_records,
    COUNT(DISTINCT student_id) AS total_students_reviewed,
    COUNT(DISTINCT subject_id) AS distinct_subjects,
    COUNT(DISTINCT teacher_id) AS distinct_teachers,
    AVG(CAST(rating AS DECIMAL(3, 2))) AS average_rating,
    CASE WHEN COUNT(1) >= 50 THEN N'PASS (>= 50 rows)' ELSE N'WARNING (< 50 rows)' END AS row_target_status
FROM student_schema.student_personality_development_review
WHERE is_active = 1;

-- B. Breakdown by Category Type
SELECT 
    category_type,
    COUNT(1) AS total_reviews,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(CAST(rating AS DECIMAL(3, 2))) AS avg_rating
FROM student_schema.student_personality_development_review
WHERE is_active = 1
GROUP BY category_type
ORDER BY total_reviews DESC;

-- C. Breakdown by Rating (1, 2, 3, 4, 5)
SELECT 
    rating,
    COUNT(1) AS frequency,
    CONCAT(CAST(COUNT(1) * 100.0 / (SELECT COUNT(1) FROM student_schema.student_personality_development_review WHERE is_active = 1) AS DECIMAL(5, 1)), N'%') AS share_percentage
FROM student_schema.student_personality_development_review
WHERE is_active = 1
GROUP BY rating
ORDER BY rating DESC;

-- D. Sample Top 10 Preview
SELECT TOP 10
    r.personality_review_id,
    CONCAT(s.first_name, N' ', COALESCE(s.last_name, N'')) AS student_name,
    sc.class_name,
    sec.section_name,
    sub.subject_name,
    r.category_type,
    r.rating,
    SUBSTRING(r.review, 1, 60) + N'...' AS review_snippet,
    r.review_date,
    CONCAT(t.first_name, N' ', t.last_name) AS teacher_name
FROM student_schema.student_personality_development_review r
INNER JOIN student_schema.student s ON s.student_id = r.student_id
INNER JOIN management_schema.school_class sc ON sc.class_id = r.class_id
INNER JOIN management_schema.section sec ON sec.section_id = r.section_id
INNER JOIN management_schema.subject sub ON sub.subject_id = r.subject_id
INNER JOIN teachers_schema.teacher t ON t.teacher_id = r.teacher_id
WHERE r.is_active = 1
ORDER BY r.personality_review_id DESC;
GO
