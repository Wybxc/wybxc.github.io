import { z, defineCollection } from 'astro:content';
import { rssSchema } from '@astrojs/rss';

export const collections = {
    posts: defineCollection({
        type: 'content',
        schema: rssSchema.merge(z.object({
            title: z.string(),
            pubDate: z.date(),
            draft: z.boolean().optional(),
            tags: z.array(z.string()),
        }))
    }),
}