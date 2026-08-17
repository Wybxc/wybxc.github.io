#import "/templates/post.typ": post
#show: post.with(
  title: "Mitigating My Site to a Typst-Native Static Site Generator (a.k.a. a Preview of Aster)",
  pubDate: datetime(year: 2026, month: 8, day: 17),
  draft: false,
)

= Mitigating My Site to a Typst-Native Static Site Generator (a.k.a. a Preview of Aster)

In early 2026, when I was preparing to rebuild my personal website, I wanted to find a static site generator that could: 1) use Typst to write content#footnote[MDX is actually comparable to Typst in expressiveness, but I prefer Typst’s math formula syntax.], and 2) be highly customizable and not rely on fixed templates.
The only choice at that time was #link("https://astro.build")[Astro], with the #link("https://github.com/OverflowCat/astro-typst")[astro-typst] plugin, which uses #link("https://github.com/Myriad-Dreamin/typst.ts")[typst.ts] to compile Typst files to HTML.

This is a highly customizable solution, though part of the customization is done by hacking.
To give Typst files the same flexibility as MDX, astro-typst uses a fixed pipeline: it first compiles Typst files to HTML, then applies an internal rehype plugin named `rehypeTransformJsxInTypst` to handle MDX-style dynamic components in Typst.
This is a reasonable default for an Astro integration, but it becomes troublesome if you want to customize it.
For example, images inserted in Typst files are compiled to HTML with inline base64 data, which is not ideal for a website with many images.
To extract images from the HTML, I had to use several rehype plugins#footnote[You can see the code at #link("https://github.com/Wybxc/wybxc.github.io/blob/b065cc83e59c115e78bf49a065a0c94c8c7db1d3/astro.config.mjs#L87")[here].] to:
1. Replace img tags containing base64 data with Astro's Image component,
2. Insert `import { Image } from "astro:assets";` at the beginning of the file, and
3. Apply `rehypeTransformJsxInTypst` again to handle the newly added dynamic components, because user-added rehype plugins run after astro-typst's internal pipeline.

There are also other issues, such as the incremental feature of the Typst compiler cannot be utilized in the pipeline, which causes a significant increase in build time, and in `npm dev` mode, header size limitations of node.js can cause pictures to fail to load, etc.
These issues are not insurmountable, but they are annoying and a waste of time.

That's why I decided to create a Typst-native static site generator, which I named Aster#footnote[Obviously, it's named after Astro.].

The core idea of Aster is to use Typst as the language for content as well as for *scripting*, and as the only language for scripting#footnote[Specifically, server-side scripting. In browser environments, JavaScript is still the only option.].
Typst's programming capability is powerful enough that it can mix scripting and markup in a way that is more intuitive than JSX and more flexible than MDX.

There have already been quite a few Typst-focused SSGs, such as #link("https://github.com/Myriad-Dreamin/shiroa")[Shiora], #link("https://github.com/Glomzzz/typsite")[Typsite], #link("https://typst.app/universe/package/tufted/")[Tufted], and #link("https://github.com/tola-rs/tola-ssg")[Tola].
Most of them are closer to traditional SSGs like Jekyll or 11ty, where users choose one of the fixed templates and then write content in Typst.
Tola's philosophy is the most flexible one; it injects virtual packages such as `@tola/pages` into the Typst environment, which contain information like how many pages the site has, the path and title of each page, etc. Users can use this information in Typst to generate pages.
This allows Tola to achieve more flexible page generation than templates.

Aster draws on Astro's design and takes inspiration from the working principles of Tola and #link("https://trunk-rs.github.io/trunk/")[Trunk].
Specifically, Aster separates *pages* and *content*: pages follow file-based routing with an Astro-like dynamic routing mechanism, while content is referenced by pages to generate the actual page content.
This separation mirrors Astro's flexibility: the content side can focus purely on writing, while the page side focuses on styling and layout.
In addition, Aster offers Trunk-style CSS and JS bundling, so you can write CSS and JS directly in Typst and have them automatically bundled into the site at build time.

Aster is written in Rust, which means it can call Typst's Rust API directly. This allows it to take full advantage of the Typst compiler's incremental compilation, significantly speeding up builds. For comparison, this site took over 10s to build with the previous architecture; with Aster, the first build takes only 2s, and subsequent incremental builds take just 0.6s.

Aster also includes a number of other features, such as:

- An Astro-like component system that lets you define components in Typst and use them in pages.
- The ability to collect page information and generate arbitrary text files with Typst scripts, including sitemaps and RSS/Atom feeds.
- Code block re-highlighting with #link("https://lumis.sh")[lumis] to solve the problem of Typst's built-in highlighting not adapting well to both dark and light modes.

I may have gotten a bit carried away. Although Aster is already available on #link("https://github.com/Wybxc/aster")[GitHub] and #link("https://crates.io/crates/aster-ssg")[crates.io], I'm not quite ready to publish it yet.
The interface between Aster and Typst files is still unstable, and I need more time to improve the documentation.
Let this post be a preview of Aster for now.
