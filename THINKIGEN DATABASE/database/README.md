# Thinkigen Database

This directory is the controlled database contract for the Thinkigen School ERP.

## Primary technology

- SQL Server / Azure SQL is the current database technology.
- Local development is currently used for development and test work.
- The environment path is Local → Dev → Test → Staging → Production.
- The logical schema must remain consistent across environments.

## Database boundary

**One Organization = one dedicated database.**

There is no multi-Organization data model inside one database. Do not add an `organization_id` to every table merely for generic multi-tenancy.

The database itself is the Organization boundary.

## Canonical academic hierarchy

Organization database
→ School
→ Branch
→ Academic Year
→ Class
→ Section
→ Student

A school may have one or many branches. A school without operational branches still uses the approved branch representation so downstream relationships remain consistent.

## Core rules

- The database is a controlled contract.
- Cursor must implement exactly the requested change.
- Cursor must not redesign unrelated schema.
- Cursor must not invent business rules.
- Every schema change requires a migration.
- Applied migrations are immutable.
- Production schema is never changed directly.
- Historical data is preserved.
- PK/FK/UNIQUE/CHECK constraints are first-class integrity controls.
- Indexes are workload-driven.
- Security is least privilege + RBAC/ABAC at the application authorization boundary.
- Procedures/triggers/jobs are created only when explicitly requested or explicitly approved.
- Financial behavior beyond the currently approved baseline must be clarified before implementation.

## Cursor operating rule

Before changing anything:

1. Inspect the current implementation/schema.
2. Identify exactly what the user asked to change.
3. List affected objects.
4. Check existing objects before creating anything.
5. Identify security, data, compatibility, migration and performance impact.
6. Ask for clarification if a business rule is missing.
7. Make the smallest correct change.
8. Do not modify unrelated files.
9. Add/adjust tests.
10. Report what changed and what did not.

Never interpret "make it better" as permission to redesign the database.
