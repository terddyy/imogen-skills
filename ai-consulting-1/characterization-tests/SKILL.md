---
name: characterization-tests
description: Lock in what untested code currently does — including its quirks and bugs — before anyone changes it, so any behavior change shows up as a failing test. Use before refactoring or changing legacy/untested code, when someone is "scared to touch this", or after a regression to pin the area down.
---

# Characterization Tests

These tests don't check what the code *should* do. They record what it *does* do, today, so you can change it with a safety net. If the current behavior is a bug, the test still asserts the bug, with a comment. Fixing it is a separate, deliberate change.

## Step 1: Draw the boundary

Pick the highest seam that covers the code you're about to change and that you can call from a test:

- An API endpoint (best: covers serializer, view, permissions, queryset)
- A service function or model method
- A Celery task body (call the function directly, not `.delay`)
- A management command (`call_command`)

Write down the inputs that matter: user roles, object states, flags/settings, dates. Read the code for branches (`if`, `try`, early returns) and list one case per branch. That's your case list. Show it to the dev before writing tests.

## Step 2: Capture the current behavior

For each case: set up the state (factories / fixtures in the project's style), call the seam, and assert on *everything observable*:

- Return value / response status and full response body
- DB state afterwards (rows created, fields changed, rows *not* changed)
- Side effects: emails (`mailoutbox`), tasks queued (mock `.delay` / `.apply_async` at the boundary), outbound HTTP (mock the client or use `responses`/`respx`), signals fired, cache writes
- Errors raised and their messages
- Query count (`django_assert_num_queries`), if the change is perf-related

Don't guess the expected values. Run the code, look at what comes out, then paste it into the assertion. For big payloads, a snapshot is fine: store the JSON in `tests/snapshots/` and compare, but strip volatile fields (ids, timestamps) first or freeze time.

```python
@pytest.mark.django_db
def test_void_invoice_already_paid__characterization(api_client, paid_invoice):
    # Characterization: locks current behavior. Paid invoices can be voided and
    # NO refund is created. Looks like a bug (see ABC-130); don't fix here.
    resp = api_client.post(f"/api/invoices/{paid_invoice.id}/void/")
    assert resp.status_code == 200
    assert resp.json() == {"id": paid_invoice.id, "status": "void", "refund": None}
    assert Refund.objects.count() == 0
```

Name or mark them so they're findable: `__characterization` suffix or `@pytest.mark.characterization` (register the marker in `pytest.ini`/`pyproject.toml` if you add it).

## Step 3: Prove the net works

- All new tests pass against the current code, unchanged.
- Run them 2-3 times to catch flakiness (ordering, time, randomness). Fix the flakiness now.
- Sanity check: make one small deliberate change to the code under test and confirm at least one test fails. Revert it.
- Check coverage of the target file if `pytest-cov` is available: `pytest --cov=<module> --cov-report=term-missing <tests>`. Uncovered branches in the area you're about to change are gaps to fill.

## Step 4: Hand off

List: what's covered, what isn't, and the suspected bugs you locked in (with tickets). Commit the tests on their own, before any behavior change, so the next diff only shows the intended change. Then on to `safe-change` or whatever the route was.

## Rules

- Never change production code in this step. Not even "obvious" fixes.
- When the refactor later changes a characterization test, that must be a deliberate, reviewed decision, called out in the PR.
