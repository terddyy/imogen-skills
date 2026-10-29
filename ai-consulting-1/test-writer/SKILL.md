---
name: test-writer
description: Write pytest-django tests for new or existing Django/DRF code in the project's own style — API tests, permission and scoping tests, service tests, query-count guards. Use when someone asks to "write tests", "add test coverage", after building a feature, or when a ticket's acceptance criteria need tests.
---

# Test Writer

Tests that read like the acceptance criteria and survive refactors. Test behavior through public seams (API endpoints, service functions), not private helpers.

## Step 1: Match the project

Before writing anything, read:

- `pytest.ini` / `pyproject.toml` / `setup.cfg` for pytest settings, markers, `DJANGO_SETTINGS_MODULE`
- Every `conftest.py` from the root down to the app: reuse its fixtures (`api_client`, `user`, `org`, authenticated clients) rather than making new ones
- Factories (`factories.py`, `factory_boy`) or fixtures/baker. Use what exists; add a factory for a new model in the same file style
- One existing test file in the same app: naming, class vs function style, how auth is set up

If the project uses Django `TestCase` instead of pytest, follow that instead; everything below translates.

## Step 2: Decide what to test

From the ticket or the code, list cases before writing:

- **Happy path** per acceptance criterion
- **Permissions**: anonymous (401), wrong role (403), and **cross-tenant**: a user from another org/account gets 404 (or 403, whatever the project does) on another org's object. This is the test most often missing and the bug most often shipped.
- **Validation**: each required field missing, each invalid value that has a rule
- **State rules**: can't void a void invoice, can't edit after lock, etc.
- **Side effects**: emails, tasks queued, webhooks, audit rows
- **Query count** on list endpoints

Skip tests for Django/DRF itself (that `CharField(max_length=10)` rejects 11 chars) unless it's an acceptance criterion.

## Step 3: Write them

```python
import pytest
from django.urls import reverse

pytestmark = pytest.mark.django_db


class TestVoidInvoice:
    def url(self, invoice):
        return reverse("invoice-void", args=[invoice.id])

    def test_org_admin_can_void_issued_invoice(self, admin_client_for, invoice_factory):
        invoice = invoice_factory(status="issued")
        resp = admin_client_for(invoice.org).post(self.url(invoice))
        assert resp.status_code == 200
        invoice.refresh_from_db()
        assert invoice.status == "void"

    def test_member_cannot_void(self, member_client_for, invoice_factory):
        invoice = invoice_factory(status="issued")
        resp = member_client_for(invoice.org).post(self.url(invoice))
        assert resp.status_code == 403

    def test_other_org_gets_404(self, admin_client_for, invoice_factory, org_factory):
        invoice = invoice_factory(status="issued")
        resp = admin_client_for(org_factory()).post(self.url(invoice))
        assert resp.status_code == 404

    @pytest.mark.parametrize("status", ["draft", "void"])
    def test_cannot_void_from(self, status, admin_client_for, invoice_factory):
        invoice = invoice_factory(status=status)
        resp = admin_client_for(invoice.org).post(self.url(invoice))
        assert resp.status_code == 400


def test_invoice_list_query_count(admin_client_for, org, invoice_factory, django_assert_max_num_queries):
    invoice_factory.create_batch(20, org=org)
    with django_assert_max_num_queries(6):
        admin_client_for(org).get(reverse("invoice-list"))
```

Useful pytest-django pieces: `pytestmark = pytest.mark.django_db`, `settings` fixture to override settings, `mailoutbox`, `django_assert_num_queries` / `django_assert_max_num_queries`, `django_capture_on_commit_callbacks` (to run `on_commit` hooks in tests). Time: use whatever the project has (`freezegun`, `time-machine`); don't add a new one without asking.

Mock at the boundary only: outbound HTTP, payment providers, `.delay()`. Don't mock the ORM or the code under test.

## Step 4: Run and check

- Run the new file, then the app's tests, then the full suite if reasonable.
- Each new test should fail if you break the behavior it covers. Spot-check one or two by temporarily breaking the code.
- Test names say the behavior: `test_member_cannot_void`, not `test_void_2`.

## Rules

- No assertions that recompute the expected value the same way the code does. Use literal expected values.
- No sleeping, no dependence on test order, no real network.
- Don't loosen an existing test to make new code pass. If an existing test fails, report it and ask.
