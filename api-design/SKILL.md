---
name: api-design
description: Design a new HTTP, GraphQL or RPC API, or change an existing one, so it matches the endpoints the repo already has. Covers resource naming, request/response shapes, errors, pagination, versioning, idempotency, auth and backwards compatibility, and writes the contract (OpenAPI, GraphQL schema, .proto) first when the repo keeps one. Use when "add an endpoint for", "what should this API look like", "design the API for this ticket", "change this response", "review this endpoint", or before building anything another team or client will call.
---

# API Design

Decide the shape before anyone writes a handler. A consistent, boring API that looks like the rest of the repo beats a clever one.

## Step 0: Read the stack

1. Find the API style and framework: REST routes (Express, FastAPI, DRF, Rails, Spring, Gin), GraphQL (`schema.graphql`, resolvers, codegen config), RPC (`*.proto`, tRPC routers).
2. Find the contract, if the repo keeps one: `openapi.yaml`/`openapi.json`, generated docs (drf-spectacular, FastAPI `/openapi.json`, springdoc), `schema.graphql`, `proto/`. Note whether it is hand-written (contract first) or generated from code.
3. Read the repo map (`../repo-map.md` or `docs/repo-map.md`) for who consumes this API: web app, mobile, partners, other services.

## Step 1: Learn the house conventions

Open three or four existing endpoints near yours and write down what they do:

- **Paths and names**: plural nouns (`/invoices/{id}`), kebab or snake case, nesting depth, action routes (`POST /invoices/{id}/void`) vs state fields.
- **Field casing**: `camelCase` or `snake_case`, id format (int, UUID, prefixed), timestamp format (ISO 8601 UTC), money (integer minor units or decimal string).
- **Envelope**: bare object, or `{ data, meta }`. How lists are wrapped.
- **Errors**: status codes used, and the body shape (`{ error: { code, message, details } }`, RFC 9457 problem+json, GraphQL `errors[].extensions.code`).
- **Pagination**: cursor or offset, param names (`cursor`/`limit`, `page`/`page_size`), where next-page info lives.
- **Filtering and sorting**: param style (`?status=paid`, `?filter[status]=paid`, `?sort=-created_at`).
- **Auth**: how the caller is identified, how permissions and tenant scoping are checked.
- **Versioning**: `/v1/` in the path, a header, or none.

If two conventions coexist, ask the dev which one is current. Don't add a third.

## Step 2: Draft the contract

Write the shape in the repo's own format: an OpenAPI path, a GraphQL type and field, a proto message. If there is no contract file, write a short spec in the ticket:

```
POST /v1/invoices/{invoiceId}/credit-notes
Auth: bearer; caller must be billing-admin in the invoice's org
Headers: Idempotency-Key (required)
Body: { "amountCents": 1500, "reason": "damaged" }
201: { "id": "cn_123", "invoiceId": "inv_9", "amountCents": 1500, "status": "issued", "createdAt": "..." }
400 validation_error  amountCents <= 0 or above invoice balance
403 forbidden         caller not billing-admin
404 not_found         invoice missing or in another org (don't leak existence)
409 conflict          same Idempotency-Key, different body
```

Check the draft against these:

- Every list is paginated with a max page size.
- Creates and payment-like actions that clients may retry accept an idempotency key, or are naturally idempotent (`PUT`).
- Errors use the house shape, with a stable machine-readable `code`, and never leak stack traces or other tenants' data.
- Input is validated with the repo's validator; unknown fields are rejected or ignored the way existing endpoints do.
- Responses list fields explicitly. No dumping the DB row (internal columns, secrets, other users' data).
- Breaking vs additive: adding an optional field or endpoint is additive. Removing or renaming a field, changing a type, tightening validation, or changing a status code is breaking and goes through `safe-change` and `cross-repo-change`.

## Step 3: Review with the dev, then hand off

Show the draft and the conventions you matched. Get a yes before code. Then:

- Commit the contract file change first (or with the first slice), so generated clients and docs update.
- Hand the build to `feature-build`.
- Have `contract-tests` pin the agreed shape so drift fails CI.

## Rules

- Match the existing API before any style guide, including ones you prefer.
- Never break a published field, status code or error code in place.
- Don't expose ids or existence of another tenant's resources: return 404, not 403, for rows the caller can't see, unless the repo does otherwise.
- Record any lasting decision (new versioning scheme, new error shape) with `adr`.
