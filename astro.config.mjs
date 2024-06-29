import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  site: 'https://wybxc.github.io',
  integrations: [],
  markdown: {
    shikiConfig: {
      themes: {
        light: 'catppuccin-latte',
        dark: 'catppuccin-mocha'
      }
    }
  }
});
