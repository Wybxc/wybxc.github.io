#import "/lib.typ": get-collection

#let _blog-posts() = {
  get-collection("blog")
    .filter(entry => entry.id != "index")
    .map(entry => (entry: entry, metadata: entry.metadata()))
    .filter(item => (
      item.metadata.hidden == false and item.metadata.draft == false
    ))
    .sorted(key: item => item.metadata.pubDate)
    .rev()
}

#let _display-date(value) = {
  let (year, month, day) = value.split("-").map(int)
  datetime(year: year, month: month, day: day).display(
    "[month repr:short] [day padding:zero], [year]",
  )
}

#let blog-list() = list(.._blog-posts().map(item => [
  #link("/blog/" + item.entry.id + "/")[#item.metadata.title] #_display-date(
    item.metadata.pubDate,
  )
]))
