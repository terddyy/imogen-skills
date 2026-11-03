---
name: query-optimizer
description: Rewrite slow database access in whatever the repo uses (Prisma, Drizzle, TypeORM, SQLAlchemy, Django ORM, ActiveRecord, GORM, Eloquent, Knex, raw SQL) - fix N+1s, add the right indexes, push counting and aggregation into the database, batch writes - read the EXPLAIN plan, and lock the gain in with a query-count or timing guard in tests. Use after perf-audit, or when someone says "too many queries", "N+1", "optimize this query", "this loop hits the DB", or "this report takes forever".
---

# Query Optimizer

Fix the queries, prove it with numbers, and add a guard so it doesn't come back.

## Step 0: Read the stack

Identify the database (Postgres, MySQL, SQLite, SQL Server, Mongo) and the access layer from manifests and imports. Find how the repo already logs queries and whether any test already counts them (`grep -ri "query count\|assertNumQueries\|num_queries\|\$on('query'"`). Copy that pattern. Read the migration tool's conventions before adding an index (see `db-migrations`).

## Step 1: Guard first

Before changing code, write (or reuse from `perf-audit`) a test that pins the query count with enough rows (20+) that an N+1 is visible. Use the repo's mechanism, or a counter on the ORM's query event:

- Prisma: `prisma.$on("query", () => count++)` with `log: [{ emit: "event", level: "query" }]`
- SQLAlchemy: `event.listen(engine, "before_cursor_execute", lambda *a: counter.append(1))`
- Django: `django_assert_num_queries(3)` / `assertNumQueries(3)`

Set the target count (after the fix). It fails now; that's the point. Run the endpoint's existing tests too, so you know current behavior is pinned.

## Step 2: Read the plan

Run `EXPLAIN (ANALYZE, BUFFERS)` (Postgres) or `EXPLAIN ANALYZE` (MySQL 8) on the slow query against realistic data. Get the SQL from the ORM's query log. Look for:

- `Seq Scan` / `type: ALL` on a big table with a selective filter: missing index.
- Estimated rows far off from actual rows: stale statistics (`ANALYZE table`) or a skewed column.
- `Sort` spilling to disk, or `Nested Loop` over thousands of outer rows.
- Rows removed by filter much larger than rows returned: index doesn't match the filter.

## Step 3: Fix, by pattern

**N+1 on a relation**: load it with the parent. Prisma `include`/`select`, Django `select_related`/`prefetch_related`, SQLAlchemy `selectinload`/`joinedload`, ActiveRecord `includes`, GORM `Preload`, Eloquent `with`. GraphQL: batch per request with a dataloader.

**Per-row counts or sums**: one aggregate query (`GROUP BY`, `_count`, `annotate(Count(...))`, `func.count`) instead of a count per row. Watch row multiplication when joining two one-to-many relations at once; use a subquery for one.

**"Does any exist"**: `EXISTS` / `.exists()` / `findFirst`, not `count() > 0`.

**Latest child per parent**: `DISTINCT ON` (Postgres), a lateral join, or a window function (`ROW_NUMBER() OVER (PARTITION BY ...)`).

**Over-fetching**: select only the columns the caller uses, especially on list views with big text/JSON columns.

**Unbounded lists**: paginate. Keyset (`WHERE (created_at, id) < (?, ?) ORDER BY created_at DESC, id DESC LIMIT 50`) beats large `OFFSET` on deep pages.

**Writes in a loop**: bulk insert/update (`createMany`, `bulk_create`, `insert_all`, multi-row `INSERT ... ON CONFLICT`) or one set-based `UPDATE`. These often skip model hooks/callbacks; check nothing relies on them.

**Missing index**: composite index with equality columns first, then the range/sort column: `(org_id, status, created_at DESC)`. Add it through the repo's migration tool. On a big live Postgres table use `CREATE INDEX CONCURRENTLY` (outside a transaction). Re-run EXPLAIN to confirm the planner uses it.

## Step 4: Verify

- Guard passes at the new count. Use an exact count, not a max, for list endpoints so a new N+1 fails loudly. Add a timing assertion only if the repo already has stable perf tests; timing in CI is noisy.
- All existing tests for the code path pass: same results, same ordering, same pagination.
- Before/after numbers (query count, DB time, response time, EXPLAIN cost) go in the PR description.

## Rules

- One pattern at a time, re-measure after each. Five stacked changes make it impossible to tell which one helped or broke something.
- Keep ordering stable. Joins, `DISTINCT` and aggregates can change order or add duplicates; always end with a deterministic `ORDER BY` (add `id` as tiebreaker).
- Raw SQL only when the query layer genuinely can't express it, and always parameterized. Never build SQL with string concatenation or template literals.
- Never run `EXPLAIN ANALYZE` on write queries or against production without explicit OK.

Next: `caching-strategy` if it's efficient but still hot, `db-migrations` for the index rollout, `pr-description` to ship.
