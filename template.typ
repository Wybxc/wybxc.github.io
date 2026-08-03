#import "@preview/wordometer:0.1.5": word-count
#import "/lib/aster/content.typ": get-collection

#let target = dictionary(std).at("target", default: () => "paged")

#let web(body, render: body => body, fallback: body => body) = context {
  if target() == "html" {
    render(body)
  } else {
    fallback(body)
  }
}

#let render(body) = web(body, render: body => html.frame(body))

#let center(body) = web(
  body,
  render: body => html.div(style: "text-align: center", body),
  fallback: body => align(std.center, body),
)

#let invert(body) = web(body, render: body => html.span(
  class: "typst-invert",
  body,
))

#let darken(body) = web(body, render: body => html.span(
  class: "typst-darken",
  body,
))

#let div(body, ..args) = web(body, render: body => html.div(body, ..args))

#let compact(body) = web(body, render: body => html.span(
  class: "compact",
  body,
))

#let fullwidth(body) = web(body, render: body => html.div(
  class: "fullwidth",
  body,
))

#let image-content-grid(body) = web(body, render: body => html.div(
  class: "image-content-grid",
  body,
))

#let aside(block: false, is-note: false, class: (), body) = web(
  body,
  render: body => {
    let class = class + if is-note { ("note",) } else { ("",) }
    if block {
      html.aside(
        class: class,
        body,
      )
    } else {
      html.span(
        role: "note",
        class: class,
        body,
      )
    }
  },
  fallback: body => box(stroke: 1pt + gray, inset: 0.5em, body),
)

#let sidenote(block: false, body) = context {
  let cnt = counter("sidenote")
  cnt.step()
  super(cnt.display("1"))
  aside(
    block: block,
    class: ("numbering",),
    is-note: true,
    {
      web(cnt.display("1."), render: it => html.span(
        class: "number",
        it,
      ))
      web(body, render: body => if block { html.div(body) } else {
        html.span(body)
      })
    },
  )
}

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

#let post(
  body,
  title: "",
  description: "",
  pubDate: datetime.today(),
  hidden: false,
  draft: false,
  toc: true,
  ..args,
) = [
  #metadata((
    title: title,
    description: description,
    pubDate: pubDate.display("[year]-[month]-[day]"),
    hidden: hidden,
    draft: draft,
    ..args.named(),
  ))<frontmatter>
  #set text(font: "MLMRoman12")
  #show raw: set text(font: "Monaspace Neon", features: (
    "calt",
    "liga",
    "ss01",
    "ss02",
    "ss03",
    "ss05",
    "ss07",
    "ss09",
  ))

  #show link: it => web(
    it,
    fallback: underline,
  )
  #show heading: anchored-heading
  #show footnote: it => {
    sidenote(it.body)
  }
  #show footnote.entry: none
  #show quote.where(block: true): it => web(
    it,
    render: it => html.blockquote({
      it.body
      if it.attribution != none {
        html.cite([-- #it.attribution])
      }
    }),
  )
  #set cite(form: "full")
  #show cite: citation-footnote
  #set bibliography(style: "/assets/ieee-no-number.csl", title: none)
  #show bibliography: set text(fill: color.rgb(0, 0, 0, 0))

  #show math.equation.where(block: false): set math.frac(style: "horizontal")
  #show html.elem.where(tag: "mtable"): set html.elem(attrs: (
    columnalign: "right left",
  ))

  #counter("sidenote").update(1)
  #web(
    {
      if toc {
        aside(block: true, [
          #pubDate.display("[month repr:short] [day], [year]")\
          #context {
            let time = calc.round(state("wordometer").final().words / 150)
            if time <= 1 {
              "1 min read"
            } else {
              str(time) + " mins read"
            }
          }

          *Table of Contents*
          #outline(title: none)
        ])
      }
      word-count(body)
    },
    render: body => html.article(body),
  )
]

#let _blog-posts() = {
  get-collection("blog")
    .filter(entry => entry.id != "index")
    .map(entry => (entry: entry, metadata: entry.metadata()))
    .filter(item => item.metadata.hidden == false and item.metadata.draft == false)
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
  #link("/blog/" + item.entry.id)[#item.metadata.title] #_display-date(item.metadata.pubDate)
]))
