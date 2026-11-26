import { defineConfig } from 'astro/config';

// Tailwind 3 runs through postcss.config.mjs (Astro 7 has no @astrojs/tailwind).
export default defineConfig({
  site: 'https://havennotes.app',
  // Astro 7 defaults to 'jsx' whitespace rules; `true` keeps the Astro 5 output.
  compressHTML: true,
  build: {
    format: 'directory',
  },
  vite: {
    build: {
      // Vite 8 targets Safari 16.4+ by default and would rewrite media queries
      // into range syntax older browsers skip. Keep the Vite 6 browser floor.
      cssTarget: ['chrome87', 'edge88', 'firefox78', 'safari14'],
    },
  },
});
