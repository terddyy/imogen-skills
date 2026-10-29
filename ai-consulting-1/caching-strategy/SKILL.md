---
name: caching-strategy
description: Decide what to cache in a Django app, at which layer, with which keys, TTLs and invalidation — and avoid the classic bugs (leaking one user's data to another, stale data after writes, stampedes). Use when "should we cache this", after perf-audit/query-optimizer when queries are already efficient, or when adding Redis/memcached caching.
---

# Caching Strategy

Caching is the last step, not the first. If `perf-audit` hasn't been run, or the query is slow because of an N+1 or a missing index, fix that first; caching a bad query just hides it until the cache is cold.

## Step 1: Is it worth caching?

Cache only if all of these hold:

- It's read much more often than it changes.
- It's expensive (measured: slow query, heavy aggregation, external API call, big render).
- Slightly stale data is acceptable, or you can invalidate it reliably on every write.

Ask the dev (or the PRD) how stale is acceptable: "a few seconds", "until the next write", "an hour". That number drives the design.

## Step 2: Pick the layer

Check `CACHES` in settings first; know the backend (Redis via `django-redis` or Django's built-in `RedisCache`, memcached, `LocMemCache`). `LocMemCache` is per-process: with multiple workers, invalidation won't reach the others, so don't rely on it for anything that's invalidated on write.

| Layer | Use for | Watch out |
| --- | --- | --- |
| Low-level `cache.get_or_set` around a function | Expensive computation or query result, external API responses | Most control; you own keys and invalidation |
| `@cache_page` / `cache_page` via `method_decorator` | Public, anonymous, identical-for-everyone pages/endpoints | Caches by URL. Per-user responses will leak between users unless you `vary_on_headers("Authorization")` / `vary_on_cookie` |
| Template fragment `{% cache %}` | Expensive bit of a server-rendered page | Include user/org in the fragment key if content varies |
| `functools.cached_property` | Repeated work within one object / one request | Not shared across requests |
| HTTP caching (`ETag`, `Cache-Control`, CDN) | Static-ish public API responses, files | Never `public` on authenticated responses |

## Step 3: Keys

- Namespace + version + every input that changes the result: `f"billing:v1:org:{org_id}:invoice_summary:{period}"`.
- **Include the tenant/user** whenever the data is scoped. A key without `org_id` for org-scoped data is a data leak waiting to happen.
- Bump the version prefix (`v1` → `v2`) when the cached value's shape changes, so old entries are ignored after deploy.
- Hash long inputs (filters, query params) rather than putting them raw in the key; memcached keys max out at 250 chars.

## Step 4: Invalidation

Pick one and write it down next to the cache code:

- **TTL only**: simplest; fine when "stale for up to N minutes" is acceptable.
- **Delete on write**: in the service function that writes, after the transaction commits:
  ```python
  from django.db import transaction
  transaction.on_commit(lambda: cache.delete(invoice_summary_key(org_id, period)))
  ```
  Delete, don't set: the next read rebuilds it from committed data. Prefer doing this in the service layer over `post_save` signals; signals miss `bulk_update`/`qs.update()` and are easy to forget.
- **Versioned keys**: store a per-org version number and include it in keys; bump it to invalidate everything for that org at once (`cache.incr`).

Always set a TTL anyway, even with explicit invalidation, as a backstop.

## Step 5: Stampedes and failures

- Hot key expiring under load → many workers rebuild at once. For expensive rebuilds, use a short lock (`cache.add(lock_key, 1, timeout=30)`) so only one worker rebuilds, or add jitter to TTLs.
- The cache being down must not take the site down. Django's cache calls raise on Redis errors by default with some backends; for `django-redis` consider `IGNORE_EXCEPTIONS`. Check what's configured.
- Don't cache errors or empty results from a failed upstream call (or cache them with a very short TTL).

## Step 6: Write it up and test it

Short design note in the PR:

```
Cache: invoice summary per org+period
Layer: low-level, Redis (default cache)
Key: billing:v1:org:{org_id}:invoice_summary:{period}
TTL: 15 min backstop
Invalidation: delete on invoice create/update/void in billing/services.py (on_commit)
Stale tolerance: none after writes; 15 min for anything missed
```

Tests (use `test-writer` conventions; use a `LocMemCache` override in tests and clear it between tests):
- second call doesn't hit the DB (`django_assert_num_queries(0)`)
- a write invalidates (value changes on next read)
- org A never sees org B's cached value

## Rules

- Never cache per-user or per-org data under a key that doesn't include the user/org.
- Never `cache_page` an authenticated endpoint without varying on the auth header/cookie.
- Measure the hit rate after shipping if you can; a cache with a low hit rate is just extra complexity.
