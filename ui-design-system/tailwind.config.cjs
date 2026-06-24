const tokens = require('./design-tokens.json');

module.exports = {
  content: ['index.html', './src/**/*.{ts,tsx,js,jsx}'],
  theme: {
    extend: {
      colors: {
        primary: tokens.colors.primary,
        muted: tokens.colors.muted,
        surface: tokens.colors.surface,
        bg: tokens.colors.bg
      },
      borderRadius: {
        md: tokens.radius.md
      }
    }
  },
  plugins: []
};
