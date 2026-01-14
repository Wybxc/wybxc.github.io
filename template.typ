#import "@preview/wordometer:0.1.5": total-words, word-count

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

#let image-content-grid(body) = web(body, render: body => html.div(
  class: "image-content-grid",
  body,
))

#let jsx = s => web(
  s,
  render: s => html.elem("script", attrs: ("data-jsx": s)),
  fallback: s => raw(s),
)

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
      web(body, render: body => if block { html.div(body) } else { html.span(body) })
    },
  )
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
  #set page(width: 17cm, height: auto, margin: 1cm)
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
  #show math.equation.where(block: true): it => web(
    it,
    render: it => html.p(
      class: "typst-math typst-math-block",
      role: "math",
      html.frame(it),
    ),
  )
  #show math.equation.where(block: false): it => web(
    it,
    render: it => html.span(
      class: "typst-math typst-math-inline",
      role: "math",
      html.frame(box(height: 3em, inset: (y: 1em), it)),
    ),
  )
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
  #show cite: footnote
  #set bibliography(style: "src/assets/ieee-no-number.csl", title: none)
  #show bibliography: set text(fill: color.rgb(0, 0, 0, 0))

  #show math.equation.where(block: false): set math.frac(style: "horizontal")

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
