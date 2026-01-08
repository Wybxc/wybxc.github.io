#let render(body) = html.frame(body)

#let center(body) = html.div(style: "text-align: center", body)

#let invert(body) = html.span(class: "typst-invert", body)

#let jsx = s => html.elem("script", attrs: ("data-jsx": s))

#let aside(block: false, is-note: false, class: (), body) = {
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
}

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
        html.span(class: "number", str(number) + ".")
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

  #jsx("import Image from '../src/components/Image.astro'")
  #let img(src, alt: "", class: "", style: "") = {
    jsx(
      "<Image src={'"
        + src
        + "'} alt={'"
        + alt
        + "'} class={'"
        + class.replace("\n", "")
        + "'} style={'"
        + style.replace("\n", "")
        + "'}/>",
    )
  }

  #show math.equation.where(block: true): it => html.p(
    class: "typst-math",
    role: "math",
    html.frame(it),
  )
  #show math.equation.where(block: false): it => html.span(
    class: "typst-math typst-math-inline",
    role: "math",
    html.frame(box(height: 3em, inset: (y: 1em), it)),
  )
  #show footnote: it => {
    let cnt = counter(footnote)
    sidenote(number: cnt.get().first(), it.body)
  }
  #show footnote.entry: none
  #show image: it => context {
    let realtive-to-css = it => {
      let length = str(it.length.to-absolute().pt()) + "px"
      let ratio = str(it.ratio / 1%) + "%"
      if ratio == "0%" {
        length
      } else {
        "calc(" + ratio + " + " + length + ")"
      }
    }
    let width = if it.width == auto {
      ""
    } else {
      "width: " + realtive-to-css(it.width) + ";"
    }
    let height = if it.height == auto {
      ""
    } else {
      "height: " + realtive-to-css(it.height) + ";"
    }
    let fit = (
      cover: "object-fit: cover;",
      contain: "object-fit: contain;",
      stretch: "object-fit: fill;",
    ).at(it.fit)

    if target() == "html" and type(it.source) == str {
      img(
        it.source,
        alt: it.alt,
        style: width + height + fit,
      )
    } else {
      it
    }
  }
  #show quote.where(block: true): it => html.blockquote({
    it.body
    if it.attribution != none {
      html.cite([-- #it.attribution])
    }
  })
  #set cite(form: "full")
  #show cite: footnote
  #set bibliography(style: "chicago-notes")

  #show math.equation.where(block: false): set math.frac(style: "horizontal")

  #html.main(html.article(body))
]
