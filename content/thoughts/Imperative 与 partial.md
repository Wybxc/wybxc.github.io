---
date: 2024-01-08
---
在使用归纳数据结构[^1]时，若需要访问其中的数据，有两种常见的方式：

1. **模式匹配**，类似 Rust 和 OCaml：
    - 这种方式通过匹配数据结构的模式，以确保在访问数据时的安全性。例如，在Rust中，使用 `match` 语句可以处理所有可能的变体，并且编译器会强制确保所有分支都被覆盖，以防止出现未处理的情况。
2. **直接引用字段**[^2]，类似传统的标记联合：
    - 这种方式允许直接引用数据结构中某个变体的字段，即通过字段名称直接访问。这是一种partial 操作，因为如果数据结构不是对应的变体，提取的值可能是无意义的。

然而，关于 partial 操作的推理问题尚未完全研究清楚，需要进一步的研究来准确定义这种语法的语义。

**模式匹配看似可以避免 partial，实则不然**。模式匹配需要引入很多额外的语法（如 Rust 的 `if let` 和 `while let` ），而且常常出现 unreachable 的分支。当程序走入 unreachable 的分支时，其语义同样是 partial 的。

```c
list rev(list l) {
    list r = nil;
    while (l != nil) {
        match (l) {
            case cons(_, tl): l = tl;
            default: unreachable();
        }
        // ...
    }
}
```

直观上，well-defined 的函数会通过 guard 条件避免走入未定义语义中，这能**将 partial 限制在局部**，避免从函数作用域中泄漏。关于 guard 条件如何起作用，是 partial reasoning 的研究之一。

[^1]: [[Imperative 的语法限制]]
[^2]: [[Equational-based semantics]] 中的例子写法