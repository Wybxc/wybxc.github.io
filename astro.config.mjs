// @ts-check
import { defineConfig, fontProviders } from "astro/config";
import { typst } from "astro-typst";
import { visit } from "unist-util-visit";
// @ts-expect-error
import { rehypeTransformJsxInTypst } from "./node_modules/typstx/lib/core.js";

// https://astro.build/config
export default defineConfig({
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
			() => (tree) => {
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
