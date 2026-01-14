#import "../../template.typ": *
#show: post.with(
  title: "Translating a Haskell Pretty Printer to Rust",
  pubDate: datetime(year: 2026, month: 1, day: 9),
  draft: true,
)

= Translating a Haskell Pretty Printer to Rust

In this post, I talk about the story in building my crate #link("https://crates.io/crates/elegance")[elegance], a language-independent pretty printer implemented in Rust. It features an Oppen-style streaming API that takes sources in and produces formatted text without constructing an intermediate representation of the entire document.

I first encountered Oppen's algorithm in rustc's internal pretty printer.#footnote[Check out my #link("/blog/pretty-printer-rustc")[previous blog post] for more.] Surprised to find no standalone crate for it, I decided to build one myself.
After researching several implementations and papers on pretty printing, I settled on translating a Haskell implementation into Rust.

Just a quick note: basic knowledge of Haskell#footnote[Don't worry; just a little familiarity will do. I won't talk about those "monads" non-sense.] and Rust will help you follow along.

This is going to be a interesting example of *program calculus* in action, i.e., rewriting a program into a different form while preserving its semantics by equational reasoning.
Here's the cool part: even though we are building an imperative program in Rust, we'll use functional programming as our blueprint.
Yeah, just a view shift can be a game-changer.
That’s exactly why I love programming languages!

= The History of Pretty Printing

To provide some context for readers unfamiliar with pretty printing: as programming languages evolved, the need for readable and aesthetically formatted code grew. While early solutions were often ad-hoc, Oppen established the theoretical groundwork in 1980 with a language-independent algorithm@oppenPrettyprinting1980.

Oppen's algorithm takes as input a sequence of tokens that form a document, including text, potential line breaks, and indentation commands.
It processes this sequence in a single pass, deciding where to insert line breaks and how to indent lines based on a specified maximum line width.
The result is a neatly formatted document that adheres to the desired constraints.
To see it in action, this Rust trait mimics Oppen's interface:

```rust
trait PrettyPrinter {
    fn initialize(&mut self, line_width: usize);
    fn scan_text(&mut self, text: &str);     // feed text into the printer
    fn scan_space(&mut self, size: usize);   // feed a potential line break
    fn scan_begin(&mut self, indent: usize); // begin a indented group
    fn scan_end(&mut self);                  // end a group
    fn finalize(self) -> String;  // get the formatted output
}
```

Although Oppen's approach was imperative, it inspired functional implementations by Hughes@hughesDesignPrettyprintingLibrary1995 and later Wadler@wadlerPrettierPrinter2003, who introduced combinators to build pretty printers in a modular fashion.

Wadler’s algorithm is highly influential, powering the widely used code formatter #link("https://prettier.io/docs/technical-details.html")[Prettier] and serving as the basis for libraries like Haskell's #link("https://hackage.haskell.org/package/prettyprinter")[prettyprinter] and Rust's #link("https://crates.io/crates/pretty")[pretty] crate. Given this prevalence, why do I (and rustc) choose Oppen’s algorithm over Wadler’s?

The primary reason is that Wadler’s approach clashes with Rust’s explicit memory management. Wadler’s algorithm constructs a full intermediate representation of the document before rendering. While this is trivial in garbage-collected languages, it becomes cumbersome in Rust. For instance, the #link("https://crates.io/crates/pretty")[pretty] crate forces users to manage allocators manually, deciding between arena allocators, `Box`, or `Rc`, which adds significant complexity.

In contrast, Oppen’s algorithm is streaming by nature. It processes the document in a single pass, calculating line breaks and indentation on the fly without building a heavy intermediate representation. This results in a much more ergonomic API for Rust, bypassing the need for complex memory management strategies.

= From Haskell to Rust

In his paper, Oppen provided his algorithm in Pascal-style pseudo-code, making it easy to port line-by-line to Rust. That's basically what rustc and the #link("https://crates.io/crates/prettyplease")[prettyplease] crate did.

But is there a better way? Oppen's original code doesn't use data structures very well, making it needlessly tangled.

After digging through some papers, I stumbled upon Swierstra's Haskell implementation@swierstraLinearBoundedFunctional2009 and made a bold choice: I would *translate a Haskell pretty printer to Rust*! It sounds ridiculous, and I didn't believe it would work initially, but it actually makes perfect sense.

So, let's see how I pulled it off. The heart of Swierstra's algorithm looks like this:

```haskell
type Indent = Int -- zero or positive
type Width = Int -- positive
type Position = Int
type Remaining = Int
type Horizontal = Bool
type Out = Remaining -> String
type OutGroup = Horizontal -> Out -> Out
type Dq = DeQueue (Position, OutGroup)
type TreeCont = Position -> Dq -> Out
type Doc = (Indent, Width) -> TreeCont -> TreeCont

prune :: TreeCont -> TreeCont
prune c p [] r = c p [] r
prune c p dq r = if p > s + r then grp False (prune c p dq') r
                 else c p dq r
  where (s, grp), dq' = front dq, popFront dq

leave :: TreeCont -> TreeCont
leave c p [] = c p []
leave c p [(s1 , grp1)] = grp1 True (c p [])
leave c p dq = c p (
    dq'' `append` (s2 , \h c -> grp2 h (\r -> grp1 (p <= s1 + r) c r)))
  where (s1, grp1), dq' = front dq, popFront dq
        (s2, grp2), dq'' = front dq', popFront dq'

scan :: Width -> OutGroup -> TreeCont -> TreeCont
scan l out c p [] = out False (c (p + l) [])
scan l out c p dq = prune c (p + l) (dq' `append` (s, \h -> grp h . out h))
  where (s, grp), dq' = front dq, popFront dq

nil :: Doc
nil iw = \c -> c

text :: String -> Doc
text t iw = scan l outText
  where l = length t
        outText _ c r = t ++ c (r − l)

space :: Doc
space (i, w) = scan 1 outLine
  where outLine True c r = ' ' : c (r − 1)
        outLine False c r = '\n' : replicate i ' ' ++ c (w − i)

(<>) :: Doc -> Doc -> Doc
(dl <> dr) iw = dl iw . dr iw

group :: Doc -> Doc
group d iw = \c p dq -> d iw (leave c) p (dq `append` (p, \h c -> c))

nest :: Indent -> Doc -> Doc
nest j d (i, w) = d (i + j, w)

pretty :: Width -> Doc -> String
pretty w d = d (0, w) (\p dq r -> "") 0 [] w
```

Hmm, this looks a bit complex. Let's break it down.

The Haskell version takes a different path:
it wraps the core logic of Oppen's algorithm in a Wadler-style combinator interface.
Instead of issuing commands step-by-step, you construct the document structure using building blocks like `text`, `space`, and `group`, and then render the result with `pretty`.

To see this in action, let's look at how we'd pretty-print an S-Expression (Lisp-style code):

```haskell
ppSExp :: SExp -> Doc
ppSExp (Atom x) = text x
ppSExp (List xs) = group $ text "(" <> pp xs <> text ")"
  where pp [] = nil
        pp [x] = text x
        pp x:xs = text x <> space <> pp xs

printSExp :: SExp -> String
printSExp s = pretty 80 $ ppSExp s   -- line width = 80
```

However, these combinators do not build an intermediate representation; instead, they form a chain of continuations.
Thanks to Haskell's laziness, computations are deferred until the final `pretty` call, which executes the entire chain in a streaming manner.

Since we cannot bring Haskell's laziness to Rust, how can we preserve this streaming nature? The answer lies in a technique called "fusion."

== Interlude: Fusion

Let us briefly digress to examine the concept of "fusion."
Consider a generator function that produces a list of factorials, and a consumer function that retrieves the first element from that list:

```haskell
facts :: Int -> [Int]
facts 0 = [1]
facts n = let x:xs = facts (n − 1) in (n * x) : x : xs

head :: [a] -> a
head (x:xs) = x
```

What happens when we combine these to compute the n-th factorial?
The Haskell compiler is sufficiently sophisticated to realize that only a single element is required. Consequently, it avoids constructing the entire intermediate list.
The two functions are "fused" into a new, optimized function that directly computes the result:

```haskell
fact :: Int -> Int
fact n = head (facts n)
-- which can be optimized to --
fact 0 = 1
fact n = n * fact (n − 1)
```

How do we ensure such optimizations are valid? The validity rests on equational reasoning@huHowFunctionalProgramming2015. This allows us to rewrite programs while preserving their semantics, much like solving algebraic equations.

```haskell
fact 0 = head (facts 0) = head [1] = 1
fact n = head (facts n)
       = head (let x:xs = facts (n − 1) in (n * x) : x : xs)
       = let x:xs = facts (n − 1) in head ((n * x) : x : xs)
       = let x:xs = facts (n − 1) in n * x
       = n * (head (facts (n − 1)))
       = n * fact (n − 1)
```

Here's where the name "fusion" comes from: we are fusing two functions into one by rewriting them.
Usually the inner function produces some intermediate data structure, and the outer function consumes it.
By unfolding the definitions and rearranging the computations, we can eliminate the intermediate structure entirely.

== Fuse the Pretty Printer

Now, let's return to our pretty printer. Our goal is to fuse the combinator-based pretty printer into a streaming one, mirroring Oppen's original imperative interface.

```rust
trait PrettyPrinter {
    fn initialize(&mut self, line_width: usize);
    fn scan_text(&mut self, text: &str);     // feed text into the printer
    fn scan_space(&mut self, size: usize);   // feed a potential line break
    fn scan_begin(&mut self, indent: usize); // begin a indented group
    fn scan_end(&mut self);                  // end a group
    fn finalize(self) -> String;  // get the formatted output
}
```

First, let's identify which functions to fuse. The inner functions that generate the document structure are combinators like `group`, `nest`, and `<>`, while the outer function is `pretty`, which consumes this structure to produce the final string. Therefore, we need to analyze three patterns: `pretty w (nest j d)`, `pretty w (group d)`, and `pretty w (dl <> dr)`.
#sidenote(block: true)[
  For recovery, here are the relevant definitions again:

  ```haskell
  (<>) :: Doc -> Doc -> Doc
  (dl <> dr) iw = dl iw . dr iw

  group :: Doc -> Doc
  group d iw = \c p dq ->
    d iw (leave c) p (
      dq `append` (p, \h c -> c))

  nest :: Indent -> Doc -> Doc
  nest j d (i, w) = d (i + j, w)

  pretty :: Width -> Doc -> String
  pretty w d =
    d (0, w) (\p dq r -> "") 0 [] w
  ```
]

Let's begin with `pretty w (nest j d)`:

```hs
  pretty w (nest j d)
= nest j d (0, w) (\p dq r -> "") 0 [] w
= d (j, w) (\p dq r -> "") 0 [] w
```

Here we hit a wall: the right side cannot be simplified further.
The trick is to fuse a *generalized* version of `pretty`, where the fixed subexpressions are replaced with parameters.
We will call this generalized function `pretty'`, making `pretty` a specialization of it:

```hs
pretty' :: Doc -> Indent -> Width -> String
pretty' d i w = d (i, w) (\p dq r -> "") 0 [] w

pretty :: Width -> Doc -> String
pretty w d = pretty' d 0 w
```

Now we can continue the derivation:

```hs
  pretty' (nest j d) i w
= nest j d (i, w) (\p dq r -> "") 0 [] w
= d (i + j, w) (\p dq r -> "") 0 [] w
= pretty' d (i + j) w
```

Great! We found a tail recursive form for this case, which means a close relation between `pretty d` and `pretty (nest j d)`.
Later we will see how such relations help us implement the fused function in Rust.

Actually, we can generalize `pretty'` even further by making all its fixed arguments into parameters.

```hs
pretty' d i w c p dq r = d (i, w) c p dq r
pretty w d = pretty' d 0 w (\p dq r -> "") 0 [] w
```

This version of `pretty'` has a beautiful point-free representation:

```hs
pretty' :: Doc -> Indent -> Width -> TreeCont -> TreeCont
pretty' d i w = d (i, w)
```

And it simplifies our previous derivation procedure a lot:

```hs
  pretty' (nest j d) i w
= nest j d (i, w)
= d (i + j, w)
= pretty' d (i + j) w
```

// Take a look at how we draw a sketch of the Rust implementation for this fused function:

// ```rust
// fn nest(i: Indent, j: Indent, pretty: impl FnOnce(Indent)) {
//     pretty(i + j);
// }
// ```

// Here, the parameter `pretty` represents the a continuation that corresponds to the `pretty' i w d` call in Haskell.
// For better alignment with Oppen's original interface, we can make `i` a mutable state variable instead of passing it around:

// ```rust
// fn nest(pp: &mut Pretty, j: Indent, d: impl FnOnce(&mut Pretty)) {
//   pp.indent += j;
//   d(pp);
// }
// ```

Next, let's tackle `pretty w (group d)`:

```haskell
  pretty' (group d) i w c p dq
= group d (i, w) c p dq
= d (i, w) (leave c) p (dq `append` (p, \h c -> c))
= pretty' d i w (leave c) p (dq `append` (p, \h c -> c))
```

// We get stuck again.
// But we can apply the same trick as before: generalize `pretty'` further by replacing the fixed argument `[]` with a parameter `dq`, and the fixed argument `(\p dq r -> "")` with a parameter `c`.

// ```haskell
// pretty' :: Doc -> Indent -> Width -> TreeCont -> Dq -> String
// pretty' d i w c dq = d (i, w) c 0 dq w

// pretty :: Width -> Doc -> String
// pretty w d = pretty' d 0 w (\p dq r -> "") []

// pretty' (group d) i w c dq = (\c p dq -> d (i, w) (leave c) p (dq `append` (p, \h c -> c))) c 0 dq w
//     = d (i, w) (leave c) 0 (dq `append` (0, \h c -> c)) w
//     = pretty' d i w (leave c) (dq `append` (0, \h c -> c))
// ```

// Here's the corresponding Rust sketch#footnote[
//   You may wonder how to implement the strange `leave` function in Rust. Well, this piece of code is not quite correct yet. We'll refine it later.
// ]:

// ```rust
// fn group(pp: &mut Pretty, pretty: impl FnOnce(&mut Pretty)) {
//     pp.tree_cont = leave(pp.tree_cont);
//     pp.deque.push_back((0, |h, c| c));
//     pretty(pp);
// }
// ```

Finally, let's handle `pretty w (dl <> dr)`:

```haskell
  pretty' (dl <> dr) i w
= (dl <> dr) (i, w)
= dl (i, w) . dr (i, w)
= pretty' dl i w . pretty' dr i w
```

And the base cases of the fused versions of the primitives combinators:

```haskell
pretty' nil i w c = nil i w c = c
pretty' (text t) i w = scan l outText
  where l = length t
        outText _ c r = t ++ c (r − l)
pretty' space i w = scan 1 outLine
  where outLine True c r = ' ' : c (r − 1)
        outLine False c r = '\n' : replicate i ' ' ++ c (w − i)
```


#bibliography("references.bib")
