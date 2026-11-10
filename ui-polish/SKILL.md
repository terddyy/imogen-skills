---
name: ui-polish
description: Clean up a screen that works but looks off - spacing, alignment, visual hierarchy, typography, color contrast, empty/loading/error states, responsiveness and small layout bugs - using the repo's existing design system, tokens and CSS framework, then check it in a browser with before/after screenshots. Use when "this page looks messy", "make it look nicer", "the spacing is off", "it breaks on mobile", "QA says the layout is weird", or before a client demo.
---

# UI Polish

Make an existing screen look finished without redesigning it. Keep the product's look; fix what's inconsistent, cramped, unclear or broken.

If `impeccable` is installed, prefer its commands: `critique` or `audit` to find issues, `polish` to fix them, `typeset`/`layout`/`harden` for the specific areas. If `ui-ux-pro-max` is installed, use it when you need palette, font pairing or design-system choices. Otherwise follow the steps below directly.

## Step 0: Read the stack

Find the UI framework (React, Vue, Svelte, Angular, server templates, Flutter) and the styling system: Tailwind config, CSS variables/tokens file, a component library (shadcn/ui, MUI, Chakra, Vuetify, Bootstrap), CSS Modules or styled-components. Find the spacing scale, type scale, color tokens and breakpoints. Read 2-3 screens the team considers "good" and match them. Check `DESIGN.md` or a Storybook if present.

## Step 1: Look before touching

1. Start the app with the repo's dev command (README, `package.json` scripts, Makefile). Log in as a user with realistic data.
2. Screenshot the target at 375px, 768px and 1280px+ wide (browser tools, Playwright `page.screenshot`, or DevTools device mode). Save them outside the repo as the "before".
3. Also capture the states: empty (no data), loading (throttle the network), error (block the API call), long content (long names, 200 rows, long translations).

## Step 2: List the issues

Walk the screen and write a short list, each item tied to a file:

- **Spacing**: values off the scale (`margin: 13px`, `mt-[17px]`), uneven gaps between siblings, cramped padding in cards and tables.
- **Alignment**: edges that almost line up, labels and inputs on different baselines, icons off-center against text.
- **Hierarchy**: everything the same weight, two competing primary buttons, the page title not clearly the largest thing.
- **Typography**: sizes and weights outside the type scale, lines wider than ~75 characters, inconsistent casing in headings and buttons.
- **Color and contrast**: hard-coded hex instead of tokens, text below 4.5:1 (3:1 for large text and UI borders), meaning carried by color alone.
- **States**: no empty state, a spinner that shifts layout, raw error text or none, disabled buttons with no reason, missing hover/focus styles.
- **Responsive**: horizontal scroll at 375px, tables that overflow, tap targets under 24x24px, fixed heights that clip text.

## Step 3: Fix with the system

- Use existing tokens, utility classes and components only. No new colors, font sizes or spacing values unless the scale has a real gap; if it does, add the token in the theme file, not inline.
- Reuse the repo's existing empty/loading/error components; if none exist, build one small component and use it here.
- Keep changes in the presentation layer. No business logic moves, no API changes.
- Small diffs per area. Don't reformat files you aren't fixing.

## Step 4: Verify in the browser

- Re-take the screenshots at the same widths and states. Compare before/after side by side.
- Check keyboard focus is still visible and tab order still makes sense.
- Run the repo's lint, typecheck, unit and visual/snapshot tests; update snapshots only for intended changes.

Report shape:

```
Screen: /settings/billing
Fixed: card padding to scale (p-6), one primary action, empty state for no invoices,
       table scrolls inside its container at 375px, muted text 3.1:1 -> 4.8:1 (text-muted-foreground)
Screenshots: before/after at 375, 768, 1280
Left alone: header nav spacing (shared layout, needs its own ticket)
```

## Rules

- Polish, not redesign. If the fix needs a new visual direction, stop and ask.
- No inline styles and no one-off values when a token exists.
- Never claim it looks right without a screenshot at mobile and desktop width.
- Implementation screenshots, recordings and QA or validation notes never go in git. Capture outside the repo, stage by explicit path, check `git diff --cached --name-status`, and delete captures you made before committing. To share one, give the dev its outside-repo path to upload to the PR or ticket.
- Don't touch shared layout components for one screen's problem without checking every screen that uses them.

Next: `accessibility-audit` for a full WCAG pass, `e2e-tests` or `verify-done` before the PR.
