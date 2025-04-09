---
date: 2024-01-09
---
Tagged union 可用于实现归纳数据结构[^1]。

C 语言的 tagged union 语法如下：

```c
struct either {
    enum { left, right } tag;
    union {
        int i;
        float f;
    } u;
};
```

C 语言的语义没有对 tagged union 做出保证，即不保证 tag 与变体是一一对应的。

Rust 没有采用显式的 tagged union，而是采用更接近函数式 ADT 的语法：

```rust
enum Either {
    Left(i32),
    Right(f32),
}
```

Zig 的 tagged union 介于二者之间，它在 C 的基础上保证了 tag 与变体的对应：

```c
const Either = union(enum { left, right }) {
    i: i32,
    f: f32,
}
```

[^1]: [[Imperative 的语法限制]]