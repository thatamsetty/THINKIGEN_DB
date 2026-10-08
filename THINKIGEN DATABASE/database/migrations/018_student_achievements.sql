/* Module migration: 018_student_achievements.sql */
/*
    Migration: 018_student_achievements
    Purpose:   Student achievements catalog and tracking

    Design notes:
    - student_schema.student_achievement = achievement records for students
    - Scope: school_id + branch_id + student_id for branch-wise tracking
    - Achievements are created by management for individual students
    - Supports multiple categories, levels (National, State, District), and ranking (1st, 2nd, etc.)
    - Audit trail: created_by, updated_by with timestamps

    Rollback:
    - DROP TABLE student_schema.student_achievement;
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student_achievement                                        */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student_achievement', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_achievement
    (
        achievement_id         BIGINT          NOT NULL IDENTITY(1, 1),
        school_id              BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        student_id             BIGINT          NOT NULL,
        achievement_title      NVARCHAR(200)   NOT NULL,
        category               NVARCHAR(100)   NOT NULL,
        description            NVARCHAR(MAX)   NULL,
        achievement_place      NVARCHAR(50)    NOT NULL,
        achievement_level      NVARCHAR(50)    NOT NULL,
        date_issued            DATE            NOT NULL,
        certificate_url        NVARCHAR(500)   NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_student_achievement_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_student_achievement_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_student_achievement_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_achievement PRIMARY KEY CLUSTERED (achievement_id),
        CONSTRAINT CK_student_achievement_title CHECK (LEN(LTRIM(RTRIM(achievement_title))) > 0),
        CONSTRAINT CK_student_achievement_category CHECK (LEN(LTRIM(RTRIM(category))) > 0),
        CONSTRAINT CK_student_achievement_place CHECK (LEN(LTRIM(RTRIM(achievement_place))) > 0),
        CONSTRAINT CK_student_achievement_level CHECK
            (achievement_level IN (N'NATIONAL', N'STATE', N'DISTRICT', N'SCHOOL', N'BRANCH', N'CLASS')),
        CONSTRAINT FK_student_achievement_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_achievement_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_achievement_student_scope FOREIGN KEY (school_id, branch_id, student_id)
            REFERENCES student_schema.student (school_id, branch_id, student_id),
        CONSTRAINT FK_student_achievement_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_achievement_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

/* -------------------------------------------------------------------------- */
/* Indexes for student_schema.student_achievement                            */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_achievement_student_branch'
      AND object_id = OBJECT_ID(N'student_schema.student_achievement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_achievement_student_branch
        ON student_schema.student_achievement (school_id, branch_id, student_id, is_active)
        INCLUDE (achievement_title, category, achievement_level, date_issued)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_achievement_branch_date'
      AND object_id = OBJECT_ID(N'student_schema.student_achievement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_achievement_branch_date
        ON student_schema.student_achievement (school_id, branch_id, date_issued DESC)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_achievement_category_level'
      AND object_id = OBJECT_ID(N'student_schema.student_achievement')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_achievement_category_level
        ON student_schema.student_achievement (school_id, branch_id, category, achievement_level, is_active)
        WHERE is_active = 1;
END;
GO
