---
date: 2024-01-08
---
Equational-based semantics 将函数的语义建模为**逐步化简的等式**。这种模式可用于实现 imperative 语言上的推理。

Isabelle/HOL 采用了 equational-based 处理函数定义[^2]，但他们没有扩展到 imperative 上。

例如，对于如下代码：

```c
list rev(list l) {
    list r = nil;
    while (l != nil) {
        r = list(l->head, r);
        l = l->next;
    }
    return r;
}
```

建模得到的语义为：

```c
rev(l) == rev_while(l, nil)
rev_while(l, nil) == l != nil ? rev_wt(l, r) : rev_wf(l, r)
rev_wt(l, r) == rev_wt_assign(l, list(l->head, r))
rev_wt_assign(l, r) == rev_while(l->next, r)
rev_wf(l, r) == r
```

未来可能考虑引入 lambda 语句块与 IIFE 类似的语法，例如：

```c
rev(l) == [list l = l, list r = nil] {
    while (l != nil) {
        r = list(l->head, r);
        l = l->next;
    }
    return r;
}

[list l, list r] {
    while (l != nil) {
        r = list(l->head, r);
        l = l->next;
    }
    return r;
} == l != nil ? [list l = l, list r = r] {
    r = list(l->head, r);
    l = l->next;
    while (l != nil) {
        r = list(l->head, r);
        l = l->next;
    }
    return r;
} : [list l = l, list r = r] { return r; }

// ...
```


[^2]: [Isabelle functions: Always total, sometimes undefined](https://www.joachim-breitner.de/blog/732-Isabelle_functions__Always_total,_sometimes_undefined)