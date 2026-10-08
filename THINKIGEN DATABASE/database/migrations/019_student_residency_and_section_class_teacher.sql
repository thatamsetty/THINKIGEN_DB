/* Module migration: 019_student_residency_and_section_class_teacher.sql */
/*
    Purpose:
    - Classify each student as a hosteller or day scholar.
    - Store the class teacher assigned to each section for an academic year.

    Notes:
    - residency_type describes accommodation, not academic placement.
    - Existing students are initialized as DAY_SCHOLAR and should be corrected
      where applicable after deployment.
    - A section can have only one active class-teacher assignment per academic year.
*/

/* -------------------------------------------------------------------------- */
/* student_schema.student.residency_type                                      */
/* -------------------------------------------------------------------------- */

IF COL_LENGTH(N'student_schema.student', N'residency_type') IS NULL
BEGIN
    ALTER TABLE student_schema.student
        ADD residency_type NVARCHAR(20) NOT NULL
            CONSTRAINT DF_student_residency_type DEFAULT (N'DAY_SCHOLAR') WITH VALUES;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_student_residency_type'
      AND parent_object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    ALTER TABLE student_schema.student
        ADD CONSTRAINT CK_student_residency_type
            CHECK (residency_type IN (N'HOSTELLER', N'DAY_SCHOLAR'));
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_student_residency_type_active'
      AND object_id = OBJECT_ID(N'student_schema.student')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_student_residency_type_active
        ON student_schema.student (school_id, branch_id, residency_type, is_active)
        INCLUDE (student_id, first_name, last_name, admission_number);
END;
GO

/* -------------------------------------------------------------------------- */
/* teachers_schema.section_class_teacher_assignment                           */
/* -------------------------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UQ_teacher_school_branch_scope'
      AND object_id = OBJECT_ID(N'teachers_schema.teacher')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_teacher_school_branch_scope
        ON teachers_schema.teacher (school_id, branch_id, teacher_id);
END;
GO

IF OBJECT_ID(N'teachers_schema.section_class_teacher_assignment', N'U') IS NULL
BEGIN
    CREATE TABLE teachers_schema.section_class_teacher_assignment
    (
        section_class_teacher_assignment_id BIGINT       NOT NULL IDENTITY(1, 1),
        school_id                           BIGINT       NOT NULL,
        branch_id                           BIGINT       NOT NULL,
        academic_year_id                    BIGINT       NOT NULL,
        class_id                            BIGINT       NOT NULL,
        section_id                          BIGINT       NOT NULL,
        teacher_id                          BIGINT       NOT NULL,
        is_active                           BIT          NOT NULL CONSTRAINT DF_section_class_teacher_assignment_is_active DEFAULT (1),
        created_at                          DATETIME2(0) NOT NULL CONSTRAINT DF_section_class_teacher_assignment_created_at DEFAULT (SYSUTCDATETIME()),
        created_by                          BIGINT       NOT NULL,
        updated_at                          DATETIME2(0) NOT NULL CONSTRAINT DF_section_class_teacher_assignment_updated_at DEFAULT (SYSUTCDATETIME()),
        updated_by                          BIGINT       NULL,
        row_version                         ROWVERSION   NOT NULL,
        CONSTRAINT PK_section_class_teacher_assignment PRIMARY KEY CLUSTERED (section_class_teacher_assignment_id),
        CONSTRAINT FK_section_class_teacher_assignment_school FOREIGN KEY (school_id) REFERENCES management_schema.school (school_id),
        CONSTRAINT FK_section_class_teacher_assignment_branch_scope FOREIGN KEY (school_id, branch_id)
            REFERENCES management_schema.branch (school_id, branch_id),
        CONSTRAINT FK_section_class_teacher_assignment_academic_year_scope FOREIGN KEY (school_id, academic_year_id)
            REFERENCES management_schema.academic_year (school_id, academic_year_id),
        CONSTRAINT FK_section_class_teacher_assignment_class_scope FOREIGN KEY (school_id, class_id)
            REFERENCES management_schema.school_class (school_id, class_id),
        CONSTRAINT FK_section_class_teacher_assignment_section_scope FOREIGN KEY (class_id, section_id)
            REFERENCES management_schema.section (class_id, section_id),
        CONSTRAINT FK_section_class_teacher_assignment_teacher_scope FOREIGN KEY (school_id, branch_id, teacher_id)
            REFERENCES teachers_schema.teacher (school_id, branch_id, teacher_id),
        CONSTRAINT FK_section_class_teacher_assignment_created_by FOREIGN KEY (created_by)
            REFERENCES security_schema.users (user_id),
        CONSTRAINT FK_section_class_teacher_assignment_updated_by FOREIGN KEY (updated_by)
            REFERENCES security_schema.users (user_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_section_class_teacher_assignment_active_scope'
      AND object_id = OBJECT_ID(N'teachers_schema.section_class_teacher_assignment')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_section_class_teacher_assignment_active_scope
        ON teachers_schema.section_class_teacher_assignment
            (school_id, branch_id, academic_year_id, class_id, section_id)
        WHERE is_active = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_section_class_teacher_assignment_teacher_active'
      AND object_id = OBJECT_ID(N'teachers_schema.section_class_teacher_assignment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_section_class_teacher_assignment_teacher_active
        ON teachers_schema.section_class_teacher_assignment (teacher_id, is_active)
        INCLUDE (school_id, branch_id, academic_year_id, class_id, section_id);
END;
GO
