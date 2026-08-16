#import "/lib.typ": get-collection-ids, get-entry, route-param
#import "/templates/site.typ": site

#metadata(
  get-collection-ids("blog").filter(id => id != "index").map(slug => (slug: slug)),
) <aster-route>

#let entry = get-entry("blog", route-param("slug", default: ""))

#if entry != none [
  #let metadata = entry.metadata()
  #show: site.with(title: metadata.title)
  #entry.render()
]
