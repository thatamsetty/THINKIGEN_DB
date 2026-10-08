/*
    ================================================================================
    THINKIGEN FINANCE MODULE — MOCK DATA SEED SCRIPT (STUDENTS 1 TO 30)
    ================================================================================
    Updated Rules:
      1. OTHER FEE IS APPLICABLE TO EVERY STUDENT (no student has NOT_APPLICABLE).
         - Base Other Fee = 3,000.00 per student (Annual Lab, Library & Exam Composite).
         - Students 1–10 (Paid): other_fee_paid = 3,000.00, balance = 0.00, status = 'PAID'.
         - Students 11–20 (Partial): other_fee_paid = 1,500.00, balance = 1,500.00, status = 'PARTIAL'.
         - Students 21–25 (Pending): other_fee_paid = 0.00, balance = 3,000.00, status = 'PENDING'.
         - Students 26–30 (Scholarship): other_fee_paid = 3,000.00, balance = 0.00, status = 'PAID'.
      2. TRANSACTION REFERENCE CLARITY:
         - transaction_reference represents the actual Transaction Reference ID / Bank Reference /
           UTR / Authorization Code / Cheque No.
         - Distinct from receipt_number (internal receipt) and gateway_transaction_id (gateway token).
    ================================================================================
*/

-- If running in SSMS, ensure you are connected to your database or uncomment and set your DB name:
-- USE [YourDatabaseName];
-- GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'----------------------------------------------------------------------';
    PRINT N'1. INITIALIZING SEED PREREQUISITES & AUDIT ACTOR';
    PRINT N'----------------------------------------------------------------------';

    DECLARE @admin_user_id BIGINT;
    SELECT TOP 1 @admin_user_id = user_id 
    FROM security_schema.users 
    ORDER BY user_id;

    IF @admin_user_id IS NULL
    BEGIN
        THROW 51000, N'Seed failed: No users found in security_schema.users to populate audit columns.', 1;
    END;

    PRINT N'Using audit user_id: ' + CAST(@admin_user_id AS NVARCHAR(10));

    PRINT N'----------------------------------------------------------------------';
    PRINT N'2. CLEANING EXISTING FINANCE DATA FOR STUDENTS 1 TO 30';
    PRINT N'----------------------------------------------------------------------';

    DELETE FROM finance_schema.fee_payment_transaction
    WHERE student_id BETWEEN 1 AND 30;

    DELETE FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30;

    PRINT N'Cleared existing finance records for students 1 to 30.';

    PRINT N'----------------------------------------------------------------------';
    PRINT N'3. ENSURING ACTIVE FEE STRUCTURES FOR REQUIRED CLASSES';
    PRINT N'----------------------------------------------------------------------';

    INSERT INTO finance_schema.fee_structure_term
    (
        school_id, branch_id, academic_year_id, class_id,
        total_amount, term1_amount, term1_due_date,
        term2_amount, term2_due_date,
        term3_amount, term3_due_date,
        status, is_active, created_by
    )
    SELECT
        src.school_id, src.branch_id, src.academic_year_id, src.class_id,
        75000.00, 25000.00, '2026-06-30',
        25000.00, '2026-10-31',
        25000.00, '2027-01-31',
        N'ACTIVE', 1, @admin_user_id
    FROM
    (
        SELECT DISTINCT school_id, branch_id, academic_year_id, class_id
        FROM student_schema.student
        WHERE student_id BETWEEN 1 AND 30
    ) src
    WHERE NOT EXISTS (
        SELECT 1 
        FROM finance_schema.fee_structure_term fst
        WHERE fst.school_id = src.school_id
          AND fst.branch_id = src.branch_id
          AND fst.academic_year_id = src.academic_year_id
          AND fst.class_id = src.class_id
          AND fst.is_active = 1
    );

    PRINT N'Active fee structures verified / created.';

    PRINT N'----------------------------------------------------------------------';
    PRINT N'4. SEEDING student_fee_record (ALL STUDENTS HAVE OTHER FEE APPLICABLE)';
    PRINT N'----------------------------------------------------------------------';

    ;WITH StudentBase AS (
        SELECT 
            st.student_id,
            st.school_id,
            st.branch_id,
            st.academic_year_id,
            st.class_id,
            st.section_id,
            st.residency_type,
            fst.fee_structure_term_id,
            CASE 
                WHEN st.student_id BETWEEN 1 AND 10  THEN N'PAID'
                WHEN st.student_id BETWEEN 11 AND 20 THEN N'PARTIAL'
                WHEN st.student_id BETWEEN 21 AND 25 THEN N'PENDING'
                ELSE N'SCHOLARSHIP'
            END AS profile_type,
            /* Other Fee is APPLICABLE to 100% of students */
            CAST(3000.00 AS DECIMAL(12,2)) AS other_fee_amt,
            /* Scholarship Amount */
            CASE WHEN st.student_id BETWEEN 26 AND 30 THEN CAST(10000.00 AS DECIMAL(12,2)) ELSE CAST(0.00 AS DECIMAL(12,2)) END AS scholarship_amt
        FROM student_schema.student st
        JOIN finance_schema.fee_structure_term fst
          ON fst.school_id = st.school_id
         AND fst.branch_id = st.branch_id
         AND fst.academic_year_id = st.academic_year_id
         AND fst.class_id = st.class_id
         AND fst.is_active = 1
        WHERE st.student_id BETWEEN 1 AND 30
    ),
    CalculatedRecords AS (
        SELECT
            sb.student_id,
            sb.school_id,
            sb.branch_id,
            sb.academic_year_id,
            sb.class_id,
            sb.section_id,
            sb.residency_type,
            sb.fee_structure_term_id,

            /* Term 1 Tuition */
            CAST(25000.00 AS DECIMAL(12,2)) AS t1_tui_amt,
            CASE 
                WHEN sb.profile_type IN (N'PAID', N'PARTIAL', N'SCHOLARSHIP') THEN CAST(25000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t1_tui_paid,

            /* Term 1 Residency:
               HOSTELLER: 15000.00 (hostel charges)
               DAY_SCHOLAR WITH TRANSPORT: 5000.00 (transport charges)
            */
            CASE 
                WHEN sb.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2))
                WHEN sb.residency_type = N'DAY_SCHOLAR' THEN CAST(5000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t1_res_amt,
            CASE 
                WHEN sb.profile_type IN (N'PAID', N'PARTIAL', N'SCHOLARSHIP') AND sb.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2))
                WHEN sb.profile_type IN (N'PAID', N'PARTIAL', N'SCHOLARSHIP') AND sb.residency_type = N'DAY_SCHOLAR' THEN CAST(5000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t1_res_paid,

            /* Term 2 Tuition */
            CAST(25000.00 AS DECIMAL(12,2)) AS t2_tui_amt,
            CASE 
                WHEN sb.profile_type = N'PAID' THEN CAST(25000.00 AS DECIMAL(12,2))
                WHEN sb.profile_type = N'PARTIAL' THEN CAST(10000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t2_tui_paid,

            /* Term 2 Residency */
            CASE 
                WHEN sb.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2))
                WHEN sb.residency_type = N'DAY_SCHOLAR' THEN CAST(5000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t2_res_amt,
            CASE 
                WHEN sb.profile_type = N'PAID' AND sb.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2))
                WHEN sb.profile_type = N'PAID' AND sb.residency_type = N'DAY_SCHOLAR' THEN CAST(5000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t2_res_paid,

            /* Term 3 Tuition */
            CAST(25000.00 AS DECIMAL(12,2)) AS t3_tui_amt,
            CASE 
                WHEN sb.profile_type = N'PAID' THEN CAST(25000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t3_tui_paid,

            /* Term 3 Residency */
            CASE 
                WHEN sb.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2))
                WHEN sb.residency_type = N'DAY_SCHOLAR' THEN CAST(5000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t3_res_amt,
            CASE 
                WHEN sb.profile_type = N'PAID' AND sb.residency_type = N'HOSTELLER' THEN CAST(15000.00 AS DECIMAL(12,2))
                WHEN sb.profile_type = N'PAID' AND sb.residency_type = N'DAY_SCHOLAR' THEN CAST(5000.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS t3_res_paid,

            /* Other Fee: Applicable to all 30 students */
            sb.other_fee_amt AS oth_amt,
            CASE 
                WHEN sb.profile_type IN (N'PAID', N'SCHOLARSHIP') THEN CAST(3000.00 AS DECIMAL(12,2))
                WHEN sb.profile_type = N'PARTIAL' THEN CAST(1500.00 AS DECIMAL(12,2))
                ELSE CAST(0.00 AS DECIMAL(12,2))
            END AS oth_paid,

            /* Single Scholarship */
            sb.scholarship_amt AS schol_amt
        FROM StudentBase sb
    )
    INSERT INTO finance_schema.student_fee_record
    (
        fee_structure_term_id, school_id, branch_id, academic_year_id, class_id, section_id, student_id,
        residency_type,

        /* Term 1 */
        term1_tuition_amount, term1_tuition_paid, term1_tuition_balance, term1_tuition_status,
        term1_residency_amount, term1_residency_paid, term1_residency_balance, term1_residency_status,
        term1_total_amount, term1_total_paid, term1_total_balance, term1_status,

        /* Term 2 */
        term2_tuition_amount, term2_tuition_paid, term2_tuition_balance, term2_tuition_status,
        term2_residency_amount, term2_residency_paid, term2_residency_balance, term2_residency_status,
        term2_total_amount, term2_total_paid, term2_total_balance, term2_status,

        /* Term 3 */
        term3_tuition_amount, term3_tuition_paid, term3_tuition_balance, term3_tuition_status,
        term3_residency_amount, term3_residency_paid, term3_residency_balance, term3_residency_status,
        term3_total_amount, term3_total_paid, term3_total_balance, term3_status,

        /* Other Fee (Applicable to every student: PENDING, PARTIAL, or PAID) */
        other_fee_amount, other_fee_paid, other_fee_balance, other_fee_status,

        /* Overall Financial Totals */
        scholarship_amount, total_fee_amount, total_paid_amount, total_balance_amount, overall_status,

        /* Concurrency & Audit */
        is_active, created_by
    )
    SELECT
        cr.fee_structure_term_id, cr.school_id, cr.branch_id, cr.academic_year_id, cr.class_id, cr.section_id, cr.student_id,
        cr.residency_type,

        /* Term 1 Tuition */
        cr.t1_tui_amt, cr.t1_tui_paid, (cr.t1_tui_amt - cr.t1_tui_paid),
        CASE 
            WHEN cr.t1_tui_paid = 0 THEN N'PENDING' 
            WHEN cr.t1_tui_paid = cr.t1_tui_amt THEN N'PAID' 
            ELSE N'PARTIAL' 
        END,

        /* Term 1 Residency */
        cr.t1_res_amt, cr.t1_res_paid, (cr.t1_res_amt - cr.t1_res_paid),
        CASE 
            WHEN cr.t1_res_amt = 0 AND cr.t1_res_paid = 0 THEN N'NOT_APPLICABLE'
            WHEN cr.t1_res_paid = 0 THEN N'PENDING'
            WHEN cr.t1_res_paid = cr.t1_res_amt THEN N'PAID'
            ELSE N'PARTIAL'
        END,

        /* Term 1 Totals */
        (cr.t1_tui_amt + cr.t1_res_amt) AS t1_tot_amt,
        (cr.t1_tui_paid + cr.t1_res_paid) AS t1_tot_paid,
        ((cr.t1_tui_amt + cr.t1_res_amt) - (cr.t1_tui_paid + cr.t1_res_paid)) AS t1_tot_bal,
        CASE 
            WHEN (cr.t1_tui_paid + cr.t1_res_paid) = 0 THEN N'PENDING'
            WHEN (cr.t1_tui_paid + cr.t1_res_paid) = (cr.t1_tui_amt + cr.t1_res_amt) THEN N'PAID'
            ELSE N'PARTIAL'
        END AS t1_tot_stat,

        /* Term 2 Tuition */
        cr.t2_tui_amt, cr.t2_tui_paid, (cr.t2_tui_amt - cr.t2_tui_paid),
        CASE 
            WHEN cr.t2_tui_paid = 0 THEN N'PENDING' 
            WHEN cr.t2_tui_paid = cr.t2_tui_amt THEN N'PAID' 
            ELSE N'PARTIAL' 
        END,

        /* Term 2 Residency */
        cr.t2_res_amt, cr.t2_res_paid, (cr.t2_res_amt - cr.t2_res_paid),
        CASE 
            WHEN cr.t2_res_amt = 0 AND cr.t2_res_paid = 0 THEN N'NOT_APPLICABLE'
            WHEN cr.t2_res_paid = 0 THEN N'PENDING'
            WHEN cr.t2_res_paid = cr.t2_res_amt THEN N'PAID'
            ELSE N'PARTIAL'
        END,

        /* Term 2 Totals */
        (cr.t2_tui_amt + cr.t2_res_amt) AS t2_tot_amt,
        (cr.t2_tui_paid + cr.t2_res_paid) AS t2_tot_paid,
        ((cr.t2_tui_amt + cr.t2_res_amt) - (cr.t2_tui_paid + cr.t2_res_paid)) AS t2_tot_bal,
        CASE 
            WHEN (cr.t2_tui_paid + cr.t2_res_paid) = 0 THEN N'PENDING'
            WHEN (cr.t2_tui_paid + cr.t2_res_paid) = (cr.t2_tui_amt + cr.t2_res_amt) THEN N'PAID'
            ELSE N'PARTIAL'
        END AS t2_tot_stat,

        /* Term 3 Tuition */
        cr.t3_tui_amt, cr.t3_tui_paid, (cr.t3_tui_amt - cr.t3_tui_paid),
        CASE 
            WHEN cr.t3_tui_paid = 0 THEN N'PENDING' 
            WHEN cr.t3_tui_paid = cr.t3_tui_amt THEN N'PAID' 
            ELSE N'PARTIAL' 
        END,

        /* Term 3 Residency */
        cr.t3_res_amt, cr.t3_res_paid, (cr.t3_res_amt - cr.t3_res_paid),
        CASE 
            WHEN cr.t3_res_amt = 0 AND cr.t3_res_paid = 0 THEN N'NOT_APPLICABLE'
            WHEN cr.t3_res_paid = 0 THEN N'PENDING'
            WHEN cr.t3_res_paid = cr.t3_res_amt THEN N'PAID'
            ELSE N'PARTIAL'
        END,

        /* Term 3 Totals */
        (cr.t3_tui_amt + cr.t3_res_amt) AS t3_tot_amt,
        (cr.t3_tui_paid + cr.t3_res_paid) AS t3_tot_paid,
        ((cr.t3_tui_amt + cr.t3_res_amt) - (cr.t3_tui_paid + cr.t3_res_paid)) AS t3_tot_bal,
        CASE 
            WHEN (cr.t3_tui_paid + cr.t3_res_paid) = 0 THEN N'PENDING'
            WHEN (cr.t3_tui_paid + cr.t3_res_paid) = (cr.t3_tui_amt + cr.t3_res_amt) THEN N'PAID'
            ELSE N'PARTIAL'
        END AS t3_tot_stat,

        /* Other Fee: Strictly PENDING, PARTIAL, or PAID (never NOT_APPLICABLE) */
        cr.oth_amt, cr.oth_paid, (cr.oth_amt - cr.oth_paid),
        CASE 
            WHEN cr.oth_paid = 0 THEN N'PENDING'
            WHEN cr.oth_paid = cr.oth_amt THEN N'PAID'
            ELSE N'PARTIAL'
        END,

        /* Overall Financial Totals: total_fee_amount = sum(term totals) + other_fee - scholarship */
        cr.schol_amt,
        (((cr.t1_tui_amt + cr.t1_res_amt) +
          (cr.t2_tui_amt + cr.t2_res_amt) +
          (cr.t3_tui_amt + cr.t3_res_amt) + cr.oth_amt) - cr.schol_amt) AS tot_fee,
        ((cr.t1_tui_paid + cr.t1_res_paid) +
         (cr.t2_tui_paid + cr.t2_res_paid) +
         (cr.t3_tui_paid + cr.t3_res_paid) + cr.oth_paid) AS tot_paid,
        ((((cr.t1_tui_amt + cr.t1_res_amt) +
           (cr.t2_tui_amt + cr.t2_res_amt) +
           (cr.t3_tui_amt + cr.t3_res_amt) + cr.oth_amt) - cr.schol_amt) -
         ((cr.t1_tui_paid + cr.t1_res_paid) +
          (cr.t2_tui_paid + cr.t2_res_paid) +
          (cr.t3_tui_paid + cr.t3_res_paid) + cr.oth_paid)) AS tot_bal,
        /* Overall Status */
        CASE 
            WHEN ((cr.t1_tui_paid + cr.t1_res_paid) +
                  (cr.t2_tui_paid + cr.t2_res_paid) +
                  (cr.t3_tui_paid + cr.t3_res_paid) + cr.oth_paid) = 0 THEN N'PENDING'
            WHEN ((cr.t1_tui_paid + cr.t1_res_paid) +
                  (cr.t2_tui_paid + cr.t2_res_paid) +
                  (cr.t3_tui_paid + cr.t3_res_paid) + cr.oth_paid) = 
                 (((cr.t1_tui_amt + cr.t1_res_amt) +
                   (cr.t2_tui_amt + cr.t2_res_amt) +
                   (cr.t3_tui_amt + cr.t3_res_amt) + cr.oth_amt) - cr.schol_amt) THEN N'PAID'
            ELSE N'PARTIAL'
        END AS ov_stat,

        1, @admin_user_id
    FROM CalculatedRecords cr;

    PRINT N'Inserted student_fee_record for students 1 to 30 with Other Fee applied.';

    PRINT N'----------------------------------------------------------------------';
    PRINT N'5. SEEDING fee_payment_transaction WITH REALISTIC TRANSACTION REFERENCE IDs';
    PRINT N'----------------------------------------------------------------------';

    /* Helper table variable to stage payments */
    DECLARE @TxnStage TABLE
    (
        seq_num INT IDENTITY(1,1) PRIMARY KEY,
        student_fee_record_id BIGINT,
        school_id BIGINT,
        branch_id BIGINT,
        academic_year_id BIGINT,
        student_id BIGINT,
        class_id BIGINT,
        section_id BIGINT,
        fee_type NVARCHAR(20),
        term_number TINYINT,
        amount DECIMAL(12,2),
        payment_method NVARCHAR(20),
        payment_gateway NVARCHAR(50),
        gateway_transaction_id NVARCHAR(100),
        transaction_reference NVARCHAR(100),
        paid_at DATETIME2(0)
    );

    /* 5.1 Term 1 Tuition Payments */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'TUITION', 1, term1_tuition_paid, 
        N'ONLINE', N'RAZORPAY', 
        CONCAT(N'pay_rzp_t1tui_', RIGHT(CONCAT(N'000000', CAST(student_id AS NVARCHAR(6))), 6)),
        CONCAT(N'REF-TXN-T1TUI-', CAST(student_id AS NVARCHAR(6))),
        '2026-05-10T10:15:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND term1_tuition_paid > 0;

    /* 5.2 Term 1 Hostel Payments (for HOSTELLER) */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'HOSTEL', 1, term1_residency_paid, 
        N'BANK_TRANSFER', NULL, NULL,
        CONCAT(N'NEFT-HDFC-', RIGHT(CONCAT(N'00000000', CAST(student_id * 1111 AS NVARCHAR(8))), 8)),
        '2026-05-11T11:30:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND residency_type = N'HOSTELLER' AND term1_residency_paid > 0;

    /* 5.3 Term 1 Transport Payments (for DAY_SCHOLAR) */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'TRANSPORT', 1, term1_residency_paid, 
        N'UPI', NULL, NULL,
        CONCAT(N'UTR-42890', RIGHT(CONCAT(N'000000', CAST(student_id * 3333 AS NVARCHAR(7))), 7)),
        '2026-05-12T09:00:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND residency_type = N'DAY_SCHOLAR' AND term1_residency_paid > 0;

    /* 5.4 Term 2 Tuition Payments */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'TUITION', 2, term2_tuition_paid, 
        N'CARD', N'HDFC_PG', 
        CONCAT(N'pg_hdfc_t2tui_', RIGHT(CONCAT(N'000000', CAST(student_id AS NVARCHAR(6))), 6)),
        CONCAT(N'AUTH-CODE-', RIGHT(CONCAT(N'000000', CAST(student_id * 9876 AS NVARCHAR(6))), 6)),
        '2026-09-15T14:20:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND term2_tuition_paid > 0;

    /* 5.5 Term 2 Hostel Payments (for HOSTELLER) */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'HOSTEL', 2, term2_residency_paid, 
        N'BANK_TRANSFER', NULL, NULL,
        CONCAT(N'RTGS-SBI-', RIGHT(CONCAT(N'00000000', CAST(student_id * 2222 AS NVARCHAR(8))), 8)),
        '2026-09-16T15:00:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND residency_type = N'HOSTELLER' AND term2_residency_paid > 0;

    /* 5.6 Term 2 Transport Payments (for DAY_SCHOLAR) */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'TRANSPORT', 2, term2_residency_paid, 
        N'UPI', NULL, NULL,
        CONCAT(N'UTR-42891', RIGHT(CONCAT(N'000000', CAST(student_id * 4444 AS NVARCHAR(7))), 7)),
        '2026-09-17T12:10:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND residency_type = N'DAY_SCHOLAR' AND term2_residency_paid > 0;

    /* 5.7 Term 3 Tuition Payments */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'TUITION', 3, term3_tuition_paid, 
        N'ONLINE', N'RAZORPAY', 
        CONCAT(N'pay_rzp_t3tui_', RIGHT(CONCAT(N'000000', CAST(student_id AS NVARCHAR(6))), 6)),
        CONCAT(N'REF-TXN-T3TUI-', CAST(student_id AS NVARCHAR(6))),
        '2027-01-10T16:00:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND term3_tuition_paid > 0;

    /* 5.8 Term 3 Hostel Payments (for HOSTELLER) */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'HOSTEL', 3, term3_residency_paid, 
        N'BANK_TRANSFER', NULL, NULL,
        CONCAT(N'NEFT-ICICI-', RIGHT(CONCAT(N'00000000', CAST(student_id * 5555 AS NVARCHAR(8))), 8)),
        '2027-01-11T16:30:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND residency_type = N'HOSTELLER' AND term3_residency_paid > 0;

    /* 5.9 Term 3 Transport Payments (for DAY_SCHOLAR) */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'TRANSPORT', 3, term3_residency_paid, 
        N'UPI', NULL, NULL,
        CONCAT(N'UTR-42892', RIGHT(CONCAT(N'000000', CAST(student_id * 6666 AS NVARCHAR(7))), 7)),
        '2027-01-12T17:00:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND residency_type = N'DAY_SCHOLAR' AND term3_residency_paid > 0;

    /* 5.10 Other Fee Payments (For all students with other_fee_paid > 0) */
    INSERT INTO @TxnStage (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, fee_type, term_number, amount, payment_method, payment_gateway, gateway_transaction_id, transaction_reference, paid_at)
    SELECT 
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id, 
        N'OTHER', NULL, other_fee_paid, 
        N'CHEQUE', NULL, NULL,
        CONCAT(N'CHQ-', RIGHT(CONCAT(N'000000', CAST(700000 + student_id AS NVARCHAR(6))), 6)),
        '2026-06-01T10:00:00'
    FROM finance_schema.student_fee_record
    WHERE student_id BETWEEN 1 AND 30 AND other_fee_paid > 0;

    /* Insert All Standard Payments */
    INSERT INTO finance_schema.fee_payment_transaction
    (
        student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id,
        fee_type, term_number, transaction_type, amount,
        receipt_number, payment_method, payment_gateway, gateway_transaction_id, transaction_reference,
        parent_transaction_id, remarks, paid_at, created_by
    )
    SELECT
        t.student_fee_record_id, t.school_id, t.branch_id, t.academic_year_id, t.student_id, t.class_id, t.section_id,
        t.fee_type, t.term_number, N'PAYMENT', t.amount,
        CONCAT(N'FEE-2026-', RIGHT(CONCAT(N'000000', CAST(t.seq_num AS NVARCHAR(6))), 6)),
        t.payment_method, t.payment_gateway, t.gateway_transaction_id, t.transaction_reference,
        NULL,
        N'Regular fee collection entry',
        t.paid_at,
        @admin_user_id
    FROM @TxnStage t;

    DECLARE @payment_count INT = @@ROWCOUNT;
    PRINT N'Inserted ' + CAST(@payment_count AS NVARCHAR(10)) + N' payment transactions.';

    /*
       Insert Sample Compensating REFUND Transaction:
       - transaction_type = 'REFUND'
       - receipt_number = 'REF-YYYY-NNNNNN'
       - parent_transaction_id pointing to original payment
       - transaction_reference = Refund Bank Reference ID / UTR
    */
    DECLARE @sample_parent_id BIGINT;
    DECLARE @orig_record_id BIGINT, @orig_school_id BIGINT, @orig_branch_id BIGINT, @orig_year_id BIGINT;
    DECLARE @orig_student_id BIGINT, @orig_class_id BIGINT, @orig_section_id BIGINT;

    SELECT TOP 1 
        @sample_parent_id = fee_payment_transaction_id,
        @orig_record_id = student_fee_record_id,
        @orig_school_id = school_id,
        @orig_branch_id = branch_id,
        @orig_year_id = academic_year_id,
        @orig_student_id = student_id,
        @orig_class_id = class_id,
        @orig_section_id = section_id
    FROM finance_schema.fee_payment_transaction
    WHERE student_id = 26 AND fee_type = N'TUITION' AND term_number = 1;

    IF @sample_parent_id IS NOT NULL
    BEGIN
        INSERT INTO finance_schema.fee_payment_transaction
        (
            student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id,
            fee_type, term_number, transaction_type, amount,
            receipt_number, payment_method, transaction_reference, parent_transaction_id, remarks, paid_at, created_by
        )
        VALUES
        (
            @orig_record_id, @orig_school_id, @orig_branch_id, @orig_year_id, @orig_student_id, @orig_class_id, @orig_section_id,
            N'TUITION', 1, N'REFUND', 2000.00,
            N'REF-2026-000001', N'BANK_TRANSFER',
            N'REFUND-UTR-998877665544',
            @sample_parent_id,
            N'Partial concession adjustment refund for Student 26', '2026-05-20T14:00:00', @admin_user_id
        );
        PRINT N'Inserted compensating REFUND transaction REF-2026-000001 referencing parent transaction ' + CAST(@sample_parent_id AS NVARCHAR(10));
    END;

    COMMIT TRANSACTION;
    PRINT N'----------------------------------------------------------------------';
    PRINT N'SEEDED FINANCE MOCK DATA SUCCESSFULLY FOR STUDENTS 1 TO 30!';
    PRINT N'----------------------------------------------------------------------';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'ERROR OCCURRED DURING SEEDING: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO

/* -------------------------------------------------------------------------- */
/* 6. VERIFICATION SUMMARY AUDIT QUERY                                         */
/* -------------------------------------------------------------------------- */

SELECT 
    'finance_schema.fee_structure_term' AS table_name, 
    COUNT(*) AS total_rows 
FROM finance_schema.fee_structure_term
UNION ALL
SELECT 
    'finance_schema.student_fee_record' AS table_name, 
    COUNT(*) AS total_rows 
FROM finance_schema.student_fee_record 
WHERE student_id BETWEEN 1 AND 30
UNION ALL
SELECT 
    'finance_schema.fee_payment_transaction' AS table_name, 
    COUNT(*) AS total_rows 
FROM finance_schema.fee_payment_transaction 
WHERE student_id BETWEEN 1 AND 30;

/* Breakdown of Other Fee Status across all 30 students */
SELECT 
    other_fee_status,
    COUNT(*) AS student_count,
    SUM(other_fee_amount) AS total_other_fee_amount,
    SUM(other_fee_paid) AS total_other_fee_paid,
    SUM(other_fee_balance) AS total_other_fee_balance
FROM finance_schema.student_fee_record
WHERE student_id BETWEEN 1 AND 30
GROUP BY other_fee_status;

/* Sample Transactions showing transaction_reference (Reference IDs) */
SELECT TOP 10
    receipt_number,
    transaction_type,
    fee_type,
    term_number,
    amount,
    payment_method,
    payment_gateway,
    gateway_transaction_id,
    transaction_reference
FROM finance_schema.fee_payment_transaction
WHERE student_id BETWEEN 1 AND 30
ORDER BY fee_payment_transaction_id;
GO
