// @ts-check
import { defineConfig, fontProviders } from "astro/config";
import { typst } from "astro-typst";
import { visit } from "unist-util-visit";
// @ts-expect-error
import { rehypeTransformJsxInTypst } from "./node_modules/typstx/lib/core.js";
import rehypeSlug from "rehype-slug";
import rehypeAutolinkHeadings from "rehype-autolink-headings";

/** @type {(script: string) => import("hast").Element} */
const jsx = (script) => ({
  type: "element",
  tagName: "script",
  properties: { "data-jsx": script },
  children: [],
});

// https://astro.build/config
export default defineConfig({
  site: "https://blog.wybxc.cc",
  integrations: [
    typst({
      target: "html",
      htmlMode: "hast",
    }),
  ],
  experimental: {
    fonts: [
      {
        provider: fontProviders.fontsource(),
        name: "Monaspace Neon",
        cssVariable: "--font-monaspace-neon",
        fallbacks: ["Georgia", "Times", "serif"],
      },
      {
        provider: "local",
        name: "MLModern",
        cssVariable: "--font-mlmodern",
        variants: [
          {
            weight: 400,
            style: "normal",
            src: ["./src/assets/fonts/mlmodern-regular.woff2"],
          },
          {
            weight: 400,
            style: "italic",
            src: ["./src/assets/fonts/mlmodern-italic.woff2"],
          },
          {
            weight: 700,
            style: "normal",
            src: ["./src/assets/fonts/mlmodern-bold.woff2"],
          },
        ],
        fallbacks: ["monaspace"],
      },
    ],
  },
  image: {
    remotePatterns: [
      {
        protocol: "data",
      },
    ],
  },
  markdown: {
    rehypePlugins: [
      () => (tree) => {
        visit(tree, { tagName: "body" }, (node) => {
          node.children.splice(
            0,
            0,
            jsx(`import { Image as AstroImage } from "astro:assets";`),
            jsx(`import { Link } from "@lucide/astro";`),
          );
        });
      },
      () => (tree) => {
        visit(tree, { tagName: "img" }, (node) => {
          const src = node.properties.src?.toString();
          if (src && src.startsWith("data:") && src.length >= 100) {
            const format = /data:image\/([a-zA-Z0-9]+)/.exec(src)?.[1] || "svg";
            node.tagName = "script";
            node.properties = {
              "data-jsx": `<AstroImage src="${src}" alt="" format="${format}" inferSize />`,
            };
          }
        });
      },
      rehypeSlug,
      [
        rehypeAutolinkHeadings,
        {
          content: () => jsx(`<Link size={16} />`),
          properties: {
            ariaHidden: true,
            tabIndex: -1,
            className: "heading-anchor",
          },
        },
      ],
      () => rehypeTransformJsxInTypst(),
      () => (tree) => {
        // post process: remove the link inside citation
        visit(tree, { tagName: "a" }, (node) => {
          if (node.properties.role === "doc-biblioref") {
            node.tagName = "span";
            // make DOI links open in new tab
            visit(node, { tagName: "a" }, (node) => {
              node.properties.target = "_blank";
            });
          }
        });
      },
    ],
  },
});
