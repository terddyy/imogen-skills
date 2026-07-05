---
name: overnight-task-runner
description: Organize and execute major feature or task requests end-to-end while the user is away. Use when the user describes a large coding task, feature, bug cluster, repo cleanup, integration, migration, or production-ready change and wants an AI agent to break it into a clear task plan, work autonomously, verify the result, commit, and push to the repository.
---

# Overnight Task Runner

Use this skill when the user gives a major repo task and expects the agent to finish without frequent check-ins. Optimize for safe autonomy: understand the current system, make a scoped execution plan, implement in small verified steps, and leave the repo pushed with a useful summary.

## Operating Rules

- Treat the repository as shared with other agents or humans. Inspect status before editing, preserve unrelated changes, and never revert work you did not make.
- Confirm the real git root, package/app root, active branch, and remotes before planning.
- For production-like systems, credentials, VPS, databases, or deployed services, default to read-only inspection unless the user explicitly approved that specific write action.
- Prefer the smallest correct implementation that completes the task. Reuse existing patterns before adding dependencies or abstractions.
- Keep working until the task is complete, blocked by a real external dependency, or unsafe to continue.

## Workflow

1. **Define Done**
   - Restate the objective as concrete acceptance criteria.
   - Identify required deliverables: code, tests, migration, docs, screenshots, build artifact, deployment, commit, or push.
   - If the request is too vague to execute safely, make the smallest reasonable assumption and state it.

2. **Map The Repo**
   - Run `git status --short`, `git rev-parse --show-toplevel`, `git branch --show-current`, and `git remote -v`.
   - Locate the relevant app/package root, scripts, tests, environment examples, and existing implementations.
   - Read the current files that own the behavior before editing.

3. **Plan The Work**
   - Create a short checklist with ordered phases.
   - Split large work into vertical slices that can each be verified.
   - Name risky areas early: data changes, auth, billing, external APIs, background jobs, platform config, or production access.

4. **Execute**
   - Edit only the files needed for the current slice.
   - After each meaningful slice, run the smallest useful check before moving on.
   - If a test/build failure appears, trace the root cause instead of patching only the visible symptom.
   - Keep notes of commands run and important results for the final summary.

5. **Verify**
   - Run the repo's relevant formatter, linter, typecheck, tests, build, smoke test, or browser/app check.
   - For UI work, verify the rendered result when practical instead of relying only on code review.
   - If a required check cannot run, record the exact reason and the closest completed substitute.

6. **Commit And Push**
   - Re-check `git status --short` and review the diff.
   - Stage only intended files.
   - Commit with a concise message that names the completed task.
   - Push to the configured upstream or the target remote/branch requested by the user.
   - If push fails for auth, branch protection, or network reasons, leave the commit local and report the exact blocker.

## Final Report

Keep the handoff short and operational:

- What changed.
- What checks passed.
- Commit hash and pushed branch.
- Any unresolved blocker, skipped item, or follow-up that matters.
