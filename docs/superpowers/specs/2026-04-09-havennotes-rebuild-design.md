# havennotes.app Rebuild — Design Spec

## Overview

Complete visual rebuild of the havennotes.app marketing site to match the iOS app's actual aesthetic. The current site is light-first, flat, and feels disconnected from the app (which is dark, warm, cinematic, and premium). The rebuild is **dark-first throughout**, with amber glow effects, cinematic screenshots, and the signature "italic accent word" typographic move borrowed from the App Store marketing screenshots.

**Scope:** This rebuild replaces the visual layer (styles.css + page markup). Page content, SEO meta, sitemap, robots.txt, favicons, Vercel config, and legal pages are already done — no need to recreate them.

## Visual Identity

### Theme
**Dark-first, single theme.** The entire site uses a deep warm charcoal background. Light mode is removed. Users arriving from the App Store or the app itself see continuity. The site should feel like a direct extension of the product.

### Color Tokens

```
--bg:              #161512   /* deep charcoal - matches app background */
--surface:         #1E1B17   /* raised panel */
--surface-elevated:#252018   /* cards, pricing cards */
--text:            #FAF7F3   /* warm cream */
--text-secondary:  #A89E94   /* muted cream */
--border:          hsl(30, 8%, 20%)    /* warm subtle border */
--border-strong:   hsl(30, 10%, 25%)   /* borders on hover/active */
--accent:          #A0855E   /* amber - primary action, accent words */
--accent-hover:    #B8996A   /* brighter amber on hover */
--glow:            rgba(160, 133, 94, 0.15)  /* radial gradient glow */
--shadow-color:    hsl(30, 30%, 4%)   /* warm tinted shadow */
```

### Typography

**Fonts:** Georgia (serif display) + system sans-serif (body). No webfonts. Same philosophy as before.

**Type scale:**
```
--text-micro:    12px  (eyebrow labels, small UI)
--text-sm:       14px  (captions, meta)
--text-base:     16px  (body default)
--text-lg:       18px  (body emphasis, subtitles)
--text-xl:       22px  (feature card titles, small headings)
--text-2xl:      32px  (section headings, h2)
--text-3xl:      44px  (feature hero headings)
--text-hero:     clamp(48px, 7vw, 88px)  (hero h1 — fluid, monumental)
```

**Typography rules:**
- Display headlines use Georgia 700, letter-spacing `-0.02em`, line-height 1.05
- Italic accent words use Georgia 400 italic in accent color — this is the signature move. Every major headline has one italic amber word
- Body uses system sans-serif 400, letter-spacing 0, line-height 1.65
- Eyebrows: sans-serif 600 uppercase, letter-spacing `0.15em`, 12px, accent color
- Body base size: 17px

**Signature headline pattern:**
```
Your thoughts, *beautifully organized*
See how ideas *connect*
Private *by design*
Ready to *start writing*?
```

### Depth & Light

**Radial glow gradients** are the signature effect. They simulate the amber "lamp light" feel from the app's marketing shots.

```css
/* Hero ambient glow — top of page */
background:
  radial-gradient(ellipse 80% 60% at 50% 0%, var(--glow), transparent 70%),
  var(--bg);

/* Feature section glow — subtle, localized */
background:
  radial-gradient(ellipse at 70% 30%, var(--glow), transparent 60%),
  var(--bg);
```

**Shadows** are warm-tinted, never black:
```css
/* Card elevated */
box-shadow:
  0 16px 48px hsl(30, 30%, 4%, 0.5),
  0 4px 16px hsl(30, 30%, 4%, 0.3),
  0 0 0 1px var(--border);

/* Screenshot hero */
box-shadow:
  0 40px 100px hsl(30, 30%, 4%, 0.6),
  0 0 80px var(--glow),
  0 0 0 1px var(--border);
```

### Motion

**Scroll-reveal** animations via Intersection Observer. Elements fade + translate-up on enter:

```css
.reveal {
  opacity: 0;
  transform: translateY(24px);
  transition: opacity 0.8s ease, transform 0.8s ease;
}
.reveal.visible {
  opacity: 1;
  transform: translateY(0);
}
```

**Transition easing:** `cubic-bezier(0.25, 0.1, 0.25, 1)` for interactive elements. 150-250ms duration.

**Hover moments:**
- Feature cards: border shifts to accent, slight translateY(-2px), amber glow appears
- Buttons: subtle lift + glow shadow
- Nav links: amber underline animates from left
- Screenshot hover: subtle scale(1.015)

## Landing Page Structure

### 1. Hero Section

**Layout:** Full-width, centered content. Ambient amber glow at top of viewport.

**Content:**
- Eyebrow: "HAVEN — PRIVATE NOTES FOR iOS" (amber, small caps, 12px)
- h1 (two lines):
  - Line 1: "Your thoughts," (Georgia 700, cream, 88px desktop)
  - Line 2: "*beautifully organized.*" (Georgia 400 italic, amber, same size)
- Subtitle: "Markdown notes with wiki links and a visual knowledge graph. Private by design. Encrypted end to end." (sans-serif, muted cream, 18px, max-width 520px)
- Dual CTA:
  - Primary: "Download for iOS" (amber bg, dark text, bold)
  - Secondary: "See it in action" (border, cream text)
- Hero screenshot: centered below, max-width 380px, with warm shadow + amber glow halo

**Technical:**
- Background: combined radial gradient at 50% 0%
- Content wrapper: max-width 1080px, padding 96px 24px 64px
- Screenshot wrapper: has `.reveal` class for scroll animation

### 2. Knowledge Graph Hero Feature

**Layout:** 2-column (text left, image right) on desktop. Stacked on mobile.

**Content:**
- Eyebrow: "THE KNOWLEDGE GRAPH" (amber, 12px)
- Big headline: "See how ideas *connect*" (Georgia, 44px, italic accent)
- Body: 2-3 sentences about wiki links building a visual network
- Secondary link: "Learn how it works →" (amber, arrow)
- Image: knowledge graph screenshot (from `Screenshots/Haven-Notes-screenshot-3.png`), with warm shadow and subtle amber glow

**Technical:**
- Background: bg + radial glow at right side
- Section padding: 120px vertical
- Two-column grid: 45% / 55% split, 80px gap
- Both halves have `.reveal` class with stagger

### 3. Feature Grid

**Layout:** 3-column grid on desktop (1080px max), 2 on tablet, 1 on mobile.

**6 cards:**
1. Markdown — "Format as you type"
2. Wiki Links — "Connect with [[brackets]]"
3. E2E Encryption — "AES-256. Keys on device"
4. Daily Notes — "A rhythm for writing"
5. Voice Dictation — "Hands-free capture"
6. Full-Text Search — "Find anything instantly"

**Card structure:**
- Background: `var(--surface-elevated)` with 1px warm border
- Padding: 32px
- Content order: emoji (28px) → title (Georgia, 20px) → description (sans, 14px, muted)
- Hover: border becomes accent, card lifts 2px, amber glow shadow appears

**Technical:**
- Section heading: "Everything you need, *nothing you don't*" (Georgia, 32px, italic accent)
- Section padding: 96px vertical
- Cards use `.reveal` class with stagger delay (0.1s between each)

### 4. Pricing Teaser

**Layout:** Centered, narrow (max-width 600px).

**Content:**
- Small eyebrow: "PRICING"
- Headline: "Free forever. Pro *unlocks sync*." (Georgia, 32px)
- Body: "All core features are free. Haven Pro adds cloud sync and end-to-end encryption — $2.99/month or $19.99/year."
- CTA: "See full pricing →" (link to /pricing)

**Technical:**
- Background: bg + subtle glow
- Section padding: 80px vertical

### 5. Final CTA

**Layout:** Centered, full-width dramatic.

**Content:**
- Headline: "Ready to *start writing*?" (Georgia, 48px, italic accent)
- Subtitle: "Haven is free to download. Pro unlocks sync."
- Button: "Download for iOS" (amber, large)

**Technical:**
- Background: bg + radial glow at bottom
- Section padding: 120px vertical
- Border-top separator (subtle warm border)

## Other Pages

All existing pages (pricing, story, compare, changelog, privacy, terms, support) inherit:
- New dark-first theme (styles.css)
- New nav styling (sticky, dark bg, amber hover underlines)
- New footer styling (dark, warm)
- Updated typography (Georgia italic accent moves where appropriate)

**Content on other pages is NOT rewritten.** Only visual treatment changes.

**Story page** gets slight enhancement: the eyebrow + italic accent headline treatment, warmer prose layout. Still same content.

**Pricing page** gets updated card styling (dark surfaces, amber borders on featured), Free card updated, savings badge kept.

**Compare page** gets the dark table treatment with amber highlight on Haven column.

## Technical Implementation

### File Changes

**Replace entirely:**
- `docs/styles.css` — complete rewrite matching new system
- `docs/index.html` — complete rewrite with new structure

**Update (preserve content, apply new classes):**
- `docs/pricing.html`
- `docs/story.html`
- `docs/compare.html`
- `docs/changelog.html`
- `docs/privacy.html`
- `docs/terms.html`
- `docs/support.html`

**Add:**
- `docs/assets/graph.png` — knowledge graph screenshot (from Haven-Notes-screenshot-3.png)
- `docs/assets/editor.png` — editor screenshot (already exists as screenshot.png)
- `docs/js/reveal.js` — tiny scroll-reveal Intersection Observer (~30 lines)

**Preserve as-is:**
- `docs/sitemap.xml`
- `docs/robots.txt`
- `docs/vercel.json`
- `docs/favicon.png`, `docs/apple-touch-icon.png`

### JavaScript

Single inline script or `docs/js/reveal.js`:

```javascript
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.15, rootMargin: '0px 0px -50px 0px' });

document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
```

Plus the existing nav scroll script (already in every page).

### Performance Target
- Total CSS < 20KB
- Total JS < 2KB
- Zero external dependencies
- LCP < 1.5s on 3G

## What This Is NOT

- No light mode (dark-first only)
- No frameworks, no build step, no npm
- No hero video or heavy animations
- No carousels or sliders
- No external fonts
- No scroll-hijacking or parallax
- Not a content rewrite — visual rebuild only

## Out of Scope

- Rewriting page copy (content stays)
- Adding new pages
- Adding blog/CMS
- Adding analytics
- Mobile app changes
