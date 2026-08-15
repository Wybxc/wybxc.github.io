#import "/components/icons.typ": icon

#let heading-link-icon = icon("lucide:link", size: "16")

#let anchored-heading(it) = {
  let tag = if it.level < 6 { "h" + str(it.level + 1) } else { "div" }
  let attrs = if it.level < 6 {
    (:)
  } else {
    (role: "heading", "aria-level": str(it.level + 1))
  }
  let anchor = html.span(class: "heading-anchor", link(it.location(), [
    #heading-link-icon
    #html.span(class: "visually-hidden", [Link to this section])
  ]))
  html.elem(tag, attrs: attrs)[#anchor#it.body]
}

#let citation-footnote(it) = {
  show link: link => {
    if type(link.dest) == str {
      html.elem("a", attrs: (
        href: link.dest,
        target: "_blank",
      ))[#link.body]
    } else {
      html.elem("span")[#link.body]
    }
  }
  footnote(it)
}
