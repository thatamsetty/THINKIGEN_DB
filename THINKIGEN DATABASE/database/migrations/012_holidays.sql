/* Module migration: 012_holidays.sql */
/*
    Migration: 015_holiday
    Purpose:   School/branch holiday calendar master (academic calendar)

    Design notes:
    - management_schema.holiday = official non-working days per school + branch + academic year
    - Distinct from management_schema.announcement (type HOLIDAY) which is student-facing notices
    - holiday_type: NATIONAL, RELIGIOUS, FESTIVAL, VACATION, OPTIONAL, OTHER
    - App uses this to skip timetable period generation and attendance on holiday dates

    Rollback:
    - DROP TABLE management_schema.holiday;
*/

/* -------------------------------------------------------------------------- */
/* management_schema.holiday                                                  */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'management_schema.holiday', N'U') IS NULL
BEGIN
    CREATE TABLE management_schema.holiday
    (
        holiday_id         BIGINT          NOT NULL IDENTITY(1, 1),
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        academic_year_id   BIGINT          NOT NULL,
        holiday_type       NVARCHAR(30)    NOT NULL,
        holiday_name       NVARCHAR(150)   NOT NULL,
        description        NVARCHAR(MAX)   NULL,
        start_date         DATE            NOT NULL,
        end_date           DATE            NOT NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_holiday_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_holiday_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NOT NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_holiday_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_holiday PRIMARY KEY CLUSTERED (holiday_id),
        CONSTRAINT CK_holiday_type CHECK
            (holiday_type IN (
                N'NATIONAL', N'RELIGIOUS', N'FESTIVAL', N'VACATION', N'OPTIONAL', N'OTHER')),
        CONSTRAINT CK_holiday_date_range CHECK (end_date >= start_date),
        CONSTRAINT FK_holiday_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_holiday_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_holiday_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_holiday_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_holiday_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_holiday_branch_year_dates'
      AND object_id = OBJECT_ID(N'management_schema.holiday')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_holiday_branch_year_dates
        ON management_schema.holiday
        (school_id, branch_id, academic_year_id, start_date, end_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_holiday_branch_type_date'
      AND object_id = OBJECT_ID(N'management_schema.holiday')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_holiday_branch_type_date
        ON management_schema.holiday (branch_id, holiday_type, start_date)
        WHERE is_active = 1;
END;
GO

