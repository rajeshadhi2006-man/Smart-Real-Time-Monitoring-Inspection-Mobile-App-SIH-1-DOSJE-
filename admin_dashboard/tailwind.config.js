/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        govNavy: '#0A192F',
        govBlue: '#1D4ED8',
        govLight: '#F8FAFC',
        govBorder: '#E2E8F0',
      },
    },
  },
  plugins: [],
};
