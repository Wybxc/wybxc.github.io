#import "/templates/post.typ": post
#show: post.with(
  title: "Polonius, a Formal Perspective",
  pubDate: datetime(year: 2026, month: 7, day: 21),
  draft: true,
)

= Polonius, a Formal Perspective

Recently, there has been exciting news that Polonius (the next‑generation borrow checker) is nearing stabilization
#footnote[The relevant project goal is #link("https://github.com/rust-lang/rust-project-goals/issues/118#issuecomment-4863622327")[here].] after six years of development since its initial proposal in 2018.

Although the implementation of Polonius will be transparent to most users, if you happen to care about the formalization of Rust as much as I do, you may want to understand how Polonius works#footnote[This is already well covered in #link("https://rust-lang.github.io/polonius/what_is_polonius.html")[Polonius's documentation], but it focuses more on implementation than theory.].
This article approaches Polonius's working principles from a formal perspective.

Overall, Polonius's goal is to replace the existing borrow checker so that it accepts more code that is semantically safe but syntactically rejected by the current borrow checker.
To achieve this goal, Polonius performs more precise _flow‑sensitive_ analysis.
It is precisely this flow sensitivity that inspired the key distinction in Polonius between loans and lifetimes, and this distinction, in turn, makes the formalization simpler and clearer.

== What are Lifetimes (from the Borrow Checker's Perspective)?

Rustaceans who frequently fight with the borrow checker all have their own opinions about lifetimes to some extent.
One simple way to understand them, as well as the original inspiration for lifetimes, is to think of a lifetime as the period during which a reference remains valid.
This mental model is so intuitive and easy to reason about informally that the error messages given by the borrow checker basically reflect this understanding.

// In reality, however, the concept of lifetimes is more complex.
// So, from the borrow checker's perspective, what are lifetimes and lifetime errors?

Consider the following code, which is rejected by the borrow checker because the reference `z` might point to the local variable `y`, and therefore cannot be returned from the function.

```rust
// error[E0515]: cannot return value referencing local variable `y`
fn foo(x: &i32) -> &i32 {
    let y: i32 = 42;
    let z: &i32 = if random() {
        &y  // `y` is borrowed here
    } else {
        &*x
    };
    z  // returns a value referencing data owned by the current function
}
```

How can the borrow checker detect this problem? The first step is to fill in the elided lifetime annotations#footnote[Strictly speaking, they cannot be called "elided" lifetimes, because the positions marked `'l1`, `'l2` below are not syntactically allowed in Rust; these appear only in the borrow checker's internal input.], as follows:

```rust
fn foo<'a>(x: &'a i32) -> &'a i32 {
    let y: i32 = 42;
    let z: &'b i32 = if random() {
        &'l1 *x
    } else {
        &'l2 y
    };
    z
}
```

Looking closely at this example, we can see that there are three kinds of lifetimes with different scopes and semantics.

- `'a` is an input lifetime; in other words, it is *universally quantified*. It indicates that the function `foo` should work no matter what `'a` is.
- `'b` is a local lifetime; it is *existentially quantified*. The reference `z` has some lifetime `'b`, but we don't know what it is. The borrow checker will infer `'b` based on the control flow of the function.
- `'l1` and `'l2` are also local lifetimes, but are determined by the borrow operations where they appear. In this example, `'l1` comes from a reborrow of `x`, so it can be as long as `'a`, while `'l2` comes from a borrow of a local variable, so it is limited to the scope of the function.

As input to the borrow checker, besides the additional lifetime annotations, there is also a set of subtyping constraints among the lifetimes. As with constraints in trait bounds, here `'b: 'a` indicates that `'b` is a subtype of `'a`, meaning that the period of time represented by `'b` must at least contain the period of time represented by `'a`.
In this example, we can derive the following constraints from the code:

- From assignments: because `z` is assigned either `&'l1 *x` or `&'l2 y`, we have `'l1: 'b` and `'l2: 'b`. Likewise, because `z` is assigned to the return value, we have `'b: 'a`.
- From the reborrow: because `&'l1 *x` is a reborrow of `x`, and `x` has type `&'a i32`, we have `'a: 'l1`.

Annotating the sources of these constraints in the code, we get:

```rust
fn foo<'a>(x: &'a i32) -> &'a i32 {
    let y: i32 = 42;
    let z: &'b i32 = if random() { // 'l1: 'b, 'l2: 'b
        &'l1 *x // 'a: 'l1
    } else {
        &'l2 y
    };
    z // 'b: 'a  => 'l2: 'b: 'a
}
```

Combining `'l2: 'b` and `'b: 'a`, we can derive `'l2: 'a`, which means the period of time represented by `'l2` must at least contain the period of time represented by `'a`. This is impossible because `'l2` is a local lifetime while `'a` is universally quantified and can be arbitrarily long.
Therefore, the borrow checker concludes that there is no possible value for `'b` that satisfies all the constraints, so the function `foo` is unsafe.

However, the above analysis of how the borrow checker works is still quite informal. If we dig deeper, some questions remain unanswered:
- What does it mean for the local lifetime `'b` to be existentially quantified? I said `'b` is inferred; but what is it inferred to be?
- What does it mean for `'l2` to be limited to the scope of the function? Is "function scope" a lexical scope or a set of program points? In what form does this restriction participate in constraint solving?
- Polonius is more precise due to its flow sensitivity. Although this example does not need flow sensitivity, how does it manifest in borrow checking in general?

为了回答这些问题，我们需要给lifetime一个更形式化的刻画。为此，需要引入loans的概念。

== Lifetimes are Sets of Loans

细心的读者可能已经发现了，在上面的三种lifetime中，`'l1`和`'l2`的命名规则有所不同。
这其实是一个文字游戏："l"在这里代表的不是"lifetime"，而是"loan"。

引入loan是为了区分lifetime的两项不同的语义：
- 一方面，lifetime表示一个period，它从borrow创建开始，直到reference不再使用，或者被borrow的地址被以其他方式使用，导致reference失效。
- 另一方面，lifetime之间存在subtyping关系。一个更长的lifetime可以视作一个更短的lifetime的subtype。

然而，这两种语义其实并非完全兼容。

```rust
fn foo(mut a: i32, mut b: i32) {
    let x = &mut a;
    let mut y = &mut b;
    a += 1;
    b += 1;
    y = x;
}
```
