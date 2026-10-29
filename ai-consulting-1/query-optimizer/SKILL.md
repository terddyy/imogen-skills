---
name: query-optimizer
description: Rewrite slow Django ORM code — fix N+1s, add the right indexes, move counting/aggregation into the database, batch writes — and lock in the gain with assertNumQueries / django_assert_num_queries guards. Use after perf-audit, or when someone says "too many queries", "N+1", "optimize this queryset", or "this loop hits the DB".
---

# Query Optimizer

Fix the queries, prove it with numbers, and add a guard so it doesn't regress.

## Step 1: Guard first

Before changing code, write (or reuse from `perf-audit`) a test that pins the current query count with realistic row counts (at least 10-20 rows, so N+1 is visible):

```python
def test_invoice_list_queries(admin_client_for, org, invoice_factory, django_assert_num_queries):
    invoice_factory.create_batch(20, org=org)
    with django_assert_num_queries(3):   # target after fix
        resp = admin_client_for(org).get("/api/invoices/")
    assert resp.status_code == 200
```

It fails now (that's the point). Also check the existing tests for the endpoint pass, so you know behavior doesn't change. `TestCase` projects: `with self.assertNumQueries(3):`.

## Step 2: Fix, by pattern

**N+1 on FK / one-to-one** → `select_related`
```python
Invoice.objects.filter(org=org).select_related("customer", "customer__account")
```

**N+1 on reverse FK / M2M** → `prefetch_related`, with `Prefetch` to filter or slim the related queryset
```python
from django.db.models import Prefetch
Invoice.objects.prefetch_related(
    Prefetch("lines", queryset=InvoiceLine.objects.only("id", "invoice_id", "amount"))
)
```
Prefetched data is only used if you then call `.all()`. `obj.lines.filter(...)` in the serializer throws the prefetch away and queries again. Filter in the `Prefetch` instead, or use `to_attr`.

**Per-row counts / sums** → annotate in one query
```python
from django.db.models import Count, Sum, Q
Customer.objects.annotate(
    open_invoices=Count("invoices", filter=Q(invoices__status="issued")),
    balance=Sum("invoices__total", filter=Q(invoices__status="issued")),
)
```
Watch for row multiplication when annotating across two different reverse relations: use `Subquery` for one of them, or `distinct=True` on `Count` (`Sum` can't be fixed with distinct).

**"Does any exist"** → `Exists` / `.exists()`, not `count() > 0` or `if qs:`
```python
from django.db.models import Exists, OuterRef
Customer.objects.annotate(has_overdue=Exists(Invoice.objects.filter(customer=OuterRef("pk"), overdue=True)))
```

**Latest related row per parent** → `Subquery` with `OuterRef` and `[:1]`.

**Over-fetching** → `only()` / `defer()` for list views with big text/JSON columns; `values()` / `values_list()` when you don't need model instances. Careful: accessing a deferred field later triggers one query per object.

**Writes in a loop** → `bulk_create`, `bulk_update(objs, fields, batch_size=500)`, or a single `qs.update(...)` with `F()` expressions. These skip `save()` and signals; check nothing relies on them first.

**Big iteration** (exports, commands) → `.iterator(chunk_size=2000)`; combine with `prefetch_related` only on Django 4.1+ (needs `chunk_size`).

**DRF**: put `select_related`/`prefetch_related` in the view's `get_queryset`, matched to what the serializer touches. Replace `SerializerMethodField`s that query with annotations read via a plain field (`serializers.IntegerField(read_only=True)`).

**Missing index** → add to `Meta.indexes`, composite in the order of equality filters first, then range/sort:
```python
class Meta:
    indexes = [models.Index(fields=["org", "status", "-created_at"], name="inv_org_status_created_idx")]
```
Ship it with `AddIndexConcurrently` per `django-migrations`. Confirm with `explain()` that the planner uses it on realistic data.

## Step 3: Verify

- Guard test passes at the new count. Set it to the exact number (not max) for list endpoints so new N+1s fail loudly.
- All existing tests for the endpoint pass: same responses, same ordering.
- Before/after numbers: query count, DB time, response time. Put them in the PR description.

## Rules

- Change one pattern at a time and re-measure. Stacking five "optimizations" makes it impossible to tell which one helped or broke something.
- Keep ordering stable: adding `distinct()` or annotations can change result order or duplicates; tests should catch it, so check.
- No raw SQL unless the ORM genuinely can't express it; if you do, parameterize it (`cursor.execute(sql, params)`), never f-strings.
