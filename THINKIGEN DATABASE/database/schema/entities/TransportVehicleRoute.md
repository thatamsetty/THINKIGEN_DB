# Entity: transport_schema.vehicle_route

## Purpose

Transport master alignment: **one row per stop** on a vehicle route (PICKUP or DROP).

Defines: Vehicle → Route → ordered stops → planned times.

No separate `route` or `route_stop` master tables.

## Key columns

| Column | Notes |
|--------|-------|
| vehicle_id | FK → vehicle |
| route_code, route_name | Route identity |
| route_type | PICKUP / DROP |
| route_stop_id | Stable stop id within branch — UNIQUE with branch_id |
| stop_sequence | 1, 2, 3… order |
| stop_name, stop_address | Stop display |
| planned_arrival_time, planned_departure_time | Planned schedule |
| effective_from, effective_to | Alignment validity |

## Redis

Live coordinates and ETA are **not** stored here — Redis only.
