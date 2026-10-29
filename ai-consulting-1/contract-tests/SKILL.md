---
name: contract-tests
description: Guard API responses (and webhook/queue payloads) that other repos depend on, so a backend change that would break a consumer fails CI first. Use when an endpoint is consumed by another repo, during a cross-repo change, or when someone asks "how do I make sure I don't break the frontend/the other service".
---

# Contract Tests

A contract test says: "these fields, with these types, are promised to consumers." Adding fields is fine. Removing, renaming, or changing the type of a promised field fails the test, and the failure message tells you who will break.

## Step 1: Find the contracts

From the repo map's Connections table and `impact-analysis`, list the endpoints and payloads another repo consumes. For each, find which fields the consumer actually reads: search the consumer repo for the field names. The contract is what consumers use, not everything the endpoint returns.

## Step 2: Pick the approach

Use the lightest one that fits; check what the project already has first.

**A. Schema-diff on OpenAPI** (project uses drf-spectacular or drf-yasg)
Generate the schema in CI, compare to a committed copy, fail on breaking changes:

```bash
python manage.py spectacular --file openapi.yml --validate
git diff --exit-code openapi.yml   # or use oasdiff for "breaking only": oasdiff breaking old.yml openapi.yml --fail-on ERR
```

Good coverage for little effort, but only as accurate as the serializers' annotations.

**B. Pytest contract tests in the provider repo** (default)
One test module per consumed resource, in `tests/contracts/`:

```python
# tests/contracts/test_invoice_contract.py
# Consumers: web-app (src/api/invoices.ts), reporting-service (exports/invoices.py)
INVOICE_CONTRACT = {
    "id": int,
    "number": str,
    "status": str,
    "total": str,          # decimal serialized as string
    "issued_at": str,      # ISO 8601
    "customer": dict,
}
INVOICE_STATUSES = {"draft", "issued", "paid", "void"}

@pytest.mark.django_db
def test_invoice_detail_contract(api_client, invoice):
    body = api_client.get(f"/api/invoices/{invoice.id}/").json()
    for field, typ in INVOICE_CONTRACT.items():
        assert field in body, f"'{field}' removed; consumers: web-app, reporting-service"
        assert isinstance(body[field], typ), f"'{field}' changed type"
    assert body["status"] in INVOICE_STATUSES
```

Cover: detail, list (including pagination envelope: `count`, `next`, `results`), the error format (400 body shape), and enum values consumers switch on. Null-able fields: assert `typ | None` explicitly so a field turning nullable is a decision.

**C. Consumer-driven (Pact)** only if the team already runs a Pact broker. Don't introduce it for one endpoint.

**Webhook / queue payloads**: same as B, but build the payload with the real producer function and assert on its shape.

## Step 3: Wire it into CI

- Make sure the contract tests run in the provider's normal test command (they're just pytest).
- Optional but useful: a short note in the consumer repo pointing at the provider's contract file, so consumer devs know where to add fields they start depending on.

## Step 4: Changing a contract

When a contract test fails, that's the point. Either the change is a mistake, or it's intentional and goes through `safe-change` + `cross-repo-change`: expand (add the new field to the contract), consumers switch, then contract (remove the old field from the contract in the same PR that removes it from the API).

## Rules

- Each contract file names its consumers and where in their code the fields are read.
- Never "fix" a failing contract test by deleting the assertion in a PR that isn't explicitly a contract change.
- Keep contracts to fields consumers use; asserting every field makes every change a contract change and people start ignoring the failures.
