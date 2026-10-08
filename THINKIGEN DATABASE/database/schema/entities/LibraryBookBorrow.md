# Entity: library_schema.library_book_borrow

## Purpose

Student book loan — current borrows (My Borrowed Books) and history (View History).

## Key columns

| Column | Type | Notes |
|--------|------|-------|
| borrowed_at | DATETIME2(0) | When borrowed (UTC) |
| due_date | DATE | Return due date (`YYYY-MM-DD`) |
| returned_at | DATETIME2(0) | When returned (UTC) |
| fine_amount | DECIMAL(18,2) | Library fine amount |
| fine_status | NVARCHAR(20) | NONE / DUE / PAID |

## UI labels (API)

- DUE IN N DAYS — from `due_date`
- OVERDUE — `due_date < today` and ACTIVE
