// @ts-check

import { defineConfig, fontProviders } from "astro/config";
import { typst } from "astro-typst";
import { toText } from "hast-util-to-text";
import rehypeAutolinkHeadings from "rehype-autolink-headings";
import rehypeSlug from "rehype-slug";
import {
	bundledLanguages,
	bundledThemes,
	getSingletonHighlighter,
} from "shiki";
import { visit } from "unist-util-visit";
// @ts-expect-error
import { rehypeTransformJsxInTypst } from "./node_modules/typstx/lib/core.js";

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
			{
				provider: "local",
				name: "NewComputerModernMath",
				cssVariable: "--font-new-computer-modern-math",
				variants: [
					{
						src: ["./src/assets/fonts/NewCMMath-Book.woff2"],
					},
				],
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
			() => async (tree) => {
				// post process: re-highlight code with shiki
				const highlighter = await getSingletonHighlighter({
					themes: Object.keys(bundledThemes),
					langs: Object.keys(bundledLanguages),
				});
				visit(tree, { tagName: "code" }, (node, idx, parent) => {
					const lang = node.properties["data-lang"];
					if (typeof lang === "string" && parent && idx !== undefined) {
						const pre = highlighter.codeToHast(
							toText(node, { whitespace: "pre" }),
							{
								lang,
								themes: {
									light: "github-light",
									dark: "github-dark-dimmed",
								},
							},
						).children[0];
						if (pre.type === "element") {
							parent.children[idx] = pre.children[0];
						}
					}
				});
			},
		],
	},
});
