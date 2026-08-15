#import "/lib.typ": aster-version, settings
#import "/components/icons.typ": icon, provide-site-icons
#import "/components/theme-toggle.typ": theme-toggle

#let site(title: settings.site.title, body) = {
  let generator = if aster-version == none { "Aster" } else {
    "Aster " + aster-version
  }
  html.html(lang: settings.site.language)[
    #provide-site-icons()
    #html.head[
      #html.meta(charset: "utf-8")
      #html.link(
        rel: "icon",
        type: "image/svg+xml",
        href: "/assets/favicon.svg",
      )
      #html.meta(name: "viewport", content: "width=device-width")
      #html.meta(name: "generator", content: generator)
      #html.link(
        rel: "alternate",
        type: "application/atom+xml",
        title: "Wybxc’s Blog",
        href: settings.site.url + "atom.xml",
      )
      #html.script(
        defer: true,
        src: "https://cdn.jsdelivr.net/npm/mathjax@4/mml-chtml.js",
      )
      #html.title(title)
      #html.link(rel: "stylesheet", href: "/styles/site.css")
    ]
    #html.body[
      #html.main[
        #html.nav[
          #html.ul[
            #html.li(style: "flex: 1;")[]
            #html.li[#link("/")[Home]]
            #html.li[#link("/blog/")[Blog]]
            #html.li[#link("/about/")[About]]
            #html.li[#html.a(href: "/atom.xml", aria-label: "Atom Feed", icon("lucide:rss"))]
            #html.li[#theme-toggle]
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
