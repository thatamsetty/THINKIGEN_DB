# Database Access Control

## Principle

Least privilege.

Application runtime access must be separated from migration/administration access.

Do not grant application accounts broad DDL or db_owner privileges.

## Authorization

FastAPI:
JWT validation
→ RBAC
→ ABAC
→ authorized query/database operation.

A database query must not accept a school/branch/student ID and assume it is authorized merely because it is syntactically valid.

## Scope

Principal, administrator and correspondent are restricted to their permitted school.

Teacher is restricted to assigned academic scope.

Management is restricted to explicitly assigned schools.

Student is restricted to own authorized data.

No cross-Organization access exists because each Organization has a separate database.
