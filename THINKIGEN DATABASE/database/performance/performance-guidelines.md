# Performance Guidelines

## Query quality

Prefer:
- SARGable predicates
- explicit datatypes
- parameterized SQL
- set-based operations
- appropriate pagination
- narrow projections

Avoid:
- SELECT *
- implicit conversions
- functions around indexed filter columns when avoidable
- unnecessary DISTINCT
- unbounded result sets
- N+1 database access
- long transactions
- cursor-based row processing unless explicitly justified

## Evidence

Performance optimization requires measurable evidence:
- duration
- CPU
- logical reads
- row count
- actual execution plan
- representative data volume

Do not claim a query is optimized because it "looks faster".
