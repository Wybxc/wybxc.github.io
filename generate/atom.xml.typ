#import "@preview/exemel:0.1.0": to-xml
#import "/lib.typ": get-collection, settings

#let atom-date(value) = value + "T00:00:00Z"

#let entries = {
  get-collection("blog")
    .filter(entry => entry.id != "index")
    .map(entry => (entry: entry, metadata: entry.metadata()))
    .filter(item => item.metadata.hidden == false and item.metadata.draft == false)
    .sorted(key: item => item.metadata.pubDate)
    .rev()
}

#let feed-entries = entries.map(item => {
  let metadata = item.metadata
  let path = "/blog/" + item.entry.id + "/"
  let page = sys.inputs._aster.site.pages.find(page => page.path == path)
  let url = settings.site.url + path.trim("/") + "/"
  let content = page.content.html
    .replace("=\"../../", "=\"" + settings.site.url)
    .replace("href=\"#", "href=\"" + url + "#")
  (
    tag: "entry",
    children: (
      (tag: "title", children: (metadata.title,)),
      (tag: "id", children: (url,)),
      (tag: "link", attrs: (href: url)),
      (tag: "published", children: (atom-date(metadata.pubDate),)),
      (tag: "updated", children: (atom-date(metadata.pubDate),)),
      ..if metadata.description == "" { () } else {
        ((tag: "summary", children: (metadata.description,)),)
      },
      (tag: "content", attrs: (type: "html", "xml:base": url), children: (content,)),
    ),
  )
})

#let feed = (
  tag: "feed",
  attrs: (xmlns: "http://www.w3.org/2005/Atom", "xml:lang": settings.site.language),
  children: (
    (tag: "title", children: (settings.site.title,)),
    (tag: "subtitle", children: (settings.site.description,)),
    (tag: "id", children: (settings.site.url,)),
    (tag: "link", attrs: (href: settings.site.url)),
    (tag: "link", attrs: (
      rel: "self",
      type: "application/atom+xml",
      href: settings.site.url + "atom.xml",
    )),
    (tag: "updated", children: (atom-date(entries.first().metadata.pubDate),)),
    (tag: "author", children: ((tag: "name", children: (settings.site.author,)),)),
    ..feed-entries,
  ),
)

#metadata(to-xml(feed, pretty: true)) <aster-output>
