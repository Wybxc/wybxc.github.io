import { getCollection } from "astro:content";
import rss, { type RSSFeedItem } from "@astrojs/rss";
import type { APIRoute } from "astro";

export const GET: APIRoute = async (context) => {
	const posts = await getCollection("blog", (post) => !post.data.hidden && !post.data.draft);
	return rss({
		title: "Jiayi Zhuang’s Blog",
		description: "Jiayi Zhuang’s personal blog and academic portfolio.",
		site: context.site ?? "https://example.com",
		items: posts.map(
			(post) =>
				({
					...post,
					link: `/${post.id}`,
					content: post.body,
				}) satisfies RSSFeedItem,
		),
	});
};
