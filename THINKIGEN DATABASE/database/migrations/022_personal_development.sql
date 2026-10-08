/*
    Migration: 022_personal_development.sql
    Module:    Personal Development (student_schema)
    Purpose:   Store official student personality development ratings maintained by
               Class Teachers, and subject-based qualitative reviews written by teachers.

    Design Notes:
    - student_schema.student_personality_development:
      * Maintained by student's Class Teacher.
      * Ratings: leadership, communication, collaboration, responsibility, overall (0.00 to 5.00 scale).
      * Unique per (student_id, academic_year_id).
    - student_schema.student_personality_development_review:
      * Subject-based qualitative evaluations written by respective subject teachers.
      * Supports multiple reviews across subjects and review dates.
      * No separate development area or review master catalog tables.
      * Zero percentage or calculation logic in the database (handled in backend).

    Rollback:
    - DROP TABLE IF EXISTS student_schema.student_personality_development_review;
    - DROP TABLE IF EXISTS student_schema.student_personality_development;
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Creating Personal Development Module Tables in student_schema...';
PRINT N'========================================================================';

-- =============================================================================
-- 1. TABLE: student_schema.student_personality_development
-- =============================================================================
IF OBJECT_ID(N'student_schema.student_personality_development', N'U') IS NULL
BEGIN
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

        CONSTRAINT CK_student_personality_dev_leadership
            CHECK (leadership_rating IS NULL OR (leadership_rating >= 0.00 AND leadership_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_communication
            CHECK (communication_rating IS NULL OR (communication_rating >= 0.00 AND communication_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_collaboration
            CHECK (collaboration_rating IS NULL OR (collaboration_rating >= 0.00 AND collaboration_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_responsibility
            CHECK (responsibility_rating IS NULL OR (responsibility_rating >= 0.00 AND responsibility_rating <= 5.00)),
        CONSTRAINT CK_student_personality_dev_overall
            CHECK (overall_rating IS NULL OR (overall_rating >= 0.00 AND overall_rating <= 5.00)),

        CONSTRAINT FK_student_personality_dev_school
            FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_personality_dev_branch
            FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_personality_dev_academic_year
            FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_personality_dev_class
            FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_personality_dev_section
            FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_personality_dev_student
            FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_personality_dev_class_teacher
            FOREIGN KEY (class_teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_student_personality_dev_created_by
            FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_personality_dev_updated_by
            FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );

    PRINT N'Created table student_schema.student_personality_development successfully.';
END
ELSE
BEGIN
    PRINT N'Table student_schema.student_personality_development already exists. Skipping creation.';
END;
GO

-- Indexes for student_personality_development
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_student_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_personality_dev_student_year
        ON student_schema.student_personality_development (student_id, academic_year_id)
        INCLUDE (class_teacher_id, overall_rating)
        WHERE is_active = 1;
    PRINT N'Created index IX_student_personality_dev_student_year.';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_scope'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_personality_dev_scope
        ON student_schema.student_personality_development (school_id, branch_id, academic_year_id, class_id, section_id)
        WHERE is_active = 1;
    PRINT N'Created index IX_student_personality_dev_scope.';
END;
GO


-- =============================================================================
-- 2. TABLE: student_schema.student_personality_development_review
-- =============================================================================
IF OBJECT_ID(N'student_schema.student_personality_development_review', N'U') IS NULL
BEGIN
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
    PRINT N'Table student_schema.student_personality_development_review already exists.';

    -- Idempotent check: Add category_type if missing
    IF COL_LENGTH(N'student_schema.student_personality_development_review', N'category_type') IS NULL
    BEGIN
        PRINT N'Adding category_type column to student_personality_development_review...';
        EXEC sp_executesql N'
            ALTER TABLE student_schema.student_personality_development_review
                ADD category_type NVARCHAR(50) NOT NULL
                    CONSTRAINT DF_student_personality_dev_rev_category DEFAULT (N''COMMUNICATION_RATING'') WITH VALUES;

            ALTER TABLE student_schema.student_personality_development_review
                ADD CONSTRAINT CK_student_personality_dev_rev_category
                    CHECK (category_type IN (
                        N''LEADERSHIP_RATING'', N''COMMUNICATION_RATING'', N''COLLABORATION_RATING'', N''RESPONSIBILITY_RATING'',
                        N''LEADERSHIP'', N''COMMUNICATION'', N''COLLABORATION'', N''RESPONSIBILITY''
                    ));
        ';
        PRINT N'Added category_type column and check constraint.';
    END;

    -- Idempotent check: Add rating if missing
    IF COL_LENGTH(N'student_schema.student_personality_development_review', N'rating') IS NULL
    BEGIN
        PRINT N'Adding rating column to student_personality_development_review...';
        EXEC sp_executesql N'
            ALTER TABLE student_schema.student_personality_development_review
                ADD rating INT NOT NULL
                    CONSTRAINT DF_student_personality_dev_rev_rating DEFAULT (4) WITH VALUES;

            ALTER TABLE student_schema.student_personality_development_review
                ADD CONSTRAINT CK_student_personality_dev_rev_rating
                    CHECK (rating >= 1 AND rating <= 5);
        ';
        PRINT N'Added rating column and check constraint.';
    END;

    -- Idempotent check: Upgrade UQ_student_personality_dev_rev_session to include category_type
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
            PRINT N'Upgrading unique constraint UQ_student_personality_dev_rev_session to include category_type...';
            EXEC sp_executesql N'
                ALTER TABLE student_schema.student_personality_development_review
                    DROP CONSTRAINT UQ_student_personality_dev_rev_session;

                ALTER TABLE student_schema.student_personality_development_review
                    ADD CONSTRAINT UQ_student_personality_dev_rev_session UNIQUE NONCLUSTERED
                        (student_id, subject_id, teacher_id, category_type, review_date);
            ';
            PRINT N'Upgraded unique constraint UQ_student_personality_dev_rev_session.';
        END;
    END;
END;
GO

-- Indexes for student_personality_development_review
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
    EXEC sp_executesql N'
        CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_student_year
            ON student_schema.student_personality_development_review (student_id, academic_year_id)
            INCLUDE (subject_id, teacher_id, category_type, rating, review_date)
            WHERE is_active = 1;
    ';
    PRINT N'Created index IX_student_personality_dev_rev_student_year.';
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
    EXEC sp_executesql N'
        CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_student_subject_year
            ON student_schema.student_personality_development_review (student_id, subject_id, academic_year_id)
            INCLUDE (teacher_id, category_type, rating, review_date)
            WHERE is_active = 1;
    ';
    PRINT N'Created index IX_student_personality_dev_rev_student_subject_year.';
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
    EXEC sp_executesql N'
        CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_teacher_subject
            ON student_schema.student_personality_development_review (teacher_id, subject_id, review_date)
            INCLUDE (student_id, category_type, rating)
            WHERE is_active = 1;
    ';
    PRINT N'Created index IX_student_personality_dev_rev_teacher_subject.';
END;
GO

PRINT N'========================================================================';
PRINT N'Personal Development Module setup completed successfully.';
PRINT N'========================================================================';
GO
