// @ts-check
import { defineConfig } from "astro/config";
import { typst } from "astro-typst";

// https://astro.build/config
export default defineConfig({
	integrations: [
		typst({
			target: "html",
			htmlMode: "hast",
		}),
	],
});
