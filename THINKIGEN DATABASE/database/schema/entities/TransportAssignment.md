# Entity: student_schema.transport_assignment

## Purpose

Active transport arrangement for one student — which bus/route, pickup stop, drop stop, and estimated times.

**Student bus UI:** query `WHERE student_id = @me AND status = 'ACTIVE'` — only their route, not all branch buses.

## Academic hierarchy

`school_id` → `branch_id` → `academic_year_id` → `class_id` → `section_id` → `student_id`

## Key columns

| Column | Notes |
|--------|-------|
| vehicle_route_id | FK → route alignment (join vehicle + ordered stops) |
| pickup_route_stop_id | FK → `vehicle_route(branch_id, route_stop_id)` |
| drop_route_stop_id | FK → destination stop |
| estimated_pickup_time / estimated_drop_time | TIME for this student |
| effective_from / effective_to | Assignment validity |
| status | ACTIVE / INACTIVE |

## Live tracking

1. Resolve `vehicle_id` from `vehicle_route` via assignment.
2. Read **Redis** for live GPS/ETA for that vehicle.
3. Optional: `trip` + `trip_stop` for actual arrival at student's pickup stop.

## Finance

Transport fee amounts are **not** on this table — finance module stores fee only.
