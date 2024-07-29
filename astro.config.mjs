import { defineConfig } from 'astro/config';
import sitemap from "@astrojs/sitemap";

import mdx from "@astrojs/mdx";
import remarkToc from 'remark-toc';

// https://astro.build/config
export default defineConfig({
  site: 'https://wybxc.github.io',
  prefetch: true,
  integrations: [sitemap(), mdx()],
  markdown: {
    shikiConfig: {
      themes: {
        light: 'catppuccin-latte',
        dark: 'catppuccin-mocha'
      }
    },
    remarkRehype: {
      footnoteLabel: 'Notes',
    },
    remarkPlugins: [remarkToc],
  }
});