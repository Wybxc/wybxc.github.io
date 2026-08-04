#import "/components/blog.typ": blog-list
#import "/templates/post.typ": post
#show: post.with(
  title: "Blog Posts",
  hidden: true,
  toc: false,
)

= Blog Posts

#blog-list()
