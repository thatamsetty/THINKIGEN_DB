/* Module migration: 024_teacher_designation.sql */
/*
    Migration: 024_teacher_designation
    Purpose:   Add designation VARCHAR(100) NOT NULL column to teachers_schema.teacher,
               populated by mapping each teacher's subject_id to the authoritative
               management_schema.subject.subject_name and generating designation
               as '<subject_name> Teacher'.

    Design notes:
    - Authoritative source for subject mapping: management_schema.subject (subject_id -> subject_name).
    - No separate designation master table created.
    - Preserves all existing data, PKs, FKs, constraints, indexes, and relationships.
    - Separated by GO batches to guarantee clean compilation in SSMS and sqlcmd.
    - Validates that every teacher has a non-NULL designation matching <subject_name> Teacher.

    Rollback:
    - See database/migrations/rollback/024_teacher_designation_rollback.sql
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Applying Migration 024: Add designation to teachers_schema.teacher...';
PRINT N'========================================================================';

-- -----------------------------------------------------------------------------
-- Step 1: Detect and add column as VARCHAR(100) NULL if missing
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'teachers_schema.teacher', N'designation') IS NULL
    BEGIN
        PRINT N'1. Adding column designation VARCHAR(100) NULL...';
        ALTER TABLE teachers_schema.teacher
            ADD designation VARCHAR(100) NULL;
        PRINT N'   ✔ Column designation added.';
    END
    ELSE
    BEGIN
        PRINT N'1. Column designation already exists.';
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- Step 2: Populate designation mapping subject_id -> subject_name + ' Teacher'
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    PRINT N'2. Populating designation from authoritative subject master...';
    UPDATE t
    SET t.designation = CONCAT(s.subject_name, ' Teacher')
    FROM teachers_schema.teacher t
    INNER JOIN management_schema.subject s
        ON s.subject_id = t.subject_id
    WHERE t.designation IS NULL
       OR t.designation <> CONCAT(s.subject_name, ' Teacher');
    PRINT N'   ✔ Populated teacher records.';
END;
GO

-- -----------------------------------------------------------------------------
-- Step 3: Enforce NOT NULL constraint once existing records are populated
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'teachers_schema.teacher')
          AND name = N'designation'
          AND is_nullable = 1
    )
    BEGIN
        IF EXISTS (SELECT 1 FROM teachers_schema.teacher WHERE designation IS NULL)
        BEGIN
            THROW 50001, N'Cannot alter designation to NOT NULL: unmapped teachers exist with NULL designation.', 1;
        END;

        PRINT N'3. Enforcing NOT NULL constraint on column designation...';
        ALTER TABLE teachers_schema.teacher
            ALTER COLUMN designation VARCHAR(100) NOT NULL;
        PRINT N'   ✔ Column designation is now VARCHAR(100) NOT NULL.';
    END
    ELSE
    BEGIN
        PRINT N'3. Column designation is already NOT NULL.';
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- Step 4: Strict validation: verify every single teacher has valid designation
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'teachers_schema.teacher', N'U') IS NOT NULL
BEGIN
    PRINT N'4. Validating teacher designations...';
    IF EXISTS (
        SELECT 1
        FROM teachers_schema.teacher t
        LEFT JOIN management_schema.subject s
            ON s.subject_id = t.subject_id
        WHERE t.designation IS NULL
           OR t.designation <> CONCAT(s.subject_name, ' Teacher')
    )
    BEGIN
        THROW 50002, N'Validation failed: Found teacher records where designation is NULL or does not match <subject_name> Teacher.', 1;
    END;
    PRINT N'   ✔ Validation passed: All teachers verified with non-NULL designation matching authoritative subject master.';
END;
GO

PRINT N'========================================================================';
PRINT N'Migration 024: Completed successfully.';
PRINT N'========================================================================';
GO
