/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./*.html",
    "./partials/*.html",
    "./editor/**/*.html",
    "./backend/**/*.{js,mjs,py}",
    "./infra/cloudformation/*.yaml",
  ],
  theme: {
    extend: {
      fontFamily: {
        display: ['"Dancing Script"', "cursive"],
        body: ["Adamina", "serif"],
      },
    },
  },
  plugins: [],
};
