import { getCollection } from "astro:content";

export async function getPosts() {
    const posts = await getCollection(
        'posts',
        ({ data }) => import.meta.env.DEV || data.draft !== true,
    );

    return posts.sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
}

export async function getTags() {
    const posts = await getPosts();
    const uniqueTags = [
        ...new Set(posts.map((post) => post.data.tags).flat()),
    ].sort();
    return uniqueTags;
}