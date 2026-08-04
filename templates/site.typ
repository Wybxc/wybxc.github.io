#import "/lib.typ": settings

#let _rss-icon = html.elem("svg", attrs: (
  xmlns: "http://www.w3.org/2000/svg",
  width: "1em",
  height: "1em",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  "stroke-width": "2",
  "stroke-linecap": "round",
  "stroke-linejoin": "round",
))[
  #html.elem("path", attrs: (d: "M4 11a9 9 0 0 1 9 9"))
  #html.elem("path", attrs: (d: "M4 4a16 16 0 0 1 16 16"))
  #html.elem("circle", attrs: (cx: "5", cy: "19", r: "1"))
]

#let site(title: settings.site.title, body) = {
  html.html(lang: settings.site.language)[
    #html.head[
      #html.meta(charset: "utf-8")
      #html.elem("link", attrs: (
        rel: "icon",
        type: "image/svg+xml",
        href: "/favicon.svg",
      ))
      #html.meta(name: "viewport", content: "width=device-width")
      #html.meta(name: "generator", content: "Aster 0.1.0")
      #html.elem("link", attrs: (
        rel: "alternate",
        type: "application/rss+xml",
        title: "Wybxc’s Blog",
        href: settings.site.url + "rss.xml",
      ))
      #html.elem("script", attrs: (
        defer: "",
        src: "https://cdn.jsdelivr.net/npm/mathjax@4/mml-chtml.js",
      ))
      #html.title(title)
      #html.elem("link", attrs: (rel: "css", href: "/styles/site.css"))
    ]
    #html.body[
      #html.main[
        #html.nav[
          #html.ul[
            #html.li(style: "flex: 1;")[]
            #html.li[#link("/")[Home]]
            #html.li[#link("/blog")[Blog]]
            #html.li[#link("/about")[About]]
            #html.li[
              #html.elem("a", attrs: (
                href: "/rss.xml",
                "aria-label": "RSS Feed",
              ))[
                #_rss-icon
              ]
            ]
          ]
        ]
        #body
        #html.footer[
          #html.small[
            © #datetime.today().display("[year]") Jiayi Zhuang. Powered by
            #link("https://github.com/Wybxc/aster")[Aster] and
            #link("https://typst.app/")[Typst]. Licensed under
            #link(
              "https://creativecommons.org/licenses/by-nc/4.0/",
            )[CC BY-NC 4.0]
            #html.elem("img", attrs: (
              src: "https://mirrors.creativecommons.org/presskit/icons/cc.svg",
              alt: "",
              class: "cc",
            ))
            #html.elem("img", attrs: (
              src: "https://mirrors.creativecommons.org/presskit/icons/by.svg",
              alt: "",
              class: "cc",
            ))
            #html.elem("img", attrs: (
              src: "https://mirrors.creativecommons.org/presskit/icons/nc.svg",
              alt: "",
              class: "cc",
            )).
          ]
        ]
      ]
    ]
  ]
}
