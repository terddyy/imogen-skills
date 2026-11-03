---
name: refactor-plan
description: Turn a refactor you want to do into an ordered list of tiny commits, each one shippable on its own and each keeping the tests green. Locks current behavior with characterization tests first when coverage is thin, and can publish the plan as a GitHub issue or Jira ticket. Use when "I want to refactor this", "how do I split this up safely", "this module needs restructuring", "plan the refactor", or after improve-architecture picks a design.
---

# Refactor Plan

A refactor changes structure, not behavior. Plan it as a chain of small steps where every step leaves main working, so you can stop or roll back at any point.

## Step 0: Read the stack

Detect the stack from the manifests and find the repo's test, lint and type-check commands (README, Makefile, package.json scripts, CI config). Read the repo map if present (`../repo-map.md` or `docs/repo-map.md`) and check it against the code.

## Step 1: Pin the goal

Get from the dev, in one or two sentences each:
- **Now:** how the code is shaped today and what hurts (with file paths).
- **Target:** the shape you want. If it came from `improve-architecture`, use that interface.
- **Out of scope:** what stays as it is.
- **Constraint:** deadline, freeze, other people working in the same files.

If the target is vague ("clean this up"), stop and agree on a concrete end state first.

## Step 2: Check the safety net

1. Find the callers of the code you will move (`grep`, IDE references, or `impact-analysis` when there are many or they span repos).
2. Run the existing tests for that area and note what they cover. Check coverage if the repo has it (`vitest --coverage`, `pytest --cov=<pkg>`, `go test -cover`).
3. If the behavior you're about to move isn't tested, the first commits are `characterization-tests`. No structural change until the current behavior is pinned.

## Step 3: Cut the steps

Each step is one commit (or one small PR) that:
- does one kind of move: extract, rename, move, inline, introduce an interface, switch callers, delete dead code;
- keeps the build, the type check and every test green;
- doesn't mix in behavior changes or new features;
- can be reverted alone.

Useful orderings:
- **Add the new next to the old, move callers, delete the old** (see `safe-change` for anything other code or other repos depend on).
- **Extract first, improve later:** move code as-is, then change it in the next step.
- **One caller at a time** when the callers are many or risky.
- **Delete last,** in its own step, after a search shows no callers remain.

## Step 4: Write the plan

```
Refactor: split OrderService into pricing + fulfilment
Safety net: tests/orders/* cover create/cancel; pricing untested -> step 1

1. test: characterization tests for OrderService.price()          risk: none
2. refactor: extract Pricing module, OrderService delegates to it  risk: low
3. refactor: move 3 pricing callers in api/ to Pricing             risk: low
4. refactor: move checkout caller to Pricing                       risk: med (hot path)
5. refactor: remove pricing methods from OrderService              risk: low
Check after each: npm test && npm run typecheck
Stop point: after step 3 the code is better even if we pause here
```

Mark any step that needs a deploy or a feature flag. Get the dev to confirm the plan before writing code.

## Step 5: Publish (optional)

If the dev wants it tracked, post the plan as a GitHub issue (`gh issue create --title ... --body-file plan.md`) or a Jira ticket (Atlassian MCP if connected, else the REST API with JIRA_URL / JIRA_EMAIL / JIRA_API_TOKEN, else give the dev the text to paste). For many steps, `imogen-issue` or `jira-tickets` can split them into tickets.

## Rules

- No step that leaves tests red, even for one commit.
- Structure and behavior change in separate commits. If you find a bug mid-refactor, note it and fix it in its own commit.
- Steps small enough that a reviewer can check one in a few minutes.
- If a step turns out bigger than planned, split it and update the plan instead of pushing through.

Next: implement the steps one at a time, then `code-quality` and `pr-description`.
