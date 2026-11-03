---
name: code-quality
description: Review a branch before the PR on any stack - house style, hidden coupling, business logic in the wrong layer, test gaps, and a light security pass - with findings ranked so the dev fixes the important ones first. Points to security-audit when something needs a deeper look. Use when "ready to open a PR", "review my changes", "check this before I push", "is this good to merge", or as a reviewer on someone else's branch.
---

# Code Quality

Review the diff the way a senior reviewer on this team would, then fix what's real. Every finding is file:line, why it matters, and the fix.

## Step 0: Read the stack

Detect the stack from the manifests and find how this repo is meant to look: `CONTRIBUTING.md`, coding standards docs, ADRs, the repo map's "how we do X here" section (`../repo-map.md` or `docs/repo-map.md`), and neighbouring files that do the same kind of thing. A documented house rule beats the generic advice below.

## Step 1: Get the diff and the context

```bash
git fetch origin
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
```

Use the repo's default branch if it isn't `main`. Read the ticket, issue or PRD so you can check scope and acceptance criteria.

## Step 2: Run the tools first

Run whatever the repo has configured so review time isn't spent on what a tool catches: pre-commit hooks, the linter, formatter check, type checker, and the tests for the changed areas. Take the commands from package.json scripts, the Makefile or CI config (e.g. `npm run lint && npm run typecheck && npx vitest run <paths>`, `ruff check && mypy && pytest <paths>`, `go vet ./... && go test ./...`). Also run any schema or migration drift check the repo has. Report tool failures first.

## Step 3: Review in three passes

Keep the passes separate in the report.

**Pass 1: Design and hidden coupling**
- Business logic in the wrong layer: rules in route handlers, controllers, UI components, serializers or DB hooks instead of where this repo keeps them (service, domain module, use case).
- Hidden side effects: event listeners, ORM hooks, model `save` overrides or middleware that send emails, call APIs or write other tables, so the caller can't see them.
- Side effects before the transaction commits (job queued before the row exists).
- Reaching into another module's internals instead of its public API; new import cycles.
- The same rule copied to several places; magic strings where the repo has an enum or constant.
- New N+1 queries or per-row network calls in loops.
- Errors swallowed, or caught and logged with no handling.
- Scope creep against the ticket; acceptance criteria not met.

**Pass 2: Tests**
- Each acceptance criterion has a test. Error paths, permission and cross-tenant cases covered.
- Tests assert behavior, not implementation; the code under test isn't mocked.
- Tests follow the repo's existing test style and fixtures.

**Pass 3: Light security**
- New routes go through the repo's auth and permission layer; lookups by id are scoped to the caller's user/org.
- Input validated with the repo's schema tool; server-owned fields can't be set by the client.
- No string-built SQL or shell commands, no raw HTML sinks with user content, no secrets in code, tests or logs.
- Config changes that weaken security (debug on, CORS `*`, disabled CSRF).

Anything beyond a quick fix here (auth redesign, a dependency CVE, a pattern repeated across the repo) goes to `security-audit`.

## Step 4: Report, then fix

```
Design
  [Should fix] src/orders/routes.ts:40 discount rule computed in the handler; move to orders/pricing.ts like the other rules
Tests
  [Should fix] no test for a member role cancelling another user's order
Security
  [Must fix] src/orders/routes.ts:58 findById(req.params.id) has no org filter -> any user can cancel any org's order. Scope by session orgId.
Nits
  [Optional] ...
```

Levels: **Must fix** (security, data loss, broken behavior, failing checks), **Should fix** (design or test gaps a reviewer will flag), **Optional**. Ask the dev which to fix, fix them, re-run the tools and tests.

## Rules

- No finding without file:line and a concrete fix.
- Don't flag what the formatter owns, or pre-existing issues outside the diff (list those separately as "noticed, not in scope").
- Don't approve what you couldn't run; say what you couldn't verify.

Next: `pr-description`. For deeper security work, `security-audit`.
