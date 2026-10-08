# Thinkigen Database Task Prompt

Use this prompt when asking Cursor to modify the database:

> You are working on the Thinkigen database.  
> First inspect the current implementation, schema, migrations, constraints, indexes, relevant queries and tests.  
> Do not redesign unrelated parts.  
> Implement only the exact requested change.  
> Do not invent business rules, tables, relationships, statuses, permissions, financial behavior, procedures, triggers or jobs.  
> Preserve Organization database isolation, academic history, RBAC + ABAC assumptions, least privilege and existing API compatibility.  
> If the requirement is ambiguous in a way that changes business behavior, stop and ask me.  
> If schema changes are required, create a versioned migration, test it, assess backward compatibility, and document rollback/recovery.  
> Never modify an applied migration or production schema directly.  
> Never hardcode secrets.  
> Before completion, inspect the final diff and remove unrelated changes.  
> Report exactly what changed, what did not change, tests performed, migration/rollback considerations, and any remaining ambiguity.
