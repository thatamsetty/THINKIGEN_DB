# Thinkigen Database Docs

| Document | Description |
|----------|-------------|
| [full-table-reference.md](./full-table-reference.md) | All SQL Server tables, columns, constraints (generated) |
| [full-table-reference.txt](./full-table-reference.txt) | Same content in plain-text form (generated) |
| [mongodb-collections-reference.md](./mongodb-collections-reference.md) | MongoDB collections + full validation scripts (generated) |
| [conventions.md](./conventions.md) | SQL conventions |
| [naming.md](./naming.md) | Naming rules |
| [data-dictionary.md](./data-dictionary.md) | Data dictionary standard |

## Regenerate docs

```bash
python database/scripts/generate_full_table_reference.py
python database/scripts/generate_mongodb_collections_reference.py
```
