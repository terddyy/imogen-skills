---
name: e2e-tests
description: Write end-to-end tests for critical user journeys through the real app, in a browser (Playwright, Cypress, or whatever the repo uses) or against the running API. Stable selectors, seeded data, no fixed sleeps, headless in CI, traces and screenshots on failure. Use when someone says "add an e2e test", "test the whole flow", "test signup/checkout/login end to end", "the e2e tests are flaky", or before a release that touches a key journey.
---

# E2E Tests

A few tests that walk the journeys the business cannot afford to break, the way a user would. Not a second copy of the unit tests.

## Step 0: Read the stack

1. Look for an existing e2e setup: `playwright.config.*`, `cypress.config.*`, `e2e/` or `tests/e2e/`, `wdio.conf.*`, Selenium/Capybara specs, or API suites (supertest, `httpx` + pytest, Postman/Newman, Hurl). Use it. Copy its folder layout, fixtures, page objects, and login helper.
2. Find how the app starts for tests: the `webServer` block in the Playwright config, a `docker-compose.test.yml`, a `start:test` script, or the CI job. Find how data is seeded: seed script, factories behind a test-only endpoint, DB fixtures, or API calls in `beforeEach`.
3. No e2e setup at all? Propose Playwright for web apps (or the API runner the repo already uses for backend-only) and get the dev's OK before adding the dependency.

## Step 1: Pick the journeys

List 3-8 critical journeys, not every screen: sign up, log in, the main create/edit flow, checkout or payment, permissions on the most sensitive page. For each, write the steps and the one outcome that proves it worked ("order shows as Paid on /orders"). Confirm the list with the dev. Edge cases and validation belong in `test-writer`.

## Step 2: Make data and auth deterministic

- Each test creates the data it needs (API call, seed helper, factory endpoint) with unique values, e.g. `user-${Date.now()}@test.local`. No test depends on another test's leftovers or on order.
- Log in once and reuse the session (Playwright `storageState` in a setup project, `cy.session` in Cypress). Only the login journey itself goes through the login form.
- Stub only third parties you cannot run (payment provider, email) at the network layer (`page.route`, `cy.intercept`) or use their sandbox. Never stub your own backend in an e2e test.

## Step 3: Write the test

```ts
test("member can create and submit an expense", async ({ page, seed }) => {
  const { project } = await seed.projectWithMember();
  await page.goto(`/projects/${project.id}/expenses`);
  await page.getByRole("button", { name: "New expense" }).click();
  await page.getByLabel("Amount").fill("42.50");
  await page.getByLabel("Category").selectOption("Travel");
  await page.getByRole("button", { name: "Submit" }).click();
  await expect(page.getByRole("row", { name: /42\.50.*Submitted/ })).toBeVisible();
});
```

- Selectors, in order: role + accessible name, label, `data-testid`. Never CSS classes, DOM position, or generated ids. Add a `data-testid` to the app code only when no accessible handle exists.
- Waiting: rely on auto-waiting assertions (`expect(...).toBeVisible()`, `cy.contains`) or wait for a specific response (`page.waitForResponse`). Never `waitForTimeout`, `cy.wait(2000)`, or `sleep`.
- One journey per test, asserting the user-visible outcome. A page object or helper is fine when 3+ tests share the steps.

## Step 4: Run it like CI

1. Headless, from a clean state: `npx playwright test e2e/expenses.spec.ts`, `npx cypress run --spec ...`, or the repo's script.
2. Run it 5 times in a row (`--repeat-each=5` in Playwright) and with parallel workers. Any failure is flakiness to fix now, not later.
3. Confirm the config keeps evidence on failure: Playwright `trace: "on-first-retry"`, `screenshot: "only-on-failure"`, `video: "retain-on-failure"`; Cypress screenshots and videos on. Retries at most 1-2 in CI, and a retried pass still gets looked at.
4. Make sure CI runs it: headless, the app started by the config or compose file, artifacts (trace, screenshots) uploaded on failure.

## Rules

- No fixed sleeps. No order-dependent tests. No shared accounts that tests mutate.
- Never point e2e tests at production data or send real emails or payments.
- A flaky test is a bug. Fix it or quarantine it with a ticket; do not just raise the retry count.
- Report the exact command and output of the passing runs.

Next: `verify-done` before calling it finished, `ci-fix` if the CI run fails, `accessibility-audit` if role selectors are hard to find.
