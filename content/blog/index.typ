#import "../../template.typ": *
#show: post.with(
  title: "Blog Posts",
  date: datetime.today(),
  hidden: true,
)

= Blog Posts

#jsx("import BlogList from '../../src/components/BlogList.astro'")
#jsx("<BlogList />")
