# Entity: finance_schema.student_other_fee_record

## Purpose

Per-student single-amount fee record with one due date (no terms).

Created once per student/year/category (from `fee_structure_other` or MANUAL e.g. library fine). Payments **update** this row.

## Primary key

- `student_other_fee_record_id` — `BIGINT IDENTITY`, clustered

## Fee categories

EXAM, SPORTS, LAB, LIBRARY, BOOKS, ADMISSION, OTHER

## Key columns

| Column | Notes |
|--------|-------|
| fee_structure_other_id | Optional link to master when assignment_source = STRUCTURE |
| total_amount, scholarship_amount, net_amount | Scholarship reduces net |
| total_paid, balance_amount | App-maintained with payments |
| due_date | Single due date |
| payment_status | DUE / PARTIAL / PAID |
| row_version | Concurrency on fee updates |

## Uniqueness

`(school_id, branch_id, academic_year_id, student_id, fee_category_code)`

## Application rule

Insert `other_fee_payment_transaction` and update this fee record in the same transaction.
