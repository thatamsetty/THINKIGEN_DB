/*
    Module: 002_security
    Purpose: Identity + credentials (one users table), login audit, migration tracking

    Auth design (approved simplified model):
    - users = identity + password/lock fields; login key = email_address (NOT NULL, UNIQUE)
    - No username column
    - No separate user_credential table (merged into users)
    - No user_refresh_token in SQL — access + refresh tokens live in MongoDB
    - No RBAC tables (role / permission / role_permission / user_role_assignment)
      Authorization = user_type + domain placement (student / teacher assignment) in FastAPI
    - No user_scope table — scope derived in FastAPI from student/teacher/admin rules
    - user_login_attempt = append-only audit; user_id NOT NULL (only when user is known)
    - password_hash via FastAPI (bcrypt/argon2); password_plain_dev LOCAL only — remove before production
    - schema_version tracks applied SQL migrations
*/

/* -------------------------------------------------------------------------- */
/* security_schema.users                                                      */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.users', N'U') IS NULL
BEGIN
    CREATE TABLE security_schema.users
    (
        user_id                BIGINT          NOT NULL IDENTITY(1, 1),
        email_address          NVARCHAR(254)   NOT NULL,
        user_type              NVARCHAR(30)    NOT NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_users_is_active DEFAULT (1),
        password_hash          NVARCHAR(255)   NULL,
        password_plain_dev     NVARCHAR(255)   NULL,
        password_set_at        DATETIME2(0)    NULL,
        failed_login_count     INT             NOT NULL CONSTRAINT DF_users_failed_login DEFAULT (0),
        locked_until           DATETIME2(0)    NULL,
        last_login_at          DATETIME2(0)    NULL,
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_users_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_users_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        CONSTRAINT PK_users PRIMARY KEY CLUSTERED (user_id),
        CONSTRAINT UQ_users_email_address UNIQUE NONCLUSTERED (email_address),
        CONSTRAINT CK_users_failed_login CHECK (failed_login_count >= 0)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_users_user_type_active' AND object_id = OBJECT_ID(N'security_schema.users')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_users_user_type_active
        ON security_schema.users (user_type, is_active);
END;
GO

/* -------------------------------------------------------------------------- */
/* security_schema.user_login_attempt                                         */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.user_login_attempt', N'U') IS NULL
BEGIN
    CREATE TABLE security_schema.user_login_attempt
    (
        login_attempt_id     BIGINT          NOT NULL IDENTITY(1, 1),
        user_id              BIGINT          NOT NULL,
        is_success           BIT             NOT NULL,
        failure_reason       NVARCHAR(50)    NULL,
        ip_address           NVARCHAR(45)    NULL,
        user_agent           NVARCHAR(500)   NULL,
        attempted_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_user_login_attempt_attempted_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_user_login_attempt PRIMARY KEY CLUSTERED (login_attempt_id),
        CONSTRAINT CK_user_login_attempt_result CHECK
            ((is_success = 1 AND failure_reason IS NULL)
             OR (is_success = 0 AND failure_reason IS NOT NULL)),
        CONSTRAINT CK_user_login_attempt_failure_reason CHECK
            (failure_reason IS NULL OR failure_reason IN (
                N'BAD_PASSWORD', N'USER_INACTIVE', N'ACCOUNT_LOCKED')),
        CONSTRAINT FK_user_login_attempt_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_user_login_attempt_user_time'
      AND object_id = OBJECT_ID(N'security_schema.user_login_attempt')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_user_login_attempt_user_time
        ON security_schema.user_login_attempt (user_id, attempted_at DESC);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_user_login_attempt_ip_time'
      AND object_id = OBJECT_ID(N'security_schema.user_login_attempt')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_user_login_attempt_ip_time
        ON security_schema.user_login_attempt (ip_address, attempted_at DESC)
        WHERE ip_address IS NOT NULL;
END;
GO

/* -------------------------------------------------------------------------- */
/* security_schema.schema_version                                             */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'security_schema.schema_version', N'U') IS NULL
BEGIN
    CREATE TABLE security_schema.schema_version
    (
        schema_version_id  INT             NOT NULL IDENTITY(1, 1),
        migration_name     NVARCHAR(200)   NOT NULL,
        applied_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_schema_version_applied_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_schema_version PRIMARY KEY CLUSTERED (schema_version_id),
        CONSTRAINT UQ_schema_version_name UNIQUE NONCLUSTERED (migration_name)
    );
END;
GO
