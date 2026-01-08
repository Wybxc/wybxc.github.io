// @ts-check
import { defineConfig } from "astro/config";
import { typst } from "astro-typst";
import rehypeSvgo from "rehype-svgo";
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
          visit(tree, "element", (node) => {
            if (
              node.tagName === "a" &&
              node.properties.role === "doc-biblioref"
            ) {
              node.tagName = "span";
              // make DOI links open in new tab
              visit(node, "element", (node) => {
                if (node.tagName === "a") {
                  node.properties.target = "_blank";
                }
              });
            }
          });
        },
      rehypeSvgo,
    ],
  },
});
