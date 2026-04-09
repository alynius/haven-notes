# havennotes.app Astro Migration + Typographic Rebuild — Design Spec

## Overview

Migrate the havennotes.app website from static HTML/CSS to Astro + Tailwind CSS, while simultaneously rebuilding the visual language toward **typographic minimalism**. The hero becomes a manifesto excerpt in massive serif type, with no phone screenshots or illustrations. The rest of the landing page simplifies similarly — typography and whitespace carry the premium feel.

**Why both at once:** Every page's markup needs to change for the typographic rebuild, so porting to Astro components + rebuilding in one step avoids rewriting twice.

## Tech Stack

- **Astro 5.x** — static site generator, outputs plain HTML with zero client-side JS by default
- **Tailwind CSS 4.x** — utility-first styling via `@astrojs/tailwind` integration
- **TypeScript** — for component props (used lightly, most components are JSX-less)
- **No webfonts** — Georgia (serif) + system sans-serif stack
- **Deployment** — Vercel auto-detects Astro, builds `dist/` on push

## Project Structure

The Astro project lives at `docs/`. Existing static files move to `docs/_legacy/` during migration, deleted when the new site is verified live.

```
docs/
  package.json
  astro.config.mjs
  tailwind.config.mjs
  tsconfig.json
  vercel.json                 — keeps cleanUrls: true
  .gitignore                  — ignore node_modules, dist, .astro
  public/
    favicon.png               — copied from _legacy
    apple-touch-icon.png      — copied from _legacy
    robots.txt                — copied from _legacy
    sitemap.xml               — copied from _legacy
  src/
    layouts/
      BaseLayout.astro        — HTML shell, meta, nav, footer, slot
    components/
      Nav.astro               — sticky nav with blur-on-scroll
      Footer.astro            — 3-column footer
      Hero.astro              — typographic manifesto hero (landing only)
      Eyebrow.astro           — small caps amber labels
      Button.astro            — btn-primary / btn-outline variants
      FeatureCard.astro       — minimal feature card (no emoji)
      PricingCard.astro       — pricing card for pricing page
    pages/
      index.astro             — landing
      pricing.astro           — pricing
      story.astro             — story / about
      compare.astro           — comparison
      changelog.astro         — changelog
      privacy.astro           — privacy policy
      terms.astro             — terms of use
      support.astro           — support
    styles/
      global.css              — @tailwind directives + base resets + custom classes
  _legacy/                    — old docs/*.html files archived (deleted at end)
```

**What gets deleted from the old site:**
- `docs/styles.css` (replaced by Tailwind utilities + `global.css`)
- `docs/assets/screenshot.png`, `docs/assets/graph.png` (no longer referenced)
- All inline `<style>` blocks (no more inline CSS)
- All inline nav/footer markup (now components)
- Hero network illustration SVG (typography replaces it)
- Knowledge graph illustration SVG (replaced by pull quote)
- 6 feature icon SVGs (replaced by typographic treatment)

**What's preserved:**
- All page copy (unless explicitly changed in hero manifesto)
- All legal content (privacy, terms)
- All meta tags, OG tags, canonical URLs, SEO
- Clean URLs via Vercel config
- Sitemap, robots.txt, favicon

## Tailwind Configuration

Design tokens move from CSS custom properties to Tailwind's theme config, so they're accessible as utility classes.

```js
// tailwind.config.mjs
export default {
  content: ['./src/**/*.{astro,html,ts}'],
  theme: {
    extend: {
      colors: {
        bg: '#161512',
        surface: '#1E1B17',
        elevated: '#252018',
        text: {
          primary: '#FAF7F3',
          secondary: '#A89E94',
        },
        accent: {
          DEFAULT: '#A0855E',
          hover: '#B8996A',
        },
        border: {
          DEFAULT: 'hsl(30, 8%, 20%)',
          strong: 'hsl(30, 10%, 28%)',
        },
      },
      fontFamily: {
        serif: ['Georgia', '"Times New Roman"', 'Times', 'serif'],
        sans: ['-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'Roboto', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        micro: ['12px', { lineHeight: '1.4' }],
        hero: ['clamp(56px, 9vw, 128px)', { lineHeight: '1.02', letterSpacing: '-0.03em' }],
        display: ['clamp(40px, 6vw, 80px)', { lineHeight: '1.08', letterSpacing: '-0.025em' }],
      },
      backgroundImage: {
        'glow-top': 'radial-gradient(ellipse 80% 60% at 50% 0%, rgba(160,133,94,0.18), transparent 70%)',
        'glow-center': 'radial-gradient(ellipse 60% 50% at center, rgba(160,133,94,0.12), transparent 70%)',
        'glow-right': 'radial-gradient(ellipse 60% 60% at 70% 40%, rgba(160,133,94,0.15), transparent 70%)',
      },
      boxShadow: {
        'warm-sm': '0 4px 12px hsl(30, 30%, 4%, 0.4)',
        'warm-md': '0 12px 32px hsl(30, 30%, 4%, 0.45), 0 4px 16px hsl(30, 30%, 4%, 0.3)',
        'warm-lg': '0 24px 64px hsl(30, 30%, 4%, 0.5), 0 8px 24px hsl(30, 30%, 4%, 0.35)',
        'accent-glow': '0 0 40px rgba(160, 133, 94, 0.25)',
      },
      maxWidth: {
        prose: '640px',
      },
      transitionTimingFunction: {
        'ease-premium': 'cubic-bezier(0.16, 1, 0.3, 1)',
      },
    },
  },
  plugins: [],
};
```

### global.css

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    scroll-behavior: smooth;
    -webkit-text-size-adjust: 100%;
    text-size-adjust: 100%;
  }

  body {
    @apply bg-bg text-text-primary font-sans;
    font-size: 17px;
    line-height: 1.65;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-rendering: optimizeLegibility;
    font-feature-settings: 'kern' 1, 'liga' 1;
  }

  ::selection {
    background: rgba(160, 133, 94, 0.25);
    color: #FAF7F3;
  }

  :focus-visible {
    outline: 2px solid #A0855E;
    outline-offset: 2px;
    border-radius: 4px;
  }

  h1, h2, h3, h4, h5, h6 {
    @apply font-serif font-bold text-text-primary;
    letter-spacing: -0.02em;
    line-height: 1.1;
  }
}

@layer components {
  .accent-italic {
    @apply text-accent;
    font-style: italic;
    font-weight: 400;
  }

  .prose-serif {
    @apply font-serif;
    font-size: 18px;
    line-height: 1.75;
  }

  .reveal {
    opacity: 0;
    transform: translateY(24px);
    transition: opacity 0.8s cubic-bezier(0.16, 1, 0.3, 1),
                transform 0.8s cubic-bezier(0.16, 1, 0.3, 1);
  }

  .reveal.visible {
    opacity: 1;
    transform: translateY(0);
  }
}
```

## Components

### BaseLayout.astro

Wraps every page. Receives `title`, `description`, `ogUrl`, `currentPath` as props.

**Responsibilities:**
- HTML shell, charset, viewport
- All meta tags (title, description, og:*, canonical)
- Favicon links
- Stylesheet link (Astro auto-bundles global.css)
- `<Nav currentPath={currentPath} />`
- `<slot />` for page content
- `<Footer />`
- Inline scroll reveal script + nav scroll script

Usage:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
---
<BaseLayout
  title="Pricing — Haven Notes"
  description="Haven is free. Pro unlocks sync."
  ogUrl="https://havennotes.app/pricing"
  currentPath="/pricing"
>
  <!-- page content -->
</BaseLayout>
```

### Nav.astro

**Props:** `currentPath: string`

**Responsibilities:**
- Sticky top nav with backdrop blur
- Logo links to `/`
- 4 text links: Features (/#features), Pricing, Story, Compare
- Download CTA button (App Store link)
- Mobile hamburger + slide panel (<768px)
- Set `aria-current="page"` on matching link based on `currentPath`
- Animated underline on hover (not on CTA)

### Footer.astro

No props. Identical across all pages.

**Responsibilities:**
- 3-column grid: Pages / Legal / Connect
- Footer bottom with "Made by one person..." + copyright
- Mobile: stacks to single column

### Hero.astro (landing page only)

No props. Hardcoded manifesto text.

**Responsibilities:**
- Full-width hero section with ambient amber glow at top
- Eyebrow: "HAVEN — PRIVATE NOTES FOR iOS"
- Headline across 6 lines (see Hero Design below)
- Dual CTA buttons (Download + Read the story)
- Massive vertical whitespace (~120px top, ~80px bottom)

### Eyebrow.astro

**Props:** `children` (slot)

Simple presentational component for the small-caps amber label pattern used on every section.

### Button.astro

**Props:** `href: string`, `variant: 'primary' | 'outline'`, `external?: boolean`

**Responsibilities:**
- Inline-flex button with consistent sizing
- Primary: amber bg, dark text, glow shadow on hover
- Outline: transparent, cream text, border, amber fill on hover
- `external` adds `target="_blank" rel="noopener"`

### FeatureCard.astro

**Props:** `label: string`, `title: string`, `description: string`

New minimal design — no emoji icons, no illustrations. Just:
- Small amber eyebrow (the `label` — e.g., "WRITE", "CONNECT", "PROTECT")
- Serif title
- Sans-serif description
- Subtle hover: border shifts to accent, small amber glow

### PricingCard.astro

**Props:** `tier: 'free' | 'monthly' | 'yearly'`, `featured?: boolean`, `price: string`, `period: string`, `cta: string`

Same as current pricing cards but as reusable component.

## Hero Design (the signature moment)

This is the most important piece of the entire site.

### Layout

```
   [top of viewport with radial amber glow]


   HAVEN — PRIVATE NOTES FOR iOS         [12px eyebrow, amber, letter-spacing]


   A quiet place                          [~9vw serif, cream]
   to think.                              [~9vw serif, cream]

   No AI watching.                        [~9vw serif, cream]
   No metrics counting.                   [~9vw serif, cream]

   Just you and your words —              [~9vw serif italic, amber]
   the way writing                        [~9vw serif italic, amber]
   used to feel.                          [~9vw serif italic, amber]


   [Download for iOS]  [Read the story]   [buttons, centered]


   [large whitespace below]
```

### Typographic details

- **Font size**: `clamp(56px, 9vw, 128px)` — fluid, massive on desktop, still readable on mobile
- **Line height**: 1.02 — tight so the lines feel like one block
- **Letter spacing**: -0.03em — tight for drama
- **First 3 paragraphs** (cream): `font-bold` (700)
- **Last 3 paragraphs** (amber italic): `font-normal` (400) + `italic`
- **Spacing between paragraphs**: 0 within a stanza, ~0.5em between stanzas
- **Max-width**: Set on the container, not the text — let text flow naturally

### Responsive
- Desktop: max-width 1080px, centered, left-aligned
- Mobile: padding 24px, font scales down via clamp
- The break points in the text stay the same — they're part of the rhythm

### What's NOT in the hero
- No phone screenshot
- No illustration
- No graph
- No decorative SVG marks
- No video
- No image of any kind

## Landing Page Structure (Full)

### 1. Hero
(see above — manifesto in massive type)

### 2. Knowledge Graph Section
**Before:** Split layout with SVG illustration on one side

**After:** Full-width centered pull quote:
```
THE KNOWLEDGE GRAPH

   Link notes with [[double brackets]].
   Watch ideas find each other.

                                        [pull quote, Georgia italic, 32-44px]

   [Learn how it works →]               [small text link]
```

### 3. Features Grid
**Before:** 6 cards with emoji/SVG icons

**After:** 6 cards with typographic treatment only:
- Eyebrow label (e.g., "WRITE" in amber small caps)
- Serif title
- Sans-serif one-line description
- No icons
- Card has hover state (amber border, subtle lift)

```
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ WRITE            │  │ CONNECT          │  │ PROTECT          │
│                  │  │                  │  │                  │
│ Live Markdown    │  │ Wiki Links       │  │ E2E Encrypted    │
│                  │  │                  │  │                  │
│ Format as you    │  │ Connect notes    │  │ AES-256 on your  │
│ type. No modes.  │  │ with [[links]].  │  │ device only.     │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

### 4. Pricing Teaser
Centered, minimal. No illustration.
```
                  PRICING

                  Free forever.
                  Pro unlocks sync.

   Haven is free. Pro adds cloud sync and end-to-end
   encryption for $2.99/mo or $19.99/yr.

                  [See full pricing →]
```

### 5. Final CTA
```
                  Ready to
                  start writing?

   [Download for iOS]

   — radial glow fades in from bottom —
```

## Other Pages

**pricing.html → pricing.astro:** Same content, now using components. Pricing cards become `<PricingCard />` instances. FAQ uses native `<details>`.

**story.html → story.astro:** Same narrative, wrapped in `BaseLayout`. Prose styled with `prose-serif` utility. Section marks removed (typography carries the section breaks).

**compare.html → compare.astro:** Comparison table preserved. Brand mark SVG removed, replaced with typographic header.

**changelog.html → changelog.astro:** Content preserved, divider SVG removed.

**privacy, terms, support:** Content fully preserved, wrapped in components.

## Scroll Reveal (JavaScript)

~20 lines of vanilla JS in `BaseLayout.astro`, same Intersection Observer approach as before. Only triggers on elements with `.reveal` class.

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

## Vercel Configuration

`docs/vercel.json`:
```json
{
  "cleanUrls": true
}
```

Astro automatically generates clean URLs in `dist/`, so `/pricing` already maps to `pricing/index.html`. The cleanUrls config is kept as a safety net.

**Vercel project settings update:**
- Build command: `npm run build` (Astro default)
- Output directory: `dist` (Astro default)
- Root directory: `docs` (unchanged)
- Framework preset: Astro (auto-detected)

## Migration Safety

1. Move existing `docs/*.html`, `docs/styles.css`, `docs/assets/` to `docs/_legacy/`
2. Initialize Astro project in `docs/`
3. Build new site in parallel — live site keeps serving from last Vercel deploy
4. When new build works locally, push and let Vercel deploy
5. Verify live site
6. Delete `docs/_legacy/` in a follow-up commit

If anything breaks, we can:
- Revert the commit
- Vercel auto-reverts to previous deploy
- Restore `_legacy/` contents

## Performance Target

- Total CSS < 15KB (Tailwind purged + global.css)
- Zero JavaScript on initial load (only scroll reveal ~500B)
- LCP < 1.2s on 3G (no images to load on landing page)
- Lighthouse score: 100 performance, 100 accessibility, 100 SEO, 100 best practices

## What This Is NOT

- Not a content rewrite (except hero manifesto text)
- Not a change to site structure or URLs
- Not adding analytics, tracking, or third-party scripts
- Not adding webfonts
- Not adding React or client-side JS frameworks
- Not adding images, illustrations, or video
- Not adding dark/light mode toggle (dark only, same as current)
- Not changing domain or deployment platform

## Out of Scope

- Blog / CMS
- Internationalization
- A/B testing
- Comments or social widgets
- Newsletter signup
- User authentication
- Server-side rendering (Astro static only)
