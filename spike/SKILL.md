---
name: spike
description: Build a throwaway prototype that answers one design question fast (which UI variant, what API shape, which library, is this fast enough), in an isolated branch or folder with a timebox, then write down what was learned and delete or promote it. Never merged as-is. Use when "let's try it quickly", "will this library work", "can this even be fast enough", "mock up two options", "prototype this", or when a grill-plan question can only be answered by trying it.
---

# Spike

Answer one question with the least code possible, then throw the code away. The output is the learning note, not the prototype.

## Step 0: Read the stack

Detect the stack from the manifests (package.json + lockfile, pyproject.toml / requirements*.txt, go.mod, Cargo.toml, Gemfile, composer.json, pom.xml / build.gradle, *.csproj) and the run commands from README / Makefile / package.json scripts. The spike should run the same way the app does, so the answer applies to the real thing.

## Step 1: Pin the question

Write it down before any code, and get the dev to agree:

```
Question: Can we render the 5k-row orders table under 200ms with react-virtual?
Done when: measured render time on 5k rows from the staging fixture
Timebox: 2 hours
Out of scope: styling, auth, error states, tests
```

One question per spike. If there are two, run two spikes. A question with no "done when" is not ready.

## Step 2: Isolate it

Pick one, and say which:

- Branch: `spike/<short-name>` off main. Never open a PR from it into main.
- Folder: `spikes/<short-name>/` (or `scratch/`, `playground/` if the repo already has one). Add it to `.gitignore` if the dev does not want it committed.
- Separate sandbox for library trials: a fresh minimal project with only that dependency, so it doesn't touch the main lockfile.

Do not add dependencies to the main project's manifest for a spike without the dev's OK.

## Step 3: Build the shortest path to the answer

- Hardcode data, skip validation, inline everything. Speed over quality is the point here.
- For UI variants, build them side by side behind a query param or a toggle so the dev can compare in one screen.
- For API shape, write the handler stub and a client call that uses it; the client side usually decides the shape.
- For perf, measure with the same data volume as production and record the numbers (e.g. `hyperfine`, `pytest-benchmark`, `go test -bench`, browser Performance panel).
- Check the timebox. At the limit, stop and write up what you have, even if the answer is "unknown, because X".

## Step 4: Write the learning note

Save to `docs/spikes/YYYY-MM-DD-<short-name>.md` (or the repo's existing spot):

```
# Spike: react-virtual for orders table
Question: render 5k rows under 200ms?
Answer: Yes. 140ms median (10 runs, M1, staging fixture). Default table: 2.3s.
How: spike/orders-virtual @ 3f2a1c9 (delete after 2026-11-17)
Gotchas: sticky header needs a wrapper; row height must be fixed.
Recommendation: adopt; ticket the real build with fixed row heights.
Not tested: keyboard nav, screen readers.
```

## Step 5: Delete or promote

- Delete: remove the folder or branch once the note is saved. Confirm with the dev first.
- Promote: start a fresh branch and rebuild the chosen option properly with tests. Copy ideas, not files.

## Rules

- Never merge spike code into main as-is. No exceptions for "it already works".
- One question, one timebox, one note.
- Numbers or it didn't happen for perf spikes.
- Spike code does not need tests or lint; the real build does.

Next: `adr` if the answer settles a design decision, then `feature-build` or `test-first` for the real build, or `jira-tickets` to ticket it.
