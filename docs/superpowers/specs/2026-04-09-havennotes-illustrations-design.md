# havennotes.app Illustrations — Design Spec

## Overview

Replace all app screenshots and emoji feature icons with custom inline SVG illustrations in a consistent **duotone** style. This gives the site a unique visual identity, removes reliance on phone frames, and creates a cohesive brand mark system.

**Scope:** Full takeover — illustrations on landing page, pricing, story, compare, and changelog. All illustrations are inline SVG (no external files), using design tokens from the existing stylesheet.

## Illustration Style

### Duotone system
- **Fill**: `var(--accent)` (amber #A0855E)
- **Stroke**: `var(--text)` (warm cream #FAF7F3), 1-1.2px
- **Accent details**: `var(--bg)` (dark charcoal #161512) for inner marks
- **Connecting lines**: `var(--accent)` stroke at 0.6 opacity
- **Rounded corners**: 1.5-2px radius for small shapes, 3-4px for large

### Visual rules
- Geometric, not whimsical — sharp angles balanced with rounded containers
- Amber dominant, cream outline only for definition
- No gradients inside illustrations (the ambient page glow provides depth)
- Every illustration sits on `var(--surface)` or `var(--surface-elevated)` backgrounds
- Vector-first — crisp at any size, dark-mode native

## Illustrations

### 1. Hero illustration (landing page)
**Concept:** A network of notes connected by curves — the signature Haven visual. Five note rectangles arranged asymmetrically, connected by flowing curves, sitting within an amber glow.

**Dimensions:** ~460×300 viewBox, scales fluidly
**Key elements:**
- 5 rounded rectangles representing notes
- Cream outlines, amber fill, dark interior lines for "text"
- Connecting curves in amber at 60% opacity
- Small dots at connection points
- Subtle glow radial behind via CSS (not SVG)

**Location:** Replaces the iPhone screenshot in `.hero-image` section

### 2. Knowledge graph illustration (landing page)
**Concept:** A larger, more abstract version of the hero — an actual graph visualization with nodes of varying sizes and interconnected edges. Asymmetric, organic placement.

**Dimensions:** ~400×400 viewBox
**Key elements:**
- 8-10 circle nodes of 3 sizes (small, medium, large)
- Larger nodes have filled amber, smaller have cream outlines
- Curved connecting lines
- One "central" node with a subtle ring around it (the note being viewed)

**Location:** Replaces `/assets/graph.png` in `.graph-feature` section (graph.png can be deleted)

### 3. Feature icons (landing page)
Six custom icons in the duotone style, each ~40×40 viewBox, sized at 40px display:

| Feature | Icon concept |
|---------|--------------|
| Markdown | Page with formatted text lines (one bold, one normal, one with arrow) |
| Wiki Links | Two note rectangles connected by an arcing line |
| E2E Encrypted | Padlock with amber body, cream shackle, dot keyhole |
| Daily Notes | Calendar with amber body, cream header bar, one highlighted day |
| Voice Dictation | Five vertical amber bars (sound wave) of varying heights |
| Full-Text Search | Magnifying glass with amber circle + cream inner + amber handle |

**Location:** Replace `<span class="emoji">` in each `.feature-card`

### 4. Pricing teaser illustration (landing page)
**Concept:** Three stacked "card" shapes in perspective, one elevated — suggesting free/monthly/yearly tiers.

**Dimensions:** ~120×80 viewBox
**Location:** Small decorative mark above the pricing teaser heading

### 5. CTA illustration (landing page)
**Concept:** An abstract pen/quill tip with a small glow dot, suggesting "ready to write."

**Dimensions:** ~80×80 viewBox
**Location:** Above the "Ready to start writing?" heading

### 6. Story page illustrations
Three section illustrations, one per section of the narrative:
- **The problem:** A tangled knot of lines (chaos)
- **The alternative:** A single clean line (clarity)
- **The craft:** A simple hand icon or anvil silhouette

**Dimensions:** ~100×80 viewBox each
**Location:** Above each `h2` section heading

### 7. Compare page illustration
**Concept:** Haven's mark (a simple "H" in amber with a circle around it) alone at the top, above the comparison table.

**Dimensions:** ~80×80 viewBox
**Location:** Above the compare page header

### 8. Changelog page illustration
**Concept:** A small decorative divider — three dots + a line — between entries or at the top.

**Dimensions:** ~100×20 viewBox
**Location:** Above the changelog heading

## Technical Implementation

### Approach: Inline SVG
All illustrations live inline in each HTML file (not external `.svg` files). This:
- Allows CSS to style them via `currentColor` or `var()` references
- No extra HTTP requests
- Crisp at any resolution
- Can be animated with CSS

### CSS updates needed
In `docs/styles.css`, add:

```css
/* ── Illustration styles ── */
.illustration {
  display: block;
  width: 100%;
  max-width: 100%;
  height: auto;
}

/* Hero illustration sizing */
.hero-illustration {
  max-width: 480px;
  margin: 0 auto;
  filter: drop-shadow(0 20px 40px hsl(30, 30%, 4%, 0.3));
}

/* Graph illustration sizing */
.graph-illustration {
  max-width: 420px;
  margin: 0 auto;
  display: block;
}

/* Feature card icon sizing */
.feature-card .feature-icon {
  width: 40px;
  height: 40px;
  margin-bottom: var(--space-4);
  display: block;
}

/* Section mark (small decorative) */
.section-mark {
  width: 60px;
  height: 60px;
  margin: 0 auto var(--space-6);
  display: block;
  opacity: 0.8;
}

/* Hover effects on feature icons */
.feature-card:hover .feature-icon {
  transform: scale(1.05);
  transition: transform 0.3s var(--ease);
}
```

### Remove from feature cards
Remove the `<span class="emoji">` element entirely. Replace with the inline `<svg class="feature-icon">...</svg>`.

### Remove hero image file
The iPhone screenshot and graph screenshot stay in `docs/assets/` but are no longer referenced. Leave them in place for now (don't delete — may be useful later).

## File Changes Summary

| File | Changes |
|------|---------|
| `docs/index.html` | Replace hero img with SVG, replace graph img with SVG, replace all 6 emoji spans with SVG, add pricing + CTA decorative illustrations |
| `docs/pricing.html` | No illustration changes (optional: add small decorative mark above heading) |
| `docs/story.html` | Add 3 small section illustrations above h2 headings |
| `docs/compare.html` | Add single "H" mark illustration at top |
| `docs/changelog.html` | Add small divider illustration at top |
| `docs/styles.css` | Add illustration classes (CSS-only update, ~30 lines added) |

## What This Is NOT

- Not external SVG files (all inline)
- Not a change to layout or page structure
- Not a change to copy or content
- Not removing existing assets (keep screenshots in `docs/assets/` for archive)
- Not affecting pricing.html, privacy.html, terms.html, support.html (these keep their current look)

## Out of Scope

- Animation of illustrations (static SVG only, hover scale via CSS)
- Light mode variants
- Printable versions
- Figma source files
