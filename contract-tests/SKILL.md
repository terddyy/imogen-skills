---
name: contract-tests
description: Guard API responses, webhook payloads and queue/event messages that other repos or external consumers depend on, so a change that would break a consumer fails CI first. Uses OpenAPI/GraphQL schema diffing, schema snapshot tests, or consumer-driven contracts (Pact) when the team already runs them. Use when an endpoint or event is consumed by another repo, during a cross-repo change, or when someone asks "how do I make sure I don't break the frontend / the mobile app / the other service".
---

# Contract Tests

A contract says: these fields, with these types and values, are promised to consumers. Adding fields is fine. Removing, renaming, or changing the type of a promised field fails the test, and the message names who will break.

## Step 0: Read the stack

1. Detect the provider's language and test runner from its manifest and CI config. Contract tests run in the normal test command, so use that runner.
2. Look for what already exists: an OpenAPI file (`openapi.yaml`, `swagger.json`) or a generator (`drf-spectacular`, `springdoc`, `swag`, `@nestjs/swagger`, `fastapi` built-in), a GraphQL schema file, JSON Schema / Zod / Pydantic models for events, `pact/` folders or a Pact broker URL in CI. Extend what is there.
3. Read the Connections section of `repo-map.md` (parent folder) or `docs/repo-map.md` if present, and verify against code.

## Step 1: Find the contracts

List every endpoint, webhook, and event another repo or external client consumes (`impact-analysis` gives you this). For each one, search the consumer code for the field names it reads. The contract is what consumers use, not everything the provider returns.

## Step 2: Pick the lightest approach that fits

**A. Schema diff** (repo has or can generate OpenAPI/GraphQL schema). Generate in CI, compare to the committed copy, fail on breaking changes only:

```bash
npm run openapi:generate                  # or the repo's generator command
oasdiff breaking main-openapi.yaml openapi.yaml --fail-on ERR
# GraphQL: npx graphql-inspector diff schema.main.graphql schema.graphql
```

Cheap and wide, but only as accurate as the annotations behind the schema.

**B. Shape tests in the provider repo** (default). One file per consumed resource, e.g. `tests/contracts/invoice.contract.test.ts`, calling the real endpoint or producer function:

```ts
// Consumers: web-app (src/api/invoices.ts), reporting (exports/invoices.py)
const InvoiceContract = z.object({
  id: z.number(),
  number: z.string(),
  status: z.enum(["draft", "issued", "paid", "void"]),
  total: z.string(),             // decimal as string
  issuedAt: z.string().datetime().nullable(),
}).passthrough();                // extra fields are allowed

it("GET /api/invoices/:id keeps its contract", async () => {
  const res = await request(app).get(`/api/invoices/${invoice.id}`);
  const parsed = InvoiceContract.safeParse(res.body);
  expect(parsed.success, JSON.stringify(parsed.error?.issues)).toBe(true);
});
```

Same idea in Python with a Pydantic model or `jsonschema`, in Go by decoding into a `map[string]any` and checking each promised key and type. Cover detail, list (the pagination envelope too), the error body shape, and every enum consumers branch on. Make nullability explicit so a field turning nullable is a decision.

**C. Consumer-driven (Pact)** only when the team already runs Pact or a broker. Consumers publish pacts, the provider verifies them in CI (`pact-provider-verifier` or the language binding). Do not introduce Pact for one endpoint.

**Events and webhooks**: build the payload with the real producer code and validate it the same way as B. If the repo has a schema registry (Avro, Protobuf), run its compatibility check instead.

## Step 3: Wire it into CI

1. Confirm the contract tests run in the provider's normal test job. Run them once locally and paste the output.
2. For schema diff, commit the baseline schema and document the regenerate command next to it.
3. Leave a short note in each consumer repo pointing at the provider's contract file, so consumer devs know where to add fields they start reading.

## Step 4: When a contract test fails

That is the point. Either the change is a mistake, or it is intentional and goes through `safe-change` and `cross-repo-change`: expand (add the new field to the contract), consumers move over and deploy, then contract (remove the old field from the API and the contract in the same PR).

## Rules

- Every contract file names its consumers and where in their code the fields are read.
- Never "fix" a failing contract test by deleting the assertion in a PR that is not explicitly a contract change.
- Keep contracts to fields consumers use. Asserting every field makes every change a contract change, and people start ignoring the failures.
- No new dependency (oasdiff, Pact, schema libs) without the dev's OK; prefer what the repo has.

Next: `safe-change` or `cross-repo-change` when a contract has to move, `api-design` for new endpoints.
