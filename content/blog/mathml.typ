#import "../../template.typ": *
#import "@preview/mitex:0.2.7": *
#show: post.with(
  title: "Native Typst to MathML in My Blog",
  pubDate: datetime(year: 2026, month: 5, day: 17),
)

= Native Typst to MathML in My Blog

Quick update: math equations on my blog are now rendered using *native* Typst-to-MathML conversion!

Last year, when Typst enhanced its HTML export in version 0.14, I redesigned my blog to use Typst for authoring content. At the time, though, Typst's HTML export didn't support math equations. The workaround was to render them as SVG images, which preserved the visual quality but came with several drawbacks: (1) the equations weren't selectable, (2) they didn't scale well across different font sizes, (3) they broke in dark mode, and (4) they couldn't line-wrap to fit the surrounding typography. So I ended up using a third-party library called #link("https://codeberg.org/akida/mathyml")[mathyml] to convert math equations into MathML. #footnote[It hooks into Typst's `#show` rule to extract the structured math content, and while its feature coverage is limited, it handles most everyday cases just fine.] It served me well, but I was still hoping for a proper built-in solution.

I'd been keeping an eye on the progress of native MathML support (#link("https://github.com/typst/typst/pull/7436")[\#7436]) in Typst, and on May 12, 2026, the PR finally got merged. With this feature, Typst can directly emit math equations as MathML during HTML export.
Fantastic news for my blog! Naturally, I decided to upgrade and switch to native MathML rendering.

There's just one catch: the feature hasn't landed in a stable Typst release yet, and understandably it's not available in the downstream libraries that power my blog either. So I had to build those libraries myself against the latest Typst. Turns out it wasn't as straightforward as I'd hoped. Let me explain.

I use #link("https://github.com/OverflowCat/astro-typst")[astro-typst] to integrate Typst into Astro, which in turn uses #link("https://github.com/Myriad-Dreamin/typst.ts")[typst.ts] as the underlying Typst engine. Typst.ts shares a lot of code with #link("https://github.com/Myriad-Dreamin/tinymist")[tinymist], the Typst LSP service. Both projects had pinned their Typst dependency to 0.14, and since then Typst's APIs have gone through a fair number of breaking changes. So the upgrade was decidedly non-trivial.
It touched a lot of code across both typst.ts and tinymist.

My plan was to fork typst.ts, bump its pinned Typst version to the latest main branch, and vendor in some of tinymist's code to get everything working. #footnote[Admittedly, this is not the cleanest approach. It pretty much rules out contributing these changes back upstream. But honestly, I don't have much bandwidth to maintain a fork properly; I just wanted things to work for my blog, and for now that's good enough.]
With assistance from Claude Code and DeepSeek V4 Pro, I managed to finish the whole upgrade in a single day. #footnote[I have to say, having an AI assistant tag-team a Rust codebase across multiple crates is quite the experience.] Now my blog renders math equations using native Typst-to-MathML conversion, and it works beautifully.

If you'd also like to use the bleeding-edge Typst in your own project, feel free to check out my fork of typst.ts at #link("https://github.com/Wybxc/typst.ts/tree/wybxc")[GitHub]. Or, if you're using pnpm, you can simply override the dependency with my pre-built version:

```yaml
overrides:
  "@myriaddreamin/typst-ts-node-compiler": "npm:@wybxc/typst-ts-node-compiler@0.7.1"
  "@myriaddreamin/typst-ts-renderer": "npm:@wybxc/typst-ts-renderer@0.7.1"
  "@myriaddreamin/typst.ts": "npm:@wybxc/typst.ts@0.7.1"
```

Below are a few sample math equations to give you a sense of the rendering quality with native Typst-to-MathML conversion:

#quote(block: true)[
  The Poincaré–Birkhoff–Witt theorem is a fundamental result in Lie theory that connects the symmetric algebra and the universal enveloping algebra. Let #mi(`\mathfrak{g}`) be a Lie algebra over a field #mi(`\mathbb{F}`), and let #mi(`\mathcal{U}(\mathfrak{g})`) be its universal enveloping algebra. Choose a basis #mi(`\{ \mathbf{x}_i \}`) and denote the symmetric algebra by #mi(`\mathsf{S}(\mathfrak{g})`). Then the PBW theorem asserts the existence of a graded algebra isomorphism
  #mitex(
    `
\mathtt{gr}\,\mathcal{U}(\mathfrak{g}) \;\cong\; \mathsf{S}(\mathfrak{g}),
`,
  )
  where #mi(`\mathtt{gr}`) denotes the associated graded algebra with respect to the standard filtration. In the representation theory of Lie algebras, the adjoint action is often written as #mi(`\mathtt{ad}_{\mathbf{x}}(\mathfrak{y}) = [\mathbf{x}, \mathfrak{y}]`) (with #mi(`\mathfrak{y} \in \mathfrak{g}`)). Usually the ground field is taken to be #mi(`\mathbb{C}`) or #mi(`\mathbb{R}`), in which case #mi(`\mathcal{U}(\mathfrak{g})`) has a natural Hopf algebra structure, and the left regular action is given by #mi(`\mathsf{L}_{\mathbf{x}}(u) = \mathbf{x} u`). This result profoundly reveals the intrinsic connection between Lie algebras and associative algebras.
]
