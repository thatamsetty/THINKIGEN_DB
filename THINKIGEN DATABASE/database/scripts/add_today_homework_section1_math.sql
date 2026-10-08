/*
================================================================================
SCRIPT:        add_today_homework_section1_math.sql
MODULE:        teachers_schema.homework & student_schema.homework_status
PURPOSE:       Insert one homework record with TODAY's date and exact academic
               scope mappings for:
                 - school_id  = 1
                 - branch_id  = 1
                 - class_id   = 1
                 - section_id = 1
                 - subject_id = 2 (Mathematics)
               And generate corresponding per-student submission tracking rows
               in student_schema.homework_status for all active students in Section 1.
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'================================================================================';
PRINT N'Adding Today''s Homework for Subject 2 (Mathematics) - Class 1, Section 1...';
PRINT N'================================================================================';

BEGIN TRANSACTION;

BEGIN TRY

    /* -------------------------------------------------------------------------- */
    /* 1. CONFIGURATION & EXACT SCOPE PARAMETERS                                  */
    /* -------------------------------------------------------------------------- */
    DECLARE @SchoolId       BIGINT       = 1;
    DECLARE @BranchId       BIGINT       = 1;
    DECLARE @ClassId        BIGINT       = 1;
    DECLARE @SectionId      BIGINT       = 1;
    DECLARE @SubjectId      BIGINT       = 2; -- Mathematics
    DECLARE @HomeworkType   NVARCHAR(50) = N'HOMEWORK';
    DECLARE @PriorityLevel  NVARCHAR(20) = N'MEDIUM';
    DECLARE @Status         NVARCHAR(20) = N'PUBLISHED';
    DECLARE @EstimatedMins  INT          = 45;

    DECLARE @Title          NVARCHAR(200) = N'Mathematics - Daily Practice: Linear Equations & Algebra Review';
    DECLARE @Description    NVARCHAR(MAX) = N'Complete Exercise 3.2, Questions 1 through 10 in your Mathematics homework notebook. Show all intermediate factorization steps and algebraic verification.';

    /* -------------------------------------------------------------------------- */
    /* 2. DATE DEFINITION (TODAY''S DATE)                                         */
    /* -------------------------------------------------------------------------- */
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    -- Assigned today at 09:00:00 UTC
    DECLARE @AssignedAt  DATETIME2(0) = DATEADD(HOUR, 9, CAST(@Today AS DATETIME2(0)));
    -- Deadline today at 18:00:00 UTC (satisfies deadline_at >= assigned_at)
    DECLARE @DeadlineAt  DATETIME2(0) = DATEADD(HOUR, 18, CAST(@Today AS DATETIME2(0)));
    -- Published at matches assigned_at when status is PUBLISHED
    DECLARE @PublishedAt DATETIME2(0) = @AssignedAt;

    /* -------------------------------------------------------------------------- */
    /* 3. SCOPE & REFERENTIAL INTEGRITY VALIDATION                                */
    /* -------------------------------------------------------------------------- */
    -- A. Validate School
    IF NOT EXISTS (SELECT 1 FROM management_schema.school WHERE school_id = @SchoolId AND is_active = 1)
        THROW 50001, N'Specified school_id does not exist or is inactive.', 1;

    -- B. Validate Branch
    IF NOT EXISTS (SELECT 1 FROM management_schema.branch WHERE branch_id = @BranchId AND school_id = @SchoolId AND is_active = 1)
        THROW 50002, N'Specified branch_id does not belong to school_id = 1 or is inactive.', 1;

    -- C. Validate Class
    IF NOT EXISTS (SELECT 1 FROM management_schema.school_class WHERE class_id = @ClassId AND school_id = @SchoolId AND is_active = 1)
        THROW 50003, N'Specified class_id does not belong to school_id = 1 or is inactive.', 1;

    -- D. Validate Section
    IF NOT EXISTS (SELECT 1 FROM management_schema.section WHERE section_id = @SectionId AND class_id = @ClassId AND is_active = 1)
        THROW 50004, N'Specified section_id does not belong to class_id = 1 or is inactive.', 1;

    -- E. Validate Subject
    IF NOT EXISTS (SELECT 1 FROM management_schema.subject WHERE subject_id = @SubjectId AND school_id = @SchoolId AND is_active = 1)
        THROW 50005, N'Specified subject_id does not belong to school_id = 1 or is inactive.', 1;

    -- F. Resolve Active Academic Year
    DECLARE @AcademicYearId BIGINT;
    SELECT TOP 1 @AcademicYearId = academic_year_id
    FROM management_schema.academic_year
    WHERE school_id = @SchoolId AND is_current = 1;

    IF @AcademicYearId IS NULL
        SELECT TOP 1 @AcademicYearId = academic_year_id
        FROM management_schema.academic_year
        WHERE school_id = @SchoolId AND is_active = 1
        ORDER BY academic_year_id DESC;

    IF @AcademicYearId IS NULL SET @AcademicYearId = 1;

    -- G. Resolve Assigned Subject Teacher for Class 1, Section 1, Subject 2
    DECLARE @TeacherId BIGINT;
    SELECT TOP 1 @TeacherId = teacher_id
    FROM teachers_schema.teacher_subject_assignment
    WHERE section_id = @SectionId
      AND subject_id = @SubjectId
      AND is_active = 1;

    IF @TeacherId IS NULL
    BEGIN
        SELECT TOP 1 @TeacherId = teacher_id
        FROM teachers_schema.teacher
        WHERE school_id = @SchoolId AND branch_id = @BranchId AND is_active = 1
        ORDER BY teacher_id ASC;
    END;

    IF @TeacherId IS NULL SET @TeacherId = 2;

    -- H. Resolve Audit User (Teacher user account or Admin)
    DECLARE @CreatedBy BIGINT;
    SELECT @CreatedBy = user_id
    FROM teachers_schema.teacher
    WHERE teacher_id = @TeacherId;

    IF @CreatedBy IS NULL
    BEGIN
        SELECT TOP 1 @CreatedBy = user_id
        FROM security_schema.users
        WHERE user_type = N'ADMIN' AND is_active = 1
        ORDER BY user_id ASC;
    END;

    IF @CreatedBy IS NULL SET @CreatedBy = 1;

    PRINT CONCAT(N'Resolved Scope Context: Academic Year = ', @AcademicYearId, 
                 N', Teacher ID = ', @TeacherId, 
                 N', User ID = ', @CreatedBy,
                 N', Assigned = ', CONVERT(NVARCHAR(30), @AssignedAt, 120),
                 N', Deadline = ', CONVERT(NVARCHAR(30), @DeadlineAt, 120));

    /* -------------------------------------------------------------------------- */
    /* 4. INSERT HOMEWORK MASTER (teachers_schema.homework)                       */
    /* -------------------------------------------------------------------------- */
    DECLARE @InsertedHomework TABLE (homework_id BIGINT);

    INSERT INTO teachers_schema.homework
    (
        school_id,
        academic_year_id,
        branch_id,
        class_id,
        section_id,
        subject_id,
        teacher_id,
        homework_type,
        title,
        description,
        priority_level,
        assigned_at,
        deadline_at,
        status,
        estimated_minutes,
        published_at,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    OUTPUT INSERTED.homework_id INTO @InsertedHomework(homework_id)
    VALUES
    (
        @SchoolId,
        @AcademicYearId,
        @BranchId,
        @ClassId,
        @SectionId,
        @SubjectId,
        @TeacherId,
        @HomeworkType,
        @Title,
        @Description,
        @PriorityLevel,
        @AssignedAt,
        @DeadlineAt,
        @Status,
        @EstimatedMins,
        @PublishedAt,
        1,                  -- is_active
        SYSUTCDATETIME(),   -- created_at
        @CreatedBy,         -- created_by
        SYSUTCDATETIME(),   -- updated_at
        @CreatedBy          -- updated_by
    );

    DECLARE @NewHomeworkId BIGINT;
    SELECT TOP 1 @NewHomeworkId = homework_id FROM @InsertedHomework;

    PRINT CONCAT(N'✔ Successfully created homework in teachers_schema.homework. homework_id: ', @NewHomeworkId);

    /* -------------------------------------------------------------------------- */
    /* 5. INSERT PER-STUDENT STATUS ROWS (student_schema.homework_status)         */
    /* -------------------------------------------------------------------------- */
    INSERT INTO student_schema.homework_status
    (
        homework_id,
        school_id,
        branch_id,
        academic_year_id,
        class_id,
        section_id,
        student_id,
        submission_status,
        submitted_at,
        submission_timing,
        remarks,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    SELECT
        @NewHomeworkId,
        @SchoolId,
        @BranchId,
        @AcademicYearId,
        @ClassId,
        @SectionId,
        st.student_id,
        N'NOT_SUBMITTED'                AS submission_status,
        NULL                            AS submitted_at,
        NULL                            AS submission_timing,
        N'Pending student submission'   AS remarks,
        1                               AS is_active,
        SYSUTCDATETIME()                AS created_at,
        @CreatedBy                      AS created_by,
        SYSUTCDATETIME()                AS updated_at,
        @CreatedBy                      AS updated_by
    FROM student_schema.student st
    WHERE st.section_id = @SectionId
      AND st.is_active = 1
      AND NOT EXISTS (
          SELECT 1 
          FROM student_schema.homework_status existing
          WHERE existing.homework_id = @NewHomeworkId
            AND existing.student_id = st.student_id
      );

    DECLARE @StatusCount INT = @@ROWCOUNT;
    PRINT CONCAT(N'✔ Seeded student submission records in student_schema.homework_status. Students mapped: ', @StatusCount);

    COMMIT TRANSACTION;
    PRINT N'================================================================================';
    PRINT N'Transaction committed successfully!';
    PRINT N'================================================================================';

    /* -------------------------------------------------------------------------- */
    /* 6. VERIFICATION QUERIES                                                    */
    /* -------------------------------------------------------------------------- */
    -- A. Verified Homework Master Record
    SELECT
        h.homework_id,
        sch.school_name,
        br.branch_name,
        cls.class_name,
        sec.section_name,
        sub.subject_code,
        sub.subject_name,
        CONCAT(tchr.first_name, N' ', tchr.last_name) AS assigned_teacher,
        h.homework_type,
        h.title,
        h.priority_level,
        h.assigned_at,
        h.deadline_at,
        h.status,
        h.estimated_minutes,
        h.published_at,
        h.created_at
    FROM teachers_schema.homework h
    INNER JOIN management_schema.school sch         ON sch.school_id = h.school_id
    INNER JOIN management_schema.branch br          ON br.branch_id = h.branch_id
    INNER JOIN management_schema.school_class cls   ON cls.class_id = h.class_id
    INNER JOIN management_schema.section sec        ON sec.section_id = h.section_id
    INNER JOIN management_schema.subject sub        ON sub.subject_id = h.subject_id
    LEFT  JOIN teachers_schema.teacher tchr         ON tchr.teacher_id = h.teacher_id
    WHERE h.homework_id = @NewHomeworkId;

    -- B. Verified Student Homework Status Records
    SELECT
        hs.homework_status_id,
        hs.homework_id,
        hs.student_id,
        st.admission_number,
        st.roll_number,
        CONCAT(st.first_name, N' ', st.last_name) AS student_name,
        hs.submission_status,
        hs.submitted_at,
        hs.submission_timing,
        hs.remarks,
        hs.is_active
    FROM student_schema.homework_status hs
    INNER JOIN student_schema.student st ON st.student_id = hs.student_id
    WHERE hs.homework_id = @NewHomeworkId
    ORDER BY st.student_id ASC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT           = ERROR_SEVERITY();
    DECLARE @ErrorState    INT           = ERROR_STATE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
