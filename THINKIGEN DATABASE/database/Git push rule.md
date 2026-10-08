# Database Git Daily Commit and Push Policy

## 1. Objective

All database structural changes made during development must be version-controlled in GitHub.

GitHub is the source of truth for database code and database structure.

The database itself must NOT be treated as a Git repository.

## 2. What Must Be Stored in Git

The repository must contain:

- Database schemas
- Table definitions
- Primary keys
- Foreign keys
- Unique constraints
- Check constraints
- Indexes
- Views
- Materialized views
- Stored procedures
- Functions
- Triggers
- Sequences
- Database migrations
- Reference/seed data scripts
- Database configuration templates
- ER diagrams/documentation
- Database change documentation

## 3. What Must NOT Be Stored in Git

Never commit:

- Production database backups
- Database passwords
- Connection strings containing passwords
- API keys
- JWT secrets
- TLS/private keys
- Personally identifiable production data
- Large production database dumps
- .env files containing secrets

Use environment variables or a secrets manager for credentials.

## 4. Daily Development Rule

Every database change made during the working day must be represented as a version-controlled file.

Before the end of the working day:

1. Review database changes.
2. Validate SQL/migrations.
3. Check naming conventions.
4. Check constraints.
5. Check indexes.
6. Check migration ordering.
7. Check that no secrets or production data are included.
8. Review `git diff`.
9. Commit the changes.
10. Push the commit to GitHub.

## 5. Daily Push Time

The standard daily synchronization time is:

**7:30 PM every working day.**

At 7:30 PM, the developer should ensure that all completed database changes for that day are committed and pushed to the appropriate Git branch.

Recommended commit format:

`db: add student attendance indexes`

`db: create timetable tables`

`db: add fee payment constraints`

`db: update student migration`

## 6. Branching Rule

Never make database changes directly on the production branch.

Recommended structure:

- `main` → production-ready database changes
- `develop` → integrated development changes
- `feature/*` → individual database features
- `hotfix/*` → urgent production fixes

Example:

`feature/timetable-db`

`feature/attendance-db`

`feature/fee-management-db`

## 7. Pull Before Push

Before the 7:30 PM push:

```bash
git pull --rebase origin <branch>

```

Resolve conflicts if necessary.

Then:

```bash
git status
git diff
git add .
git commit -m "db: <description>"
git push origin <branch>

```

## 8. Database Change Rule

A database change must follow:

Developer change  
→ Migration/SQL script  
→ Local validation  
→ Code review  
→ Git commit  
→ GitHub  
→ Test environment  
→ Validation  
→ Production deployment

Never manually change production first and document it later.

## 9. Migration Rule

Every structural database change must have a migration.

Examples:

- Create table
- Add column
- Remove column
- Change data type
- Add constraint
- Remove constraint
- Create index
- Modify index
- Create view
- Modify function
- Create trigger

Existing migration files must not be modified after they have been applied to shared environments.

Create a new migration instead.

## 10. Production Safety Rule

GitHub must NOT automatically execute every developer database change against production.

Production database deployment must require:

- Migration review
- Testing
- Approval
- Backup/rollback consideration
- Controlled deployment

## 11. Backup Rule

Git version control and database backup are separate systems.

GitHub stores database definitions and migrations.

The database backup system stores recoverable database data.

Both are required.

## 12. Daily Completion Checklist

At 7:30 PM verify:

- Database changes reviewed
- SQL/migrations validated
- Constraints checked
- Indexes checked
- No secrets committed
- No production data committed
- `git diff` reviewed
- Commit created
- Changes pushed to GitHub
- GitHub branch is synchronized
- Migration status is documented

## 13. Golden Rule

GitHub is the source of truth for:

**Database Structure + Database Changes + Database Documentation**

The database is the source of truth for:

**Actual Runtime Data**

Never use GitHub as a replacement for database backups.

