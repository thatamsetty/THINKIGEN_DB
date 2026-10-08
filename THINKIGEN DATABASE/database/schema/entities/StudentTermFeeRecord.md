# Entity: finance_schema.student_term_fee_record

## Purpose

Per-student term-wise fee record for TUITION, HOSTEL, and TRANSPORT (Term 1/2/3).

Created once per student/year/category (usually copied from `fee_structure_term`). Payments **update** this row; they do not add columns.

## Key columns

| Column | Type | Notes |
|--------|------|-------|
| fee_structure_term_id | BIGINT NULL | Optional link to master when assignment_source = STRUCTURE |
| term1_amount … term3_amount | DECIMAL(18,2) | Must sum to total_amount |
| term1_due_date … term3_due_date | DATE | Per-term due dates |
| term1_paid … term3_paid | DECIMAL(18,2) | Updated on payment |
| term1_paid_at … term3_paid_at | DATETIME2(0) | When each term was paid (UTC) |
| total_paid, balance_amount | DECIMAL(18,2) | App-maintained with payments |
| payment_status | NVARCHAR(20) | DUE / PARTIAL / PAID |

## Constraint

`total_paid <= total_amount - scholarship_amount`

## Application rule

Insert `term_fee_payment_transaction` and update this fee record in the same transaction.
