# Aster migration

This branch replaces the Astro application with an Aster project while keeping
the Typst articles as the source of truth.

## Project layout

- `pages/` contains the home, about, blog index, and dynamic post pages.
- `generate/` contains the Atom generator, which runs after rendered pages are
  available.
- `content/blog/` contains the reusable Typst blog entries.
- `lib.typ` owns the content protocol and other non-rendering helpers.
- `components/` contains reusable content-rendering functions.
- `templates/` contains the shared HTML document and post template.
- `styles/`, `assets/`, and `public/` contain processed styles, source assets,
  and files copied verbatim, respectively.

Page templates use explicit `index.typ` files for directory URLs. Dynamic
parameters and generated route information come from `sys.inputs._aster.route`.
Generators read final rendered page content from `sys.inputs._aster.site.pages`,
and project settings are read directly from `aster.toml`.

The dynamic blog route still publishes hidden and draft entries when addressed
directly. The blog list and Atom feed filter them out, matching the Astro site.

## Verified parity

Both builds produce the same 13 HTML routes, while Aster publishes `atom.xml`.
The Aster build also publishes the favicon, CNAME, six fonts, CSS dependencies, Typst-generated
images, light/dark syntax themes, file-based directory URLs, and six public Atom
items. The final local build completed with 13 pages and one generated file.

Project show rules now reproduce the former Rehype behavior for all 50
headings, all six aligned MathML tables, and all 12 DOI links in inline
citations. Heading IDs and table-of-contents links are identical. Citations no
longer contain nested anchors.

After heading decorations are excluded, visible article text is byte-for-byte
equal on nine of the 13 routes. The about page intentionally names Aster
instead of Astro. The remaining three routes differ only in formatted
bibliography text.

## Known output differences

| Area | Astro baseline | Aster branch | Impact |
| --- | --- | --- | --- |
| Home images | Data images are converted to optimized external assets | Four `html.frame` images remain inline SVG data, downsampled at 2x display density | `index.html` is 326,123 bytes instead of 9,458 bytes; substantially smaller than the initial 1,122,476-byte migration output |
| Raster assets | The large PNG is optimized to 291,700 bytes | Aster optimizes the 436,542-byte source to 255,040 bytes | Slightly smaller transfer than the Astro output |
| Heading anchors | The icon link itself carries the styling class and is removed from keyboard navigation | A wrapper carries the class and the link has a visually hidden accessible name | Same location and visual behavior; Aster's link remains keyboard-accessible |
| Citation formatting | The typst.ts toolchain formats bibliography entries | Native Typst 0.15.1 formats the same entries with additional editor and publication details | Visible wording differs in three posts, while destinations and semantics match |
| Code highlighting | Shiki emits inline colors for GitHub light/dark themes | Aster emits Lumis-scoped classes and shared light/dark stylesheets | Colors and grammar coverage are not identical |
| Font loading | Three body-font files are preloaded | The same six fonts are published, with no preload links | Rendering can begin with fallback fonts |
| HTML structure | Astro wraps Typst's `<body>` inside the layout `<body>` | Aster inserts only the rendered content | Aster removes invalid nested-body markup |
| Feed format | The Astro endpoint emits RSS items without `title` and `pubDate` | Aster emits Atom entries with titles, dates, summaries, and final transformed article HTML | Intentional correctness improvement and complete reader content |

The complete output is 2.3 MiB for Aster and 3.0 MiB for the captured Astro
baseline, including about 313 KiB of full-text Atom content. The home document
remains larger because `html.frame` preserves inline SVG rendering, but the
image pipeline now removes most of the original size difference.

## Remaining prerequisites

The deployment workflow installs the exact Aster revision used for this
migration.
