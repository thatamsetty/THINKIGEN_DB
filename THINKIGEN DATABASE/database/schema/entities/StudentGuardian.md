# Entity: student_schema.student_guardian

## Purpose

Parents/guardians linked to a student. One row per guardian relationship (not fixed Father/Mother columns).

Guardian address is not duplicated; the student's address is the common family address.

## Primary key

- `student_guardian_id` — `BIGINT IDENTITY`, clustered

## Columns

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| student_guardian_id | BIGINT | NO | IDENTITY | Guardian relationship id |
| student_id | BIGINT | NO | — | Student FK |
| guardian_name | NVARCHAR(200) | NO | — | Full name |
| relationship_type | NVARCHAR(50) | NO | — | e.g. FATHER, MOTHER, GUARDIAN |
| mobile_number | NVARCHAR(20) | YES | — | Primary mobile |
| alternate_mobile_number | NVARCHAR(20) | YES | — | Alternate mobile |
| email_address | NVARCHAR(254) | YES | — | Email |
| occupation | NVARCHAR(150) | YES | — | Occupation |
| organization_name | NVARCHAR(200) | YES | — | Employer/organization |
| is_legal_guardian | BIT | NO | 0 | Legal guardian flag |
| is_primary_contact | BIT | NO | 0 | Primary family contact |
| is_emergency_contact | BIT | NO | 0 | Emergency contact |
| is_pickup_authorized | BIT | NO | 0 | Pickup authorization |
| is_active | BIT | NO | 1 | Active relationship |
| created_at | DATETIME2(0) | NO | SYSUTCDATETIME() | Created (UTC) |
| created_by | BIGINT | NO | — | Created by user |
| updated_at | DATETIME2(0) | NO | SYSUTCDATETIME() | Updated (UTC) |
| updated_by | BIGINT | YES | — | Updated by user |
| row_version | ROWVERSION | NO | — | Optimistic concurrency |

## Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_student_guardian | PRIMARY KEY CLUSTERED | student_guardian_id |
| FK_student_guardian_student | FOREIGN KEY | student_id → student_schema.student(student_id) |
| FK_student_guardian_created_by | FOREIGN KEY | created_by → security_schema.users(user_id) |
| FK_student_guardian_updated_by | FOREIGN KEY | updated_by → security_schema.users(user_id) |

## Indexes

| Name | Type | Columns | Purpose |
|------|------|---------|---------|
| PK_student_guardian | Clustered | student_guardian_id | Primary access |
| IX_student_guardian_student | Nonclustered | student_id, is_active | List guardians |
| IX_student_guardian_relationship | Nonclustered filtered | student_id, relationship_type WHERE is_active=1 | Relationship lookup |
| UX_student_guardian_primary_contact | Unique filtered | student_id WHERE is_primary_contact=1 AND is_active=1 | One primary contact |

## Business rules

- Multiple guardians per student allowed
- Only one primary contact per active student
- Multiple emergency/pickup-authorized guardians allowed
- Guardian credentials are not stored here

## Security

PII. Restricted by student scope in FastAPI.
