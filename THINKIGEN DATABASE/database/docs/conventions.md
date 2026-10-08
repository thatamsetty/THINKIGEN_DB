# SQL Conventions

## Datatypes

Use the smallest safe datatype.

- money: DECIMAL with approved precision/scale;
- booleans: BIT;
- timestamps: `DATETIME2(0)` for instants (UTC storage; API format `YYYY-MM-DDTHH:mm:ss`);
- dates: `DATE` (API format `YYYY-MM-DD`);
- times: `TIME(0)` 24-hour (API format `HH:mm:ss`);
- text: controlled VARCHAR/NVARCHAR length;
- identifiers: approved key datatype;
- rowversion: only on approved mutable tables.

## Constraints

Prefer database-enforced invariants:
- PK
- FK
- UNIQUE
- CHECK
- NOT NULL

## SQL

- explicit column lists;
- explicit joins;
- parameterized predicates;
- no SELECT * in production;
- no implicit conversions;
- no unsafe dynamic SQL.
