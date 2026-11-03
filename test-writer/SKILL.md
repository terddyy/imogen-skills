---
name: test-writer
description: Write unit and integration tests for new or existing code in the repo's own style, using its test runner, fixtures or factories, and mocking approach. Covers happy paths, auth and tenant scoping, validation, state rules, side effects, and performance guards. Use when someone says "write tests", "add test coverage", "this needs tests", after building a feature, or when a ticket's acceptance criteria need tests.
---

# Test Writer

Tests that read like the acceptance criteria and survive refactors. Test behavior through public seams (endpoints, exported functions, components as a user sees them), not private helpers.

## Step 0: Read the stack

1. Detect the language and runner from the manifest and config: `vitest.config.*`/`jest.config.*`, `pytest.ini`/`pyproject.toml`, `go test`, `cargo test`, `rspec`, `phpunit.xml`, JUnit/`build.gradle`. Find the exact test command in package.json scripts, Makefile, or CI.
2. Read the shared setup: `conftest.py`, `setupTests.ts`, `test/helpers`, `spec_helper.rb`, `testutil` packages. Reuse its fixtures, authenticated clients, and DB reset instead of writing new ones.
3. Find how test data is built: factories (`factory_boy`, `fishery`, FactoryBot), builders, seed files, or plain literals. Add a new factory in the same file and style when you need one.
4. Open one existing test in the same module and copy its layout: file location and naming, `describe`/class vs flat functions, how auth is set up, how mocks are done.

If there are no tests yet, use the ecosystem default and say so before writing.

## Step 1: List the cases

From the ticket or the code, write the case list first:

- **Happy path**: one per acceptance criterion
- **Auth**: anonymous gets 401, wrong role gets 403, and **another tenant/account gets 404 (or 403) on someone else's record**. This is the test most often missing and the bug most often shipped.
- **Validation**: each required field missing, each value that breaks a rule
- **State rules**: can't void a void invoice, can't edit after lock
- **Side effects**: emails, queued jobs, webhooks, audit rows, events
- **Edge cases**: empty lists, zero, max length, time zones, concurrency where it matters
- **Performance guards** on list endpoints: query count or call count, if the repo already has a helper for it

Skip tests of the framework itself (that a max-length validator rejects long strings) unless it is an acceptance criterion.

## Step 2: Write them

Match the repo. A typical shape (vitest + supertest; pytest and Go read the same way):

```ts
describe("POST /api/invoices/:id/void", () => {
  it("lets an org admin void an issued invoice", async () => {
    const inv = await invoiceFactory.create({ status: "issued" });
    const res = await asAdmin(inv.orgId).post(`/api/invoices/${inv.id}/void`);
    expect(res.status).toBe(200);
    expect((await db.invoice.findUnique({ where: { id: inv.id } }))?.status).toBe("void");
  });

  it("returns 404 for an admin of another org", async () => {
    const inv = await invoiceFactory.create({ status: "issued" });
    const res = await asAdmin(await orgFactory.create()).post(`/api/invoices/${inv.id}/void`);
    expect(res.status).toBe(404);
  });

  it.each(["draft", "void"])("rejects voiding from %s", async (status) => {
    const inv = await invoiceFactory.create({ status });
    expect((await asAdmin(inv.orgId).post(`/api/invoices/${inv.id}/void`)).status).toBe(400);
  });
});
```

Use parametrized tests (`it.each`, `@pytest.mark.parametrize`, Go table tests) for input variations. For time, use what the repo has (`vi.useFakeTimers`, `freezegun`/`time-machine`, an injected clock); do not add a new library without asking.

Mock at the boundary only: outbound HTTP, payment and email providers, queues, the clock. Do not mock the database layer or the code under test. For UI components, query by role and label (Testing Library) and assert what the user sees.

## Step 3: Run and check

1. Run the new file, then the module's tests, then the full suite if it is reasonably fast. Paste the summary line.
2. Break the behavior on purpose for one or two tests and confirm they fail. Revert.
3. Check names say the behavior: `rejects voiding from draft`, not `test_void_2`.

## Rules

- Literal expected values. Never recompute the expectation the way the code does.
- No sleeps, no dependence on test order, no real network, no shared mutable state between tests.
- Never loosen or delete an existing test to make new code pass. If one fails, report it and ask.
- Run the tests before saying they pass.

Next: `e2e-tests` for full user journeys, `verify-done` before calling the work finished.
