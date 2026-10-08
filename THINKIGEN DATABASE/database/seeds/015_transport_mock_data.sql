/*
    ================================================================================
    THINKIGEN ERP — Transport Module Mock Data Seeder
    ================================================================================
    File Path: database/seeds/015_transport_mock_data.sql
    Target Tables:
      1. transport_schema.vehicle
      2. transport_schema.staff
      3. transport_schema.vehicle_route
      4. transport_schema.vehicle_route_stop
      5. transport_schema.trip
      6. transport_schema.trip_stop
      7. transport_schema.speed_measurement
      8. student_schema.transport_assignment
      9. student_schema.transport_change_request

    Prerequisites:
      - Tables must be created by running: database/migrations/015_transport.sql
      - Base data: schools, branches, academic years, classes, sections, students,
        and users must already be present (e.g. from 002_THINKIGEN_REALISTIC_MOCK_DATA_V22.sql).

    Dataset Highlights:
      - 4 Vehicles (1 per branch)
      - 8 Staff (4 Drivers, 4 Attendants)
      - 8 Vehicle Routes (4 Pickup, 4 Drop)
      - 24 Route Stops (3 stops per route)
      - 8 Trips (4 IN_TRANSIT, 4 SCHEDULED) adhering to driver_type_enforcer & time constraints
      - 24 Operational Trip Stops (departed, arrived, pending)
      - 24 Speed Measurements (GPS telemetry tracking logs)
      - 24 Day-Scholar Transport Assignments (linked to live student IDs)
      - 4 Transport Change Requests (Pending, Approved, Rejected workflows)
    ================================================================================
*/

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Verify that the transport tables exist before attempting to seed data
IF OBJECT_ID(N'transport_schema.vehicle', N'U') IS NULL
   OR OBJECT_ID(N'transport_schema.staff', N'U') IS NULL
   OR OBJECT_ID(N'transport_schema.vehicle_route', N'U') IS NULL
   OR OBJECT_ID(N'transport_schema.vehicle_route_stop', N'U') IS NULL
   OR OBJECT_ID(N'transport_schema.trip', N'U') IS NULL
   OR OBJECT_ID(N'transport_schema.trip_stop', N'U') IS NULL
   OR OBJECT_ID(N'transport_schema.speed_measurement', N'U') IS NULL
   OR OBJECT_ID(N'student_schema.transport_assignment', N'U') IS NULL
   OR OBJECT_ID(N'student_schema.transport_change_request', N'U') IS NULL
BEGIN
    RAISERROR(N'Transport module tables are missing. Please execute database/migrations/015_transport.sql first before running this seeder.', 16, 1);
    RETURN;
END;
GO

PRINT N'Starting Transport Mock Data Seeding...';

BEGIN TRANSACTION;
BEGIN TRY

    /* -------------------------------------------------------------------------- */
    /* 0A. ALIGN MANAGEMENT USER EMAILS TO ''mgt'' FORMAT                           */
    /* -------------------------------------------------------------------------- */
    IF OBJECT_ID(N'security_schema.users', N'U') IS NOT NULL
    BEGIN
        UPDATE security_schema.users
        SET email_address = N'mgt001@thinkigen.test'
        WHERE user_id = 73 AND email_address <> N'mgt001@thinkigen.test';

        UPDATE security_schema.users
        SET email_address = N'mgt002@thinkigen.test'
        WHERE user_id = 74 AND email_address <> N'mgt002@thinkigen.test';
    END;

    /* -------------------------------------------------------------------------- */
    /* 0. CLEANUP EXISTING TRANSPORT DATA (Child-to-Parent Order)                 */
    /* -------------------------------------------------------------------------- */
    DELETE FROM student_schema.transport_change_request;
    DELETE FROM student_schema.transport_assignment;
    DELETE FROM transport_schema.speed_measurement;
    DELETE FROM transport_schema.trip_stop;
    DELETE FROM transport_schema.trip;
    DELETE FROM transport_schema.vehicle_route_stop;
    DELETE FROM transport_schema.vehicle_route;
    DELETE FROM transport_schema.staff;
    DELETE FROM transport_schema.vehicle;

    /* -------------------------------------------------------------------------- */
    /* 1. SEED: transport_schema.vehicle (4 Vehicles, 1 per Branch)               */
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT transport_schema.vehicle ON;
    INSERT INTO transport_schema.vehicle
      (vehicle_id, school_id, branch_id, vehicle_number, vehicle_name, capacity, status, vehicle_health, is_active, created_by)
    VALUES
      (1, 1, 1, N'TG-01-BUS-1001', N'Central Campus Bus 1', 40, N'ACTIVE', N'EXCELLENT',     1, 1),
      (2, 1, 2, N'TG-01-BUS-1002', N'North Campus Bus 2',   40, N'ACTIVE', N'GOOD',          1, 1),
      (3, 2, 3, N'TG-02-BUS-2001', N'City Campus Bus 3',    40, N'ACTIVE', N'GOOD',          1, 1),
      (4, 2, 4, N'TG-02-BUS-2002', N'Lake Campus Bus 4',    40, N'ACTIVE', N'NEEDS_SERVICE', 1, 1);
    SET IDENTITY_INSERT transport_schema.vehicle OFF;
    PRINT N'✔ Seeded transport_schema.vehicle (4 rows)';

    /* -------------------------------------------------------------------------- */
    /* 2. SEED: transport_schema.staff (8 Staff: 4 Drivers + 4 Attendants)        */
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT transport_schema.staff ON;
    INSERT INTO transport_schema.staff
      (staff_id, school_id, branch_id, user_id, staff_name, staff_type, experience, mobile_number, license_number,
       license_expiry_date, status, is_active, created_by)
    VALUES
      (1, 1, 1, 65, N'Ravi Kumar',   N'DRIVER',    10, N'919800000001', N'TS-DRV-1001', '2028-12-31', N'ACTIVE', 1, 1),
      (2, 1, 1, 66, N'Mohan Rao',    N'ATTENDANT',  4, N'919800000002', NULL,            NULL,         N'ACTIVE', 1, 1),
      (3, 1, 2, 67, N'Suresh Naidu', N'DRIVER',     8, N'919800000003', N'TS-DRV-1002', '2028-12-31', N'ACTIVE', 1, 1),
      (4, 1, 2, 68, N'Karthik Rao',  N'ATTENDANT',  3, N'919800000004', NULL,            NULL,         N'ACTIVE', 1, 1),
      (5, 2, 3, 69, N'Vijay Reddy',  N'DRIVER',    12, N'919800000005', N'TS-DRV-2001', '2028-12-31', N'ACTIVE', 1, 1),
      (6, 2, 3, 70, N'Imran Ali',    N'ATTENDANT',  5, N'919800000006', NULL,            NULL,         N'ACTIVE', 1, 1),
      (7, 2, 4, 71, N'Prakash Rao',  N'DRIVER',     7, N'919800000007', N'TS-DRV-2002', '2028-12-31', N'ACTIVE', 1, 1),
      (8, 2, 4, 72, N'Anil Kumar',   N'ATTENDANT',  2, N'919800000008', NULL,            NULL,         N'ACTIVE', 1, 1);
    SET IDENTITY_INSERT transport_schema.staff OFF;
    PRINT N'✔ Seeded transport_schema.staff (8 rows)';

    /* -------------------------------------------------------------------------- */
    /* 3. SEED: transport_schema.vehicle_route (8 Master Routes: 4 Pickup + 4 Drop)*/
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT transport_schema.vehicle_route ON;
    INSERT INTO transport_schema.vehicle_route
      (vehicle_route_id, school_id, branch_id, vehicle_id, route_code, route_name, route_type,
       status, effective_from, effective_to, is_active, created_by)
    VALUES
      (1, 1, 1, 1, N'BR1-PU', N'Central Morning Pickup', N'PICKUP', N'ACTIVE', '2026-04-01', NULL, 1, 1),
      (2, 1, 1, 1, N'BR1-DR', N'Central Afternoon Drop',  N'DROP',   N'ACTIVE', '2026-04-01', NULL, 1, 1),
      (3, 1, 2, 2, N'BR2-PU', N'North Morning Pickup',   N'PICKUP', N'ACTIVE', '2026-04-01', NULL, 1, 1),
      (4, 1, 2, 2, N'BR2-DR', N'North Afternoon Drop',    N'DROP',   N'ACTIVE', '2026-04-01', NULL, 1, 1),
      (5, 2, 3, 3, N'BR3-PU', N'City Morning Pickup',    N'PICKUP', N'ACTIVE', '2026-04-01', NULL, 1, 1),
      (6, 2, 3, 3, N'BR3-DR', N'City Afternoon Drop',     N'DROP',   N'ACTIVE', '2026-04-01', NULL, 1, 1),
      (7, 2, 4, 4, N'BR4-PU', N'Lake Morning Pickup',    N'PICKUP', N'ACTIVE', '2026-04-01', NULL, 1, 1),
      (8, 2, 4, 4, N'BR4-DR', N'Lake Afternoon Drop',     N'DROP',   N'ACTIVE', '2026-04-01', NULL, 1, 1);
    SET IDENTITY_INSERT transport_schema.vehicle_route OFF;
    PRINT N'✔ Seeded transport_schema.vehicle_route (8 master routes)';

    /* -------------------------------------------------------------------------- */
    /* 4. SEED: transport_schema.vehicle_route_stop (24 Stops: 3 Stops per Route) */
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT transport_schema.vehicle_route_stop ON;
    INSERT INTO transport_schema.vehicle_route_stop
      (route_stop_id, vehicle_route_id, stop_sequence, stop_name, stop_address,
       planned_arrival_time, planned_departure_time, is_active, created_by)
    VALUES
      -- Route 1: Branch 1 Morning Pickup
      (101, 1, 1, N'Central Park',       N'Central Park Road',   '07:10', '07:12', 1, 1),
      (102, 1, 2, N'Lake View',          N'Lake View Road',      '07:20', '07:22', 1, 1),
      (103, 1, 3, N'Central School Gate',N'Campus Main Gate',    '08:05', '08:10', 1, 1),

      -- Route 2: Branch 1 Afternoon Drop
      (104, 2, 1, N'Central School Gate',N'Campus Main Gate',    '15:10', '15:12', 1, 1),
      (105, 2, 2, N'Lake View',          N'Lake View Road',      '15:35', '15:37', 1, 1),
      (106, 2, 3, N'Central Park',       N'Central Park Road',   '15:45', '15:50', 1, 1),

      -- Route 3: Branch 2 Morning Pickup
      (201, 3, 1, N'North Square',       N'North Square Ring',   '07:10', '07:12', 1, 1),
      (202, 3, 2, N'Green Valley',       N'Valley Avenue',       '07:25', '07:27', 1, 1),
      (203, 3, 3, N'North School Gate',  N'Campus North Gate',   '08:05', '08:10', 1, 1),

      -- Route 4: Branch 2 Afternoon Drop
      (204, 4, 1, N'North School Gate',  N'Campus North Gate',   '15:10', '15:12', 1, 1),
      (205, 4, 2, N'Green Valley',       N'Valley Avenue',       '15:35', '15:37', 1, 1),
      (206, 4, 3, N'North Square',       N'North Square Ring',   '15:45', '15:50', 1, 1),

      -- Route 5: Branch 3 Morning Pickup
      (301, 5, 1, N'Metro Circle',       N'Metro Pillar 42',     '07:10', '07:12', 1, 1),
      (302, 5, 2, N'Riverdale',          N'Riverdale Cross',     '07:25', '07:27', 1, 1),
      (303, 5, 3, N'City School Gate',   N'City Campus Gate',    '08:05', '08:10', 1, 1),

      -- Route 6: Branch 3 Afternoon Drop
      (304, 6, 1, N'City School Gate',   N'City Campus Gate',    '15:10', '15:12', 1, 1),
      (305, 6, 2, N'Riverdale',          N'Riverdale Cross',     '15:35', '15:37', 1, 1),
      (306, 6, 3, N'Metro Circle',       N'Metro Pillar 42',     '15:45', '15:50', 1, 1),

      -- Route 7: Branch 4 Morning Pickup
      (401, 7, 1, N'Orchid Meadows',     N'Meadows Avenue',      '07:10', '07:12', 1, 1),
      (402, 7, 2, N'Hill Crest',         N'Crest Boulevard',     '07:25', '07:27', 1, 1),
      (403, 7, 3, N'Lake School Gate',   N'Lake Campus Gate',    '08:05', '08:10', 1, 1),

      -- Route 8: Branch 4 Afternoon Drop
      (404, 8, 1, N'Lake School Gate',   N'Lake Campus Gate',    '15:10', '15:12', 1, 1),
      (405, 8, 2, N'Hill Crest',         N'Crest Boulevard',     '15:35', '15:37', 1, 1),
      (406, 8, 3, N'Orchid Meadows',     N'Meadows Avenue',      '15:45', '15:50', 1, 1);
    SET IDENTITY_INSERT transport_schema.vehicle_route_stop OFF;
    PRINT N'✔ Seeded transport_schema.vehicle_route_stop (24 route stops)';

    /* -------------------------------------------------------------------------- */
    /* 5. SEED: transport_schema.trip (8 Trips: 4 IN_TRANSIT, 4 SCHEDULED)        */
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT transport_schema.trip ON;
    INSERT INTO transport_schema.trip
      (trip_id, school_id, branch_id, vehicle_id, vehicle_route_id, driver_id, driver_type_enforcer,
       trip_date, trip_type, planned_start_time, planned_destination_time, actual_start_at,
       actual_destination_at, delay_minutes, status, is_active, created_by)
    VALUES
      -- Branch 1
      (1, 1, 1, 1, 1, 1, N'DRIVER', '2026-09-01', N'PICKUP', '07:10', '08:10', '2026-09-01 07:10:00', NULL, 0, N'IN_TRANSIT', 1, 1),
      (2, 1, 1, 1, 2, 1, N'DRIVER', '2026-09-01', N'DROP',   '15:10', '16:00', NULL,                  NULL, NULL, N'SCHEDULED',  1, 1),

      -- Branch 2
      (3, 1, 2, 2, 3, 3, N'DRIVER', '2026-09-01', N'PICKUP', '07:10', '08:10', '2026-09-01 07:10:00', NULL, 0, N'IN_TRANSIT', 1, 1),
      (4, 1, 2, 2, 4, 3, N'DRIVER', '2026-09-01', N'DROP',   '15:10', '16:00', NULL,                  NULL, NULL, N'SCHEDULED',  1, 1),

      -- Branch 3
      (5, 2, 3, 3, 5, 5, N'DRIVER', '2026-09-01', N'PICKUP', '07:10', '08:10', '2026-09-01 07:10:00', NULL, 0, N'IN_TRANSIT', 1, 1),
      (6, 2, 3, 3, 6, 5, N'DRIVER', '2026-09-01', N'DROP',   '15:10', '16:00', NULL,                  NULL, NULL, N'SCHEDULED',  1, 1),

      -- Branch 4
      (7, 2, 4, 4, 7, 7, N'DRIVER', '2026-09-01', N'PICKUP', '07:10', '08:10', '2026-09-01 07:10:00', NULL, 0, N'IN_TRANSIT', 1, 1),
      (8, 2, 4, 4, 8, 7, N'DRIVER', '2026-09-01', N'DROP',   '15:10', '16:00', NULL,                  NULL, NULL, N'SCHEDULED',  1, 1);
    SET IDENTITY_INSERT transport_schema.trip OFF;
    PRINT N'✔ Seeded transport_schema.trip (8 trips)';

    /* -------------------------------------------------------------------------- */
    /* 6. SEED: transport_schema.trip_stop (24 Operational Trip Stops)            */
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT transport_schema.trip_stop ON;
    INSERT INTO transport_schema.trip_stop
      (trip_stop_id, trip_id, vehicle_route_id, route_stop_id, stop_sequence,
       planned_arrival_at, actual_arrival_at, actual_departure_at, delay_minutes, status)
    VALUES
      -- Trip 1 (Pickup, In-Transit: Stop 1 departed, Stop 2 arrived, Stop 3 pending)
      (1, 1, 1, 101, 1, '2026-09-01 07:10:00', '2026-09-01 07:11:00', '2026-09-01 07:13:00', 1,    N'DEPARTED'),
      (2, 1, 1, 102, 2, '2026-09-01 07:20:00', '2026-09-01 07:21:00', NULL,                  1,    N'ARRIVED'),
      (3, 1, 1, 103, 3, '2026-09-01 08:05:00', NULL,                  NULL,                  NULL, N'PENDING'),

      -- Trip 2 (Drop, Scheduled)
      (4, 2, 2, 104, 1, '2026-09-01 15:10:00', NULL,                  NULL,                  NULL, N'PENDING'),
      (5, 2, 2, 105, 2, '2026-09-01 15:35:00', NULL,                  NULL,                  NULL, N'PENDING'),
      (6, 2, 2, 106, 3, '2026-09-01 15:45:00', NULL,                  NULL,                  NULL, N'PENDING'),

      -- Trip 3 (Pickup, In-Transit)
      (7, 3, 3, 201, 1, '2026-09-01 07:10:00', '2026-09-01 07:10:00', '2026-09-01 07:12:00', 0,    N'DEPARTED'),
      (8, 3, 3, 202, 2, '2026-09-01 07:25:00', '2026-09-01 07:26:00', NULL,                  1,    N'ARRIVED'),
      (9, 3, 3, 203, 3, '2026-09-01 08:05:00', NULL,                  NULL,                  NULL, N'PENDING'),

      -- Trip 4 (Drop, Scheduled)
      (10, 4, 4, 204, 1, '2026-09-01 15:10:00', NULL,                 NULL,                  NULL, N'PENDING'),
      (11, 4, 4, 205, 2, '2026-09-01 15:35:00', NULL,                 NULL,                  NULL, N'PENDING'),
      (12, 4, 4, 206, 3, '2026-09-01 15:45:00', NULL,                 NULL,                  NULL, N'PENDING'),

      -- Trip 5 (Pickup, In-Transit)
      (13, 5, 5, 301, 1, '2026-09-01 07:10:00', '2026-09-01 07:12:00', '2026-09-01 07:14:00', 2,    N'DEPARTED'),
      (14, 5, 5, 302, 2, '2026-09-01 07:25:00', '2026-09-01 07:24:00', NULL,                 0,    N'ARRIVED'),
      (15, 5, 5, 303, 3, '2026-09-01 08:05:00', NULL,                 NULL,                  NULL, N'PENDING'),

      -- Trip 6 (Drop, Scheduled)
      (16, 6, 6, 304, 1, '2026-09-01 15:10:00', NULL,                 NULL,                  NULL, N'PENDING'),
      (17, 6, 6, 305, 2, '2026-09-01 15:35:00', NULL,                 NULL,                  NULL, N'PENDING'),
      (18, 6, 6, 306, 3, '2026-09-01 15:45:00', NULL,                 NULL,                  NULL, N'PENDING'),

      -- Trip 7 (Pickup, In-Transit)
      (19, 7, 7, 401, 1, '2026-09-01 07:10:00', '2026-09-01 07:11:00', '2026-09-01 07:13:00', 1,    N'DEPARTED'),
      (20, 7, 7, 402, 2, '2026-09-01 07:25:00', '2026-09-01 07:25:00', NULL,                  0,    N'ARRIVED'),
      (21, 7, 7, 403, 3, '2026-09-01 08:05:00', NULL,                 NULL,                  NULL, N'PENDING'),

      -- Trip 8 (Drop, Scheduled)
      (22, 8, 8, 404, 1, '2026-09-01 15:10:00', NULL,                 NULL,                  NULL, N'PENDING'),
      (23, 8, 8, 405, 2, '2026-09-01 15:35:00', NULL,                 NULL,                  NULL, N'PENDING'),
      (24, 8, 8, 406, 3, '2026-09-01 15:45:00', NULL,                 NULL,                  NULL, N'PENDING');
    SET IDENTITY_INSERT transport_schema.trip_stop OFF;
    PRINT N'✔ Seeded transport_schema.trip_stop (24 trip stops)';

    /* -------------------------------------------------------------------------- */
    /* 7. SEED: transport_schema.speed_measurement (24 Telemetry Records)         */
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT transport_schema.speed_measurement ON;
    INSERT INTO transport_schema.speed_measurement
      (speed_measurement_id, trip_id, vehicle_id, recorded_at, speed_kmh)
    SELECT
      ts.trip_stop_id,
      ts.trip_id,
      t.vehicle_id,
      COALESCE(ts.actual_arrival_at, ts.planned_arrival_at),
      CAST(20.0 + ((ts.trip_stop_id * 7) % 25) + ((ts.trip_stop_id * 3) % 10) * 0.5 AS DECIMAL(6, 2))
    FROM transport_schema.trip_stop ts
    INNER JOIN transport_schema.trip t
      ON t.trip_id = ts.trip_id;
    SET IDENTITY_INSERT transport_schema.speed_measurement OFF;
    PRINT N'✔ Seeded transport_schema.speed_measurement (24 speed measurements)';

    /* -------------------------------------------------------------------------- */
    /* 8. SEED: student_schema.transport_assignment (24 Active Day Scholars)      */
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT student_schema.transport_assignment ON;
    INSERT INTO student_schema.transport_assignment
      (transport_assignment_id, school_id, branch_id, academic_year_id, class_id, section_id,
       student_id, vehicle_route_id, pickup_route_stop_id, drop_route_stop_id,
       estimated_pickup_time, estimated_drop_time, effective_from, effective_to,
       status, is_active, created_by)
    SELECT
      ROW_NUMBER() OVER (ORDER BY st.student_id) AS transport_assignment_id,
      st.school_id,
      st.branch_id,
      st.academic_year_id,
      st.class_id,
      st.section_id,
      st.student_id,
      -- Branch 1 -> Route 1 (BR1-PU), Branch 2 -> Route 3 (BR2-PU), Branch 3 -> Route 5 (BR3-PU), Branch 4 -> Route 7 (BR4-PU)
      CASE st.branch_id
        WHEN 1 THEN 1
        WHEN 2 THEN 3
        WHEN 3 THEN 5
        ELSE 7
      END AS vehicle_route_id,
      -- Pickup stop (Stop 1 or Stop 2 on that pickup route)
      CASE st.branch_id
        WHEN 1 THEN CASE WHEN st.student_id % 2 = 1 THEN 101 ELSE 102 END
        WHEN 2 THEN CASE WHEN st.student_id % 2 = 1 THEN 201 ELSE 202 END
        WHEN 3 THEN CASE WHEN st.student_id % 2 = 1 THEN 301 ELSE 302 END
        ELSE        CASE WHEN st.student_id % 2 = 1 THEN 401 ELSE 402 END
      END AS pickup_route_stop_id,
      -- Drop stop at School Gate (Stop 3 on that same pickup route)
      CASE st.branch_id
        WHEN 1 THEN 103
        WHEN 2 THEN 203
        WHEN 3 THEN 303
        ELSE 403
      END AS drop_route_stop_id,
      '07:15',
      '08:05',
      '2026-04-01',
      NULL,
      N'ACTIVE',
      1,
      1
    FROM student_schema.student st
    WHERE st.residency_type = N'DAY_SCHOLAR';
    SET IDENTITY_INSERT student_schema.transport_assignment OFF;
    PRINT N'✔ Seeded student_schema.transport_assignment (24 active assignments)';

    /* -------------------------------------------------------------------------- */
    /* 9. SEED: student_schema.transport_change_request (Sample Change Requests)  */
    /* -------------------------------------------------------------------------- */
    SET IDENTITY_INSERT student_schema.transport_change_request ON;
    INSERT INTO student_schema.transport_change_request
      (transport_change_request_id, transport_assignment_id, school_id, branch_id, student_id, request_type,
       current_vehicle_route_id, requested_vehicle_route_id, current_pickup_stop_id, requested_pickup_stop_id,
       current_drop_stop_id, requested_drop_stop_id, effective_date, return_date, reason, status,
       reviewed_by, reviewed_at, is_active, created_by)
    SELECT
      r.req_id,
      ta.transport_assignment_id,
      ta.school_id,
      ta.branch_id,
      ta.student_id,
      r.request_type,
      ta.vehicle_route_id,
      ta.vehicle_route_id,
      ta.pickup_route_stop_id,
      r.requested_pickup_stop_id,
      ta.drop_route_stop_id,
      ta.drop_route_stop_id,
      r.effective_date,
      r.return_date,
      r.reason,
      r.status,
      CASE
        WHEN r.reviewed_by = 73 AND NOT EXISTS (SELECT 1 FROM security_schema.users WHERE user_id = 73) THEN 1
        ELSE r.reviewed_by
      END AS reviewed_by,
      r.reviewed_at,
      1,
      COALESCE((SELECT u.user_id FROM security_schema.users u WHERE u.user_id = 2 * ta.student_id - 1), 1) AS created_by
    FROM (
      VALUES
        (1, 1, N'PERMANENT', 102, '2026-09-05', CAST(NULL AS DATE), N'Family moved closer to Lake View stop.', N'PENDING',  CAST(NULL AS BIGINT), CAST(NULL AS DATETIME2(0))),
        (2, 4, N'TEMPORARY', 202, '2026-09-06', CAST('2026-09-12' AS DATE), N'Temporary stay at alternate pickup location.', N'APPROVED', CAST(73 AS BIGINT), CAST('2026-09-01T10:00:00' AS DATETIME2(0))),
        (3, 7, N'PERMANENT', 302, '2026-09-08', CAST(NULL AS DATE), N'New residential pickup point requested.', N'REJECTED',  CAST(73 AS BIGINT), CAST('2026-09-01T11:00:00' AS DATETIME2(0))),
        (4, 10, N'TEMPORARY', 402, '2026-09-10', CAST('2026-09-17' AS DATE), N'Family travel arrangement.', N'PENDING',   CAST(NULL AS BIGINT), CAST(NULL AS DATETIME2(0)))
    ) AS r(req_id, assignment_id, request_type, requested_pickup_stop_id, effective_date, return_date, reason, status, reviewed_by, reviewed_at)
    INNER JOIN student_schema.transport_assignment ta
      ON ta.transport_assignment_id = r.assignment_id;
    SET IDENTITY_INSERT student_schema.transport_change_request OFF;
    PRINT N'✔ Seeded student_schema.transport_change_request (4 requests)';

    COMMIT TRANSACTION;
    PRINT N'=================================================================';
    PRINT N'Transport Mock Data Seeding Completed Successfully!';
    PRINT N'=================================================================';

    -- Display seeded row counts
    SELECT 'transport_schema.vehicle' AS entity_name, COUNT(*) AS row_count FROM transport_schema.vehicle
    UNION ALL
    SELECT 'transport_schema.staff', COUNT(*) FROM transport_schema.staff
    UNION ALL
    SELECT 'transport_schema.vehicle_route', COUNT(*) FROM transport_schema.vehicle_route
    UNION ALL
    SELECT 'transport_schema.vehicle_route_stop', COUNT(*) FROM transport_schema.vehicle_route_stop
    UNION ALL
    SELECT 'transport_schema.trip', COUNT(*) FROM transport_schema.trip
    UNION ALL
    SELECT 'transport_schema.trip_stop', COUNT(*) FROM transport_schema.trip_stop
    UNION ALL
    SELECT 'transport_schema.speed_measurement', COUNT(*) FROM transport_schema.speed_measurement
    UNION ALL
    SELECT 'student_schema.transport_assignment', COUNT(*) FROM student_schema.transport_assignment
    UNION ALL
    SELECT 'student_schema.transport_change_request', COUNT(*) FROM student_schema.transport_change_request;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'Error occurred during Transport Mock Data Seeding:';
    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;
GO
