#import "@preview/umbra:0.1.1": shadow-path
#import "@preview/fontawesome:0.6.0": *

#set text(font: ("MLMRoman12", "FZNewShuSong-Z10"))

#set par(justify: true, justification-limits: (tracking: (min: -0.01em, max: 0.02em)), first-line-indent: 2em)

// Ornament
#align(center, move(dy: 0.5cm, [
  #box(fill: rgb("#d4af37"), stroke: none, width: 140% - 4cm, height: 1pt, radius: 0pt)

  #move(dy: -17.5pt, box(fill: white, inset: (x: 2pt), text(fill: rgb("#d4af37"), size: 10pt, "❦")))
]))


#figure[
  #box(clip: true, stroke: 0pt, radius: 1.5cm, width: 3cm, height: 3cm, image("images/avatar.jpg", height: 3cm))

  #text(fill: blue.darken(30%), size: 13pt)[*Jiayi Zhuang*]

  PhD Student

  Programming Languages Lab, Peking University

  #link("mailto:wybxc@stu.pku.edu.cn")[
    wybxc (at) stu.pku.edu.cn
  ]

  #text(fill: blue.darken(30%))[
    #link("https://scholar.google.com/citations?user=PG5aLyIAAAAJ")[#fa-google-scholar()]
    #link("https://github.com/Wybxc")[#fa-github()]
  ]
]

#show link: underline

= About Me

Hello! I am Jiayi Zhuang(庄嘉毅).
Welcome to my homepage.

I am a first-year PhD student at Peking University's School of Computer Science, affiliated with the #link("https://pl.cs.pku.edu.cn/en/")[Programming Languages Lab] under the supervision of Prof. #link("https://stonebuddha.github.io")[Di Wang(王迪)] and Prof. #link("https://zhenjiang888.github.io/")[Zhenjiang Hu(胡振江)].

My research focuses on *Program Verification* and *Programming Languages*, with the goal of bridging the gap between theoretical foundations and practical applications.

My journey into programming languages began with a fascination for the interplay between human logic and machine execution.
I view language as fundamental to human intelligence, and programming languages as essential tools that enable effective communication with machines.
I am passionate about enhancing software reliability and efficiency through innovations in programming languages.

I welcome new ideas and collaborations. If my work resonates with you, please feel free to get in touch!

= Publications

== Preprints

#let publication(title: none, url: none, authors: (), pubtype: none, widgets: (), cover: none) = context layout(
  size => {
    let pt-length(len) = measure(line(length: len)).width.to-absolute()
    let cover-width = calc.min(pt-length(12em), size.width * 0.3)
    let cover-height = calc.max(cover-width * 0.67, 35000 / size.width.pt() * 1pt)
    grid(
      columns: (cover-width, 1fr),
      gutter: 10pt,
      align: start + horizon,
      {
        box(
          stroke: 1pt + black.lighten(80%),
          radius: 0.5em,
          width: cover-width,
          height: cover-height,
          clip: true,
          image(cover, width: 100%, height: 100%),
        )
      },
      {
        let title = text(fill: blue.darken(30%), weight: "bold", title)
        link(url, title)
        parbreak()
        let authors = authors.map(author => {
          if author == "Jiayi Zhuang" {
            text(weight: "bold", "Jiayi Zhuang")
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
            h(0.5em, weak: true)
          }
        } else {
          widgets
        }
      },
    )
    h(1em, weak: true)
  },
)

#publication(
  title: [C$star$: Unifying Programming and Verification in C],
  url: "https://arxiv.org/pdf/2504.02246",
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

== Conference Papers

None yet.

I hope I can fill this section soon :)

#v(2cm)
#align(center, text(size: 10pt, fill: black.lighten(40%), emph([
  #set par(spacing: 0.5em)
  This site is powered by #link("https://typst.app")[Typst] and #link("https://mozilla.github.io/pdf.js/")[PDF.js].

  Source code available at #link("https://github.com/Wybxc/wybxc.github.io")[GitHub].

  Updated on #datetime.today().display().
])))
