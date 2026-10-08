# Entity: finance_schema.term_fee_payment_transaction

## Purpose

Payment or refund receipt linked only to a `student_term_fee_record` and a term number (1–3).

## Primary key

- `term_fee_payment_transaction_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Notes |
|--------|-------|
| receipt_number | Unique per school + academic year (within this table) |
| student_term_fee_record_id | Required FK |
| term_number | 1 / 2 / 3 |
| txn_type | PAYMENT / REFUND |
| amount | Must be > 0 |
| paid_at | Payment timestamp UTC |

## Application rule

Insert this transaction and update parent `student_term_fee_record` (`termN_paid`, `total_paid`, `payment_status`) in the same DB transaction.

Prefer receipt prefix `TRM-` when sharing a display series with other-fee receipts.
