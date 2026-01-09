#import "@preview/wordometer:0.1.5": word-count, total-words

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

#let sidenote(number: none, block: false, body) = {
  if number != none {
    super(str(number))
  }
  aside(
    block: block,
    class: if number != none { ("numbering",) } else { ("",) },
    is-note: true,
    {
      if number != none {
        web(str(number) + ".", render: it => html.span(
          class: "number",
          it,
        ))
      }
      web(body, render: body => html.span(body))
    },
  )
}

#let post(
  title: "",
  desciption: "",
  pubDate: datetime.today(),
  hidden: false,
  toc: true,
  body,
) = [
  #metadata((
    title: title,
    description: desciption,
    pubDate: pubDate.display("[year]-[month]-[day]"),
    hidden: hidden,
  ))<frontmatter>
  #set page(paper: "iso-b5")
  #set text(font: "MLMRoman12")
  #show raw: set text(font: "Monaspace Neon")

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
    let cnt = counter(footnote)
    sidenote(number: cnt.get().first(), it.body)
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
  #set bibliography(style: "chicago-notes", title: none)

  #show math.equation.where(block: false): set math.frac(style: "horizontal")

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
