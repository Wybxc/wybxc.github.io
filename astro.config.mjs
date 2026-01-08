// @ts-check
import { defineConfig } from "astro/config";
import { typst } from "astro-typst";
import { visit } from "unist-util-visit";
// @ts-ignore
import { rehypeTransformJsxInTypst } from "./node_modules/typstx/lib/core.js";

// https://astro.build/config
export default defineConfig({
  integrations: [
    typst({
      target: "html",
      htmlMode: "hast",
    }),
  ],
  image: {
    remotePatterns: [
      {
        protocol: "data",
      }
    ]
  },
  markdown: {
    rehypePlugins: [
      () =>
        function (tree) {
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
      () =>
        function (tree) {
          visit(tree, { tagName: "body" }, (node) => {
            node.children.splice(0, 0, {
              type: "element",
              tagName: "script",
              properties: {
                "data-jsx": `import { Image as AstroImage } from "astro:assets";`,
              },
              children: [],
            });
          });
          visit(tree, { tagName: "img" }, (node) => {
            if (node.properties.class === "typst-frame") {
              const src = node.properties.src;
              node.tagName = "script";
              node.properties = {
                "data-jsx": `<AstroImage src="${src}" alt="" format="svg" inferSize />`,
              };
            }
          });
        },
      () => rehypeTransformJsxInTypst(),
    ],
  },
});
