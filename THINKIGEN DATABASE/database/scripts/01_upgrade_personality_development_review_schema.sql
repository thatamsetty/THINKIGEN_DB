/* ============================================================================
   SCRIPT 1: SCHEMA UPGRADE
   Target: student_schema.student_personality_development_review
   Purpose: Adds 'category_type' and 'rating' columns, check constraints,
            unique session constraint, and covering indexes.
   ============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'STEP 1: Adding category_type column...';
PRINT N'========================================================================';
IF COL_LENGTH(N'student_schema.student_personality_development_review', N'category_type') IS NULL
BEGIN
    ALTER TABLE student_schema.student_personality_development_review
        ADD category_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_student_personality_dev_rev_category DEFAULT (N'COMMUNICATION_RATING') WITH VALUES;
    PRINT N'Column category_type added successfully.';
END
ELSE
BEGIN
    PRINT N'Column category_type already exists.';
END;
GO

PRINT N'========================================================================';
PRINT N'STEP 2: Adding CHECK constraint on category_type...';
PRINT N'========================================================================';
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_student_personality_dev_rev_category'
      AND parent_object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    ALTER TABLE student_schema.student_personality_development_review
        ADD CONSTRAINT CK_student_personality_dev_rev_category
            CHECK (category_type IN (
                N'LEADERSHIP_RATING', N'COMMUNICATION_RATING', N'COLLABORATION_RATING', N'RESPONSIBILITY_RATING',
                N'LEADERSHIP', N'COMMUNICATION', N'COLLABORATION', N'RESPONSIBILITY'
            ));
    PRINT N'Constraint CK_student_personality_dev_rev_category added.';
END;
GO

PRINT N'========================================================================';
PRINT N'STEP 3: Adding rating column...';
PRINT N'========================================================================';
IF COL_LENGTH(N'student_schema.student_personality_development_review', N'rating') IS NULL
BEGIN
    ALTER TABLE student_schema.student_personality_development_review
        ADD rating INT NOT NULL
            CONSTRAINT DF_student_personality_dev_rev_rating DEFAULT (4) WITH VALUES;
    PRINT N'Column rating added successfully.';
END
ELSE
BEGIN
    PRINT N'Column rating already exists.';
END;
GO

PRINT N'========================================================================';
PRINT N'STEP 4: Adding CHECK constraint on rating (1 to 5)...';
PRINT N'========================================================================';
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_student_personality_dev_rev_rating'
      AND parent_object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    ALTER TABLE student_schema.student_personality_development_review
        ADD CONSTRAINT CK_student_personality_dev_rev_rating
            CHECK (rating >= 1 AND rating <= 5);
    PRINT N'Constraint CK_student_personality_dev_rev_rating added.';
END;
GO

PRINT N'========================================================================';
PRINT N'STEP 5: Upgrading Unique Constraint UQ_student_personality_dev_rev_session...';
PRINT N'========================================================================';
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_personality_dev_rev_session'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
BEGIN
    -- Check if category_type is already part of the constraint
    IF NOT EXISTS (
        SELECT 1 FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
          AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'student_schema.student_personality_development_review'), N'UQ_student_personality_dev_rev_session', 'IndexId')
          AND c.name = N'category_type'
    )
    BEGIN
        ALTER TABLE student_schema.student_personality_development_review
            DROP CONSTRAINT UQ_student_personality_dev_rev_session;

        ALTER TABLE student_schema.student_personality_development_review
            ADD CONSTRAINT UQ_student_personality_dev_rev_session UNIQUE NONCLUSTERED
                (student_id, subject_id, teacher_id, category_type, review_date);
        PRINT N'Unique constraint UQ_student_personality_dev_rev_session upgraded.';
    END;
END
ELSE
BEGIN
    ALTER TABLE student_schema.student_personality_development_review
        ADD CONSTRAINT UQ_student_personality_dev_rev_session UNIQUE NONCLUSTERED
            (student_id, subject_id, teacher_id, category_type, review_date);
    PRINT N'Unique constraint UQ_student_personality_dev_rev_session created.';
END;
GO

PRINT N'========================================================================';
PRINT N'STEP 6: Rebuilding Covering Indexes...';
PRINT N'========================================================================';
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
    DROP INDEX IX_student_personality_dev_rev_student_year 
        ON student_schema.student_personality_development_review;
GO

CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_student_year
    ON student_schema.student_personality_development_review (student_id, academic_year_id)
    INCLUDE (subject_id, teacher_id, category_type, rating, review_date)
    WHERE is_active = 1;
PRINT N'Index IX_student_personality_dev_rev_student_year created.';
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_student_subject_year'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
    DROP INDEX IX_student_personality_dev_rev_student_subject_year 
        ON student_schema.student_personality_development_review;
GO

CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_student_subject_year
    ON student_schema.student_personality_development_review (student_id, subject_id, academic_year_id)
    INCLUDE (teacher_id, category_type, rating, review_date)
    WHERE is_active = 1;
PRINT N'Index IX_student_personality_dev_rev_student_subject_year created.';
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_personality_dev_rev_teacher_subject'
      AND object_id = OBJECT_ID(N'student_schema.student_personality_development_review')
)
    DROP INDEX IX_student_personality_dev_rev_teacher_subject 
        ON student_schema.student_personality_development_review;
GO

CREATE NONCLUSTERED INDEX IX_student_personality_dev_rev_teacher_subject
    ON student_schema.student_personality_development_review (teacher_id, subject_id, review_date)
    INCLUDE (student_id, category_type, rating)
    WHERE is_active = 1;
PRINT N'Index IX_student_personality_dev_rev_teacher_subject created.';
GO

PRINT N'========================================================================';
PRINT N'SCHEMA UPGRADE COMPLETED SUCCESSFULLY.';
PRINT N'========================================================================';
GO
