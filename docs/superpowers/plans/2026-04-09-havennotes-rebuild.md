# havennotes.app Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild havennotes.app with a dark-first, cinematic visual system that matches Haven iOS app's actual aesthetic — amber glow effects, signature italic-accent serif headlines, and scroll-reveal animations.

**Architecture:** Complete rewrite of `docs/styles.css` and `docs/index.html`. Other pages get the new theme applied (nav/footer/type system). Single inline JS for scroll-reveal. No frameworks, no build step, deploys to Vercel via existing config.

**Tech Stack:** HTML5, CSS3 (custom properties, grid, flexbox, radial gradients), minimal vanilla JS (Intersection Observer), Georgia serif + system sans-serif (no webfonts).

---

## File Structure

```
docs/
  styles.css              — REPLACED (complete rewrite, dark-first system)
  index.html              — REPLACED (new structure with hero/graph/features/teaser/cta)
  pricing.html            — UPDATED (new nav, new dark theme applied, cards restyled)
  story.html              — UPDATED (new nav, dark prose)
  compare.html            — UPDATED (new nav, dark table)
  changelog.html          — UPDATED (new nav, dark theme)
  privacy.html            — UPDATED (new nav, dark prose)
  terms.html              — UPDATED (new nav, dark prose)
  support.html            — UPDATED (new nav, dark theme)
  assets/
    screenshot.png        — EXISTS (editor hero screenshot)
    graph.png             — NEW (knowledge graph screenshot)
  sitemap.xml             — PRESERVED
  robots.txt              — PRESERVED
  vercel.json             — PRESERVED
  favicon.png             — PRESERVED
  apple-touch-icon.png    — PRESERVED
```

Existing infrastructure (Vercel deploy, sitemap, favicon, clean URLs) stays. Only visual layer changes.

---

### Task 1: Copy knowledge graph screenshot asset

**Files:**
- Create: `docs/assets/graph.png` (copy from Screenshots/Haven-Notes-screenshot-3.png)

- [ ] **Step 1: Copy the graph screenshot**

Run:
```bash
cp /Users/youneshaddaj/Projects/notes-classic-ios/Haven/Screenshots/Haven-Notes-screenshot-3.png /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/assets/graph.png
```

- [ ] **Step 2: Resize for web performance (max 1200px tall)**

Run:
```bash
sips -Z 1200 /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/assets/graph.png
```

Expected: Image resized, file size ~500-700KB.

- [ ] **Step 3: Verify it exists**

Run:
```bash
ls -lh /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/assets/graph.png
```

Expected: File exists at docs/assets/graph.png

- [ ] **Step 4: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/assets/graph.png
git commit -m "feat(site): add knowledge graph screenshot asset"
```

---

### Task 2: Rewrite styles.css with dark-first design system

**Files:**
- Replace: `docs/styles.css`

This is the foundation. Complete rewrite, dark-first only (no light mode), new color tokens, new type scale, new shadow system with warm tints, scroll-reveal helper class.

- [ ] **Step 1: Write the complete new styles.css**

Replace the entire contents of `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/styles.css` with:

```css
/* ============================================================
   Haven Notes — Dark-First Design System
   ============================================================ */

/* ── 1. Reset ── */
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

/* ── 2. Design Tokens ── */
:root {
  /* Color */
  --bg:               #161512;
  --surface:          #1E1B17;
  --surface-elevated: #252018;
  --text:             #FAF7F3;
  --text-secondary:   #A89E94;
  --border:           hsl(30, 8%, 20%);
  --border-strong:    hsl(30, 10%, 28%);
  --accent:           #A0855E;
  --accent-hover:     #B8996A;
  --accent-glow:      rgba(160, 133, 94, 0.15);
  --accent-glow-strong: rgba(160, 133, 94, 0.25);
  --shadow-color:     hsl(30, 30%, 4%);

  /* Fonts */
  --font-serif: Georgia, "Times New Roman", Times, serif;
  --font-sans:  -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  --font-mono:  "SF Mono", "Fira Code", "Fira Mono", Menlo, Monaco, Consolas, monospace;

  /* Type scale */
  --text-micro: 12px;
  --text-sm:    14px;
  --text-base:  16px;
  --text-lg:    18px;
  --text-xl:    22px;
  --text-2xl:   32px;
  --text-3xl:   44px;
  --text-hero:  clamp(48px, 7vw, 88px);

  /* Spacing */
  --space-1:  4px;
  --space-2:  8px;
  --space-3:  12px;
  --space-4:  16px;
  --space-6:  24px;
  --space-8:  32px;
  --space-12: 48px;
  --space-16: 64px;
  --space-20: 80px;
  --space-24: 96px;
  --space-32: 128px;

  /* Layout */
  --max-width: 1080px;
  --max-prose: 640px;

  /* Motion */
  --ease: cubic-bezier(0.25, 0.1, 0.25, 1);
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
}

/* ── 3. Base ── */
html {
  scroll-behavior: smooth;
  -webkit-text-size-adjust: 100%;
  text-size-adjust: 100%;
}

body {
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans);
  font-size: 17px;
  line-height: 1.65;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
  font-feature-settings: 'kern' 1, 'liga' 1;
  min-height: 100vh;
}

::selection {
  background: var(--accent-glow-strong);
  color: var(--text);
}

:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
  border-radius: 4px;
}

:focus:not(:focus-visible) { outline: none; }

a {
  color: var(--accent);
  text-decoration: none;
  transition: color 0.2s var(--ease);
}

a:hover { color: var(--accent-hover); }

img {
  display: block;
  max-width: 100%;
  height: auto;
}

code, kbd, samp {
  font-family: var(--font-mono);
  font-size: 0.9em;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: 0.1em 0.35em;
}

ul, ol { padding-left: 1.5em; }

/* ── 4. Typography ── */
h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-serif);
  font-weight: 700;
  line-height: 1.1;
  letter-spacing: -0.02em;
  color: var(--text);
}

h1 { font-size: var(--text-hero); }
h2 { font-size: var(--text-2xl); }
h3 { font-size: var(--text-xl); }

.accent-italic {
  font-style: italic;
  font-weight: 400;
  color: var(--accent);
}

.eyebrow {
  display: inline-block;
  font-family: var(--font-sans);
  font-size: var(--text-micro);
  font-weight: 600;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: var(--accent);
  margin-bottom: var(--space-4);
}

.subtitle {
  font-size: var(--text-lg);
  line-height: 1.65;
  color: var(--text-secondary);
  max-width: 520px;
}

.pull-quote {
  font-family: var(--font-serif);
  font-size: var(--text-xl);
  font-style: italic;
  color: var(--text);
  max-width: var(--max-prose);
  margin: 0 auto;
  padding: var(--space-12) 0;
  text-align: center;
  line-height: 1.5;
}

/* ── 5. Layout ── */
.container {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 var(--space-6);
}

.section {
  padding: var(--space-24) 0;
}

.section-centered {
  text-align: center;
}

/* ── 6. Navigation ── */
.nav {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(22, 21, 18, 0.85);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-bottom: 1px solid var(--border);
  transition: background 0.3s var(--ease);
}

.nav-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 var(--space-6);
  height: 68px;
}

.nav-logo {
  font-family: var(--font-serif);
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.01em;
  color: var(--text);
  text-decoration: none;
}

.nav-logo:hover { color: var(--text); }

.nav-links {
  display: flex;
  align-items: center;
  gap: var(--space-8);
}

.nav-links a {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  text-decoration: none;
  position: relative;
  transition: color 0.2s var(--ease);
}

.nav-links a:hover,
.nav-links a[aria-current="page"] {
  color: var(--text);
}

.nav-links a:not(.nav-cta)::after {
  content: '';
  position: absolute;
  bottom: -6px;
  left: 0;
  width: 0;
  height: 1.5px;
  background: var(--accent);
  transition: width 0.2s var(--ease);
}

.nav-links a:not(.nav-cta):hover::after { width: 100%; }

.nav-links .nav-cta {
  display: inline-flex;
  align-items: center;
  background: var(--accent);
  color: var(--bg);
  font-weight: 600;
  padding: 9px 18px;
  border-radius: 8px;
  transition: background 0.2s var(--ease), box-shadow 0.2s var(--ease);
}

.nav-links .nav-cta:hover {
  background: var(--accent-hover);
  color: var(--bg);
  box-shadow: 0 4px 16px var(--accent-glow-strong);
}

.nav-hamburger {
  display: none;
  background: none;
  border: none;
  cursor: pointer;
  padding: 8px;
}

.nav-hamburger span {
  display: block;
  width: 20px;
  height: 2px;
  background: var(--text);
  margin: 4px 0;
  transition: transform 0.2s, opacity 0.2s;
}

.nav-mobile {
  display: none;
  flex-direction: column;
  background: var(--bg);
  border-top: 1px solid var(--border);
  padding: var(--space-2) 0 var(--space-4);
}

.nav-mobile.open { display: flex; }

.nav-mobile a {
  font-size: var(--text-base);
  color: var(--text-secondary);
  padding: var(--space-3) var(--space-6);
  text-decoration: none;
}

.nav-mobile a:hover { color: var(--text); }

/* ── 7. Hero ── */
.hero {
  position: relative;
  padding: var(--space-24) 0 var(--space-16);
  text-align: center;
  overflow: hidden;
}

.hero::before {
  content: '';
  position: absolute;
  top: -10%;
  left: 50%;
  transform: translateX(-50%);
  width: 120%;
  height: 70%;
  background: radial-gradient(ellipse 50% 50% at center, var(--accent-glow) 0%, transparent 70%);
  pointer-events: none;
  z-index: 0;
}

.hero-inner {
  position: relative;
  z-index: 1;
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 var(--space-6);
}

.hero h1 {
  margin: var(--space-4) 0 var(--space-6);
  line-height: 1.02;
}

.hero .subtitle {
  margin: 0 auto var(--space-8);
  max-width: 560px;
  font-size: var(--text-lg);
}

.hero-buttons {
  display: flex;
  gap: var(--space-3);
  justify-content: center;
  flex-wrap: wrap;
  margin-bottom: var(--space-16);
}

.hero-image {
  max-width: 320px;
  margin: 0 auto;
  position: relative;
}

.hero-image img {
  width: 100%;
  border-radius: 24px;
  box-shadow:
    0 40px 100px hsl(30, 30%, 4%, 0.6),
    0 0 80px var(--accent-glow),
    0 0 0 1px var(--border);
  transition: transform 0.4s var(--ease-out);
}

.hero-image img:hover {
  transform: translateY(-4px);
}

/* ── 8. Buttons ── */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  font-family: var(--font-sans);
  font-size: var(--text-base);
  font-weight: 600;
  padding: 14px 28px;
  border-radius: 10px;
  border: none;
  cursor: pointer;
  text-decoration: none;
  transition: all 0.2s var(--ease);
  white-space: nowrap;
  letter-spacing: -0.005em;
}

.btn-primary {
  background: var(--accent);
  color: var(--bg);
}

.btn-primary:hover {
  background: var(--accent-hover);
  color: var(--bg);
  transform: translateY(-1px);
  box-shadow: 0 8px 24px var(--accent-glow-strong);
}

.btn-primary:active {
  transform: translateY(0);
  box-shadow: 0 4px 12px var(--accent-glow-strong);
}

.btn-outline {
  background: transparent;
  color: var(--text);
  border: 1px solid var(--border-strong);
}

.btn-outline:hover {
  border-color: var(--accent);
  color: var(--accent);
  background: rgba(160, 133, 94, 0.05);
}

/* ── 9. Graph Feature Section ── */
.graph-feature {
  position: relative;
  padding: var(--space-24) 0;
  overflow: hidden;
}

.graph-feature::before {
  content: '';
  position: absolute;
  top: 0;
  right: -10%;
  width: 70%;
  height: 100%;
  background: radial-gradient(ellipse 50% 50% at center, var(--accent-glow) 0%, transparent 70%);
  pointer-events: none;
}

.graph-inner {
  position: relative;
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 var(--space-6);
  display: grid;
  grid-template-columns: 5fr 6fr;
  gap: var(--space-20);
  align-items: center;
}

.graph-text h2 {
  font-size: var(--text-3xl);
  margin: var(--space-4) 0 var(--space-6);
  line-height: 1.08;
}

.graph-text .subtitle {
  margin-bottom: var(--space-8);
  max-width: 440px;
}

.graph-text .link-arrow {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  color: var(--accent);
  font-weight: 600;
  font-size: var(--text-base);
  transition: gap 0.2s var(--ease);
}

.graph-text .link-arrow:hover {
  gap: var(--space-3);
  color: var(--accent-hover);
}

.graph-image img {
  width: 100%;
  max-width: 420px;
  margin: 0 auto;
  display: block;
  border-radius: 20px;
  box-shadow:
    0 40px 80px hsl(30, 30%, 4%, 0.55),
    0 0 60px var(--accent-glow),
    0 0 0 1px var(--border);
}

/* ── 10. Feature Grid ── */
.features-section {
  padding: var(--space-24) 0;
}

.features-section .section-heading {
  text-align: center;
  margin-bottom: var(--space-16);
}

.features-section h2 {
  font-size: var(--text-3xl);
  line-height: 1.1;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--space-4);
}

.feature-card {
  background: var(--surface-elevated);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: var(--space-8);
  transition: all 0.3s var(--ease);
}

.feature-card:hover {
  transform: translateY(-3px);
  border-color: var(--accent);
  box-shadow:
    0 12px 32px hsl(30, 30%, 4%, 0.4),
    0 0 40px var(--accent-glow);
}

.feature-card .emoji {
  display: block;
  font-size: 28px;
  margin-bottom: var(--space-4);
}

.feature-card h3 {
  font-family: var(--font-serif);
  font-size: var(--text-xl);
  margin-bottom: var(--space-2);
  color: var(--text);
}

.feature-card p {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  line-height: 1.6;
}

/* ── 11. Pricing Teaser ── */
.pricing-teaser {
  padding: var(--space-20) 0;
  text-align: center;
  position: relative;
  overflow: hidden;
}

.pricing-teaser::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 80%;
  height: 200%;
  background: radial-gradient(ellipse 40% 40% at center, var(--accent-glow) 0%, transparent 70%);
  pointer-events: none;
}

.pricing-teaser-inner {
  position: relative;
  max-width: 600px;
  margin: 0 auto;
  padding: 0 var(--space-6);
}

.pricing-teaser h2 {
  font-size: var(--text-2xl);
  margin-bottom: var(--space-4);
}

.pricing-teaser .subtitle {
  margin: 0 auto var(--space-6);
  max-width: 500px;
}

.pricing-teaser .link-arrow {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  color: var(--accent);
  font-weight: 600;
  font-size: var(--text-base);
  transition: gap 0.2s var(--ease);
}

.pricing-teaser .link-arrow:hover {
  gap: var(--space-3);
  color: var(--accent-hover);
}

/* ── 12. Final CTA ── */
.cta-section {
  position: relative;
  padding: var(--space-32) 0 var(--space-24);
  text-align: center;
  border-top: 1px solid var(--border);
  overflow: hidden;
}

.cta-section::before {
  content: '';
  position: absolute;
  bottom: -40%;
  left: 50%;
  transform: translateX(-50%);
  width: 100%;
  height: 100%;
  background: radial-gradient(ellipse 60% 50% at center, var(--accent-glow) 0%, transparent 70%);
  pointer-events: none;
}

.cta-inner {
  position: relative;
  max-width: 600px;
  margin: 0 auto;
  padding: 0 var(--space-6);
}

.cta-section h2 {
  font-size: var(--text-3xl);
  margin-bottom: var(--space-4);
}

.cta-section .subtitle {
  margin: 0 auto var(--space-8);
}

/* ── 13. Footer ── */
.footer {
  border-top: 1px solid var(--border);
  padding: var(--space-16) 0 var(--space-8);
  background: var(--bg);
}

.footer-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--space-12);
  max-width: var(--max-width);
  margin: 0 auto var(--space-12);
  padding: 0 var(--space-6);
}

.footer-col h4 {
  font-family: var(--font-sans);
  font-size: var(--text-micro);
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--text-secondary);
  margin-bottom: var(--space-4);
}

.footer-col {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.footer-col a {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  text-decoration: none;
  transition: color 0.2s var(--ease);
}

.footer-col a:hover { color: var(--text); }

.footer-bottom {
  display: flex;
  align-items: center;
  justify-content: space-between;
  max-width: var(--max-width);
  margin: 0 auto;
  padding: var(--space-6) var(--space-6) 0;
  border-top: 1px solid var(--border);
  font-size: var(--text-sm);
  color: var(--text-secondary);
  gap: var(--space-4);
  flex-wrap: wrap;
}

/* ── 14. Comparison Table (for compare page) ── */
.comparison-table {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--text-sm);
}

.comparison-table th,
.comparison-table td {
  padding: var(--space-4) var(--space-6);
  text-align: left;
  border-bottom: 1px solid var(--border);
}

.comparison-table th {
  font-family: var(--font-sans);
  font-size: var(--text-micro);
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-secondary);
  background: var(--surface);
}

.comparison-table tbody tr:hover {
  background: rgba(160, 133, 94, 0.04);
}

.comparison-table .highlight {
  background: rgba(160, 133, 94, 0.08);
}

.check { color: var(--accent); font-weight: 600; }
.dash { color: var(--text-secondary); }

/* ── 15. Pricing Cards (for pricing page) ── */
.pricing-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--space-4);
  max-width: 820px;
  margin: 0 auto;
}

.pricing-card {
  background: var(--surface-elevated);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: var(--space-8);
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  transition: all 0.3s var(--ease);
}

.pricing-card:hover {
  transform: translateY(-2px);
  border-color: var(--border-strong);
  box-shadow: 0 12px 32px hsl(30, 30%, 4%, 0.4);
}

.pricing-card.featured {
  border-color: var(--accent);
  box-shadow:
    0 0 0 1px var(--accent),
    0 0 40px var(--accent-glow);
}

.pricing-card .badge {
  display: inline-block;
  background: var(--accent);
  color: var(--bg);
  font-size: var(--text-micro);
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  padding: 4px 12px;
  border-radius: 999px;
  margin-bottom: var(--space-2);
  align-self: flex-start;
}

.pricing-card h3 {
  font-size: var(--text-xl);
  font-family: var(--font-serif);
  margin-bottom: var(--space-2);
}

.pricing-card .price {
  font-family: var(--font-serif);
  font-size: var(--text-3xl);
  line-height: 1;
  letter-spacing: -0.03em;
  color: var(--text);
}

.pricing-card .period {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  margin-bottom: var(--space-2);
}

.pricing-card .note {
  font-size: var(--text-micro);
  color: var(--text-secondary);
  margin-top: var(--space-2);
}

/* ── 16. FAQ (details/summary) ── */
details {
  border-bottom: 1px solid var(--border);
}

details:first-of-type {
  border-top: 1px solid var(--border);
}

summary {
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  padding: var(--space-6) 0;
  font-size: var(--text-lg);
  font-weight: 500;
  list-style: none;
  user-select: none;
  gap: var(--space-4);
  color: var(--text);
}

summary::-webkit-details-marker { display: none; }

summary::after {
  content: '+';
  font-size: 24px;
  font-weight: 300;
  color: var(--accent);
  flex-shrink: 0;
  line-height: 1;
  transition: transform 0.2s var(--ease);
}

details[open] summary::after {
  content: '−';
}

details[open] summary {
  margin-bottom: var(--space-2);
}

details .faq-body {
  padding: 0 0 var(--space-6);
  color: var(--text-secondary);
  line-height: 1.7;
  font-size: var(--text-base);
}

/* ── 17. Prose (for story, privacy, terms, support pages) ── */
.prose {
  max-width: var(--max-prose);
  margin: 0 auto;
}

.prose-serif {
  font-family: var(--font-serif);
  font-size: var(--text-lg);
  line-height: 1.75;
}

.prose h2, .prose h3 {
  margin-top: 2em;
  margin-bottom: 0.6em;
  letter-spacing: -0.01em;
}

.prose h2 {
  font-size: var(--text-2xl);
}

.prose h3 {
  font-size: var(--text-xl);
}

.prose p, .prose ul, .prose ol {
  margin-bottom: 1.25em;
}

.prose li {
  margin-bottom: 0.4em;
}

.prose a {
  color: var(--accent);
  text-decoration: underline;
  text-underline-offset: 3px;
  text-decoration-thickness: 1px;
}

.prose a:hover {
  color: var(--accent-hover);
}

/* ── 18. Changelog ── */
.changelog-entry {
  border-bottom: 1px solid var(--border);
  padding: var(--space-8) 0;
}

.changelog-entry:first-child { padding-top: 0; }

.changelog-entry .date {
  font-size: var(--text-micro);
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-secondary);
  margin-bottom: var(--space-2);
}

.changelog-entry h3 {
  font-size: var(--text-xl);
  margin-bottom: var(--space-4);
}

.changelog-entry ul {
  color: var(--text-secondary);
  font-size: var(--text-base);
  line-height: 1.65;
}

/* ── 19. Contact Box (for support page) ── */
.contact-box {
  background: var(--surface-elevated);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: var(--space-8);
  transition: border-color 0.2s var(--ease);
  margin: var(--space-6) 0;
}

.contact-box:hover { border-color: var(--accent); }

.contact-box a {
  font-size: var(--text-lg);
  font-weight: 600;
}

/* ── 20. Scroll Reveal ── */
.reveal {
  opacity: 0;
  transform: translateY(24px);
  transition: opacity 0.8s var(--ease-out), transform 0.8s var(--ease-out);
}

.reveal.visible {
  opacity: 1;
  transform: translateY(0);
}

.reveal-delay-1 { transition-delay: 0.1s; }
.reveal-delay-2 { transition-delay: 0.2s; }
.reveal-delay-3 { transition-delay: 0.3s; }

/* ── 21. Utilities ── */
.section--flush { padding-top: 0; }
.text-center { text-align: center; }

/* ── 22. Responsive ── */
@media (max-width: 900px) {
  .feature-grid { grid-template-columns: repeat(2, 1fr); }

  .graph-inner {
    grid-template-columns: 1fr;
    gap: var(--space-12);
    text-align: center;
  }

  .graph-text .subtitle { margin-left: auto; margin-right: auto; }

  .graph-image img { max-width: 320px; }
}

@media (max-width: 768px) {
  .nav-links,
  .nav-cta { display: none; }

  .nav-hamburger {
    display: flex;
    align-items: center;
    justify-content: center;
  }
}

@media (max-width: 700px) {
  .footer-grid {
    grid-template-columns: 1fr;
    gap: var(--space-8);
  }

  .footer-bottom {
    flex-direction: column;
    align-items: flex-start;
  }

  .pricing-cards { grid-template-columns: 1fr; }
}

@media (max-width: 600px) {
  .hero { padding: var(--space-16) 0 var(--space-12); }
  .section { padding: var(--space-16) 0; }
  .graph-feature { padding: var(--space-16) 0; }
  .features-section { padding: var(--space-16) 0; }
  .cta-section { padding: var(--space-20) 0 var(--space-16); }

  .features-section .section-heading { margin-bottom: var(--space-12); }

  .feature-card { padding: var(--space-6); }
}

@media (max-width: 500px) {
  .feature-grid { grid-template-columns: 1fr; }
}
```

- [ ] **Step 2: Verify file was written**

Run:
```bash
wc -l /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/styles.css
```

Expected: ~850-900 lines

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/styles.css
git commit -m "feat(site): rewrite stylesheet with dark-first editorial design system"
```

---

### Task 3: Rewrite index.html with new structure

**Files:**
- Replace: `docs/index.html`

New hero with italic accent, knowledge graph feature section, compact feature grid, pricing teaser, dramatic CTA.

- [ ] **Step 1: Write the new index.html**

Replace the entire contents of `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/index.html` with:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <link rel="icon" href="/favicon.png" type="image/png">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Haven Notes — Private markdown notes for iOS</title>
  <meta name="description" content="Markdown notes with wiki links and a knowledge graph. Private by design. End-to-end encrypted. No AI. No tracking.">
  <meta property="og:title" content="Haven Notes — Private markdown notes for iOS">
  <meta property="og:description" content="Markdown notes with wiki links and a knowledge graph. Private by design. End-to-end encrypted.">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://havennotes.app/">
  <link rel="canonical" href="https://havennotes.app/">
  <link rel="stylesheet" href="styles.css">
</head>
<body>

<nav class="nav" id="nav">
  <div class="nav-inner">
    <a href="/" class="nav-logo">Haven</a>
    <div class="nav-links">
      <a href="/#features">Features</a>
      <a href="/pricing">Pricing</a>
      <a href="/story">Story</a>
      <a href="/compare">Compare</a>
      <a href="https://apps.apple.com/app/id6744229406" class="nav-cta">Download</a>
    </div>
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu" aria-expanded="false" aria-controls="mobile-menu">
      <span aria-hidden="true"></span><span aria-hidden="true"></span><span aria-hidden="true"></span>
    </button>
  </div>
  <div class="nav-mobile" id="mobile-menu">
    <a href="/#features">Features</a>
    <a href="/pricing">Pricing</a>
    <a href="/story">Story</a>
    <a href="/compare">Compare</a>
    <a href="https://apps.apple.com/app/id6744229406">Download</a>
  </div>
</nav>

<main>
  <!-- Hero -->
  <section class="hero">
    <div class="hero-inner">
      <span class="eyebrow reveal">Haven — Private notes for iOS</span>
      <h1 class="reveal reveal-delay-1">
        Your thoughts,<br>
        <span class="accent-italic">beautifully organized.</span>
      </h1>
      <p class="subtitle reveal reveal-delay-2">
        Markdown notes with wiki links and a visual knowledge graph. Private by design. Encrypted end to end. No AI. No tracking.
      </p>
      <div class="hero-buttons reveal reveal-delay-3">
        <a href="https://apps.apple.com/app/id6744229406" class="btn btn-primary">Download for iOS</a>
        <a href="#graph" class="btn btn-outline">See it in action</a>
      </div>
      <div class="hero-image reveal reveal-delay-3">
        <img src="assets/screenshot.png" alt="Haven Notes app showing the markdown editor with wiki links" width="320" height="640">
      </div>
    </div>
  </section>

  <!-- Knowledge Graph Hero Feature -->
  <section class="graph-feature" id="graph">
    <div class="graph-inner">
      <div class="graph-text">
        <span class="eyebrow reveal">The Knowledge Graph</span>
        <h2 class="reveal reveal-delay-1">
          See how ideas<br>
          <span class="accent-italic">connect.</span>
        </h2>
        <p class="subtitle reveal reveal-delay-2">
          Link notes with <code>[[double brackets]]</code>. Watch your thinking form a living network. The graph reveals connections you didn't know existed.
        </p>
        <a href="/story" class="link-arrow reveal reveal-delay-2">
          Why we built this →
        </a>
      </div>
      <div class="graph-image reveal reveal-delay-1">
        <img src="assets/graph.png" alt="Haven knowledge graph showing connected notes" loading="lazy">
      </div>
    </div>
  </section>

  <!-- Features Grid -->
  <section class="features-section" id="features">
    <div class="container">
      <div class="section-heading reveal">
        <span class="eyebrow">Built for thinkers</span>
        <h2>
          Everything you need,<br>
          <span class="accent-italic">nothing you don't.</span>
        </h2>
      </div>

      <div class="feature-grid">
        <div class="feature-card reveal">
          <span class="emoji" aria-hidden="true">✏️</span>
          <h3>Live Markdown</h3>
          <p>Bold, italic, headings, and code — rendered as you type. No mode switching.</p>
        </div>
        <div class="feature-card reveal reveal-delay-1">
          <span class="emoji" aria-hidden="true">🔗</span>
          <h3>Wiki Links</h3>
          <p>Connect notes with <code>[[brackets]]</code>. Build a personal knowledge network.</p>
        </div>
        <div class="feature-card reveal reveal-delay-2">
          <span class="emoji" aria-hidden="true">🔒</span>
          <h3>E2E Encrypted</h3>
          <p>AES-256 encryption. Keys live on your device. Not even we can read your notes.</p>
        </div>
        <div class="feature-card reveal">
          <span class="emoji" aria-hidden="true">📅</span>
          <h3>Daily Notes</h3>
          <p>A fresh note every day, automatically. Perfect for journaling and rhythm.</p>
        </div>
        <div class="feature-card reveal reveal-delay-1">
          <span class="emoji" aria-hidden="true">🎤</span>
          <h3>Voice Dictation</h3>
          <p>Capture thoughts hands-free. On-device processing. Nothing leaves your phone.</p>
        </div>
        <div class="feature-card reveal reveal-delay-2">
          <span class="emoji" aria-hidden="true">🔍</span>
          <h3>Full-Text Search</h3>
          <p>Find anything instantly. Fast, on-device, no indexing delays.</p>
        </div>
      </div>
    </div>
  </section>

  <!-- Pricing Teaser -->
  <section class="pricing-teaser">
    <div class="pricing-teaser-inner">
      <span class="eyebrow reveal">Pricing</span>
      <h2 class="reveal reveal-delay-1">
        Free forever.<br>
        Pro <span class="accent-italic">unlocks sync.</span>
      </h2>
      <p class="subtitle reveal reveal-delay-2">
        All core features are free. Haven Pro adds cloud sync and end-to-end encryption — $2.99/month or $19.99/year.
      </p>
      <a href="/pricing" class="link-arrow reveal reveal-delay-2">
        See full pricing →
      </a>
    </div>
  </section>

  <!-- Final CTA -->
  <section class="cta-section">
    <div class="cta-inner">
      <h2 class="reveal">
        Ready to<br>
        <span class="accent-italic">start writing?</span>
      </h2>
      <p class="subtitle reveal reveal-delay-1">
        Haven is free to download. Pro unlocks sync when you need it.
      </p>
      <div class="reveal reveal-delay-2">
        <a href="https://apps.apple.com/app/id6744229406" class="btn btn-primary">Download for iOS</a>
      </div>
    </div>
  </section>
</main>

<footer class="footer">
  <div class="footer-grid">
    <div class="footer-col">
      <h4>Pages</h4>
      <a href="/">Home</a>
      <a href="/pricing">Pricing</a>
      <a href="/story">Story</a>
      <a href="/compare">Compare</a>
      <a href="/changelog">Changelog</a>
    </div>
    <div class="footer-col">
      <h4>Legal</h4>
      <a href="/privacy">Privacy Policy</a>
      <a href="/terms">Terms of Use</a>
    </div>
    <div class="footer-col">
      <h4>Connect</h4>
      <a href="mailto:support@havennotes.app">support@havennotes.app</a>
      <a href="/support">Support</a>
      <a href="https://apps.apple.com/app/id6744229406">App Store</a>
    </div>
  </div>
  <div class="footer-bottom">
    <span>Made by one person who was tired of bloated note apps.</span>
    <span>&copy; 2026 Haven Notes</span>
  </div>
</footer>

<script>
// Nav scroll effect
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 10);
}, { passive: true });

// Scroll reveal
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.15, rootMargin: '0px 0px -50px 0px' });

document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
</script>

</body>
</html>
```

- [ ] **Step 2: Verify page loads in local server**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs && npx serve -l 4444 -s --no-clipboard &
sleep 2
curl -sI http://localhost:4444/ | head -3
```

Expected: HTTP 200

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/index.html
git commit -m "feat(site): rewrite landing page with dark hero, graph feature, and new CTA"
```

---

### Task 4: Apply new theme to pricing.html

**Files:**
- Modify: `docs/pricing.html`

The content stays the same. Only visual styling classes need updating to match the new dark theme. The existing CSS classes (`.pricing-cards`, `.pricing-card`, `.feature`, `.comparison-table`) are already styled in the new stylesheet — the HTML structure just needs to use the new eyebrow/accent-italic treatment for headlines.

- [ ] **Step 1: Read the current pricing.html**

Run:
```bash
cat /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/pricing.html | head -80
```

- [ ] **Step 2: Update the heading treatment**

In `docs/pricing.html`, find the main page heading section (likely with h1 "Simple, honest pricing") and replace it with:

```html
<section class="section section-centered">
  <div class="container">
    <span class="eyebrow">Pricing</span>
    <h1>Simple, <span class="accent-italic">honest pricing.</span></h1>
    <p class="subtitle" style="margin:16px auto 0;">Haven is free. Pro unlocks sync.</p>
  </div>
</section>
```

- [ ] **Step 3: Update the FAQ heading**

Find the "Frequently asked questions" heading and change it to:
```html
<h2 style="text-align:center;margin-bottom:40px;">Frequently asked <span class="accent-italic">questions</span></h2>
```

- [ ] **Step 4: Update the final CTA heading**

Find "Ready to start writing?" and change it to:
```html
<h2>Ready to <span class="accent-italic">start writing?</span></h2>
```

- [ ] **Step 5: Verify in browser**

Run: `curl -sI http://localhost:4444/pricing | head -3`
Expected: HTTP 200

- [ ] **Step 6: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/pricing.html
git commit -m "feat(site): apply dark theme and italic accent to pricing page"
```

---

### Task 5: Apply new theme to story.html

**Files:**
- Modify: `docs/story.html`

- [ ] **Step 1: Update the page heading**

In `docs/story.html`, find the main h1 section and update to use the new eyebrow + accent pattern:

```html
<span class="eyebrow">The story</span>
<h1>Why <span class="accent-italic">Haven exists.</span></h1>
<p class="subtitle">Built by one person who was tired of bloated note apps.</p>
```

- [ ] **Step 2: Update the CTA heading**

Find "Ready to start writing?" near the bottom and change to:
```html
<h2>Ready to <span class="accent-italic">start writing?</span></h2>
```

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/story.html
git commit -m "feat(site): apply dark theme and italic accent to story page"
```

---

### Task 6: Apply new theme to compare.html

**Files:**
- Modify: `docs/compare.html`

- [ ] **Step 1: Update the page heading**

In `docs/compare.html`, find the main h1 section:

```html
<span class="eyebrow">Compare</span>
<h1>Haven vs <span class="accent-italic">the rest.</span></h1>
<p class="subtitle" style="margin:16px auto 0;">Haven isn't trying to be everything. It's trying to be the best at what matters.</p>
```

- [ ] **Step 2: Update the "How Haven is different" heading**

Find the section heading and update to:
```html
<h2>How Haven is <span class="accent-italic">different.</span></h2>
```

- [ ] **Step 3: Update the CTA heading**

Find the CTA section and change to:
```html
<h2>Try Haven <span class="accent-italic">for free.</span></h2>
```

- [ ] **Step 4: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/compare.html
git commit -m "feat(site): apply dark theme and italic accent to compare page"
```

---

### Task 7: Apply new theme to changelog.html

**Files:**
- Modify: `docs/changelog.html`

- [ ] **Step 1: Update the page heading**

In `docs/changelog.html`:
```html
<span class="eyebrow">Updates</span>
<h1><span class="accent-italic">Changelog.</span></h1>
<p class="subtitle">What's new in Haven.</p>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/changelog.html
git commit -m "feat(site): apply dark theme and italic accent to changelog page"
```

---

### Task 8: Apply new theme to privacy.html

**Files:**
- Modify: `docs/privacy.html`

- [ ] **Step 1: Update the page heading**

In `docs/privacy.html`:
```html
<span class="eyebrow">Legal</span>
<h1>Privacy <span class="accent-italic">Policy.</span></h1>
<p class="subtitle">Last updated: March 30, 2026</p>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/privacy.html
git commit -m "feat(site): apply dark theme and italic accent to privacy page"
```

---

### Task 9: Apply new theme to terms.html

**Files:**
- Modify: `docs/terms.html`

- [ ] **Step 1: Update the page heading**

In `docs/terms.html`:
```html
<span class="eyebrow">Legal</span>
<h1>Terms <span class="accent-italic">of Use.</span></h1>
<p class="subtitle">Last updated: April 8, 2026</p>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/terms.html
git commit -m "feat(site): apply dark theme and italic accent to terms page"
```

---

### Task 10: Apply new theme to support.html

**Files:**
- Modify: `docs/support.html`

- [ ] **Step 1: Update the page heading**

In `docs/support.html`:
```html
<span class="eyebrow">Help</span>
<h1><span class="accent-italic">Support.</span></h1>
<p class="subtitle">We're here to help.</p>
```

- [ ] **Step 2: Update the FAQ heading**

Find "Frequently Asked Questions" and change to:
```html
<h2>Frequently asked <span class="accent-italic">questions</span></h2>
```

- [ ] **Step 3: Update System Requirements heading**

Find and change to:
```html
<h2>System <span class="accent-italic">Requirements</span></h2>
```

- [ ] **Step 4: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/support.html
git commit -m "feat(site): apply dark theme and italic accent to support page"
```

---

### Task 11: Final verification and smoke test

**Files:** All pages

- [ ] **Step 1: Start local server**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs && npx serve -l 4444 -s --no-clipboard &
sleep 2
```

- [ ] **Step 2: Verify all 8 pages return 200**

Run:
```bash
for page in / pricing story compare changelog privacy terms support; do
  echo -n "$page: "
  curl -sI "http://localhost:4444$page" | head -1
done
```

Expected: All pages return `HTTP/1.1 200 OK`

- [ ] **Step 3: Verify styles.css loads**

Run:
```bash
curl -sI http://localhost:4444/styles.css | head -3
```

Expected: HTTP 200, Content-Type: text/css

- [ ] **Step 4: Verify graph asset loads**

Run:
```bash
curl -sI http://localhost:4444/assets/graph.png | head -3
```

Expected: HTTP 200, Content-Type: image/png

- [ ] **Step 5: Visual check with Playwright screenshot**

Use the Playwright MCP tools to navigate to http://localhost:4444 and take a full-page screenshot. Visually verify:
- Dark background throughout
- Amber glow behind hero
- Italic accent words in amber
- Feature cards on dark surface
- Knowledge graph section with screenshot

Save to: `smoke-test/rebuild-final.png`

- [ ] **Step 6: Final commit (if anything remains)**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git status
```

If nothing to commit, proceed to push.

- [ ] **Step 7: Push and deploy**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git push origin main
cd docs
vercel --yes --prod
```

Expected: Deployment completes, URL returned.

- [ ] **Step 8: Verify live site**

Run:
```bash
sleep 5
curl -sI https://havennotes.app | head -3
```

Expected: HTTP 200 from live site.
