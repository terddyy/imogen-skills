---
name: perf-audit
description: Find why a page, screen or API endpoint is slow, backend or frontend. Measure it first (profiler, query log, APM trace, Lighthouse/Web Vitals, bundle analyzer), find the cause (N+1 queries, missing indexes, heavy payloads, render waterfalls, large bundles, slow external calls), rank the findings by impact and write optional Jira tickets. Use when "this page is slow", "this endpoint times out", "the app feels sluggish", "Lighthouse score dropped", before a client demo, or for a periodic performance review.
---

# Perf Audit

Measure, explain, then ticket. This skill does not optimize anything. `query-optimizer`, `caching-strategy` and the dev's own fixes do that.

## Step 0: Read the stack

Find the backend and frontend from manifests (`package.json` + lockfile, `pyproject.toml`, `go.mod`, `Gemfile`, `composer.json`, `pom.xml`, `*.csproj`), the ORM or query layer (Prisma, Drizzle, SQLAlchemy, Django ORM, ActiveRecord, GORM, Eloquent, raw SQL), the database, and the frontend build tool (Vite, Next.js, webpack). Check `repo-map.md` (parent folder or `docs/`) if there is one, and verify it against the code.

## Step 1: Scope

Pin down the specific slow thing: URL/endpoint/screen, which user or tenant, rough data size, how slow and where ("4s TTFB on prod for org X", "list scrolls at 10fps on mobile"). Slow for one tenant only usually means data volume, so ask which one.

For a broad audit with no specific complaint, list the endpoints and routes first, then prioritize by traffic (APM, access logs, analytics, or ask) times likely cost (lists, reports, exports, dashboards).

## Step 2: Measure

Use what the project already has, in this order:

1. **APM / tracing** (Sentry, Datadog, New Relic, OpenTelemetry) if the dev has access. Ask them to paste the trace: DB vs external vs app time.
2. **A test or script that reproduces it** with realistic volume (seed 50+ rows). Log query count and time with the ORM's query logging (Prisma `log: ["query"]`, SQLAlchemy `echo=True`, Django `CaptureQueriesContext`, ActiveRecord log). Query count that grows with row count is an N+1. Keep this test; it becomes the guard.
3. **Profiler** for CPU-bound code: `node --cpu-prof`/clinic, `py-spy`/`cProfile`, `go tool pprof`.
4. **EXPLAIN** the slow queries (`EXPLAIN (ANALYZE, BUFFERS)` on Postgres, `EXPLAIN ANALYZE` on MySQL 8) against realistic data, such as a staging copy.
5. **Frontend**: Lighthouse (`npx lighthouse <url> --view` or DevTools), the Performance panel for long tasks and re-renders, the Network panel for waterfalls and payload sizes, React Profiler for wasted renders. Field data (Web Vitals: LCP, INP, CLS) beats lab data when it exists.
6. **Bundle**: the repo's analyzer if configured, else `npx vite-bundle-visualizer`, `@next/bundle-analyzer`, or `npx source-map-explorer dist/**/*.js`.

Record a baseline: query count, DB time, response time, payload size, LCP/INP/CLS, JS shipped (gzip).

## Step 3: Look for the usual suspects

Backend:
- **N+1**: serializer/resolver/template touching a relation per row; GraphQL resolvers without a dataloader.
- **Missing indexes**: filter/sort on unindexed columns, combined filters wanting a composite index. Seq Scan on a big table in EXPLAIN.
- **Unbounded reads**: lists without pagination, exports loading everything into memory.
- **Over-fetching**: `SELECT *` with big text/JSON columns on list views; returning far more fields than the client uses.
- **Work in the request** that belongs in a background job: email, PDFs, third-party calls.
- **External calls** per row or without timeouts.

Frontend:
- **Waterfalls**: fetch in child after parent's fetch resolves; sequential `await`s that could run in parallel.
- **Large bundles**: a whole library for one function (moment, lodash, icon packs), no route-level code splitting, server-only code in the client bundle.
- **Render cost**: re-rendering long lists on every keystroke, no virtualization past a few hundred rows, context changes re-rendering the whole tree.
- **Assets**: unsized or uncompressed images (CLS, LCP), render-blocking fonts/scripts, no caching headers.
- **Repeated identical work** across requests or screens: candidate for `caching-strategy`.

## Step 4: Report and ticket

Rank by expected gain divided by effort:

```
[High] N+1 on invoice list (customer name per row)
Where: src/invoices/invoice.service.ts:44
Evidence: 50 invoices -> 53 queries, +1 per row; 610ms locally
Fix: include customer in the list query; add query-count guard
Expected: 53 -> 2 queries, ~80ms
Effort: 1 pt   Route: query-optimizer
```

Then offer one Jira ticket per finding (group trivial ones) in the `jira-tickets` format, with the baseline numbers so the fix can be verified. Jira: Atlassian MCP if connected, else REST with `JIRA_URL`/`JIRA_EMAIL`/`JIRA_API_TOKEN`, else give the dev text to paste. Create tickets only after the dev confirms. Never print tokens.

## Rules

- Every finding has evidence: numbers, EXPLAIN output, a trace, a Lighthouse run. "Probably slow" is not a finding.
- Never run `EXPLAIN ANALYZE` on writes or against production without the dev explicitly saying it's OK. It executes the query.
- Lab numbers vary. Run Lighthouse 3 times and take the median; note device and throttling.
- Don't recommend caching for something an index, a join or pagination fixes.

Next: `query-optimizer` for DB findings, `caching-strategy` once queries are already efficient, `jira-tickets` to file the rest.
