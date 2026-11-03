---
name: test-first
description: Red-green-refactor TDD one vertical slice at a time on any stack. Write one failing test for one behavior, write the least code that passes it, refactor while green, repeat. Tests go through public interfaces, not internals. Detects the repo's test runner. Use when "do this TDD", "test first", "red-green-refactor", "write the test before the code", or when fixing a bug that should get a regression test first.
---

# Test First

One behavior at a time: a failing test, the least code that passes it, a cleanup, then the next behavior. Never write a pile of tests up front and then a pile of code.

## Step 0: Read the stack

1. Find the test runner and how this repo calls it: `package.json` scripts (`vitest`/`jest`), `pyproject.toml`/`pytest.ini` (`pytest`), `go test ./...`, `cargo test`. Check the README, `Makefile` and CI config for flags and env vars.
2. Learn how to run a single test file or test name fast, e.g. `vitest run path -t "name"`, `pytest path::test_name`, `go test ./pkg -run TestName`. You'll run it dozens of times.
3. Open two or three existing tests near the code you're changing. Copy their layout, fixtures, factories and naming.
4. Run the existing suite for that area once. If it's already red, stop and tell the dev before adding anything.

## Step 1: List behaviors, not tests

Write a short list of what the code must do, in the caller's words, ordered from simplest to hardest:

```
1. issuing a credit note for a paid invoice returns the note with status "issued"
2. amount above the invoice balance is rejected with a validation error
3. a user from another org gets 404
4. issuing twice with the same idempotency key returns the first note
```

Confirm the list with the dev. Pick the public interface the test will use: the HTTP endpoint, the exported function, the component as a user sees it. Not a private helper, not the ORM.

## Step 2: Red

Write one test for the first behavior on the list.

- Run it and watch it fail, and check it fails for the right reason (an assertion about the behavior, not an import error or typo).
- Assert on outcomes the caller can observe: return values, response status and body, rendered text, rows written. Not on which internal method was called.
- Mock only what crosses the process boundary (third-party HTTP, clock, email), and only the way the repo already mocks it.

## Step 3: Green

Write the least code that makes this test pass. Hard-coding is fine if the next test will force the real logic. Run the single test, then the file.

## Step 4: Refactor

With everything green, clean up: names, duplication, moving logic to where the house pattern puts it. Run the tests after each change. No new behavior in this step.

## Step 5: Repeat

Next behavior on the list, back to Step 2. If a new case shows up while coding, add it to the list instead of testing it now. When the list is done, run the whole suite plus the repo's lint and typecheck.

For a bug fix: the first test reproduces the bug and must fail on current code before you touch anything.

## Rules

- One failing test at a time. Never more than one red test in the working tree.
- A test that passed the first time it ran proved nothing. Break the code briefly to see it fail, or rewrite it.
- Test through public interfaces. If you need to reach into internals, the design probably wants a seam; mention it.
- Don't change a test and the code under it in the same step unless the behavior itself changed.
- Keep each cycle small enough that you're never more than a few minutes from green.

For tests around existing untested code, use `characterization-tests` first. For broader coverage after the feature exists, use `test-writer`. When done, `verify-done`.
