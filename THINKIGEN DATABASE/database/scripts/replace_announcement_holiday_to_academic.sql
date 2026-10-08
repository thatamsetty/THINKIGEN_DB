/*
    THINKIGEN ERP - Replace Announcement Holiday -> Academic
    Target: SQL Server / SSMS

    Purpose:
    1. Ensures CK_announcement_type constraint permits 'ACADEMIC'.
    2. Replaces announcement mock data (IDs 9990-9999), replacing HOLIDAY with ACADEMIC.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

/* 1. Ensure CK_announcement_type permits 'ACADEMIC' */
IF OBJECT_ID(N'management_schema.announcement', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_announcement_type'
          AND parent_object_id = OBJECT_ID(N'management_schema.announcement')
          AND definition LIKE N'%ACADEMIC%'
    )
    BEGIN
        IF EXISTS
        (
            SELECT 1
            FROM sys.check_constraints
            WHERE name = N'CK_announcement_type'
              AND parent_object_id = OBJECT_ID(N'management_schema.announcement')
        )
        BEGIN
            ALTER TABLE management_schema.announcement
                DROP CONSTRAINT CK_announcement_type;
        END;

        ALTER TABLE management_schema.announcement
            ADD CONSTRAINT CK_announcement_type
            CHECK (announcement_type IN (N'EVENT', N'ACADEMIC', N'HOLIDAY', N'NOTICE'));
    END;
END;
GO

/* 2. Upsert/Replace the 10 Mock Data Rows */
DELETE FROM management_schema.announcement
WHERE announcement_id BETWEEN 9990 AND 9999;

SET IDENTITY_INSERT management_schema.announcement ON;

INSERT INTO management_schema.announcement
(
    announcement_id,
    school_id,
    branch_id,
    academic_year_id,
    announcement_type,
    title,
    description,
    start_date,
    end_date,
    publish_at,
    status,
    is_active,
    created_at,
    created_by,
    updated_at,
    updated_by,
    registration_url
)
VALUES
(9990, 1, 1, 1, N'EVENT',    N'Academic Timetable Launch',    N'New academic timetable begins for all students.',                     '2026-09-10', '2026-09-10', '2026-09-10 08:00:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9991, 1, 1, 1, N'NOTICE',   N'Classroom Schedule Notice',    N'Students should check their classroom and period schedule.',          '2026-09-10', '2026-09-10', '2026-09-10 08:15:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9992, 1, 1, 1, N'ACADEMIC', N'Local Holiday',                N'School holiday announcement for students and staff.',                 '2026-09-11', '2026-09-11', '2026-09-10 08:30:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9993, 1, 1, 1, N'EVENT',    N'Student Orientation Session',  N'Orientation session for students regarding the new academic schedule.','2026-09-11', '2026-09-11', '2026-09-10 09:00:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9994, 1, 1, 1, N'NOTICE',   N'Period Timing Update',         N'Updated period timings are available for review.',                    '2026-09-12', '2026-09-12', '2026-09-10 09:30:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9995, 1, 1, 1, N'EVENT',    N'Academic Skills Workshop',     N'Students will attend an academic skills and study planning workshop.','2026-09-12', '2026-09-12', '2026-09-10 10:00:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9996, 1, 1, 1, N'ACADEMIC', N'School Maintenance Holiday',   N'School facilities will be unavailable during the maintenance holiday.','2026-09-13', '2026-09-13', '2026-09-10 10:30:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9997, 1, 1, 1, N'NOTICE',   N'Assignment Submission Reminder',N'Students should submit assignments according to the timetable schedule.', '2026-09-14', '2026-09-14', '2026-09-10 11:00:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9998, 1, 1, 1, N'EVENT',    N'Weekly Academic Review',       N'Teachers will review lessons, attendance, and student progress.',     '2026-09-14', '2026-09-14', '2026-09-10 11:30:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0'),
(9999, 1, 1, 1, N'ACADEMIC', N'Academic Calendar Holiday',     N'Holiday recorded in the academic calendar for the current session.',  '2026-09-15', '2026-09-15', '2026-09-10 12:00:00', N'PUBLISHED', 1, '2026-09-10 07:44:59', 73, '2026-09-10 07:44:59', 73, N'https://docs.google.com/spreadsheets/d/1L-B_JfTy5SYj5zrfYKLoa7IAVwqwYJZl57h8jGyL4qo/edit?gid=0#gid=0');

SET IDENTITY_INSERT management_schema.announcement OFF;

COMMIT TRANSACTION;
GO

/* Verification */
SELECT announcement_id, announcement_type, title, start_date, end_date, publish_at, status
FROM management_schema.announcement
WHERE announcement_id BETWEEN 9990 AND 9999
ORDER BY announcement_id ASC;
GO