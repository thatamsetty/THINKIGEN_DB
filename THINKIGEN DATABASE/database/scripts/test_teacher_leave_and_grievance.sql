/* ============================================================================
   Test Script: test_teacher_leave_and_grievance.sql
   Purpose: Verification script testing teacher leave and grievance tables,
            persisted computed columns, and constraints directly via standard DML.
   ============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'========================================================================';
PRINT N'Testing Teacher Leave & Grievance Tables, Computed Columns & Constraints';
PRINT N'========================================================================';

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @test_school_id        BIGINT;
    DECLARE @test_branch_id        BIGINT;
    DECLARE @test_academic_year_id BIGINT;
    DECLARE @test_teacher_id       BIGINT;
    DECLARE @test_user_id          BIGINT;

    SELECT TOP 1 
        @test_school_id        = t.school_id,
        @test_branch_id        = t.branch_id,
        @test_teacher_id       = t.teacher_id,
        @test_user_id          = COALESCE(t.user_id, 1)
    FROM teachers_schema.teacher t
    WHERE t.is_active = 1;

    SELECT TOP 1 
        @test_academic_year_id = academic_year_id
    FROM management_schema.academic_year
    WHERE school_id = @test_school_id AND is_active = 1;

    PRINT CONCAT(N'Test Scope: School=', @test_school_id, N', Branch=', @test_branch_id, 
                 N', Year=', @test_academic_year_id, N', Teacher=', @test_teacher_id);

    -- 1. Test Allowance Table & Computed Persisted Remaining Columns
    DELETE FROM teachers_schema.teacher_leave_allowance
    WHERE school_id = @test_school_id 
      AND branch_id = @test_branch_id 
      AND academic_year_id = @test_academic_year_id 
      AND teacher_id = @test_teacher_id;

    INSERT INTO teachers_schema.teacher_leave_allowance
    (
        school_id, branch_id, academic_year_id, teacher_id,
        sick_total_days, sick_used_days,
        casual_total_days, casual_used_days,
        privilege_total_days, privilege_used_days,
        on_duty_total_days, on_duty_used_days,
        compensatory_total_days, compensatory_used_days,
        created_by
    )
    VALUES
    (
        @test_school_id, @test_branch_id, @test_academic_year_id, @test_teacher_id,
        10.0, 0.0,
        12.0, 2.0,  -- 2 used, remaining should be 10.0
        15.0, 0.0,
        10.0, 0.0,
        5.0, 0.0,
        @test_user_id
    );

    DECLARE @rem_casual DECIMAL(4, 1);
    SELECT @rem_casual = casual_remaining_days 
    FROM teachers_schema.teacher_leave_allowance
    WHERE teacher_id = @test_teacher_id AND academic_year_id = @test_academic_year_id;

    IF @rem_casual <> 10.0
        THROW 50001, N'Allowance test failed: casual_remaining_days computed column mismatch.', 1;
    PRINT N'  [PASS] 1. Allowance table and computed persisted remaining balance verified.';

    -- 2. Test Leave Application Insert (FULL_DAY)
    INSERT INTO teachers_schema.teacher_leave_application
    (
        school_id, branch_id, academic_year_id, teacher_id,
        leave_type, leave_duration_type, start_date, end_date,
        total_days, reason, status, is_active,
        created_by, updated_by
    )
    VALUES
    (
        @test_school_id, @test_branch_id, @test_academic_year_id, @test_teacher_id,
        N'CASUAL', N'FULL_DAY', '2026-11-10', '2026-11-11',
        2.0, N'Personal work', N'PENDING', 1,
        @test_user_id, @test_user_id
    );
    DECLARE @app_id BIGINT = SCOPE_IDENTITY();

    -- 3. Test Leave Status History Insert
    INSERT INTO teachers_schema.teacher_leave_status_history
    (
        teacher_leave_application_id, old_status, new_status,
        changed_by, remarks
    )
    VALUES
    (
        @app_id, NULL, N'PENDING',
        @test_user_id, N'Initial application submitted'
    );
    PRINT N'  [PASS] 2. Leave application and status history records created.';

    -- 4. Test Grievance Table Insert
    INSERT INTO teachers_schema.teacher_grievance
    (
        school_id, branch_id, academic_year_id, teacher_id,
        grievance_title, grievance_category, priority,
        incident_date, incident_location, description,
        status, is_active, created_by, updated_by
    )
    VALUES
    (
        @test_school_id, @test_branch_id, @test_academic_year_id, @test_teacher_id,
        N'SmartBoard Issue', N'IT_EQUIPMENT', N'HIGH',
        '2026-10-25', N'Lab 2', N'HDMI display port is unresponsive.',
        N'OPEN', 1, @test_user_id, @test_user_id
    );
    DECLARE @grievance_id BIGINT = SCOPE_IDENTITY();

    -- 5. Test Grievance Status History Insert
    INSERT INTO teachers_schema.teacher_grievance_status_history
    (
        teacher_grievance_id, old_status, new_status,
        changed_by, remarks
    )
    VALUES
    (
        @grievance_id, NULL, N'OPEN',
        @test_user_id, N'Grievance registered'
    );
    PRINT N'  [PASS] 3. Grievance ticket and status history records created.';

    PRINT N'========================================================================';
    PRINT N'ALL TABLE & CONSTRAINT TESTS PASSED! Rolling back test transaction.';
    PRINT N'========================================================================';

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
