# Backup and Recovery

Production databases require an approved backup and recovery strategy.

## Required controls

- defined RPO/RTO;
- protected backups;
- encryption where required;
- restricted backup access;
- backup monitoring;
- failure alerts;
- retention;
- restore testing;
- point-in-time recovery where supported and required;
- documented restore validation.

A successful backup job is not proof of recoverability.

## Restore validation

After restore:
1. validate database accessibility;
2. validate schema/migration state;
3. validate constraints;
4. validate critical data;
5. validate application connectivity;
6. record restore-test evidence.

Never perform destructive recovery steps without an approved runbook.
