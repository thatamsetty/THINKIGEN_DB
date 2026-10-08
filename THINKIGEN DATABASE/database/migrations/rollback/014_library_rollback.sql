/* ============================================================================
   Rollback script: 014_library_rollback.sql
   Target: library_schema.library_book_borrow,
           library_schema.library_book_copy,
           library_schema.library_book
   ============================================================================ */

SET NOCOUNT ON;
GO

PRINT N'Rolling back 014_library...';

IF OBJECT_ID(N'library_schema.library_book_borrow', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping library_schema.library_book_borrow...';
    DROP TABLE library_schema.library_book_borrow;
END;
GO

IF OBJECT_ID(N'library_schema.library_book_copy', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping library_schema.library_book_copy...';
    DROP TABLE library_schema.library_book_copy;
END;
GO

IF OBJECT_ID(N'library_schema.library_book', N'U') IS NOT NULL
BEGIN
    PRINT N'Dropping library_schema.library_book...';
    DROP TABLE library_schema.library_book;
END;
GO

IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NOT NULL
BEGIN
    DELETE FROM security_schema.schema_version WHERE migration_name = N'014_library';
END;
GO

PRINT N'Rollback of 014_library complete.';
GO
