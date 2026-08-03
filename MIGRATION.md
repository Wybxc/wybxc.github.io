# Aster migration

This branch replaces the Astro application with an Aster project while keeping
the Typst articles as the source of truth.

## Project layout

- `pages/` defines the home, about, blog, dynamic post, and RSS routes.
- `content/site/` and `content/blog/` contain the Typst entries.
- `site.typ` owns the shared HTML document, navigation, and footer.
- `template.typ` owns post metadata and project-specific Typst components.
- `styles/`, `assets/`, and `public/` contain processed styles, source assets,
  and files copied verbatim, respectively.
- `lib/aster/content.typ` is the Aster content protocol helper used by pages.

The dynamic blog route still publishes hidden and draft entries when addressed
directly. The blog list and RSS feed filter them out, matching the Astro site.

## Verified parity

Both builds produce the same 13 HTML routes and `rss.xml`. The Aster build also
publishes the favicon, CNAME, six fonts, CSS dependencies, Typst-generated
images, light/dark syntax themes, clean directory URLs, and six public RSS
items. The final local build completed with 13 pages and one endpoint.

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
| Home images | Data images are converted to optimized external assets | Four `html.frame` images remain inline data inside SVG | `index.html` is 1,122,476 bytes instead of 9,458 bytes |
| Raster assets | The large PNG is optimized to 291,700 bytes | The original 436,542-byte PNG is published | Larger transfer |
| Heading anchors | The icon link itself carries the styling class and is removed from keyboard navigation | A wrapper carries the class and the link has a visually hidden accessible name | Same location and visual behavior; Aster's link remains keyboard-accessible |
| Citation formatting | The typst.ts toolchain formats bibliography entries | Native Typst 0.15.1 formats the same entries with additional editor and publication details | Visible wording differs in three posts, while destinations and semantics match |
| Code highlighting | Shiki emits inline colors for GitHub light/dark themes | Aster emits Syntect classes and a shared light/dark stylesheet | Colors and grammar coverage are not identical |
| Font loading | Three body-font files are preloaded | The same six fonts are published, with no preload links | Rendering can begin with fallback fonts |
| HTML structure | Astro wraps Typst's `<body>` inside the layout `<body>` | Aster inserts only the rendered content | Aster removes invalid nested-body markup |
| RSS metadata | Items omit `title` and `pubDate` because the Astro endpoint spreads the entry rather than its data | Every item includes `title` and `pubDate` | Intentional correctness improvement |

The complete output is 3.1 MiB for Aster and 3.0 MiB for the captured Astro
baseline. The unusually large home document offsets Aster's smaller HTML on
ordinary pages.

## Remaining prerequisites

The deployment workflow installs the exact Aster revision used for this
migration. That revision is currently ahead of the public Aster `main` branch
and must be pushed before GitHub Actions can resolve it.

Typst 0.15 still reports that HTML export is experimental. Fletcher also emits
two warnings about the math font used by one diagram; the generated page and
diagram are present.
