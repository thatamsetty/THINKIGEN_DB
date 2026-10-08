# Rollback

Every migration must document its rollback/recovery strategy.

For destructive or irreversible operations, do not pretend rollback is possible.

Instead document:
- why it is irreversible;
- backup/recovery requirement;
- validation before execution;
- recovery procedure;
- approval requirement.
