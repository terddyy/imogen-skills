---
name: perf-audit
description: Find why a Django page or API endpoint is slow — N+1 queries, missing indexes, heavy serializers, unbounded querysets, slow external calls — measure it, rank the findings by impact, and output Jira-ready tickets. Use when "this page is slow", "this endpoint times out", before a client demo, or for a periodic performance review.
---

# Perf Audit

Measure first, then explain, then ticket. No optimizing in this skill; `query-optimizer` and `caching-strategy` do the fixing.

## Step 1: Scope

Get the specific slow thing: URL/endpoint, the user/role it's slow for, rough data size, and how slow ("4s on prod for org X"). Slow for one tenant and fast for others usually means data volume, so ask which tenant.

For a broad audit (no specific complaint), list the endpoints first and prioritize by traffic (ask, or check APM/access logs) × likely cost (list endpoints, nested serializers, reports, exports).

## Step 2: Measure

Use what the project has, in this order:

1. **APM** (Sentry Performance, New Relic, Datadog, Scout) if the dev has access: the trace shows DB vs external vs Python time for real requests. Ask them to paste the trace summary.
2. **A test that reproduces it** with realistic volume. This is also the regression guard later:

   ```python
   from django.db import connection
   from django.test.utils import CaptureQueriesContext

   @pytest.mark.django_db
   def test_measure_invoice_list(admin_client_for, org, invoice_factory):
       invoice_factory.create_batch(50, org=org)
       with CaptureQueriesContext(connection) as ctx:
           admin_client_for(org).get("/api/invoices/")
       print(len(ctx.captured_queries))
       for q in ctx.captured_queries:
           print(q["time"], q["sql"][:200])
   ```
   Run with `pytest -s`. Query count that grows with the number of rows = N+1.
3. **django-debug-toolbar** or **django-silk** locally, if installed.
4. **EXPLAIN** for slow individual queries: `queryset.explain(analyze=True)` on Postgres against a DB with realistic data (staging copy). `ANALYZE` actually runs the query, so never on production writes.
5. **`pg_stat_statements`** on staging/prod (if the dev has read access) for the top queries by total time.

Record a baseline: query count, total DB time, total response time, payload size.

## Step 3: Look for the usual suspects

- **N+1**: serializer touching `obj.related.field` or a `SerializerMethodField` that queries, nested serializers, `@property` on models that query, template loops over relations. Missing `select_related` (FK/one-to-one) or `prefetch_related` (reverse FK/M2M).
- **Counting in Python**: `len(qs)`, `qs.count()` per row, `.all()` then filtering in Python.
- **Missing indexes**: `filter()` / `order_by()` / `exclude()` on non-indexed columns, especially combined filters (`org_id` + `status` + `created_at` wants a composite index). Look for `Seq Scan` on big tables in EXPLAIN.
- **Unbounded querysets**: list endpoints without pagination, exports loading everything into memory (should use `.iterator()`).
- **Over-fetching**: huge `TextField`/`JSONField` loaded for list views (`only()`/`defer()`), returning far more fields than the consumer uses.
- **Heavy serialization**: DRF serializing thousands of objects; deep nesting.
- **Work in the request** that could be async: emails, PDF generation, third-party API calls (Celery).
- **External calls** without timeouts or called once per row.
- **Repeated identical work** across requests: candidates for `caching-strategy`.

## Step 4: Report and ticket

Rank findings by expected gain ÷ effort. For each:

```
[High] N+1 on InvoiceSerializer.customer_name
Where: billing/serializers.py:44 (SerializerMethodField → obj.customer.name)
Evidence: 50 invoices → 53 queries; grows 1 per row
Fix: select_related("customer") in InvoiceViewSet.get_queryset; add query-count guard
Expected: 53 → 3 queries, ~600ms → ~80ms locally
Effort: 1 pt   Route: query-optimizer
```

Then produce one Jira ticket per finding (or group trivial ones), in the `jira-tickets` format, with the baseline numbers in the ticket so the fix can be verified. Create them only after the dev confirms.

## Rules

- Every finding has evidence (numbers, EXPLAIN output, trace). "Probably slow" isn't a finding.
- Never run `EXPLAIN ANALYZE` on write queries or against production without the dev explicitly saying it's OK.
- Don't recommend caching for something an index or `select_related` fixes.
