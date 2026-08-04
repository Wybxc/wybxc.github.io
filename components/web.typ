#import "/lib.typ": target

#let web(body, render: body => body, fallback: body => body) = context {
  if target() == "html" {
    render(body)
  } else {
    fallback(body)
  }
}

#let render(body) = web(body, render: body => box(html.frame(body)))

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
