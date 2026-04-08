# havennotes.app Website Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a static marketing website for Haven Notes with 8 pages, shared CSS, dark mode, and mobile-responsive layout.

**Architecture:** Static HTML + single shared CSS file. No frameworks, no build step, no JS dependencies. Each page includes shared nav/footer markup. Mobile hamburger menu uses ~10 lines of inline JS.

**Tech Stack:** HTML5, CSS3 (custom properties, grid, flexbox, `prefers-color-scheme`), minimal inline JS for mobile nav toggle only.

---

## File Structure

```
docs/
  styles.css          — Shared stylesheet (CSS custom properties, nav, footer, grids, dark mode)
  index.html          — Landing page (hero, feature grid, CTA)
  pricing.html        — Pricing (free vs pro table, subscription cards, FAQ)
  story.html          — About / narrative page
  compare.html        — Haven vs competitors table
  changelog.html      — Version history
  privacy.html        — Privacy policy (existing content, new template)
  terms.html          — Terms of use (existing content, new template)
  support.html        — Support (existing content, new template)
  assets/
    screenshot.png    — App screenshot for hero (placeholder until real screenshot added)
```

**Existing files to replace:** `docs/index.html`, `docs/privacy.html`, `docs/terms.html`, `docs/support.html`
**New files:** `docs/styles.css`, `docs/pricing.html`, `docs/story.html`, `docs/compare.html`, `docs/changelog.html`, `docs/assets/`

---

### Task 1: Shared Stylesheet (`styles.css`)

**Files:**
- Create: `docs/styles.css`

This is the foundation — every page depends on it. Defines CSS custom properties, reset, typography, nav, footer, grid utilities, card styles, dark mode, and responsive breakpoints.

- [ ] **Step 1: Create `docs/styles.css` with CSS reset, custom properties, and typography**

```css
/* docs/styles.css — Haven Notes website */

/* ── Reset ── */
*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

/* ── Custom Properties (Light) ── */
:root {
  --bg: #FEFDFB;
  --surface: #FAF7F3;
  --text: #1A1815;
  --text-secondary: #6B6560;
  --border: #E8E2DA;
  --accent: #8B6F47;
  --accent-hover: #7A6140;
  --link-hover: #6B9B8E;
  --font-serif: Georgia, 'Times New Roman', serif;
  --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-mono: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, monospace;
  --max-width: 1080px;
  --section-pad: 80px;
  --section-pad-mobile: 48px;
}

/* ── Dark Mode ── */
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #161512;
    --surface: #1E1B17;
    --text: #FAF7F3;
    --text-secondary: #A89E94;
    --border: #3D3730;
    --accent: #A0855E;
    --accent-hover: #B8996A;
    --link-hover: #7BAFA2;
  }
}

/* ── Base ── */
html { scroll-behavior: smooth; }
body {
  font-family: var(--font-sans);
  background: var(--bg);
  color: var(--text);
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
}
a { color: var(--accent); text-decoration: none; transition: color 0.15s; }
a:hover { color: var(--link-hover); }
img { max-width: 100%; height: auto; display: block; }
code { font-family: var(--font-mono); font-size: 0.9em; background: var(--surface); padding: 2px 6px; border-radius: 4px; }

/* ── Typography ── */
h1, h2, h3 { font-family: var(--font-serif); color: var(--text); line-height: 1.2; }
h1 { font-size: 48px; font-weight: 700; }
h2 { font-size: 32px; font-weight: 700; }
h3 { font-size: 22px; font-weight: 600; }
.eyebrow {
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  color: var(--text-secondary);
}
.subtitle {
  font-size: 18px;
  color: var(--text-secondary);
  line-height: 1.6;
}

/* ── Layout ── */
.container { max-width: var(--max-width); margin: 0 auto; padding: 0 24px; }
.section { padding: var(--section-pad) 0; }
.section-centered { text-align: center; }

@media (max-width: 768px) {
  h1 { font-size: 36px; }
  h2 { font-size: 26px; }
  .section { padding: var(--section-pad-mobile) 0; }
}
```

- [ ] **Step 2: Add navigation styles**

Append to `docs/styles.css`:

```css
/* ── Navigation ── */
.nav {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--bg);
  border-bottom: 1px solid var(--border);
  transition: background 0.2s;
}
.nav.scrolled {
  background: color-mix(in srgb, var(--bg) 85%, transparent);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}
.nav-inner {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 64px;
}
.nav-logo {
  font-family: var(--font-serif);
  font-size: 20px;
  font-weight: 600;
  color: var(--text);
  text-decoration: none;
}
.nav-logo:hover { color: var(--text); }
.nav-links { display: flex; align-items: center; gap: 32px; }
.nav-links a {
  font-size: 14px;
  color: var(--text-secondary);
  text-decoration: none;
  transition: color 0.15s;
}
.nav-links a:hover { color: var(--text); }
.nav-cta {
  font-size: 14px;
  font-weight: 500;
  padding: 8px 20px;
  background: var(--accent);
  color: #fff !important;
  border-radius: 8px;
  transition: background 0.15s;
}
.nav-cta:hover { background: var(--accent-hover); color: #fff !important; }

/* Hamburger (mobile) */
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
  gap: 0;
  background: var(--bg);
  border-bottom: 1px solid var(--border);
  padding: 8px 24px 16px;
}
.nav-mobile a {
  display: block;
  padding: 12px 0;
  font-size: 16px;
  color: var(--text-secondary);
  border-bottom: 1px solid var(--border);
}
.nav-mobile a:last-child { border-bottom: none; }
.nav-mobile a:hover { color: var(--text); }
.nav-mobile.open { display: flex; }

@media (max-width: 768px) {
  .nav-links { display: none; }
  .nav-hamburger { display: block; }
}
```

- [ ] **Step 3: Add footer styles**

Append to `docs/styles.css`:

```css
/* ── Footer ── */
.footer {
  border-top: 1px solid var(--border);
  padding: 48px 0 32px;
  color: var(--text-secondary);
  font-size: 14px;
}
.footer-grid {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 24px;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
}
.footer-col h4 {
  font-family: var(--font-sans);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: var(--text-secondary);
  margin-bottom: 16px;
}
.footer-col a {
  display: block;
  color: var(--text-secondary);
  font-size: 14px;
  padding: 4px 0;
}
.footer-col a:hover { color: var(--text); }
.footer-bottom {
  max-width: var(--max-width);
  margin: 32px auto 0;
  padding: 24px 24px 0;
  border-top: 1px solid var(--border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  font-size: 13px;
  color: var(--text-secondary);
}

@media (max-width: 768px) {
  .footer-grid { grid-template-columns: 1fr; gap: 24px; }
  .footer-bottom { flex-direction: column; text-align: center; }
}
```

- [ ] **Step 4: Add component styles (buttons, cards, feature grid, hero, tables)**

Append to `docs/styles.css`:

```css
/* ── Buttons ── */
.btn {
  display: inline-block;
  font-family: var(--font-sans);
  font-size: 15px;
  font-weight: 500;
  padding: 12px 28px;
  border-radius: 8px;
  transition: background 0.15s, color 0.15s;
  cursor: pointer;
  text-decoration: none;
}
.btn-primary { background: var(--accent); color: #fff; }
.btn-primary:hover { background: var(--accent-hover); color: #fff; }
.btn-outline { background: transparent; color: var(--text); border: 1px solid var(--border); }
.btn-outline:hover { border-color: var(--text-secondary); color: var(--text); }

/* ── Hero ── */
.hero { padding: 80px 0 40px; }
.hero-inner {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  align-items: center;
  gap: 48px;
}
.hero-text { flex: 1; }
.hero-text .eyebrow { margin-bottom: 16px; }
.hero-text h1 { margin-bottom: 16px; }
.hero-text .subtitle { margin-bottom: 32px; max-width: 480px; }
.hero-buttons { display: flex; gap: 12px; flex-wrap: wrap; }
.hero-image { flex: 0 0 360px; display: flex; justify-content: center; }
.hero-image img { max-width: 300px; border-radius: 24px; box-shadow: 0 16px 48px rgba(0,0,0,0.08); }

@media (max-width: 768px) {
  .hero-inner { flex-direction: column; text-align: center; }
  .hero-text .subtitle { margin-left: auto; margin-right: auto; }
  .hero-buttons { justify-content: center; }
  .hero-image { flex: none; }
  .hero-image img { max-width: 240px; }
}

/* ── Feature Grid ── */
.feature-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.feature-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 24px;
}
.feature-card .emoji { font-size: 28px; margin-bottom: 12px; }
.feature-card h3 {
  font-family: var(--font-sans);
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 6px;
}
.feature-card p { font-size: 14px; color: var(--text-secondary); line-height: 1.5; }

@media (min-width: 900px) {
  .feature-grid { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 500px) {
  .feature-grid { grid-template-columns: 1fr; }
}

/* ── CTA Section ── */
.cta-section {
  text-align: center;
  padding: var(--section-pad) 0;
}
.cta-section h2 { margin-bottom: 16px; }
.cta-section .subtitle { margin-bottom: 32px; }
.cta-section .caption {
  margin-top: 12px;
  font-size: 13px;
  color: var(--text-secondary);
}

/* ── Tables ── */
.comparison-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}
.comparison-table th, .comparison-table td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid var(--border);
}
.comparison-table th {
  font-family: var(--font-sans);
  font-weight: 600;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--text-secondary);
}
.comparison-table td:first-child { font-weight: 500; }
.comparison-table .highlight {
  background: color-mix(in srgb, var(--accent) 8%, transparent);
}
.check { color: var(--accent); }
.dash { color: var(--text-secondary); }

/* ── Pricing Cards ── */
.pricing-cards { display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; max-width: 600px; margin: 0 auto; }
.pricing-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 32px 24px;
  text-align: center;
}
.pricing-card.featured { border-color: var(--accent); border-width: 2px; }
.pricing-card .badge {
  display: inline-block;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: #fff;
  background: var(--accent);
  padding: 4px 10px;
  border-radius: 4px;
  margin-bottom: 12px;
}
.pricing-card .price {
  font-family: var(--font-serif);
  font-size: 36px;
  font-weight: 700;
  margin: 8px 0 4px;
}
.pricing-card .period { font-size: 14px; color: var(--text-secondary); margin-bottom: 16px; }
.pricing-card .note { font-size: 12px; color: var(--text-secondary); }

@media (max-width: 500px) {
  .pricing-cards { grid-template-columns: 1fr; }
}

/* ── FAQ ── */
details { border-bottom: 1px solid var(--border); }
details summary {
  padding: 16px 0;
  font-weight: 500;
  cursor: pointer;
  list-style: none;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
details summary::after { content: '+'; font-size: 20px; color: var(--text-secondary); }
details[open] summary::after { content: '−'; }
details summary::-webkit-details-marker { display: none; }
details p { padding: 0 0 16px; color: var(--text-secondary); line-height: 1.6; }

/* ── Prose (Story, Privacy, Terms, Support) ── */
.prose { max-width: 640px; margin: 0 auto; }
.prose h1 { margin-bottom: 8px; }
.prose .subtitle { margin-bottom: 40px; }
.prose h2 { margin-top: 40px; margin-bottom: 12px; font-size: 26px; }
.prose h3 { margin-top: 28px; margin-bottom: 8px; font-size: 20px; }
.prose p, .prose li { font-size: 16px; margin-bottom: 16px; line-height: 1.7; }
.prose ul { padding-left: 24px; }
.prose li { margin-bottom: 8px; }
.prose-serif { font-family: var(--font-serif); }
.prose-serif p, .prose-serif li { font-family: var(--font-serif); }

/* ── Changelog ── */
.changelog-entry { padding: 32px 0; border-bottom: 1px solid var(--border); }
.changelog-entry:last-child { border-bottom: none; }
.changelog-entry .date { font-size: 13px; color: var(--text-secondary); margin-bottom: 4px; }
.changelog-entry h3 { margin-bottom: 12px; }
.changelog-entry ul { padding-left: 20px; }
.changelog-entry li { font-size: 15px; margin-bottom: 6px; color: var(--text-secondary); }

/* ── Contact Box ── */
.contact-box {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 24px;
  margin: 24px 0;
}
.contact-box a { font-size: 18px; font-weight: 600; }

/* ── Pull Quote ── */
.pull-quote {
  font-family: var(--font-serif);
  font-size: 24px;
  font-weight: 600;
  color: var(--text);
  text-align: center;
  padding: 48px 0;
  max-width: 500px;
  margin: 0 auto;
  line-height: 1.4;
}
```

- [ ] **Step 5: Verify file was created**

Run: `ls -la docs/styles.css && wc -l docs/styles.css`
Expected: File exists, ~300-350 lines

- [ ] **Step 6: Commit**

```bash
git add docs/styles.css
git commit -m "feat(site): add shared stylesheet with design tokens, nav, footer, and components"
```

---

### Task 2: Landing Page (`index.html`)

**Files:**
- Replace: `docs/index.html`

- [ ] **Step 1: Create `docs/index.html` with nav, hero, feature grid, CTA, and footer**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Haven Notes — Fast, Private Markdown Notes for iOS</title>
<meta name="description" content="Fast, private markdown notes with wiki links, a knowledge graph, and end-to-end encryption. Your notes stay on your device.">
<meta property="og:title" content="Haven Notes — Fast, Private Markdown Notes for iOS">
<meta property="og:description" content="Fast, private markdown notes with wiki links, a knowledge graph, and end-to-end encryption.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://havennotes.app/">
<link rel="canonical" href="https://havennotes.app/">
<link rel="stylesheet" href="styles.css">
</head>
<body>

<!-- Navigation -->
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
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu">
      <span></span><span></span><span></span>
    </button>
  </div>
  <div class="nav-mobile" id="mobile-menu">
    <a href="/#features" onclick="document.getElementById('mobile-menu').classList.remove('open')">Features</a>
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
      <div class="hero-text">
        <span class="eyebrow">Haven Notes</span>
        <h1>Your notes deserve a quiet home.</h1>
        <p class="subtitle">Fast, private markdown notes with wiki links and end-to-end encryption. No AI. No cloud. Just yours.</p>
        <div class="hero-buttons">
          <a href="https://apps.apple.com/app/id6744229406" class="btn btn-primary">Download for iOS</a>
          <a href="#features" class="btn btn-outline">See features</a>
        </div>
      </div>
      <div class="hero-image">
        <img src="assets/screenshot.png" alt="Haven Notes app showing a note with wiki links" width="300" height="600">
      </div>
    </div>
  </section>

  <!-- Features -->
  <section class="section" id="features">
    <div class="container section-centered">
      <h2>Everything you need, nothing you don't.</h2>
      <p class="subtitle" style="margin-bottom:48px;">A note-taking app that respects your time, your privacy, and your intelligence.</p>
      <div class="feature-grid">
        <div class="feature-card">
          <div class="emoji">✏️</div>
          <h3>Live Markdown</h3>
          <p>Bold, italic, headings, and code — rendered as you type. No toolbar needed.</p>
        </div>
        <div class="feature-card">
          <div class="emoji">🔗</div>
          <h3>Wiki Links</h3>
          <p>Connect notes with [[links]] and see your knowledge graph grow.</p>
        </div>
        <div class="feature-card">
          <div class="emoji">🔒</div>
          <h3>E2E Encrypted</h3>
          <p>AES-256 encryption. Not even we can read your notes.</p>
        </div>
        <div class="feature-card">
          <div class="emoji">📅</div>
          <h3>Daily Notes</h3>
          <p>One-tap daily journal with automatic dating.</p>
        </div>
        <div class="feature-card">
          <div class="emoji">🎤</div>
          <h3>Voice Notes</h3>
          <p>Dictate your thoughts. On-device speech processing.</p>
        </div>
        <div class="feature-card">
          <div class="emoji">🔍</div>
          <h3>Full-Text Search</h3>
          <p>Find anything instantly across all your notes.</p>
        </div>
      </div>
    </div>
  </section>

  <!-- Pull Quote -->
  <div class="container">
    <p class="pull-quote">No AI. No bloat. Just notes.</p>
  </div>

  <!-- CTA -->
  <section class="cta-section">
    <div class="container">
      <h2>Ready to start writing?</h2>
      <p class="subtitle">Haven is free to download. Pro unlocks sync.</p>
      <div style="margin-top:32px;">
        <a href="https://apps.apple.com/app/id6744229406" class="btn btn-primary">Download for iOS</a>
      </div>
      <p class="caption" style="margin-top:12px;">Free to use · Pro unlocks sync</p>
    </div>
  </section>
</main>

<!-- Footer -->
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
      <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a>
      <a href="/support">Support</a>
      <a href="https://apps.apple.com/app/id6744229406">App Store</a>
    </div>
  </div>
  <div class="footer-bottom">
    <span>Made by one person who was tired of bloated note apps.</span>
    <span>&copy; 2026 Haven Notes</span>
  </div>
</footer>

<!-- Nav scroll effect -->
<script>
window.addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 10);
});
</script>

</body>
</html>
```

- [ ] **Step 2: Create `docs/assets/` directory and add a placeholder screenshot**

Run: `mkdir -p docs/assets`

Note: The actual app screenshot (`screenshot.png`) should be added manually — take a screenshot from the iOS simulator showing the note editor with wiki links in dark mode. For now, the `<img>` tag will show the alt text.

- [ ] **Step 3: Open in browser and verify**

Run: `cd docs && python3 -m http.server 8080`

Check: nav layout, hero split, feature grid (2-col on small, 3-col on wide), CTA section, footer columns, dark mode toggle via system prefs.

- [ ] **Step 4: Commit**

```bash
git add docs/index.html docs/assets/
git commit -m "feat(site): add landing page with hero, feature grid, and CTA"
```

---

### Task 3: Pricing Page (`pricing.html`)

**Files:**
- Create: `docs/pricing.html`

- [ ] **Step 1: Create `docs/pricing.html` with free vs pro table, subscription cards, and FAQ**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Pricing — Haven Notes</title>
<meta name="description" content="Haven is free to use. Haven Pro unlocks cloud sync and end-to-end encryption.">
<meta property="og:title" content="Pricing — Haven Notes">
<meta property="og:description" content="Haven is free to use. Haven Pro unlocks cloud sync and end-to-end encryption.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://havennotes.app/pricing">
<link rel="canonical" href="https://havennotes.app/pricing">
<link rel="stylesheet" href="styles.css">
</head>
<body>

<!-- Navigation (same as index.html) -->
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
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu">
      <span></span><span></span><span></span>
    </button>
  </div>
  <div class="nav-mobile" id="mobile-menu">
    <a href="/#features" onclick="document.getElementById('mobile-menu').classList.remove('open')">Features</a>
    <a href="/pricing">Pricing</a>
    <a href="/story">Story</a>
    <a href="/compare">Compare</a>
    <a href="https://apps.apple.com/app/id6744229406">Download</a>
  </div>
</nav>

<main>
  <section class="section">
    <div class="container section-centered">
      <h1>Simple, honest pricing</h1>
      <p class="subtitle" style="margin-top:12px;">Haven is free. Pro unlocks sync.</p>
    </div>
  </section>

  <!-- Free vs Pro -->
  <section class="section" style="padding-top:0;">
    <div class="container">
      <div style="overflow-x:auto;">
        <table class="comparison-table">
          <thead>
            <tr>
              <th>Feature</th>
              <th>Free</th>
              <th class="highlight">Pro</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>Local notes</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Markdown editor</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Wiki links</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Knowledge graph</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Tags &amp; folders</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Daily notes</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Voice dictation</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Full-text search</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Widgets</td><td class="check">✓</td><td class="check highlight">✓</td></tr>
            <tr><td>Cloud sync</td><td class="dash">—</td><td class="check highlight">✓</td></tr>
            <tr><td>E2E encrypted sync</td><td class="dash">—</td><td class="check highlight">✓</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- Pricing Cards -->
  <section class="section" style="padding-top:0;">
    <div class="container">
      <div class="pricing-cards">
        <div class="pricing-card">
          <h3>Monthly</h3>
          <div class="price">$2.99</div>
          <div class="period">per month</div>
          <a href="https://apps.apple.com/app/id6744229406" class="btn btn-outline" style="width:100%;">Subscribe</a>
          <p class="note" style="margin-top:12px;">Auto-renewable · Cancel anytime</p>
        </div>
        <div class="pricing-card featured">
          <span class="badge">Best value</span>
          <h3>Yearly</h3>
          <div class="price">$19.99</div>
          <div class="period">per year</div>
          <a href="https://apps.apple.com/app/id6744229406" class="btn btn-primary" style="width:100%;">Subscribe</a>
          <p class="note" style="margin-top:12px;">Auto-renewable · Cancel anytime</p>
        </div>
      </div>
    </div>
  </section>

  <!-- FAQ -->
  <section class="section" style="padding-top:0;">
    <div class="container" style="max-width:640px;">
      <h2 style="margin-bottom:24px;">Questions</h2>
      <details>
        <summary>Can I use Haven for free?</summary>
        <p>Yes. All core features — markdown editor, wiki links, knowledge graph, tags, folders, daily notes, voice dictation, full-text search, and widgets — are free forever.</p>
      </details>
      <details>
        <summary>What does Pro add?</summary>
        <p>Cloud sync to your own server and end-to-end encryption. Everything else is included in the free version.</p>
      </details>
      <details>
        <summary>How do I cancel?</summary>
        <p>Open your device Settings → tap your name → Subscriptions → Haven Pro → Cancel. Your subscription continues until the end of the current billing period.</p>
      </details>
      <details>
        <summary>Is my data private?</summary>
        <p>Yes. Notes are stored locally on your device. Haven collects no analytics, no telemetry, no personal data. If you enable sync, notes are encrypted before leaving your device.</p>
      </details>
    </div>
  </section>

  <!-- CTA -->
  <section class="cta-section">
    <div class="container">
      <h2>Ready to start writing?</h2>
      <div style="margin-top:24px;">
        <a href="https://apps.apple.com/app/id6744229406" class="btn btn-primary">Download for iOS</a>
      </div>
    </div>
  </section>
</main>

<!-- Footer (same as index.html) -->
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
      <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a>
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
window.addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 10);
});
</script>

</body>
</html>
```

- [ ] **Step 2: Verify in browser**

Check: table renders with highlighted Pro column, pricing cards side by side, FAQ opens/closes, responsive on mobile.

- [ ] **Step 3: Commit**

```bash
git add docs/pricing.html
git commit -m "feat(site): add pricing page with free vs pro table, cards, and FAQ"
```

---

### Task 4: Story Page (`story.html`)

**Files:**
- Create: `docs/story.html`

- [ ] **Step 1: Create `docs/story.html` with editorial narrative**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Story — Haven Notes</title>
<meta name="description" content="Haven is built by one person who was tired of bloated note apps. No venture capital. No data harvesting. Just craft.">
<meta property="og:title" content="Story — Haven Notes">
<meta property="og:description" content="Why Haven exists and what it stands for.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://havennotes.app/story">
<link rel="canonical" href="https://havennotes.app/story">
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
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu">
      <span></span><span></span><span></span>
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
  <section class="section">
    <div class="container prose prose-serif">
      <span class="eyebrow">The story</span>
      <h1>Why Haven exists</h1>
      <p class="subtitle">Built by one person who was tired of bloated note apps.</p>

      <h2>The problem</h2>
      <p>Note-taking apps used to be simple. Open the app, write your thoughts, close the app. Somewhere along the way, they became "productivity platforms" and "AI-powered workspaces" and "connected knowledge systems with real-time collaboration."</p>
      <p>They got slow. They got bloated. And then they started reading your notes to train AI models.</p>
      <p>Your private thoughts — your journal entries, your rough drafts, your half-formed ideas — became training data. And you were paying for the privilege.</p>

      <h2>The alternative</h2>
      <p>Haven is a note-taking app. That's it. It opens fast, it stays out of your way, and it never reads your notes.</p>
      <p>Notes live on your device. If you want sync, you bring your own server and everything is encrypted before it leaves your phone. There are no accounts, no analytics, no telemetry. Haven doesn't even know how many users it has.</p>
      <p>It supports markdown because formatting should be fast. It has wiki links because ideas should connect. It has a knowledge graph because sometimes you need to see the bigger picture. And it has end-to-end encryption because privacy isn't a feature — it's a right.</p>

      <h2>The craft</h2>
      <p>Haven is built by one person. No venture capital. No investors. No growth targets. No pressure to "monetize the user base" or "increase engagement metrics."</p>
      <p>Every decision is simple: does this make the app better for the person using it? If yes, build it. If no, don't.</p>
      <p>Haven Pro exists because servers cost money and development takes time. The subscription keeps the lights on. That's it. The core app is free because notes should be free.</p>

      <h2>The name</h2>
      <p>A haven is a place of safety. A quiet place where you can think without being watched, measured, or optimized. That's what your notes app should be.</p>
    </div>
  </section>

  <section class="cta-section">
    <div class="container">
      <h2>Ready to start writing?</h2>
      <div style="margin-top:24px;">
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
      <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a>
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
window.addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 10);
});
</script>

</body>
</html>
```

- [ ] **Step 2: Commit**

```bash
git add docs/story.html
git commit -m "feat(site): add story page with indie developer narrative"
```

---

### Task 5: Compare Page (`compare.html`)

**Files:**
- Create: `docs/compare.html`

- [ ] **Step 1: Create `docs/compare.html` with competitor comparison table and positioning**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Haven vs Notion, Bear, Obsidian — Haven Notes</title>
<meta name="description" content="How Haven compares to Notion, Bear, Apple Notes, and Obsidian. Privacy-first, fast, native markdown notes.">
<meta property="og:title" content="Haven vs Notion, Bear, Obsidian — Haven Notes">
<meta property="og:description" content="How Haven compares to other note-taking apps.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://havennotes.app/compare">
<link rel="canonical" href="https://havennotes.app/compare">
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
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu">
      <span></span><span></span><span></span>
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
  <section class="section">
    <div class="container section-centered">
      <h1>Haven vs the rest</h1>
      <p class="subtitle" style="margin-top:12px;max-width:500px;margin-left:auto;margin-right:auto;">Haven isn't trying to be everything. It's trying to be the best at what matters.</p>
    </div>
  </section>

  <section class="section" style="padding-top:0;">
    <div class="container">
      <div style="overflow-x:auto;">
        <table class="comparison-table">
          <thead>
            <tr>
              <th></th>
              <th class="highlight">Haven</th>
              <th>Notion</th>
              <th>Bear</th>
              <th>Apple Notes</th>
              <th>Obsidian</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Local-first</td>
              <td class="check highlight">✓</td>
              <td class="dash">—</td>
              <td class="check">✓</td>
              <td class="check">✓</td>
              <td class="check">✓</td>
            </tr>
            <tr>
              <td>E2E encryption</td>
              <td class="check highlight">✓</td>
              <td class="dash">—</td>
              <td class="dash">—</td>
              <td class="dash">—</td>
              <td class="dash">Via plugin</td>
            </tr>
            <tr>
              <td>Wiki links</td>
              <td class="check highlight">✓</td>
              <td class="check">✓</td>
              <td class="check">✓</td>
              <td class="dash">—</td>
              <td class="check">✓</td>
            </tr>
            <tr>
              <td>Knowledge graph</td>
              <td class="check highlight">✓</td>
              <td class="dash">—</td>
              <td class="dash">—</td>
              <td class="dash">—</td>
              <td class="check">✓</td>
            </tr>
            <tr>
              <td>Live markdown</td>
              <td class="check highlight">✓</td>
              <td class="dash">Blocks</td>
              <td class="check">✓</td>
              <td class="dash">—</td>
              <td class="check">✓</td>
            </tr>
            <tr>
              <td>Offline-first</td>
              <td class="check highlight">✓</td>
              <td class="dash">Partial</td>
              <td class="check">✓</td>
              <td class="check">✓</td>
              <td class="check">✓</td>
            </tr>
            <tr>
              <td>No account required</td>
              <td class="check highlight">✓</td>
              <td class="dash">—</td>
              <td class="dash">—</td>
              <td class="check">✓</td>
              <td class="check">✓</td>
            </tr>
            <tr>
              <td>Native iOS app</td>
              <td class="check highlight">✓</td>
              <td class="dash">Electron</td>
              <td class="check">✓</td>
              <td class="check">✓</td>
              <td class="dash">Electron</td>
            </tr>
            <tr>
              <td>No telemetry</td>
              <td class="check highlight">✓</td>
              <td class="dash">—</td>
              <td class="dash">—</td>
              <td class="dash">Unknown</td>
              <td class="check">✓</td>
            </tr>
            <tr>
              <td>Price</td>
              <td class="highlight">Free / $2.99/mo</td>
              <td>Free / $10/mo</td>
              <td>$2.99/mo</td>
              <td>Free</td>
              <td>Free / $4/mo</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <section class="section" style="padding-top:0;">
    <div class="container prose">
      <h2>How Haven is different</h2>

      <h3>vs Notion</h3>
      <p>Notion is a workspace. Haven is a notebook. If you need databases, project management, and team collaboration, use Notion. If you need a fast, private place to write and think, Haven is built for that.</p>

      <h3>vs Bear</h3>
      <p>Bear is beautiful and we admire it. Haven adds wiki links and a knowledge graph — so your notes don't just sit in folders, they connect to each other. And Haven offers end-to-end encryption for sync.</p>

      <h3>vs Apple Notes</h3>
      <p>Apple Notes is simple and reliable. Haven adds markdown formatting, wiki links between notes, a visual knowledge graph, and end-to-end encryption. If you've outgrown Apple Notes but don't want the complexity of Notion, Haven is the middle ground.</p>

      <h3>vs Obsidian</h3>
      <p>Obsidian is powerful and extensible. Haven is fast and native. Obsidian uses Electron — Haven is pure SwiftUI, built for iOS from the ground up. No plugins to configure, no sync setup headaches. It just works.</p>
    </div>
  </section>

  <section class="cta-section">
    <div class="container">
      <h2>Try Haven for free</h2>
      <div style="margin-top:24px;">
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
      <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a>
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
window.addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 10);
});
</script>

</body>
</html>
```

- [ ] **Step 2: Commit**

```bash
git add docs/compare.html
git commit -m "feat(site): add comparison page — Haven vs Notion, Bear, Apple Notes, Obsidian"
```

---

### Task 6: Changelog Page (`changelog.html`)

**Files:**
- Create: `docs/changelog.html`

- [ ] **Step 1: Create `docs/changelog.html` with initial version entry**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Changelog — Haven Notes</title>
<meta name="description" content="What's new in Haven Notes. Release notes and version history.">
<meta property="og:title" content="Changelog — Haven Notes">
<meta property="og:description" content="Release notes and version history for Haven Notes.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://havennotes.app/changelog">
<link rel="canonical" href="https://havennotes.app/changelog">
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
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu">
      <span></span><span></span><span></span>
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
  <section class="section">
    <div class="container prose">
      <span class="eyebrow">Updates</span>
      <h1>Changelog</h1>
      <p class="subtitle">What's new in Haven.</p>

      <div class="changelog-entry">
        <p class="date">April 2026</p>
        <h3>Version 1.0</h3>
        <ul>
          <li>Initial release</li>
          <li>Live markdown editor with bold, italic, headings, code, and lists</li>
          <li>Wiki links with [[double bracket]] syntax and autocomplete</li>
          <li>Visual knowledge graph</li>
          <li>Folders, tags, and full-text search</li>
          <li>Daily notes with one-tap creation</li>
          <li>Voice dictation with on-device processing</li>
          <li>Haven Pro: cloud sync with end-to-end encryption</li>
          <li>Biometric lock (Face ID / Touch ID)</li>
          <li>Home screen widgets (quick note + daily note)</li>
          <li>Notion import</li>
        </ul>
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
      <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a>
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
window.addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 10);
});
</script>

</body>
</html>
```

- [ ] **Step 2: Commit**

```bash
git add docs/changelog.html
git commit -m "feat(site): add changelog page with v1.0 release notes"
```

---

### Task 7: Redesign Privacy, Terms, and Support Pages

**Files:**
- Replace: `docs/privacy.html` (keep existing content, new template)
- Replace: `docs/terms.html` (keep existing content, new template)
- Replace: `docs/support.html` (keep existing content, new template)

These three pages share the same pattern: existing content wrapped in the new shared template with nav, footer, and prose styling. Each page uses Georgia serif for body text (legal/editorial).

- [ ] **Step 1: Replace `docs/privacy.html` with new template, preserving all content**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Privacy Policy — Haven Notes</title>
<meta name="description" content="Haven is built on a simple principle: your notes are yours. We don't collect, store, or transmit your data.">
<meta property="og:title" content="Privacy Policy — Haven Notes">
<meta property="og:description" content="Your notes are yours. We don't collect, store, or transmit your data.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://havennotes.app/privacy">
<link rel="canonical" href="https://havennotes.app/privacy">
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
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu">
      <span></span><span></span><span></span>
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
  <section class="section">
    <div class="container prose prose-serif">
      <span class="eyebrow">Legal</span>
      <h1>Privacy Policy</h1>
      <p class="subtitle">Last updated: March 30, 2026</p>

      <h2>The Short Version</h2>
      <p>Haven is built on a simple principle: <strong>your notes are yours</strong>. We don't collect, store, or transmit your data. Period.</p>

      <h2>Data Storage</h2>
      <p>All notes, tags, folders, and tasks are stored <strong>locally on your device</strong> in an SQLite database. Haven does not operate any servers that receive your data.</p>

      <h2>Optional Sync</h2>
      <p>If you enable sync, your notes are sent to a server URL that <strong>you provide and control</strong>. Haven never connects to any Haven-operated server. If you enable encryption, notes are encrypted with AES-256-GCM on your device before being transmitted. Not even your sync server can read encrypted notes.</p>

      <h2>Data We Do Not Collect</h2>
      <ul>
        <li>We do not collect personal information</li>
        <li>We do not collect usage analytics or telemetry</li>
        <li>We do not collect crash reports</li>
        <li>We do not use advertising or tracking SDKs</li>
        <li>We do not share data with third parties</li>
        <li>We have no user accounts or registration</li>
      </ul>

      <h2>Microphone &amp; Speech Recognition</h2>
      <p>Haven includes an optional voice dictation feature. When enabled, audio is processed using Apple's on-device Speech Recognition framework. Audio data is <strong>not sent to Haven</strong> and is not stored. On-device processing is preferred when available.</p>

      <h2>Face ID / Touch ID</h2>
      <p>Haven offers optional biometric lock. Authentication is handled entirely by Apple's LocalAuthentication framework on your device. No biometric data is accessed or stored by Haven.</p>

      <h2>In-App Purchases</h2>
      <p>Subscriptions are processed by Apple through StoreKit. Haven does not receive or store payment information.</p>

      <h2>Children's Privacy</h2>
      <p>Haven does not knowingly collect information from children under 13. The app contains no features that target children.</p>

      <h2>Changes to This Policy</h2>
      <p>If we update this policy, we will post the revised version here with an updated date. Material changes will be communicated through the app's update notes.</p>

      <h2>Contact</h2>
      <p>Questions about this privacy policy? Contact us at <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a></p>
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
      <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a>
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
window.addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 10);
});
</script>

</body>
</html>
```

- [ ] **Step 2: Replace `docs/terms.html` with new template, preserving all content**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Terms of Use — Haven Notes</title>
<meta name="description" content="Terms of Use for Haven Notes, including subscription terms and auto-renewal policy.">
<meta property="og:title" content="Terms of Use — Haven Notes">
<meta property="og:description" content="Terms of Use for Haven Notes.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://havennotes.app/terms">
<link rel="canonical" href="https://havennotes.app/terms">
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
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu">
      <span></span><span></span><span></span>
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
  <section class="section">
    <div class="container prose prose-serif">
      <span class="eyebrow">Legal</span>
      <h1>Terms of Use</h1>
      <p class="subtitle">Last updated: April 8, 2026</p>

      <h2>Acceptance of Terms</h2>
      <p>By downloading, installing, or using Haven ("the App"), you agree to these Terms of Use. If you do not agree, do not use the App.</p>

      <h2>Description of Service</h2>
      <p>Haven is a note-taking application for iOS. The App stores your notes locally on your device and offers optional features such as cloud sync and encryption through an in-app subscription.</p>

      <h2>Haven Pro Subscription</h2>
      <p>Haven offers auto-renewable subscriptions ("Haven Pro") that unlock additional features including cloud sync and end-to-end encryption.</p>
      <ul>
        <li><strong>Plans:</strong> Haven Pro is available as a monthly or yearly subscription.</li>
        <li><strong>Payment:</strong> Payment is charged to your Apple ID account at confirmation of purchase.</li>
        <li><strong>Renewal:</strong> Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current billing period.</li>
        <li><strong>Pricing:</strong> Your account will be charged for renewal within 24 hours prior to the end of the current period at the same price as the original subscription.</li>
        <li><strong>Management:</strong> You can manage and cancel your subscription in your device's Settings &gt; Apple ID &gt; Subscriptions.</li>
        <li><strong>Free trial:</strong> If offered, any unused portion of a free trial period will be forfeited when you purchase a subscription.</li>
      </ul>

      <h2>User Content</h2>
      <p>You retain all rights to the notes, tasks, and other content you create in Haven. The App does not claim ownership of your content. You are solely responsible for the content you create and store.</p>

      <h2>Acceptable Use</h2>
      <p>You agree not to use the App for any unlawful purpose or in violation of any applicable laws or regulations.</p>

      <h2>Intellectual Property</h2>
      <p>The App, including its design, code, and branding, is the intellectual property of Haven Notes. You may not copy, modify, distribute, or reverse-engineer the App.</p>

      <h2>Disclaimer of Warranties</h2>
      <p>The App is provided "as is" without warranties of any kind, either express or implied. We do not guarantee that the App will be uninterrupted, error-free, or free of harmful components.</p>

      <h2>Limitation of Liability</h2>
      <p>To the maximum extent permitted by law, Haven Notes shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App, including but not limited to loss of data.</p>

      <h2>Data and Backups</h2>
      <p>You are responsible for maintaining backups of your data. While we strive to ensure data integrity, we cannot guarantee against data loss. We recommend regular backups through your device's backup mechanisms.</p>

      <h2>Changes to These Terms</h2>
      <p>We may update these Terms from time to time. Continued use of the App after changes constitutes acceptance of the updated Terms. Material changes will be communicated through the app's update notes.</p>

      <h2>Governing Law</h2>
      <p>These Terms are governed by the laws applicable in your jurisdiction, subject to Apple's Standard EULA where applicable.</p>

      <h2>Apple's Standard EULA</h2>
      <p>In addition to these Terms, your use of the App is subject to Apple's <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdfla/">Standard Licensed Application End User License Agreement</a>.</p>

      <h2>Contact</h2>
      <p>Questions about these terms? Contact us at <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a></p>
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
      <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a>
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
window.addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 10);
});
</script>

</body>
</html>
```

- [ ] **Step 3: Replace `docs/support.html` with new template, preserving all content**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Support — Haven Notes</title>
<meta name="description" content="Get help with Haven Notes. FAQs, contact information, and system requirements.">
<meta property="og:title" content="Support — Haven Notes">
<meta property="og:description" content="Get help with Haven Notes.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://havennotes.app/support">
<link rel="canonical" href="https://havennotes.app/support">
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
    <button class="nav-hamburger" onclick="document.getElementById('mobile-menu').classList.toggle('open')" aria-label="Menu">
      <span></span><span></span><span></span>
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
  <section class="section">
    <div class="container prose prose-serif">
      <span class="eyebrow">Help</span>
      <h1>Support</h1>
      <p class="subtitle">We're here to help.</p>

      <div class="contact-box">
        <p>For bugs, feature requests, or questions:</p>
        <p><a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a></p>
      </div>

      <h2>Frequently Asked Questions</h2>

      <details>
        <summary>Where are my notes stored?</summary>
        <p>All notes are stored locally on your device in an encrypted database. Nothing leaves your phone unless you enable optional sync to your own server.</p>
      </details>

      <details>
        <summary>Can I sync between devices?</summary>
        <p>Yes — Haven Pro includes sync to a self-hosted server. You provide the server URL and authentication token. Haven never operates servers that hold your data.</p>
      </details>

      <details>
        <summary>What is encryption?</summary>
        <p>Haven offers optional AES-256-GCM encryption. When enabled, your notes are encrypted on your device before being sent to your sync server. Even if someone accesses the server, they cannot read your notes without your password.</p>
      </details>

      <details>
        <summary>Can I import from Notion?</summary>
        <p>Yes. Export your Notion workspace as "Markdown & CSV", unzip the file, and select the folder in Haven's import screen (Settings → Import from Notion).</p>
      </details>

      <details>
        <summary>What are wiki links?</summary>
        <p>Type [[Note Title]] to create a link to another note. This builds a knowledge graph — connections between your ideas that you can visualize.</p>
      </details>

      <details>
        <summary>How do I recover a deleted note?</summary>
        <p>Deleted notes are soft-deleted and can be recovered. If you've purged deleted notes, they cannot be recovered. We recommend enabling sync as a backup.</p>
      </details>

      <details>
        <summary>What happens if I forget my encryption password?</summary>
        <p>Your encryption password cannot be recovered. There is no password reset. If you forget it, encrypted notes on your sync server become permanently unreadable. Notes on your device remain accessible.</p>
      </details>

      <h2>System Requirements</h2>
      <ul>
        <li>iOS 17.0 or later</li>
        <li>iPhone or iPad</li>
      </ul>
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
      <a href="mailto:havennotes.app@gmail.com">havennotes.app@gmail.com</a>
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
window.addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 10);
});
</script>

</body>
</html>
```

- [ ] **Step 4: Verify all three pages in browser**

Run: `cd docs && python3 -m http.server 8080`

Check each page: nav works, content is present and unchanged, footer links work, dark mode applies, prose serif styling on body text.

- [ ] **Step 5: Commit**

```bash
git add docs/privacy.html docs/terms.html docs/support.html
git commit -m "feat(site): redesign privacy, terms, and support pages with shared template"
```

---

### Task 8: Final Verification and Cleanup

**Files:**
- Check: all files in `docs/`

- [ ] **Step 1: Verify all pages exist**

Run: `ls -la docs/*.html docs/*.css docs/assets/`
Expected: `index.html`, `pricing.html`, `story.html`, `compare.html`, `changelog.html`, `privacy.html`, `terms.html`, `support.html`, `styles.css`, `assets/` directory

- [ ] **Step 2: Check all internal links work**

Run each in browser at `http://localhost:8080`:
- `/` → index.html loads, nav links work
- `/pricing.html` → table, cards, FAQ render
- `/story.html` → prose renders in serif
- `/compare.html` → table renders, Haven column highlighted
- `/changelog.html` → v1.0 entry shows
- `/privacy.html` → content preserved, new template
- `/terms.html` → content preserved, new template
- `/support.html` → content preserved, FAQ accordions work

- [ ] **Step 3: Test mobile responsiveness**

In browser dev tools, check at 375px width:
- Hamburger menu appears and toggles
- Feature grid collapses to 1 column
- Hero stacks vertically (text above, image below)
- Tables scroll horizontally
- Footer collapses to single column

- [ ] **Step 4: Test dark mode**

Toggle system dark mode (or use dev tools `prefers-color-scheme: dark`). Verify:
- Background switches to `#161512`
- Text switches to `#FAF7F3`
- Cards, borders, and accent colors all update
- No white flashes or unstyled elements

- [ ] **Step 5: Check total page weight**

Run: `du -sh docs/` (excluding assets/screenshot.png)
Expected: < 50KB for HTML + CSS

- [ ] **Step 6: Final commit**

```bash
git add -A docs/
git commit -m "feat(site): complete havennotes.app website — 8 pages, shared CSS, dark mode, responsive"
```
