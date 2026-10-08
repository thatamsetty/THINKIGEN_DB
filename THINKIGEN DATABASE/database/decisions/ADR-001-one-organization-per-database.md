# ADR-001 — One Organization Per Database

## Decision

One Organization has one dedicated SQL Server/Azure SQL database.

## Consequences

Database-level isolation is the Organization boundary. Generic multi-tenant row filtering is not the architecture.

No cross-Organization FK or normal application query is allowed.
