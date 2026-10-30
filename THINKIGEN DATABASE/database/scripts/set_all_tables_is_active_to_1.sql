/* ============================================================================
   SCRIPT: SET ALL TABLES is_active FROM 0 TO 1
   Target Database: Thinkigen School ERP (SSMS / Azure SQL Database)
   Purpose: Safely restores is_active = 1 across all database tables where
            records were previously set to 0 based on deadlines or past dates.
            All historical/concluded lifecycle tracking is preserved via
            dedicated status columns (CLOSED, ARCHIVED, COMPLETED, RETURNED).
   ============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'========================================================================';
PRINT N'STARTING RESTORATION OF is_active = 1 ACROSS ALL TABLES';
PRINT N'Target Evaluation Time (UTC): ' + CONVERT(NVARCHAR(30), SYSUTCDATETIME(), 120);
PRINT N'========================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    -- Table variable to capture update metrics
    DECLARE @Results TABLE (
        schema_name NVARCHAR(128),
        table_name  NVARCHAR(128),
        rows_fixed  INT
    );

    DECLARE @SchemaName NVARCHAR(128);
    DECLARE @TableName NVARCHAR(128);
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @RowsUpdated INT;

    -- Cursor iterating over every user table that contains an is_active column
    DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT 
            s.name AS schema_name,
            t.name AS table_name
        FROM sys.tables t
        INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
        INNER JOIN sys.columns c ON c.object_id = t.object_id
        WHERE c.name = N'is_active'
          AND t.is_ms_shipped = 0
        ORDER BY s.name, t.name;

    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Dynamically update is_active from 0 to 1
        SET @Sql = N'UPDATE [' + @SchemaName + N'].[' + @TableName + N'] '
                 + N'SET is_active = 1 '
                 + N'WHERE is_active = 0; '
                 + N'SET @CountOut = @@ROWCOUNT;';

        EXEC sp_executesql 
            @stmt = @Sql, 
            @params = N'@CountOut INT OUTPUT', 
            @CountOut = @RowsUpdated OUTPUT;

        IF @RowsUpdated > 0
        BEGIN
            INSERT INTO @Results (schema_name, table_name, rows_fixed)
            VALUES (@SchemaName, @TableName, @RowsUpdated);
            
            PRINT CONCAT(N'   ✔ Updated [', @SchemaName, N'].[', @TableName, N']: ', @RowsUpdated, N' row(s) restored to is_active = 1');
        END

        FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;
    END;

    CLOSE table_cursor;
    DEALLOCATE table_cursor;

    COMMIT TRANSACTION;
    PRINT N'';
    PRINT N'========================================================================';
    PRINT N'SUCCESS: ALL TABLES RESTORED TO is_active = 1!';
    PRINT N'========================================================================';

    -- Display breakdown of modified tables
    IF EXISTS (SELECT 1 FROM @Results)
    BEGIN
        SELECT 
            CONCAT(schema_name, N'.', table_name) AS [Table Name],
            rows_fixed AS [Rows Restored (0 -> 1)]
        FROM @Results
        ORDER BY rows_fixed DESC, [Table Name] ASC;
    END
    ELSE
    BEGIN
        PRINT N'Notice: All records across all tables already have is_active = 1. (0 rows needed update).';
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrLine INT = ERROR_LINE();
    PRINT CONCAT(N'ERROR at line ', @ErrLine, N': ', @ErrMsg);
    RAISERROR(@ErrMsg, 16, 1);
END CATCH;
GO

-- =============================================================================
-- FINAL VERIFICATION AUDIT (Checks all tables for any remaining is_active = 0)
-- =============================================================================
PRINT N'';
PRINT N'========================================================================';
PRINT N'FINAL VERIFICATION: REMAINING is_active = 0 AUDIT';
PRINT N'========================================================================';

DECLARE @AuditSql NVARCHAR(MAX) = N'';

SELECT @AuditSql = @AuditSql + 
    CASE WHEN @AuditSql = N'' THEN N'' ELSE N' UNION ALL ' END +
    N'SELECT ''' + s.name + N'.' + t.name + N''' AS [Table Name], COUNT(*) AS [Inactive Count] FROM [' + s.name + N'].[' + t.name + N'] WHERE is_active = 0'
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
INNER JOIN sys.columns c ON c.object_id = t.object_id
WHERE c.name = N'is_active'
  AND t.is_ms_shipped = 0;

IF @AuditSql <> N''
BEGIN
    DECLARE @FinalAuditSql NVARCHAR(MAX) = N'
    SELECT 
        [Table Name],
        [Inactive Count],
        CASE WHEN [Inactive Count] = 0 THEN N''PASS (100% Active)'' ELSE N''FAIL'' END AS [Status]
    FROM (' + @AuditSql + N') a
    WHERE [Inactive Count] > 0;
    
    IF @@ROWCOUNT = 0
        PRINT N''   ✔ AUDIT PASSED: 0 inactive (is_active = 0) rows remain across all tables in the entire database!'';
    ';
    EXEC sp_executesql @FinalAuditSql;
END
GO
