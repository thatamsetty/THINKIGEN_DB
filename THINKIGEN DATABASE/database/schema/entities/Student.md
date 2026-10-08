# Entity: student_schema.student

## Purpose

Authoritative master for student identity, demographics, admission, contact, address, lifecycle status, and **current** academic placement.

When `security_schema.users.user_type = STUDENT` completes enrollment, one row is created here with `student_id` and placement (`school_id`, `branch_id`, `academic_year_id`, `class_id`, `section_id`). Promotion or section change updates this row.

There is **no** `student_enrollment` table and **no** SQL document table.

## Primary key

- `student_id` — `BIGINT IDENTITY`, clustered

## Columns

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| student_id | BIGINT | NO | IDENTITY | Internal student identifier |
| user_id | BIGINT | YES | — | Optional link to login account |
| school_id | BIGINT | NO | — | Current school |
| branch_id | BIGINT | NO | — | Current branch |
| academic_year_id | BIGINT | NO | — | Current academic year |
| class_id | BIGINT | NO | — | Current class |
| section_id | BIGINT | NO | — | Current section |
| admission_number | NVARCHAR(50) | NO | — | School admission number |
| roll_number | NVARCHAR(30) | YES | — | Class roll number |
| first_name | NVARCHAR(100) | NO | — | First name |
| middle_name | NVARCHAR(100) | YES | — | Middle name |
| last_name | NVARCHAR(100) | YES | — | Last name |
| date_of_birth | DATE | NO | — | Date of birth |
| gender | NVARCHAR(30) | NO | — | Gender (descriptive value) |
| blood_group | NVARCHAR(10) | YES | — | Blood group |
| nationality | NVARCHAR(100) | YES | — | Nationality |
| mother_tongue | NVARCHAR(100) | YES | — | Mother tongue |
| religion | NVARCHAR(100) | YES | — | Religion |
| student_category | NVARCHAR(100) | YES | — | Student category |
| residency_type | NVARCHAR(20) | NO | DAY_SCHOLAR | Accommodation type: `HOSTELLER` or `DAY_SCHOLAR` |
| admission_date | DATE | NO | — | Admission date |
| student_status | NVARCHAR(30) | NO | — | Lifecycle status |
| status_effective_date | DATE | YES | — | Status effective from |
| mobile_number | NVARCHAR(20) | YES | — | Student mobile |
| email_address | NVARCHAR(254) | YES | — | Student email |
| address_line_1 | NVARCHAR(200) | YES | — | Address line 1 |
| address_line_2 | NVARCHAR(200) | YES | — | Address line 2 |
| landmark | NVARCHAR(150) | YES | — | Landmark |
| city | NVARCHAR(100) | YES | — | City |
| district | NVARCHAR(100) | YES | — | District |
| state | NVARCHAR(100) | YES | — | State |
| postal_code | NVARCHAR(20) | YES | — | Postal/PIN code |
| country | NVARCHAR(100) | YES | — | Country |
| is_active | BIT | NO | 1 | Active/inactive record flag |
| created_at | DATETIME2(0) | NO | SYSUTCDATETIME() | Created timestamp (UTC) |
| created_by | BIGINT | NO | — | Creating user |
| updated_at | DATETIME2(0) | NO | SYSUTCDATETIME() | Updated timestamp (UTC) |
| updated_by | BIGINT | YES | — | Last updating user |
| row_version | ROWVERSION | NO | — | Optimistic concurrency |

## Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_student | PRIMARY KEY CLUSTERED | student_id |
| UQ_student_school_admission_number | UNIQUE | (school_id, admission_number) |
| UQ_student_user_id | UNIQUE | user_id |
| CK_student_residency_type | CHECK | residency_type IN (`HOSTELLER`, `DAY_SCHOLAR`) |
| FK_student_user | FOREIGN KEY | user_id → security_schema.users(user_id) |
| FK_student_school | FOREIGN KEY | school_id → management_schema.school(school_id) |
| FK_student_branch | FOREIGN KEY | branch_id → management_schema.branch(branch_id) |
| FK_student_academic_year | FOREIGN KEY | academic_year_id → management_schema.academic_year(academic_year_id) |
| FK_student_class | FOREIGN KEY | class_id → management_schema.school_class(class_id) |
| FK_student_section | FOREIGN KEY | section_id → management_schema.section(section_id) |
| FK_student_created_by | FOREIGN KEY | created_by → security_schema.users(user_id) |
| FK_student_updated_by | FOREIGN KEY | updated_by → security_schema.users(user_id) |

## Indexes

| Name | Type | Columns | Purpose |
|------|------|---------|---------|
| PK_student | Clustered | student_id | Primary access |
| UQ_student_school_admission_number | Unique nonclustered | school_id, admission_number | Admission lookup |
| UQ_student_user_id | Unique nonclustered | user_id | Auth-to-student lookup |
| IX_student_academic_scope | Nonclustered | school_id, branch_id, academic_year_id, class_id, section_id, is_active | Class/section roster |
| IX_student_branch_status | Nonclustered | branch_id, student_status, is_active | Branch status filter |
| IX_student_name | Nonclustered | last_name, first_name INCLUDE (...) | Name search |
| IX_student_roll_number | Nonclustered filtered | school_id, academic_year_id, class_id, section_id, roll_number WHERE roll_number IS NOT NULL | Roll lookup |
| IX_student_residency_type_active | Nonclustered | school_id, branch_id, residency_type, is_active INCLUDE (student_id, first_name, last_name, admission_number) | Hostel/day-scholar roster |

## Delete behavior

No physical delete once ERP history exists. Use `is_active = 0` and `student_status` changes.

## Security

PII. Scope enforced in FastAPI (RBAC + ABAC).

## Documents

Student documents: MongoDB metadata + Blob Storage files. See `.cursor/rules/24-student-documents-mongodb.mdc`.
