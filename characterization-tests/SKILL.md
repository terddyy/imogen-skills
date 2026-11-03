---
name: characterization-tests
description: Lock in what untested code currently does, quirks and bugs included, before anyone changes it, so any behavior change shows up as a failing test. Works with whatever test runner the repo uses. Use before refactoring or changing legacy or untested code, when someone says "I'm scared to touch this", "there are no tests for this", "pin this down before we refactor", or after a regression to fence the area in.
---

# Characterization Tests

These tests record what the code does today, not what it should do. If today's behavior is a bug, the test asserts the bug and says so in a comment. Fixing it is a separate, deliberate change.

## Step 0: Read the stack

1. Find the manifest (`package.json` + lockfile, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`/`build.gradle`, `*.csproj`, ...) and the test command (package.json scripts, Makefile, CI config, README).
2. Open one existing test near the code you will cover. Copy its runner, file naming, fixture/factory style, and how it mocks things. If the repo has no tests at all, use the ecosystem default (`vitest`/`jest`, `pytest`, `go test`) and tell the dev you are adding the first ones.
3. If `repo-map.md` (parent folder) or `docs/repo-map.md` exists, read the entry for this area, then check it against the code.

## Step 1: Draw the boundary

Pick the highest seam that covers the code you are about to change and that a test can call:

- An HTTP endpoint or route handler (covers validation, auth, data access together)
- A public service function, class method, or exported module function
- A CLI command or job/worker body (call the handler directly, not through the queue)

Read the code for branches (`if`, `switch`, `try/catch`, early returns, feature flags) and list one case per branch. Note the inputs that matter: roles, record states, config/env values, dates, locale. Show the case list to the dev before writing tests.

## Step 2: Capture the current behavior

For each case, set up state the way the repo already does, call the seam, and assert on everything observable:

- Return value, or status code plus the full response body
- Data afterwards: rows created, fields changed, and rows that were not changed
- Side effects at the boundary: emails, queued jobs, outbound HTTP, events published, cache or file writes (mock or record them with the repo's existing tools)
- Errors thrown and their messages
- Query or call counts, if the coming change is about performance

Do not guess expected values. Run the code, read what comes out, paste it into the assertion. For large payloads use the runner's snapshot support (`toMatchSnapshot` in jest/vitest, `syrupy` or a committed JSON file in pytest, golden files in Go) and strip or freeze volatile fields (ids, timestamps, random values) first.

```ts
// Characterization: paid invoices can be voided and no refund is created.
// Looks like a bug (ABC-130). Do not fix here.
it("voids a paid invoice without a refund [characterization]", async () => {
  const res = await request(app).post(`/api/invoices/${paid.id}/void`);
  expect(res.status).toBe(200);
  expect(res.body).toEqual({ id: paid.id, status: "void", refund: null });
  expect(await db.refund.count()).toBe(0);
});
```

Make them findable: a `characterization` tag, marker, or name suffix, whichever the runner supports and the repo already uses.

## Step 3: Prove the net works

1. All new tests pass against the current code, untouched.
2. Run them 3 times (or with random order if the runner supports it) to catch flakiness from time, ordering, or shared state. Fix it now.
3. Break the code on purpose in one small way and confirm at least one test fails. Revert.
4. Check coverage for the target file if the repo has a coverage tool (`vitest --coverage`, `pytest --cov=<module> --cov-report=term-missing`, `go test -cover`). Uncovered branches in the area you will change are gaps to fill.

## Step 4: Hand off

Report what is covered, what is not, and each suspected bug you locked in (with a ticket key if one exists). Commit the tests on their own, before any behavior change, so the next diff shows only the intended change.

## Rules

- Never change production code in this skill. Not even obvious fixes.
- Assert literal values you observed, never values recomputed the way the code computes them.
- When a later change breaks a characterization test, updating it is a deliberate decision that gets called out in the PR.

Next: `safe-change` or `refactor-plan` for the change itself, `test-writer` for tests of the new behavior.
