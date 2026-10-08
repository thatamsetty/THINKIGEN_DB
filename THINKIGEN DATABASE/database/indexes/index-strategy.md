# Thinkigen Index Strategy

## Objective

Provide predictable SQL Server/Azure SQL performance without unnecessary write cost.

## Index design process

For every new/changed query:

1. Identify exact predicates.
2. Identify JOIN keys.
3. Identify ORDER BY/GROUP BY.
4. Identify expected cardinality.
5. Inspect existing indexes.
6. Check whether PK/UNIQUE/FK indexes already satisfy the access path.
7. Design the smallest useful index.
8. Consider INCLUDE columns only for a validated covering need.
9. Measure before/after.
10. Remove redundant indexes when evidence supports removal.

## ERP access patterns

Review indexes around:
- School + Academic Year + Branch
- Class + Section
- Student identifiers
- Teacher assignments
- Attendance
- Marks/grades
- Timetable
- Fee records
- Receipt transactions

Do not blindly create one giant `(organization, school, branch, academic_year, class, section, student)` index on every table.

The correct key order is determined by actual predicates and cardinality.

## Hard rules

- Every index must have a reason.
- No duplicate/near-duplicate index without justification.
- Foreign-key indexing is workload-driven.
- UNIQUE constraints should provide the required uniqueness enforcement.
- Avoid excessive indexes on high-write tables.
- Validate with actual execution plans and representative data.
- Do not use NOLOCK as a generic performance solution.
- Missing-index DMV output is advisory only.
