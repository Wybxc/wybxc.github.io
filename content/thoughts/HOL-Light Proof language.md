---
tags: []
date: 2024-01-31
---
HOL light 遵循 LCF 架构，其证明语言描述了 Theorem 对象的构造过程。证明语言分为前向证明与后向证明两部分。

前向证明包含一系列用于构造和操作 Theorem 的函数，包括：

- Theorem：类型 `thm` 
- Inference rules (meta theorem)：类型 `X -> thm`
- Conversions：表示等价（重写）关系，类型 `type conv = term -> thm`
    - Conversionals：将 conversion 转为在 sub term 上进行，类型 `conv -> conv`

后向证明基于 goal stack 与 tactic 机制。goal stack 是 goal state 的列表，每个 goal state 表示一个证明目标。tactic 将一个 goal state 转化为其充分条件，并添加到 goal stack 顶部。

- 一般 tactic：类型 `tactic`
- Theorem-tactic：类型 `thm -> tactic`