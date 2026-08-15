#import "/lib.typ": get-entry
#import "/components/blog.typ": blog-list
#import "/templates/post.typ": post

#show: post.with(title: "Blog Posts", toc: false)

= Blog Posts

#blog-list()
