/* Module migration: 010_attendance.sql */
/*
    Migration: 013_student_attendance
    Purpose:   Period-wise student attendance linked to timetable

    Design notes:
    - One row per student + timetable_period + attendance_date
    - attendance_status: PRESENT / ABSENT only
    - Scope columns (school -> section) on each row for ABAC and reporting
    - subject_id, teacher_id, period_number, start_time, end_time snapshot from period at record time
    - recorded_at / recorded_by = when and who marked attendance (distinct from created_* audit)
    - No separate attendance-session table (THINKIGEN doc)
    - Application: create rows only for CLASS timetable periods unless business approves otherwise

    Rollback:
    - DROP TABLE student_schema.student_attendance;
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student_attendance                                            */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student_attendance', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_attendance
    (
        student_attendance_id BIGINT          NOT NULL IDENTITY(1, 1),
        school_id             BIGINT          NOT NULL,
        branch_id             BIGINT          NOT NULL,
        academic_year_id      BIGINT          NOT NULL,
        class_id              BIGINT          NOT NULL,
        section_id            BIGINT          NOT NULL,
        student_id            BIGINT          NOT NULL,
        timetable_id          BIGINT          NOT NULL,
        timetable_period_id   BIGINT          NOT NULL,
        attendance_date       DATE            NOT NULL,
        subject_id            BIGINT          NOT NULL,
        teacher_id            BIGINT          NOT NULL,
        period_number         TINYINT         NOT NULL,
        start_time            TIME(0)         NOT NULL,
        end_time              TIME(0)         NOT NULL,
        attendance_status     NVARCHAR(10)    NOT NULL,
        recorded_at           DATETIME2(0)    NOT NULL CONSTRAINT DF_student_attendance_recorded_at DEFAULT (SYSUTCDATETIME()),
        recorded_by           BIGINT          NOT NULL,
        is_active             BIT             NOT NULL CONSTRAINT DF_student_attendance_is_active DEFAULT (1),
        created_at            DATETIME2(0)    NOT NULL CONSTRAINT DF_student_attendance_created_at DEFAULT (SYSUTCDATETIME()),
        created_by            BIGINT          NOT NULL,
        updated_at            DATETIME2(0)    NOT NULL CONSTRAINT DF_student_attendance_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by            BIGINT          NULL,
        row_version           ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_attendance PRIMARY KEY CLUSTERED (student_attendance_id),
        CONSTRAINT UQ_student_attendance_student_period_date UNIQUE NONCLUSTERED
            (student_id, timetable_period_id, attendance_date),
        CONSTRAINT CK_student_attendance_status CHECK
            (attendance_status IN (N'PRESENT', N'ABSENT')),
        CONSTRAINT CK_student_attendance_period_number CHECK (period_number > 0),
        CONSTRAINT CK_student_attendance_time CHECK (end_time > start_time),
        CONSTRAINT FK_student_attendance_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_attendance_branch FOREIGN KEY (branch_id) REFERENCES management_schema.branch (branch_id),
        CONSTRAINT FK_student_attendance_academic_year FOREIGN KEY (academic_year_id) REFERENCES management_schema.academic_year (academic_year_id),
        CONSTRAINT FK_student_attendance_class FOREIGN KEY (class_id) REFERENCES management_schema.school_class (class_id),
        CONSTRAINT FK_student_attendance_section FOREIGN KEY (section_id) REFERENCES management_schema.section (section_id),
        CONSTRAINT FK_student_attendance_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_attendance_timetable FOREIGN KEY (timetable_id) REFERENCES management_schema.timetable (timetable_id),
        CONSTRAINT FK_student_attendance_timetable_period FOREIGN KEY (timetable_period_id) REFERENCES management_schema.timetable_period (timetable_period_id),
        CONSTRAINT FK_student_attendance_subject FOREIGN KEY (subject_id) REFERENCES management_schema.subject (subject_id),
        CONSTRAINT FK_student_attendance_teacher FOREIGN KEY (teacher_id) REFERENCES teachers_schema.teacher (teacher_id),
        CONSTRAINT FK_student_attendance_recorded_by FOREIGN KEY (recorded_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_attendance_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_attendance_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_student_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_student_date
        ON student_schema.student_attendance (student_id, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_student_year_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_student_year_date
        ON student_schema.student_attendance (student_id, academic_year_id, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_section_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_section_date
        ON student_schema.student_attendance
        (school_id, branch_id, class_id, section_id, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_section_period_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_section_period_date
        ON student_schema.student_attendance (section_id, attendance_date, period_number)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_teacher_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_teacher_date
        ON student_schema.student_attendance (teacher_id, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_status_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_status_date
        ON student_schema.student_attendance (attendance_status, attendance_date)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_attendance_timetable_period_date'
      AND object_id = OBJECT_ID(N'student_schema.student_attendance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_attendance_timetable_period_date
        ON student_schema.student_attendance (timetable_period_id, attendance_date)
        INCLUDE (student_id, attendance_status, section_id)
        WHERE is_active = 1;
END;
GO

