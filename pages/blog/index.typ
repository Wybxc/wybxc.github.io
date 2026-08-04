#import "/lib.typ": get-entry
#import "/templates/site.typ": site

#let entry = get-entry("blog", "index")
#let metadata = entry.metadata()

#show: site.with(title: metadata.title)

#entry.render()
