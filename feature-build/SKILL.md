---
name: feature-build
description: Build a feature end to end in the repo's house style on any stack. Finds the closest existing feature, mirrors its layers (schema, data access, business logic, handler or UI component, validation, auth, routes, tests) and ships it in small vertical slices that each end green. Use when "build this ticket", "add an endpoint for", "add a page for", "scaffold this", "implement this feature", or "how would we add X here".
---

# Feature Build

Build the feature the way this codebase already builds features. The most common review complaint is not a bug, it's "we don't do it like that here". Copy house style first and invent nothing.

## Step 0: Read the stack

1. Detect the stack from manifests: `package.json` (+ lockfile for npm/pnpm/yarn/bun), `pyproject.toml`/`requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `pom.xml`/`build.gradle`, `*.csproj`.
2. Find the real commands for test, lint, format, typecheck and build in the README, `Makefile`, `package.json` scripts or CI config. Use those, not the defaults you'd guess.
3. Read the repo map if there is one (`../repo-map.md` or `docs/repo-map.md`), especially any "how we do X here" section. Verify it against the code; it can be stale.

## Step 1: Find the closest existing feature

Pick the feature most like yours (same module if possible, a similar resource or screen otherwise) and trace it top to bottom. Note, for each layer it has:

- **Schema / model**: ORM model, Prisma schema, SQL migration, GraphQL type. Base class, id type, timestamps, soft delete.
- **Data access**: repository, query module, selectors, or the ORM called directly from handlers.
- **Business logic**: service functions, use cases, model methods, or inline in handlers.
- **Entry point**: controller, route handler, resolver, CLI command, or UI component and its data hook.
- **Validation**: Zod, Pydantic, class-validator, DRF serializer, struct tags. Where it runs.
- **Auth / permissions**: middleware, decorators, policy objects, and how queries are scoped to the user, org or tenant.
- **Wiring**: router registration, DI container, module exports, nav entries, feature flags.
- **Tests**: location, runner, fixtures/factories, how the API or component is exercised.

Tell the dev in 4-6 bullets which feature you're mirroring and what you'll copy. If two patterns coexist (legacy and new), ask which one is current.

## Step 2: Plan the files

List every file you'll create or touch before writing any code:

```
src/invoices/credit-note.schema.ts     + CreditNote input/output schemas
prisma/schema.prisma                   + model CreditNote (migration generated)
src/invoices/credit-note.service.ts    + issueCreditNote()
src/invoices/credit-note.routes.ts     POST /credit-notes, GET /credit-notes
src/app.ts                             register routes
src/invoices/credit-note.test.ts
```

Stop and reroute if the change touches something other code depends on: a shared model, a public endpoint, a response shape, another repo. Use `impact-analysis`, then `safe-change` or `cross-repo-change`. For a new or changed API shape, run `api-design` first. For schema changes, follow `db-migrations`.

## Step 3: Build in vertical slices

Each slice cuts through every layer it needs and ends with tests green. Use `test-first` for the loop inside each slice.

1. **Schema.** Generate the migration with the repo's tool and read the SQL it produces (`db-migrations`). Index the columns you'll filter or sort on.
2. **Create path.** Tests for happy path, validation error and permission denied, then validation, service, handler, route.
3. **Read path.** List and detail, including "a user can't see another tenant's rows". Paginate lists the way existing lists do. Check the query count on the list and fix N+1s now.
4. **Update / delete** if in scope, same pattern.
5. **UI** if in scope: copy the nearest similar screen's component, data fetching, form and error handling. Loading, empty and error states.
6. **Wiring and docs**: routes, nav, OpenAPI/GraphQL schema, changelog if the repo keeps one.

## Step 4: Check before handing off

- The repo's lint, format, typecheck and full test commands for the touched area, then the whole suite if it's fast.
- No missing migrations (e.g. `prisma migrate diff`, `makemigrations --check`, `alembic check`).
- Run it once for real: hit the endpoint or click through the screen.

Then hand off to `verify-done`, `code-quality`, then `pr-description`.

## Rules

- Mirror the closest feature. A new pattern needs a reason the dev agrees with.
- Every query in a handler is scoped to what the caller may see. No unscoped "find all" behind an API.
- Explicit auth on every new route, even when it matches the default.
- Validate input at the boundary with the repo's validator. Never pass raw request bodies to the ORM (mass assignment).
- No business logic in handlers or UI components. Put it where the house pattern puts it.
- Side effects (emails, jobs, webhooks) run after the transaction commits.
- No new dependencies without asking.
