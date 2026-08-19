# Portable NixOS Readiness Report — Design System

## 0. Research Log

- Embedded references: shortlisted Notion, Linear, and Stripe → picked `minimalist-skill.md` + `notion.md` because this is a long operational document whose hierarchy must feel like a warm, precise engineering notebook rather than a product landing page.
- Design architecture: loaded `design-system-architecture.md`, the frontend design router, perfection rules, and designpowers Lane C review contract.
- Lazyweb: skipped — the supplied corpus already includes the visual and technical source material; external visual imitation would weaken the report's evidence-first identity.
- Imagen drafts: skipped — this report needs no decorative raster asset; its memorable object is the support/readiness matrix itself.

## 1. Atmosphere & Identity

A meticulous field notebook for a high-risk system deployment: warm paper, exact typography, whisper-weight structure, and visible evidence boundaries. The signature is the **readiness ledger**—a compact grid that never lets evaluation, VM proof, physical proof, and unknowns blur together.

## 2. Color

| Role | Token | Value | Usage |
|---|---|---:|---|
| Canvas | `--canvas` | `#fbfbfa` | Page background |
| Paper | `--paper` | `#ffffff` | Primary reading surface |
| Warm surface | `--warm` | `#f6f5f4` | Alternate sections and code |
| Ink | `--ink` | `#242321` | Primary text |
| Muted ink | `--muted` | `#615d59` | Secondary text and metadata |
| Faint ink | `--faint` | `#8c8782` | Captions |
| Border | `--border` | `#e6e3df` | Whisper dividers |
| Focus | `--focus` | `#005fae` | Keyboard focus and links; 6.47:1 against paper |
| P0 background | `--p0-bg` | `#fdebec` | Critical claim surface |
| P0 ink | `--p0-ink` | `#8f2d2b` | Critical claim label |
| P1 background | `--p1-bg` | `#fbf3db` | High-priority claim surface |
| P1 ink | `--p1-ink` | `#7a5400` | High-priority claim label |
| Pass background | `--pass-bg` | `#edf3ec` | Verified-positive surface |
| Pass ink | `--pass-ink` | `#2f6335` | Verified-positive label |
| Deferred background | `--deferred-bg` | `#e1f3fe` | Physical/external evidence surface |
| Deferred ink | `--deferred-ink` | `#215f87` | Physical/external label |
| Refuted background | `--refuted-bg` | `#eee7f5` | Disproved-claim surface |
| Refuted ink | `--refuted-ink` | `#5d3b7a` | Disproved-claim label |

Rules: semantic colors encode status only; no large saturated fields; links and focus are the sole interactive blue; body contrast targets WCAG 2.2 AA.

## 3. Typography

| Level | Size | Weight | Line height | Usage |
|---|---:|---:|---:|---|
| Display | `3rem` | 700 | 1.02 | Report title |
| H1 | `2rem` | 700 | 1.15 | Major sections |
| H2 | `1.5rem` | 700 | 1.25 | Findings groups |
| H3 | `1.125rem` | 700 | 1.35 | Claim titles |
| Lead | `1.125rem` | 400 | 1.65 | Executive framing |
| Body | `1rem` | 400 | 1.65 | Reading text |
| Small | `0.875rem` | 400 | 1.55 | Metadata and dense tables |
| Label | `0.75rem` | 700 | 1.35 | Status badges |

- Primary: `Avenir Next`, `Segoe UI`, `Helvetica Neue`, system sans-serif.
- Editorial: `Iowan Old Style`, `Palatino Linotype`, `Book Antiqua`, serif.
- Mono: `SFMono-Regular`, `Cascadia Code`, `Liberation Mono`, monospace.
- No network fonts; the report remains offline-capable and print-stable.

## 4. Spacing & Layout

All spacing uses a 4 px base: `--s1:4px`, `--s2:8px`, `--s3:12px`, `--s4:16px`, `--s5:20px`, `--s6:24px`, `--s8:32px`, `--s10:40px`, `--s12:48px`, `--s16:64px`, `--s20:80px`.

- Reading width: 80 rem; prose measure: 72 characters.
- Desktop: sticky 15 rem contents rail plus fluid report column.
- Tablet: contents rail becomes a top index.
- Mobile: single column, 16 px gutters, horizontally scrollable tables with an explicit affordance.
- Breakpoints: 48 rem and 72 rem.
- Print: A4/Letter-safe, no sticky elements, no clipped tables, repeated table headings, controlled page breaks.

## 5. Components

### Status badge
- **Structure**: inline label with semantic class.
- **Variants**: P0, P1, verified, deferred, refuted.
- **States**: static; links inside follow link states.
- **Accessibility**: status text is always present; color never carries meaning alone.

### Evidence card
- **Structure**: heading, status badge, claim, evidence, implication, next gate.
- **Variants**: critical, priority, positive, deferred.
- **States**: default and target-highlight; no hidden content.
- **Accessibility**: semantic heading order and sufficiently contrasted border/background.

### Readiness matrix
- **Structure**: captioned table with `thead`, row headers, and evidence-level cells.
- **Variants**: six-config matrix and hardware-class matrix.
- **States**: desktop table; mobile scroll container with visible hint.
- **Accessibility**: captions, scoped headers, selectable text, no icon-only state.

### Contents navigation
- **Structure**: labeled nav with fragment links.
- **States**: default, hover, active, focus-visible.
- **Accessibility**: skip link precedes it; native anchors; focus remains visible.

### Command/evidence block
- **Structure**: preformatted text with a short label.
- **Variants**: command, observed output, invariant.
- **States**: selectable and horizontally scrollable.
- **Accessibility**: never relies on syntax color; wraps only when safe.

### Primitive showcase
- The report's opening legend exercises every status badge and evidence-card variant at all responsive widths before the detailed sections use them.

## 6. Motion & Interaction

- Fragment navigation uses native scrolling; no scripted scroll listener.
- Hover and focus transitions: 150 ms ease-out on color and outline only.
- Targeted sections receive a 2 s semantic outline cue without layout movement.
- `prefers-reduced-motion: reduce` removes smooth scrolling and transitions.
- Print contains no motion or interactive-only meaning.

## 7. Depth & Surface

Strategy: **borders-only with warm tonal alternation**. Cards use 1 px `--border`, 8 px radius, and no decorative shadow. The title area gains depth through a sparse technical grid pattern, not gradients or glass. This deliberately preserves the minimalist reference's document character.

## 8. Accessibility Constraints & Accepted Debt

### Constraints

- WCAG 2.2 AA target: body contrast at least 4.5:1; visible focus; keyboard-reachable navigation; semantic landmarks/headings/tables; 200% zoom without lost content; reduced-motion honored.
- Plain, specific language; acronyms expanded on first use where practical.
- All report claims distinguish observed, inferred, refuted, and physically deferred evidence.

### Accepted Debt

| Item | Location | Why accepted | Owner / Exit |
|---|---|---|---|
| No scripted current-section indicator | contents navigation | Avoids unnecessary JavaScript and observer complexity in an offline report | Add only if user testing shows orientation trouble |
| Wide evidence tables scroll on narrow screens | matrix sections | Preserves exact cell content and avoids unreadably compressed columns | Replace with card view only if mobile testing finds a blocker |
