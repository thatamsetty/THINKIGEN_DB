/* Module migration: 005_student.sql */
/*
    Migration: 004_student_master
    Purpose:   Student master identity, current academic placement, and guardians

    Design notes:
    - No student_enrollment table. When a security_schema.users row with user_type = STUDENT
      completes enrollment, one student_schema.student row is created with school/branch/
      academic_year/class/section placement. Class promotion/transfer updates this row.
    - No student_document SQL table. Document metadata lives in MongoDB; files in Blob Storage.
    - Student documents rule: .cursor/rules/24-student-documents-mongodb.mdc

    Rollback:
    - DROP TABLE student_schema.student_guardian;
    - DROP TABLE student_schema.student;
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student                                                     */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student
    (
        student_id             BIGINT          NOT NULL IDENTITY(1, 1),
        user_id                BIGINT          NULL,
        school_id              BIGINT          NOT NULL,
        branch_id              BIGINT          NOT NULL,
        academic_year_id       BIGINT          NOT NULL,
        class_id               BIGINT          NOT NULL,
        section_id             BIGINT          NOT NULL,
        admission_number       NVARCHAR(50)    NOT NULL,
        roll_number            NVARCHAR(30)    NULL,
        first_name             NVARCHAR(100)   NOT NULL,
        middle_name            NVARCHAR(100)   NULL,
        last_name              NVARCHAR(100)   NULL,
        date_of_birth          DATE            NOT NULL,
        gender                 NVARCHAR(30)    NOT NULL,
        blood_group            NVARCHAR(10)    NULL,
        nationality            NVARCHAR(100)   NULL,
        mother_tongue          NVARCHAR(100)   NULL,
        religion               NVARCHAR(100)   NULL,
        student_category       NVARCHAR(100)   NULL,
        admission_date         DATE            NOT NULL,
        student_status         NVARCHAR(30)    NOT NULL,
        status_effective_date  DATE            NULL,
        mobile_number          NVARCHAR(20)    NULL,
        email_address          NVARCHAR(254)   NULL,
        address_line_1         NVARCHAR(200)   NULL,
        address_line_2         NVARCHAR(200)   NULL,
        landmark               NVARCHAR(150)   NULL,
        city                   NVARCHAR(100)   NULL,
        district               NVARCHAR(100)   NULL,
        state                  NVARCHAR(100)   NULL,
        postal_code            NVARCHAR(20)    NULL,
        country                NVARCHAR(100)   NULL,
        is_active              BIT             NOT NULL CONSTRAINT DF_student_is_active DEFAULT (1),
        created_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_student_created_at DEFAULT (SYSUTCDATETIME()),
        created_by             BIGINT          NOT NULL,
        updated_at             DATETIME2(0)    NOT NULL CONSTRAINT DF_student_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by             BIGINT          NULL,
        row_version            ROWVERSION      NOT NULL,
        residency_type         NVARCHAR(20)    NOT NULL CONSTRAINT DF_student_residency_type DEFAULT (N'DAY_SCHOLAR'),
        CONSTRAINT PK_student PRIMARY KEY CLUSTERED (student_id),
        CONSTRAINT UQ_student_school_admission_number UNIQUE NONCLUSTERED (school_id, admission_number),
        CONSTRAINT UQ_student_user_id UNIQUE NONCLUSTERED (user_id),
        CONSTRAINT FK_student_user FOREIGN KEY (user_id) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_student_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_student_academic_year_scope FOREIGN KEY (school_id, academic_year_id) REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_student_class_scope FOREIGN KEY (school_id, class_id) REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_student_section_scope FOREIGN KEY (class_id, section_id) REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_student_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_academic_scope' AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_academic_scope
        ON student_schema.student (school_id, branch_id, academic_year_id, class_id, section_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_branch_status' AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_branch_status
        ON student_schema.student (branch_id, student_status, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_name' AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_name
        ON student_schema.student (last_name, first_name)
        INCLUDE (school_id, branch_id, class_id, section_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_roll_number' AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_roll_number
        ON student_schema.student (school_id, academic_year_id, class_id, section_id, roll_number)
        WHERE roll_number IS NOT NULL;
END;
GO

/* -------------------------------------------------------------------------- */
/* student_schema.student_guardian                                              */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.student_guardian', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.student_guardian
    (
        student_guardian_id     BIGINT          NOT NULL IDENTITY(1, 1),
        student_id              BIGINT          NOT NULL,
        guardian_name           NVARCHAR(200)   NOT NULL,
        relationship_type       NVARCHAR(50)    NOT NULL,
        mobile_number           NVARCHAR(20)    NULL,
        alternate_mobile_number NVARCHAR(20)    NULL,
        email_address           NVARCHAR(254)   NULL,
        occupation              NVARCHAR(150)   NULL,
        organization_name       NVARCHAR(200)   NULL,
        is_legal_guardian       BIT             NOT NULL CONSTRAINT DF_student_guardian_is_legal_guardian DEFAULT (0),
        is_primary_contact      BIT             NOT NULL CONSTRAINT DF_student_guardian_is_primary_contact DEFAULT (0),
        is_emergency_contact    BIT             NOT NULL CONSTRAINT DF_student_guardian_is_emergency_contact DEFAULT (0),
        is_pickup_authorized    BIT             NOT NULL CONSTRAINT DF_student_guardian_is_pickup_authorized DEFAULT (0),
        is_active               BIT             NOT NULL CONSTRAINT DF_student_guardian_is_active DEFAULT (1),
        created_at              DATETIME2(0)    NOT NULL CONSTRAINT DF_student_guardian_created_at DEFAULT (SYSUTCDATETIME()),
        created_by              BIGINT          NOT NULL,
        updated_at              DATETIME2(0)    NOT NULL CONSTRAINT DF_student_guardian_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by              BIGINT          NULL,
        row_version             ROWVERSION      NOT NULL,
        CONSTRAINT PK_student_guardian PRIMARY KEY CLUSTERED (student_guardian_id),
        CONSTRAINT FK_student_guardian_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_student_guardian_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_student_guardian_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_guardian_student' AND object_id = OBJECT_ID(N'student_schema.student_guardian')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_guardian_student
        ON student_schema.student_guardian (student_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_student_guardian_relationship' AND object_id = OBJECT_ID(N'student_schema.student_guardian')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_guardian_relationship
        ON student_schema.student_guardian (student_id, relationship_type)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_student_guardian_primary_contact'
      AND object_id = OBJECT_ID(N'student_schema.student_guardian')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_student_guardian_primary_contact
        ON student_schema.student_guardian (student_id)
        WHERE is_primary_contact = 1 AND is_active = 1;
END;
GO

/* -------------------------------------------------------------------------- */
/* student_schema.exam_result                                                 */
/* -------------------------------------------------------------------------- */

IF OBJECT_ID(N'student_schema.exam_result', N'U') IS NULL
BEGIN
    CREATE TABLE student_schema.exam_result
    (
        exam_result_id     BIGINT          NOT NULL IDENTITY(1, 1),
        exam_schedule_id   BIGINT          NOT NULL,
        school_id          BIGINT          NOT NULL,
        branch_id          BIGINT          NOT NULL,
        academic_year_id   BIGINT          NOT NULL,
        class_id           BIGINT          NOT NULL,
        section_id         BIGINT          NOT NULL,
        student_id         BIGINT          NOT NULL,
        marks_obtained     DECIMAL(6, 2)   NULL,
        result_status      NVARCHAR(20)    NOT NULL,
        grade              NVARCHAR(10)    NULL,
        rank_in_class      INT             NULL,
        remarks            NVARCHAR(500)   NULL,
        published_at       DATETIME2(0)    NULL,
        is_active          BIT             NOT NULL CONSTRAINT DF_exam_result_is_active DEFAULT (1),
        created_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_exam_result_created_at DEFAULT (SYSUTCDATETIME()),
        created_by         BIGINT          NOT NULL,
        updated_at         DATETIME2(0)    NOT NULL CONSTRAINT DF_exam_result_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by         BIGINT          NULL,
        row_version        ROWVERSION      NOT NULL,
        CONSTRAINT PK_exam_result PRIMARY KEY CLUSTERED (exam_result_id),
        CONSTRAINT UQ_exam_result_schedule_student UNIQUE NONCLUSTERED (exam_schedule_id, student_id),
        CONSTRAINT CK_exam_result_status CHECK
            (result_status IN (N'PASS', N'FAIL', N'ABSENT')),
        CONSTRAINT CK_exam_result_marks CHECK
            (marks_obtained IS NULL OR marks_obtained >= 0),
        CONSTRAINT CK_exam_result_absent_marks CHECK
            ((result_status = N'ABSENT' AND marks_obtained IS NULL)
             OR (result_status <> N'ABSENT')),
        CONSTRAINT CK_exam_result_rank CHECK
            (rank_in_class IS NULL OR rank_in_class > 0),
        CONSTRAINT FK_exam_result_exam_schedule FOREIGN KEY (exam_schedule_id) REFERENCES management_schema.exam_schedule (exam_schedule_id),
        CONSTRAINT FK_exam_result_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_exam_result_branch_scope FOREIGN KEY (school_id, branch_id) REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_exam_result_academic_year_scope FOREIGN KEY (school_id, academic_year_id) REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_exam_result_class_scope FOREIGN KEY (school_id, class_id) REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_exam_result_section_scope FOREIGN KEY (class_id, section_id) REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_exam_result_student FOREIGN KEY (student_id) REFERENCES student_schema.student (student_id),
        CONSTRAINT FK_exam_result_created_by FOREIGN KEY (created_by) REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_exam_result_updated_by FOREIGN KEY (updated_by) REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_result_student_scope'
      AND object_id = OBJECT_ID(N'student_schema.exam_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_result_student_scope
        ON student_schema.exam_result
        (school_id, branch_id, academic_year_id, class_id, section_id, student_id, is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_result_schedule_status'
      AND object_id = OBJECT_ID(N'student_schema.exam_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_result_schedule_status
        ON student_schema.exam_result (exam_schedule_id, result_status)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_exam_result_student_published'
      AND object_id = OBJECT_ID(N'student_schema.exam_result')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_exam_result_student_published
        ON student_schema.exam_result (student_id, published_at)
        WHERE published_at IS NOT NULL AND is_active = 1;
END;
GO

/* Scope composite unique keys (enable child composite FK enforcement across modules) */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_school_branch_student'
      AND object_id = OBJECT_ID(N'student_schema.student')
      AND (is_unique = 0 OR is_disabled = 1 OR has_filter = 1)
)
BEGIN
    DROP INDEX UQ_student_school_branch_student ON student_schema.student;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_school_branch_student'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_school_branch_student
        ON student_schema.student (school_id, branch_id, student_id);
END;
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_placement_scope'
      AND object_id = OBJECT_ID(N'student_schema.student')
      AND (is_unique = 0 OR is_disabled = 1 OR has_filter = 1)
)
BEGIN
    DROP INDEX UQ_student_placement_scope ON student_schema.student;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_placement_scope'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_placement_scope
        ON student_schema.student (school_id, branch_id, academic_year_id, class_id, section_id, student_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_student_id_placement_scope'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_student_id_placement_scope
        ON student_schema.student (student_id, school_id, branch_id, academic_year_id, class_id, section_id);
END;
GO


