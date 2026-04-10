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
