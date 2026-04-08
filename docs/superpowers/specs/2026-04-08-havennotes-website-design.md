# havennotes.app Website Design Spec

## Overview

A full marketing website for Haven Notes at `havennotes.app`. Static HTML + CSS, no frameworks, no JS dependencies — matching Haven's "no bloat" philosophy. 8 pages total.

## Visual Identity

### Typography
- **Headlines**: Georgia serif, bold (700)
- **Body/UI**: System sans-serif stack (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`)
- **Code/monospace**: System monospace for any inline code references

### Color Palette

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| Background | `#FEFDFB` | `#161512` | Page background |
| Surface | `#FAF7F3` | `#1E1B17` | Cards, elevated elements |
| Text primary | `#1A1815` | `#FAF7F3` | Headlines, body |
| Text secondary | `#6B6560` | `#A89E94` | Subtitles, captions |
| Border | `#E8E2DA` | `#3D3730` | Card borders, dividers |
| Accent (brown) | `#8B6F47` | `#A0855E` | CTAs, labels, highlights |
| Link hover | `#6B9B8E` | `#7BAFA2` | Only on hover state |

### Spacing
- 8px baseline grid
- Section padding: 80px vertical (desktop), 48px (mobile)
- Max content width: 1080px, centered
- Card grid gap: 16px

### Dark Mode
- Implemented via `prefers-color-scheme: dark` media query
- All tokens have light/dark variants (table above)
- No toggle — respects system preference

## Shared Layout

### Navigation (sticky)
- Left: "Haven" wordmark in Georgia serif, links to `/`
- Center/Right: Features, Pricing, Story, Compare — text links in sans-serif
- Far right: "Download" button (brown accent background, white text, rounded)
- Mobile: hamburger menu → slide-down panel
- Background becomes slightly opaque on scroll (`backdrop-filter: blur`)

### Footer
- 3-column layout: Pages (all 8 links), Legal (Privacy, Terms), Connect (Support email, App Store link)
- Bottom row: "Made by one person who was tired of bloated note apps." + App Store badge
- Muted styling, `border-top: 1px solid` border color

## Pages

### 1. Landing (`index.html`)

**Hero section:**
- Split layout: text left (60%), phone mockup right (40%)
- Left side:
  - Eyebrow: "Haven Notes" in small caps, secondary text color
  - Headline (Georgia serif, ~48px): "Your notes deserve a quiet home."
  - Subtext (sans-serif, 18px, secondary color): "Fast, private markdown notes with wiki links and end-to-end encryption. No AI. No cloud. Just yours."
  - Two buttons: "Download for iOS" (brown accent) + "See features" (outline, border color)
- Right side: iPhone mockup showing the app in dark mode (actual screenshot, not illustration)

**Feature grid:**
- Section headline (centered): "Everything you need, nothing you don't."
- 2-column grid (3-col on wide screens), 6 cards:
  1. Live Markdown — emoji ✏️, "Bold, italic, headings — rendered as you type"
  2. Wiki Links — emoji 🔗, "Connect notes with [[links]] and see your graph"
  3. E2E Encrypted — emoji 🔒, "AES-256 encryption. Not even we can read your notes"
  4. Daily Notes — emoji 📅, "One-tap daily journal with automatic dating"
  5. Voice Notes — emoji 🎤, "Dictate your thoughts. On-device processing"
  6. Full-Text Search — emoji 🔍, "Find anything instantly across all your notes"
- Each card: white/surface background, border, rounded corners (12px), emoji top, title bold, description secondary

**Social proof section (optional):**
- If App Store rating data is available: star rating + review count
- "No AI. No bloat. Just notes." as a pull quote

**Bottom CTA:**
- Full-width section, centered text
- "Ready to start writing?" headline
- Download button + "Free to use · Pro unlocks sync" caption

### 2. Pricing (`pricing.html`)

**Header:**
- "Simple, honest pricing" headline
- "Haven is free. Pro unlocks sync." subtext

**Comparison table:**
- 2 columns: Free vs Pro
- Rows: Local notes, Markdown editor, Wiki links, Knowledge graph, Tags & folders, Daily notes, Voice dictation, Full-text search, Widgets, Cloud sync (Pro), E2E encrypted sync (Pro), Priority support (Pro)
- Checkmarks for included, dash for not included

**Subscription cards:**
- 2 cards side by side: Monthly + Yearly
- Each shows: plan name, price, billing period, "auto-renewable" label
- Yearly card has "Best value" badge
- Both link to App Store

**FAQ accordion:**
- "Can I use Haven for free?" — Yes, core features are free forever
- "What does Pro add?" — Cloud sync and E2E encryption
- "How do I cancel?" — Settings > Apple ID > Subscriptions
- "Is there a free trial?" — answer based on actual StoreKit config
- Plain `<details>/<summary>` elements, no JS needed

### 3. Story (`story.html`)

**Structure:**
- Single column, prose-focused (narrower max-width: 640px)
- Georgia serif for body text here (exception — this page is editorial)
- The narrative: why Haven exists, the problem with modern note apps (bloat, AI, privacy), what Haven stands for (craft, simplicity, respect for the user)
- Reference the onboarding copy tone: "Built by one person who was tired of bloated note apps. No venture capital. No data harvesting. Just craft."
- No stock photos, no headshot required. Just honest writing.

### 4. Compare (`compare.html`)

**Header:**
- "Haven vs the rest" headline
- Brief intro: Haven isn't trying to be everything — it's trying to be the best at what matters

**Comparison table:**
- Columns: Haven, Notion, Bear, Apple Notes, Obsidian
- Rows: Privacy (local-first), E2E Encryption, Wiki Links, Knowledge Graph, Markdown, Offline-first, No account required, Open file format, Price
- Use checkmarks, dashes, and brief notes
- Haven column highlighted with accent background

**Positioning paragraphs below the table:**
- vs Notion: "Notion is a workspace. Haven is a notebook."
- vs Bear: "Bear is beautiful. Haven adds wiki links and a knowledge graph."
- vs Apple Notes: "Apple Notes is simple. Haven adds markdown, linking, and encryption."
- vs Obsidian: "Obsidian is powerful. Haven is fast and native."

### 5. Changelog (`changelog.html`)

**Structure:**
- Reverse chronological list
- Each entry: version number + date + bullet list of changes
- Minimal styling: version as h3, date in secondary text, bullets
- No categories or tags — keep it simple
- Can be extended over time as updates ship

### 6. Privacy Policy (`privacy.html`)

- Redesign existing content to match new site template
- Same content, new visual treatment with shared nav/footer
- Georgia serif body text (legal/editorial page)

### 7. Terms of Use (`terms.html`)

- Redesign existing content to match new site template
- Same content, new visual treatment with shared nav/footer
- Georgia serif body text (legal/editorial page)

### 8. Support (`support.html`)

- Redesign existing content to match new site template
- Same content, new visual treatment with shared nav/footer
- Contact email, FAQ if applicable

## Technical Implementation

### Stack
- Static HTML + CSS files in `docs/` directory
- No build step, no bundler, no framework
- Single shared CSS file (`styles.css`) for all pages
- No JavaScript except:
  - `<details>` elements for FAQ (native HTML, no JS)
  - Optional: minimal JS for mobile hamburger menu toggle (~10 lines)

### File Structure
```
docs/
  index.html          — Landing page
  pricing.html        — Pricing
  story.html          — About / Story
  compare.html        — Comparison
  changelog.html      — Changelog
  privacy.html        — Privacy policy
  terms.html          — Terms of use
  support.html        — Support
  styles.css          — Shared stylesheet
  assets/
    screenshot.png    — App screenshot for hero
    og-image.png      — Open Graph image
```

### SEO & Meta
- Each page: unique `<title>`, `<meta description>`, Open Graph tags
- `og:image` — branded card for social sharing
- Canonical URLs: `https://havennotes.app/<page>`
- Semantic HTML: `<header>`, `<main>`, `<footer>`, `<section>`, `<article>`

### Performance
- No external fonts (system stack + Georgia which is pre-installed)
- No external CSS/JS dependencies
- Target: < 50KB total page weight (excluding screenshot image)
- Screenshot image: optimized WebP with PNG fallback

### Hosting
- GitHub Pages or similar static host
- Custom domain: `havennotes.app`
- HTTPS via provider's default certificate

## What This Is NOT

- No animations, parallax, or scroll effects
- No hero illustrations or abstract SVG graphics
- No testimonial carousels or sliders
- No cookie banners or analytics scripts
- No chatbot or support widget
- No blog CMS — changelog is hand-edited HTML
