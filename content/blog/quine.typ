#import "/templates/post.typ": post
#import "/components/web.typ": *
#show: post.with(
  title: "Let's Play Quine!",
  pubDate: datetime(year: 2026, month: 8, day: 26),
  draft: true,
)

= Let's Play Quine!

How can one write a program whose output is exactly its own source code?

This question was posed by Douglas Hofstadter in _Gödel, Escher, Bach_, where he coined the term "quine" for such a program#footnote[
  The term "quine" is named after the philosopher Willard Van Orman Quine. In the mid-twentieth century, he formulated a well-known self-referential paradox:
  "Yields falsehood when preceded by its quotation" yields falsehood when preceded by its quotation.
].

The most obvious approach is a program that reads its own source file and prints it. In Python, this can be written as:

```python
print(Path(__file__).read_text())
```

But anyone with even a passing familiarity with quines will immediately object: "Reading your own source violates the rules!" They will then present a proper quine:

```python
s = 's = {!r}\nprint(s.format(s))'
print(s.format(s))
```

This is quite a clever solution, but why is reading the source file disallowed? And where does the apparently magical pattern in the proper solution come from? To answer either question, we first need to say precisely what a quine is.

== A Weak Objection

A common objection to source-reading quines is that they are not robust. They assume that the source file remains accessible when the program runs. If the program is compiled into a binary and moved elsewhere, it may no longer be able to find that file.

However, this objection is not decisive. A program might read its source at compile time rather than at runtime. Rust's `include_str!` macro, for example, reads a text file during compilation and embeds the result into the executable:

```rust
fn main() {
    let s = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/", file!()));
    println!("{s}");
}
```

Once compiled, this executable can print the embedded source even after the original file has been deleted.
Thus, dismissing the previous program solely on grounds of robustness is not entirely justified. We need a more precise criterion to distinguish it from a standard quine.

== The Semantics of Quines

"A program whose output is exactly its own source code" appears straightforward at first glance, but it leaves several key notions undefined.  What exactly is a _program_? What is the _output_? What is the _source code_? We have, in effect, been using these concepts without defining them.

To define these concepts is to provide a semantics for programs. Generally speaking, semantics is the mapping of syntactic constructs and related notions to mathematical objects, thereby enabling rigorous mathematical reasoning about them.

To define quines in different languages, we need a general, language-agnostic way of specifying semantics. Here we adopt operational semantics. In operational semantics, the semantics of a language consists of a set of rules that map the current program and state to the residual program and a new state after one execution step. #footnote[
  For simplicity, we assume an interpreted execution model.
  // In the case of compiled languages, one may regard the source code and the compiler as a single combined entity: the first step compiles the source into target code, and the remaining steps execute that target code on the machine.
] This style of definition is known as small-step semantics.

Let $cal(P)$ be the set of programs or program fragments, and let $cal(S)$ be the set of machine states. In this article, an initial program $p_0 in cal(P)$ is identified with its exact source string. A configuration is a pair
$
  (p, sigma) in cal(P) times cal(S),
$
where $p$ is the residual program and $sigma$ is the current state. The semantics is then specified by a binary relation

$
  class("normal", ->) : (cal(P) times cal(S)) times (cal(P) times cal(S)),
$

called the small-step transition relation. We write

$
  (p, σ) -> (p', σ')
$

to mean that one step of execution transforms the configuration $(p, σ)$ into the configuration $(p', σ')$.

Given the abstract apparatus for describing semantics, let us examine how it applies to a concrete program. Consider the standard quine solution discussed earlier. Here, the program $p$ can be represented simply by its source code.

$
  p = bbox(#render[```python
  s = 's = {!r}\nprint(s.format(s))'
  print(s.format(s))
  ```])
$

What is the state $σ$? For an interpreter, it is natural to expect that the program state includes a mapping from all current variables to their values.

But this is still insufficient to capture the full state. Suppose we are about to execute a `print` statement; what effect does it have on the state? It does not modify any local variables; it merely writes some text to the output. To represent the effect of `print` on the state, we must also incorporate the program's output into the state.

We therefore need to divide the state into two parts: internal state and external state. The internal state includes variable values, memory contents, etc. The external state, by contrast, encompasses everything outside the internal state that the program may depend upon or modify.
For example, in the case of `print`, we may regard the external state as containing a terminal, and the behavior of `print` is to append a piece of text to the end of that terminal. We call any interaction (either reading or writing) with the external state an _effect_. To mark when a program produces an effect, we can annotate the small-step transition relation with a label:
$
  (p, σ) ->^α (p', σ')
$
means that the program $p$, in state $σ$, takes one step of execution, leaving the residual program $p'$ and the updated state $σ'$, and in doing so produces the effect $α$.
In the `print` example, we can write $α = sans("Print")(s)$, indicating that the effect is to print the string $s$ to the terminal.
If the program reads a file, we can write $α = sans("Read")(f)$, If the program does not produce any effect, we can write $α = ε$, where $ε$ denotes the empty effect.

The boundary between internal and external state is somewhat arbitrary: certain parts of the state may be regarded as internal under one standard but external under another. Nevertheless, we generally tend to treat program memory as internal state, while the file system, network, and so on are considered external. This division originates from the Turing machine model of computation: a Turing machine describes purely computational behavior, its tape corresponds to memory, and concepts such as files or networks simply do not exist for a Turing machine. Hence we classify them as external.

Now we are finally in a position to define precisely what a quine is. Given a program $p = p_0$ and an initial state $sigma_0$ whose internal state is independent of the program, consider a finite execution trace
$
  (p_0, σ_0) ->^(α_1) (p_1, σ_1) ->^(α_2) dots.h ->^(α_n) (p_n, σ_n)
$
such that each adjacent pair satisfies the small-step transition relation, and the configuration $(p_n, σ_n)$ is terminal, that is, there is no configuration $(p', σ')$ such that $(p_n, σ_n) -> (p', σ')$. If all non-empty effects produced during this execution are text output, and the concatenation of this output text is exactly equal to the source code of program $p_0$, then we call $p_0$ a quine.
#footnote[
  Strictly speaking, we need to give special consideration to programs with nondeterministic semantics. For example, in a multithreaded program, the order of execution across different threads is not fixed. In such cases, we must require that every possible execution trace of the program satisfies the above condition before we can call it a quine.
]

According to this definition, we can now reject those quine programs that read their own source code. This is because the program's own source code is not part of its initial internal state; it must belong to the external state. Reading the source code is therefore an additional effect, which violates the requirement that the only effects be text output.

== Why do Quines Exist?

We have now given a precise definition of a quine, and we have also seen how to rule out programs that read their own source code by appealing to the concept of effects.
But a question remains: why do quines exist at all?
After all, the definition seems to demand a kind of circularity that is not obviously possible.
To produce an output which is exactly the source code, the program must, in some sense, know a copy of its own source code.
But how can a program refer to itself without falling into infinite regress?

If you are starting to feel confused by this question, then my sophistry has succeeded. In fact, it is perfectly normal for a program to refer to itself. Each of us encountered this concept when learning to program: *recursion*.

In Python, we can easily write a recursive function. For example, suppose we want to compute factorials using recursion. We first assume there is a `factorial` function that can compute the factorial of a natural number. Then we can use this `factorial` function to define itself, that is, let `factorial(n) = n * factorial(n - 1)`:

```python
def factorial(n):
    return 1 if n == 0 else n * factorial(n - 1)
```

What happens if we try to construct a quine in the same way?

First we assume there is a function `quine` whose return value is its own source code. Since we have the source code of `quine`, to turn this source code into a computation, we can call `eval` on it, so we get the following definition:

```python
def quine():
    return eval(quine())
```

We fail as expected: this function, according to this way of defining it, will fall into infinite recursion and yield no result at all.
However, this attempt is not meaningless, because we have obtained an important property of quines from it.

If a function `quine` can return its own source code, then it must satisfy `quine() = eval(quine())`. In other words, the result of `quine` is a _fixed point_ of `eval`.

There is a very deep connection between recursive functions and fixed points. To elaborate in detail here would require too much space. One important conclusion is that if we can find a way to construct#footnote[
  "Construct" is of central importance here. If we could only establish the existence of a fixed point but could not give a method for constructing it (say, by contradiction), then it would be of no computational use for recursive functions. Fortunately, as we shall see, fixed-point theory is rich in constructive results.
] fixed points in a certain structure, then we can define recursion in that structure. Conversely, it is not always feasible to construct a fixed point starting from a recursive form. The mistake we just made was trying to construct a fixed point from the recursive definition of a quine, which resulted in a non-computable result. The correct direction should be the reverse: starting from fixed points to construct the structure of a quine.

We have derived a fixed-point property of quines, though it does not yet align precisely with the definition given earlier. To make the connection rigorous, we need to lift this property to a general operational semantics.

Given a program $p$, an initial state $σ$, and a finite execution trace in small-step semantics:
$
  (p, σ) ->^(α_1) (p_1, σ_1) ->^(α_2) dots.h ->^(α_n) (p_n, σ_n),
$
we only care about the effects produced during execution.
Therefore, we define a partial function
$⟦p⟧_σ = bold(α)$
when executing $p$ in state $σ$ terminates and produces a sequence of effects $bold(α) = (α_1, α_2, dots, α_n)$. Otherwise, we define $⟦p⟧_σ = ⊥$.

Let $sans("out")(bold(α))$ denote the concatenation of all text-output effects in the sequence $bold(α)$, and $sans("out")(⊥) = ⊥$.
For a quine $p$, it then follows that
$
  sans("out")(⟦p⟧_σ) = p,
$
that is, $p$ is a fixed point of the function $f(p) = sans("out")(⟦p⟧_σ)$.

This reformulation immediately connects quines to one of the central ideas in recursion theory: the existence of fixed points for computable functions. The most important result here is Kleene's second recursion theorem.
Using this theorem, we will prove that if a language is *Turing-complete* and *self-hosting*, then one can construct a quine within it.

== Kleene's Recursion Theorem

Fixed-point theory studies the following class of problems: given a set $D$ and a function $f: D -> D$, under what conditions does $f$ admit a fixed point?
Of course, by Rice's theorem, the most general form of this problem is undecidable. Therefore, fixed-point theory typically restricts attention to domains $D$ and functions $f$ that possess additional structure, and aims to provide a constructive procedure for finding a fixed point of $f$.

We now return to the problem of quines. Assume the language in which we intend to construct a quine is self-hosting, meaning that one can implement an interpreter for the language within the language itself. Denote this meta-circular interpreter by $mono("run")$. It satisfies

$
  sans("interp")_σ (p) = sans("interp")_σ (bbox(mono("run")(p))),
$

where $bbox(mono("run")(p))$ denotes the program whose source code is the string $mono("run")(p)$.

TODO

_Kleene's second recursion theorem_, also commonly called _Kleene's recursion theorem_, is a fundamental result in recursion theory. It states that for any total computable function $F: cal(P) -> cal(P)$, there exists a program $q in cal(P)$ such that#footnote[
  For consistency with the notation adopted in this post, the statement of Kleene's recursion theorem given here departs slightly from the original formulation, which uses Gödel numbering; the equivalence between the two is readily verified.
]


We now state the source-string version carefully. Let $sans("Src")$ be the set of exact source strings of closed programs. This is a meta-level set; it need not be a type offered by the language. Let $sans("Code")$ be the set of strings (or syntax trees) used by the source constructor to represent code. A static source template is a syntactic object in $sans("Tpl")$: a source string or syntax tree with exactly one distinguished static code slot. It is not an extensional run-time function. Its induced plugging operation and its quotation are

$
  sans("plug"): sans("Tpl") times sans("Code") -> sans("Src"), \
  sans("quote"): sans("Tpl") -> sans("Code").
$

The first operation replaces the marked slot by a properly escaped code literal; the second returns the template's canonical source representation. The diagonal operation is the heterogeneous, static operation

$
  sans("diag")(T) = sans("plug")(T, sans("quote")(T)):
  sans("Tpl") -> sans("Src").
$

The quotation is essential for typing: the template $T$ is not itself inserted into its hole. Its code representation is inserted. The construction takes place before execution, so neither $sans("plug")$ nor the hole is a run-time input.

_Kleene's second recursion theorem_, also commonly called _Kleene's recursion theorem_, is a fundamental result in recursion theory. In the present notation, assume that the source system has the following effective representability property: for every total computable source transformation $F: sans("Src") -> sans("Src")$, there is a template $D_F in sans("Tpl")$ such that, for every template $T$ and every admitted initial state $σ$,

$
  ⟦sans("plug")(D_F, sans("quote")(T))⟧_σ
  ≃
  ⟦F(sans("diag")(T))⟧_σ.
$

This is the source-level analogue of the universal-program step in the natural-number proof. It can be realized by a source-to-source compiler, macro expander, or an internal evaluator, but it is not a consequence of Turing completeness alone. Self-hosting supplies a compiler implementation; it does not automatically supply a run-time `Code` type or `eval`.

Now define the closed source string

$
  q = sans("diag")(D_F)
  = sans("plug")(D_F, sans("quote")(D_F)).
$

Applying the property of $D_F$ to $T = D_F$ gives

$
  ⟦q⟧_σ
  & = ⟦sans("plug")(D_F, sans("quote")(D_F))]_σ \
  & ≃ ⟦F(sans("diag")(D_F))]_σ \
  & = ⟦F(q)⟧_σ.
$

Therefore $q$ is a behavioral fixed point of $F$. This is the same diagonal argument as in the natural-number proof, but the two levels that were collapsed into the natural-number notation are now visible: $D_F$ is a static source constructor, $sans("quote")(D_F)$ is code data, and $q$ is the closed program obtained by plugging the latter into the former.

The preceding construction does not require an object-level `Code Template`. One may represent a template externally as a pair of strings $(u, v)$ and define

$
  sans("plug")((u, v), c) = u dot sans("escape")(c) dot v.
$

This is merely a different representation of the same meta-level constructor. If the language has no effective syntax, serialization, and source transformation, then the source-string version of the recursion theorem is not justified. Conversely, if the theorem is required to be implemented entirely inside the language, some internal code representation and an evaluator (or an equivalent loader) must be added as an explicit assumption.

== Quines as an Instance

For every string $x in cal(P)$, let

$
  sans("emit")(x) in cal(P)
$

be a computably constructed program whose execution terminates, has no non-empty effect except text output, and satisfies

$
  sans("out")(⟦sans("emit")(x)⟧_(sigma_0)) = x.
$

In a concrete language, `emit(x)` is generated by quoting $x$ and placing it in a `print` expression. The argument $x$ is a meta-level source string; it is embedded before execution, not supplied as run-time input. Define the source transformation

$
  F(p) = sans("emit")(p).
$

By Kleene's theorem, there is a source string $q$ such that

$
  q approx sans("emit")(q).
$

Consequently,

$
  sans("out")(sans("interp")_(sigma_0)(q)) & = sans("out")(sans("interp")_(sigma_0)(sans("emit")(q))) \
                                           & = q.
$

Moreover, because $q$ and $sans("emit")(q)$ have the same effect behavior, the only non-empty effects of $q$ are text output. Thus $q$ satisfies the operational definition of a quine.

This formulation separates two facts that are easy to conflate:

+ Kleene's theorem supplies the behavioral fixed point $q approx F(q)$.
+ The chosen transformation $F(p) = sans("emit")(p)$ turns that behavior into the output equation $sans("out")(sans("interp")_(sigma_0)(q)) = q$.

The theorem does not say directly that every fixed point prints itself. It says that every effective program transformation has a behavioral fixed point; the `emit` transformation makes that fixed point a quine.

== From the Proof to a Quine Trick

The proof is already a construction algorithm. All operations in the following pseudocode are meta-level source-construction operations:

```text
fixed_point(F):
    define D_F[□]:
        q = diagonalize(□)
        execute(F(q))

    return plug(D_F, quote(D_F))

quine():
    return fixed_point(emit)
```

The notation $D_F[□]$ emphasizes that the slot is static: it is filled when the source string is constructed, before the resulting program starts. It is not a run-time input. The construction has two ingredients:

+ a static source constructor $D_F$ that describes what should be done with a diagonalized copy; and
+ a quotation-and-plugging step $sans("plug")(D_F, sans("quote")(D_F))$ that inserts the constructor's code representation into itself.

This explains the familiar Python program:

```python
s = 's = {!r}\nprint(s.format(s))'
print(s.format(s))
```

Let $T$ be the string assigned to `s`. This is an internal constant, not external input. Python's `!r` supplies a valid quoted source representation of its argument, and `.format` performs specialization. Thus

$
  q = T."format"(T)
$

is the complete two-line source string. When that source is run, it reconstructs the same value $T$ and evaluates the same specialization again, so its sole output is

$
  T."format"(T) = q.
$

In the abstract proof, $T$ plays the role of the quoted helper source $d$, and `T.format(T)` is the diagonal specialization $sans("diag")(D_F)$. The `print` operation implements `emit`.

The contrast with source reading is now precise. A source-reading program obtains $q$ through a runtime $sans("Read")$ or reflection effect. A classical quine uses a computable source transformation before execution so that the initial program already contains enough quoted data to reconstruct and emit $q$. Kleene's recursion theorem proves that this arrangement exists; its diagonal proof supplies the general quine trick.
