# havennotes.app Illustrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all app screenshots and emoji feature icons with custom inline SVG duotone illustrations across the havennotes.app site.

**Architecture:** All illustrations are inline SVG using design tokens (amber fill, cream outline, dark inner details). No external files, no JS libraries. CSS additions for sizing/hover. Surgical edits to 5 HTML files + CSS.

**Tech Stack:** Inline SVG, CSS custom properties, no dependencies.

---

## File Structure

```
docs/
  index.html         — hero SVG, graph SVG, 6 feature icon SVGs, pricing mark, CTA mark
  story.html         — 3 section marks (problem/alternative/craft)
  compare.html       — "H" brand mark at top
  changelog.html     — decorative divider at top
  styles.css         — add illustration sizing classes (~30 lines)
```

Pricing, privacy, terms, support pages are NOT modified.

---

### Task 1: Add illustration CSS classes to styles.css

**Files:**
- Modify: `docs/styles.css` (append to end, before the responsive media queries)

- [ ] **Step 1: Read styles.css to find the insertion point**

Use the Read tool on `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/styles.css`. Find the line that starts with `/* ── 22. Responsive ── */`.

- [ ] **Step 2: Insert illustration classes before the Responsive section**

Use the Edit tool to add this block BEFORE `/* ── 22. Responsive ── */`:

```css
/* ── 23. Illustrations ── */
.illustration {
  display: block;
  width: 100%;
  max-width: 100%;
  height: auto;
}

.hero-illustration {
  max-width: 480px;
  margin: 0 auto;
  filter: drop-shadow(0 20px 40px hsl(30, 30%, 4%, 0.3));
}

.graph-illustration {
  max-width: 420px;
  margin: 0 auto;
  display: block;
  filter: drop-shadow(0 20px 40px hsl(30, 30%, 4%, 0.3));
}

.feature-card .feature-icon {
  width: 44px;
  height: 44px;
  margin-bottom: var(--space-4);
  display: block;
  transition: transform 0.3s var(--ease);
}

.feature-card:hover .feature-icon {
  transform: scale(1.08);
}

.section-mark {
  width: 64px;
  height: 64px;
  margin: 0 auto var(--space-6);
  display: block;
  opacity: 0.9;
}

.story-mark {
  width: 80px;
  height: 64px;
  margin: var(--space-12) auto var(--space-6);
  display: block;
  opacity: 0.85;
}

.divider-mark {
  width: 120px;
  height: 20px;
  margin: var(--space-4) auto var(--space-8);
  display: block;
  opacity: 0.7;
}

.brand-mark {
  width: 72px;
  height: 72px;
  margin: 0 auto var(--space-6);
  display: block;
}

```

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/styles.css
git commit -m "feat(site): add illustration CSS classes"
```

---

### Task 2: Replace hero screenshot with illustration in index.html

**Files:**
- Modify: `docs/index.html`

- [ ] **Step 1: Find the existing hero image**

Use the Read tool on `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/index.html`. Locate this block:

```html
      <div class="hero-image reveal reveal-delay-3">
        <img src="assets/screenshot.png" alt="Haven Notes app showing the markdown editor with wiki links" width="320" height="640">
      </div>
```

- [ ] **Step 2: Replace with hero illustration SVG**

Use the Edit tool. Replace the block above with exactly:

```html
      <div class="hero-image reveal reveal-delay-3">
        <svg class="illustration hero-illustration" viewBox="0 0 480 320" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="A network of connected notes">
          <defs>
            <style>
              .note-fill { fill: #A0855E; }
              .note-stroke { stroke: #FAF7F3; stroke-width: 1.2; fill: none; }
              .note-line { stroke: #161512; stroke-width: 2; stroke-linecap: round; }
              .edge { stroke: #A0855E; stroke-width: 1.5; fill: none; stroke-linecap: round; opacity: 0.65; }
              .dot { fill: #A0855E; }
            </style>
          </defs>

          <!-- Connecting edges (drawn first so notes sit on top) -->
          <path class="edge" d="M 110 90 Q 180 55 260 95"/>
          <path class="edge" d="M 140 160 Q 220 195 300 165"/>
          <path class="edge" d="M 260 95 Q 330 130 360 210"/>
          <path class="edge" d="M 110 90 Q 90 150 140 160"/>
          <path class="edge" d="M 300 165 Q 340 190 360 210"/>
          <path class="edge" d="M 260 95 Q 300 130 300 165"/>

          <!-- Note 1 (top left) -->
          <g transform="translate(60, 50)">
            <rect class="note-fill" x="0" y="0" width="100" height="70" rx="4"/>
            <rect class="note-stroke" x="0" y="0" width="100" height="70" rx="4"/>
            <line class="note-line" x1="14" y1="22" x2="72" y2="22"/>
            <line class="note-line" x1="14" y1="34" x2="86" y2="34"/>
            <line class="note-line" x1="14" y1="46" x2="62" y2="46"/>
          </g>

          <!-- Note 2 (top right) -->
          <g transform="translate(210, 60)">
            <rect class="note-fill" x="0" y="0" width="100" height="70" rx="4"/>
            <rect class="note-stroke" x="0" y="0" width="100" height="70" rx="4"/>
            <line class="note-line" x1="14" y1="22" x2="76" y2="22"/>
            <line class="note-line" x1="14" y1="34" x2="86" y2="34"/>
            <line class="note-line" x1="14" y1="46" x2="68" y2="46"/>
          </g>

          <!-- Note 3 (middle left) -->
          <g transform="translate(90, 130)">
            <rect class="note-fill" x="0" y="0" width="100" height="70" rx="4"/>
            <rect class="note-stroke" x="0" y="0" width="100" height="70" rx="4"/>
            <line class="note-line" x1="14" y1="22" x2="70" y2="22"/>
            <line class="note-line" x1="14" y1="34" x2="84" y2="34"/>
            <line class="note-line" x1="14" y1="46" x2="56" y2="46"/>
          </g>

          <!-- Note 4 (middle right) -->
          <g transform="translate(250, 135)">
            <rect class="note-fill" x="0" y="0" width="100" height="70" rx="4"/>
            <rect class="note-stroke" x="0" y="0" width="100" height="70" rx="4"/>
            <line class="note-line" x1="14" y1="22" x2="74" y2="22"/>
            <line class="note-line" x1="14" y1="34" x2="86" y2="34"/>
            <line class="note-line" x1="14" y1="46" x2="64" y2="46"/>
          </g>

          <!-- Note 5 (bottom) -->
          <g transform="translate(310, 200)">
            <rect class="note-fill" x="0" y="0" width="100" height="70" rx="4"/>
            <rect class="note-stroke" x="0" y="0" width="100" height="70" rx="4"/>
            <line class="note-line" x1="14" y1="22" x2="72" y2="22"/>
            <line class="note-line" x1="14" y1="34" x2="86" y2="34"/>
            <line class="note-line" x1="14" y1="46" x2="60" y2="46"/>
          </g>

          <!-- Connection dots -->
          <circle class="dot" cx="110" cy="90" r="3"/>
          <circle class="dot" cx="260" cy="95" r="3"/>
          <circle class="dot" cx="140" cy="160" r="3"/>
          <circle class="dot" cx="300" cy="165" r="3"/>
          <circle class="dot" cx="360" cy="210" r="3"/>
        </svg>
      </div>
```

- [ ] **Step 3: Verify in browser**

Run: `curl -sI http://localhost:4444/ | head -3`
Expected: HTTP 200

- [ ] **Step 4: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/index.html
git commit -m "feat(site): replace hero screenshot with network illustration"
```

---

### Task 3: Replace knowledge graph screenshot with illustration in index.html

**Files:**
- Modify: `docs/index.html`

- [ ] **Step 1: Find the graph image**

Use the Read tool. Locate this block in index.html:

```html
      <div class="graph-image reveal reveal-delay-1">
        <img src="assets/graph.png" alt="Haven knowledge graph showing connected notes" loading="lazy">
      </div>
```

- [ ] **Step 2: Replace with graph illustration SVG**

Use the Edit tool. Replace the block above with exactly:

```html
      <div class="graph-image reveal reveal-delay-1">
        <svg class="illustration graph-illustration" viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="An abstract knowledge graph with connected nodes">
          <defs>
            <style>
              .node-large { fill: #A0855E; stroke: #FAF7F3; stroke-width: 1.5; }
              .node-medium { fill: #A0855E; stroke: #FAF7F3; stroke-width: 1.2; }
              .node-small { fill: none; stroke: #A0855E; stroke-width: 1.5; }
              .node-center { fill: #A0855E; stroke: #FAF7F3; stroke-width: 2; }
              .node-ring { fill: none; stroke: #A0855E; stroke-width: 1; opacity: 0.4; }
              .graph-edge { stroke: #A0855E; stroke-width: 1.3; fill: none; opacity: 0.55; stroke-linecap: round; }
            </style>
          </defs>

          <!-- Edges (drawn first) -->
          <path class="graph-edge" d="M 200 200 L 90 110"/>
          <path class="graph-edge" d="M 200 200 L 310 90"/>
          <path class="graph-edge" d="M 200 200 L 340 220"/>
          <path class="graph-edge" d="M 200 200 L 260 320"/>
          <path class="graph-edge" d="M 200 200 L 90 290"/>
          <path class="graph-edge" d="M 200 200 L 60 200"/>
          <path class="graph-edge" d="M 90 110 L 60 200"/>
          <path class="graph-edge" d="M 310 90 L 340 220"/>
          <path class="graph-edge" d="M 340 220 L 260 320"/>
          <path class="graph-edge" d="M 260 320 L 90 290"/>
          <path class="graph-edge" d="M 90 290 L 60 200"/>
          <path class="graph-edge" d="M 90 110 L 180 70"/>
          <path class="graph-edge" d="M 310 90 L 180 70"/>
          <path class="graph-edge" d="M 200 200 L 180 70"/>

          <!-- Outer small nodes -->
          <circle class="node-small" cx="180" cy="70" r="10"/>
          <circle class="node-small" cx="90" cy="110" r="11"/>
          <circle class="node-small" cx="60" cy="200" r="9"/>
          <circle class="node-small" cx="90" cy="290" r="10"/>
          <circle class="node-small" cx="260" cy="320" r="11"/>

          <!-- Medium filled nodes -->
          <circle class="node-medium" cx="310" cy="90" r="14"/>
          <circle class="node-medium" cx="340" cy="220" r="13"/>

          <!-- Center node with ring -->
          <circle class="node-ring" cx="200" cy="200" r="30"/>
          <circle class="node-center" cx="200" cy="200" r="18"/>
        </svg>
      </div>
```

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/index.html
git commit -m "feat(site): replace knowledge graph screenshot with SVG illustration"
```

---

### Task 4: Replace feature emoji icons with SVG icons in index.html

**Files:**
- Modify: `docs/index.html`

This task replaces 6 `<span class="emoji">` elements with custom SVG icons. All 6 changes are in the `.feature-grid` section.

- [ ] **Step 1: Replace Live Markdown icon**

Use the Edit tool. Find:
```html
        <div class="feature-card reveal">
          <span class="emoji" aria-hidden="true">✏️</span>
          <h3>Live Markdown</h3>
```

Replace with:
```html
        <div class="feature-card reveal">
          <svg class="feature-icon" viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <rect x="6" y="9" width="32" height="26" rx="2.5" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
            <rect x="11" y="15" width="14" height="3" rx="0.5" fill="#161512"/>
            <rect x="11" y="20" width="22" height="2.5" rx="0.5" fill="#161512"/>
            <rect x="11" y="25" width="18" height="2.5" rx="0.5" fill="#161512"/>
          </svg>
          <h3>Live Markdown</h3>
```

- [ ] **Step 2: Replace Wiki Links icon**

Find:
```html
        <div class="feature-card reveal reveal-delay-1">
          <span class="emoji" aria-hidden="true">🔗</span>
          <h3>Wiki Links</h3>
```

Replace with:
```html
        <div class="feature-card reveal reveal-delay-1">
          <svg class="feature-icon" viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <rect x="4" y="8" width="16" height="18" rx="1.5" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
            <rect x="24" y="18" width="16" height="18" rx="1.5" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
            <path d="M 19 15 Q 26 10 27 22" stroke="#FAF7F3" stroke-width="1.8" fill="none" stroke-linecap="round"/>
            <circle cx="19" cy="15" r="1.8" fill="#FAF7F3"/>
            <circle cx="27" cy="22" r="1.8" fill="#FAF7F3"/>
          </svg>
          <h3>Wiki Links</h3>
```

- [ ] **Step 3: Replace E2E Encrypted icon**

Find:
```html
        <div class="feature-card reveal reveal-delay-2">
          <span class="emoji" aria-hidden="true">🔒</span>
          <h3>E2E Encrypted</h3>
```

Replace with:
```html
        <div class="feature-card reveal reveal-delay-2">
          <svg class="feature-icon" viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <rect x="10" y="20" width="24" height="18" rx="2" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
            <path d="M 15 20 L 15 13 Q 15 7 22 7 Q 29 7 29 13 L 29 20" fill="none" stroke="#FAF7F3" stroke-width="2.2" stroke-linecap="round"/>
            <circle cx="22" cy="28" r="2.5" fill="#161512"/>
            <rect x="21" y="28" width="2" height="5" fill="#161512"/>
          </svg>
          <h3>E2E Encrypted</h3>
```

- [ ] **Step 4: Replace Daily Notes icon**

Find:
```html
        <div class="feature-card reveal">
          <span class="emoji" aria-hidden="true">📅</span>
          <h3>Daily Notes</h3>
```

Replace with:
```html
        <div class="feature-card reveal">
          <svg class="feature-icon" viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <rect x="7" y="10" width="30" height="28" rx="2.5" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
            <rect x="7" y="10" width="30" height="8" fill="#FAF7F3"/>
            <line x1="14" y1="6" x2="14" y2="13" stroke="#FAF7F3" stroke-width="2" stroke-linecap="round"/>
            <line x1="30" y1="6" x2="30" y2="13" stroke="#FAF7F3" stroke-width="2" stroke-linecap="round"/>
            <circle cx="22" cy="27" r="4" fill="#161512"/>
            <circle cx="22" cy="27" r="1.5" fill="#A0855E"/>
          </svg>
          <h3>Daily Notes</h3>
```

- [ ] **Step 5: Replace Voice Dictation icon**

Find:
```html
        <div class="feature-card reveal reveal-delay-1">
          <span class="emoji" aria-hidden="true">🎤</span>
          <h3>Voice Dictation</h3>
```

Replace with:
```html
        <div class="feature-card reveal reveal-delay-1">
          <svg class="feature-icon" viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <rect x="8" y="16" width="3" height="12" rx="1.5" fill="#A0855E"/>
            <rect x="14" y="11" width="3" height="22" rx="1.5" fill="#A0855E"/>
            <rect x="20" y="6" width="3" height="32" rx="1.5" fill="#A0855E" stroke="#FAF7F3" stroke-width="0.8"/>
            <rect x="26" y="11" width="3" height="22" rx="1.5" fill="#A0855E"/>
            <rect x="32" y="16" width="3" height="12" rx="1.5" fill="#A0855E"/>
          </svg>
          <h3>Voice Dictation</h3>
```

- [ ] **Step 6: Replace Full-Text Search icon**

Find:
```html
        <div class="feature-card reveal reveal-delay-2">
          <span class="emoji" aria-hidden="true">🔍</span>
          <h3>Full-Text Search</h3>
```

Replace with:
```html
        <div class="feature-card reveal reveal-delay-2">
          <svg class="feature-icon" viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <circle cx="19" cy="19" r="11" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
            <circle cx="19" cy="19" r="6" fill="#161512"/>
            <circle cx="17" cy="17" r="1.5" fill="#A0855E"/>
            <line x1="27" y1="27" x2="37" y2="37" stroke="#A0855E" stroke-width="3.5" stroke-linecap="round"/>
            <line x1="27" y1="27" x2="37" y2="37" stroke="#FAF7F3" stroke-width="1" stroke-linecap="round"/>
          </svg>
          <h3>Full-Text Search</h3>
```

- [ ] **Step 7: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/index.html
git commit -m "feat(site): replace emoji feature icons with custom SVG icons"
```

---

### Task 5: Add pricing teaser and CTA decorative marks to index.html

**Files:**
- Modify: `docs/index.html`

- [ ] **Step 1: Add pricing mark above the pricing teaser heading**

Use the Read tool to find this block in index.html:
```html
  <!-- Pricing Teaser -->
  <section class="pricing-teaser">
    <div class="pricing-teaser-inner">
      <span class="eyebrow reveal">Pricing</span>
```

Replace with:
```html
  <!-- Pricing Teaser -->
  <section class="pricing-teaser">
    <div class="pricing-teaser-inner">
      <svg class="section-mark reveal" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <rect x="8" y="28" width="20" height="26" rx="2.5" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2" opacity="0.7"/>
        <rect x="22" y="20" width="20" height="34" rx="2.5" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2" opacity="0.85"/>
        <rect x="36" y="12" width="20" height="42" rx="2.5" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
        <line x1="40" y1="22" x2="52" y2="22" stroke="#161512" stroke-width="1.5"/>
        <line x1="40" y1="28" x2="52" y2="28" stroke="#161512" stroke-width="1.5"/>
      </svg>
      <span class="eyebrow reveal">Pricing</span>
```

- [ ] **Step 2: Add CTA mark above the final CTA heading**

Find this block:
```html
  <!-- Final CTA -->
  <section class="cta-section">
    <div class="cta-inner">
      <h2 class="reveal">
        Ready to<br>
```

Replace with:
```html
  <!-- Final CTA -->
  <section class="cta-section">
    <div class="cta-inner">
      <svg class="section-mark reveal" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <path d="M 15 42 L 38 19 Q 42 15 46 19 L 48 21 Q 52 25 48 29 L 25 52 L 12 52 Z" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2" stroke-linejoin="round"/>
        <line x1="17" y1="48" x2="25" y2="40" stroke="#161512" stroke-width="1.5" stroke-linecap="round"/>
        <circle cx="43" cy="24" r="2" fill="#FAF7F3"/>
        <circle cx="43" cy="24" r="4" fill="none" stroke="#A0855E" stroke-width="1" opacity="0.5"/>
      </svg>
      <h2 class="reveal">
        Ready to<br>
```

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/index.html
git commit -m "feat(site): add decorative illustrations to pricing teaser and CTA"
```

---

### Task 6: Add section illustrations to story.html

**Files:**
- Modify: `docs/story.html`

- [ ] **Step 1: Find the first h2 "The problem"**

Use the Read tool on `docs/story.html`. Find:
```html
      <h2>The problem</h2>
```

- [ ] **Step 2: Add tangled knot illustration before "The problem"**

Use the Edit tool. Replace with:
```html
      <svg class="story-mark" viewBox="0 0 80 64" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <path d="M 15 32 Q 25 10 40 32 Q 55 54 65 32 Q 55 10 40 32 Q 25 54 15 32" fill="none" stroke="#A0855E" stroke-width="2" stroke-linecap="round"/>
        <path d="M 20 32 Q 30 45 40 32 Q 50 19 60 32" fill="none" stroke="#A0855E" stroke-width="2" stroke-linecap="round" opacity="0.6"/>
        <path d="M 25 20 L 55 44" stroke="#A0855E" stroke-width="1.5" stroke-linecap="round" opacity="0.4"/>
      </svg>
      <h2>The problem</h2>
```

- [ ] **Step 3: Find "The alternative" h2**

Find:
```html
      <h2>The alternative</h2>
```

- [ ] **Step 4: Add clean line illustration**

Replace with:
```html
      <svg class="story-mark" viewBox="0 0 80 64" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <line x1="10" y1="32" x2="70" y2="32" stroke="#A0855E" stroke-width="2.5" stroke-linecap="round"/>
        <circle cx="40" cy="32" r="4" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
      </svg>
      <h2>The alternative</h2>
```

- [ ] **Step 5: Find "The craft" h2**

Find:
```html
      <h2>The craft</h2>
```

- [ ] **Step 6: Add craft mark illustration**

Replace with:
```html
      <svg class="story-mark" viewBox="0 0 80 64" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <rect x="30" y="18" width="20" height="34" rx="2" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
        <line x1="35" y1="28" x2="45" y2="28" stroke="#161512" stroke-width="1.5" stroke-linecap="round"/>
        <line x1="35" y1="34" x2="45" y2="34" stroke="#161512" stroke-width="1.5" stroke-linecap="round"/>
        <line x1="35" y1="40" x2="42" y2="40" stroke="#161512" stroke-width="1.5" stroke-linecap="round"/>
        <path d="M 40 10 L 44 18 L 36 18 Z" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.2"/>
      </svg>
      <h2>The craft</h2>
```

- [ ] **Step 7: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/story.html
git commit -m "feat(site): add section illustrations to story page"
```

---

### Task 7: Add brand mark illustration to compare.html

**Files:**
- Modify: `docs/compare.html`

- [ ] **Step 1: Find the page heading block**

Use the Read tool on `docs/compare.html`. Find:
```html
      <span class="eyebrow">Compare</span>
      <h1>Haven vs <span class="accent-italic">the rest.</span></h1>
```

- [ ] **Step 2: Add brand mark before eyebrow**

Use the Edit tool. Replace with:
```html
      <svg class="brand-mark" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <circle cx="36" cy="36" r="30" fill="none" stroke="#A0855E" stroke-width="1.5" opacity="0.4"/>
        <circle cx="36" cy="36" r="24" fill="#A0855E" stroke="#FAF7F3" stroke-width="1.5"/>
        <path d="M 24 22 L 24 50 M 48 22 L 48 50 M 24 36 L 48 36" stroke="#FAF7F3" stroke-width="3" stroke-linecap="round"/>
      </svg>
      <span class="eyebrow">Compare</span>
      <h1>Haven vs <span class="accent-italic">the rest.</span></h1>
```

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/compare.html
git commit -m "feat(site): add brand mark illustration to compare page"
```

---

### Task 8: Add divider illustration to changelog.html

**Files:**
- Modify: `docs/changelog.html`

- [ ] **Step 1: Find the changelog heading**

Use the Read tool on `docs/changelog.html`. Find:
```html
      <span class="eyebrow">Updates</span>
      <h1><span class="accent-italic">Changelog.</span></h1>
```

- [ ] **Step 2: Add divider illustration before eyebrow**

Use the Edit tool. Replace with:
```html
      <svg class="divider-mark" viewBox="0 0 120 20" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <line x1="10" y1="10" x2="45" y2="10" stroke="#A0855E" stroke-width="1.5" stroke-linecap="round"/>
        <circle cx="52" cy="10" r="2" fill="#A0855E"/>
        <circle cx="60" cy="10" r="3" fill="#A0855E" stroke="#FAF7F3" stroke-width="1"/>
        <circle cx="68" cy="10" r="2" fill="#A0855E"/>
        <line x1="75" y1="10" x2="110" y2="10" stroke="#A0855E" stroke-width="1.5" stroke-linecap="round"/>
      </svg>
      <span class="eyebrow">Updates</span>
      <h1><span class="accent-italic">Changelog.</span></h1>
```

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/changelog.html
git commit -m "feat(site): add divider illustration to changelog page"
```

---

### Task 9: Final verification, push, and deploy

**Files:** All pages

- [ ] **Step 1: Start local server if not running**

Run:
```bash
lsof -ti:4444 > /dev/null || (cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs && npx serve -l 4444 --no-clipboard &)
sleep 2
```

- [ ] **Step 2: Verify all pages return 200**

Run:
```bash
for page in / pricing story compare changelog privacy terms support; do
  echo -n "$page: "
  curl -sI "http://localhost:4444$page" | head -1
done
```

Expected: All pages `HTTP/1.1 200 OK`

- [ ] **Step 3: Use Playwright to visually verify landing page**

Use `mcp__plugin_playwright_playwright__browser_navigate` to `http://localhost:4444/` and take a full-page screenshot. Force `.reveal` elements visible via JS first. Save to `smoke-test/illustrations-final.png`.

Verify visually:
- Hero shows the network illustration (no phone)
- Knowledge graph section shows the abstract node graph
- Feature cards show custom SVG icons (no emoji)
- Pricing teaser has the stacked cards mark
- Final CTA has the pen mark

- [ ] **Step 4: Verify story page illustrations**

Navigate to `http://localhost:4444/story` and take a screenshot. Verify 3 section marks appear above the h2s.

- [ ] **Step 5: Verify compare and changelog**

Navigate to `http://localhost:4444/compare` and `http://localhost:4444/changelog`, verify the brand mark and divider appear at the top.

- [ ] **Step 6: Push and deploy**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git push origin main
cd docs
vercel --yes --prod
```

Expected: Deployment URL returned.

- [ ] **Step 7: Verify live site**

```bash
sleep 5
curl -sI https://havennotes.app | head -3
```

Expected: HTTP 200.
