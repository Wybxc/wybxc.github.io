#import "../../template.typ": *
#show: post.with(
  title: "A New Design for Pretty Printer Implementations in Rust",
  pubDate: datetime(year: 2026, month: 5, day: 28),
)

= A New Design for Pretty Printer Implementations in Rust

Since I studied #link("https://blog.wybxc.cc/blog/pretty-printer-rustc/")[Rustc's pretty printer] and implemented #link("https://crates.io/crates/elegance")[my own pretty printer library] (which is used in the #link("https://crates.io/crates/cgrammar")[cgrammar] crate, a crate for parsing and processing C23 syntax), I have been thinking about how to design a better pretty printer library, especially by applying the research results from academia
@hughesDesignPrettyprintingLibrary1995
@wadlerPrettierPrinter2003
@bernardyPrettyNotGreedy2017
to practical Rust library designs.

An important obstacle is that academic research is often based on functional programming languages, and in particular assumes the existence of garbage collection, whereas Rust is a systems programming language without garbage collection. This means that memory management must be an extra consideration when implementing these designs in Rust.

For example, in a typical Wadler-style#footnote[
  For the differences between Wadler-style and Oppen-style pretty printers, see #link("https://docs.rs/elegance/0.4.0/elegance/#differences-from-other-libraries")[this explanation] in the elegance crate's documentation.
] pretty printer, the document structure is usually a recursive data type:

```ocaml
type doc =
  | Nil
  | Append of doc * doc
  | Group of doc
  | FlatAlt of doc * doc
  | Nest of int * doc
  | Hardline
  | Text of string
  | Union of doc * doc
  | Fail
```

This document structure is then converted into a string output through a layout function:

```ocaml
let rec layout (d : doc) (width : int) : string
  = (* implementation omitted *)
```

To implement such an algorithm in Rust, the most straightforward approach is to adopt the same pattern.
For instance, the #link("https://crates.io/crates/pretty")[pretty] crate implements Wadler's classic algorithm (with some later supplements), and its document structure definition (simplified) is as follows:

```rust
pub enum Doc<T> {
    Nil,
    Append(T, T),
    Group(T),
    FlatAlt(T, T),
    Nest(isize, T),
    Hardline,
    Text(Box<str>),
    Union(T, T),
    Fail,
}

type BoxDoc = Box<Doc<BoxDoc>>;
type RcDoc = Rc<Doc<RcDoc>>;
```

As shown above, the pretty crate makes the `Doc` enum generic over a type `T`, which can be either `BoxDoc`, `RcDoc`, or any other pointer type of `Doc`.
This allows users to make more flexible memory management decisions: using the lighter `BoxDoc`, the more flexible but heavier `RcDoc`, or some arena allocators.
#footnote[
  Another benefit is that this design effectively turns `Doc` from a type into a functor, enabling the use of functor-related abstractions (like catamorphisms) to implement efficient recursive algorithms; see the #link("https://crates.io/crates/recursion")[recursion] crate.
]
However, this design also has some limitations. For example, it forces all nodes in a document tree to use the same memory management strategy, which may lack flexibility in certain situations.

Oppen-style pretty printers (such as #link("https://blog.wybxc.cc/blog/pretty-printer-rustc/")[Rustc's pretty printer] and the #link("https://crates.io/crates/elegance")[elegance] crate) do not have this problem because Oppen-style processes the document's input and output as a stream without building a complete document tree.
But the streaming approach of Oppen-style pretty printers also limits their expressive power.
Research by Sorawee Porncharoenwase, et al. @porncharoenwasePrettyExpressivePrinter2023
points out that the general pretty printing problem is a global optimization problem; streaming pretty printers can only obtain a locally optimal solution through greedy algorithms and cannot guarantee global optimality.
Therefore, to achieve a globally optimal pretty printer, one must build the complete document tree.

This post will propose a new design for pretty printer implementations in Rust, aiming to retain the expressive power of Wadler-style document trees while implementing them in a way that better aligns with Rust's memory management.

The inspiration for this implementation comes from a concept in functional programming:
a data type can be equivalently represented by the ways you consume it.#footnote[
  See my other blog post #link("https://blog.wybxc.cc/blog/parametricity")[Church Encoding, Parametricity, and the Yoneda Lemma].
]
We are not really interested in the concrete structure of the document tree, but rather in how to use it to produce output.

Therefore, instead of defining a recursive data structure for `Doc`, we can define `Doc` as a trait, with a method that consumes the document and produces the output.

```rust
pub trait Doc {
    fn layout(&self, renderer: &mut Render) -> RenderOutput;
}
```

The various document constructions then become different types implementing this trait, for example:

```rust
#[derive(Clone)]
pub struct Text {
    s: String,
}

impl Doc for Text {
    fn layout(&self, renderer: &mut Render) -> RenderOutput {
        renderer.text(&self.s)
    }
}

pub fn text(s: impl Into<String>) -> impl Doc {
    Text { s: s.into() }
}
```

And also:

```rust
#[derive(Clone)]
pub struct Concat<A, B> {
    a: A,
    b: B,
}

impl<A: Doc, B: Doc> Doc for Concat<A, B> {
    fn layout(&self, renderer: &mut Render) -> RenderOutput {
        // fn Render::concat(
        //     self: &Render,
        //     left: RenderOutput,
        //     right: impl Fn(&Render) -> RenderOutput
        // ) -> RenderOutput;
        renderer.concat(self.a.layout(renderer), |r| self.b.layout(r))
    }
}

pub fn concat<A: Doc, B: Doc>(a: A, b: B) -> impl Doc {
    Concat { a, b }
}
```

In this model, the structure of the document tree still exists.
However, compared to the recursive data structure approach, it significantly reduces memory indirection and dynamic allocation overhead.

At the same time, it supports more flexible memory management. For example, you can mix `Box<dyn Doc>` and `Rc<dyn Doc>` within a document tree because both implement the `Doc` trait.

```rust
impl Doc for Box<dyn Doc> {
    fn layout(&self, renderer: &mut Render) -> RenderOutput {
        self.as_ref().layout(renderer)
    }
}

impl Doc for Rc<dyn Doc> {
    fn layout(&self, renderer: &mut Render) -> RenderOutput {
        self.as_ref().layout(renderer)
    }
}
```

From another perspective, this is somewhat similar to how we implement enumeration types in object-oriented languages (like C++): we define a base class for all documents, and each document construction is a subclass of this base class.

I wrote a proof-of-concept (referred to below as pye)#footnote[
  With assistance from AI.
  I did not publish the code for pye because I have not yet fully reviewed and structured it.
] for the above design, implementing the algorithm $Π_e$ from the paper
_A pretty expressive printer_ (OOPSLA'23)
@porncharoenwasePrettyExpressivePrinter2023,
a general and globally optimal pretty printing algorithm,
and conducted a performance comparison with the following crates:
- The #link("https://crates.io/crates/pretty")[pretty] crate, the most widely used Wadler-style pretty printer implementation in the Rust ecosystem.
- The #link("https://crates.io/crates/elegance")[elegance] crate, an Oppen-style streaming pretty printer implementation.
- The #link("https://crates.io/crates/pretty-expressive")[pretty-expressive] crate (referred to below as pe), a direct Rust implementation of the _A pretty expressive printer_ paper.

On a 78kB JSON formatting task, pye achieved a 60x speedup over pe and reached about 57% of the performance of the pretty crate.
The reason pye is slower than the pretty crate is mainly that pye implements a globally optimal algorithm, while the pretty crate uses a simpler greedy algorithm.
However, compared to pe, which uses the same algorithm, pye's performance improvement demonstrates that this new design is competitive in Rust.

#image("images/bench_outlier.svg")

Below is a performance comparison on more formatting tasks, including JSON records, JSON arrays, deeply nested JSON, mixed JSON, and Lisp code. Each task has several variants: wide (ample line width to fit in one line), middle (moderate line width, like common use cases), and narrow (very small line width).
On these tasks, pye's performance is generally on par with pretty and elegance, and even surpasses both crates on some tasks, while significantly outperforming pe on the vast majority of tasks.

#fullwidth[
  #image("images/bench_summary.svg")
]

*Updated:*

I added new experiments with more performance comparisons, including:
- An implementation using the design proposed in this post, but implementing the same greedy algorithm as the pretty crate (referred to below as pretty2);
- The pretty crate, but using an arena allocator (referred to below as p-arena).

The experimental results are shown below:

#fullwidth[
  #image("images/bench_summary_2.svg")
]

Several more interesting findings can be observed:
1. p-arena outperforms pretty, confirming that memory management is indeed a performance bottleneck in pretty printer implementations.
2. pretty2 is faster than all other implementations, and on some tasks it achieves more than a 10x gap over pretty and p-arena (comparable to the performance gap between pye and pe) demonstrating that the design proposed in this post can indeed deliver significant performance improvements.
3. pye is consistently slower than pretty2. This shows that while the proposed design can improve performance, the choice of algorithm (globally optimal vs. greedy) has an even greater impact on performance.
4. The streaming-based elegance shows no performance advantage over pretty2 and p-arena. This may be due to the benchmark design: non-streaming algorithms only measure the time spent on the layout task, excluding document tree construction; whereas in streaming algorithms the two are interleaved, so both are included in the measured time.

#bibliography("references.bib")
