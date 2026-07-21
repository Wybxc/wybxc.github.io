#import "../../template.typ": *
#show: post.with(
  title: "The Story of Slipst",
  pubDate: datetime(year: 2026, month: 3, day: 30),
  draft: true,
)

= The Story of Slipst

It's been more than two months since I built #link("https://typst.app/universe/package/slipst")[slipst], and last week I gave my first talk using slipst as the presentation tool. Preparing for that talk prompted several improvements to slipst, which have been shipped in the latest 0.3 release. With that milestone, now seems like a good time to share the story of slipst, how it came to be, and some of the interesting tricks it uses under the hood.

If you're not familiar with it, slipst is a tool for a new paradigm for presentations in typst, inspired by #link("https://slipshow.org/")[slipshow]. It structures presentations as a series of vertical "slips" that scroll from top to bottom, rather than as fixed-size slides. This makes for more dynamic and flexible presentations.

== The first spark of slipst

One day, while browsing GitHub for interesting projects, I stumbled upon a web-based presentation tool called #link("https://slipshow.org/")[slipshow].
What set it apart from traditional slide-based tools was its vertical scrolling format, a design that felt both intuitive and refreshing.
The project used a Markdown dialect for content authoring and sported a clean, minimal aesthetic.
I immediately found myself wondering: could I build something like this in typst?
Since 0.13, typst has had the capability to export to HTML, and its powerful scripting features seemed like a perfect fit for implementing a tool like this.
That question was the spark that led to slipst.

I quickly drafted a prototype of what a document of slipst shows might look like in typst, mimicking the structure of slipshow's Markdown format.

```typ
#import "slipst.typ": *
#show: slipst()

= A Title
The first slip. <anchor1>

#pause

The second slip. #up(<anchor1>)
```

The concept was simple enough; the real question was implementation.

The architecture resolved into a clean pipeline:
1. Target a single HTML file using Typst’s native export capabilities, supplemented by custom JavaScript for interactivity.
2. On the content side, the document is divided into discrete “slips” using `#pause` delimiters.
3. Under the hood, the slipst library slices the document at these markers, renders each segment as an isolated HTML element#sidenote[
  I use the word "render", because each slip is wrapped in `#html.frame`, which
], and bundles the necessary CSS and JS for styling and interactivity.

The first two steps were straightforward enough; the real challenge lay in the third, specifically, how to slice the document into discrete segments.
I knew that typst presentation tools like #link("https://typst.app/universe/package/polylux")[polylux] and #link("https://typst.app/universe/package/touying")[touying] already implemented heading-based slide splitting, so I started reading through their source code to see how they approached the problem.

// content: the undocumented elements of typst

// coodinate system

// bun bundler; release process

#fullwidth[```typ
#let pause = metadata((kind: "slipst-pause"))

#let _should_strip(item) = {
  type(item) == content and (item.func() == parbreak or item == [ ])
}

#let _strip(segment) = {
  let _ = while _should_strip(segment.first(default: none)) {
    segment.remove(0)
  }
  let _ = while _should_strip(segment.last(default: none)) {
    segment.pop()
  }
  segment
}

#let _cut(content) = {
  let (segments, remainder) = content.children.fold((segments: (), remainder: ()), (acc, item) => {
    let (segments, remainder) = acc
    if item.func() == metadata {
      (segments + (remainder,), ())
    } else if item.func() == heading and item.at("depth", default: 100) <= 2 {
      (segments + (remainder,), (item,))
    } else {
      (segments, remainder + (item,))
    }
  })
  let segments = segments + (remainder,)
  let segments = segments.map(_strip).filter(segment => segment.len() > 0)
  segments
}

#let slipst(body, width: 16cm) = {
  if dictionary(std).at("html", default: none) == none {
    panic("Slipst is only available in HTML export mode.")
  }
  let segments = _cut(body)
  html.html({
    html.meta(charset: "utf-8")
    html.head({
      html.link(rel: "stylesheet", href: "https://esm.sh/normalize.css@8.0.1/normalize.css")
      html.style(read("slipst.css"))
      html.script(read("slipst.js"), type: "module")
    })
    html.main(html.div(
      id: "container",
      {
        for (i, slip) in segments.enumerate() {
          html.elem(
            "div",
            attrs: (class: "slip", data-slip: str(i + 1)),
            html.frame(block(width: width, slip.join())),
          )
        }
      },
    ))
  })
}
```]
