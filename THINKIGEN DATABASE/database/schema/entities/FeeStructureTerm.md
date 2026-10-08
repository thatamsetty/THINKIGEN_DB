# Entity: finance_schema.fee_structure_term

## Purpose

Class-level master template for term-wise fees (TUITION, HOSTEL, TRANSPORT). One ACTIVE row per school/branch/year/class/category.

Copied into `student_term_fee_record` on enroll/promote. Master has amounts and due dates only — no paid columns.

## Primary key

- `fee_structure_term_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Notes |
|--------|-------|
| fee_category_code | TUITION / HOSTEL / TRANSPORT |
| term1_amount … term3_amount | Must sum to total_amount |
| term1_due_date … term3_due_date | Per-term due dates |
| status | DRAFT / ACTIVE / INACTIVE |

## Uniqueness

Filtered unique: one ACTIVE row per `(school_id, branch_id, academic_year_id, class_id, fee_category_code)`.

## Security

Configuration. Scope enforced in FastAPI (RBAC + ABAC).
