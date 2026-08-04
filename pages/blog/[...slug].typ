#import "/lib.typ": get-collection-ids, get-entry
#import "/templates/site.typ": site

#metadata(
  get-collection-ids("blog")
    .filter(id => id != "index")
    .map(slug => (slug: slug))
) <route>

#let slug = sys.inputs.at("slug", default: "")
#let entry = get-entry("blog", slug)

#if entry != none [
  #let metadata = entry.metadata()
  #show: site.with(title: metadata.title)
  #entry.render()
]
