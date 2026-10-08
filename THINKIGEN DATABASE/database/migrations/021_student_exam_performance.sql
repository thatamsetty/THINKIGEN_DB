/*
    Migration: 021_student_exam_performance.sql
    Module:    student_schema.student_exam_performance
    Purpose:   Store backend-generated exam performance summary metrics for each student
               per academic scope (academic_year, class, section).

    Architectural Constraints & Design Rules:
    ---------------------------------------------------------------------------
    - All attendance and exam performance calculations are handled EXCLUSIVELY in the backend application layer.
    - The database does NOT contain:
      * Calculated formulas
      * Computed columns
      * Triggers for percentage calculation
      * Stored procedures for percentage calculation
    - Existing table student_schema.exam_result is UNCHANGED.
    - Only stores the backend-generated summary values:
      * student_exam_performance_id (PK IDENTITY)
      * student_id (FK -> student_schema.student)
      * academic_year_id (FK -> management_schema.academic_year)
      * class_id (FK -> management_schema.school_class)
      * section_id (FK -> management_schema.section)
      * total_exams_count (INT >= 0)
      * overall_percentage (DECIMAL(5, 2) BETWEEN 0.00 AND 100.00)
      * created_at (DATETIME2(0))
      * updated_at (DATETIME2(0))
      * row_version (ROWVERSION for optimistic concurrency)

    Rollback:
    - DROP TABLE IF EXISTS student_schema.student_exam_performance;
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'Creating student_schema.student_exam_performance table...';
PRINT N'========================================================================';

IF OBJECT_ID(N'student_schema.student_exam_performance', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_exam_performance
    (
        student_exam_performance_id BIGINT          NOT NULL IDENTITY(1, 1),
        student_id                  BIGINT          NOT NULL,
        academic_year_id            BIGINT          NOT NULL,
        class_id                    BIGINT          NOT NULL,
        section_id                  BIGINT          NOT NULL,
        total_exams_count           INT             NOT NULL CONSTRAINT DF_student_exam_performance_total_exams DEFAULT (0),
        overall_percentage          DECIMAL(5, 2)   NOT NULL,
        created_at                  DATETIME2(0)    NOT NULL CONSTRAINT DF_student_exam_performance_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at                  DATETIME2(0)    NOT NULL CONSTRAINT DF_student_exam_performance_updated_at DEFAULT (SYSUTCDATETIME()),
        row_version                 ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_exam_performance PRIMARY KEY CLUSTERED (student_exam_performance_id),
        CONSTRAINT UQ_student_exam_performance_student_scope UNIQUE NONCLUSTERED
            (student_id, academic_year_id, class_id, section_id),
        CONSTRAINT CK_student_exam_performance_total_exams CHECK
            (total_exams_count >= 0),
        CONSTRAINT CK_student_exam_performance_overall_percentage CHECK
            (overall_percentage >= 0.00 AND overall_percentage <= 100.00),
        CONSTRAINT FK_student_exam_performance_student FOREIGN KEY (student_id)
            REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_exam_performance_academic_year FOREIGN KEY (academic_year_id)
            REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_exam_performance_class FOREIGN KEY (class_id)
            REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_exam_performance_section FOREIGN KEY (section_id)
            REFERENCES management_schema.section (section_id)
    );

    PRINT N'Created table student_schema.student_exam_performance successfully.';
END
ELSE
BEGIN
    PRINT N'Table student_schema.student_exam_performance already exists. Skipping creation.';
END;
GO

-- Index for querying exam performance summary across a section / class
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_exam_performance_scope'
      AND object_id = OBJECT_ID(N'student_schema.student_exam_performance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_exam_performance_scope
        ON student_schema.student_exam_performance (academic_year_id, class_id, section_id)
        INCLUDE (student_id, total_exams_count, overall_percentage);

    PRINT N'Created index IX_student_exam_performance_scope.';
END;
GO

-- Index for rapid single-student lookup
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_exam_performance_student'
      AND object_id = OBJECT_ID(N'student_schema.student_exam_performance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_exam_performance_student
        ON student_schema.student_exam_performance (student_id)
        INCLUDE (academic_year_id, total_exams_count, overall_percentage);

    PRINT N'Created index IX_student_exam_performance_student.';
END;
GO

PRINT N'========================================================================';
PRINT N'student_schema.student_exam_performance setup completed.';
PRINT N'========================================================================';
GO
