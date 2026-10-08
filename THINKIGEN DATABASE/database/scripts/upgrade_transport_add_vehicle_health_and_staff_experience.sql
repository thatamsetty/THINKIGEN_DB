/* =============================================================================
    THINKIGEN ERP — Schema Upgrade & Mock Data Update
    Migration Script: Add 'vehicle_health' to vehicle & 'experience' to staff
    Target Schemas:   transport_schema.vehicle, transport_schema.staff

    NOTE: SQL Server parses and compiles batches before execution.
    DDL (ALTER TABLE) is separated by GO from DML (UPDATE) to prevent Msg 207.
   ============================================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'Starting Transport Schema Upgrade: vehicle_health and staff.experience...';
GO

/* ============================================================================= */
/* BATCH 1: ALTER TABLES — ADD COLUMNS WITH VALUES                               */
/* ============================================================================= */

-- 1. Add [vehicle_health] to [transport_schema].[vehicle]
IF OBJECT_ID(N'transport_schema.vehicle', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'transport_schema.vehicle')
          AND name = N'vehicle_health'
    )
    BEGIN
        PRINT N'Adding column [vehicle_health] to [transport_schema].[vehicle]...';
        ALTER TABLE [transport_schema].[vehicle]
        ADD [vehicle_health] NVARCHAR(30) NOT NULL
            CONSTRAINT [DF_transport_vehicle_health] DEFAULT (N'GOOD') WITH VALUES;
        PRINT N'✔ Column [vehicle_health] added successfully.';
    END
    ELSE
    BEGIN
        PRINT N'Column [vehicle_health] already exists on [transport_schema].[vehicle].';
    END;
END;
GO

-- 2. Add [experience] to [transport_schema].[staff]
IF OBJECT_ID(N'transport_schema.staff', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'transport_schema.staff')
          AND name = N'experience'
    )
    BEGIN
        PRINT N'Adding column [experience] to [transport_schema].[staff]...';
        ALTER TABLE [transport_schema].[staff]
        ADD [experience] INT NOT NULL
            CONSTRAINT [DF_transport_staff_experience] DEFAULT ((0)) WITH VALUES;
        PRINT N'✔ Column [experience] added successfully.';
    END
    ELSE
    BEGIN
        PRINT N'Column [experience] already exists on [transport_schema].[staff].';
    END;
END;
GO

/* ============================================================================= */
/* BATCH 2: ADD CHECK CONSTRAINTS                                                */
/* ============================================================================= */

-- 1. Check constraint for allowed vehicle health statuses
IF OBJECT_ID(N'transport_schema.vehicle', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.check_constraints 
        WHERE name = N'CK_transport_vehicle_health'
          AND parent_object_id = OBJECT_ID(N'transport_schema.vehicle')
    )
    BEGIN
        PRINT N'Adding constraint [CK_transport_vehicle_health]...';
        ALTER TABLE [transport_schema].[vehicle] WITH CHECK
        ADD CONSTRAINT [CK_transport_vehicle_health] CHECK (
            [vehicle_health] IN (N'EXCELLENT', N'GOOD', N'FAIR', N'NEEDS_SERVICE', N'CRITICAL')
        );

        ALTER TABLE [transport_schema].[vehicle] CHECK CONSTRAINT [CK_transport_vehicle_health];
        PRINT N'✔ Constraint [CK_transport_vehicle_health] added.';
    END;
END;
GO

-- 2. Check constraint for experience (years >= 0)
IF OBJECT_ID(N'transport_schema.staff', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.check_constraints 
        WHERE name = N'CK_transport_staff_experience'
          AND parent_object_id = OBJECT_ID(N'transport_schema.staff')
    )
    BEGIN
        PRINT N'Adding constraint [CK_transport_staff_experience]...';
        ALTER TABLE [transport_schema].[staff] WITH CHECK
        ADD CONSTRAINT [CK_transport_staff_experience] CHECK ([experience] >= 0);

        ALTER TABLE [transport_schema].[staff] CHECK CONSTRAINT [CK_transport_staff_experience];
        PRINT N'✔ Constraint [CK_transport_staff_experience] added.';
    END;
END;
GO

/* ============================================================================= */
/* BATCH 3: UPDATE EXISTING MOCK DATA                                            */
/* ============================================================================= */

BEGIN TRANSACTION;
BEGIN TRY

    PRINT N'Updating existing vehicle rows with vehicle_health mock data...';

    UPDATE [transport_schema].[vehicle]
    SET [vehicle_health] = N'EXCELLENT',
        [updated_at] = SYSUTCDATETIME()
    WHERE [vehicle_id] = 1;

    UPDATE [transport_schema].[vehicle]
    SET [vehicle_health] = N'GOOD',
        [updated_at] = SYSUTCDATETIME()
    WHERE [vehicle_id] = 2;

    UPDATE [transport_schema].[vehicle]
    SET [vehicle_health] = N'GOOD',
        [updated_at] = SYSUTCDATETIME()
    WHERE [vehicle_id] = 3;

    UPDATE [transport_schema].[vehicle]
    SET [vehicle_health] = N'NEEDS_SERVICE',
        [updated_at] = SYSUTCDATETIME()
    WHERE [vehicle_id] = 4;

    PRINT N'Updating existing staff rows with experience mock data...';

    -- Ravi Kumar (Driver, central branch) - 10 years
    UPDATE [transport_schema].[staff]
    SET [experience] = 10,
        [updated_at] = SYSUTCDATETIME()
    WHERE [staff_id] = 1;

    -- Mohan Rao (Attendant, central branch) - 4 years
    UPDATE [transport_schema].[staff]
    SET [experience] = 4,
        [updated_at] = SYSUTCDATETIME()
    WHERE [staff_id] = 2;

    -- Suresh Naidu (Driver, north branch) - 8 years
    UPDATE [transport_schema].[staff]
    SET [experience] = 8,
        [updated_at] = SYSUTCDATETIME()
    WHERE [staff_id] = 3;

    -- Karthik Rao (Attendant, north branch) - 3 years
    UPDATE [transport_schema].[staff]
    SET [experience] = 3,
        [updated_at] = SYSUTCDATETIME()
    WHERE [staff_id] = 4;

    -- Vijay Reddy (Driver, city branch) - 12 years
    UPDATE [transport_schema].[staff]
    SET [experience] = 12,
        [updated_at] = SYSUTCDATETIME()
    WHERE [staff_id] = 5;

    -- Imran Ali (Attendant, city branch) - 5 years
    UPDATE [transport_schema].[staff]
    SET [experience] = 5,
        [updated_at] = SYSUTCDATETIME()
    WHERE [staff_id] = 6;

    -- Prakash Rao (Driver, lake branch) - 7 years
    UPDATE [transport_schema].[staff]
    SET [experience] = 7,
        [updated_at] = SYSUTCDATETIME()
    WHERE [staff_id] = 7;

    -- Anil Kumar (Attendant, lake branch) - 2 years
    UPDATE [transport_schema].[staff]
    SET [experience] = 2,
        [updated_at] = SYSUTCDATETIME()
    WHERE [staff_id] = 8;

    COMMIT TRANSACTION;
    PRINT N'✔ Transport mock data updated successfully.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO

/* ============================================================================= */
/* BATCH 4: VERIFICATION                                                         */
/* ============================================================================= */

PRINT N'--- Transport Vehicles with vehicle_health ---';
SELECT 
    vehicle_id, 
    vehicle_number, 
    vehicle_name, 
    capacity, 
    status, 
    vehicle_health
FROM transport_schema.vehicle;

PRINT N'--- Transport Staff with experience ---';
SELECT 
    staff_id, 
    staff_name, 
    staff_type, 
    experience, 
    license_number, 
    status
FROM transport_schema.staff;
GO
