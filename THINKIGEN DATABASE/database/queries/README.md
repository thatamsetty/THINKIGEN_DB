# Query Governance

Queries must:
- use explicit column lists;
- use parameterized inputs;
- use explicit JOINs;
- enforce authorized scope;
- avoid SELECT *;
- avoid accidental Cartesian joins;
- avoid implicit conversions;
- avoid unnecessary row-by-row processing.

Common, analytics and report queries must remain separated by purpose.
