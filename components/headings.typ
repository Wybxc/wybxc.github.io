#let heading-link-icon = html.elem("svg", attrs: (
  xmlns: "http://www.w3.org/2000/svg",
  width: "16",
  height: "16",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  "stroke-width": "2",
  "stroke-linecap": "round",
  "stroke-linejoin": "round",
))[
  #html.elem("path", attrs: (
    d: "M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71",
  ))
  #html.elem("path", attrs: (
    d: "M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71",
  ))
]

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
