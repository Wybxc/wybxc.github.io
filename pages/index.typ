#import "/lib/aster/content.typ": get-entry
#import "/site.typ": site

#let entry = get-entry("site", "index")
#let metadata = entry.metadata()

#show: site.with(title: metadata.title)

#entry.render()
