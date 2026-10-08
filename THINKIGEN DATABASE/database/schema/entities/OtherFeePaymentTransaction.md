# Entity: finance_schema.other_fee_payment_transaction

## Purpose

Payment or refund receipt linked only to a `student_other_fee_record`.

## Primary key

- `other_fee_payment_transaction_id` — `BIGINT IDENTITY`, clustered

## Key columns

| Column | Notes |
|--------|-------|
| receipt_number | Unique per school + academic year (within this table) |
| student_other_fee_record_id | Required FK |
| txn_type | PAYMENT / REFUND |
| amount | Must be > 0 |
| paid_at | Payment timestamp UTC |

## Application rule

Insert this transaction and update parent `student_other_fee_record` (`total_paid`, `payment_status`) in the same DB transaction.

Prefer receipt prefix `OTH-` when sharing a display series with term-fee receipts.
