#import "/lib.typ": get-entry
#import "/components/blog.typ": blog-list
#import "/templates/site.typ": site

#show: site.with(title: "Blog Posts")

= Blog Posts

#blog-list()
