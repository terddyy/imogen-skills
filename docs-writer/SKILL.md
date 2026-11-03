---
name: docs-writer
description: Write or update a README, API docs, how-to guides, or inline docstrings in the style the repo already uses, and verify every command, path and code example against the repo before writing it down. Use when "update the README", "document this endpoint", "write setup instructions", "add docstrings", "the docs are out of date", or after a feature changes how something is run or called.
---

# Docs Writer

Docs that are wrong are worse than no docs. Write only what you have checked against the repo, in the format the repo already uses.

## Step 0: Read the stack and the existing docs

1. Detect the stack from manifests (package.json + lockfile, pyproject.toml / requirements*.txt, go.mod, Cargo.toml, Gemfile, composer.json, pom.xml / build.gradle, *.csproj). This decides the package manager and run commands you will write down.
2. Find the real commands: package.json `scripts`, Makefile / justfile / Taskfile targets, CI config (`.github/workflows/`, `.gitlab-ci.yml`), Dockerfile / compose files.
3. Find where docs live and how they look: README.md, `docs/`, a docs site (mkdocs.yml, docusaurus.config.*, VitePress), OpenAPI files (`openapi.yaml`, generated from code?), CONTRIBUTING.md.
4. Docstrings: check what the repo uses (JSDoc/TSDoc, Google / NumPy / reST style in Python, GoDoc comments) and how much. Match it. If the repo has none, do not add them everywhere.

## Step 1: Scope the change

Ask, or infer from the ticket: who reads this (new dev, API consumer, ops) and what they need to do after reading it. Pick the doc type:

- README: what it is, how to run it locally, how to test, where to go next.
- How-to: one task, numbered steps, start state and end state.
- API reference: endpoint/function, inputs, outputs, errors, one example.
- Docstring: what it does, args, return, raises / errors, only the non-obvious parts.

If the API docs are generated from code (OpenAPI from annotations, typedoc, Sphinx autodoc), edit the source annotations, not the generated output.

## Step 2: Verify before writing

For every item you are about to write:

- Commands: run them, or confirm they exist in scripts / Makefile / CI. `npm run dev` is wrong if the repo uses pnpm.
- Paths and file names: confirm they exist.
- Env vars: confirm they are read in the code (grep) and in `.env.example`. Never copy real values.
- Code examples: run them or write them as a test. At minimum, check every function name, argument and import against the source.
- API examples: field names and status codes from the actual handler or schema, not from memory.

Anything you could not verify gets marked for the dev: `<!-- unverified: needs staging creds -->`, and listed in your reply.

## Step 3: Write it

- Lead with what the reader does. Setup steps as a numbered list with copy-pasteable commands.
- Short sections, plain headings, one example per concept.
- Update, don't append: remove or fix the outdated text instead of adding a "new way" section under it.
- Link to code, ADRs and other docs rather than repeating them.

Example report back:

```
Updated README.md: setup (pnpm, not npm), new STRIPE_WEBHOOK_SECRET env var, test command.
Verified: pnpm install, pnpm dev, pnpm test (all ran clean).
Unverified: deploy section (needs prod access), left a marker at README.md:88.
```

## Rules

- Never document a command, flag, path or env var you have not checked in the repo.
- Match the repo's existing tone, heading style and docstring format.
- No secrets, tokens or internal URLs that are not already in the repo.
- Don't document the obvious. A docstring that repeats the function name adds nothing.

Next: `commit-message` for the docs change, or `pr-description` if it goes with a feature PR.
