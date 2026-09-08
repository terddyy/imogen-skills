---
name: imogen-issue
description: Turn an idea into GitHub issues junior developers can pick up and implement. Interviews you to sharpen the idea (keeping CONTEXT.md/ADRs up to date), synthesizes it into a buildable spec, then splits the spec into tracer-bullet tickets with blocking edges and publishes them as GitHub issues.
---

# Imogen Issue

You do the planning. Your juniors get GitHub issues they can execute against and PR from. This skill runs the full pipeline: **interview → spec → tickets**.

The issue tracker is assumed to be GitHub unless the user says otherwise. If no GitHub repo/remote is configured, ask for it before publishing anything.

## Step 1 — Sharpen the idea (interview)

Run a relentless interview to pressure-test the idea before anything gets written down as a spec. Don't let vague answers pass — push on:

- What problem is this actually solving, and for whom?
- What does success look like, concretely?
- What's explicitly out of scope?
- Where are the fuzzy or overloaded terms? Pin down the vocabulary (this becomes the project's glossary).
- Are there decisions here that are hard to reverse? If so, they deserve an ADR (Architecture Decision Record).

As you go, maintain two files in the repo (create them if they don't exist):

- **`CONTEXT.md`** — a running glossary of domain terms used consistently across the project. Update it whenever a term gets clarified or a new one is introduced.
- **`docs/adr/NNNN-<slug>.md`** — one file per hard-to-reverse decision (format: Title, Status, Context, Decision, Consequences). Only create one when a decision genuinely warrants it — not for every choice made.

Keep this whole step in **one unbroken context window** — don't compact until the tickets are published in Step 3, so the interview, spec, and tickets all build on the same thinking.

If a question can't be settled in conversation (it needs a runnable answer — state, business logic, a UI you have to see), say so explicitly and suggest the user prototype it before continuing, rather than guessing.

## Step 2 — Synthesize into a spec

Once the interview has converged, do NOT keep asking questions — synthesize what you now know into a spec.

1. Explore the repo (if you haven't already) to understand current state. Use the glossary vocabulary from `CONTEXT.md` throughout, and respect any ADRs in the area being touched.
2. Sketch the seams at which this feature will be tested. Prefer existing seams over new ones, and the highest seam possible — fewer seams is better, one is ideal. Confirm these match the user's expectations before moving on.
3. Write the spec using the template below.

<spec-template>

## Problem Statement

The problem the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list, each in the form:

1. As an `<actor>`, I want `<feature>`, so that `<benefit>`

This list should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

Modules to be built/modified, their interfaces, technical clarifications, architectural decisions, schema changes, API contracts, specific interactions. No specific file paths or code snippets — they go stale fast. Exception: a prototype snippet that encodes a decision more precisely than prose (state machine, reducer, schema, type shape) can be inlined, noted as coming from a prototype, trimmed to just the decision-rich part.

## Testing Decisions

What makes a good test here (external behavior, not implementation details), which modules will be tested, and any prior art for similar tests already in the codebase.

## Out of Scope

What this spec explicitly does not cover.

## Further Notes

Anything else worth recording.

</spec-template>

## Step 3 — Split into tracer-bullet tickets and publish as GitHub issues

Break the spec into **tickets** — vertical, tracer-bullet slices, each declaring the other tickets that **block** it.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer.
- A completed slice is demoable or verifiable on its own.
- Each slice is sized to fit in a single fresh context window (small enough for one junior dev sitting to implement and PR).
- Any prefactoring needed to make the change easy is its own ticket, done first: "make the change easy, then make the easy change."

</vertical-slice-rules>

**Wide refactors are the exception.** A wide refactor (rename a shared column/symbol, blast radius across the whole codebase) can't be sliced vertically — sequence it as expand → migrate (batched by blast radius, each batch its own ticket) → contract, each stage blocked by the previous.

**Quiz the user before publishing.** Present the proposed breakdown as a numbered list, each with:

- **Title**
- **Blocked by** (or "None — can start immediately")
- **What it delivers** — the end-to-end behaviour this ticket makes work

Ask: does the granularity feel right, are the blocking edges correct, should anything merge or split? Iterate until approved.

**Publish to GitHub.** Once approved, create one GitHub issue per ticket, in dependency order (blockers first), using the template below. Use GitHub's native "blocked by" / sub-issue linking where available; otherwise reference blocking issues by number in the body. Apply a `ready-for-agent` (or equivalent) label if the repo uses one — these tickets should be grabbable as-is by a junior dev with no further triage needed.

<issue-template>

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective — not a layer-by-layer implementation list.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

A reference to each blocking issue, or "None — can start immediately".

</issue-template>

No specific file paths or code snippets in the issue body unless they come from a prototype and encode a decision precisely (state machine, schema, type shape) — trim to just that part.

Do not close or modify any pre-existing parent issue this ticket set was derived from.
