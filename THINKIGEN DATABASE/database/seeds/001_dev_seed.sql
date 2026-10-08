/*
    Seed: 001_dev_seed
    Purpose: Local development bootstrap — admin user only

    Default dev login:
      email:    admin@thinkigen.local
      password: Admin@123  (stored in password_plain_dev for local visibility;
                            hash with bcrypt in FastAPI before production)

    Authorization: user_type + FastAPI domain rules (no SQL RBAC tables).
    Tokens: MongoDB (access + refresh).
*/

SET NOCOUNT ON;
GO

/* Admin user */
IF NOT EXISTS (SELECT 1 FROM security_schema.users WHERE email_address = N'admin@thinkigen.local')
BEGIN
    INSERT INTO security_schema.users
    (
        email_address,
        user_type,
        password_plain_dev,
        password_set_at
    )
    VALUES
    (
        N'admin@thinkigen.local',
        N'ADMIN',
        N'Admin@123',
        SYSUTCDATETIME()
    );
END;
GO

/* Track applied modules */
DECLARE @modules TABLE (migration_name NVARCHAR(200));
INSERT INTO @modules (migration_name) VALUES
    (N'001_schemas'), (N'002_security'), (N'003_management'), (N'004_teacher'),
    (N'005_student'), (N'006_assignment'), (N'007_announcement'), (N'008_timetable'),
    (N'009_homework'), (N'010_attendance'), (N'011_leave'), (N'012_holidays'),
    (N'013_grievance'), (N'014_library'), (N'015_transport'), (N'016_finance'),
    (N'017_exam'), (N'001_dev_seed');

INSERT INTO security_schema.schema_version (migration_name)
SELECT m.migration_name
FROM @modules m
WHERE NOT EXISTS (
    SELECT 1 FROM security_schema.schema_version v WHERE v.migration_name = m.migration_name
);
GO
