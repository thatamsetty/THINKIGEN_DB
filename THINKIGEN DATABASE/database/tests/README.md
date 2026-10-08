# Database Tests

## 001_schema_integrity.sql

Post-migration checks (run via `migrations/000_run_all.sql`):

- Table count >= 51
- Admin user + credential seeded
- Scope composite indexes present
- Student composite scope FK present
- Refresh token table exists
- Login attempt table exists
- `schema_version` populated

Fails with `THROW` if any check fails.
