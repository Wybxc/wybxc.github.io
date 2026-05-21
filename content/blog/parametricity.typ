#import "../../template.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#show: post.with(
  title: "Church Encoding, Parametricity, and the Yoneda Lemma",
  pubDate: datetime(year: 2026, month: 5, day: 19),
)

= Church Encoding, Parametricity, and the Yoneda Lemma

I still remember the shock I felt when I first encountered functional programming years ago. That was the moment I learned that natural numbers can be built within the language itself:

```hs
data Nat = Zero | Succ Nat
```

I went on to learn that all computation can be expressed through functions (the lambda calculus), that recursion itself can be encoded as the mesmerizing Y combinator:

```
Y = λf. (λx. f (x x)) (λx. f (x x))
```

And then there were Church numerals, where each number becomes a function:

```
0 = λs. λz. z
1 = λs. λz. s z
2 = λs. λz. s (s z)
```

Church encoding represents natural numbers as functions; each number $n$ takes a successor function and a starting point, then applies the successor $n$ times.

But what is the reasoning behind it? Why these particular lambda terms?

There is also Church encoding for lists:

```
nil  = λc. λn. n
cons = λx. λxs. λc. λn. c x (xs c n)
```

The pattern feels similar, but the details are different.
For a long time I assumed this was just how things were: a clever trick, rediscovered case by case.

It is after many years of learning that I finally understand the deeper story.
Church encoding manifests deep connections between data types, polymorphism, and category theory.
Once you see these connections, the shape of the encoding follows inevitably, and the result is more elegant than the trick itself.

In this article, I want to trace those connections. We'll start from the simplest data types in a typed setting, watch a pattern emerge, and gradually build up the machinery (parametricity, algebraic data types, F-algebras, and the Yoneda Lemma) until the Church encoding reveals itself as something the mathematics demands.

== System F

To capture the pattern behind Church encoding, we need types. The untyped lambda calculus gives us the terms, but it gives us no vocabulary to say _what_ those terms are.
That's the Simply Typed Lambda Calculus (STLC), where every term has a type. The only type constructor in bare STLC is the function arrow $A → B$#footnote[
  To be precise, STLC also includes some base types, like $mono("Unit"),$ $mono("Bool"),$ or $mono("Int");$
  otherwise you cannot give the parameter of the innermost function a type. But the particular choice of base types is irrelevant to the story; we just need something in the language to talk about.
].

But STLC hits a wall almost immediately. A Church numeral must accept *any* type as its carrier: the whole point is that $2$ works the same whether you're counting apples or functions. STLC can't say that. Every function in STLC has a fixed, monomorphic type.

This is where the experienced programmer sits up: we need *generics*. We need functions that are polymorphic over types. The calculus that gives us this is *System F*, the polymorphic lambda calculus.

Here's the idea. In System F, a function can take a type as an argument. You write type abstraction as $Λ X. med t$ and type application as $f med [X].$
Types of System F include type variables $X,$ function types $A → B,$ and universal quantification $∀X. med A.$#footnote[
  Unlike STLC, base types are not necessary in System F.
  The polymorphism alone gives us enough structure to build everything we need.
]

As you can see, our System F starts as an empty universe.
In STLC, we would declare base types like $mono("Unit")$ and $mono("Bool")$ to get started. But in System F, an interesting thing happens: we can build these types from scratch, using only functions and polymorphism! We can encode $mono("Unit")$ and $mono("Bool")$ as polymorphic functions, without any special syntax for data types.

Let me state a principle: a data type can be equivalently represented by the ways you consume it.
I cannot yet explain the logic behind this statement, but let's set it aside for now and see how it works for $mono("Unit").$
#footnote[In the second half of this article, we will ultimately understand the true meaning of this statement through the lens of category theory. Specifically, the Yoneda Lemma will show that the set of all ways to consume a type fully determines the type itself.]

If you're holding a value of type $mono("Unit"),$ what can you do with it? The only way to consume a $mono("Unit")$ value is to ignore it and return something that has nothing to do with it.

Suppose you want to write a universal consumer: for any target type $X,$ it turns a $mono("Unit")$ into an $X.$
Because we know nothing about $X,$ we cannot make up any new value of type $X.$ The only thing we can do is to return an $X$ that we already have. But where do we get an $X$ from? We don't have one! We should receive it as an argument.
Therefore, the type signature of a universal consumer of $mono("Unit")$ is:

$
  ∀X. med X → X
$

Read as: "for any type $X,$ give me an $X$ and I'll give you back an $X.$"

What is the inhabitant of this type? It is easy to think of one: the identity function.#footnote[
  Later we will see that this is the only possible implementation, as a consequence of parametricity.
] It takes an $X$ and returns it unchanged:

```
id = ΛX. λx. x
```

This function is the Church encoding of $mono("Unit").$

Let's try the same reasoning with $mono("Bool").$ $mono("Bool")$ has two constructors, $mono("True")$ and $mono("False").$

What does consuming a $mono("Bool")$ require? You need a target type $X,$ and you need an interpretation for $mono("True")$ and one for $mono("False"),$ two values of type $X.$ Then, depending on which constructor the actual $mono("Bool")$ value represents, you return the appropriate interpretation.

As a type signature:

```
∀X. X → X → X
```

Read as: "for any type $X,$ give me two $X$s and I'll give you back an $X.$"

We can find two inhabitants of this type, which correspond to the two ways to consume a $mono("Bool"):$

```
true  = ΛX. λx. λy. x
false = ΛX. λx. λy. y
```

One chooses the first argument, the other chooses the second. They correspond exactly to the two values of $mono("Bool").$

Looking at these two examples, a pattern emerges:

To summarize the pattern so far: the Church encoding of a data type in System F is a polymorphic function whose arguments match the constructors. It is a universal consumption interface for the type.
This investigation works perfectly for $mono("Unit")$ and $mono("Bool"),$ whose constructors carry no data. But what about a type like the $mono("Nat")$?
Its $mono("Succ")$ constructor has a recursive parameter.
We will talk about how to handle that in the following sections, but before we do, we need to understand the mechanism that makes the pattern work in the first place.

== Parametricity

What is truly remarkable is that for $∀X. med X → X,$ we can only find a single implementation, the identity function.
Likewise, for $∀X. med X → X → X,$ we can only find two implementations, `true` and `false`.
The type system of System F does not permit any other implementations.

Once you have convinced yourself of the fact, let's move on.

To understand *why* the type system restricts the inhabitants so precisely, we need to examine the mechanism behind System F's polymorphism.
The polymorphism in System F is *parametric*: a polymorphic function gets a type argument, but it can't inspect it. It can't branch on "am I dealing with Int or Bool?" It must treat the type as a black box. That restriction turns out to be the source of enormous power.

John Reynolds proved the *parametricity theorem* (also called the *abstraction theorem*) in 1983. Here is a compact statement:

#quote(block: true)[
  Let $f : ∀X. med τ(X)$ be a closed term of System F, where $τ(X)$ is a type expression. For any types $A, B$ and any relation $R ⊆ A × B,$ let $τ(R) ⊆ τ(A) × τ(B)$ be the relational lifting defined recursively from the structure of $τ.$ If $(a, b) ∈ τ(R)$ then $(f med [A] med a, f med [B] med b) ∈ τ(R).$
]

That formulation may look abstract, but its core message is simple: a polymorphic function must "preserve" whatever relation you associate with the type parameter.
It cannot detect the concrete structure of the type it's instantiated with.
A consequence is that you can derive equations the function must satisfy purely from its type signature, regardless of implementation. Philip Wadler later called these "theorems for free."

Let's begin with a special case you can verify by hand.

*Claim*: $∀X. med X → X$ has only the identity function, i.e., any $f : ∀X. med X → X$ must satisfy $f med [A] med a = a$ for all $A$ and $a.$

*Proof*: Let's see what parametricity has to say about $f : ∀X. med X → X.$ Take two arbitrary types $A$ and $B,$ and pick any relation $R ⊆ A × B$ between them. The theorem requires us to lift $R$ through the type expression $τ(X) = X → X.$ Here's how the lifting works: two functions $h_A : A → A$ and $h_B : B → B$ are related by $τ(R)$ precisely when they map $R$-related inputs to $R$-related outputs, that is, $(h_A (x), h_B (y)) ∈ R$ whenever $(x, y) ∈ R.$ Intuitively, $h_A$ and $h_B$ preserve $R$ in lockstep.

Now, parametricity says: because $f$ is polymorphic, its instantiations at $A$ and $B$ must be related by this lifted relation. In symbols: $(f med[A], f med[B]) ∈ τ(R).$ Spelling that out: for any $(x, y) ∈ R,$ we have $(f med[A] med x, f med[B] med y) ∈ R.$

Here comes the trick. Fix a type $A$ and a value $a : A.$ Our goal is to show $f med[A] med a = a.$ Define a very specific relation:

$
  R = {(a, a)} ⊆ A × A
$

This relation pairs $a$ with itself and nothing else. Take $B = A.$ Since $(a, a) ∈ R,$ the parametricity condition forces:

$
  (f med[A] med a, f med[A] med a) ∈ R
$

But $R$ contains exactly one pair: $(a, a).$ So $f med[A] med a$ must be $a.$ Done.

Notice what just happened: parametricity forced $f$ to be the identity function, even though $f$ knows absolutely nothing about the type it's applied to. The type signature alone left it no other choice.

A similar argument works for $∀X. med X → X → X.$ A function of this type receives two values of an unknown type $X$ and must return an $X.$ With no operations available on $X,$ the only possible behaviors are "always return the first argument" or "always return the second." That's `true` and `false`.#footnote[A formal proof follows the same relational strategy, using $R = {(a, a), (b, b)}$ for two distinct values $a, b : A.$]

Now for the payoff. What does parametricity say about the general shape $f : ∀X. med (F med X → X) → X$? Here $F$ is any type operator; think of it as describing the structure of a data type. The free theorem we get is this: for any F-algebra homomorphism#footnote[
  We will explain what an F-algebra homomorphism is later.
] $h : (A, f_A) → (B, f_B),$

$
  h med (f med [A] med f_A) = f med [B] med f_B
$

This equation will play a central role later when we prove that Church encoding is equivalent to the data type it encodes.

== Algebraic Data Types and Functors

With parametricity in our toolkit, we now return to the main thread. Recall where we left off: $mono("Unit")$ and $mono("Bool")$ revealed a pattern (the Church encoding is a polymorphic function whose arguments match the constructors), but we had no way to handle recursive types like $mono("Nat").$ To extend the pattern, we need a systematic language for describing the structure of data types, which makes the structure of constructors and their arguments explicit. This is where *algebraic data types* (ADT) enter the picture.

We know that tuples are *product types* and tagged unions are *sum types*. An algebraic data type is built from these two operations, fundamentally, as a *sum of products*. Each constructor is a product of its fields; the whole type is the sum among constructors. If a constructor carries no data, it is the empty product, i.e., the $mono("Unit")$ type.

We can make this precise with a small algebraic notation:

- $1$ (the unit type, $mono("Unit")$): a type with exactly one value. It is the identity of the product: $1 × A ≅ A.$
- $A + B$ (the sum type): a value is either an $A$ or a $B,$ tagged with the choice.
- $A × B$ (the product type): a pair of an $A$ and a $B.$

Under this notation:

$
  mono("Unit") & = 1 \
  mono("Bool") & = 1 + 1 \
   mono("Nat") & = 1 + mono("Nat")
$

The last line reads: a natural number is either $mono("Zero")$ (the $1$ branch, carrying no information) or $mono("Succ")$ (wrapping another $mono("Nat")$). The equation is recursive, and we make sense of it with the $μ$ binder:

$
  mono("Nat") = μ X. med 1 + X
$

The same recipe works for lists:

$
  mono("List")(a) = μ X. med 1 + a × X
$

Here, $mono("Nil")$ is the $1$ branch and $mono("Cons")$ is the $a × X$ branch.

But the algebra goes deeper than notation. Types surprisingly obey the familiar laws of algebra.
For example, the distributivity law:

$
  a × (b + c) ≅ a × b + a × c
$

Here $≅$ denotes type isomorphism: there exist functions witnessing the equivalence in both directions.

Read the law as types: `(a, Either b c)` is isomorphic to `Either (a, b) (a, c)`. As evidence, we can write the following functions:

```hs
f :: (a, Either b c) -> Either (a, b) (a, c)
f (a, Left b)  = Left  (a, b)
f (a, Right c) = Right (a, c)

g :: Either (a, b) (a, c) -> (a, Either b c)
g (Left (a, b))  = (a, Left b)
g (Right (a, c)) = (a, Right c)
```

What about function types? Can we express them in terms of algebraic operations?

Let me declare: *functions are exponents.* Consider two finite types $A$ and $B,$ with $|A|$ and $|B|$ inhabitants respectively. How many functions $A → B$ exist? For each input $a ∈ A,$ we can independently choose any output $b ∈ B.$ That's $|B|$ choices repeated $|A|$ times: $|B|^(|A|)$ possibilities. This suggests writing the function type as an exponential:

$
  A → B ≅ B^A
$

Currying then becomes the familiar exponent law:

$
  C^(A × B) ≅ (C^B)^A
$

And functions out of sums follow their own distributive law:

$
  C^(A + B) ≅ C^A × C^B
$

Now let's return to the Church encoding of natural numbers. We have seen Church numerals in untyped lambda calculus:

```
0 = λs. λz. z
1 = λs. λz. s z
2 = λs. λz. s (s z)
```

We want to give them types in System F. Assume the type of `z` is $X.$
We expect the type of `0` and `1` to be the same, so term `s z` should have the same type as `z`. Therefore, `s` must have type $X → X.$
That gives us the Church encoding type for natural numbers:

$
  "ChurchNat" = ∀X. med X → (X → X) → X
$

It looks somewhat different from the Church encoding types for `Unit` and `Bool`.
The second argument is a function rather than a value.
Is there a single shape that captures all of them?

Let's inspect the inner part of the encoding more closely.

Currying tells us that a function $X → (X → X) → X$ is equivalent to a function $(X, X → X) → X.$
And we already know that the tuple $(A, B)$ can be written as $A × B,$ and the function type $A → B$ can be written as $B^A.$
Then we can do some algebraic manipulation:

$
              & X → (X → X) → X \
  tilde.equiv & X × X^X -> X \
  tilde.equiv & X^(1+X) -> X \
  tilde.equiv & ((1 + X) → X) → X
$

So the full Church encoding becomes:

$
  "ChurchNat" tilde.equiv ∀X. med ((1 + X) → X) → X
$

Now look at the expression $1 + X.$ That is precisely the body of the recursive type definition of $mono("Nat") = μ X. med 1 + X.$ In other words, the Church encoding is of the form:

$
  ∀X. med (F med X → X) → X quad "where" F med X = 1 + X
$

Here, $F$ is a *functor* that captures the shape of the algebraic data type.
Let's check that this holds for our earlier examples:

- For $mono("Unit"):$ the functor is $F med X = 1.$ Then $(F med X → X) → X = (1 → X) → X ≅ X → X.$ Matches $∀X. med X → X.$
- For $mono("Bool"):$ the functor is $F med X = 1 + 1.$ Then $(F med X → X) → X = (1 + 1 → X) → X ≅ (X × X) → X ≅ X → X → X.$ Matches $∀X. med X → X → X.$

Here we get the general pattern: for an algebraic data type $T = μ X. med F med X,$ its Church encoding is $∀X. med (F med X → X) → X.$

In the next section we will see that the Church encoding $∀X. (F med X → X) → X$ is the type of universal consumers of *F-algebras*, and this is the perspective that will lead us, via parametricity and the Yoneda Lemma, to the deepest understanding of what Church encoding really is.

== F-Algebra

We've arrived at a turning point. The last section ended with a shape, $∀X. med (F med X → X) → X,$ that unifies the Church encodings of $mono("Unit"),$ $mono("Bool"),$ and $mono("Nat")$ under one roof. But the shape still feels pulled from thin air. Why this particular arrangement of symbols? To answer that, we need to give names to the pieces. This is where category theory enters.

Let's start small. A *category* is a collection of objects and arrows between them, with sensible rules for _composition_ and _identity_. For a programmer, the natural example is the category $bold("Set"):$ objects are types, arrows are functions, composition is function composition, and the identity arrow is `id`.

A *functor* $F$ is a mapping between categories. In our world, $F$ maps each type $A$ to a type $F med A,$ and each function $f : A → B$ to a function $F med f : F med A → F med B,$ preserving composition and identity:

$
  F med (g ∘ f) & = F med g ∘ F med f \
     F med "id" & = "id"
$

This is exactly what the $F$ in $F med X = 1 + X$ has been doing all along: it builds a new type from an old one, *and* it lifts functions to act inside that structure.#footnote[For $mono("NatF"),$ given $f : X → Y,$ $mono("NatF") med f$ maps $mono("Left") med ()$ to $mono("Left") med ()$ and $mono("Right") med x$ to $mono("Right") med (f med x).$] This function-lifting is the machinery behind structural recursion; we'll return to it when we define folds.

A *natural transformation* $η$ between two functors $F$ and $G$ is a way of turning $F$ shapes into $G$ shapes, uniformly for all types. For each type $X,$ you have an arrow $η_X : F med X → G med X,$ and for every function $h : X → Y$ the following square commutes:

#center(invert(render(diagram(
  cell-size: 14mm,
  $F med X edge("r", F med h, ->) edge("d", eta_X, ->) & F med Y edge("d", eta_Y, ->) \
  G med X edge("r", G med h, ->) & G med Y$,
))))

That is, $η_Y ∘ F med h = G med h ∘ η_X.$ This is *naturality*: the transformation must work the same way no matter which object you look at. Here's the connection that makes all of this tick: the free theorems we got from parametricity are naturality conditions in disguise. A polymorphic function in System F is a natural transformation when viewed through the right categorical lens. Parametricity and naturality are two sides of the same coin.

With these three concepts, category, functor, natural transformation, we finally have the language to name the pattern that has been staring at us since the very beginning. An *F-algebra* is a triple $⟨F, X, f⟩$ consisting of a functor $F,$ a carrier type $X,$ and a function $f : F med X → X.$

Intuitively, $f : F med X → X$ is an *evaluator* that folds the structure described by $F$ into a single value of type $X.$
For example, the functor of natural numbers is $mono("NatF") med X = 1 + X.$ An F-algebra for this functor consists of a type $X$ and a function $f : 1 + X → X.$
By algebraic manipulation, this becomes a pair of functions $(z : X, s : X → X),$ where

- $z = f med (mono("Left") med ())$ gives what the zero value evaluates to, and
- $s med n = f med (mono("Right") med n)$ maps the evaluation of $n$ to the evaluation of its successor.

For $mono("BoolF") med X = 1 + 1,$ a $mono("BoolF")$-algebra is simply two values of type $X:$ the algebra map $f : 1 + 1 → X$ corresponds to a pair $(x_1 : X, x_2 : X),$ where $x_1$ evaluates `true` and $x_2$ evaluates `false`.

The Church encoding type $∀X. med (F med X → X) → X$ now acquires a precise meaning: it is a *universal consumer of F-algebras*: given any F-algebra $⟨F, X, f⟩,$ it takes the evaluator $f : F med X → X$ and runs it on the conceptual structure of the data type to produce a value of type $X.$ It makes rigorous the "consumption interface" idea introduced earlier.

F-algebras for a fixed functor $F$ themselves form a category. An arrow in this category is called an *F-algebra homomorphism*. If $⟨F, A, f⟩$ and $⟨F, B, g⟩$ are two F-algebras, a homomorphism between them is a function $h : A → B$ that preserves the algebraic structure:

$
  h ∘ f = g ∘ F med h
$

In diagram form:

#center(invert(render(diagram(
  cell-size: 14mm,
  $F med A edge("r", f, ->) edge("d", F med h, ->) & A edge("d", h, ->) \
  F med B edge("r", g, ->) & B$,
))))

The condition says: evaluating a structure in $A$ and then translating the result to $B$ yields the same value as translating the sub-structure to $B$ first and then evaluating in $B.$ The two paths through the square produce the same result.

For example, for $mono("NatF") med X = 1 + X,$ the homomorphism condition becomes:

$
        h med (z_A) & = z_B \
  h med (s_A med a) & = s_B med (h med a)
$

These two equations are exactly the pattern that any structural recursion must obey: the base case maps to the base case, and the recursive case applies $h$ to the predecessor and then the successor function.

== Initial Algebra

Among the F-algebras for a given functor $F,$ one deserves special attention.
In a category, an *initial object* satisfies the *initiality* property: there is a unique arrow from it to every other object. In the category of F-algebras, the initial object is called the *initial algebra*, written $⟨F, μ F, mono("in")⟩,$ where $μ F$ is the carrier and $mono("in") : F(μ F) → μ F$ is the structure map.

By initiality, for any F-algebra $⟨F, X, f⟩,$ there is exactly one homomorphism from $⟨F, μ F, mono("in")⟩$ to it. We call it $mono("fold") med f : μ F → X.$

To get an intuitive grasp of what the initial algebra is, let's look at the type of $mono("fold")$ in System F.
It takes an evaluator $f : F med X → X$ and returns a function $mono("fold") med f : μ F → X.$
So its type signature is $∀X. med (F med X → X) → μ F → X.$

Compare this with the Church encoding type: $mono("ChurchF") = ∀X. med (F med X → X) → X.$
They are almost identical. The only difference is that $mono("fold")$ has an extra $μ F →$ tucked before the final $X.$ Where Church encoding takes an algebra and produces an $X,$ fold takes an algebra _and_ a $μ F$ value to produce an $X.$

This suggests a natural way to move between $μ F$ and $mono("ChurchF").$
Given $x : μ F,$ we can partially apply $mono("fold")$ to get a Church encoding: $Λ X. λ f. mono("fold") med f med x : mono("ChurchF").$
Conversely, given $c : mono("ChurchF"),$ we can feed it the initial algebra's own structure map: $c med [μ F] med mono("in") : μ F.$
These two maps point at each other: one wraps a $μ F$ value into a universal consumer, the other unwraps a universal consumer by running it on the initial algebra itself. We will prove shortly that they are inverses, establishing $mono("ChurchF") ≅ μ F.$

Before we do, we still need to understand what $μ F$ actually is. For that we return to initiality.
Take the object $F(μ F)$ and turn it into an F-algebra by using $F(mono("in")) : F(F(μ F)) → F(μ F)$ as the structure map. By initiality, we get a unique homomorphism from $⟨F, μ F, mono("in")⟩$ to this new algebra; call it $g : μ F → F(μ F).$ But $mono("in")$ itself is a homomorphism in the opposite direction: $F(μ F) → μ F.$ Compose the two: $mono("in") ∘ g$ is a homomorphism from $μ F$ to itself. Initiality says there is exactly one such homomorphism, namely $mono("id"),$ so $mono("in") ∘ g = mono("id").$ The same argument on the other side gives $g ∘ mono("in") = mono("id").$ So $mono("in")$ and $g$ are inverses: $mono("in")$ is an isomorphism.

This is *Lambek's theorem*: $F(μ F) ≅ μ F.$
The carrier of the initial algebra is the recursive type $μ X. med F med X.$
That is why we choose the notation $μ F.$

Now that we know $μ F$ is a recursive type, the role of the structure map $mono("in")$ becomes clear.
It is a constructor that builds the recursive type from its components.
Take $mono("Nat")$ as an example, $mono("in") : 1 + mono("Nat") → mono("Nat")$ has two cases:
- $mono("Left") ()$ means no predecessor: $mono("in")$ returns $mono("Zero");$
- $mono("Right") n$ means one predecessor $n$ already built: $mono("in")$ returns $mono("Succ") n.$

The fold equation now also becomes concrete. An algebra $⟨F, X, f⟩$ expands to a pair $(z : X, s : X → X),$ and the equation $mono("fold") med f ∘ mono("in") = f ∘ F(mono("fold") med f)$ becomes:

$
  mono("fold") med f med (mono("Zero")) &= z \
  mono("fold") med f med (mono("Succ") n) &= s med (mono("fold") med f med n)
$

This is structural recursion: replace every $mono("Zero")$ with $z,$ every $mono("Succ")$ with an application of $s$ to the recursively processed predecessor. The fold walks through the value from the bottom up, substituting each constructor with the algebra's interpretation.

One more consequence of initiality: $mono("fold") med mono("in") = mono("id").$ Since $mono("id")$ is a homomorphism from the initial algebra to itself, and initiality says there can only be one, the fold at the initial algebra's own structure map must be the identity. This equation will unlock the entire proof.

Now step back. $mono("in")$ builds values from nothing. $mono("fold")$ takes those values and interprets them in any algebra you choose, uniquely. One end generates; the other end consumes. This combination is what we call a *universal producer*.

The Church encoding $mono("ChurchF") = ∀X. med (F med X → X) → X$ is the mirror image: it takes any algebra and returns a value: a *universal consumer*. Universal producer meets universal consumer.

They are.

Let's prove $mono("ChurchF") ≅ μ F.$
We define two functions between them in System F, and show that they are inverses of each other:

```
fromChurch : ChurchF → μ F
fromChurch c = c [μ F] in

toChurch : μ F → ChurchF
toChurch x = ΛX. λ(f : F X → X). fold f x
```

$mono("fromChurch")$ feeds the initial algebra to the universal consumer. $mono("toChurch")$ takes a concrete value and turns it into a consumer by folding over any algebra you give it.

*Step one:* $mono("fromChurch") ∘ mono("toChurch") = mono("id").$ For any $x : μ F:$

$
    & mono("fromChurch") med (mono("toChurch") med x) \
  = & mono("toChurch") med x med [μ F] med mono("in") \
  = & mono("fold") med mono("in") med x \
  = & x
$

*Step two:* $mono("toChurch") ∘ mono("fromChurch") = mono("id").$

We need to show that for any $c : mono("ChurchF"),$ any $X,$ and any $f : F med X → X:$

$
  mono("fold") med f med (c med [μ F] med mono("in")) = c med [X] med f
$

This is where parametricity earns its keep. Remember the free theorem we derived: for any F-algebra homomorphism $h : (A, f_A) → (B, f_B),$

$
  h med (c med [A] med f_A) = c med [B] med f_B
$

Now let $A = μ F,$ $f_A = mono("in"),$ $B = X,$ $f_B = f,$ and $h = mono("fold") med f.$ Since $mono("fold") med f$ is an algebra homomorphism, the free theorem applies directly:

$
  mono("fold") med f med (c med [μ F] med mono("in")) = c med [X] med f
$

That's the equality we needed. Both directions are inverses, so $mono("ChurchF") ≅ μ F.$

Notice what just happened. Two completely independent ideas: the uniqueness of the fold from the initial algebra, and the free theorem from parametricity, interlocked to deliver the isomorphism. Together they're airtight.

We've proved the isomorphism. But a question lingers: *why* this shape? Why $∀X. med (F med X → X) → X$ of all things? We arrived at it by following our noses through $mono("Unit"),$ $mono("Bool"),$ $mono("Nat"),$ and a bit of algebra. That's a fine derivation, but it doesn't explain why the shape *must* be what it is. For that, we turn to what is arguably the _most beautiful_ theorem in category theory.

== The Yoneda Lemma

Before stating the lemma, one more piece of vocabulary. The *Hom-functor* $sans("Hom")(A, −)$ embodies "the view from $A.$" For any object $X,$ $sans("Hom")(A, X)$ is the set of all arrows from $A$ to $X,$ which in the $bold("Set")$ category is just the function type $A → X.$ Given a function $g : X → Y,$ the Hom-functor maps it by post-composition: $sans("Hom")(A, g) = λ h. med g ∘ h.$ It's the formal way of saying "everything you can do with an $A.$"

Now the Yoneda Lemma:

#quote(block: true)[
  For any (locally small) category $cal(C),$ any object $A$ in $cal(C),$ and any $bold("Set")$-valued functor $F : cal(C) → mono("Set"),$ there exists a bijection:

  $
    sans("Nat")(sans("Hom")(A, −), med F) ≅ F(A)
  $

  The left side is the set of natural transformations from $sans("Hom")(A, −)$ to $F;$ the right side is the value of $F$ at $A.$ This bijection is natural in both $A$ and $F.$
]

Underneath the imposing formalism lives a disarmingly simple idea. A natural transformation from $sans("Hom")(A, −)$ to $F$ is completely determined by a single choice: where you send $mono("id")_A.$ Pick any element of $F(A)$ as the image of $mono("id")_A,$ and naturality does the rest; it uniquely transports that choice to every other object. Conversely, given a natural transformation, applying it to $mono("id")_A$ at $A$ picks out an element of $F(A).$ That's the whole correspondence.

Think about what this means. The Hom-functor captures everything you can arrow out of $A,$ the "outward view" of $A.$ Yoneda says this outward view *completely determines* $A$ itself. Sound familiar? It's the categorical incarnation of our consumption-interface principle: a type is fully characterized by how you can consume it.

Let's try a concrete case. Set $F$ to the identity functor $mono("Id")$ where $mono("Id")(X) = X$ and $cal(C)$ to the $bold("Set")$ category. The Yoneda lemma specializes to:

$
  sans("Nat")(sans("Hom")(A, −), med mono("Id")) ≅ A
$

Now unpack the left side. $sans("Hom")(A, X)$ is $A → X.$ A natural transformation $η : sans("Hom")(A, −) → mono("Id")$ is a family of functions $η_X : (A → X) → X,$ one for each $X.$
So $η$ is necessarily a polymorphic function in System F.
Its type is $∀X. med (A → X) → X.$
So $∀X. med (A → X) → X ≅ A.$
Yoneda gives us the isomorphism directly.

For $A = mono("Unit"),$ this says $∀X. med (mono("Unit") → X) → X ≅ mono("Unit"),$ which simplifies to $∀X. med X → X ≅ mono("Unit").$ For $A = mono("Bool"),$ we get $∀X. med X → X → X ≅ mono("Bool").$ These are exactly the Church encodings we derived by hand. Now they fall out of Yoneda for free.

But there's a catch. This only works for non-recursive types: $A$ is a fixed type, not a recursive definition. To capture $mono("Nat")$ and $mono("List"),$ we need to level up.

Here's the move. Instead of the category of types, we work in the *category of F-algebras*. The objects are F-algebras $⟨F, X, f⟩,$ and the arrows are homomorphisms. In this category, the initial algebra $⟨F, μ F, mono("in")⟩$ is a distinguished object. Its Hom-functor $sans("Hom")(⟨F, μ F, mono("in")⟩, −)$ maps any algebra $⟨F, X, f⟩$ to the set of homomorphisms from the initial algebra to it. By initiality, that set contains exactly one element: $mono("fold") med f.$

Now introduce the *forgetful functor* $U,$ which takes an algebra $⟨F, X, f⟩$ and discards the structure, keeping only the carrier $X.$ It's a functor from the F-algebra category to $bold("Set")$ category.

Apply Yoneda with $cal(C)$ as the category of F-algebras, $A = ⟨F, μ F, mono("in")⟩,$ and $F = U:$

$
  sans("Nat")(sans("Hom")(⟨F, μ F, mono("in")⟩, −), med U) ≅ U(⟨F, μ F, mono("in")⟩) = μ F
$

Let's decode the left side. A natural transformation here gives, for each F-algebra $⟨F, X, f⟩,$ a function from $sans("Hom")(⟨F, μ F, mono("in")⟩, ⟨F, X, f⟩)$ to $X.$ But that Hom-set is a singleton, it contains only $mono("fold") med f.$ So specifying this function is equivalent to picking a value of type $X$ for each algebra. Let's call it $c med [X] med f.$ The naturality condition, with the algebra homomorphisms as arrows, becomes exactly:

#quote(block: true)[
  For any algebra homomorphism $h : ⟨F, X, f⟩ → ⟨F, Y, g⟩,$
  $h med (c med [X] med f) = c med [Y] med g.$
]

So the inhabitants of $mono("ChurchF")$ correspond precisely to the natural transformations on the left side of the Yoneda bijection. By Yoneda, they are in one-to-one correspondence with $μ F.$ Therefore $mono("ChurchF") ≅ μ F.$
Put another way: the universal shape of Church encoding, $∀X. med (F med X → X) → X,$ is a direct translation of "the Yoneda representation of the initial algebra over the forgetful functor."

This is the full picture. The Church encoding is Yoneda in disguise. $∀X. med (F med X → X) → X$ is the left side of the Yoneda bijection for the initial algebra over the forgetful functor. Yoneda guarantees it's isomorphic to $μ F.$ The shape is inevitable.

And here's the deepest revelation: parametricity and Yoneda are the same idea in two different languages. The free theorem $h med (c med [A] med f_A) = c med [B] med f_B$ is the Yoneda naturality square, instantiated in the category of F-algebras. The key proof step $mono("fold") med mono("in") = mono("id")$ is Yoneda's central move: determining the entire natural transformation from a single choice at $mono("id").$#footnote[The two proofs run in strict parallel: the step $mono("fold") med f med (c med [μ F] med mono("in")) = c med [X] med f$ is the naturality square applied to the homomorphism $mono("fold") med f;$ $mono("fold") med mono("in") = mono("id")$ corresponds to Yoneda's key step where $mono("id")$ determines the entire transformation. One path lives inside the type system; the other stands at a higher categorical vantage point. They are two views of the same structure, mutually reinforcing.] Parametricity is the type-theoretic shadow of categorical naturality.

== The Final Recap

We can now see the whole arc. Church encoding begins with a simple intuition: a data type can be replaced by the way you consume it. From $mono("Unit")$ and $mono("Bool"),$ this yields types like $∀X. med X → X$ and $∀X. med X → X → X.$ To handle recursive types, we introduce functors $F$ that describe a data type's one-layer structure, unifying all Church encodings under a single shape: $∀X. med (F med X → X) → X.$

At this point the pieces start locking together. The inner part $F med X → X$ is an *F-algebra*, and the Church encoding is the universal consumer of F-algebras: it takes any algebra and produces a value. Among all F-algebras, the initial algebra $μ F$ (the recursive data type itself) plays a special role: its unique fold operation gives us $mono("fold") med mono("in") = mono("id").$ Meanwhile, parametricity forces polymorphic functions to behave as natural transformations, yielding the free theorem $h med (c med [A] med f_A) = c med [B] med f_B.$ These two facts (one from initiality, one from parametricity) interlock cleanly to prove that Church encoding is isomorphic to the original data type: $∀X. med (F med X → X) → X ≅ μ F.$

The Yoneda Lemma reveals why the shape must be exactly this. Applied in the category of F-algebras, Yoneda states that the natural transformations from the Hom-functor out of the initial algebra to the forgetful functor are isomorphic to $μ F$ itself; and those natural transformations are precisely the inhabitants of $∀X. med (F med X → X) → X.$ The Church encoding is thus a direct consequence of one of category theory's most fundamental results. Parametricity and Yoneda are two views of the same structure: both rest on naturality, and one is the type-theoretic shadow of the other.

Returning to the Church numeral $λ s. med λ z. med s med (s med z):$ it can now be understood as the Church representation of the initial algebra for the functor $mono("NatF").$ Church encoding remains an elegant tool in programming, and its shape can be traced along a repeatable path from the consumption intuition all the way to the deep structure of category theory.

#bibliography("references.bib")
