#import "@preview/wordometer:0.1.5": word-count
#import "/components/headings.typ": anchored-heading, citation-footnote
#import "/components/web.typ": aside, sidenote, web
#import "site.typ": site

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
  #show: site.with(title: title)
  #metadata((
    title: title,
    description: description,
    pubDate: pubDate.display("[year]-[month]-[day]"),
    hidden: hidden,
    draft: draft,
    ..args.named(),
  )) <aster-frontmatter>
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
    render: body => [#html.article(body) <aster-content>],
  )
]
