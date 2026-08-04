#import "@preview/exemel:0.1.0": to-xml
#import "/lib.typ": get-collection

#let rss-date(value) = {
  let (year, month, day) = value.split("-").map(int)
  datetime(year: year, month: month, day: day).display(
    "[weekday repr:short], [day padding:zero] [month repr:short] [year] 00:00:00 GMT",
  )
}

#let entries = {
  get-collection("blog")
    .filter(entry => entry.id != "index")
    .map(entry => (entry: entry, metadata: entry.metadata()))
    .filter(item => item.metadata.hidden == false and item.metadata.draft == false)
}

#let items = entries.map(item => {
  let metadata = item.metadata
  let url = sys.inputs.site.url + "blog/" + item.entry.id + "/"
  (
    tag: "item",
    children: (
      (tag: "title", children: (metadata.title,)),
      (tag: "link", children: (url,)),
      (tag: "guid", attrs: ("isPermaLink": "true"), children: (url,)),
      (tag: "pubDate", children: (rss-date(metadata.pubDate),)),
      (tag: "content:encoded", children: (
        read("/content/blog/" + item.entry.id + ".typ"),
      )),
    ),
  )
})

#let feed = (
  tag: "rss",
  attrs: (
    version: "2.0",
    "xmlns:content": "http://purl.org/rss/1.0/modules/content/",
  ),
  children: (
    (
      tag: "channel",
      children: (
        (tag: "title", children: (sys.inputs.site.title,)),
        (tag: "description", children: (sys.inputs.site.description,)),
        (tag: "link", children: (sys.inputs.site.url,)),
        ..items,
      ),
    ),
  ),
)

#metadata(to-xml(feed, pretty: true)) <endpoint>
