# Thinkigen Relationship Rules

## Required relationship behavior

1. Every FK must point to an existing approved parent entity.
2. Child rows must never reference a different logical school/academic context unless the business rule explicitly permits it.
3. Cross-Organization relationships do not exist.
4. Delete behavior must be explicit.
5. Do not use CASCADE DELETE on historical/transactional structures without explicit approval.
6. Historical records must remain resolvable after current placement changes.
7. Composite relationships must enforce the correct scope where a child can otherwise reference a valid but wrong parent from another school/branch/year.

## Student placement

The active student placement must be unique according to the approved lifecycle design.

Historical placement must remain queryable.

## Subject mappings

Subject master is reused.

SchoolSubject controls school-level availability.

ClassSubject controls class-level assignment.

Do not create a new subject row merely to assign an existing subject to another class.
