import { defineCollection } from "astro:content";
import { rssSchema } from "@astrojs/rss";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

const blog = defineCollection({
	loader: glob({ pattern: "**/*.typ", base: "./content" }),
	schema: rssSchema.extend({
		hidden: z.boolean(),
	}),
});

export const collections = { blog };
