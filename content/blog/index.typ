#import "../../template.typ": *
#show: post.with(
  title: "Blog Posts",
  hidden: true,
  toc: false,
)

= Blog Posts

#jsx("import BlogList from '../../src/components/BlogList.astro'")
#jsx("<BlogList />")
