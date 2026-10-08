/* Module migration: 016_finance.sql */
/*
    ================================================================================
    THINKIGEN FINANCE DATABASE — MASTER SCHEMA
    ================================================================================

    MIGRATION STRATEGY:
    - Target Environment: SQL Server 2022+ / Azure SQL Database.
    - Scope: Institutional Finance Module (3-table authoritative architecture).
    - Data-Safety Strategy:
        1. Safely cleans up the deprecated 6-table / category-based finance models.
        2. Drops superseded draft objects containing legacy columns (e.g., net_amount, student_type).
        3. Deploys tables, constraints, composite scope keys, and operational indexes
           in dependency-safe order (Master -> Student Record -> Transactions).
        4. Completely idempotent for subsequent safe executions.

    APPROVED ARCHITECTURE (EXACTLY THREE TABLES):
      1. finance_schema.fee_structure_term       Class-level annual fee master & term due dates
      2. finance_schema.student_fee_record       Frozen annual financial state per student
      3. finance_schema.fee_payment_transaction  Unified immutable payment & refund transaction history

    CRITICAL BUSINESS RULES IMPLEMENTED:
      - Unified Residency: term1/2/3 residency_* fields snapshot hostel charges for HOSTELLER,
        transport charges for DAY_SCHOLAR with active transport, or 0 for DAY_SCHOLAR without transport.
      - Single Scholarship: Exactly one scholarship_amount column; subtracted from overall total_fee_amount.
      - Zero Net Amount: No column containing net_amount anywhere in the schema.
      - Transaction Types: PAYMENT and REFUND only (NO scholarship transaction type).
      - Controlled Statuses: PENDING / PARTIAL / PAID (+ NOT_APPLICABLE for non-applicable components).
      - Composite Scope Enforcement: Prevents cross-school, cross-branch, cross-year, or cross-class data drift.
      - Refund Lineage: Refund transactions must reference a valid parent payment.
      - Concurrency & Audit: Full rowversion and auditable created/updated fields on all tables.

    Rollback Order:
      DROP TABLE IF EXISTS finance_schema.fee_payment_transaction;
      DROP TABLE IF EXISTS finance_schema.student_fee_record;
      DROP TABLE IF EXISTS finance_schema.fee_structure_term;
    ================================================================================
*/

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* -------------------------------------------------------------------------- */
/* 1. SCHEMA CREATION                                                         */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'finance_schema')
    EXEC(N'CREATE SCHEMA finance_schema AUTHORIZATION dbo;');
GO

/* -------------------------------------------------------------------------- */
/* 2. SUPERSEDED OBJECT CLEANUP                                               */
/* -------------------------------------------------------------------------- */

/* Remove legacy six-table architecture objects if they exist */
IF OBJECT_ID(N'finance_schema.other_fee_payment_transaction', N'U') IS NOT NULL DROP TABLE finance_schema.other_fee_payment_transaction;
IF OBJECT_ID(N'finance_schema.term_fee_payment_transaction', N'U') IS NOT NULL DROP TABLE finance_schema.term_fee_payment_transaction;
IF OBJECT_ID(N'finance_schema.student_other_fee_record', N'U') IS NOT NULL DROP TABLE finance_schema.student_other_fee_record;
IF OBJECT_ID(N'finance_schema.student_term_fee_record', N'U') IS NOT NULL DROP TABLE finance_schema.student_term_fee_record;
IF OBJECT_ID(N'finance_schema.fee_structure_other', N'U') IS NOT NULL DROP TABLE finance_schema.fee_structure_other;

/* Remove superseded fee_structure_term if legacy category column exists */
IF COL_LENGTH(N'finance_schema.fee_structure_term', N'fee_category_code') IS NOT NULL
    DROP TABLE finance_schema.fee_structure_term;

/* Remove superseded student_fee_record and transactions if legacy forbidden columns exist */
IF COL_LENGTH(N'finance_schema.student_fee_record', N'total_net_amount') IS NOT NULL
    OR COL_LENGTH(N'finance_schema.student_fee_record', N'student_type') IS NOT NULL
BEGIN
    IF OBJECT_ID(N'finance_schema.fee_payment_transaction', N'U') IS NOT NULL
        DROP TABLE finance_schema.fee_payment_transaction;
    DROP TABLE finance_schema.student_fee_record;
END;

/* Align fee_payment_transaction column name to 'status' if previously deployed with 'transaction_status' */
IF COL_LENGTH(N'finance_schema.fee_payment_transaction', N'transaction_status') IS NOT NULL
   AND COL_LENGTH(N'finance_schema.fee_payment_transaction', N'status') IS NULL
BEGIN
    -- 1. Drop CHECK constraint that references transaction_status
    IF OBJECT_ID(N'finance_schema.CK_fee_payment_transaction_status', N'C') IS NOT NULL
        ALTER TABLE finance_schema.fee_payment_transaction DROP CONSTRAINT CK_fee_payment_transaction_status;

    -- 2. Drop DEFAULT constraint that references transaction_status if present
    DECLARE @df_sql NVARCHAR(500);
    SELECT @df_sql = N'ALTER TABLE finance_schema.fee_payment_transaction DROP CONSTRAINT ' + QUOTENAME(d.name) + N';'
    FROM sys.default_constraints d 
    JOIN sys.columns c ON c.object_id = d.parent_object_id AND c.column_id = d.parent_column_id
    WHERE d.parent_object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
      AND c.name = N'transaction_status';

    IF @df_sql IS NOT NULL
        EXEC sp_executesql @df_sql;

    -- 3. Rename the column to 'status'
    EXEC sp_rename N'finance_schema.fee_payment_transaction.transaction_status', N'status', N'COLUMN';

    -- 4. Re-create DEFAULT and CHECK constraints on 'status' via dynamic SQL (avoids compile-time binding error Msg 207)
    EXEC(N'ALTER TABLE finance_schema.fee_payment_transaction ADD CONSTRAINT DF_fee_payment_transaction_status DEFAULT (N''SUCCESS'') FOR status;');
    EXEC(N'ALTER TABLE finance_schema.fee_payment_transaction ADD CONSTRAINT CK_fee_payment_transaction_status CHECK (status IN (N''PENDING'', N''SUCCESS'', N''FAILED'', N''CANCELLED''));');
END;
GO

/* -------------------------------------------------------------------------- */
/* 3. TABLE 1: finance_schema.fee_structure_term                              */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'finance_schema.fee_structure_term', N'U') IS NULL
BEGIN
    CREATE TABLE finance_schema.fee_structure_term
    (
        fee_structure_term_id BIGINT IDENTITY(1,1) NOT NULL,
        school_id             BIGINT NOT NULL,
        branch_id             BIGINT NOT NULL,
        academic_year_id      BIGINT NOT NULL,
        class_id              BIGINT NOT NULL,
        total_amount          DECIMAL(12,2) NOT NULL,
        term1_amount          DECIMAL(12,2) NOT NULL,
        term1_due_date        DATE NOT NULL,
        term2_amount          DECIMAL(12,2) NOT NULL,
        term2_due_date        DATE NOT NULL,
        term3_amount          DECIMAL(12,2) NOT NULL,
        term3_due_date        DATE NOT NULL,
        status                NVARCHAR(20) NOT NULL CONSTRAINT DF_fee_structure_term_status DEFAULT (N'DRAFT'),
        is_active             BIT NOT NULL CONSTRAINT DF_fee_structure_term_is_active DEFAULT (1),
        created_at            DATETIME2(0) NOT NULL CONSTRAINT DF_fee_structure_term_created_at DEFAULT (SYSUTCDATETIME()),
        created_by            BIGINT NOT NULL,
        updated_at            DATETIME2(0) NULL,
        updated_by            BIGINT NULL,
        row_version           ROWVERSION NOT NULL,

        CONSTRAINT PK_fee_structure_term PRIMARY KEY CLUSTERED (fee_structure_term_id),
        CONSTRAINT UQ_fee_structure_term_scope UNIQUE NONCLUSTERED (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id),

        /* Financial value integrity */
        CONSTRAINT CK_fee_structure_term_amounts CHECK (
            total_amount >= 0 AND term1_amount >= 0 AND term2_amount >= 0 AND term3_amount >= 0
            AND total_amount = term1_amount + term2_amount + term3_amount
        ),
        CONSTRAINT CK_fee_structure_term_status CHECK (status IN (N'DRAFT', N'ACTIVE', N'INACTIVE')),
        CONSTRAINT CK_fee_structure_term_due_dates CHECK (term2_due_date >= term1_due_date AND term3_due_date >= term2_due_date),

        /* Institutional Master Relationships */
        CONSTRAINT FK_fee_structure_term_school FOREIGN KEY (school_id)
            REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_fee_structure_term_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_fee_structure_term_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_fee_structure_term_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_fee_structure_term_created_by FOREIGN KEY (created_by)
            REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_fee_structure_term_updated_by FOREIGN KEY (updated_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* 4. TABLE 2: finance_schema.student_fee_record                              */
/* -------------------------------------------------------------------------- */

/* 4A. MIGRATION OF EXISTING student_fee_record TO UNIFIED RESIDENCY FIELDS */
IF OBJECT_ID(N'finance_schema.student_fee_record', N'U') IS NOT NULL
   AND COL_LENGTH(N'finance_schema.student_fee_record', N'term1_hostel_amount') IS NOT NULL
BEGIN
    BEGIN TRANSACTION;

    -- 1. Drop obsolete check constraints referencing hostel/transport/totals before modifying data
    IF OBJECT_ID(N'finance_schema.CK_student_fee_record_hostel_residency', N'C') IS NOT NULL
        ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT CK_student_fee_record_hostel_residency;
    IF OBJECT_ID(N'finance_schema.CK_student_fee_record_transport', N'C') IS NOT NULL
        ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT CK_student_fee_record_transport;
    IF OBJECT_ID(N'finance_schema.CK_student_fee_record_term_totals', N'C') IS NOT NULL
        ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT CK_student_fee_record_term_totals;
    IF OBJECT_ID(N'finance_schema.CK_student_fee_record_overall_totals', N'C') IS NOT NULL
        ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT CK_student_fee_record_overall_totals;

    -- 2. Add new unified residency columns if not present
    IF COL_LENGTH(N'finance_schema.student_fee_record', N'term1_residency_amount') IS NULL
    BEGIN
        ALTER TABLE finance_schema.student_fee_record ADD
            term1_residency_amount  DECIMAL(12,2) NULL,
            term1_residency_paid    DECIMAL(12,2) NULL,
            term1_residency_balance DECIMAL(12,2) NULL,
            term1_residency_status  NVARCHAR(20) NULL,
            term2_residency_amount  DECIMAL(12,2) NULL,
            term2_residency_paid    DECIMAL(12,2) NULL,
            term2_residency_balance DECIMAL(12,2) NULL,
            term2_residency_status  NVARCHAR(20) NULL,
            term3_residency_amount  DECIMAL(12,2) NULL,
            term3_residency_paid    DECIMAL(12,2) NULL,
            term3_residency_balance DECIMAL(12,2) NULL,
            term3_residency_status  NVARCHAR(20) NULL;
    END;

    -- 2. Migrate existing values based on residency_type:
    --    HOSTELLER: residency_* <- hostel_*
    --    DAY_SCHOLAR: residency_* <- transport_* when applicable, otherwise 0
    EXEC(N'
    UPDATE finance_schema.student_fee_record
    SET
        term1_residency_amount = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term1_hostel_amount, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term1_transport_amount, 0)
            ELSE 0 END,
        term1_residency_paid = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term1_hostel_paid, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term1_transport_paid, 0)
            ELSE 0 END,
        term2_residency_amount = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term2_hostel_amount, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term2_transport_amount, 0)
            ELSE 0 END,
        term2_residency_paid = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term2_hostel_paid, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term2_transport_paid, 0)
            ELSE 0 END,
        term3_residency_amount = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term3_hostel_amount, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term3_transport_amount, 0)
            ELSE 0 END,
        term3_residency_paid = CASE 
            WHEN residency_type = N''HOSTELLER'' THEN ISNULL(term3_hostel_paid, 0)
            WHEN residency_type = N''DAY_SCHOLAR'' THEN ISNULL(term3_transport_paid, 0)
            ELSE 0 END;
    ');

    -- 3. Recalculate residency balances & status
    EXEC(N'
    UPDATE finance_schema.student_fee_record
    SET
        term1_residency_balance = term1_residency_amount - term1_residency_paid,
        term1_residency_status = CASE 
            WHEN term1_residency_amount = 0 AND term1_residency_paid = 0 THEN N''NOT_APPLICABLE''
            WHEN term1_residency_amount > 0 AND term1_residency_paid = 0 THEN N''PENDING''
            WHEN term1_residency_paid > 0 AND term1_residency_paid < term1_residency_amount THEN N''PARTIAL''
            ELSE N''PAID'' END,
        term2_residency_balance = term2_residency_amount - term2_residency_paid,
        term2_residency_status = CASE 
            WHEN term2_residency_amount = 0 AND term2_residency_paid = 0 THEN N''NOT_APPLICABLE''
            WHEN term2_residency_amount > 0 AND term2_residency_paid = 0 THEN N''PENDING''
            WHEN term2_residency_paid > 0 AND term2_residency_paid < term2_residency_amount THEN N''PARTIAL''
            ELSE N''PAID'' END,
        term3_residency_balance = term3_residency_amount - term3_residency_paid,
        term3_residency_status = CASE 
            WHEN term3_residency_amount = 0 AND term3_residency_paid = 0 THEN N''NOT_APPLICABLE''
            WHEN term3_residency_amount > 0 AND term3_residency_paid = 0 THEN N''PENDING''
            WHEN term3_residency_paid > 0 AND term3_residency_paid < term3_residency_amount THEN N''PARTIAL''
            ELSE N''PAID'' END;
    ');

    -- 4. Recalculate term totals
    EXEC(N'
    UPDATE finance_schema.student_fee_record
    SET
        term1_total_amount = term1_tuition_amount + term1_residency_amount,
        term1_total_paid = term1_tuition_paid + term1_residency_paid,
        term1_total_balance = (term1_tuition_amount + term1_residency_amount) - (term1_tuition_paid + term1_residency_paid),
        term1_status = CASE 
            WHEN (term1_tuition_paid + term1_residency_paid) = 0 AND (term1_tuition_amount + term1_residency_amount) > 0 THEN N''PENDING''
            WHEN (term1_tuition_paid + term1_residency_paid) > 0 AND (term1_tuition_paid + term1_residency_paid) < (term1_tuition_amount + term1_residency_amount) THEN N''PARTIAL''
            ELSE N''PAID'' END,
        term2_total_amount = term2_tuition_amount + term2_residency_amount,
        term2_total_paid = term2_tuition_paid + term2_residency_paid,
        term2_total_balance = (term2_tuition_amount + term2_residency_amount) - (term2_tuition_paid + term2_residency_paid),
        term2_status = CASE 
            WHEN (term2_tuition_paid + term2_residency_paid) = 0 AND (term2_tuition_amount + term2_residency_amount) > 0 THEN N''PENDING''
            WHEN (term2_tuition_paid + term2_residency_paid) > 0 AND (term2_tuition_paid + term2_residency_paid) < (term2_tuition_amount + term2_residency_amount) THEN N''PARTIAL''
            ELSE N''PAID'' END,
        term3_total_amount = term3_tuition_amount + term3_residency_amount,
        term3_total_paid = term3_tuition_paid + term3_residency_paid,
        term3_total_balance = (term3_tuition_amount + term3_residency_amount) - (term3_tuition_paid + term3_residency_paid),
        term3_status = CASE 
            WHEN (term3_tuition_paid + term3_residency_paid) = 0 AND (term3_tuition_amount + term3_residency_amount) > 0 THEN N''PENDING''
            WHEN (term3_tuition_paid + term3_residency_paid) > 0 AND (term3_tuition_paid + term3_residency_paid) < (term3_tuition_amount + term3_residency_amount) THEN N''PARTIAL''
            ELSE N''PAID'' END;
    ');

    -- 5. Recalculate overall totals
    EXEC(N'
    UPDATE finance_schema.student_fee_record
    SET
        total_fee_amount = (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount,
        total_paid_amount = term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid,
        total_balance_amount = ((term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount) - (term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid),
        overall_status = CASE 
            WHEN (term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid) = 0 AND ((term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount) > 0 THEN N''PENDING''
            WHEN (term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid) > 0 AND (term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid) < ((term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount) THEN N''PARTIAL''
            ELSE N''PAID'' END;
    ');

    -- 6. Enforce NOT NULL on residency columns
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term1_residency_amount DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term1_residency_paid DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term1_residency_balance DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term1_residency_status NVARCHAR(20) NOT NULL;

    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term2_residency_amount DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term2_residency_paid DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term2_residency_balance DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term2_residency_status NVARCHAR(20) NOT NULL;

    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term3_residency_amount DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term3_residency_paid DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term3_residency_balance DECIMAL(12,2) NOT NULL;
    ALTER TABLE finance_schema.student_fee_record ALTER COLUMN term3_residency_status NVARCHAR(20) NOT NULL;

    -- Add default constraints on residency columns if not present
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term1_residency_amount', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term1_residency_amount DEFAULT (0) FOR term1_residency_amount;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term1_residency_paid', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term1_residency_paid DEFAULT (0) FOR term1_residency_paid;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term1_residency_balance', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term1_residency_balance DEFAULT (0) FOR term1_residency_balance;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term1_residency_status', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term1_residency_status DEFAULT (N'NOT_APPLICABLE') FOR term1_residency_status;

    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term2_residency_amount', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term2_residency_amount DEFAULT (0) FOR term2_residency_amount;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term2_residency_paid', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term2_residency_paid DEFAULT (0) FOR term2_residency_paid;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term2_residency_balance', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term2_residency_balance DEFAULT (0) FOR term2_residency_balance;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term2_residency_status', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term2_residency_status DEFAULT (N'NOT_APPLICABLE') FOR term2_residency_status;

    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term3_residency_amount', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term3_residency_amount DEFAULT (0) FOR term3_residency_amount;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term3_residency_paid', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term3_residency_paid DEFAULT (0) FOR term3_residency_paid;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term3_residency_balance', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term3_residency_balance DEFAULT (0) FOR term3_residency_balance;
    IF OBJECT_ID(N'finance_schema.DF_student_fee_record_term3_residency_status', N'D') IS NULL
        ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT DF_student_fee_record_term3_residency_status DEFAULT (N'NOT_APPLICABLE') FOR term3_residency_status;

    -- 7. Drop default constraints on old columns
    DECLARE @drop_df NVARCHAR(MAX) = N'';
    SELECT @drop_df = @drop_df + N'ALTER TABLE finance_schema.student_fee_record DROP CONSTRAINT ' + QUOTENAME(d.name) + N';' + CHAR(13)
    FROM sys.default_constraints d
    JOIN sys.columns c ON c.object_id = d.parent_object_id AND c.column_id = d.parent_column_id
    WHERE d.parent_object_id = OBJECT_ID(N'finance_schema.student_fee_record')
      AND c.name IN (
        N'term1_hostel_amount', N'term1_hostel_paid', N'term1_hostel_balance', N'term1_hostel_status',
        N'term1_transport_amount', N'term1_transport_paid', N'term1_transport_balance', N'term1_transport_status',
        N'term2_hostel_amount', N'term2_hostel_paid', N'term2_hostel_balance', N'term2_hostel_status',
        N'term2_transport_amount', N'term2_transport_paid', N'term2_transport_balance', N'term2_transport_status',
        N'term3_hostel_amount', N'term3_hostel_paid', N'term3_hostel_balance', N'term3_hostel_status',
        N'term3_transport_amount', N'term3_transport_paid', N'term3_transport_balance', N'term3_transport_status'
      );
    IF @drop_df <> N'' EXEC sp_executesql @drop_df;

    -- 8. Drop the 24 obsolete hostel/transport columns
    ALTER TABLE finance_schema.student_fee_record DROP COLUMN
        term1_hostel_amount, term1_hostel_paid, term1_hostel_balance, term1_hostel_status,
        term1_transport_amount, term1_transport_paid, term1_transport_balance, term1_transport_status,
        term2_hostel_amount, term2_hostel_paid, term2_hostel_balance, term2_hostel_status,
        term2_transport_amount, term2_transport_paid, term2_transport_balance, term2_transport_status,
        term3_hostel_amount, term3_hostel_paid, term3_hostel_balance, term3_hostel_status,
        term3_transport_amount, term3_transport_paid, term3_transport_balance, term3_transport_status;

    -- 9. Recreate updated check constraints via dynamic SQL
    EXEC(N'
    ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT CK_student_fee_record_residency CHECK (
        term1_residency_amount >= 0 AND term1_residency_paid >= 0 AND term1_residency_balance >= 0
        AND term1_residency_paid <= term1_residency_amount
        AND term1_residency_balance = term1_residency_amount - term1_residency_paid
        AND term1_residency_status IN (N''NOT_APPLICABLE'', N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term1_residency_amount = 0 AND term1_residency_paid = 0 AND term1_residency_status = N''NOT_APPLICABLE'')
            OR (term1_residency_amount > 0 AND term1_residency_paid = 0 AND term1_residency_status = N''PENDING'')
            OR (term1_residency_paid > 0 AND term1_residency_paid < term1_residency_amount AND term1_residency_status = N''PARTIAL'')
            OR (term1_residency_paid = term1_residency_amount AND term1_residency_amount > 0 AND term1_residency_status = N''PAID'')
        )
        AND term2_residency_amount >= 0 AND term2_residency_paid >= 0 AND term2_residency_balance >= 0
        AND term2_residency_paid <= term2_residency_amount
        AND term2_residency_balance = term2_residency_amount - term2_residency_paid
        AND term2_residency_status IN (N''NOT_APPLICABLE'', N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term2_residency_amount = 0 AND term2_residency_paid = 0 AND term2_residency_status = N''NOT_APPLICABLE'')
            OR (term2_residency_amount > 0 AND term2_residency_paid = 0 AND term2_residency_status = N''PENDING'')
            OR (term2_residency_paid > 0 AND term2_residency_paid < term2_residency_amount AND term2_residency_status = N''PARTIAL'')
            OR (term2_residency_paid = term2_residency_amount AND term2_residency_amount > 0 AND term2_residency_status = N''PAID'')
        )
        AND term3_residency_amount >= 0 AND term3_residency_paid >= 0 AND term3_residency_balance >= 0
        AND term3_residency_paid <= term3_residency_amount
        AND term3_residency_balance = term3_residency_amount - term3_residency_paid
        AND term3_residency_status IN (N''NOT_APPLICABLE'', N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term3_residency_amount = 0 AND term3_residency_paid = 0 AND term3_residency_status = N''NOT_APPLICABLE'')
            OR (term3_residency_amount > 0 AND term3_residency_paid = 0 AND term3_residency_status = N''PENDING'')
            OR (term3_residency_paid > 0 AND term3_residency_paid < term3_residency_amount AND term3_residency_status = N''PARTIAL'')
            OR (term3_residency_paid = term3_residency_amount AND term3_residency_amount > 0 AND term3_residency_status = N''PAID'')
        )
    );
    ');

    EXEC(N'
    ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT CK_student_fee_record_term_totals CHECK (
        term1_total_amount = term1_tuition_amount + term1_residency_amount
        AND term1_total_paid = term1_tuition_paid + term1_residency_paid
        AND term1_total_balance = term1_total_amount - term1_total_paid
        AND term1_total_amount >= 0 AND term1_total_paid >= 0 AND term1_total_balance >= 0
        AND term1_total_paid <= term1_total_amount
        AND term1_status IN (N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term1_status = N''PENDING'' AND term1_total_paid = 0 AND term1_total_amount > 0)
            OR (term1_status = N''PARTIAL'' AND term1_total_paid > 0 AND term1_total_paid < term1_total_amount)
            OR (term1_status = N''PAID'' AND term1_total_paid = term1_total_amount)
        )
        AND term2_total_amount = term2_tuition_amount + term2_residency_amount
        AND term2_total_paid = term2_tuition_paid + term2_residency_paid
        AND term2_total_balance = term2_total_amount - term2_total_paid
        AND term2_total_amount >= 0 AND term2_total_paid >= 0 AND term2_total_balance >= 0
        AND term2_total_paid <= term2_total_amount
        AND term2_status IN (N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term2_status = N''PENDING'' AND term2_total_paid = 0 AND term2_total_amount > 0)
            OR (term2_status = N''PARTIAL'' AND term2_total_paid > 0 AND term2_total_paid < term2_total_amount)
            OR (term2_status = N''PAID'' AND term2_total_paid = term2_total_amount)
        )
        AND term3_total_amount = term3_tuition_amount + term3_residency_amount
        AND term3_total_paid = term3_tuition_paid + term3_residency_paid
        AND term3_total_balance = term3_total_amount - term3_total_paid
        AND term3_total_amount >= 0 AND term3_total_paid >= 0 AND term3_total_balance >= 0
        AND term3_total_paid <= term3_total_amount
        AND term3_status IN (N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (term3_status = N''PENDING'' AND term3_total_paid = 0 AND term3_total_amount > 0)
            OR (term3_status = N''PARTIAL'' AND term3_total_paid > 0 AND term3_total_paid < term3_total_amount)
            OR (term3_status = N''PAID'' AND term3_total_paid = term3_total_amount)
        )
    );
    ');

    EXEC(N'
    ALTER TABLE finance_schema.student_fee_record ADD CONSTRAINT CK_student_fee_record_overall_totals CHECK (
        total_fee_amount = (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount
        AND total_paid_amount = term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid
        AND scholarship_amount >= 0
        AND scholarship_amount <= (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount)
        AND total_paid_amount <= total_fee_amount
        AND total_balance_amount = total_fee_amount - total_paid_amount
        AND total_fee_amount >= 0 AND total_paid_amount >= 0 AND total_balance_amount >= 0
        AND overall_status IN (N''PENDING'', N''PARTIAL'', N''PAID'')
        AND (
            (overall_status = N''PENDING'' AND total_paid_amount = 0 AND total_fee_amount > 0)
            OR (overall_status = N''PARTIAL'' AND total_paid_amount > 0 AND total_paid_amount < total_fee_amount)
            OR (overall_status = N''PAID'' AND total_paid_amount = total_fee_amount)
        )
    );
    ');

    COMMIT TRANSACTION;
END;
GO

/* 4B. CREATE TABLE IF NOT EXISTS */
IF OBJECT_ID(N'finance_schema.student_fee_record', N'U') IS NULL
BEGIN
    CREATE TABLE finance_schema.student_fee_record
    (
        student_fee_record_id   BIGINT IDENTITY(1,1) NOT NULL,
        fee_structure_term_id   BIGINT NOT NULL,
        school_id               BIGINT NOT NULL,
        branch_id               BIGINT NOT NULL,
        academic_year_id        BIGINT NOT NULL,
        class_id                BIGINT NOT NULL,
        section_id              BIGINT NOT NULL,
        student_id              BIGINT NOT NULL,
        residency_type          NVARCHAR(20) NOT NULL,

        /* Term 1 Financial State */
        term1_tuition_amount    DECIMAL(12,2) NOT NULL,
        term1_tuition_paid      DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_tuition_paid DEFAULT (0),
        term1_tuition_balance   DECIMAL(12,2) NOT NULL,
        term1_tuition_status    NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term1_tuition_status DEFAULT (N'PENDING'),
        term1_residency_amount  DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_residency_amount DEFAULT (0),
        term1_residency_paid    DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_residency_paid DEFAULT (0),
        term1_residency_balance DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_residency_balance DEFAULT (0),
        term1_residency_status  NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term1_residency_status DEFAULT (N'NOT_APPLICABLE'),
        term1_total_amount      DECIMAL(12,2) NOT NULL,
        term1_total_paid        DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term1_total_paid DEFAULT (0),
        term1_total_balance     DECIMAL(12,2) NOT NULL,
        term1_status            NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term1_status DEFAULT (N'PENDING'),

        /* Term 2 Financial State */
        term2_tuition_amount    DECIMAL(12,2) NOT NULL,
        term2_tuition_paid      DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_tuition_paid DEFAULT (0),
        term2_tuition_balance   DECIMAL(12,2) NOT NULL,
        term2_tuition_status    NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term2_tuition_status DEFAULT (N'PENDING'),
        term2_residency_amount  DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_residency_amount DEFAULT (0),
        term2_residency_paid    DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_residency_paid DEFAULT (0),
        term2_residency_balance DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_residency_balance DEFAULT (0),
        term2_residency_status  NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term2_residency_status DEFAULT (N'NOT_APPLICABLE'),
        term2_total_amount      DECIMAL(12,2) NOT NULL,
        term2_total_paid        DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term2_total_paid DEFAULT (0),
        term2_total_balance     DECIMAL(12,2) NOT NULL,
        term2_status            NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term2_status DEFAULT (N'PENDING'),

        /* Term 3 Financial State */
        term3_tuition_amount    DECIMAL(12,2) NOT NULL,
        term3_tuition_paid      DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_tuition_paid DEFAULT (0),
        term3_tuition_balance   DECIMAL(12,2) NOT NULL,
        term3_tuition_status    NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term3_tuition_status DEFAULT (N'PENDING'),
        term3_residency_amount  DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_residency_amount DEFAULT (0),
        term3_residency_paid    DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_residency_paid DEFAULT (0),
        term3_residency_balance DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_residency_balance DEFAULT (0),
        term3_residency_status  NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term3_residency_status DEFAULT (N'NOT_APPLICABLE'),
        term3_total_amount      DECIMAL(12,2) NOT NULL,
        term3_total_paid        DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_term3_total_paid DEFAULT (0),
        term3_total_balance     DECIMAL(12,2) NOT NULL,
        term3_status            NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_term3_status DEFAULT (N'PENDING'),

        /* Other Fee Financial State */
        other_fee_amount        DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_other_amount DEFAULT (0),
        other_fee_paid          DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_other_paid DEFAULT (0),
        other_fee_balance       DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_other_balance DEFAULT (0),
        other_fee_status        NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_other_status DEFAULT (N'NOT_APPLICABLE'),

        /* Overall Financial Totals & Single Scholarship Column */
        scholarship_amount      DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_scholarship_amount DEFAULT (0),
        total_fee_amount        DECIMAL(12,2) NOT NULL,
        total_paid_amount       DECIMAL(12,2) NOT NULL CONSTRAINT DF_student_fee_record_total_paid_amount DEFAULT (0),
        total_balance_amount    DECIMAL(12,2) NOT NULL,
        overall_status          NVARCHAR(20) NOT NULL CONSTRAINT DF_student_fee_record_overall_status DEFAULT (N'PENDING'),

        /* Concurrency & Audit */
        is_active               BIT NOT NULL CONSTRAINT DF_student_fee_record_is_active DEFAULT (1),
        created_at              DATETIME2(0) NOT NULL CONSTRAINT DF_student_fee_record_created_at DEFAULT (SYSUTCDATETIME()),
        created_by              BIGINT NOT NULL,
        updated_at              DATETIME2(0) NULL,
        updated_by              BIGINT NULL,
        row_version             ROWVERSION NOT NULL,

        /* Primary & Unique Scope Constraints */
        CONSTRAINT PK_student_fee_record PRIMARY KEY CLUSTERED (student_fee_record_id),
        CONSTRAINT UQ_student_fee_record_scope UNIQUE NONCLUSTERED (school_id, branch_id, academic_year_id, student_id),
        CONSTRAINT UQ_student_fee_record_hierarchy UNIQUE NONCLUSTERED (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id),

        /* Residency Type Validation */
        CONSTRAINT CK_student_fee_record_residency_type CHECK (residency_type IN (N'DAY_SCHOLAR', N'HOSTELLER')),

        /* Residency Component Integrity */
        CONSTRAINT CK_student_fee_record_residency CHECK (
            term1_residency_amount >= 0 AND term1_residency_paid >= 0 AND term1_residency_balance >= 0
            AND term1_residency_paid <= term1_residency_amount
            AND term1_residency_balance = term1_residency_amount - term1_residency_paid
            AND term1_residency_status IN (N'NOT_APPLICABLE', N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term1_residency_amount = 0 AND term1_residency_paid = 0 AND term1_residency_status = N'NOT_APPLICABLE')
                OR (term1_residency_amount > 0 AND term1_residency_paid = 0 AND term1_residency_status = N'PENDING')
                OR (term1_residency_paid > 0 AND term1_residency_paid < term1_residency_amount AND term1_residency_status = N'PARTIAL')
                OR (term1_residency_paid = term1_residency_amount AND term1_residency_amount > 0 AND term1_residency_status = N'PAID')
            )
            AND term2_residency_amount >= 0 AND term2_residency_paid >= 0 AND term2_residency_balance >= 0
            AND term2_residency_paid <= term2_residency_amount
            AND term2_residency_balance = term2_residency_amount - term2_residency_paid
            AND term2_residency_status IN (N'NOT_APPLICABLE', N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term2_residency_amount = 0 AND term2_residency_paid = 0 AND term2_residency_status = N'NOT_APPLICABLE')
                OR (term2_residency_amount > 0 AND term2_residency_paid = 0 AND term2_residency_status = N'PENDING')
                OR (term2_residency_paid > 0 AND term2_residency_paid < term2_residency_amount AND term2_residency_status = N'PARTIAL')
                OR (term2_residency_paid = term2_residency_amount AND term2_residency_amount > 0 AND term2_residency_status = N'PAID')
            )
            AND term3_residency_amount >= 0 AND term3_residency_paid >= 0 AND term3_residency_balance >= 0
            AND term3_residency_paid <= term3_residency_amount
            AND term3_residency_balance = term3_residency_amount - term3_residency_paid
            AND term3_residency_status IN (N'NOT_APPLICABLE', N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term3_residency_amount = 0 AND term3_residency_paid = 0 AND term3_residency_status = N'NOT_APPLICABLE')
                OR (term3_residency_amount > 0 AND term3_residency_paid = 0 AND term3_residency_status = N'PENDING')
                OR (term3_residency_paid > 0 AND term3_residency_paid < term3_residency_amount AND term3_residency_status = N'PARTIAL')
                OR (term3_residency_paid = term3_residency_amount AND term3_residency_amount > 0 AND term3_residency_status = N'PAID')
            )
        ),

        /* Tuition Component Integrity */
        CONSTRAINT CK_student_fee_record_tuition CHECK (
            term1_tuition_amount >= 0 AND term1_tuition_paid >= 0 AND term1_tuition_balance >= 0
            AND term1_tuition_paid <= term1_tuition_amount
            AND term1_tuition_balance = term1_tuition_amount - term1_tuition_paid
            AND term1_tuition_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term1_tuition_status = N'PENDING' AND term1_tuition_paid = 0 AND term1_tuition_amount > 0)
                OR (term1_tuition_status = N'PARTIAL' AND term1_tuition_paid > 0 AND term1_tuition_paid < term1_tuition_amount)
                OR (term1_tuition_status = N'PAID' AND term1_tuition_paid = term1_tuition_amount)
            )
            AND term2_tuition_amount >= 0 AND term2_tuition_paid >= 0 AND term2_tuition_balance >= 0
            AND term2_tuition_paid <= term2_tuition_amount
            AND term2_tuition_balance = term2_tuition_amount - term2_tuition_paid
            AND term2_tuition_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term2_tuition_status = N'PENDING' AND term2_tuition_paid = 0 AND term2_tuition_amount > 0)
                OR (term2_tuition_status = N'PARTIAL' AND term2_tuition_paid > 0 AND term2_tuition_paid < term2_tuition_amount)
                OR (term2_tuition_status = N'PAID' AND term2_tuition_paid = term2_tuition_amount)
            )
            AND term3_tuition_amount >= 0 AND term3_tuition_paid >= 0 AND term3_tuition_balance >= 0
            AND term3_tuition_paid <= term3_tuition_amount
            AND term3_tuition_balance = term3_tuition_amount - term3_tuition_paid
            AND term3_tuition_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term3_tuition_status = N'PENDING' AND term3_tuition_paid = 0 AND term3_tuition_amount > 0)
                OR (term3_tuition_status = N'PARTIAL' AND term3_tuition_paid > 0 AND term3_tuition_paid < term3_tuition_amount)
                OR (term3_tuition_status = N'PAID' AND term3_tuition_paid = term3_tuition_amount)
            )
        ),

        /* Other Fee Component Integrity */
        CONSTRAINT CK_student_fee_record_other_fee CHECK (
            other_fee_amount >= 0 AND other_fee_paid >= 0 AND other_fee_balance >= 0
            AND other_fee_paid <= other_fee_amount
            AND other_fee_balance = other_fee_amount - other_fee_paid
            AND (
                (other_fee_status = N'NOT_APPLICABLE' AND other_fee_amount = 0 AND other_fee_paid = 0 AND other_fee_balance = 0)
                OR (other_fee_status = N'PENDING' AND other_fee_paid = 0 AND other_fee_amount > 0)
                OR (other_fee_status = N'PARTIAL' AND other_fee_paid > 0 AND other_fee_paid < other_fee_amount)
                OR (other_fee_status = N'PAID' AND other_fee_paid = other_fee_amount)
            )
        ),

        /* Term Totals Reconciliation */
        CONSTRAINT CK_student_fee_record_term_totals CHECK (
            term1_total_amount = term1_tuition_amount + term1_residency_amount
            AND term1_total_paid = term1_tuition_paid + term1_residency_paid
            AND term1_total_balance = term1_total_amount - term1_total_paid
            AND term1_total_amount >= 0 AND term1_total_paid >= 0 AND term1_total_balance >= 0
            AND term1_total_paid <= term1_total_amount
            AND term1_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term1_status = N'PENDING' AND term1_total_paid = 0 AND term1_total_amount > 0)
                OR (term1_status = N'PARTIAL' AND term1_total_paid > 0 AND term1_total_paid < term1_total_amount)
                OR (term1_status = N'PAID' AND term1_total_paid = term1_total_amount)
            )
            AND term2_total_amount = term2_tuition_amount + term2_residency_amount
            AND term2_total_paid = term2_tuition_paid + term2_residency_paid
            AND term2_total_balance = term2_total_amount - term2_total_paid
            AND term2_total_amount >= 0 AND term2_total_paid >= 0 AND term2_total_balance >= 0
            AND term2_total_paid <= term2_total_amount
            AND term2_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term2_status = N'PENDING' AND term2_total_paid = 0 AND term2_total_amount > 0)
                OR (term2_status = N'PARTIAL' AND term2_total_paid > 0 AND term2_total_paid < term2_total_amount)
                OR (term2_status = N'PAID' AND term2_total_paid = term2_total_amount)
            )
            AND term3_total_amount = term3_tuition_amount + term3_residency_amount
            AND term3_total_paid = term3_tuition_paid + term3_residency_paid
            AND term3_total_balance = term3_total_amount - term3_total_paid
            AND term3_total_amount >= 0 AND term3_total_paid >= 0 AND term3_total_balance >= 0
            AND term3_total_paid <= term3_total_amount
            AND term3_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (term3_status = N'PENDING' AND term3_total_paid = 0 AND term3_total_amount > 0)
                OR (term3_status = N'PARTIAL' AND term3_total_paid > 0 AND term3_total_paid < term3_total_amount)
                OR (term3_status = N'PAID' AND term3_total_paid = term3_total_amount)
            )
        ),

        /* Overall Financial Totals Reconciliation */
        CONSTRAINT CK_student_fee_record_overall_totals CHECK (
            total_fee_amount = (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount) - scholarship_amount
            AND total_paid_amount = term1_total_paid + term2_total_paid + term3_total_paid + other_fee_paid
            AND scholarship_amount >= 0
            AND scholarship_amount <= (term1_total_amount + term2_total_amount + term3_total_amount + other_fee_amount)
            AND total_paid_amount <= total_fee_amount
            AND total_balance_amount = total_fee_amount - total_paid_amount
            AND total_fee_amount >= 0 AND total_paid_amount >= 0 AND total_balance_amount >= 0
            AND overall_status IN (N'PENDING', N'PARTIAL', N'PAID')
            AND (
                (overall_status = N'PENDING' AND total_paid_amount = 0 AND total_fee_amount > 0)
                OR (overall_status = N'PARTIAL' AND total_paid_amount > 0 AND total_paid_amount < total_fee_amount)
                OR (overall_status = N'PAID' AND total_paid_amount = total_fee_amount)
            )
        ),

        /* Composite Scope FK to Fee Structure Term */
        CONSTRAINT FK_student_fee_record_structure FOREIGN KEY (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id)
            REFERENCES finance_schema.fee_structure_term (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id),

        /* Institutional Master Relationships */
        CONSTRAINT FK_student_fee_record_school FOREIGN KEY (school_id)
            REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_fee_record_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_student_fee_record_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_student_fee_record_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_student_fee_record_section_scope FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_student_fee_record_student FOREIGN KEY (student_id)
            REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_fee_record_created_by FOREIGN KEY (created_by)
            REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_fee_record_updated_by FOREIGN KEY (updated_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* 5. TABLE 3: finance_schema.fee_payment_transaction                         */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'finance_schema.fee_payment_transaction', N'U') IS NULL
BEGIN
    CREATE TABLE finance_schema.fee_payment_transaction
    (
        fee_payment_transaction_id BIGINT IDENTITY(1,1) NOT NULL,
        student_fee_record_id      BIGINT NOT NULL,
        school_id                  BIGINT NOT NULL,
        branch_id                  BIGINT NOT NULL,
        academic_year_id           BIGINT NOT NULL,
        student_id                 BIGINT NOT NULL,
        class_id                   BIGINT NOT NULL,
        section_id                 BIGINT NOT NULL,
        fee_type                   NVARCHAR(20) NOT NULL,
        term_number                TINYINT NULL,
        transaction_type           NVARCHAR(20) NOT NULL CONSTRAINT DF_fee_payment_transaction_type DEFAULT (N'PAYMENT'),
        status                     NVARCHAR(20) NOT NULL CONSTRAINT DF_fee_payment_transaction_status DEFAULT (N'SUCCESS'),
        amount                     DECIMAL(12,2) NOT NULL,
        receipt_number             NVARCHAR(20) NOT NULL,
        payment_method             NVARCHAR(20) NOT NULL,
        payment_gateway            NVARCHAR(50) NULL,
        gateway_transaction_id     NVARCHAR(100) NULL,
        transaction_reference      NVARCHAR(100) NULL,
        parent_transaction_id      BIGINT NULL,
        remarks                    NVARCHAR(500) NULL,
        paid_at                    DATETIME2(0) NOT NULL CONSTRAINT DF_fee_payment_transaction_paid_at DEFAULT (SYSUTCDATETIME()),
        created_at                 DATETIME2(0) NOT NULL CONSTRAINT DF_fee_payment_transaction_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                 BIGINT NOT NULL,
        updated_at                 DATETIME2(0) NULL,
        updated_by                 BIGINT NULL,
        row_version                ROWVERSION NOT NULL,

        CONSTRAINT PK_fee_payment_transaction PRIMARY KEY CLUSTERED (fee_payment_transaction_id),

        /* Transaction Values and Types */
        CONSTRAINT CK_fee_payment_transaction_amount CHECK (amount > 0),
        CONSTRAINT CK_fee_payment_transaction_fee_type CHECK (fee_type IN (N'TUITION', N'HOSTEL', N'TRANSPORT', N'OTHER')),
        CONSTRAINT CK_fee_payment_transaction_term CHECK (
            (fee_type IN (N'TUITION', N'HOSTEL', N'TRANSPORT') AND term_number IN (1, 2, 3))
            OR (fee_type = N'OTHER' AND term_number IS NULL)
        ),
        CONSTRAINT CK_fee_payment_transaction_type CHECK (transaction_type IN (N'PAYMENT', N'REFUND')),
        CONSTRAINT CK_fee_payment_transaction_status CHECK (status IN (N'PENDING', N'SUCCESS', N'FAILED', N'CANCELLED')),
        CONSTRAINT CK_fee_payment_transaction_method CHECK (payment_method IN (N'CASH', N'CARD', N'UPI', N'BANK_TRANSFER', N'CHEQUE', N'ONLINE')),

        /* Receipt Format: FEE-YYYY-NNNNNN for PAYMENT; REF-YYYY-NNNNNN for REFUND */
        CONSTRAINT CK_fee_payment_transaction_receipt CHECK (
            (transaction_type = N'PAYMENT' AND receipt_number LIKE N'FEE-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
            OR (transaction_type = N'REFUND' AND receipt_number LIKE N'REF-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
        ),

        /* Refund Parent Relationship: REFUND MUST have parent_transaction_id; PAYMENT must NOT */
        CONSTRAINT CK_fee_payment_transaction_refund_parent CHECK (
            (transaction_type = N'REFUND' AND parent_transaction_id IS NOT NULL)
            OR (transaction_type = N'PAYMENT' AND parent_transaction_id IS NULL)
        ),

        /* Parent Transaction Self-Reference */
        CONSTRAINT FK_fee_payment_transaction_parent FOREIGN KEY (parent_transaction_id)
            REFERENCES finance_schema.fee_payment_transaction (fee_payment_transaction_id),

        /* Composite Scope FK to Student Fee Record Hierarchy */
        CONSTRAINT FK_fee_payment_transaction_record FOREIGN KEY (
            student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id
        ) REFERENCES finance_schema.student_fee_record (
            student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id
        ),

        /* Institutional Master Relationships */
        CONSTRAINT FK_fee_payment_transaction_school FOREIGN KEY (school_id)
            REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_fee_payment_transaction_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_fee_payment_transaction_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_fee_payment_transaction_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_fee_payment_transaction_section_scope FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_fee_payment_transaction_student FOREIGN KEY (student_id)
            REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_fee_payment_transaction_created_by FOREIGN KEY (created_by)
            REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_fee_payment_transaction_updated_by FOREIGN KEY (updated_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* 6. OPERATIONAL INDEXES                                                     */
/* -------------------------------------------------------------------------- */

/* Fee Structure: Single active structure per class per academic year within branch scope */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_fee_structure_term_active_scope'
      AND object_id = OBJECT_ID(N'finance_schema.fee_structure_term')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_fee_structure_term_active_scope
        ON finance_schema.fee_structure_term (school_id, branch_id, academic_year_id, class_id)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_structure_term_active_lookup'
      AND object_id = OBJECT_ID(N'finance_schema.fee_structure_term')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_structure_term_active_lookup
        ON finance_schema.fee_structure_term (school_id, branch_id, academic_year_id, is_active, class_id);
END;
GO

/* Student Fee Record: Student + Academic Year lookup */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_fee_record_student_year'
      AND object_id = OBJECT_ID(N'finance_schema.student_fee_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_fee_record_student_year
        ON finance_schema.student_fee_record (student_id, academic_year_id);
END;
GO

/* Student Fee Record: Class/Section scope batch lookup */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_fee_record_scope'
      AND object_id = OBJECT_ID(N'finance_schema.student_fee_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_fee_record_scope
        ON finance_schema.student_fee_record (school_id, branch_id, academic_year_id, class_id, section_id);
END;
GO

/* Student Fee Record: Outstanding balance / collection tracking */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_fee_record_outstanding'
      AND object_id = OBJECT_ID(N'finance_schema.student_fee_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_fee_record_outstanding
        ON finance_schema.student_fee_record (school_id, branch_id, academic_year_id, overall_status)
        INCLUDE (total_balance_amount);
END;
GO

/* Fee Payment Transaction: School/Year receipt uniqueness */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_fee_payment_transaction_receipt'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_fee_payment_transaction_receipt
        ON finance_schema.fee_payment_transaction (school_id, academic_year_id, receipt_number);
END;
GO

/* Fee Payment Transaction: Student transaction ledger access */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_student_created'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_student_created
        ON finance_schema.fee_payment_transaction (student_id, academic_year_id, created_at DESC);
END;
GO

/* Fee Payment Transaction: Student Fee Record ledger access */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_record_created'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_record_created
        ON finance_schema.fee_payment_transaction (student_fee_record_id, created_at DESC);
END;
GO

/* Fee Payment Transaction: Fee type & term slice queries */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_type'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_type
        ON finance_schema.fee_payment_transaction (school_id, branch_id, academic_year_id, fee_type, term_number);
END;
GO

/* Fee Payment Transaction: Payment gateway reconciliation (Filtered) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_gateway'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_gateway
        ON finance_schema.fee_payment_transaction (gateway_transaction_id)
        WHERE gateway_transaction_id IS NOT NULL;
END;
GO

/* Fee Payment Transaction: Parent transaction refund audit trail (Filtered) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_fee_payment_transaction_parent'
      AND object_id = OBJECT_ID(N'finance_schema.fee_payment_transaction')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fee_payment_transaction_parent
        ON finance_schema.fee_payment_transaction (parent_transaction_id)
        WHERE parent_transaction_id IS NOT NULL;
END;
GO