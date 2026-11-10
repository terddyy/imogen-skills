---
name: jira-build
description: Implement a Jira ticket end to end on any stack, with UI that matches the ticket's mockups as close to pixel-perfect as possible. Pulls the full ticket (description, comments, every attached image, design links), labels each image, turns the targets into a measured spec, reuses existing code, checks what the change affects, then builds and compares screenshots against the mockups until they match. Use when someone says "build ABC-123", "implement this ticket", "do this Jira", or pastes a Jira key or link.
---

# Jira Build

The ticket is the spec, and its images are the source of truth for the UI. Done means a designer comparing mockup and screenshot side by side can't find a difference. Building a layout from the description text alone is the failure this skill prevents.

## Step 0: Read the stack

Detect the stack from the manifests (`package.json` + lockfile, `pyproject.toml`, `go.mod`, `Gemfile`, ...) and find the dev, test and lint commands (README, `Makefile`, package scripts, CI). Find the styling system and its tokens: Tailwind config, CSS variables, theme file, SCSS variables, component library.

## Step 1: Pull the whole ticket, then label the images

Get all of it: summary, description, acceptance criteria, type, labels; **every attachment** (inline images in the description are attachments too); comments, newest first (a later designer or PO comment overrides the description, so note which comment changed what); linked issues, subtasks and parent epic (the epic often holds the design link); design links (Figma, Zeplin, Loom, Drive).

1. **Atlassian MCP:** get the issue, then download its attachments with the server's attachment tool.
2. **REST**, if `JIRA_URL`, `JIRA_EMAIL` and `JIRA_API_TOKEN` are set (never ask for a token in chat, never print it):
   ```bash
   curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" "$JIRA_URL/rest/api/3/issue/ABC-123?fields=summary,description,attachment,comment,issuelinks,subtasks,parent&expand=renderedFields"
   curl -sL -u "$JIRA_EMAIL:$JIRA_API_TOKEN" "$JIRA_URL/rest/api/3/attachment/content/<id>" -o "<dir>/<filename>"
   ```
   `renderedFields.description` is HTML, and inline images reference attachments by filename, so you can tell which image belongs to which paragraph.
3. **Neither:** ask the dev to paste the ticket text and drop every image into the chat or a folder.

Save images outside the repo (a temp folder) or in a path listed in `.git/info/exclude`; they're client material. If there's a Figma link and a Figma MCP is connected, pull the frame's design context: exact values beat estimates from a PNG. **If the ticket has UI work and you can't see its images, stop and ask for them.**

Label every image from its filename, the text around it, the comment it came in, and what it shows:
- **Target:** clean design or Figma export, "should look like". Spec it (Step 2) and match it (Step 7).
- **Current:** screenshot of the live app, often on a bug ("currently", browser chrome, real data). Never copy it. Reproduce the problem, then confirm it's gone.
- **Annotated:** arrows, circles, boxes, strike-throughs, notes. Each mark is a separate requested change; the marks aren't part of the UI.
- **Context:** flow diagram, error, log, data sample, competitor reference. Read it for behavior, not pixels.

Current + Annotated means "this screen with these changes": spec unmarked areas from the screenshot, marked areas from the notes. Tell the dev your labels. If you can't tell target from current, ask; building the bug back in is worse than asking.

## Step 2: Turn the mockups into a spec

Write a short spec per Target (and Current + Annotated) image; Step 7 checks against it. Annotated marks become a numbered change list.

- **Viewport:** image width gives design width. 2880 or 2560 wide is usually 1440 or 1280 at 2x; divide every measurement by the scale.
- **Regions** top to bottom. Per region: layout, sizes, spacing, typography (family, size, weight, line height, case), colors, borders, radius, shadow, icons, and the **exact copy**.
- **States** shown: hover, active, disabled, empty, loading, error, selected. A state that obviously exists but isn't shown is a question, not something to design.
- **Breakpoints:** match the ones with mockups; the rest must not break. Ask how they should look.

Figma gives exact numbers. From a PNG, measure pixels; if Pillow is already installed, sample colors with `python -c "from PIL import Image; print(Image.open('m.png').convert('RGB').getpixel((x,y)))"`. Don't install tools for this without asking.

**Snap every value to the project's tokens.** `#1F2937` one shade off `gray-800` is `gray-800`; a 15px gap in an 8px system is 16px. A raw value is a deviation the dev confirms. If text and image, or two images, disagree, list it and ask.

## Step 3: Inventory what to reuse

Before writing code, search for what exists for each region and piece of logic: UI primitives (buttons, inputs, modals, tables, badges, layout shells, icons, empty states), client logic (API client, data hooks, formatters, validators, permission checks, enums), backend (services, queries, handlers). Search by name and by behavior: component name, CSS class, endpoint path. Open the closest existing screen and copy how it's built.

```
Region / need          Reuse                          Action
Page header            components/PageHeader.tsx      as is
Status pill            components/Badge.tsx           add "void" variant
Invoice summary card   (none)                         new: components/billing/InvoiceSummary.tsx
```

Reuse first, extend second (new prop or variant), create last. New shared pieces go where the project keeps them, named like their neighbours. Follow the styling system: no inline styles, no hard-coded colors where a token exists. Keep logic out of UI components the way the codebase already does.

## Step 4: Check what it affects

- Backend changes (schema, endpoints, jobs, events): run `impact-analysis`.
- Each shared component, hook or helper you'll modify: `rg` for its import and list the pages that render it. Changing its default look changes all of them, so prefer an opt-in variant.
- Changed API responses: every consumer that reads them (`cross-repo-change`, `contract-tests` for other repos).
- Tests, stories and visual snapshots that cover the area. Use real file paths and page names, never "might affect other screens".

## Step 5: Show the plan, then wait

Briefly: the ticket in 1-2 lines plus any overriding comment, the image labels, the spec (or where it's saved) with token deviations and open questions, the reuse table, what it affects, and the files to create or touch. Wait for a go, with open questions answered or a placeholder agreed.

## Step 6: Build

- Backend: follow `feature-build`, or `safe-change` if it changes something other code depends on.
- Frontend: build region by region against the spec and the reuse table. For the visual pass use `ui-polish` (or `impeccable` if installed), held to the mockup, not to taste.
- Behavior tests the way the project writes them (`test-writer`). Leave pixels to Step 7; don't assert CSS values unless the project already does. Every acceptance criterion maps to a test or a checked screenshot.

## Step 7: Compare against the mockups until they match

1. Run the app with the repo's dev command. Seed data and copy so the screen shows what the mockup shows; differences should come from code, not data.
2. Set the viewport to the design width and screenshot with what's available: a Playwright or Chrome DevTools MCP, Claude in Chrome, or the project's Playwright (`npx playwright screenshot --viewport-size=1440,900 <url> out.png`). Save it next to the mockup as `<name>.actual.png`.
3. Compare region by region against the spec: layout and order, sizes and spacing, typography, colors, borders, radius, shadows, icons, copy character for character. Trigger each state shown (hover, modal open, empty, error) and screenshot it. Check numbers with computed styles (`getComputedStyle`, DevTools), not by eye.
4. Fix every difference and re-screenshot. Stop when nothing is left but what you can't fix (font not available locally, longer real data), or after 5 rounds, and report what's left.
5. If the project already has visual diffing (Playwright `toHaveScreenshot`, Percy, Chromatic), run it too. Don't add one without asking. If a run writes new baseline images, delete them before committing unless the dev asked for them, and then the dev commits them by hand.
6. Breakpoints with mockups must match; the rest must not break. Current images: repeat the original steps and confirm the problem is gone. Annotated: check each numbered change and screenshot its area.

## Step 8: Report

```
ABC-123 Void invoice
AC1 admin can void a draft: done (invoice-void.test.ts)    AC2 grey "Void" badge: done (screenshot matched)
Images: invoice-detail.png (target) matches; void-modal.png (target) matches except local font fallback;
        list-bug.png (current+annotated) 3/3 changes done, bug no longer reproduces
Reused: PageHeader, Badge (+ void variant), ConfirmDialog    New: components/billing/InvoiceSummary.tsx
Affects: Badge on 6 pages, variant is opt-in; Invoices and Payments checked
Open: empty state not in mockups, used existing EmptyState, needs design sign-off
```

Next: `verify-done`, then `code-quality` and `pr-description`. Don't commit the mockup or screenshot images. Give the dev their outside-repo paths to upload to the PR or ticket.

## Rules

- No UI work without seeing the ticket's images. Label each one before using it; only targets are matched, and a current-state screenshot is never copied.
- The mockup beats your taste: no redesigns, renamed labels or extra elements. Raise suggestions as questions.
- When text, images and comments disagree, ask. Newer designer or PO comments override older content.
- Never fork a component to tweak it, and never change a shared component's default look for one ticket.
- Never report UI as done without a screenshot comparison at the mockup's width.
- Don't commit downloaded attachments. Never print or commit Jira credentials.
- Implementation screenshots, recordings and QA or validation notes never go in git. Capture outside the repo, stage by explicit path, check `git diff --cached --name-status`, and delete captures you made before committing. To share one, give the dev its outside-repo path to upload to the PR or ticket.
