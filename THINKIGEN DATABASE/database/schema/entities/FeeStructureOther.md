# Entity: finance_schema.fee_structure_other

## Purpose

Class-level master template for non-term fees (EXAM, SPORTS, LAB, LIBRARY, BOOKS, ADMISSION, OTHER). One ACTIVE row per school/branch/year/class/category.

Copied into `student_other_fee_record` on enroll/promote. Master has amount + due date only — no paid columns.

## Primary key

- `fee_structure_other_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Notes |
|--------|-------|
| fee_category_code | EXAM / SPORTS / LAB / LIBRARY / BOOKS / ADMISSION / OTHER |
| total_amount | Single amount |
| due_date | Single due date |
| status | DRAFT / ACTIVE / INACTIVE |

## Uniqueness

Filtered unique: one ACTIVE row per `(school_id, branch_id, academic_year_id, class_id, fee_category_code)`.

## Security

Configuration. Scope enforced in FastAPI (RBAC + ABAC).
