// @ts-check
import { defineConfig } from "astro/config";
import { typst } from "astro-typst";
import { visit } from "unist-util-visit";

// https://astro.build/config
export default defineConfig({
  integrations: [
    typst({
      target: "html",
      htmlMode: "hast",
    }),
  ],
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
    ],
  },
});
