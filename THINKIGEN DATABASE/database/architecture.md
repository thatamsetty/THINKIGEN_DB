# Thinkigen Database Architecture

## 1. Database isolation

Thinkigen is provisioned as one dedicated database per Organization.

The Organization is the customer/business boundary. Because each Organization has its own database:

- no cross-Organization FK exists;
- no cross-Organization joins are part of the normal application model;
- no generic `organization_id` column is required on every table;
- database connection selection is part of the Organization context;
- FastAPI must never route a request to the wrong Organization database.

The Organization database contains all schools belonging to that Organization.

## 2. Organization and schools

The Organization needs an approved Organization-level record/configuration representation because the product still needs Organization identity, code and name and must know its schools and Organization-level administration context.

Do not duplicate the Organization as a second tenant row or create a second Organization database inside the same database.

School records are separate business entities because schools have independent IDs, configuration and history.

## 3. Academic hierarchy

The authoritative path is:

School → Academic Year → Branch → Class → Section → Student

The Organization is the database boundary above School.

A school may have multiple branches. If a school has no meaningful branch distinction, the approved single/default branch representation is used rather than creating a second hierarchy.

## 4. Academic identity

The same class/section label can exist in multiple branches and academic years.

Therefore human labels such as `10`, `10-A`, `A` are never sufficient as relational identity.

Relationships must retain the correct School, Academic Year, Branch, Class and Section context.

## 5. Student lifecycle

A student has one active academic placement at a time.

Promotion is an explicit authorized business operation after the academic year is completed. Automatic promotion is prohibited unless explicitly approved.

A student can change section/branch/school within the Organization according to the approved business process. Historical placements remain intact.

A student who completes the highest class has no artificial next class/section. Alumni behavior is a separate approved feature.

## 6. Subject architecture

Subject is Organization-level master data.

A subject created by one school becomes available as master data to other schools.

Schools can enable/disable the available subjects. Schools may create a new subject when required; that becomes part of the Organization subject master.

Use:
Subject → SchoolSubject → ClassSubject

Do not create duplicate Mathematics records for every school/class.

The same subject can be used by multiple classes.

## 7. Users and domain identities

User ID is authentication/session identity.

Domain identities remain separate:
- Student ID
- Teacher ID
- other approved domain IDs

Creating a Student user creates the approved User identity and Student identity through the controlled application workflow.

Do not use a display name, admission number or role as a primary key.

## 8. Authorization

Authentication:
JWT access/refresh tokens are validated by FastAPI.

Authorization:
RBAC + ABAC.

RBAC determines what a user can do.
ABAC determines which resources they can act on.

Examples:
- Principal → permitted school only.
- School Administrator → permitted school only.
- Correspondent → permitted school only.
- Teacher → assigned branch/class/section/subject scope only.
- Management/Director → explicitly permitted schools only.
- Transport Manager → assigned school/transport scope.
- Student → own authorized information only.

The UI is never an authorization boundary.

## 9. Concurrency

Use SQL Server `rowversion` only for important mutable transactional/configuration tables where concurrent edits could lose data.

Candidate areas include Student, User/Role configuration, Attendance, Marks/Grades, Timetable, Fee/Payment and important mutable configuration.

Do not add rowversion to every table.

## 10. Data integrity

Use database constraints to enforce facts that must always be true.

Required controls include, where applicable:
- PK
- FK
- UNIQUE
- CHECK
- NOT NULL
- approved defaults

Do not replace a database constraint with application-only validation when the rule is an invariant.

## 11. Finance baseline

Current approved finance model:

Organization → School → Branch → Academic Year → Class → Section → Student → Fee/Receipt.

Term-wise:
- Tuition
- Hostel
- Transport

Single amount + due date:
- Exam
- Sports
- Lab
- Library
- Books
- Admission
- Other

Scholarship reduces net amount.

Fee status:
- DUE
- PARTIAL
- PAID

Payments and refunds are receipt transactions.

Transport assignment remains in Transport. Finance stores the financial amount, not the bus/route relationship.

This is a baseline only. Do not invent accounting/ledger/tax/payroll/reconciliation rules.
