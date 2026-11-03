---
name: caching-strategy
description: Decide what to cache, at which layer (HTTP/CDN, app cache like Redis or memcached, database, client-side like React Query/SWR/Apollo), with which keys, TTLs and invalidation, and avoid the classic bugs - one user's data leaking to another, stale data after a write, cache stampedes, the site going down with the cache. Use when "should we cache this", "add Redis", "the dashboard is slow but the queries are fine", "users see old data after saving", or after perf-audit/query-optimizer.
---

# Caching Strategy

Caching is the last step. If the slowness is an N+1, a missing index or an unpaginated list, fix that first (`query-optimizer`); caching a bad query just hides it until the cache is cold.

## Step 0: Read the stack

Find what's already there: cache client and config (`ioredis`/`redis`, `django-redis`, `Rails.cache`, `go-redis`, Spring `@Cacheable`), any CDN (Cloudflare, Fastly, Vercel, CloudFront config), HTTP cache headers the app sets, and client data libraries (TanStack Query, SWR, Apollo, RTK Query). Grep for existing cache keys and copy their naming and helper functions.

## Step 1: Is it worth caching?

Cache only if all hold:
- Read much more often than it changes.
- Expensive, measured: slow aggregate, external API call, heavy render.
- Some staleness is acceptable, or every write path can invalidate it reliably.

Ask how stale is acceptable: "seconds", "until the next write", "an hour". That number drives the design.

## Step 2: Pick the layer

- **HTTP / CDN** (`Cache-Control`, `ETag`, `s-maxage`, `stale-while-revalidate`): public, identical-for-everyone responses and static assets. Never `public` on an authenticated response; use `private, no-store` for per-user data.
- **App cache** (Redis, memcached, framework cache around a function): expensive query results, computed summaries, third-party responses. You own keys and invalidation.
- **In-process memory** (LRU map, `functools.lru_cache`, framework local cache): per-process, so invalidation on write won't reach other workers or pods. Only for data that is fine stale until TTL.
- **Database**: materialized views, summary tables, denormalized counters. When the cost is aggregation over many rows.
- **Client** (TanStack Query, SWR, Apollo): avoid refetching on every mount. Set `staleTime` deliberately, and invalidate the right query keys after mutations (`queryClient.invalidateQueries({ queryKey: ["invoices", orgId] })`, `mutate(key)`).

## Step 3: Keys

- Namespace + version + every input that changes the result: `billing:v1:org:{orgId}:invoice-summary:{period}`.
- **Include the tenant/user** whenever data is scoped. A key without `orgId` for org-scoped data is a data leak.
- Bump the version segment when the cached value's shape changes, so old entries are ignored after deploy.
- Hash long inputs (filters, query strings) rather than putting them raw in the key.
- Client query keys follow the same rule: include user/org and every filter in the key array.

## Step 4: Invalidation

Pick one and write it down next to the cache code:
- **TTL only**: simplest. Fine when "stale for up to N minutes" is acceptable.
- **Delete on write**: in the code path that writes, after the transaction commits. Delete, don't set: the next read rebuilds from committed data. Find every write path (API, admin, jobs, imports, bulk updates) and cover each.
- **Versioned keys**: keep a per-org version counter in the key; increment it to drop everything for that org at once.

Always set a TTL as a backstop, even with explicit invalidation.

## Step 5: Stampedes and failures

- A hot key expiring under load makes every worker rebuild at once. Use a short lock (`SET key val NX EX 30`) so one worker rebuilds, serve stale while revalidating, or add TTL jitter.
- The cache going down must not take the app down. Wrap reads so a cache error falls through to the source, with a short client timeout. Check what the current client does on connection errors.
- Don't cache errors or empty results from a failed upstream call, or cache them for seconds only.

## Step 6: Write it up and test it

Design note in the PR:

```
Cache: invoice summary per org + period
Layer: app cache (Redis, existing client in src/lib/cache.ts)
Key: billing:v1:org:{orgId}:invoice-summary:{period}
TTL: 15 min backstop
Invalidation: delete on invoice create/update/void in invoice.service.ts, after commit
Stale tolerance: none after writes; 15 min for anything missed
```

Tests (follow `test-writer`; use an in-memory cache or a test Redis, cleared between tests):
- second call doesn't hit the source (query count 0, or the mock not called again)
- a write invalidates: next read returns the new value
- user/org A never gets B's cached value

## Rules

- Never cache per-user or per-org data under a key that doesn't include the user/org.
- Never mark an authenticated response `public` or let a CDN cache it without varying on auth.
- Measure the hit rate after shipping if you can. A cache with a low hit rate is just extra complexity.

Next: `test-writer` for the cache tests, `deploy-checklist` if this adds Redis or a CDN rule.
