---
date: 2024-01-10
---
在逻辑计算框架（LCF）和高阶逻辑（HOL）之间，一个显著的变化是 HOL 强调全称性（totalness），而 LCF 则基于域理论（domain theory），需要为每一种类型指定一个最小值（bottom value）。例如，在 LCF 中，布尔类型必须具备表示未定义的 $\omega$ 值。这种情况导致了在 LCF 中，布尔类型的项（term）不能自然地转化为公式（formula）。

在 LCF 中，公式是通过偏序（domain partial order）推导出来的，以域上的等价关系作为基础，即 $t_{1} \equiv t_{2} := (t_{1}\sqsubseteq t_{2}, t_{2}\sqsubseteq t_{1})$ 。这里的等价和偏序都是元逻辑[^1]的连接词，而非逻辑内部的连接词，因此公式与项存在本质的差异。

而 HOL 则放弃了域理论，选择直接定义等号运算符 $\mathop{=} : \alpha \to \alpha \to \mathtt{bool}$ ，这样在 HOL 中，公式可以直接定义为布尔类型的项。这种变化简化了公式的定义和使用，提高了 HOL 的易用性和灵活性。

[^1]: [[逻辑系统和指称语义]]