/* Module migration: 014_library.sql */
/*
    ============================================================================
    THINKIGEN LIBRARY MODULE — FRESH 3-TABLE PRODUCTION SCHEMA
    ============================================================================

    Migration: 014_library
    Purpose:   Drops legacy library tables and recreates the final, clean 3-table
               production architecture with columns, constraints, and indexes.

    Tables:
      1. library_schema.library_book
      2. library_schema.library_book_copy
      3. library_schema.library_book_borrow

    Rollback:
      See rollback/014_library_rollback.sql
    ============================================================================
*/

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* -------------------------------------------------------------------------- */
/* 0. CLEANUP: DROP EXISTING TABLES IN REVERSE DEPENDENCY ORDER               */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'library_schema.library_book_borrow', N'U') IS NOT NULL
    DROP TABLE library_schema.library_book_borrow;
GO

IF OBJECT_ID(N'library_schema.library_book_copy', N'U') IS NOT NULL
    DROP TABLE library_schema.library_book_copy;
GO

IF OBJECT_ID(N'library_schema.library_book', N'U') IS NOT NULL
    DROP TABLE library_schema.library_book;
GO

/* -------------------------------------------------------------------------- */
/* 1. SCHEMA & PREREQUISITE COMPOSITE CANDIDATE KEYS                          */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'library_schema')
    EXEC(N'CREATE SCHEMA library_schema AUTHORIZATION dbo;');
GO

-- Ensure student candidate key exists for child composite FK reference
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_school_branch_student'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_school_branch_student
        ON student_schema.student (school_id, branch_id, student_id);
END;
GO

-- Ensure school_class candidate key exists for child composite FK reference
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_school_class_school_scope'
      AND object_id = OBJECT_ID(N'management_schema.school_class')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_school_class_school_scope
        ON management_schema.school_class (school_id, class_id);
END;
GO

-- Ensure section candidate key exists for child composite FK reference
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_section_class_scope'
      AND object_id = OBJECT_ID(N'management_schema.section')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_section_class_scope
        ON management_schema.section (class_id, section_id);
END;
GO

/* -------------------------------------------------------------------------- */
/* 2. TABLE: library_schema.library_book (Catalog Master)                     */
/* -------------------------------------------------------------------------- */

CREATE TABLE library_schema.library_book
(
    book_id                BIGINT          NOT NULL IDENTITY(1, 1),
    school_id              BIGINT          NOT NULL,
    branch_id              BIGINT          NOT NULL,
    title                  NVARCHAR(300)   NOT NULL,
    author                 NVARCHAR(200)   NOT NULL,
    subject                NVARCHAR(100)   NOT NULL,
    category               NVARCHAR(100)   NOT NULL,
    language               NVARCHAR(50)    NOT NULL,
    edition                NVARCHAR(50)    NULL,
    description            NVARCHAR(MAX)   NULL,
    total_copies           INT             NOT NULL CONSTRAINT DF_library_book_total_copies DEFAULT (0),
    available_copies       INT             NOT NULL CONSTRAINT DF_library_book_available_copies DEFAULT (0),
    is_active              BIT             NOT NULL CONSTRAINT DF_library_book_is_active DEFAULT (1),
    created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_created_at DEFAULT (SYSUTCDATETIME()),
    created_by             BIGINT          NOT NULL,
    updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_updated_at DEFAULT (SYSUTCDATETIME()),
    updated_by             BIGINT          NULL,
    row_version            ROWVERSION      NOT NULL,

    -- Primary & Scope Candidate Keys
    CONSTRAINT PK_library_book PRIMARY KEY CLUSTERED (book_id),
    CONSTRAINT UQ_library_book_scope UNIQUE NONCLUSTERED (school_id, branch_id, book_id),

    -- Validation Constraints
    CONSTRAINT CK_library_book_title CHECK (LEN(LTRIM(RTRIM(title))) > 0),
    CONSTRAINT CK_library_book_author CHECK (LEN(LTRIM(RTRIM(author))) > 0),
    CONSTRAINT CK_library_book_subject CHECK (LEN(LTRIM(RTRIM(subject))) > 0),
    CONSTRAINT CK_library_book_category CHECK (LEN(LTRIM(RTRIM(category))) > 0),
    CONSTRAINT CK_library_book_language CHECK (LEN(LTRIM(RTRIM(language))) > 0),
    CONSTRAINT CK_library_book_total_copies CHECK (total_copies >= 0),
    CONSTRAINT CK_library_book_available_copies CHECK (available_copies >= 0),
    CONSTRAINT CK_library_book_available_lte_total CHECK (available_copies <= total_copies),

    -- Foreign Keys
    CONSTRAINT FK_library_book_school FOREIGN KEY (school_id)
        REFERENCES management_schema.school (school_id),
    CONSTRAINT FK_library_book_branch FOREIGN KEY (school_id, branch_id)
        REFERENCES management_schema.branch (school_id, branch_id),
    CONSTRAINT FK_library_book_created_by FOREIGN KEY (created_by)
        REFERENCES security_schema.users (user_id),
    CONSTRAINT FK_library_book_updated_by FOREIGN KEY (updated_by)
        REFERENCES security_schema.users (user_id)
);
GO

-- Catalog search & browse index
CREATE NONCLUSTERED INDEX IX_library_book_branch_search
    ON library_schema.library_book (school_id, branch_id, subject, category, language, is_active)
    INCLUDE (title, author, total_copies, available_copies);
GO

/* -------------------------------------------------------------------------- */
/* 3. TABLE: library_schema.library_book_copy (Physical Inventory)            */
/* -------------------------------------------------------------------------- */

CREATE TABLE library_schema.library_book_copy
(
    book_copy_id           BIGINT          NOT NULL IDENTITY(1, 1),
    book_id                BIGINT          NOT NULL,
    school_id              BIGINT          NOT NULL,
    branch_id              BIGINT          NOT NULL,
    copy_number            INT             NOT NULL,
    barcode                NVARCHAR(50)    NULL,
    copy_status            NVARCHAR(20)    NOT NULL,
    is_active              BIT             NOT NULL CONSTRAINT DF_library_book_copy_is_active DEFAULT (1),
    created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_copy_created_at DEFAULT (SYSUTCDATETIME()),
    created_by             BIGINT          NOT NULL,
    updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_copy_updated_at DEFAULT (SYSUTCDATETIME()),
    updated_by             BIGINT          NULL,
    row_version            ROWVERSION      NOT NULL,

    -- Primary & Candidate Keys
    CONSTRAINT PK_library_book_copy PRIMARY KEY CLUSTERED (book_copy_id),
    CONSTRAINT UQ_library_book_copy_number UNIQUE NONCLUSTERED (school_id, branch_id, book_id, copy_number),
    CONSTRAINT UQ_library_book_copy_scope UNIQUE NONCLUSTERED (school_id, branch_id, book_id, book_copy_id),

    -- Validation Constraints
    CONSTRAINT CK_library_book_copy_number CHECK (copy_number > 0),
    CONSTRAINT CK_library_book_copy_status CHECK
        (copy_status IN (N'AVAILABLE', N'BORROWED', N'OVERDUE', N'LOST', N'DAMAGED', N'MAINTENANCE', N'RETIRED')),
    CONSTRAINT CK_library_book_copy_active_status CHECK
        ((copy_status NOT IN (N'AVAILABLE', N'BORROWED', N'OVERDUE')) OR (is_active = 1)),

    -- Foreign Keys
    CONSTRAINT FK_library_book_copy_book_scope FOREIGN KEY (school_id, branch_id, book_id)
        REFERENCES library_schema.library_book (school_id, branch_id, book_id),
    CONSTRAINT FK_library_book_copy_school FOREIGN KEY (school_id)
        REFERENCES management_schema.school (school_id),
    CONSTRAINT FK_library_book_copy_branch FOREIGN KEY (school_id, branch_id)
        REFERENCES management_schema.branch (school_id, branch_id),
    CONSTRAINT FK_library_book_copy_created_by FOREIGN KEY (created_by)
        REFERENCES security_schema.users (user_id),
    CONSTRAINT FK_library_book_copy_updated_by FOREIGN KEY (updated_by)
        REFERENCES security_schema.users (user_id)
);
GO

-- Barcode uniqueness for active copies within branch
CREATE UNIQUE NONCLUSTERED INDEX UQ_library_book_copy_branch_barcode
    ON library_schema.library_book_copy (school_id, branch_id, barcode)
    WHERE barcode IS NOT NULL AND is_active = 1;
GO

-- Copy status lookup per book
CREATE NONCLUSTERED INDEX IX_library_book_copy_book_status
    ON library_schema.library_book_copy (book_id, copy_status)
    WHERE is_active = 1;
GO

-- Branch-level inventory index
CREATE NONCLUSTERED INDEX IX_library_book_copy_branch_status
    ON library_schema.library_book_copy (school_id, branch_id, copy_status)
    INCLUDE (book_id, copy_number);
GO

-- Fast available copy lookup index
CREATE NONCLUSTERED INDEX IX_library_book_copy_available
    ON library_schema.library_book_copy (book_id, copy_number)
    WHERE is_active = 1 AND copy_status = N'AVAILABLE';
GO

/* -------------------------------------------------------------------------- */
/* 4. TABLE: library_schema.library_book_borrow (Circulation Ledger)          */
/* -------------------------------------------------------------------------- */

CREATE TABLE library_schema.library_book_borrow
(
    borrow_id              BIGINT          NOT NULL IDENTITY(1, 1),
    school_id              BIGINT          NOT NULL,
    branch_id              BIGINT          NOT NULL,
    academic_year_id       BIGINT          NOT NULL,
    student_id             BIGINT          NOT NULL,
    class_id               BIGINT          NOT NULL,
    section_id             BIGINT          NOT NULL,
    book_id                BIGINT          NOT NULL,
    book_copy_id           BIGINT          NOT NULL,
    borrow_status          NVARCHAR(20)    NOT NULL,
    borrowed_at            DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_borrow_borrowed_at DEFAULT (SYSUTCDATETIME()),
    due_date               DATE            NOT NULL,
    returned_at            DATETIME2(0)    NULL,
    returned_to            BIGINT          NULL,
    issued_by              BIGINT          NOT NULL,
    remarks                NVARCHAR(500)   NULL,
    is_active              BIT             NOT NULL CONSTRAINT DF_library_book_borrow_is_active DEFAULT (1),
    updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_library_book_borrow_updated_at DEFAULT (SYSUTCDATETIME()),
    updated_by             BIGINT          NULL,
    row_version            ROWVERSION      NOT NULL,

    -- Primary Key
    CONSTRAINT PK_library_book_borrow PRIMARY KEY CLUSTERED (borrow_id),

    -- Validation Constraints
    CONSTRAINT CK_library_book_borrow_status CHECK
        (borrow_status IN (N'ACTIVE', N'OVERDUE', N'RETURNED', N'LOST')),
    CONSTRAINT CK_library_book_borrow_due_date CHECK
        (due_date >= CAST(borrowed_at AS DATE)),
    CONSTRAINT CK_library_book_borrow_returned_status CHECK
    (
        (borrow_status = N'RETURNED' AND returned_at IS NOT NULL AND returned_to IS NOT NULL)
        OR
        (borrow_status IN (N'ACTIVE', N'OVERDUE', N'LOST') AND returned_at IS NULL AND returned_to IS NULL)
    ),

    -- Composite & Referential Foreign Keys
    CONSTRAINT FK_library_book_borrow_school FOREIGN KEY (school_id)
        REFERENCES management_schema.school (school_id),
    CONSTRAINT FK_library_book_borrow_branch FOREIGN KEY (school_id, branch_id)
        REFERENCES management_schema.branch (school_id, branch_id),
    CONSTRAINT FK_library_book_borrow_academic_year FOREIGN KEY (school_id, academic_year_id)
        REFERENCES management_schema.academic_year (school_id, academic_year_id),
    CONSTRAINT FK_library_book_borrow_student_scope FOREIGN KEY (school_id, branch_id, student_id)
        REFERENCES student_schema.student (school_id, branch_id, student_id),
    CONSTRAINT FK_library_book_borrow_class_scope FOREIGN KEY (school_id, class_id)
        REFERENCES management_schema.school_class (school_id, class_id),
    CONSTRAINT FK_library_book_borrow_section_scope FOREIGN KEY (class_id, section_id)
        REFERENCES management_schema.section (class_id, section_id),
    CONSTRAINT FK_library_book_borrow_copy_scope FOREIGN KEY (school_id, branch_id, book_id, book_copy_id)
        REFERENCES library_schema.library_book_copy (school_id, branch_id, book_id, book_copy_id),
    CONSTRAINT FK_library_book_borrow_issued_by FOREIGN KEY (issued_by)
        REFERENCES security_schema.users (user_id),
    CONSTRAINT FK_library_book_borrow_returned_to FOREIGN KEY (returned_to)
        REFERENCES security_schema.users (user_id),
    CONSTRAINT FK_library_book_borrow_updated_by FOREIGN KEY (updated_by)
        REFERENCES security_schema.users (user_id)
);
GO

-- Prevent multiple active checkouts of the same physical copy
CREATE UNIQUE NONCLUSTERED INDEX UX_library_book_borrow_active_copy
    ON library_schema.library_book_borrow (school_id, branch_id, book_copy_id)
    WHERE is_active = 1 AND borrow_status IN (N'ACTIVE', N'OVERDUE');
GO

-- Circulation index: Student borrowing history
CREATE NONCLUSTERED INDEX IX_library_book_borrow_student_history
    ON library_schema.library_book_borrow (student_id, borrow_status, due_date)
    WHERE is_active = 1;
GO

-- Circulation index: Student history by academic year
CREATE NONCLUSTERED INDEX IX_library_book_borrow_student_year
    ON library_schema.library_book_borrow (school_id, academic_year_id, student_id, borrow_status);
GO

-- Active loans index
CREATE NONCLUSTERED INDEX IX_library_book_borrow_active_loans
    ON library_schema.library_book_borrow (school_id, branch_id, due_date)
    INCLUDE (student_id, book_id, book_copy_id, borrowed_at)
    WHERE is_active = 1 AND borrow_status = N'ACTIVE';
GO

-- Overdue loans index
CREATE NONCLUSTERED INDEX IX_library_book_borrow_overdue_loans
    ON library_schema.library_book_borrow (school_id, branch_id, due_date)
    INCLUDE (student_id, book_id, book_copy_id, borrowed_at)
    WHERE is_active = 1 AND borrow_status = N'OVERDUE';
GO

-- Circulation audit by branch
CREATE NONCLUSTERED INDEX IX_library_book_borrow_branch_circulation
    ON library_schema.library_book_borrow (branch_id, borrowed_at)
    INCLUDE (book_id, student_id, borrow_status);
GO

-- Book-copy lifecycle history
CREATE NONCLUSTERED INDEX IX_library_book_borrow_copy_history
    ON library_schema.library_book_borrow (book_copy_id, borrowed_at)
    INCLUDE (student_id, borrow_status, returned_at);
GO

-- Staff checkout audit trail
CREATE NONCLUSTERED INDEX IX_library_book_borrow_issued_by
    ON library_schema.library_book_borrow (issued_by, borrowed_at);
GO

-- Lost book reporting
CREATE NONCLUSTERED INDEX IX_library_book_borrow_lost
    ON library_schema.library_book_borrow (school_id, branch_id, updated_at)
    INCLUDE (student_id, book_id, book_copy_id)
    WHERE borrow_status = N'LOST';
GO

/* -------------------------------------------------------------------------- */
/* 5. MIGRATION TRACKING                                                      */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM security_schema.schema_version WHERE migration_name = N'014_library')
    BEGIN
        INSERT INTO security_schema.schema_version (migration_name, applied_at)
        VALUES (N'014_library', SYSUTCDATETIME());
    END;
END;
GO
