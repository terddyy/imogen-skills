---
name: commit-message
description: Write conventional-commit messages (type(scope): description) from the staged diff, matching the repo's recent commit style, and propose splitting into several commits when the diff mixes concerns. Never commits unless the dev asks. Use when "write a commit message", "what should I call this commit", "commit this", "split this into commits", or after finishing a change.
---

# Commit Message

Read the diff, match how this repo already writes commits, and say what changed and why in one line. Suggest a split when one commit is doing two jobs.

## Step 1: Read the repo's style

1. `git log --oneline -20` and `git log -5 --format=%B` for full bodies.
2. Note: conventional commits or not, which types and scopes are used (folder, package, app name), ticket IDs (`ABC-123:` prefix, `(#123)` suffix, or in the body), tense and case, body length.
3. Check for commitlint / commitizen config (`commitlint.config.*`, `.czrc`, `package.json` `commitlint` key) or a CONTRIBUTING.md section. Those rules win.
4. If the history is mixed or empty, default to `type(scope): description`, lowercase, imperative, no period, under 72 characters.

## Step 2: Read the diff

1. `git diff --staged --stat` and `git diff --staged`. If nothing is staged, read `git status` and `git diff` and say that nothing is staged.
2. Work out what changed and why: read the touched code, not just the diff lines. The why often lives in the ticket or the branch name (`git branch --show-current`).
3. Types: feat, fix, docs, style, refactor, test, chore (plus perf, build, ci if the repo uses them). Breaking change: `!` after the type and a `BREAKING CHANGE:` footer.

## Step 3: Split if it mixes concerns

Propose separate commits when the diff contains more than one of: a feature, a bug fix, a refactor, formatting-only changes, dependency bumps, unrelated files. Show the plan and the commands:

```
1. refactor(billing): extract tax calc into TaxService
   git add src/billing/tax.ts src/billing/invoice.ts
2. fix(billing): round tax per order instead of per line
   git add -p src/billing/tax.ts   # the rounding hunk only
3. test(billing): cover per-order rounding
   git add tests/billing/tax.test.ts
```

Keep each commit buildable when possible. Formatting churn goes in its own commit so the real change is reviewable.

## Step 4: Write the message

```
fix(billing): round tax per order instead of per line

Per-line rounding drifted up to 0.04 on orders with many lines,
which failed reconciliation with the payment provider.

Refs: ABC-412
```

- Subject: what changed, from the reader's side. "fix login redirect loop", not "update auth.ts".
- Body only when the why is not obvious from the subject: the reason, the tradeoff, what was ruled out. Wrap at 72.
- Footer: ticket refs and breaking changes in the repo's format.

## Step 5: Commit only if asked

Print the message(s) and stop. Run `git commit` only when the dev says to. When they do, use a heredoc or `-F` for multi-line messages, and never add `--no-verify`. If a hook fails, show the error and fix the cause.

## Rules

- Never commit, amend or push without the dev asking.
- Match the repo's history over these defaults.
- No AI attribution or co-author lines unless the repo or the dev asks for them.
- Don't describe files; describe the change. Don't pad the body.

Next: `pr-description` when the branch is ready to open.
