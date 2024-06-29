import type { APIRoute } from 'astro';

import rss from '@astrojs/rss';
import { getPosts } from '@/components/posts';

export const GET: APIRoute = async (context) => {
    const posts = await getPosts();
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