#let target = dictionary(std).at("target", default: () => "paged")

#let fallback(body, render: body => body, default: body => body) = context {
  if target() == "html" {
    render(body)
  } else {
    default(body)
  }
}

#let render(body) = fallback(body, render: body => html.frame(body))

#let center(body) = fallback(
  body,
  render: body => html.div(style: "text-align: center", body),
  default: body => align(std.center, body),
)

#let invert(body) = fallback(body, render: body => html.span(
  class: "typst-invert",
  body,
))

#let darken(body) = fallback(body, render: body => html.span(
  class: "typst-darken",
  body,
))

#let div(body, ..args) = fallback(body, render: body => html.div(body, ..args))

#let compact(body) = fallback(body, render: body => html.span(
  class: "compact",
  body,
))

#let image-content-grid(body) = fallback(body, render: body => html.div(
  class: "image-content-grid",
  body,
))

#let jsx = s => fallback(
  s,
  render: s => html.elem("script", attrs: ("data-jsx": s)),
  default: s => text(s),
)

#let aside(block: false, is-note: false, class: (), body) = fallback(
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
        fallback(str(number) + ".", render: it => html.span(
          class: "number",
          it,
        ))
      }
      body
    },
  )
}

#let post(
  title: "",
  desciption: "",
  date: datetime.today(),
  hidden: false,
  body,
) = [
  #metadata((
    title: title,
    description: desciption,
    date: date.display("[year]-[month]-[day]"),
    hidden: hidden,
  ))<frontmatter>
  #set page(height: auto)
  #set text(font: "MLMRoman12")
  #show raw: set text(font: "Monaspace Neon")

  #show math.equation.where(block: true): it => fallback(
    it,
    render: it => html.p(
      class: "typst-math typst-math-block",
      role: "math",
      html.frame(it),
    ),
  )
  #show math.equation.where(block: false): it => fallback(
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
  #show quote.where(block: true): it => fallback(
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
  #set bibliography(style: "chicago-notes")

  #show math.equation.where(block: false): set math.frac(style: "horizontal")

  #fallback(body, render: body => html.article(body))
]
