# Entity: alumni_schema.alumni_profile

## Purpose

Stores graduate profiles, graduation batch year, professional career records (role, organization, industry), and administrative verification workflow.

## Scope

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id` → `student_id` (1:1 per graduated student).

## Columns

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| alumni_id | BIGINT | NO | IDENTITY | Clustered PK |
| school_id | BIGINT | NO | — | FK → management_schema.school |
| branch_id | BIGINT | NO | — | FK → management_schema.branch |
| academic_year_id | BIGINT | NO | — | FK → management_schema.academic_year |
| class_id | BIGINT | NO | — | FK → management_schema.school_class |
| section_id | BIGINT | NO | — | FK → management_schema.section |
| student_id | BIGINT | NO | — | FK → student_schema.student (UQ) |
| passout_batch_year | INT | NO | — | Year of graduation (1950–2100) |
| current_role | NVARCHAR(150) | YES | — | Job title / designation |
| organisation_name | NVARCHAR(150) | YES | — | Employer or institution name |
| industry_name | NVARCHAR(100) | YES | — | Industry sector |
| location_city | NVARCHAR(100) | YES | — | City of residence/work |
| location_country | NVARCHAR(100) | YES | — | Country of residence/work |
| linkedin_profile_url | NVARCHAR(500) | YES | — | Public LinkedIn URL |
| verification_status | NVARCHAR(20) | NO | 'PENDING' | PENDING / VERIFIED / REJECTED |
| verified_at | DATETIME2(0) | YES | — | UTC timestamp when verified |
| verified_by | BIGINT | YES | — | FK → security_schema.users |
| profile_photo_url | NVARCHAR(500) | YES | — | S3 / CDN profile picture URL |
| is_active | BIT | NO | 1 | Soft active flag |
| created_at | DATETIME2(0) | NO | SYSUTCDATETIME() | UTC creation timestamp |
| created_by | BIGINT | NO | — | FK → security_schema.users |
| updated_at | DATETIME2(0) | NO | SYSUTCDATETIME() | UTC last update timestamp |
| updated_by | BIGINT | YES | — | FK → security_schema.users |
| row_version | ROWVERSION | NO | — | Concurrency token |

## Constraints

| Name | Rule |
|------|------|
| PK_alumni_profile | PRIMARY KEY (alumni_id) |
| UQ_alumni_profile_student | UNIQUE (student_id) |
| CK_alumni_profile_status | verification_status IN ('PENDING', 'VERIFIED', 'REJECTED') |
| CK_alumni_profile_batch | passout_batch_year BETWEEN 1950 AND 2100 |

## Indexes

| Name | Columns | Purpose |
|------|---------|---------|
| IX_alumni_profile_school_status | school_id, branch_id, verification_status | Filter verified alumni per branch |
| IX_alumni_profile_batch | school_id, passout_batch_year, verification_status | Batch reunion & directory view |
| IX_alumni_profile_scope | school_id, branch_id, academic_year_id, class_id, section_id | Academic scope filtering |
