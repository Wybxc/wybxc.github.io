import rss from '@astrojs/rss';
import type { APIContext } from 'astro';
import { getCollection } from 'astro:content';

export async function GET(context: APIContext) {
    const posts = await getCollection('posts');
    return rss({
        title: 'Wybxc\'s Blog',
        description: 'Wybxc\'s Blog',
        site: context.site ?? '',
        stylesheet: '/rss/pretty-feed-v3.xsl',
        items: posts.map((post) => ({
            title: post.data.title,
            pubDate: post.data.pubDate,
            link: `/posts/${post.slug}/`,
        })),
    });
}