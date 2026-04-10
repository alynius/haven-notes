# havennotes.app Astro Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate havennotes.app from static HTML/CSS to Astro + Tailwind CSS while simultaneously rebuilding the visual language into typographic minimalism (manifesto-driven hero, no illustrations, no screenshots).

**Architecture:** Astro 5 with `@astrojs/tailwind` integration. Single `BaseLayout.astro` wraps all pages. 7 reusable components (Nav, Footer, Hero, Eyebrow, Button, FeatureCard, PricingCard). Tailwind config holds design tokens. Static output to `docs/dist/`, deployed by Vercel.

**Tech Stack:** Astro 5, Tailwind CSS 4, TypeScript, Node 20+, Vercel.

---

## File Structure (final state)

```
docs/
  package.json              — astro + tailwind dependencies
  astro.config.mjs          — astro config with tailwind integration
  tailwind.config.mjs       — design tokens as Tailwind theme
  tsconfig.json             — astro default
  .gitignore                — ignore node_modules, dist, .astro
  vercel.json               — cleanUrls: true
  public/
    favicon.png
    apple-touch-icon.png
    robots.txt
    sitemap.xml
  src/
    layouts/
      BaseLayout.astro      — HTML shell, meta, nav, footer, reveal script
    components/
      Nav.astro
      Footer.astro
      Hero.astro            — landing hero only
      Eyebrow.astro
      Button.astro
      FeatureCard.astro
      PricingCard.astro
    pages/
      index.astro
      pricing.astro
      story.astro
      compare.astro
      changelog.astro
      privacy.astro
      terms.astro
      support.astro
    styles/
      global.css            — Tailwind directives + base + components layer
  _legacy/                  — old files (deleted at end)
```

---

### Task 1: Archive existing docs folder to _legacy

**Files:**
- Move: everything in `docs/` except `docs/superpowers/` → `docs/_legacy/`

This preserves the current site during migration. Vercel keeps serving the last good build, so no downtime.

- [ ] **Step 1: Create _legacy directory**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
mkdir -p _legacy
```

- [ ] **Step 2: Move all top-level files and asset/ folders into _legacy**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
mv *.html _legacy/
mv *.css _legacy/
mv *.png _legacy/ 2>/dev/null || true
mv *.xml _legacy/
mv *.txt _legacy/
mv assets _legacy/
```

Verify only `_legacy/`, `superpowers/`, and `vercel.json` remain:
```bash
ls -la
```

Expected: `_legacy/`, `superpowers/`, `vercel.json` (plus `.gitignore` if present).

- [ ] **Step 3: Move vercel.json into _legacy too (we'll write a new one later)**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
mv vercel.json _legacy/
```

- [ ] **Step 4: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add -A docs/
git commit -m "chore(site): archive current static site to _legacy for Astro migration"
```

---

### Task 2: Initialize Astro project with Tailwind

**Files:**
- Create: `docs/package.json`
- Create: `docs/astro.config.mjs`
- Create: `docs/tailwind.config.mjs`
- Create: `docs/tsconfig.json`
- Create: `docs/.gitignore`

- [ ] **Step 1: Create package.json**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/package.json`:

```json
{
  "name": "havennotes-site",
  "type": "module",
  "version": "0.0.1",
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "astro": "astro"
  },
  "dependencies": {
    "astro": "^5.0.0",
    "@astrojs/tailwind": "^5.1.0",
    "tailwindcss": "^3.4.0"
  }
}
```

Note: We use Tailwind 3.x with `@astrojs/tailwind` because Tailwind 4 requires a different integration path. Tailwind 3 is stable and proven.

- [ ] **Step 2: Install dependencies**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
npm install
```

Expected: `node_modules/` created, `package-lock.json` generated. No errors.

- [ ] **Step 3: Create astro.config.mjs**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/astro.config.mjs`:

```javascript
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://havennotes.app',
  integrations: [
    tailwind({
      applyBaseStyles: false,
    }),
  ],
  build: {
    format: 'directory',
  },
});
```

- [ ] **Step 4: Create tailwind.config.mjs**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/tailwind.config.mjs`:

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,ts,tsx,md,mdx,vue,svelte}'],
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
        'glow-bottom': 'radial-gradient(ellipse 60% 50% at 50% 100%, rgba(160,133,94,0.15), transparent 70%)',
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

- [ ] **Step 5: Create tsconfig.json**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/tsconfig.json`:

```json
{
  "extends": "astro/tsconfigs/strict"
}
```

- [ ] **Step 6: Create .gitignore**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/.gitignore`:

```
# build output
dist/
.astro/

# dependencies
node_modules/

# logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# environment
.env
.env.production

# macOS
.DS_Store
```

- [ ] **Step 7: Verify build works (before creating any pages)**

Create a minimal placeholder so astro doesn't error on empty project:
```bash
mkdir -p /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages
```

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/index.astro`:

```astro
---
---
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Placeholder</title>
  </head>
  <body>
    <p>Astro works.</p>
  </body>
</html>
```

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
npm run build
```

Expected: Build succeeds, `dist/index.html` is created.

- [ ] **Step 8: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/package.json docs/package-lock.json docs/astro.config.mjs docs/tailwind.config.mjs docs/tsconfig.json docs/.gitignore docs/src/pages/index.astro
git commit -m "feat(site): initialize Astro project with Tailwind"
```

---

### Task 3: Copy public assets from _legacy

**Files:**
- Create: `docs/public/favicon.png`
- Create: `docs/public/apple-touch-icon.png`
- Create: `docs/public/robots.txt`
- Create: `docs/public/sitemap.xml`

- [ ] **Step 1: Create public directory**

Run:
```bash
mkdir -p /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/public
```

- [ ] **Step 2: Copy favicon and apple-touch-icon from _legacy**

Run:
```bash
cp /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/_legacy/favicon.png /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/public/favicon.png
cp /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/_legacy/apple-touch-icon.png /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/public/apple-touch-icon.png
```

- [ ] **Step 3: Copy robots.txt and sitemap.xml from _legacy**

Run:
```bash
cp /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/_legacy/robots.txt /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/public/robots.txt
cp /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/_legacy/sitemap.xml /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/public/sitemap.xml
```

- [ ] **Step 4: Verify all 4 files exist**

Run:
```bash
ls -la /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/public/
```

Expected: 4 files present.

- [ ] **Step 5: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/public/
git commit -m "feat(site): copy static assets to Astro public directory"
```

---

### Task 4: Create global.css with Tailwind directives and base styles

**Files:**
- Create: `docs/src/styles/global.css`

- [ ] **Step 1: Create the styles directory**

Run:
```bash
mkdir -p /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/styles
```

- [ ] **Step 2: Write global.css**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/styles/global.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  *, *::before, *::after {
    box-sizing: border-box;
  }

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
    min-height: 100vh;
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

  :focus:not(:focus-visible) {
    outline: none;
  }

  h1, h2, h3, h4, h5, h6 {
    @apply font-serif font-bold text-text-primary;
    letter-spacing: -0.02em;
    line-height: 1.1;
  }

  a {
    @apply text-accent;
    text-decoration: none;
    transition: color 0.2s cubic-bezier(0.25, 0.1, 0.25, 1);
  }

  a:hover {
    @apply text-accent-hover;
  }

  img {
    display: block;
    max-width: 100%;
    height: auto;
  }

  code, kbd, samp {
    @apply font-mono text-sm bg-surface border border-border rounded px-1.5 py-0.5;
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

  .prose-serif p,
  .prose-serif ul,
  .prose-serif ol {
    margin-bottom: 1.25em;
  }

  .prose-serif li {
    margin-bottom: 0.4em;
  }

  .prose-serif h2 {
    font-size: 32px;
    margin-top: 2em;
    margin-bottom: 0.6em;
  }

  .prose-serif h3 {
    font-size: 22px;
    margin-top: 1.8em;
    margin-bottom: 0.6em;
  }

  .prose-serif a {
    text-decoration: underline;
    text-underline-offset: 3px;
    text-decoration-thickness: 1px;
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

  .reveal-delay-1 { transition-delay: 0.1s; }
  .reveal-delay-2 { transition-delay: 0.2s; }
  .reveal-delay-3 { transition-delay: 0.3s; }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/styles/global.css
git commit -m "feat(site): add Tailwind global stylesheet with base styles"
```

---

### Task 5: Create Eyebrow and Button components

**Files:**
- Create: `docs/src/components/Eyebrow.astro`
- Create: `docs/src/components/Button.astro`

- [ ] **Step 1: Create components directory**

Run:
```bash
mkdir -p /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/components
```

- [ ] **Step 2: Write Eyebrow.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/components/Eyebrow.astro`:

```astro
---
---
<span class="inline-block font-sans text-micro font-semibold tracking-[0.15em] uppercase text-accent mb-4">
  <slot />
</span>
```

- [ ] **Step 3: Write Button.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/components/Button.astro`:

```astro
---
interface Props {
  href: string;
  variant?: 'primary' | 'outline';
  external?: boolean;
}

const { href, variant = 'primary', external = false } = Astro.props;

const baseClasses = 'inline-flex items-center justify-center gap-2 font-sans text-base font-semibold px-7 py-3.5 rounded-[10px] transition-all duration-200 ease-premium whitespace-nowrap';

const variantClasses = {
  primary: 'bg-accent text-bg hover:bg-accent-hover hover:-translate-y-0.5 hover:shadow-accent-glow active:translate-y-0',
  outline: 'bg-transparent text-text-primary border border-border-strong hover:border-accent hover:text-accent hover:bg-accent/5',
};

const rel = external ? 'noopener noreferrer' : undefined;
const target = external ? '_blank' : undefined;
---
<a
  href={href}
  class={`${baseClasses} ${variantClasses[variant]}`}
  rel={rel}
  target={target}
>
  <slot />
</a>
```

- [ ] **Step 4: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/components/Eyebrow.astro docs/src/components/Button.astro
git commit -m "feat(site): add Eyebrow and Button components"
```

---

### Task 6: Create Nav component

**Files:**
- Create: `docs/src/components/Nav.astro`

- [ ] **Step 1: Write Nav.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/components/Nav.astro`:

```astro
---
interface Props {
  currentPath?: string;
}

const { currentPath = '/' } = Astro.props;

const links = [
  { href: '/#features', label: 'Features', path: '/#features' },
  { href: '/pricing', label: 'Pricing', path: '/pricing' },
  { href: '/story', label: 'Story', path: '/story' },
  { href: '/compare', label: 'Compare', path: '/compare' },
];

const appStoreUrl = 'https://apps.apple.com/app/id6744229406';
---
<nav
  id="nav"
  class="sticky top-0 z-[100] bg-bg/85 backdrop-blur-xl border-b border-border transition-all duration-300"
>
  <div class="flex items-center justify-between max-w-[1080px] mx-auto px-6 h-[68px]">
    <a href="/" class="font-serif text-[20px] font-bold tracking-[-0.01em] text-text-primary hover:text-text-primary">Haven</a>

    <div class="hidden md:flex items-center gap-8">
      {links.map((link) => (
        <a
          href={link.href}
          aria-current={currentPath === link.path ? 'page' : undefined}
          class:list={[
            'relative text-sm text-text-secondary hover:text-text-primary transition-colors duration-200',
            'after:content-[""] after:absolute after:-bottom-1.5 after:left-0 after:w-0 after:h-[1.5px] after:bg-accent after:transition-all after:duration-200',
            'hover:after:w-full',
            currentPath === link.path && 'text-text-primary',
          ]}
        >
          {link.label}
        </a>
      ))}
      <a
        href={appStoreUrl}
        class="inline-flex items-center bg-accent text-bg font-semibold text-sm px-[18px] py-[9px] rounded-lg transition-all duration-200 hover:bg-accent-hover hover:shadow-accent-glow hover:text-bg"
      >
        Download
      </a>
    </div>

    <button
      class="md:hidden bg-transparent border-none cursor-pointer p-2"
      onclick="document.getElementById('mobile-menu').classList.toggle('open')"
      aria-label="Menu"
      aria-expanded="false"
      aria-controls="mobile-menu"
    >
      <span aria-hidden="true" class="block w-5 h-0.5 bg-text-primary my-1"></span>
      <span aria-hidden="true" class="block w-5 h-0.5 bg-text-primary my-1"></span>
      <span aria-hidden="true" class="block w-5 h-0.5 bg-text-primary my-1"></span>
    </button>
  </div>

  <div
    id="mobile-menu"
    class="hidden flex-col bg-bg border-t border-border py-2 pb-4 md:hidden [&.open]:flex"
  >
    <a href="/#features" class="text-base text-text-secondary hover:text-text-primary py-3 px-6">Features</a>
    <a href="/pricing" class="text-base text-text-secondary hover:text-text-primary py-3 px-6">Pricing</a>
    <a href="/story" class="text-base text-text-secondary hover:text-text-primary py-3 px-6">Story</a>
    <a href="/compare" class="text-base text-text-secondary hover:text-text-primary py-3 px-6">Compare</a>
    <a href={appStoreUrl} class="text-base text-text-secondary hover:text-text-primary py-3 px-6">Download</a>
  </div>
</nav>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/components/Nav.astro
git commit -m "feat(site): add Nav component with sticky blur and mobile menu"
```

---

### Task 7: Create Footer component

**Files:**
- Create: `docs/src/components/Footer.astro`

- [ ] **Step 1: Write Footer.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/components/Footer.astro`:

```astro
---
const appStoreUrl = 'https://apps.apple.com/app/id6744229406';
---
<footer class="border-t border-border pt-16 pb-8 bg-bg">
  <div class="grid grid-cols-1 md:grid-cols-3 gap-12 max-w-[1080px] mx-auto px-6 mb-12">
    <div class="flex flex-col gap-2">
      <h4 class="font-sans text-micro font-semibold tracking-[0.1em] uppercase text-text-secondary mb-4">Pages</h4>
      <a href="/" class="text-sm text-text-secondary hover:text-text-primary transition-colors">Home</a>
      <a href="/pricing" class="text-sm text-text-secondary hover:text-text-primary transition-colors">Pricing</a>
      <a href="/story" class="text-sm text-text-secondary hover:text-text-primary transition-colors">Story</a>
      <a href="/compare" class="text-sm text-text-secondary hover:text-text-primary transition-colors">Compare</a>
      <a href="/changelog" class="text-sm text-text-secondary hover:text-text-primary transition-colors">Changelog</a>
    </div>

    <div class="flex flex-col gap-2">
      <h4 class="font-sans text-micro font-semibold tracking-[0.1em] uppercase text-text-secondary mb-4">Legal</h4>
      <a href="/privacy" class="text-sm text-text-secondary hover:text-text-primary transition-colors">Privacy Policy</a>
      <a href="/terms" class="text-sm text-text-secondary hover:text-text-primary transition-colors">Terms of Use</a>
    </div>

    <div class="flex flex-col gap-2">
      <h4 class="font-sans text-micro font-semibold tracking-[0.1em] uppercase text-text-secondary mb-4">Connect</h4>
      <a href="mailto:support@havennotes.app" class="text-sm text-text-secondary hover:text-text-primary transition-colors">support@havennotes.app</a>
      <a href="/support" class="text-sm text-text-secondary hover:text-text-primary transition-colors">Support</a>
      <a href={appStoreUrl} class="text-sm text-text-secondary hover:text-text-primary transition-colors">App Store</a>
    </div>
  </div>

  <div class="flex flex-col md:flex-row items-start md:items-center justify-between max-w-[1080px] mx-auto px-6 pt-6 border-t border-border text-sm text-text-secondary gap-4">
    <span>Made by one person who was tired of bloated note apps.</span>
    <span>&copy; 2026 Haven Notes</span>
  </div>
</footer>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/components/Footer.astro
git commit -m "feat(site): add Footer component"
```

---

### Task 8: Create BaseLayout component

**Files:**
- Create: `docs/src/layouts/BaseLayout.astro`

- [ ] **Step 1: Create layouts directory**

Run:
```bash
mkdir -p /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/layouts
```

- [ ] **Step 2: Write BaseLayout.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/layouts/BaseLayout.astro`:

```astro
---
import '../styles/global.css';
import Nav from '../components/Nav.astro';
import Footer from '../components/Footer.astro';

interface Props {
  title: string;
  description: string;
  ogUrl: string;
  currentPath?: string;
}

const { title, description, ogUrl, currentPath } = Astro.props;
---
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" href="/favicon.png" type="image/png" />
    <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{title}</title>
    <meta name="description" content={description} />
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta property="og:type" content="website" />
    <meta property="og:url" content={ogUrl} />
    <link rel="canonical" href={ogUrl} />
  </head>
  <body>
    <Nav currentPath={currentPath} />
    <main>
      <slot />
    </main>
    <Footer />

    <script>
      // Nav scroll effect
      const nav = document.getElementById('nav');
      if (nav) {
        window.addEventListener('scroll', () => {
          nav.classList.toggle('scrolled', window.scrollY > 10);
        }, { passive: true });
      }

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

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/layouts/BaseLayout.astro
git commit -m "feat(site): add BaseLayout with meta, nav, footer, reveal script"
```

---

### Task 9: Create Hero component (the manifesto)

**Files:**
- Create: `docs/src/components/Hero.astro`

- [ ] **Step 1: Write Hero.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/components/Hero.astro`:

```astro
---
import Eyebrow from './Eyebrow.astro';
import Button from './Button.astro';

const appStoreUrl = 'https://apps.apple.com/app/id6744229406';
---
<section class="relative overflow-hidden pt-24 pb-24 md:pt-32 md:pb-32 bg-glow-top">
  <div class="relative z-10 max-w-[1080px] mx-auto px-6 text-center">
    <div class="reveal">
      <Eyebrow>Haven — Private notes for iOS</Eyebrow>
    </div>

    <h1 class="font-serif text-hero text-text-primary reveal reveal-delay-1">
      <span class="block font-bold">A quiet place</span>
      <span class="block font-bold">to think.</span>
    </h1>

    <h1 class="font-serif text-hero text-text-primary mt-6 md:mt-10 reveal reveal-delay-2">
      <span class="block font-bold">No AI watching.</span>
      <span class="block font-bold">No metrics counting.</span>
    </h1>

    <h1 class="font-serif text-hero accent-italic mt-6 md:mt-10 reveal reveal-delay-3">
      <span class="block">Just you and your words —</span>
      <span class="block">the way writing</span>
      <span class="block">used to feel.</span>
    </h1>

    <div class="flex flex-wrap justify-center gap-3 mt-12 md:mt-16 reveal reveal-delay-3">
      <Button href={appStoreUrl} variant="primary" external={true}>Download for iOS</Button>
      <Button href="/story" variant="outline">Read the story</Button>
    </div>
  </div>
</section>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/components/Hero.astro
git commit -m "feat(site): add Hero component with typographic manifesto"
```

---

### Task 10: Create FeatureCard component

**Files:**
- Create: `docs/src/components/FeatureCard.astro`

- [ ] **Step 1: Write FeatureCard.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/components/FeatureCard.astro`:

```astro
---
interface Props {
  label: string;
  title: string;
  description: string;
}

const { label, title, description } = Astro.props;
---
<div class="group bg-elevated border border-border rounded-[14px] p-8 transition-all duration-300 hover:-translate-y-1 hover:border-accent hover:shadow-accent-glow">
  <span class="block font-sans text-micro font-semibold tracking-[0.15em] uppercase text-accent mb-4">
    {label}
  </span>
  <h3 class="font-serif text-xl font-bold text-text-primary mb-2">
    {title}
  </h3>
  <p class="text-sm text-text-secondary leading-relaxed">
    {description}
  </p>
</div>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/components/FeatureCard.astro
git commit -m "feat(site): add FeatureCard component"
```

---

### Task 11: Create PricingCard component

**Files:**
- Create: `docs/src/components/PricingCard.astro`

- [ ] **Step 1: Write PricingCard.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/components/PricingCard.astro`:

```astro
---
interface Props {
  title: string;
  price: string;
  period: string;
  cta: string;
  ctaHref: string;
  ctaVariant?: 'primary' | 'outline';
  featured?: boolean;
  badge?: string;
  note: string;
}

const { title, price, period, cta, ctaHref, ctaVariant = 'outline', featured = false, badge, note } = Astro.props;

const cardClasses = featured
  ? 'bg-elevated border-2 border-accent rounded-2xl p-8 flex flex-col gap-2 shadow-accent-glow'
  : 'bg-elevated border border-border rounded-2xl p-8 flex flex-col gap-2 transition-all duration-300 hover:-translate-y-0.5 hover:border-border-strong hover:shadow-warm-md';

const buttonClasses = ctaVariant === 'primary'
  ? 'mt-4 w-full inline-flex items-center justify-center bg-accent text-bg font-semibold text-base px-6 py-3 rounded-[10px] transition-all duration-200 hover:bg-accent-hover hover:shadow-accent-glow'
  : 'mt-4 w-full inline-flex items-center justify-center bg-transparent text-text-primary font-semibold text-base px-6 py-3 rounded-[10px] border border-border-strong transition-all duration-200 hover:border-accent hover:text-accent hover:bg-accent/5';
---
<div class={cardClasses}>
  {badge && (
    <span class="inline-block self-start bg-accent text-bg text-micro font-bold tracking-[0.08em] uppercase px-3 py-1 rounded-full mb-2">
      {badge}
    </span>
  )}
  <h3 class="font-serif text-xl font-bold text-text-primary mb-2">{title}</h3>
  <div class="font-serif text-[44px] leading-none tracking-[-0.03em] text-text-primary">{price}</div>
  <div class="text-sm text-text-secondary mb-2">{period}</div>
  <a href={ctaHref} class={buttonClasses}>{cta}</a>
  <p class="text-micro text-text-secondary mt-2">{note}</p>
</div>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/components/PricingCard.astro
git commit -m "feat(site): add PricingCard component"
```

---

### Task 12: Rewrite index.astro (landing page)

**Files:**
- Replace: `docs/src/pages/index.astro`

Replace the placeholder from Task 2 with the full landing page.

- [ ] **Step 1: Write the landing page**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/index.astro`:

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Hero from '../components/Hero.astro';
import Eyebrow from '../components/Eyebrow.astro';
import Button from '../components/Button.astro';
import FeatureCard from '../components/FeatureCard.astro';

const appStoreUrl = 'https://apps.apple.com/app/id6744229406';

const features = [
  { label: 'Write', title: 'Live Markdown', description: 'Bold, italic, headings, and code — rendered as you type. No mode switching.' },
  { label: 'Connect', title: 'Wiki Links', description: 'Connect notes with [[brackets]]. Build a personal knowledge network.' },
  { label: 'Protect', title: 'E2E Encrypted', description: 'AES-256 encryption. Keys live on your device. Not even we can read your notes.' },
  { label: 'Rhythm', title: 'Daily Notes', description: 'A fresh note every day, automatically. Perfect for journaling.' },
  { label: 'Capture', title: 'Voice Dictation', description: 'Capture thoughts hands-free. On-device processing. Nothing leaves your phone.' },
  { label: 'Find', title: 'Full-Text Search', description: 'Find anything instantly. Fast, on-device, no indexing delays.' },
];
---
<BaseLayout
  title="Haven Notes — Private markdown notes for iOS"
  description="A quiet place to think. Markdown notes with wiki links and a visual knowledge graph. Private by design. Encrypted end to end."
  ogUrl="https://havennotes.app/"
  currentPath="/"
>
  <Hero />

  <!-- Knowledge Graph Pull Quote -->
  <section id="graph" class="relative py-24 md:py-32 bg-glow-right">
    <div class="relative max-w-prose mx-auto px-6 text-center">
      <div class="reveal">
        <Eyebrow>The Knowledge Graph</Eyebrow>
      </div>
      <p class="font-serif text-3xl md:text-display accent-italic leading-[1.15] mt-6 reveal reveal-delay-1">
        Link notes with [[double brackets]]. Watch ideas find each other.
      </p>
      <div class="mt-12 reveal reveal-delay-2">
        <a href="/story" class="inline-flex items-center gap-2 text-accent font-semibold hover:text-accent-hover transition-colors">
          Why we built this →
        </a>
      </div>
    </div>
  </section>

  <!-- Features Grid -->
  <section id="features" class="py-24 md:py-32">
    <div class="max-w-[1080px] mx-auto px-6">
      <div class="text-center mb-16 reveal">
        <Eyebrow>Built for thinkers</Eyebrow>
        <h2 class="font-serif text-display mt-4">
          Everything you need,<br>
          <span class="accent-italic">nothing you don't.</span>
        </h2>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {features.map((feature, index) => (
          <div class={`reveal ${index % 3 === 1 ? 'reveal-delay-1' : index % 3 === 2 ? 'reveal-delay-2' : ''}`}>
            <FeatureCard
              label={feature.label}
              title={feature.title}
              description={feature.description}
            />
          </div>
        ))}
      </div>
    </div>
  </section>

  <!-- Pricing Teaser -->
  <section class="relative py-24 text-center bg-glow-center">
    <div class="relative max-w-[600px] mx-auto px-6">
      <div class="reveal">
        <Eyebrow>Pricing</Eyebrow>
      </div>
      <h2 class="font-serif text-4xl md:text-5xl mt-4 reveal reveal-delay-1">
        Free forever.<br>
        Pro <span class="accent-italic">unlocks sync.</span>
      </h2>
      <p class="text-lg text-text-secondary mt-6 reveal reveal-delay-2">
        Haven is free. Pro adds cloud sync and end-to-end encryption — $2.99/mo or $19.99/yr.
      </p>
      <div class="mt-8 reveal reveal-delay-2">
        <a href="/pricing" class="inline-flex items-center gap-2 text-accent font-semibold hover:text-accent-hover transition-colors">
          See full pricing →
        </a>
      </div>
    </div>
  </section>

  <!-- Final CTA -->
  <section class="relative py-32 md:py-40 text-center border-t border-border bg-glow-bottom">
    <div class="relative max-w-[600px] mx-auto px-6">
      <h2 class="font-serif text-display reveal">
        Ready to<br>
        <span class="accent-italic">start writing?</span>
      </h2>
      <p class="text-lg text-text-secondary mt-6 reveal reveal-delay-1">
        Haven is free to download. Pro unlocks sync when you need it.
      </p>
      <div class="mt-8 reveal reveal-delay-2">
        <Button href={appStoreUrl} variant="primary" external={true}>Download for iOS</Button>
      </div>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Build to verify**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
npm run build
```

Expected: Build succeeds. `dist/index.html` exists.

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/pages/index.astro
git commit -m "feat(site): rewrite landing page with typographic manifesto hero"
```

---

### Task 13: Create pricing.astro

**Files:**
- Create: `docs/src/pages/pricing.astro`

- [ ] **Step 1: Read the legacy pricing page to extract FAQ and table content**

Run:
```bash
cat /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/_legacy/pricing.html
```

Note: the content already exists. We'll rebuild it in the new component structure.

- [ ] **Step 2: Write pricing.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/pricing.astro`:

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Eyebrow from '../components/Eyebrow.astro';
import Button from '../components/Button.astro';
import PricingCard from '../components/PricingCard.astro';

const appStoreUrl = 'https://apps.apple.com/app/id6744229406';

const features = [
  { name: 'Local notes', free: true, pro: true },
  { name: 'Markdown editor', free: true, pro: true },
  { name: 'Wiki links', free: true, pro: true },
  { name: 'Knowledge graph', free: true, pro: true },
  { name: 'Tags & folders', free: true, pro: true },
  { name: 'Daily notes', free: true, pro: true },
  { name: 'Voice dictation', free: true, pro: true },
  { name: 'Full-text search', free: true, pro: true },
  { name: 'Widgets', free: true, pro: true },
  { name: 'Cloud sync', free: false, pro: true },
  { name: 'E2E encrypted sync', free: false, pro: true },
];
---
<BaseLayout
  title="Pricing — Haven Notes"
  description="Haven is free. Pro unlocks sync."
  ogUrl="https://havennotes.app/pricing"
  currentPath="/pricing"
>
  <section class="py-20 md:py-24 text-center">
    <div class="max-w-[1080px] mx-auto px-6">
      <Eyebrow>Pricing</Eyebrow>
      <h1 class="font-serif text-display mt-4">
        Simple, <span class="accent-italic">honest pricing.</span>
      </h1>
      <p class="text-lg text-text-secondary mt-4 max-w-prose mx-auto">
        Haven is free. Pro unlocks sync.
      </p>
    </div>
  </section>

  <!-- Comparison Table -->
  <section class="pb-16">
    <div class="max-w-[1080px] mx-auto px-6 overflow-x-auto">
      <table class="w-full border-collapse text-sm">
        <thead>
          <tr>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-left py-4 px-6 border-b border-border bg-surface">Feature</th>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-center py-4 px-6 border-b border-border bg-surface">Free</th>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-center py-4 px-6 border-b border-border bg-surface bg-accent/10">Pro</th>
          </tr>
        </thead>
        <tbody>
          {features.map((feature) => (
            <tr class="hover:bg-accent/5 transition-colors">
              <td class="py-4 px-6 border-b border-border text-text-primary">{feature.name}</td>
              <td class="py-4 px-6 border-b border-border text-center">
                {feature.free ? <span class="text-accent font-bold">✓</span> : <span class="text-text-secondary">—</span>}
              </td>
              <td class="py-4 px-6 border-b border-border text-center bg-accent/5">
                {feature.pro ? <span class="text-accent font-bold">✓</span> : <span class="text-text-secondary">—</span>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  </section>

  <!-- Pricing Cards -->
  <section class="pb-16">
    <div class="max-w-[820px] mx-auto px-6 grid grid-cols-1 md:grid-cols-3 gap-4">
      <PricingCard
        title="Free"
        price="$0"
        period="forever"
        cta="Download"
        ctaHref={appStoreUrl}
        ctaVariant="outline"
        note="All core features included"
      />
      <PricingCard
        title="Monthly"
        price="$2.99"
        period="per month"
        cta="Download Haven"
        ctaHref={appStoreUrl}
        ctaVariant="outline"
        note="Auto-renewable · Cancel anytime"
      />
      <PricingCard
        title="Yearly"
        price="$19.99"
        period="per year"
        cta="Download Haven"
        ctaHref={appStoreUrl}
        ctaVariant="primary"
        featured={true}
        badge="Save 44%"
        note="Auto-renewable · Cancel anytime"
      />
    </div>
  </section>

  <!-- FAQ -->
  <section class="pb-24">
    <div class="max-w-prose mx-auto px-6">
      <h2 class="font-serif text-3xl text-center mb-10">
        Frequently asked <span class="accent-italic">questions</span>
      </h2>
      <details class="border-t border-border group">
        <summary class="flex items-center justify-between cursor-pointer py-6 font-medium text-text-primary text-lg list-none [&::-webkit-details-marker]:hidden">
          Can I use Haven for free?
          <span class="text-accent text-2xl font-light group-open:hidden">+</span>
          <span class="text-accent text-2xl font-light hidden group-open:inline">−</span>
        </summary>
        <div class="pb-6 text-text-secondary leading-relaxed">All core features are free forever: markdown editor, wiki links, knowledge graph, tags, folders, daily notes, voice dictation, full-text search, and widgets. Only sync and encryption require Pro.</div>
      </details>
      <details class="border-t border-border group">
        <summary class="flex items-center justify-between cursor-pointer py-6 font-medium text-text-primary text-lg list-none [&::-webkit-details-marker]:hidden">
          What does Pro add?
          <span class="text-accent text-2xl font-light group-open:hidden">+</span>
          <span class="text-accent text-2xl font-light hidden group-open:inline">−</span>
        </summary>
        <div class="pb-6 text-text-secondary leading-relaxed">Haven Pro unlocks cloud sync to your own server plus end-to-end encryption with AES-256. Your data stays yours — Haven never operates a server that sees your notes.</div>
      </details>
      <details class="border-t border-border group">
        <summary class="flex items-center justify-between cursor-pointer py-6 font-medium text-text-primary text-lg list-none [&::-webkit-details-marker]:hidden">
          How do I cancel?
          <span class="text-accent text-2xl font-light group-open:hidden">+</span>
          <span class="text-accent text-2xl font-light hidden group-open:inline">−</span>
        </summary>
        <div class="pb-6 text-text-secondary leading-relaxed">Open Settings → your Apple ID → Subscriptions → Haven → Cancel. Your subscription stays active until the end of the current billing period.</div>
      </details>
      <details class="border-t border-border border-b group">
        <summary class="flex items-center justify-between cursor-pointer py-6 font-medium text-text-primary text-lg list-none [&::-webkit-details-marker]:hidden">
          Is my data private?
          <span class="text-accent text-2xl font-light group-open:hidden">+</span>
          <span class="text-accent text-2xl font-light hidden group-open:inline">−</span>
        </summary>
        <div class="pb-6 text-text-secondary leading-relaxed">Yes. Notes live on your device. If you enable sync, they're encrypted end-to-end before leaving your phone. Haven has no analytics, no tracking, no AI reading your notes.</div>
      </details>
    </div>
  </section>

  <!-- CTA -->
  <section class="py-24 text-center border-t border-border">
    <div class="max-w-[600px] mx-auto px-6">
      <h2 class="font-serif text-4xl md:text-5xl">
        Ready to <span class="accent-italic">start writing?</span>
      </h2>
      <div class="mt-8">
        <Button href={appStoreUrl} variant="primary" external={true}>Download for iOS</Button>
      </div>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/pages/pricing.astro
git commit -m "feat(site): add pricing page in Astro"
```

---

### Task 14: Create story.astro

**Files:**
- Create: `docs/src/pages/story.astro`

- [ ] **Step 1: Write story.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/story.astro`:

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Eyebrow from '../components/Eyebrow.astro';
import Button from '../components/Button.astro';

const appStoreUrl = 'https://apps.apple.com/app/id6744229406';
---
<BaseLayout
  title="Story — Haven Notes"
  description="Why Haven exists. Built by one person who was tired of bloated note apps."
  ogUrl="https://havennotes.app/story"
  currentPath="/story"
>
  <section class="py-20 md:py-24">
    <div class="max-w-prose mx-auto px-6 prose-serif">
      <div class="text-center mb-16">
        <Eyebrow>The story</Eyebrow>
        <h1 class="font-serif text-display mt-4">
          Why <span class="accent-italic">Haven exists.</span>
        </h1>
        <p class="text-lg text-text-secondary mt-6 not-italic font-sans">
          Built by one person who was tired of bloated note apps.
        </p>
      </div>

      <h2>The problem</h2>
      <p>Modern note apps aren't about notes anymore. They're about features. Teams. Collaboration. AI. Analytics. Everything except the simple act of writing something down.</p>
      <p>Open Notion and you're greeted by a dashboard. Open Obsidian and you're configuring plugins. Open Bear and you're scrolling ads for their cloud tier. The friction between having a thought and capturing it has grown unbearable.</p>
      <p>And now, AI reads everything. Your notes are training data. Your drafts are analyzed. Your private thinking is no longer private.</p>

      <h2>The alternative</h2>
      <p>Haven is a note app that remembers what notes are for: thinking. It opens instantly. It has no dashboard. It never asks you to sign in. It never reads your writing. It doesn't try to be a wiki, a database, a CRM, or a knowledge management system.</p>
      <p>It's just a place for your thoughts. Markdown, wiki links, a knowledge graph. Everything on your device. Everything encrypted when you sync. Nothing else.</p>

      <h2>The craft</h2>
      <p>Haven is built by one person. No venture capital. No growth team. No optimization pipeline. Just careful design and obsessive attention to detail.</p>
      <p>Every choice asks: does this serve the person writing? If the answer is no, we don't ship it. That's why there's no notification system. No streak counter. No social feed. No AI assistant asking if you'd like to "expand this idea."</p>
      <p>The subscription exists because sustainable software costs money to make. But the free version isn't crippleware — it's the full app. Pro is a way to support the work and get sync. That's it.</p>

      <p class="text-center mt-16 not-italic">
        <a href={appStoreUrl} rel="noopener noreferrer" target="_blank" class="text-accent font-semibold">Download Haven →</a>
      </p>
    </div>
  </section>

  <section class="py-24 text-center border-t border-border">
    <div class="max-w-[600px] mx-auto px-6">
      <h2 class="font-serif text-4xl md:text-5xl">
        Ready to <span class="accent-italic">start writing?</span>
      </h2>
      <div class="mt-8">
        <Button href={appStoreUrl} variant="primary" external={true}>Download for iOS</Button>
      </div>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/pages/story.astro
git commit -m "feat(site): add story page in Astro"
```

---

### Task 15: Create compare.astro

**Files:**
- Create: `docs/src/pages/compare.astro`

- [ ] **Step 1: Write compare.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/compare.astro`:

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Eyebrow from '../components/Eyebrow.astro';
import Button from '../components/Button.astro';

const appStoreUrl = 'https://apps.apple.com/app/id6744229406';

const rows = [
  { feature: 'Local-first', haven: '✓', notion: '—', bear: '✓', apple: '✓', obsidian: '✓' },
  { feature: 'E2E encryption', haven: '✓', notion: '—', bear: '—', apple: '—', obsidian: 'Plugin' },
  { feature: 'Wiki links', haven: '✓', notion: '✓', bear: '—', apple: '—', obsidian: '✓' },
  { feature: 'Knowledge graph', haven: '✓', notion: '—', bear: '—', apple: '—', obsidian: '✓' },
  { feature: 'Native iOS', haven: '✓', notion: 'Non-native', bear: '✓', apple: '✓', obsidian: 'Non-native' },
  { feature: 'No AI training', haven: '✓', notion: '—', bear: '—', apple: '—', obsidian: '✓' },
  { feature: 'No account required', haven: '✓', notion: '—', bear: '—', apple: '—', obsidian: '✓' },
];
---
<BaseLayout
  title="Haven vs Notion, Bear, Obsidian — Haven Notes"
  description="How Haven compares to other note apps. Privacy, speed, and craft over features and bloat."
  ogUrl="https://havennotes.app/compare"
  currentPath="/compare"
>
  <section class="py-20 md:py-24 text-center">
    <div class="max-w-[1080px] mx-auto px-6">
      <Eyebrow>Compare</Eyebrow>
      <h1 class="font-serif text-display mt-4">
        Haven vs <span class="accent-italic">the rest.</span>
      </h1>
      <p class="text-lg text-text-secondary mt-6 max-w-prose mx-auto">
        We're not trying to be Notion. We're not trying to be Obsidian. Here's where Haven stands.
      </p>
    </div>
  </section>

  <section class="pb-24">
    <div class="max-w-[1080px] mx-auto px-6 overflow-x-auto">
      <table class="w-full border-collapse text-sm">
        <thead>
          <tr>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-left py-4 px-4 border-b border-border bg-surface">Feature</th>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-center py-4 px-4 border-b border-border bg-accent/10">Haven</th>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-center py-4 px-4 border-b border-border bg-surface">Notion</th>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-center py-4 px-4 border-b border-border bg-surface">Bear</th>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-center py-4 px-4 border-b border-border bg-surface">Apple Notes</th>
            <th class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary text-center py-4 px-4 border-b border-border bg-surface">Obsidian</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr class="hover:bg-accent/5 transition-colors">
              <td class="py-4 px-4 border-b border-border text-text-primary">{row.feature}</td>
              <td class="py-4 px-4 border-b border-border text-center bg-accent/5">
                {row.haven === '✓' ? <span class="text-accent font-bold">✓</span> : row.haven === '—' ? <span class="text-text-secondary">—</span> : <span class="text-text-primary text-xs">{row.haven}</span>}
              </td>
              <td class="py-4 px-4 border-b border-border text-center">
                {row.notion === '✓' ? <span class="text-accent font-bold">✓</span> : row.notion === '—' ? <span class="text-text-secondary">—</span> : <span class="text-text-secondary text-xs">{row.notion}</span>}
              </td>
              <td class="py-4 px-4 border-b border-border text-center">
                {row.bear === '✓' ? <span class="text-accent font-bold">✓</span> : row.bear === '—' ? <span class="text-text-secondary">—</span> : <span class="text-text-secondary text-xs">{row.bear}</span>}
              </td>
              <td class="py-4 px-4 border-b border-border text-center">
                {row.apple === '✓' ? <span class="text-accent font-bold">✓</span> : row.apple === '—' ? <span class="text-text-secondary">—</span> : <span class="text-text-secondary text-xs">{row.apple}</span>}
              </td>
              <td class="py-4 px-4 border-b border-border text-center">
                {row.obsidian === '✓' ? <span class="text-accent font-bold">✓</span> : row.obsidian === '—' ? <span class="text-text-secondary">—</span> : <span class="text-text-secondary text-xs">{row.obsidian}</span>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  </section>

  <section class="py-24 text-center border-t border-border">
    <div class="max-w-[600px] mx-auto px-6">
      <h2 class="font-serif text-4xl md:text-5xl">
        Try Haven <span class="accent-italic">for free.</span>
      </h2>
      <div class="mt-8">
        <Button href={appStoreUrl} variant="primary" external={true}>Download for iOS</Button>
      </div>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/pages/compare.astro
git commit -m "feat(site): add compare page in Astro"
```

---

### Task 16: Create changelog.astro

**Files:**
- Create: `docs/src/pages/changelog.astro`

- [ ] **Step 1: Write changelog.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/changelog.astro`:

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Eyebrow from '../components/Eyebrow.astro';
---
<BaseLayout
  title="Changelog — Haven Notes"
  description="What's new in Haven."
  ogUrl="https://havennotes.app/changelog"
  currentPath="/changelog"
>
  <section class="py-20 md:py-24">
    <div class="max-w-prose mx-auto px-6">
      <div class="text-center mb-16">
        <Eyebrow>Updates</Eyebrow>
        <h1 class="font-serif text-display mt-4">
          <span class="accent-italic">Changelog.</span>
        </h1>
        <p class="text-lg text-text-secondary mt-6">What's new in Haven.</p>
      </div>

      <article class="border-b border-border py-12">
        <div class="font-sans text-micro font-semibold tracking-[0.08em] uppercase text-text-secondary mb-2">
          April 2026
        </div>
        <h3 class="font-serif text-2xl mb-6">Version 1.0</h3>
        <ul class="list-disc list-inside text-text-secondary space-y-2 leading-relaxed">
          <li>Initial release</li>
          <li>Markdown editor with wiki links and live preview</li>
          <li>Knowledge graph visualization</li>
          <li>Daily notes and voice dictation</li>
          <li>Full-text search</li>
          <li>Dark mode by default</li>
          <li>Haven Pro: cloud sync and end-to-end encryption</li>
        </ul>
      </article>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/pages/changelog.astro
git commit -m "feat(site): add changelog page in Astro"
```

---

### Task 17: Create privacy.astro

**Files:**
- Create: `docs/src/pages/privacy.astro`

- [ ] **Step 1: Read legacy privacy content**

Run:
```bash
cat /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/_legacy/privacy.html
```

Extract the body content. All the section headings and paragraphs need to be preserved.

- [ ] **Step 2: Write privacy.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/privacy.astro`:

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Eyebrow from '../components/Eyebrow.astro';
---
<BaseLayout
  title="Privacy Policy — Haven Notes"
  description="Haven is built on a simple principle: your notes are yours. We don't collect, store, or transmit your data."
  ogUrl="https://havennotes.app/privacy"
  currentPath="/privacy"
>
  <section class="py-20 md:py-24">
    <div class="max-w-prose mx-auto px-6 prose-serif">
      <div class="text-center mb-16">
        <Eyebrow>Legal</Eyebrow>
        <h1 class="font-serif text-display mt-4">
          Privacy <span class="accent-italic">Policy.</span>
        </h1>
        <p class="text-lg text-text-secondary mt-6 not-italic font-sans">
          Last updated: March 30, 2026
        </p>
      </div>

      <h2>The short version</h2>
      <p>Haven is built on a simple principle: <strong>your notes are yours</strong>. We don't collect, store, or transmit your data. There are no accounts. There's no tracking. There's no AI reading your writing.</p>

      <h2>What we don't collect</h2>
      <ul>
        <li><strong>No analytics.</strong> We don't track what you do in the app.</li>
        <li><strong>No crash reports.</strong> No third-party SDKs. No telemetry.</li>
        <li><strong>No account.</strong> You don't sign up. We don't know you exist.</li>
        <li><strong>No AI training.</strong> Your notes are never used to train any model.</li>
      </ul>

      <h2>What we do collect</h2>
      <p>Nothing. Haven has no servers that receive your data. All notes are stored locally on your device in an encrypted database.</p>

      <h2>Haven Pro and sync</h2>
      <p>If you subscribe to Haven Pro and enable sync, you provide your own server URL. Your notes are encrypted with AES-256 on your device before leaving your phone. Even if we ran a sync server (we don't), we wouldn't be able to read your notes.</p>

      <h2>Apple In-App Purchases</h2>
      <p>Subscription payments are processed by Apple, not by us. We receive no personal information from Apple beyond what's required for subscription validation — which is handled entirely by Apple's StoreKit framework.</p>

      <h2>Third parties</h2>
      <p>Haven uses no third-party services for analytics, tracking, advertising, or data processing. The only external connection Haven makes is to your own sync server (if you configure one) and to Apple's servers for subscription verification.</p>

      <h2>Contact</h2>
      <p>Questions? Email <a href="mailto:support@havennotes.app">support@havennotes.app</a>.</p>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 3: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/pages/privacy.astro
git commit -m "feat(site): add privacy page in Astro"
```

---

### Task 18: Create terms.astro

**Files:**
- Create: `docs/src/pages/terms.astro`

- [ ] **Step 1: Write terms.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/terms.astro`:

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Eyebrow from '../components/Eyebrow.astro';
---
<BaseLayout
  title="Terms of Use — Haven Notes"
  description="Terms of Use for Haven Notes."
  ogUrl="https://havennotes.app/terms"
  currentPath="/terms"
>
  <section class="py-20 md:py-24">
    <div class="max-w-prose mx-auto px-6 prose-serif">
      <div class="text-center mb-16">
        <Eyebrow>Legal</Eyebrow>
        <h1 class="font-serif text-display mt-4">
          Terms <span class="accent-italic">of Use.</span>
        </h1>
        <p class="text-lg text-text-secondary mt-6 not-italic font-sans">
          Last updated: April 8, 2026
        </p>
      </div>

      <h2>Acceptance of terms</h2>
      <p>By downloading, installing, or using Haven Notes ("the App"), you agree to be bound by these Terms of Use. If you do not agree, do not use the App.</p>

      <h2>License</h2>
      <p>Haven Notes grants you a personal, non-exclusive, non-transferable, limited license to use the App on any Apple-branded products that you own or control, subject to the Usage Rules set forth in the Apple Media Services Terms and Conditions.</p>

      <h2>Subscriptions (Haven Pro)</h2>
      <p>Haven Pro is an auto-renewing subscription. Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.</p>
      <p>You can manage your subscription and turn off auto-renewal by going to your Apple ID account settings after purchase. Any unused portion of a free trial period, if offered, will be forfeited when you purchase a subscription.</p>

      <h2>User content</h2>
      <p>You retain all rights to the content you create in Haven. We do not claim ownership of your notes. We do not access, read, or use your content for any purpose.</p>

      <h2>Acceptable use</h2>
      <p>You agree not to use the App for any unlawful purpose or in violation of any local, state, national, or international law.</p>

      <h2>Disclaimer</h2>
      <p>The App is provided "as is" without warranty of any kind. We do not guarantee uninterrupted, error-free operation. Use of the App is at your own risk.</p>

      <h2>Limitation of liability</h2>
      <p>To the fullest extent permitted by law, Haven Notes shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App.</p>

      <h2>Changes</h2>
      <p>We reserve the right to modify these Terms at any time. Changes will be posted on this page with an updated effective date.</p>

      <h2>Apple's standard EULA</h2>
      <p>The App is also subject to Apple's <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Licensed Application End User License Agreement</a>.</p>

      <h2>Contact</h2>
      <p>Questions? Email <a href="mailto:support@havennotes.app">support@havennotes.app</a>.</p>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/pages/terms.astro
git commit -m "feat(site): add terms page in Astro"
```

---

### Task 19: Create support.astro

**Files:**
- Create: `docs/src/pages/support.astro`

- [ ] **Step 1: Write support.astro**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/src/pages/support.astro`:

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Eyebrow from '../components/Eyebrow.astro';
---
<BaseLayout
  title="Support — Haven Notes"
  description="Get help with Haven Notes. FAQs, contact, and system requirements."
  ogUrl="https://havennotes.app/support"
  currentPath="/support"
>
  <section class="py-20 md:py-24">
    <div class="max-w-prose mx-auto px-6 prose-serif">
      <div class="text-center mb-16">
        <Eyebrow>Help</Eyebrow>
        <h1 class="font-serif text-display mt-4">
          <span class="accent-italic">Support.</span>
        </h1>
        <p class="text-lg text-text-secondary mt-6 not-italic font-sans">
          We're here to help.
        </p>
      </div>

      <div class="bg-elevated border border-border rounded-[14px] p-8 my-8 transition-colors hover:border-accent not-italic font-sans">
        <h2 class="font-serif text-xl mb-4">Contact us</h2>
        <p class="text-text-secondary mb-2">Have a question, bug report, or feedback?</p>
        <a href="mailto:support@havennotes.app" class="text-lg font-semibold">support@havennotes.app</a>
      </div>

      <h2>Frequently asked <span class="accent-italic">questions</span></h2>

      <h3>How do I enable sync?</h3>
      <p>Sync requires Haven Pro. Go to Settings → Sync, subscribe to Haven Pro, then enter your sync server URL. Haven never operates sync servers — you bring your own.</p>

      <h3>What servers work with Haven?</h3>
      <p>Any WebDAV-compatible server works. Many users run a simple self-hosted server on a Raspberry Pi, VPS, or NAS.</p>

      <h3>Is my data encrypted?</h3>
      <p>Yes. With Haven Pro, your notes are encrypted with AES-256 on your device before being sent to your sync server. Nobody but you can read them.</p>

      <h3>Can I export my notes?</h3>
      <p>Yes. Go to Settings → Export to download all your notes as markdown files.</p>

      <h3>Does Haven work offline?</h3>
      <p>Haven is offline-first. The app works entirely without an internet connection. Sync (with Pro) runs in the background when you're online.</p>

      <h2>System <span class="accent-italic">Requirements</span></h2>
      <ul>
        <li>iPhone or iPad running iOS 17.0 or later</li>
        <li>Apple Silicon Macs running macOS Sonoma or later (via iPad app)</li>
      </ul>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/src/pages/support.astro
git commit -m "feat(site): add support page in Astro"
```

---

### Task 20: Add vercel.json

**Files:**
- Create: `docs/vercel.json`

- [ ] **Step 1: Write vercel.json**

Write this exact content to `/Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/vercel.json`:

```json
{
  "cleanUrls": true
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add docs/vercel.json
git commit -m "feat(site): add vercel.json for cleanUrls"
```

---

### Task 21: Full local build and verification

**Files:** None — verification only.

- [ ] **Step 1: Clean build**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
rm -rf dist .astro
npm run build
```

Expected: Build completes successfully. Output shows 8 pages generated.

- [ ] **Step 2: Verify dist output**

Run:
```bash
ls /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/dist/
```

Expected: index.html, pricing/, story/, compare/, changelog/, privacy/, terms/, support/, favicon.png, apple-touch-icon.png, robots.txt, sitemap.xml, _astro/.

- [ ] **Step 3: Kill any existing server and start preview**

Run:
```bash
lsof -ti:4444 | xargs kill 2>/dev/null
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
npx astro preview --port 4444 &
sleep 3
```

- [ ] **Step 4: Verify all 8 pages return 200**

Run:
```bash
for page in / pricing story compare changelog privacy terms support; do
  echo -n "$page: "
  curl -sI "http://localhost:4444$page" | head -1
done
```

Expected: All 8 pages return `HTTP/1.1 200 OK`.

- [ ] **Step 5: Take a screenshot of the landing page**

Use the Playwright MCP tool `browser_navigate` to `http://localhost:4444/`, then force reveal visibility via:
```javascript
document.querySelectorAll('.reveal').forEach(el => el.classList.add('visible'));
```

Take a full-page screenshot and save to `smoke-test/astro-landing.png`.

Visually verify:
- Dark background
- Hero has the manifesto text in massive serif
- First 3 lines in cream bold
- Last 3 lines in amber italic
- No phone screenshot, no illustrations
- Nav sticky at top
- Footer at bottom with 3 columns

- [ ] **Step 6: Commit if anything remains**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git status
```

If clean, proceed to Task 22.

---

### Task 22: Delete _legacy folder and push to deploy

**Files:**
- Delete: `docs/_legacy/`

- [ ] **Step 1: Delete _legacy**

Run:
```bash
rm -rf /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs/_legacy
```

- [ ] **Step 2: Commit**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git add -A docs/
git commit -m "chore(site): remove _legacy folder after successful Astro migration"
```

- [ ] **Step 3: Push to GitHub**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven
git push origin main
```

Expected: Push succeeds.

- [ ] **Step 4: Deploy to Vercel**

Run:
```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven/docs
vercel --yes --prod
```

Note: Vercel should auto-detect Astro and use `npm run build` with output dir `dist`. If it doesn't, we'll need to manually configure the project settings in the Vercel dashboard.

Expected: Deployment URL returned.

- [ ] **Step 5: Verify live site**

Run:
```bash
sleep 5
curl -sI https://havennotes.app | head -3
```

Expected: HTTP 200. Manually open https://havennotes.app in a browser and verify the new site loads.

- [ ] **Step 6: Verify all 8 pages are live**

Run:
```bash
for page in / pricing story compare changelog privacy terms support; do
  echo -n "$page: "
  curl -sI "https://havennotes.app$page" | head -1
done
```

Expected: All 8 pages return `HTTP/2 200`.
