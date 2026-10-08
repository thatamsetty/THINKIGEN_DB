# Entity: alumni_schema.alumni_story

## Purpose

Stores verified alumni success stories, testimonials, and career journeys showcased across the school portal and community.

## Scope

`school_id` → `alumni_id` (linked to verified alumni profile).

## Columns

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| alumni_story_id | BIGINT | NO | IDENTITY | Clustered PK |
| school_id | BIGINT | NO | — | FK → management_schema.school |
| alumni_id | BIGINT | NO | — | FK → alumni_schema.alumni_profile |
| story_title | NVARCHAR(200) | NO | — | Article headline |
| story_content | NVARCHAR(MAX) | NO | — | Markdown / story text |
| is_published | BIT | NO | 1 | Publicly visible flag |
| created_at | DATETIME2(0) | NO | SYSUTCDATETIME() | UTC creation timestamp |
| created_by | BIGINT | NO | — | FK → security_schema.users |
| updated_at | DATETIME2(0) | NO | SYSUTCDATETIME() | UTC last update timestamp |
| updated_by | BIGINT | YES | — | FK → security_schema.users |
| row_version | ROWVERSION | NO | — | Concurrency token |

## Constraints

| Name | Rule |
|------|------|
| PK_alumni_story | PRIMARY KEY (alumni_story_id) |
| FK_alumni_story_alumni | FOREIGN KEY (alumni_id) REFERENCES alumni_schema.alumni_profile (alumni_id) |
| FK_alumni_story_school | FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id) |

## Indexes

| Name | Columns | Purpose |
|------|---------|---------|
| IX_alumni_story_school_pub | school_id, is_published | Filter published stories for public/student feed |
