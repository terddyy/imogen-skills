---
name: django-migrations
description: Write and review Django migrations that are safe on live databases — no long table locks, reversible, schema and data changes separated, backfills in batches. Use when adding/changing/removing models, fields, indexes or constraints, writing a data migration, or reviewing a migration before merge.
---

# Django Migrations

A migration that's fine on a dev DB with 50 rows can lock a 10M-row production table for minutes. Assume Postgres unless the project says otherwise (if it's MySQL, check each operation against MySQL online DDL instead).

## Step 1: Generate, then read the SQL

```bash
python manage.py makemigrations <app>
python manage.py sqlmigrate <app> <migration_number>
```

Always read the `sqlmigrate` output. The Python looks harmless far more often than the SQL is.

Ask the dev for the rough row count of any table being altered (or check a staging DB). Under ~100k rows most of the rules below are relaxed; say so when they are.

## Step 2: Check each operation

| Operation | Safe? | Do this instead |
| --- | --- | --- |
| Add nullable field | Safe | |
| Add field with a constant default (PG 11+) | Safe, no rewrite | Prefer `db_default=` (Django 5.0+) so the default lives in the DB too |
| Add NOT NULL field without default | Fails / locks | Add nullable → backfill → add NOT NULL later |
| Make existing column NOT NULL | Full scan under exclusive lock | Add `CHECK (col IS NOT NULL) NOT VALID` → `VALIDATE CONSTRAINT` → `SET NOT NULL` (PG 12+ skips the scan) → drop check. Use `RunSQL` with reverse SQL. |
| Add index | Blocks writes | `AddIndexConcurrently` from `django.contrib.postgres.operations`, migration with `atomic = False` |
| Remove index | Blocks | `RemoveIndexConcurrently`, `atomic = False` |
| Add unique constraint | Blocks + fails on dupes | Check for duplicates first; create unique index concurrently, then attach constraint |
| Add ForeignKey to big table | Validates all rows under lock | Add with `db_constraint=False`, or add the constraint `NOT VALID` then `VALIDATE` via `RunSQL` |
| Rename field / model | Breaks running code mid-deploy | Use `safe-change` (expand/contract) |
| Remove field | Breaks running code mid-deploy | Remove usage first; then `SeparateDatabaseAndState` to drop from state; drop the column in a later release |
| Change field type | Usually rewrites the table | New column + backfill + switch (expand/contract) |
| `AlterField` that only changes `choices`, `help_text`, `verbose_name` | No SQL | Fine, but still check `sqlmigrate` |

For risky DDL, set a lock timeout so the migration fails fast instead of queueing every query behind it:

```python
operations = [
    migrations.RunSQL("SET lock_timeout = '5s';", reverse_sql=migrations.RunSQL.noop),
    ...
]
```

## Step 3: Data migrations

- Separate migration from schema changes. Never mix DDL and a backfill in one migration.
- Use `apps.get_model("app", "Model")`, never import the model directly.
- Batch it. One `UPDATE` over 5M rows holds locks and bloats WAL:

```python
from django.db import migrations
from django.db.models import F

def backfill(apps, schema_editor):
    Invoice = apps.get_model("billing", "Invoice")
    qs = Invoice.objects.filter(state__isnull=True).values_list("pk", flat=True)
    while True:
        batch = list(qs[:1000])
        if not batch:
            break
        Invoice.objects.filter(pk__in=batch).update(state=F("status"))

class Migration(migrations.Migration):
    atomic = False
    operations = [migrations.RunPython(backfill, reverse_code=migrations.RunPython.noop)]
```

- Very large backfills (hours) belong in a management command or Celery task run after deploy, not in a migration.
- Every `RunPython` has `reverse_code`. `RunPython.noop` is fine when reversing the schema migration is enough; say so in a comment.

## Step 4: Reversibility and history

- Run it both ways locally: `migrate <app> <previous>` then `migrate <app>`.
- Never edit a migration that has run in any shared environment. Write a new one.
- Conflicting migrations after a merge: `makemigrations --merge`, and check the merge migration doesn't hide a real ordering problem.
- Squash only when the team agrees; never squash migrations other repos or environments haven't applied yet.

## Step 5: CI and deploy notes

- `python manage.py makemigrations --check --dry-run` should pass (no missing migrations).
- In the PR description, state: tables touched, row counts, expected lock behavior, whether it must deploy before/after code changes, and how to roll back. `pr-description` will pick this up.

## Rules

- Code must work with both the old and the new schema during a deploy (migrations usually run before the new code is live, and the old code keeps running for a while).
- No `RunSQL` without `reverse_sql` unless it's genuinely irreversible, and then say so in the migration.
