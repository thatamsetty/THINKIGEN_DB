# Thinkigen Database — Full Table Reference

Generated from SQL module migrations `001`–`017`.

Related: [mongodb-collections-reference.md](./mongodb-collections-reference.md) · [conventions.md](./conventions.md)

## How to read

| Marker | Meaning |
|--------|---------|
| PK | Primary key (unique row ID, clustered) |
| FK | Foreign key |
| UNIQUE | Duplicate values not allowed |
| CHECK | Allowed values / business rules |
| row_version | SQL Server concurrency protection |

## Date/time API formats

| SQL type | API format |
|----------|------------|
| `DATETIME2(0)` | `2026-07-17T14:00:00` (stored UTC) |
| `DATE` | `2026-07-18` |
| `TIME(0)` | `14:00:00` |

## Table index

### `finance_schema` (3 tables)

- `finance_schema.fee_payment_transaction`
- `finance_schema.fee_structure_term`
- `finance_schema.student_fee_record`

### `library_schema` (3 tables)

- `library_schema.library_book`
- `library_schema.library_book_borrow`
- `library_schema.library_book_copy`

### `management_schema` (13 tables)

- `management_schema.academic_year`
- `management_schema.announcement`
- `management_schema.branch`
- `management_schema.class_subject`
- `management_schema.exam`
- `management_schema.exam_schedule`
- `management_schema.holiday`
- `management_schema.school`
- `management_schema.school_class`
- `management_schema.section`
- `management_schema.subject`
- `management_schema.timetable`
- `management_schema.timetable_period`

### `security_schema` (3 tables)

- `security_schema.schema_version`
- `security_schema.user_login_attempt`
- `security_schema.users`

### `student_schema` (11 tables)

- `student_schema.assessment_result`
- `student_schema.exam_result`
- `student_schema.grievance`
- `student_schema.grievance_history`
- `student_schema.homework_status`
- `student_schema.student`
- `student_schema.student_attendance`
- `student_schema.student_guardian`
- `student_schema.student_leave`
- `student_schema.transport_assignment`
- `student_schema.transport_change_request`

### `teachers_schema` (4 tables)

- `teachers_schema.assessment`
- `teachers_schema.homework`
- `teachers_schema.teacher`
- `teachers_schema.teacher_subject_assignment`

### `transport_schema` (6 tables)

- `transport_schema.speed_measurement`
- `transport_schema.staff`
- `transport_schema.trip`
- `transport_schema.trip_stop`
- `transport_schema.vehicle`
- `transport_schema.vehicle_route`

**Total: 43 tables**

## `finance_schema`

### `finance_schema.fee_payment_transaction`

- **Migration:** `016_finance.sql`
- **Purpose:** Thinkigen module table

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `fee_payment_transaction_id` | `BIGINT` | NOT NULL |  |
| `student_fee_record_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `fee_type` | `NVARCHAR(20)` | NOT NULL |  |
| `term_number` | `TINYINT` | NULL |  |
| `transaction_type` | `NVARCHAR(20)` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `receipt_number` | `NVARCHAR(20)` | NOT NULL |  |
| `payment_method` | `NVARCHAR(20)` | NOT NULL |  |
| `payment_gateway` | `NVARCHAR(50)` | NULL |  |
| `gateway_transaction_id` | `NVARCHAR(100)` | NULL |  |
| `transaction_reference` | `NVARCHAR(100)` | NULL |  |
| `parent_transaction_id` | `BIGINT` | NULL |  |
| `remarks` | `NVARCHAR(500)` | NULL |  |
| `paid_at` | `DATETIME2(0)` | NOT NULL |  |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_fee_payment_transaction PRIMARY KEY CLUSTERED (fee_payment_transaction_id)`
- `CONSTRAINT CK_fee_payment_transaction_amount CHECK (amount > 0)`
- `CONSTRAINT CK_fee_payment_transaction_fee_type CHECK (fee_type IN (N'TUITION', N'HOSTEL', N'TRANSPORT', N'OTHER'))`
- `CONSTRAINT CK_fee_payment_transaction_term CHECK (`
- `CONSTRAINT CK_fee_payment_transaction_type CHECK (transaction_type IN (N'PAYMENT', N'REFUND'))`
- `CONSTRAINT CK_fee_payment_transaction_status CHECK (status IN (N'PENDING', N'SUCCESS', N'FAILED', N'CANCELLED'))`
- `CONSTRAINT CK_fee_payment_transaction_method CHECK (payment_method IN (N'CASH', N'CARD', N'UPI', N'BANK_TRANSFER', N'CHEQUE', N'ONLINE'))`
- `CONSTRAINT CK_fee_payment_transaction_receipt CHECK (`
- `CONSTRAINT CK_fee_payment_transaction_refund_parent CHECK (`
- `CONSTRAINT FK_fee_payment_transaction_parent FOREIGN KEY (parent_transaction_id)`
- `CONSTRAINT FK_fee_payment_transaction_record FOREIGN KEY (`
- `CONSTRAINT FK_fee_payment_transaction_school FOREIGN KEY (school_id)`
- `CONSTRAINT FK_fee_payment_transaction_branch_scope FOREIGN KEY (school_id, branch_id)`
- `CONSTRAINT FK_fee_payment_transaction_year_scope FOREIGN KEY (school_id, academic_year_id)`
- `CONSTRAINT FK_fee_payment_transaction_class_scope FOREIGN KEY (school_id, class_id)`
- `CONSTRAINT FK_fee_payment_transaction_section_scope FOREIGN KEY (class_id, section_id)`
- `CONSTRAINT FK_fee_payment_transaction_student FOREIGN KEY (student_id)`
- `CONSTRAINT FK_fee_payment_transaction_created_by FOREIGN KEY (created_by)`
- `CONSTRAINT FK_fee_payment_transaction_updated_by FOREIGN KEY (updated_by)`

**Indexes**

- `UX_fee_payment_transaction_receipt`
- `IX_fee_payment_transaction_student_created`
- `IX_fee_payment_transaction_record_created`
- `IX_fee_payment_transaction_type`
- `IX_fee_payment_transaction_gateway`
- `IX_fee_payment_transaction_parent`

### `finance_schema.fee_structure_term`

- **Migration:** `016_finance.sql`
- **Purpose:** Thinkigen module table

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `fee_structure_term_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `total_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_due_date` | `DATE` | NOT NULL |  |
| `term2_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_due_date` | `DATE` | NOT NULL |  |
| `term3_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_due_date` | `DATE` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_fee_structure_term PRIMARY KEY CLUSTERED (fee_structure_term_id)`
- `CONSTRAINT UQ_fee_structure_term_scope UNIQUE NONCLUSTERED (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id)`
- `CONSTRAINT CK_fee_structure_term_amounts CHECK (`
- `CONSTRAINT CK_fee_structure_term_status CHECK (status IN (N'DRAFT', N'ACTIVE', N'INACTIVE'))`
- `CONSTRAINT CK_fee_structure_term_due_dates CHECK (term2_due_date >= term1_due_date AND term3_due_date >= term2_due_date)`
- `CONSTRAINT FK_fee_structure_term_school FOREIGN KEY (school_id)`
- `CONSTRAINT FK_fee_structure_term_branch_scope FOREIGN KEY (school_id, branch_id)`
- `CONSTRAINT FK_fee_structure_term_year_scope FOREIGN KEY (school_id, academic_year_id)`
- `CONSTRAINT FK_fee_structure_term_class_scope FOREIGN KEY (school_id, class_id)`
- `CONSTRAINT FK_fee_structure_term_created_by FOREIGN KEY (created_by)`
- `CONSTRAINT FK_fee_structure_term_updated_by FOREIGN KEY (updated_by)`

**Indexes**

- `UX_fee_structure_term_active_scope`
- `IX_fee_structure_term_active_lookup`

### `finance_schema.student_fee_record`

- **Migration:** `016_finance.sql`
- **Purpose:** Thinkigen module table

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `student_fee_record_id` | `BIGINT` | NOT NULL |  |
| `fee_structure_term_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `residency_type` | `NVARCHAR(20)` | NOT NULL |  |
| `term1_tuition_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_tuition_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_tuition_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_tuition_status` | `NVARCHAR(20)` | NOT NULL |  |
| `term1_residency_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_residency_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_residency_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_residency_status` | `NVARCHAR(20)` | NOT NULL |  |
| `term1_total_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_total_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_total_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term1_status` | `NVARCHAR(20)` | NOT NULL |  |
| `term2_tuition_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_tuition_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_tuition_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_tuition_status` | `NVARCHAR(20)` | NOT NULL |  |
| `term2_residency_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_residency_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_residency_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_residency_status` | `NVARCHAR(20)` | NOT NULL |  |
| `term2_total_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_total_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_total_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term2_status` | `NVARCHAR(20)` | NOT NULL |  |
| `term3_tuition_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_tuition_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_tuition_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_tuition_status` | `NVARCHAR(20)` | NOT NULL |  |
| `term3_residency_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_residency_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_residency_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_residency_status` | `NVARCHAR(20)` | NOT NULL |  |
| `term3_total_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_total_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_total_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `term3_status` | `NVARCHAR(20)` | NOT NULL |  |
| `other_fee_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `other_fee_paid` | `DECIMAL(12,2)` | NOT NULL |  |
| `other_fee_balance` | `DECIMAL(12,2)` | NOT NULL |  |
| `other_fee_status` | `NVARCHAR(20)` | NOT NULL |  |
| `scholarship_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `total_fee_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `total_paid_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `total_balance_amount` | `DECIMAL(12,2)` | NOT NULL |  |
| `overall_status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_student_fee_record PRIMARY KEY CLUSTERED (student_fee_record_id)`
- `CONSTRAINT UQ_student_fee_record_scope UNIQUE NONCLUSTERED (school_id, branch_id, academic_year_id, student_id)`
- `CONSTRAINT UQ_student_fee_record_hierarchy UNIQUE NONCLUSTERED (student_fee_record_id, school_id, branch_id, academic_year_id, student_id, class_id, section_id)`
- `CONSTRAINT CK_student_fee_record_residency_type CHECK (residency_type IN (N'DAY_SCHOLAR', N'HOSTELLER'))`
- `CONSTRAINT CK_student_fee_record_residency CHECK (`
- `CONSTRAINT CK_student_fee_record_tuition CHECK (`
- `CONSTRAINT CK_student_fee_record_other_fee CHECK (`
- `CONSTRAINT CK_student_fee_record_term_totals CHECK (`
- `CONSTRAINT CK_student_fee_record_overall_totals CHECK (`
- `CONSTRAINT FK_student_fee_record_structure FOREIGN KEY (fee_structure_term_id, school_id, branch_id, academic_year_id, class_id)`
- `CONSTRAINT FK_student_fee_record_school FOREIGN KEY (school_id)`
- `CONSTRAINT FK_student_fee_record_branch_scope FOREIGN KEY (school_id, branch_id)`
- `CONSTRAINT FK_student_fee_record_year_scope FOREIGN KEY (school_id, academic_year_id)`
- `CONSTRAINT FK_student_fee_record_class_scope FOREIGN KEY (school_id, class_id)`
- `CONSTRAINT FK_student_fee_record_section_scope FOREIGN KEY (class_id, section_id)`
- `CONSTRAINT FK_student_fee_record_student FOREIGN KEY (student_id)`
- `CONSTRAINT FK_student_fee_record_created_by FOREIGN KEY (created_by)`
- `CONSTRAINT FK_student_fee_record_updated_by FOREIGN KEY (updated_by)`

**Indexes**

- `IX_student_fee_record_student_year`
- `IX_student_fee_record_scope`
- `IX_student_fee_record_outstanding`

## `library_schema`

### `library_schema.library_book`

- **Migration:** `014_library.sql`
- **Purpose:** Drops legacy library tables and recreates the final, clean 3-table

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `book_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `title` | `NVARCHAR(300)` | NOT NULL |  |
| `author` | `NVARCHAR(200)` | NOT NULL |  |
| `subject` | `NVARCHAR(100)` | NOT NULL |  |
| `category` | `NVARCHAR(100)` | NOT NULL |  |
| `language` | `NVARCHAR(50)` | NOT NULL |  |
| `edition` | `NVARCHAR(50)` | NULL |  |
| `description` | `NVARCHAR(MAX)` | NULL |  |
| `total_copies` | `INT` | NOT NULL |  |
| `available_copies` | `INT` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_library_book PRIMARY KEY CLUSTERED (book_id)`
- `CONSTRAINT UQ_library_book_scope UNIQUE NONCLUSTERED (school_id, branch_id, book_id)`
- `CONSTRAINT CK_library_book_title CHECK (LEN(LTRIM(RTRIM(title))) > 0)`
- `CONSTRAINT CK_library_book_author CHECK (LEN(LTRIM(RTRIM(author))) > 0)`
- `CONSTRAINT CK_library_book_subject CHECK (LEN(LTRIM(RTRIM(subject))) > 0)`
- `CONSTRAINT CK_library_book_category CHECK (LEN(LTRIM(RTRIM(category))) > 0)`
- `CONSTRAINT CK_library_book_language CHECK (LEN(LTRIM(RTRIM(language))) > 0)`
- `CONSTRAINT CK_library_book_total_copies CHECK (total_copies >= 0)`
- `CONSTRAINT CK_library_book_available_copies CHECK (available_copies >= 0)`
- `CONSTRAINT CK_library_book_available_lte_total CHECK (available_copies <= total_copies)`
- `CONSTRAINT FK_library_book_school FOREIGN KEY (school_id)`
- `CONSTRAINT FK_library_book_branch FOREIGN KEY (school_id, branch_id)`
- `CONSTRAINT FK_library_book_created_by FOREIGN KEY (created_by)`
- `CONSTRAINT FK_library_book_updated_by FOREIGN KEY (updated_by)`

**Indexes**

- `IX_library_book_branch_search`

### `library_schema.library_book_borrow`

- **Migration:** `014_library.sql`
- **Purpose:** Drops legacy library tables and recreates the final, clean 3-table

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `borrow_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `book_id` | `BIGINT` | NOT NULL |  |
| `book_copy_id` | `BIGINT` | NOT NULL |  |
| `borrow_status` | `NVARCHAR(20)` | NOT NULL |  |
| `borrowed_at` | `DATETIME2(0)` | NOT NULL |  |
| `due_date` | `DATE` | NOT NULL |  |
| `returned_at` | `DATETIME2(0)` | NULL |  |
| `returned_to` | `BIGINT` | NULL |  |
| `issued_by` | `BIGINT` | NOT NULL |  |
| `remarks` | `NVARCHAR(500)` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_library_book_borrow PRIMARY KEY CLUSTERED (borrow_id)`
- `CONSTRAINT CK_library_book_borrow_status CHECK`
- `CONSTRAINT CK_library_book_borrow_due_date CHECK`
- `CONSTRAINT CK_library_book_borrow_returned_status CHECK`
- `CONSTRAINT FK_library_book_borrow_school FOREIGN KEY (school_id)`
- `CONSTRAINT FK_library_book_borrow_branch FOREIGN KEY (school_id, branch_id)`
- `CONSTRAINT FK_library_book_borrow_academic_year FOREIGN KEY (school_id, academic_year_id)`
- `CONSTRAINT FK_library_book_borrow_student_scope FOREIGN KEY (school_id, branch_id, student_id)`
- `CONSTRAINT FK_library_book_borrow_class_scope FOREIGN KEY (school_id, class_id)`
- `CONSTRAINT FK_library_book_borrow_section_scope FOREIGN KEY (class_id, section_id)`
- `CONSTRAINT FK_library_book_borrow_copy_scope FOREIGN KEY (school_id, branch_id, book_id, book_copy_id)`
- `CONSTRAINT FK_library_book_borrow_issued_by FOREIGN KEY (issued_by)`
- `CONSTRAINT FK_library_book_borrow_returned_to FOREIGN KEY (returned_to)`
- `CONSTRAINT FK_library_book_borrow_updated_by FOREIGN KEY (updated_by)`

**Indexes**

- `UX_library_book_borrow_active_copy`
- `IX_library_book_borrow_student_history`
- `IX_library_book_borrow_student_year`
- `IX_library_book_borrow_active_loans`
- `IX_library_book_borrow_overdue_loans`
- `IX_library_book_borrow_branch_circulation`
- `IX_library_book_borrow_copy_history`
- `IX_library_book_borrow_issued_by`
- `IX_library_book_borrow_lost`

### `library_schema.library_book_copy`

- **Migration:** `014_library.sql`
- **Purpose:** Drops legacy library tables and recreates the final, clean 3-table

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `book_copy_id` | `BIGINT` | NOT NULL |  |
| `book_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `copy_number` | `INT` | NOT NULL |  |
| `barcode` | `NVARCHAR(50)` | NULL |  |
| `copy_status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_library_book_copy PRIMARY KEY CLUSTERED (book_copy_id)`
- `CONSTRAINT UQ_library_book_copy_number UNIQUE NONCLUSTERED (school_id, branch_id, book_id, copy_number)`
- `CONSTRAINT UQ_library_book_copy_scope UNIQUE NONCLUSTERED (school_id, branch_id, book_id, book_copy_id)`
- `CONSTRAINT CK_library_book_copy_number CHECK (copy_number > 0)`
- `CONSTRAINT CK_library_book_copy_status CHECK`
- `CONSTRAINT CK_library_book_copy_active_status CHECK`
- `CONSTRAINT FK_library_book_copy_book_scope FOREIGN KEY (school_id, branch_id, book_id)`
- `CONSTRAINT FK_library_book_copy_school FOREIGN KEY (school_id)`
- `CONSTRAINT FK_library_book_copy_branch FOREIGN KEY (school_id, branch_id)`
- `CONSTRAINT FK_library_book_copy_created_by FOREIGN KEY (created_by)`
- `CONSTRAINT FK_library_book_copy_updated_by FOREIGN KEY (updated_by)`

**Indexes**

- `UQ_library_book_copy_branch_barcode`
- `IX_library_book_copy_book_status`
- `IX_library_book_copy_branch_status`
- `IX_library_book_copy_available`

## `management_schema`

### `management_schema.academic_year`

- **Migration:** `003_management.sql`
- **Purpose:** Institutional master data required by student_schema.student foreign keys

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `year_name` | `NVARCHAR(50)` | NOT NULL |  |
| `start_date` | `DATE` | NOT NULL |  |
| `end_date` | `DATE` | NOT NULL |  |
| `is_current` | `BIT` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_academic_year PRIMARY KEY CLUSTERED (academic_year_id)`
- `CONSTRAINT UQ_academic_year_school_name UNIQUE NONCLUSTERED (school_id, year_name)`
- `CONSTRAINT CK_academic_year_dates CHECK (end_date >= start_date)`
- `CONSTRAINT FK_academic_year_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_academic_year_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_academic_year_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `UQ_academic_year_school_scope`

### `management_schema.announcement`

- **Migration:** `007_announcement.sql`
- **Purpose:** School/branch announcements for Student Overview (events, academic notices, general instructions)

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `announcement_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `announcement_type` | `NVARCHAR(20)` | NOT NULL |  |
| `sub_category` | `NVARCHAR(50)` | NOT NULL |  |
| `title` | `NVARCHAR(200)` | NOT NULL |  |
| `description` | `NVARCHAR(MAX)` | NULL |  |
| `target_audience` | `NVARCHAR(100)` | NOT NULL |  |
| `registration_url` | `NVARCHAR(2048)` | NULL |  |
| `start_date` | `DATE` | NULL |  |
| `end_date` | `DATE` | NULL |  |
| `publish_at` | `DATETIME2(0)` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |

**Constraints**

- `CONSTRAINT PK_announcement PRIMARY KEY CLUSTERED (announcement_id)`
- `CONSTRAINT CK_announcement_type CHECK`
- `CONSTRAINT CK_announcement_sub_category CHECK`
- `CONSTRAINT CK_announcement_registration_url CHECK`
- `CONSTRAINT CK_announcement_status CHECK`
- `CONSTRAINT CK_announcement_date_range CHECK`
- `CONSTRAINT FK_announcement_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_announcement_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_announcement_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_announcement_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_announcement_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_announcement_branch_status_publish`
- `IX_announcement_branch_date`
- `IX_announcement_type_date`
- `IX_announcement_academic_year`
- `IX_announcement_type_sub_category`

### `management_schema.branch`

- **Migration:** `003_management.sql`
- **Purpose:** Institutional master data required by student_schema.student foreign keys

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_code` | `NVARCHAR(50)` | NOT NULL |  |
| `branch_name` | `NVARCHAR(150)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_branch PRIMARY KEY CLUSTERED (branch_id)`
- `CONSTRAINT UQ_branch_school_code UNIQUE NONCLUSTERED (school_id, branch_code)`
- `CONSTRAINT FK_branch_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_branch_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_branch_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `UQ_branch_school_scope`

### `management_schema.class_subject`

- **Migration:** `003_management.sql`
- **Purpose:** Institutional master data required by student_schema.student foreign keys

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `class_subject_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `subject_id` | `BIGINT` | NOT NULL | Subject FK |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_class_subject PRIMARY KEY CLUSTERED (class_subject_id)`
- `CONSTRAINT UQ_class_subject_scope UNIQUE NONCLUSTERED`
- `CONSTRAINT FK_class_subject_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_class_subject_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_class_subject_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_class_subject_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_class_subject_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id)`
- `CONSTRAINT FK_class_subject_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_class_subject_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_class_subject_class_active`
- `IX_class_subject_subject_active`

### `management_schema.exam`

- **Migration:** `017_exam.sql`
- **Purpose:** Exam master, subject schedule, and per-student results

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `exam_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `exam_name` | `NVARCHAR(150)` | NOT NULL |  |
| `exam_category` | `NVARCHAR(50)` | NOT NULL |  |
| `start_date` | `DATE` | NOT NULL |  |
| `end_date` | `DATE` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_exam PRIMARY KEY CLUSTERED (exam_id)`
- `CONSTRAINT UQ_exam_section_name UNIQUE NONCLUSTERED`
- `CONSTRAINT CK_exam_date_range CHECK (end_date >= start_date)`
- `CONSTRAINT CK_exam_status CHECK`
- `CONSTRAINT FK_exam_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_exam_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_exam_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_exam_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_exam_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_exam_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_exam_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_exam_academic_scope_status`
- `IX_exam_category_scope`

### `management_schema.exam_schedule`

- **Migration:** `017_exam.sql`
- **Purpose:** Exam master, subject schedule, and per-student results

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `exam_schedule_id` | `BIGINT` | NOT NULL |  |
| `exam_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `subject_id` | `BIGINT` | NOT NULL | Subject FK |
| `teacher_id` | `BIGINT` | NOT NULL | Teacher FK |
| `exam_date` | `DATE` | NOT NULL |  |
| `start_time` | `TIME(0)` | NOT NULL |  |
| `end_time` | `TIME(0)` | NOT NULL |  |
| `max_marks` | `DECIMAL(6, 2)` | NOT NULL |  |
| `pass_marks` | `DECIMAL(6, 2)` | NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_exam_schedule PRIMARY KEY CLUSTERED (exam_schedule_id)`
- `CONSTRAINT UQ_exam_schedule_exam_subject UNIQUE NONCLUSTERED (exam_id, subject_id)`
- `CONSTRAINT CK_exam_schedule_time CHECK (end_time > start_time)`
- `CONSTRAINT CK_exam_schedule_max_marks CHECK (max_marks > 0)`
- `CONSTRAINT CK_exam_schedule_pass_marks CHECK`
- `CONSTRAINT CK_exam_schedule_status CHECK`
- `CONSTRAINT FK_exam_schedule_exam FOREIGN KEY (exam_id) REFERENCES management_schema.exam (exam_id)`
- `CONSTRAINT FK_exam_schedule_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_exam_schedule_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_exam_schedule_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_exam_schedule_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_exam_schedule_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_exam_schedule_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id)`
- `CONSTRAINT FK_exam_schedule_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id)`
- `CONSTRAINT FK_exam_schedule_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_exam_schedule_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_exam_schedule_academic_scope`
- `IX_exam_schedule_teacher_date`
- `IX_exam_schedule_exam_date`

### `management_schema.holiday`

- **Migration:** `012_holidays.sql`
- **Purpose:** School/branch holiday calendar master (academic calendar)

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `holiday_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `holiday_type` | `NVARCHAR(30)` | NOT NULL |  |
| `holiday_name` | `NVARCHAR(150)` | NOT NULL |  |
| `description` | `NVARCHAR(MAX)` | NULL |  |
| `start_date` | `DATE` | NOT NULL |  |
| `end_date` | `DATE` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_holiday PRIMARY KEY CLUSTERED (holiday_id)`
- `CONSTRAINT CK_holiday_type CHECK`
- `CONSTRAINT CK_holiday_date_range CHECK (end_date >= start_date)`
- `CONSTRAINT FK_holiday_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_holiday_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_holiday_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_holiday_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_holiday_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_holiday_branch_year_dates`
- `IX_holiday_branch_type_date`

### `management_schema.school`

- **Migration:** `003_management.sql`
- **Purpose:** Institutional master data required by student_schema.student foreign keys

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `school_code` | `NVARCHAR(50)` | NOT NULL |  |
| `school_name` | `NVARCHAR(150)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_school PRIMARY KEY CLUSTERED (school_id)`
- `CONSTRAINT UQ_school_code UNIQUE NONCLUSTERED (school_code)`
- `CONSTRAINT FK_school_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_school_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

### `management_schema.school_class`

- **Migration:** `003_management.sql`
- **Purpose:** Institutional master data required by student_schema.student foreign keys

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `class_name` | `NVARCHAR(150)` | NOT NULL |  |
| `display_order` | `INT` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_school_class PRIMARY KEY CLUSTERED (class_id)`
- `CONSTRAINT UQ_school_class_school_name UNIQUE NONCLUSTERED (school_id, class_name)`
- `CONSTRAINT FK_school_class_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_school_class_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_school_class_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `UQ_school_class_school_scope`

### `management_schema.section`

- **Migration:** `003_management.sql`
- **Purpose:** Institutional master data required by student_schema.student foreign keys

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_name` | `NVARCHAR(50)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_section PRIMARY KEY CLUSTERED (section_id)`
- `CONSTRAINT UQ_section_class_name UNIQUE NONCLUSTERED (class_id, section_name)`
- `CONSTRAINT FK_section_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_section_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_section_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `UQ_section_class_scope`

### `management_schema.subject`

- **Migration:** `003_management.sql`
- **Purpose:** Institutional master data required by student_schema.student foreign keys

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `subject_id` | `BIGINT` | NOT NULL | Subject FK |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `subject_code` | `NVARCHAR(50)` | NOT NULL |  |
| `subject_name` | `NVARCHAR(150)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_subject PRIMARY KEY CLUSTERED (subject_id)`
- `CONSTRAINT UQ_subject_school_code UNIQUE NONCLUSTERED (school_id, subject_code)`
- `CONSTRAINT FK_subject_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_subject_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_subject_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

### `management_schema.timetable`

- **Migration:** `008_timetable.sql`
- **Purpose:** Section-wise academic timetable (master + dated period slots)

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `timetable_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `timetable_name` | `NVARCHAR(150)` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_timetable PRIMARY KEY CLUSTERED (timetable_id)`
- `CONSTRAINT CK_timetable_status CHECK`
- `CONSTRAINT FK_timetable_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_timetable_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_timetable_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_timetable_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_timetable_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_timetable_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_timetable_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `UX_timetable_section_active`
- `IX_timetable_section_status`

### `management_schema.timetable_period`

- **Migration:** `008_timetable.sql`
- **Purpose:** Section-wise academic timetable (master + dated period slots)

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `timetable_period_id` | `BIGINT` | NOT NULL |  |
| `timetable_id` | `BIGINT` | NOT NULL |  |
| `period_date` | `DATE` | NOT NULL |  |
| `period_number` | `TINYINT` | NOT NULL |  |
| `period_name` | `NVARCHAR(50)` | NULL |  |
| `start_time` | `TIME(0)` | NOT NULL |  |
| `end_time` | `TIME(0)` | NOT NULL |  |
| `period_type` | `NVARCHAR(30)` | NOT NULL |  |
| `subject_id` | `BIGINT` | NULL | Subject FK |
| `subject_topic` | `NVARCHAR(200)` | NULL | Lesson/chapter topic for CLASS period |
| `teacher_id` | `BIGINT` | NULL | Teacher FK |
| `room_name` | `NVARCHAR(150)` | NULL |  |
| `activity_name` | `NVARCHAR(150)` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_timetable_period PRIMARY KEY CLUSTERED (timetable_period_id)`
- `CONSTRAINT UQ_timetable_period_slot UNIQUE NONCLUSTERED`
- `CONSTRAINT CK_timetable_period_number CHECK (period_number > 0)`
- `CONSTRAINT CK_timetable_period_time CHECK (end_time > start_time)`
- `CONSTRAINT CK_timetable_period_type CHECK`
- `CONSTRAINT CK_timetable_period_class CHECK`
- `CONSTRAINT FK_timetable_period_timetable FOREIGN KEY (timetable_id) REFERENCES management_schema.timetable (timetable_id)`
- `CONSTRAINT FK_timetable_period_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id)`
- `CONSTRAINT FK_timetable_period_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id)`
- `CONSTRAINT FK_timetable_period_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_timetable_period_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_timetable_period_my_day`
- `IX_timetable_period_teacher_day`

## `security_schema`

### `security_schema.schema_version`

- **Migration:** `002_security.sql`
- **Purpose:** Identity + credentials (one users table), login audit, migration tracking

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `schema_version_id` | `INT` | NOT NULL |  |
| `migration_name` | `NVARCHAR(200)` | NOT NULL |  |
| `applied_at` | `DATETIME2(0)` | NOT NULL |  |

**Constraints**

- `CONSTRAINT PK_schema_version PRIMARY KEY CLUSTERED (schema_version_id)`
- `CONSTRAINT UQ_schema_version_name UNIQUE NONCLUSTERED (migration_name)`

### `security_schema.user_login_attempt`

- **Migration:** `002_security.sql`
- **Purpose:** Identity + credentials (one users table), login audit, migration tracking

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `login_attempt_id` | `BIGINT` | NOT NULL |  |
| `user_id` | `BIGINT` | NOT NULL | User FK |
| `is_success` | `BIT` | NOT NULL |  |
| `failure_reason` | `NVARCHAR(50)` | NULL |  |
| `ip_address` | `NVARCHAR(45)` | NULL |  |
| `user_agent` | `NVARCHAR(500)` | NULL |  |
| `attempted_at` | `DATETIME2(0)` | NOT NULL |  |

**Constraints**

- `CONSTRAINT PK_user_login_attempt PRIMARY KEY CLUSTERED (login_attempt_id)`
- `CONSTRAINT CK_user_login_attempt_result CHECK`
- `CONSTRAINT CK_user_login_attempt_failure_reason CHECK`
- `CONSTRAINT FK_user_login_attempt_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_user_login_attempt_user_time`
- `IX_user_login_attempt_ip_time`

### `security_schema.users`

- **Migration:** `002_security.sql`
- **Purpose:** Identity + credentials (one users table), login audit, migration tracking

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `user_id` | `BIGINT` | NOT NULL | User FK |
| `email_address` | `NVARCHAR(254)` | NOT NULL |  |
| `user_type` | `NVARCHAR(30)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `password_hash` | `NVARCHAR(255)` | NULL |  |
| `password_plain_dev` | `NVARCHAR(255)` | NULL |  |
| `password_set_at` | `DATETIME2(0)` | NULL |  |
| `failed_login_count` | `INT` | NOT NULL |  |
| `locked_until` | `DATETIME2(0)` | NULL |  |
| `last_login_at` | `DATETIME2(0)` | NULL |  |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_users PRIMARY KEY CLUSTERED (user_id)`
- `CONSTRAINT UQ_users_email_address UNIQUE NONCLUSTERED (email_address)`
- `CONSTRAINT CK_users_failed_login CHECK (failed_login_count >= 0)`

**Indexes**

- `IX_users_user_type_active`

## `student_schema`

### `student_schema.assessment_result`

- **Migration:** `006_assessment.sql`
- **Purpose:** Assessment master (project works, slip tests, quizzes - subject-wise) and per-student assessment marks

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `assessment_result_id` | `BIGINT` | NOT NULL |  |
| `assessment_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `marks_obtained` | `DECIMAL(6, 2)` | NULL |  |
| `grade` | `NVARCHAR(10)` | NULL |  |
| `remarks` | `NVARCHAR(500)` | NULL |  |
| `graded_at` | `DATETIME2(0)` | NULL |  |
| `graded_by` | `BIGINT` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_assessment_result PRIMARY KEY CLUSTERED (assessment_result_id)`
- `CONSTRAINT UQ_assessment_result_assessment_student UNIQUE NONCLUSTERED (assessment_id, student_id)`
- `CONSTRAINT CK_assessment_result_marks CHECK`
- `CONSTRAINT CK_assessment_result_graded CHECK`
- `CONSTRAINT FK_assessment_result_assessment FOREIGN KEY (assessment_id) REFERENCES teachers_schema.assessment (assessment_id)`
- `CONSTRAINT FK_assessment_result_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_assessment_result_branch_scope FOREIGN KEY (school_id, branch_id)`
- `CONSTRAINT FK_assessment_result_academic_year_scope FOREIGN KEY (school_id, academic_year_id)`
- `CONSTRAINT FK_assessment_result_class_scope FOREIGN KEY (school_id, class_id)`
- `CONSTRAINT FK_assessment_result_section_scope FOREIGN KEY (class_id, section_id)`
- `CONSTRAINT FK_assessment_result_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_assessment_result_graded_by FOREIGN KEY (graded_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_assessment_result_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_assessment_result_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_assessment_result_student_scope`
- `IX_assessment_result_student_assessment`
- `IX_assessment_result_assessment`

### `student_schema.exam_result`

- **Migration:** `005_student.sql`
- **Purpose:** Student master identity, current academic placement, and guardians

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `exam_result_id` | `BIGINT` | NOT NULL |  |
| `exam_schedule_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `marks_obtained` | `DECIMAL(6, 2)` | NULL |  |
| `result_status` | `NVARCHAR(20)` | NOT NULL |  |
| `grade` | `NVARCHAR(10)` | NULL |  |
| `rank_in_class` | `INT` | NULL |  |
| `remarks` | `NVARCHAR(500)` | NULL |  |
| `published_at` | `DATETIME2(0)` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_exam_result PRIMARY KEY CLUSTERED (exam_result_id)`
- `CONSTRAINT UQ_exam_result_schedule_student UNIQUE NONCLUSTERED (exam_schedule_id, student_id)`
- `CONSTRAINT CK_exam_result_status CHECK`
- `CONSTRAINT CK_exam_result_marks CHECK`
- `CONSTRAINT CK_exam_result_absent_marks CHECK`
- `CONSTRAINT CK_exam_result_rank CHECK`
- `CONSTRAINT FK_exam_result_exam_schedule FOREIGN KEY (exam_schedule_id) REFERENCES management_schema.exam_schedule (exam_schedule_id)`
- `CONSTRAINT FK_exam_result_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_exam_result_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id)`
- `CONSTRAINT FK_exam_result_academic_year_scope FOREIGN KEY (school_id, academic_year_id) REFERENCES management_schema.academic_year (school_id, academic_year_id)`
- `CONSTRAINT FK_exam_result_class_scope FOREIGN KEY (school_id, class_id) REFERENCES management_schema.school_class (school_id, class_id)`
- `CONSTRAINT FK_exam_result_section_scope FOREIGN KEY (class_id, section_id) REFERENCES management_schema.section (class_id, section_id)`
- `CONSTRAINT FK_exam_result_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_exam_result_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_exam_result_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_exam_result_student_scope`
- `IX_exam_result_schedule_status`
- `IX_exam_result_student_published`

### `student_schema.grievance`

- **Migration:** `013_grievance.sql`
- **Purpose:** Student grievance (complaint) and lifecycle tracking

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `grievance_id` | `BIGINT` | NOT NULL |  |
| `grievance_number` | `NVARCHAR(30)` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `department_id` | `BIGINT` | NOT NULL |  |
| `title` | `NVARCHAR(200)` | NOT NULL |  |
| `category` | `NVARCHAR(50)` | NOT NULL |  |
| `priority_level` | `NVARCHAR(20)` | NOT NULL |  |
| `incident_date` | `DATE` | NOT NULL |  |
| `location` | `NVARCHAR(200)` | NOT NULL |  |
| `description` | `NVARCHAR(MAX)` | NOT NULL |  |
| `status` | `NVARCHAR(30)` | NOT NULL |  |
| `submitted_at` | `DATETIME2(0)` | NOT NULL |  |
| `assigned_to` | `BIGINT` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_grievance PRIMARY KEY CLUSTERED (grievance_id)`
- `CONSTRAINT UQ_grievance_number UNIQUE NONCLUSTERED (grievance_number)`
- `CONSTRAINT CK_grievance_category CHECK`
- `CONSTRAINT CK_grievance_priority CHECK`
- `CONSTRAINT CK_grievance_status CHECK`
- `CONSTRAINT CK_grievance_assigned_to_required CHECK`
- `CONSTRAINT FK_grievance_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_grievance_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_grievance_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_grievance_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_grievance_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_grievance_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_grievance_assigned_to FOREIGN KEY (assigned_to) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_grievance_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_grievance_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_grievance_student_status`
- `IX_grievance_department_status`
- `IX_grievance_assigned_to_status`
- `IX_grievance_submitted`

### `student_schema.grievance_history`

- **Migration:** `013_grievance.sql`
- **Purpose:** Student grievance (complaint) and lifecycle tracking

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `grievance_history_id` | `BIGINT` | NOT NULL |  |
| `grievance_id` | `BIGINT` | NOT NULL |  |
| `submitted_by` | `BIGINT` | NOT NULL |  |
| `submitted_at` | `DATETIME2(0)` | NOT NULL |  |
| `assigned_to` | `BIGINT` | NULL |  |
| `reviewed_at` | `DATETIME2(0)` | NULL |  |
| `resolved_at` | `DATETIME2(0)` | NULL |  |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_grievance_history PRIMARY KEY CLUSTERED (grievance_history_id)`
- `CONSTRAINT UQ_grievance_history_grievance_id UNIQUE NONCLUSTERED (grievance_id)`
- `CONSTRAINT CK_grievance_history_resolved_requires_reviewed CHECK`
- `CONSTRAINT CK_grievance_history_reviewed_requires_assigned CHECK`
- `CONSTRAINT FK_grievance_history_grievance FOREIGN KEY (grievance_id) REFERENCES student_schema.grievance (grievance_id)`
- `CONSTRAINT FK_grievance_history_submitted_by FOREIGN KEY (submitted_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_grievance_history_assigned_to FOREIGN KEY (assigned_to) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_grievance_history_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_grievance_history_assigned_to`
- `IX_grievance_history_submitted_by`

### `student_schema.homework_status`

- **Migration:** `009_homework.sql`
- **Purpose:** Section-scoped homework / learning tasks (no marks) with deadlines

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `homework_status_id` | `BIGINT` | NOT NULL |  |
| `homework_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `submission_status` | `NVARCHAR(20)` | NOT NULL |  |
| `submitted_at` | `DATETIME2(0)` | NULL |  |
| `submission_timing` | `NVARCHAR(20)` | NULL |  |
| `remarks` | `NVARCHAR(500)` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_homework_status PRIMARY KEY CLUSTERED (homework_status_id)`
- `CONSTRAINT UQ_homework_status_homework_student UNIQUE NONCLUSTERED (homework_id, student_id)`
- `CONSTRAINT CK_homework_status_submission_status CHECK`
- `CONSTRAINT CK_homework_status_submitted_at CHECK`
- `CONSTRAINT CK_homework_status_submission_timing CHECK`
- `CONSTRAINT FK_homework_status_homework FOREIGN KEY (homework_id) REFERENCES teachers_schema.homework (homework_id)`
- `CONSTRAINT FK_homework_status_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_homework_status_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_homework_status_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_homework_status_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_homework_status_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_homework_status_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_homework_status_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_homework_status_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_homework_status_student_scope`
- `IX_homework_status_student_submission`
- `IX_homework_status_student_homework`
- `IX_homework_status_homework_submission`

### `student_schema.student`

- **Migration:** `005_student.sql`
- **Purpose:** Student master identity, current academic placement, and guardians

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `user_id` | `BIGINT` | NULL | User FK |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `admission_number` | `NVARCHAR(50)` | NOT NULL |  |
| `roll_number` | `NVARCHAR(30)` | NULL |  |
| `first_name` | `NVARCHAR(100)` | NOT NULL |  |
| `middle_name` | `NVARCHAR(100)` | NULL |  |
| `last_name` | `NVARCHAR(100)` | NULL |  |
| `date_of_birth` | `DATE` | NOT NULL |  |
| `gender` | `NVARCHAR(30)` | NOT NULL |  |
| `blood_group` | `NVARCHAR(10)` | NULL |  |
| `nationality` | `NVARCHAR(100)` | NULL |  |
| `mother_tongue` | `NVARCHAR(100)` | NULL |  |
| `religion` | `NVARCHAR(100)` | NULL |  |
| `student_category` | `NVARCHAR(100)` | NULL |  |
| `admission_date` | `DATE` | NOT NULL |  |
| `student_status` | `NVARCHAR(30)` | NOT NULL |  |
| `status_effective_date` | `DATE` | NULL |  |
| `mobile_number` | `NVARCHAR(20)` | NULL |  |
| `email_address` | `NVARCHAR(254)` | NULL |  |
| `address_line_1` | `NVARCHAR(200)` | NULL |  |
| `address_line_2` | `NVARCHAR(200)` | NULL |  |
| `landmark` | `NVARCHAR(150)` | NULL |  |
| `city` | `NVARCHAR(100)` | NULL |  |
| `district` | `NVARCHAR(100)` | NULL |  |
| `state` | `NVARCHAR(100)` | NULL |  |
| `postal_code` | `NVARCHAR(20)` | NULL |  |
| `country` | `NVARCHAR(100)` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_student PRIMARY KEY CLUSTERED (student_id)`
- `CONSTRAINT UQ_student_school_admission_number UNIQUE NONCLUSTERED (school_id, admission_number)`
- `CONSTRAINT UQ_student_user_id UNIQUE NONCLUSTERED (user_id)`
- `CONSTRAINT FK_student_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_student_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_student_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id)`
- `CONSTRAINT FK_student_academic_year_scope FOREIGN KEY (school_id, academic_year_id) REFERENCES management_schema.academic_year (school_id, academic_year_id)`
- `CONSTRAINT FK_student_class_scope FOREIGN KEY (school_id, class_id) REFERENCES management_schema.school_class (school_id, class_id)`
- `CONSTRAINT FK_student_section_scope FOREIGN KEY (class_id, section_id) REFERENCES management_schema.section (class_id, section_id)`
- `CONSTRAINT FK_student_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_student_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_student_academic_scope`
- `IX_student_branch_status`
- `IX_student_name`
- `IX_student_roll_number`

### `student_schema.student_attendance`

- **Migration:** `010_attendance.sql`
- **Purpose:** Period-wise student attendance linked to timetable

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `student_attendance_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `timetable_id` | `BIGINT` | NOT NULL |  |
| `timetable_period_id` | `BIGINT` | NOT NULL |  |
| `attendance_date` | `DATE` | NOT NULL |  |
| `subject_id` | `BIGINT` | NOT NULL | Subject FK |
| `teacher_id` | `BIGINT` | NOT NULL | Teacher FK |
| `period_number` | `TINYINT` | NOT NULL |  |
| `start_time` | `TIME(0)` | NOT NULL |  |
| `end_time` | `TIME(0)` | NOT NULL |  |
| `attendance_status` | `NVARCHAR(10)` | NOT NULL |  |
| `recorded_at` | `DATETIME2(0)` | NOT NULL | Recorded timestamp (UTC) |
| `recorded_by` | `BIGINT` | NOT NULL | User who recorded |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_student_attendance PRIMARY KEY CLUSTERED (student_attendance_id)`
- `CONSTRAINT UQ_student_attendance_student_period_date UNIQUE NONCLUSTERED`
- `CONSTRAINT CK_student_attendance_status CHECK`
- `CONSTRAINT CK_student_attendance_period_number CHECK (period_number > 0)`
- `CONSTRAINT CK_student_attendance_time CHECK (end_time > start_time)`
- `CONSTRAINT FK_student_attendance_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_student_attendance_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_student_attendance_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_student_attendance_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_student_attendance_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_student_attendance_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_student_attendance_timetable FOREIGN KEY (timetable_id) REFERENCES management_schema.timetable (timetable_id)`
- `CONSTRAINT FK_student_attendance_timetable_period FOREIGN KEY (timetable_period_id) REFERENCES management_schema.timetable_period (timetable_period_id)`
- `CONSTRAINT FK_student_attendance_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id)`
- `CONSTRAINT FK_student_attendance_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id)`
- `CONSTRAINT FK_student_attendance_recorded_by FOREIGN KEY (recorded_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_student_attendance_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_student_attendance_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_student_attendance_student_date`
- `IX_student_attendance_student_year_date`
- `IX_student_attendance_section_date`
- `IX_student_attendance_section_period_date`
- `IX_student_attendance_teacher_date`
- `IX_student_attendance_status_date`
- `IX_student_attendance_timetable_period_date`

### `student_schema.student_guardian`

- **Migration:** `005_student.sql`
- **Purpose:** Student master identity, current academic placement, and guardians

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `student_guardian_id` | `BIGINT` | NOT NULL |  |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `guardian_name` | `NVARCHAR(200)` | NOT NULL |  |
| `relationship_type` | `NVARCHAR(50)` | NOT NULL |  |
| `mobile_number` | `NVARCHAR(20)` | NULL |  |
| `alternate_mobile_number` | `NVARCHAR(20)` | NULL |  |
| `email_address` | `NVARCHAR(254)` | NULL |  |
| `occupation` | `NVARCHAR(150)` | NULL |  |
| `organization_name` | `NVARCHAR(200)` | NULL |  |
| `is_legal_guardian` | `BIT` | NOT NULL |  |
| `is_primary_contact` | `BIT` | NOT NULL |  |
| `is_emergency_contact` | `BIT` | NOT NULL |  |
| `is_pickup_authorized` | `BIT` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_student_guardian PRIMARY KEY CLUSTERED (student_guardian_id)`
- `CONSTRAINT FK_student_guardian_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_student_guardian_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_student_guardian_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_student_guardian_student`
- `IX_student_guardian_relationship`
- `UX_student_guardian_primary_contact`

### `student_schema.student_leave`

- **Migration:** `011_leave.sql`
- **Purpose:** Student leave applications (students only â€" not teacher/staff leave)

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `student_leave_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `leave_type` | `NVARCHAR(30)` | NOT NULL |  |
| `duration_type` | `NVARCHAR(20)` | NOT NULL |  |
| `half_day_session` | `NVARCHAR(20)` | NULL |  |
| `start_date` | `DATE` | NOT NULL |  |
| `end_date` | `DATE` | NOT NULL |  |
| `reason` | `NVARCHAR(500)` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `applied_at` | `DATETIME2(0)` | NOT NULL |  |
| `reviewed_at` | `DATETIME2(0)` | NULL |  |
| `reviewed_by` | `BIGINT` | NULL |  |
| `review_remarks` | `NVARCHAR(500)` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_student_leave PRIMARY KEY CLUSTERED (student_leave_id)`
- `CONSTRAINT CK_student_leave_type CHECK`
- `CONSTRAINT CK_student_leave_duration_type CHECK`
- `CONSTRAINT CK_student_leave_half_day_session CHECK`
- `CONSTRAINT CK_student_leave_status CHECK`
- `CONSTRAINT CK_student_leave_date_range CHECK (end_date >= start_date)`
- `CONSTRAINT CK_student_leave_half_day CHECK`
- `CONSTRAINT CK_student_leave_full_day CHECK`
- `CONSTRAINT CK_student_leave_multiple_days CHECK`
- `CONSTRAINT CK_student_leave_apply_before_leave_day CHECK`
- `CONSTRAINT CK_student_leave_reviewed CHECK`
- `CONSTRAINT FK_student_leave_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_student_leave_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_student_leave_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_student_leave_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_student_leave_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_student_leave_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_student_leave_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_student_leave_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_student_leave_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_student_leave_student_dates`
- `IX_student_leave_section_status`
- `IX_student_leave_approved_student_dates`
- `IX_student_leave_pending`
- `IX_student_leave_approved_student_dates`

### `student_schema.transport_assignment`

- **Migration:** `015_transport.sql`
- **Purpose:** Bus tracking - vehicles, routes, trips, and student transport assignments

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `transport_assignment_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `vehicle_route_id` | `BIGINT` | NOT NULL |  |
| `pickup_route_stop_id` | `BIGINT` | NOT NULL |  |
| `drop_route_stop_id` | `BIGINT` | NOT NULL |  |
| `estimated_pickup_time` | `TIME(0)` | NOT NULL |  |
| `estimated_drop_time` | `TIME(0)` | NOT NULL |  |
| `effective_from` | `DATE` | NOT NULL |  |
| `effective_to` | `DATE` | NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_transport_assignment PRIMARY KEY CLUSTERED (transport_assignment_id)`
- `CONSTRAINT CK_transport_assignment_status CHECK (status IN (N'ACTIVE', N'INACTIVE'))`
- `CONSTRAINT CK_transport_assignment_dates CHECK`
- `CONSTRAINT CK_transport_assignment_stop_pair CHECK (pickup_route_stop_id <> drop_route_stop_id)`
- `CONSTRAINT FK_transport_assignment_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_transport_assignment_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_transport_assignment_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_transport_assignment_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_transport_assignment_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_transport_assignment_student_scope FOREIGN KEY (school_id, branch_id, student_id)`
- `CONSTRAINT FK_transport_assignment_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_transport_assignment_vehicle_route FOREIGN KEY (vehicle_route_id) REFERENCES transport_schema.vehicle_route (vehicle_route_id)`
- `CONSTRAINT FK_transport_assignment_pickup_stop FOREIGN KEY (branch_id, pickup_route_stop_id)`
- `CONSTRAINT FK_transport_assignment_drop_stop FOREIGN KEY (branch_id, drop_route_stop_id)`
- `CONSTRAINT FK_transport_assignment_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_transport_assignment_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `UQ_transport_assignment_active_student`
- `IX_transport_assignment_student_status`
- `IX_transport_assignment_vehicle_route`
- `IX_transport_assignment_branch_student`

### `student_schema.transport_change_request`

- **Migration:** `015_transport.sql`
- **Purpose:** Bus tracking - vehicles, routes, trips, and student transport assignments

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `transport_change_request_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `student_id` | `BIGINT` | NOT NULL | Student FK |
| `request_type` | `NVARCHAR(20)` | NOT NULL |  |
| `current_vehicle_route_id` | `BIGINT` | NOT NULL |  |
| `requested_vehicle_route_id` | `BIGINT` | NULL |  |
| `current_pickup_stop_id` | `BIGINT` | NOT NULL |  |
| `requested_pickup_stop_id` | `BIGINT` | NULL |  |
| `current_drop_stop_id` | `BIGINT` | NOT NULL |  |
| `requested_drop_stop_id` | `BIGINT` | NULL |  |
| `effective_date` | `DATE` | NOT NULL |  |
| `return_date` | `DATE` | NULL |  |
| `reason` | `NVARCHAR(500)` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `reviewed_by` | `BIGINT` | NULL |  |
| `reviewed_at` | `DATETIME2(0)` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_transport_change_request PRIMARY KEY CLUSTERED (transport_change_request_id)`
- `CONSTRAINT CK_transport_change_request_type CHECK`
- `CONSTRAINT CK_transport_change_request_status CHECK`
- `CONSTRAINT CK_transport_change_request_return_date CHECK`
- `CONSTRAINT CK_transport_change_request_reason CHECK (LEN(LTRIM(RTRIM(reason))) > 0)`
- `CONSTRAINT CK_transport_change_request_review_state CHECK`
- `CONSTRAINT CK_transport_change_request_effective_date CHECK (effective_date >= CAST(SYSDATETIME() AS date) OR status = N'PENDING' OR status = N'REJECTED')`
- `CONSTRAINT FK_transport_change_request_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_transport_change_request_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_transport_change_request_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id)`
- `CONSTRAINT FK_transport_change_request_current_route FOREIGN KEY (current_vehicle_route_id) REFERENCES transport_schema.vehicle_route (vehicle_route_id)`
- `CONSTRAINT FK_transport_change_request_requested_route FOREIGN KEY (requested_vehicle_route_id) REFERENCES transport_schema.vehicle_route (vehicle_route_id)`
- `CONSTRAINT FK_transport_change_request_current_pickup FOREIGN KEY (branch_id, current_pickup_stop_id)`
- `CONSTRAINT FK_transport_change_request_requested_pickup FOREIGN KEY (branch_id, requested_pickup_stop_id)`
- `CONSTRAINT FK_transport_change_request_current_drop FOREIGN KEY (branch_id, current_drop_stop_id)`
- `CONSTRAINT FK_transport_change_request_requested_drop FOREIGN KEY (branch_id, requested_drop_stop_id)`
- `CONSTRAINT FK_transport_change_request_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_transport_change_request_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_transport_change_request_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_transport_change_request_student_status`
- `IX_transport_change_request_pending_branch`

## `teachers_schema`

### `teachers_schema.assessment`

- **Migration:** `006_assessment.sql`
- **Purpose:** Assessment master (project works, slip tests, quizzes - subject-wise) and per-student assessment marks

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `assessment_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `subject_id` | `BIGINT` | NOT NULL | Subject FK |
| `teacher_id` | `BIGINT` | NOT NULL | Teacher FK |
| `title` | `NVARCHAR(200)` | NOT NULL |  |
| `assessment_type` | `NVARCHAR(50)` | NOT NULL |  |
| `assessment_date` | `DATE` | NOT NULL |  |
| `max_marks` | `DECIMAL(6, 2)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_assessment PRIMARY KEY CLUSTERED (assessment_id)`
- `CONSTRAINT CK_assessment_type CHECK`
- `CONSTRAINT CK_assessment_max_marks CHECK (max_marks > 0)`
- `CONSTRAINT FK_assessment_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_assessment_academic_year_scope FOREIGN KEY (school_id, academic_year_id)`
- `CONSTRAINT FK_assessment_branch_scope FOREIGN KEY (school_id, branch_id)`
- `CONSTRAINT FK_assessment_class_scope FOREIGN KEY (school_id, class_id)`
- `CONSTRAINT FK_assessment_section_scope FOREIGN KEY (class_id, section_id)`
- `CONSTRAINT FK_assessment_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id)`
- `CONSTRAINT FK_assessment_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id)`
- `CONSTRAINT FK_assessment_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_assessment_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_assessment_scope_date`
- `IX_assessment_teacher_active`
- `IX_assessment_subject`

### `teachers_schema.homework`

- **Migration:** `009_homework.sql`
- **Purpose:** Section-scoped homework / learning tasks (no marks) with deadlines

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `homework_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `subject_id` | `BIGINT` | NOT NULL | Subject FK |
| `teacher_id` | `BIGINT` | NOT NULL | Teacher FK |
| `homework_type` | `NVARCHAR(50)` | NOT NULL |  |
| `title` | `NVARCHAR(200)` | NOT NULL |  |
| `description` | `NVARCHAR(MAX)` | NULL |  |
| `priority_level` | `NVARCHAR(20)` | NOT NULL |  |
| `assigned_at` | `DATETIME2(0)` | NOT NULL |  |
| `deadline_at` | `DATETIME2(0)` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `estimated_minutes` | `INT` | NULL |  |
| `published_at` | `DATETIME2(0)` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_homework PRIMARY KEY CLUSTERED (homework_id)`
- `CONSTRAINT CK_homework_type CHECK`
- `CONSTRAINT CK_homework_priority CHECK (priority_level IN (N'HIGH', N'MEDIUM', N'LOW'))`
- `CONSTRAINT CK_homework_status CHECK (status IN (N'DRAFT', N'PUBLISHED', N'CLOSED', N'CANCELLED'))`
- `CONSTRAINT CK_homework_estimated_minutes CHECK (estimated_minutes IS NULL OR estimated_minutes >= 0)`
- `CONSTRAINT CK_homework_deadline CHECK (deadline_at >= assigned_at)`
- `CONSTRAINT CK_homework_published_at CHECK`
- `CONSTRAINT FK_homework_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_homework_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id)`
- `CONSTRAINT FK_homework_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_homework_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id)`
- `CONSTRAINT FK_homework_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id)`
- `CONSTRAINT FK_homework_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id)`
- `CONSTRAINT FK_homework_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id)`
- `CONSTRAINT FK_homework_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_homework_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_homework_scope_status_deadline`
- `IX_homework_teacher_active`

### `teachers_schema.teacher`

- **Migration:** `004_teacher.sql`
- **Purpose:** Teacher master identity within school/branch scope

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `teacher_id` | `BIGINT` | NOT NULL | Teacher FK |
| `user_id` | `BIGINT` | NULL | User FK |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `subject_id` | `BIGINT` | NULL | Subject FK |
| `employee_code` | `NVARCHAR(50)` | NOT NULL |  |
| `first_name` | `NVARCHAR(100)` | NOT NULL |  |
| `middle_name` | `NVARCHAR(100)` | NULL |  |
| `last_name` | `NVARCHAR(100)` | NULL |  |
| `mobile_number` | `NVARCHAR(20)` | NULL |  |
| `email_address` | `NVARCHAR(254)` | NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_teacher PRIMARY KEY CLUSTERED (teacher_id)`
- `CONSTRAINT UQ_teacher_school_employee_code UNIQUE NONCLUSTERED (school_id, employee_code)`
- `CONSTRAINT UQ_teacher_user_id UNIQUE NONCLUSTERED (user_id)`
- `CONSTRAINT CK_teacher_status CHECK (status IN (N'ACTIVE', N'INACTIVE', N'ON_LEAVE'))`
- `CONSTRAINT FK_teacher_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_teacher_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_teacher_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id)`
- `CONSTRAINT FK_teacher_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id)`
- `CONSTRAINT FK_teacher_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_teacher_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_teacher_school_branch_active`
- `IX_teacher_subject_active`

### `teachers_schema.teacher_subject_assignment`

- **Migration:** `004_teacher.sql`
- **Purpose:** Teacher master identity within school/branch scope

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `teacher_subject_assignment_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `academic_year_id` | `BIGINT` | NOT NULL | Academic year FK |
| `class_id` | `BIGINT` | NOT NULL | Class FK |
| `section_id` | `BIGINT` | NOT NULL | Section FK |
| `class_subject_id` | `BIGINT` | NOT NULL |  |
| `subject_id` | `BIGINT` | NOT NULL | Subject FK |
| `teacher_id` | `BIGINT` | NOT NULL | Teacher FK |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_teacher_subject_assignment PRIMARY KEY CLUSTERED (teacher_subject_assignment_id)`
- `CONSTRAINT UQ_teacher_subject_assignment_scope UNIQUE NONCLUSTERED`
- `CONSTRAINT FK_teacher_subject_assignment_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_teacher_subject_assignment_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id)`
- `CONSTRAINT FK_teacher_subject_assignment_academic_year_scope FOREIGN KEY (school_id, academic_year_id) REFERENCES management_schema.academic_year (school_id, academic_year_id)`
- `CONSTRAINT FK_teacher_subject_assignment_class_scope FOREIGN KEY (school_id, class_id) REFERENCES management_schema.school_class (school_id, class_id)`
- `CONSTRAINT FK_teacher_subject_assignment_section_scope FOREIGN KEY (class_id, section_id) REFERENCES management_schema.section (class_id, section_id)`
- `CONSTRAINT FK_teacher_subject_assignment_class_subject FOREIGN KEY (class_subject_id) REFERENCES management_schema.class_subject (class_subject_id)`
- `CONSTRAINT FK_teacher_subject_assignment_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id)`
- `CONSTRAINT FK_teacher_subject_assignment_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id)`
- `CONSTRAINT FK_teacher_subject_assignment_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_teacher_subject_assignment_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_teacher_subject_assignment_teacher_active`
- `IX_teacher_subject_assignment_section_active`

## `transport_schema`

### `transport_schema.speed_measurement`

- **Migration:** `015_transport.sql`
- **Purpose:** Bus tracking - vehicles, routes, trips, and student transport assignments

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `speed_measurement_id` | `BIGINT` | NOT NULL |  |
| `trip_id` | `BIGINT` | NOT NULL |  |
| `vehicle_id` | `BIGINT` | NOT NULL |  |
| `recorded_at` | `DATETIME2(0)` | NOT NULL | Recorded timestamp (UTC) |
| `speed_kmh` | `DECIMAL(6, 2)` | NOT NULL |  |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |

**Constraints**

- `CONSTRAINT PK_speed_measurement PRIMARY KEY CLUSTERED (speed_measurement_id)`
- `CONSTRAINT CK_speed_measurement_speed CHECK (speed_kmh >= 0)`
- `CONSTRAINT FK_speed_measurement_trip FOREIGN KEY (trip_id) REFERENCES transport_schema.trip (trip_id)`
- `CONSTRAINT FK_speed_measurement_vehicle FOREIGN KEY (vehicle_id) REFERENCES transport_schema.vehicle (vehicle_id)`

**Indexes**

- `IX_speed_measurement_trip_time`
- `IX_speed_measurement_vehicle_time`

### `transport_schema.staff`

- **Migration:** `015_transport.sql`
- **Purpose:** Bus tracking - vehicles, routes, trips, and student transport assignments

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `staff_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `user_id` | `BIGINT` | NULL | User FK |
| `staff_name` | `NVARCHAR(150)` | NOT NULL |  |
| `staff_type` | `NVARCHAR(30)` | NOT NULL |  |
| `experience` | `INT` | NOT NULL | Years of professional experience |
| `mobile_number` | `NVARCHAR(20)` | NULL |  |
| `license_number` | `NVARCHAR(50)` | NULL |  |
| `license_expiry_date` | `DATE` | NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_transport_staff PRIMARY KEY CLUSTERED (staff_id)`
- `CONSTRAINT CK_transport_staff_name CHECK (LEN(LTRIM(RTRIM(staff_name))) > 0)`
- `CONSTRAINT CK_transport_staff_type CHECK`
- `CONSTRAINT CK_transport_staff_experience CHECK (experience >= 0)`
- `CONSTRAINT CK_transport_staff_status CHECK (status IN (N'ACTIVE', N'INACTIVE'))`
- `CONSTRAINT CK_transport_staff_license_expiry CHECK`
- `CONSTRAINT FK_transport_staff_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_transport_staff_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_transport_staff_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_transport_staff_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_transport_staff_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `UQ_transport_staff_branch_user`
- `UQ_transport_staff_branch_license`
- `IX_transport_staff_branch_type`
- `IX_transport_staff_mobile`

### `transport_schema.trip`

- **Migration:** `015_transport.sql`
- **Purpose:** Bus tracking - vehicles, routes, trips, and student transport assignments

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `trip_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `vehicle_id` | `BIGINT` | NOT NULL |  |
| `vehicle_route_id` | `BIGINT` | NOT NULL |  |
| `driver_id` | `BIGINT` | NOT NULL |  |
| `trip_date` | `DATE` | NOT NULL |  |
| `trip_type` | `NVARCHAR(20)` | NOT NULL |  |
| `planned_start_time` | `TIME(0)` | NOT NULL |  |
| `actual_start_at` | `DATETIME2(0)` | NULL |  |
| `planned_destination_time` | `TIME(0)` | NOT NULL |  |
| `actual_destination_at` | `DATETIME2(0)` | NULL |  |
| `delay_minutes` | `SMALLINT` | NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_trip PRIMARY KEY CLUSTERED (trip_id)`
- `CONSTRAINT CK_trip_type CHECK (trip_type IN (N'PICKUP', N'DROP'))`
- `CONSTRAINT CK_trip_status CHECK`
- `CONSTRAINT CK_trip_delay CHECK (delay_minutes IS NULL OR delay_minutes >= 0)`
- `CONSTRAINT CK_trip_time_window CHECK`
- `CONSTRAINT FK_trip_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_trip_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_trip_vehicle FOREIGN KEY (vehicle_id) REFERENCES transport_schema.vehicle (vehicle_id)`
- `CONSTRAINT FK_trip_vehicle_route FOREIGN KEY (vehicle_route_id) REFERENCES transport_schema.vehicle_route (vehicle_route_id)`
- `CONSTRAINT FK_trip_driver FOREIGN KEY (driver_id) REFERENCES transport_schema.staff (staff_id)`
- `CONSTRAINT FK_trip_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_trip_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_trip_vehicle_date`
- `IX_trip_route_date`
- `IX_trip_status_date`
- `IX_trip_driver_date`

### `transport_schema.trip_stop`

- **Migration:** `015_transport.sql`
- **Purpose:** Bus tracking - vehicles, routes, trips, and student transport assignments

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `trip_stop_id` | `BIGINT` | NOT NULL |  |
| `trip_id` | `BIGINT` | NOT NULL |  |
| `vehicle_route_id` | `BIGINT` | NOT NULL |  |
| `route_stop_id` | `BIGINT` | NOT NULL |  |
| `stop_sequence` | `SMALLINT` | NOT NULL |  |
| `planned_arrival_at` | `DATETIME2(0)` | NOT NULL |  |
| `actual_arrival_at` | `DATETIME2(0)` | NULL |  |
| `actual_departure_at` | `DATETIME2(0)` | NULL |  |
| `delay_minutes` | `SMALLINT` | NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_trip_stop PRIMARY KEY CLUSTERED (trip_stop_id)`
- `CONSTRAINT UQ_trip_stop_trip_sequence UNIQUE NONCLUSTERED (trip_id, stop_sequence)`
- `CONSTRAINT UQ_trip_stop_trip_route_stop UNIQUE NONCLUSTERED (trip_id, route_stop_id)`
- `CONSTRAINT CK_trip_stop_sequence CHECK (stop_sequence > 0)`
- `CONSTRAINT CK_trip_stop_status CHECK`
- `CONSTRAINT CK_trip_stop_delay CHECK (delay_minutes IS NULL OR delay_minutes >= 0)`
- `CONSTRAINT CK_trip_stop_actual_time CHECK`
- `CONSTRAINT FK_trip_stop_trip FOREIGN KEY (trip_id) REFERENCES transport_schema.trip (trip_id)`
- `CONSTRAINT FK_trip_stop_vehicle_route FOREIGN KEY (vehicle_route_id) REFERENCES transport_schema.vehicle_route (vehicle_route_id)`

**Indexes**

- `IX_trip_stop_trip_sequence`
- `IX_trip_stop_status_route`

### `transport_schema.vehicle`

- **Migration:** `015_transport.sql`
- **Purpose:** Bus tracking - vehicles, routes, trips, and student transport assignments

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `vehicle_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `vehicle_number` | `NVARCHAR(30)` | NOT NULL |  |
| `vehicle_name` | `NVARCHAR(100)` | NULL |  |
| `capacity` | `INT` | NOT NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `vehicle_health` | `NVARCHAR(30)` | NOT NULL | Vehicle condition: EXCELLENT, GOOD, FAIR, NEEDS_SERVICE, CRITICAL |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_vehicle PRIMARY KEY CLUSTERED (vehicle_id)`
- `CONSTRAINT UQ_vehicle_branch_number UNIQUE NONCLUSTERED (branch_id, vehicle_number)`
- `CONSTRAINT CK_vehicle_number_non_empty CHECK (LEN(LTRIM(RTRIM(vehicle_number))) > 0)`
- `CONSTRAINT CK_vehicle_name_non_empty CHECK (vehicle_name IS NULL OR LEN(LTRIM(RTRIM(vehicle_name))) > 0)`
- `CONSTRAINT CK_vehicle_status CHECK (status IN (N'ACTIVE', N'INACTIVE', N'MAINTENANCE'))`
- `CONSTRAINT CK_transport_vehicle_health CHECK (vehicle_health IN (N'EXCELLENT', N'GOOD', N'FAIR', N'NEEDS_SERVICE', N'CRITICAL'))`
- `CONSTRAINT CK_vehicle_capacity CHECK (capacity IS NULL OR capacity > 0)`
- `CONSTRAINT FK_vehicle_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_vehicle_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_vehicle_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_vehicle_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_vehicle_branch_status`

### `transport_schema.vehicle_route`

- **Migration:** `015_transport.sql`
- **Purpose:** Bus tracking - vehicles, routes, trips, and student transport assignments

| Column | Type | Null | Notes |
|--------|------|------|-------|
| `vehicle_route_id` | `BIGINT` | NOT NULL |  |
| `school_id` | `BIGINT` | NOT NULL | School scope FK |
| `branch_id` | `BIGINT` | NOT NULL | Branch scope FK |
| `vehicle_id` | `BIGINT` | NOT NULL |  |
| `route_code` | `NVARCHAR(30)` | NOT NULL |  |
| `route_name` | `NVARCHAR(150)` | NOT NULL |  |
| `route_type` | `NVARCHAR(20)` | NOT NULL |  |
| `route_stop_id` | `BIGINT` | NOT NULL |  |
| `stop_sequence` | `SMALLINT` | NOT NULL |  |
| `stop_name` | `NVARCHAR(150)` | NOT NULL |  |
| `stop_address` | `NVARCHAR(300)` | NULL |  |
| `planned_arrival_time` | `TIME(0)` | NOT NULL |  |
| `planned_departure_time` | `TIME(0)` | NULL |  |
| `status` | `NVARCHAR(20)` | NOT NULL |  |
| `effective_from` | `DATE` | NOT NULL |  |
| `effective_to` | `DATE` | NULL |  |
| `is_active` | `BIT` | NOT NULL | Soft active flag |
| `created_at` | `DATETIME2(0)` | NOT NULL | Record created (UTC) |
| `created_by` | `BIGINT` | NOT NULL | User who created |
| `updated_at` | `DATETIME2(0)` | NOT NULL | Record last updated (UTC) |
| `updated_by` | `BIGINT` | NULL | User who last updated |
| `row_version` | `ROWVERSION` | NOT NULL | Concurrency token |

**Constraints**

- `CONSTRAINT PK_vehicle_route PRIMARY KEY CLUSTERED (vehicle_route_id)`
- `CONSTRAINT UQ_vehicle_route_branch_stop UNIQUE NONCLUSTERED (branch_id, route_stop_id)`
- `CONSTRAINT UQ_vehicle_route_stop_order UNIQUE NONCLUSTERED`
- `CONSTRAINT CK_vehicle_route_code CHECK (LEN(LTRIM(RTRIM(route_code))) > 0)`
- `CONSTRAINT CK_vehicle_route_name CHECK (LEN(LTRIM(RTRIM(route_name))) > 0)`
- `CONSTRAINT CK_vehicle_route_type CHECK (route_type IN (N'PICKUP', N'DROP'))`
- `CONSTRAINT CK_vehicle_route_status CHECK (status IN (N'ACTIVE', N'INACTIVE'))`
- `CONSTRAINT CK_vehicle_route_stop_id CHECK (route_stop_id > 0)`
- `CONSTRAINT CK_vehicle_route_stop_sequence CHECK (stop_sequence > 0)`
- `CONSTRAINT CK_vehicle_route_stop_name CHECK (LEN(LTRIM(RTRIM(stop_name))) > 0)`
- `CONSTRAINT CK_vehicle_route_dates CHECK`
- `CONSTRAINT FK_vehicle_route_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id)`
- `CONSTRAINT FK_vehicle_route_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id)`
- `CONSTRAINT FK_vehicle_route_vehicle FOREIGN KEY (vehicle_id) REFERENCES transport_schema.vehicle (vehicle_id)`
- `CONSTRAINT FK_vehicle_route_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id)`
- `CONSTRAINT FK_vehicle_route_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)`

**Indexes**

- `IX_vehicle_route_vehicle`
- `IX_vehicle_route_route_order`
- `IX_vehicle_route_branch`

## Appendix: SQL vs MongoDB vs Redis vs Blob

### SQL Server (43 tables)

Core ERP: students, teachers, masters, timetable, attendance, exams, assignments, homework, fees, receipts, library, transport, security (auth), leave, grievance, announcements.

### MongoDB

See [mongodb-collections-reference.md](./mongodb-collections-reference.md).

- Student Overview / Compass snapshots
- Learning Hub (syllabus, resources, exam papers, progress)
- Connect masters (chat threads, meetings, community)
- Auth JWT session hashes (`user_jwt_token`)
- Document / attachment metadata + Blob refs

### Azure Blob Storage

Actual file bytes (PDF, images) linked from MongoDB metadata.

### Redis (live only)

- Live bus GPS lat/long and ETA
- Connect unread / presence / recent message cache
- Optional access-token blacklist on logout

### Auth in SQL (`security_schema`)

- `users` (identity + credentials), `user_login_attempt`, `schema_version`
- Access + refresh token hashes: MongoDB `user_jwt_token`
- Authorization: `user_type` + FastAPI domain rules (no SQL RBAC / `user_scope`)
