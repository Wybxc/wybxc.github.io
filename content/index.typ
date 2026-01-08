#import "../template.typ": *
#import "@preview/sicons:16.0.0": sicon
#show: post.with(
  title: "Hello World",
  date: datetime(year: 2022, month: 1, day: 1),
  hidden: true,
)

#aside(block: true)[
  #center[
    #render(box(
      clip: true,
      stroke: 0pt,
      radius: 1.5cm,
      width: 3cm,
      height: 3cm,
      image(
        "images/avatar.jpg",
        height: 3cm,
      ),
    ))

    *Jiayi Zhuang*

    PhD Student

    Programming Languages Lab, Peking University

    #link("mailto:wybxc@stu.pku.edu.cn")[
      wybxc (at) stu.pku.edu.cn
    ]

    #link("https://scholar.google.com/citations?user=PG5aLyIAAAAJ", sicon(
      slug: "googlescholar",
      size: 1em,
    ))
    #link("https://github.com/Wybxc", invert(sicon(slug: "github", size: 1em)))
  ]
]

Hello! I am Jiayi Zhuang(庄嘉毅).
Welcome to my homepage.

I am a first-year PhD student at Peking University's School of Computer Science, affiliated with the #link("https://pl.cs.pku.edu.cn/en/")[Programming Languages Lab] under the supervision of Prof. #link("https://stonebuddha.github.io")[Di Wang(王迪)] and Prof. #link("https://zhenjiang888.github.io/")[Zhenjiang Hu(胡振江)].

My research focuses on *Program Verification*#footnote[Footnote] and *Programming Languages*#footnote[#lorem(50)], with the goal of bridging the gap between theoretical foundations and practical applications.


My journey into programming languages began with a fascination for the interplay between human logic and machine execution.
I view language as fundamental to human intelligence, and programming languages as essential tools that enable effective communication with machines.
I am passionate about enhancing software reliability and efficiency through innovations in programming languages.

I welcome new ideas and collaborations. If my work resonates with you, please feel free to get in touch!

== Recent Blog Posts

#jsx("import BlogList from '../src/components/BlogList.astro'")
#jsx("<BlogList />")

== Publications

#let publication(
  title: none,
  url: none,
  conference: none,
  authors: (),
  pubtype: none,
  widgets: (),
  cover: none,
) = {
  html.div(
    class: "compact image-content-grid",
    {
      darken(render(box(width: 12.35em, height: 10.2em, {
        place(dx: 0.25em, dy: 0.1em, box(
          stroke: 1pt + black.lighten(80%),
          radius: 0.5em,
          width: 12em,
          height: 10em,
          clip: true,
          image(cover, width: 100%, height: 100%),
        ))
        move(dy: 0.6em, box(
          fill: blue.darken(20%),
          inset: 0.4em,
          radius: 0.25em,
          text(fill: white, size: 0.8em, weight: "bold", conference),
        ))
      })))
      html.div({
        link(url, strong(title))
        parbreak()
        let authors = authors.map(author => {
          if author == "Jiayi Zhuang" {
            strong[Jiayi Zhuang]
          } else {
            author
          }
        })
        authors.join(", ")
        parbreak()
        emph(pubtype)
        parbreak()
        if type(widgets) == array {
          for widget in widgets {
            widget
            " "
          }
        } else {
          widgets
        }
      })
    },
  )
}

#publication(
  title: [C$star$: Unifying Programming and Verification in C],
  url: "https://arxiv.org/pdf/2504.02246",
  conference: [Preprint],
  cover: "images/cstar1.png",
  authors: (
    "Yiyuan Cao",
    "Jiayi Zhuang",
    "Houjin Chen",
    "Jinkai Fan",
    "Wenbo Xu",
    "Zhiyi Wang",
    "Di Wang",
    "Qinxiang Cao",
    "Yingfei Xiong",
    "Haiyan Zhao",
    "Zhenjiang Hu",
  ),
  pubtype: "arXiv preprint arXiv:2504.02246",
  widgets: (
    [#link("https://arxiv.org/pdf/2504.02246")[PDF]],
    [#link("https://arxiv.org/bibtex/2504.02246")[BibTeX]],
  ),
)

#publication(
  title: [Breathing New Life into Existing Visualizations: A Natural Language-Driven Manipulation Framework],
  url: "https://arxiv.org/pdf/2404.06039",
  conference: [Preprint],
  cover: "images/breathing1.png",
  authors: (
    "Can Liu",
    "Jiacheng Yu",
    "Yuhan Guo",
    "Jiayi Zhuang",
    "Yuchu Luo",
    "Xiaoru Yuan",
  ),
  pubtype: "arXiv preprint arXiv:2404.06039",
  widgets: (
    [#link("https://arxiv.org/pdf/2404.06039")[PDF]],
    [#link("https://arxiv.org/bibtex/2404.06039")[BibTeX]],
  ),
)
