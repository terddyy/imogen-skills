---
name: imogen-fix-issues
description: Fix a GitHub issue end to end — make sure it's agent-ready, implement it test-first at agreed seams, review the diff against standards and spec, then commit (and PR). Use when a junior dev (or an agent) is picking up an existing issue to actually build and ship it.
---

# Imogen Fix Issues

Companion to `imogen-issue` (which *creates* issues). This skill *closes* them: take an existing GitHub issue and turn it into a working, reviewed, committed change.

Pipeline: **make it agent-ready (if it isn't already) → implement test-first → review the diff → commit / open PR.**

## Step 0 — Is this issue actually ready to build?

Not every issue arriving in GitHub is ready to implement. Check:

- Does it have a clear "what to build" and acceptance criteria (i.e. did it come out of `imogen-issue` / `/to-tickets`, or is it tagged something like `ready-for-agent`)?
- Or is it a raw, unfiltered report/request (a user complaint, a vague feature ask, no acceptance criteria)?

**If it's raw, triage it first** — don't guess at scope:

1. Read the full issue (body, comments, labels, author, dates). Explore the codebase for context, using the project's glossary (`CONTEXT.md`) and respecting any ADRs in the area.
2. Check for **redundancy** — search whether the requested behavior already exists (by domain concept, not just the issue's wording). If it's already implemented, say so, point to where, and stop — don't implement it again.
3. **Verify the claim.** For a bug: reproduce it from the reporter's steps before touching code. For a vague ask: note what's unverified.
4. If the issue needs fleshing out, run a short interview to sharpen it — pin down fuzzy terms, confirm scope, confirm acceptance criteria — and post a summary comment back on the issue capturing what was established, so the record stays on GitHub.
5. Only once scope and acceptance criteria are clear, treat the issue as agent-ready and move to Step 1.

If the issue can't be resolved without human judgment calls, external access, or manual testing — say so and stop; don't force an implementation.

## Step 1 — Confirm seams, then implement test-first

Before writing any code:

- State the seams (public interfaces) this change will be tested at. Prefer existing seams over new ones — the fewer, the better, one is ideal.
- Confirm the seams match the issue's intent.

Then work in **vertical slices**, one at a time:

- **Red before green** — write the failing test first, then only enough code to pass it. No speculative features, no anticipating future tests.
- **One slice at a time** — one seam, one test, one minimal implementation per cycle.
- Tests verify behavior through public interfaces, not implementation details — a good test reads like a spec and survives refactors.
- Avoid anti-patterns: implementation-coupled tests (mocking internals, reaching around the interface), tautological assertions (expected value computed the same way the code does), and horizontal slicing (writing all tests before any implementation).
- Refactoring happens at the review stage, not mid-loop.

While implementing:

- Run typechecking and the relevant single test file regularly.
- Run the full test suite once at the end.
- Match the project's domain vocabulary from `CONTEXT.md` and respect ADRs in the touched area.

## Step 2 — Review the diff

Once the implementation is green, review the changes since the branch point along two axes, run as separate passes so neither masks the other:

- **Standards** — does the diff follow this repo's documented coding standards (`CODING_STANDARDS.md`, `CONTRIBUTING.md`, etc.)? On top of anything documented, check against the baseline code-smell list: Mysterious Name, Duplicated Code, Feature Envy, Data Clumps, Primitive Obsession, Repeated Switches, Shotgun Surgery, Divergent Change, Speculative Generality, Message Chains, Middle Man, Refused Bequest. A documented repo standard always overrides the baseline; skip anything tooling already enforces.
- **Spec** — does the diff faithfully implement what the issue asked for? Check for: requirements missing or partial, behavior added that wasn't asked for (scope creep), and requirements that look implemented but are wrong. Cite the issue's acceptance criteria for each finding.

Report both sets of findings clearly (don't merge/rerank them), fix anything real before moving on.

## Step 3 — Commit and open the PR

- Commit the work to a branch, with a message that references the issue (`Fixes #<n>` / `Closes #<n>`).
- Push and open a PR against the repo's default branch, linking the issue in the description so it closes automatically on merge.
- Do not close or edit the original issue directly — let the PR merge do that.
