# ADR-005 — Selective Rowversion

Use SQL Server rowversion on important mutable transactional/configuration tables where concurrent updates can cause lost data.

Do not apply it to every table.
