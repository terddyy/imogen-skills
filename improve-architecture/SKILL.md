---
name: improve-architecture
description: Find places where the code would get simpler by making a module deeper - shallow modules with wide interfaces, leaky abstractions, one rule scattered across layers, code that is hard to test - and propose the 2 or 3 best candidates ranked by payoff. Then design the chosen one with the dev, interface first, and hand it to refactor-plan. Use when "this codebase is a mess", "where should we refactor", "this is hard to test", "every change touches five files", "improve the architecture", or before a big feature lands in a tangled area.
---

# Improve Architecture

Look for modules that make callers do too much work. The goal is fewer, deeper modules: small interfaces that hide a lot, so changes stay local and tests stay simple.

## Step 0: Read the stack

Detect the stack from the manifests and learn the repo's layout and layers (routes/controllers, services, data access, UI, jobs). Read the repo map if present (`../repo-map.md` or `docs/repo-map.md`) and any ADRs (`docs/adr/`, `docs/decisions/`), then check them against the code. Respect decisions already recorded unless the dev wants to revisit them.

## Step 1: Scope

Ask what prompted this: a painful area, an upcoming feature, a test that's hard to write, or a general review. Narrow to one area or one flow if you can. A whole-repo pass on a large codebase gives shallow results.

## Step 2: Gather evidence

- **Churn and coupling:** `git log --since=6.months --name-only --format= | sort | uniq -c | sort -rn | head -20` shows hot files. Files that always change together in the same commits are coupled.
- **Shallow modules:** files or classes whose public surface is nearly as big as their body, pass-through layers that only forward calls, interfaces with many small methods that callers must call in a set order.
- **Leaky abstractions:** callers that need to know internal details (DB column names, HTTP status codes, cache keys, retry rules) to use a module.
- **Scattered logic:** the same business rule or status check in several places (`grep` for the magic string or condition); validation split between UI, API and DB with differences.
- **Hard-to-test seams:** tests that need heavy mocking, a real DB or network for logic that is pure, or long setup to reach one branch.

## Step 3: Propose 2 or 3 candidates

Rank by payoff (pain removed, how often the area changes) against cost (callers to move, risk). For each:

```
1. Pricing rules spread across cart, checkout and invoice (High payoff, Medium cost)
   Evidence: discount logic in cart/total.ts:30, checkout/apply.ts:88, invoices/build.ts:112; 9 of the last 20 bug fixes touched two of these
   Deepen into: one pricing module, interface price(cart, customer) -> PriceBreakdown
   Wins: one place to change rules; pure function, testable without DB
   Cost: 7 callers; checkout is a hot path
```

Let the dev pick one. Don't design all three.

## Step 4: Design the chosen one, interface first

1. Write the interface before any implementation: names, inputs, outputs, errors, what the caller no longer needs to know.
2. Show two or three real call sites rewritten against it. If the callers don't get simpler, the design is wrong.
3. Sketch one alternative interface (smaller, or split differently) and compare them with the dev.
4. Decide where the seam goes for tests: what's pure, what's injected, what stays at the edge.
5. Record the decision with `adr` if it changes how the team should build things in this area.

## Rules

- Every candidate cites files and lines. "This feels messy" isn't evidence.
- Don't propose a new layer, pattern or framework when moving code into an existing module would do.
- No code changes in this skill. Output is the ranked list and the agreed interface.
- Match the repo's existing conventions for module layout and naming.

Next: `refactor-plan` with the agreed interface; `characterization-tests` first if the area is untested.
