---
date: 2025-04-09
---
## 语法

$$
\begin{align*}
\texttt{Stmt} &::= \text{skip} \\
&\phantom{::=}| \ \text{if } \texttt{Expr} \text{ then } \texttt{Stmt} \text{ else } \texttt{Stmt} \\
&\phantom{::=}| \ \text{while } \texttt{Expr} \text{ do } \texttt{Stmt} \\
&\phantom{::=}| \ \text{return } \texttt{Expr} \\
&\phantom{::=}| \ \text{let } x := \texttt{Expr} \\
&\phantom{::=}| \ x := \texttt{Expr}\\
&\phantom{::=}| \ \texttt{Stmt}; \texttt{Stmt} \\
\end{align*}
$$

## 翻译规则/指称语义

最直觉的规则：

$$
\begin{align*}
[[\text{skip}; s]] &= [[s]] \\
[[\text{if } (c) \text{ then } s_t \text{ else } s_e; s]] &= \text{if } [[c]] \text{ then } [[s_t;s]] \text{ else } [[s_e;s]] \\
[[\text{while } (c) \text{ do } s_t; s]] &= \text{if } [[c]] \text{ then } [[s_t;\text{while } (c) \text{ do } s_t; s]] \text{ else } [[s]] \\
[[\text{return } e]] &= [[e]] \\
[[\text{let } x := e; s]]\ \vec{p} &= [[s]]\ \vec{p}\ [[e]] \\
[[x := e; s]]\ \vec{p} &= [[s]]\ \vec{p}{\{x/[[e]]\}}
\end{align*}
$$

携带$env$（表示当前环境中的变量/参数）：
$$
\begin{align*}
[[\text{if } (c) \text{ then } s_t \text{ else } s_e; s]]_{env} &= 
\text{if } [[c]]_{env} \text{ then } [[s_t; s]]_{env} \text{ else } [[s_e; s]]_{env} \\

[[\text{while } (c) \text{ do } s_t; s]]_{env} &= 
\text{if } [[c]]_{env} \text{ then } [[s_t; \text{while } (c) \text{ do } s_t; s]]_{env} \text{ else } [[s]]_{env} \\

[[\text{return } e]]_{env} &= [[e]]_{env} \\

[[\text{let } x := e; s]]_{\vec{p}} &= [[s]]_{(\vec{p}, x)}\ \vec{p}\ [[e]]_{\vec{p}} \\

[[x := e; s]]_{\vec{p}} &= [[s]]_{\vec{p}}\ \vec{p}\{x/[[e]]_{\vec{p}}\}
\end{align*}
$$


## 处理语句块

语义中采用的模式为通过 `Seq` 连接语句，而实际的语言中使用语句块来表示多条语句。

$$
\begin{align*}
\texttt{BStmt} &::= \text{skip} \\
&\phantom{::=}| \ \text{if } \texttt{Expr} \text{ then } \texttt{BStmt} \text{ else } \texttt{BStmt} \\
&\phantom{::=}| \ \text{while } \texttt{Expr} \text{ do } \texttt{BStmt} \\
&\phantom{::=}| \ \text{return } \texttt{Expr} \\
&\phantom{::=}| \ \text{let } x := \texttt{Expr} \\
&\phantom{::=}| \ x := \texttt{Expr}\\
&\phantom{::=}| \ \left\{ \texttt{BStmt}* \right\} \\
\end{align*}
$$

转换模式：计算每条语句的第一条可执行语句和剩余的语句列表。对于嵌套语句块，直接展平。

$$
\begin{align*}
\textrm{head} :: [\texttt{BStmt}] \to \texttt{Stmt} \\
\textrm{tail} :: [\texttt{BStmt}] \to [\texttt{BStmt}] \\
\end{align*}
$$
于是翻译规则可以定义如下：
$$
\text{translate} \ S = \text{head}\ S; \text{translate} \ \text{tail}\ S
$$

### 块作用域

展平语句块后，块作用域的信息丢失了。我们需要在翻译时保留块作用域的信息。

```c
int x = 2;
{ int x = 1; }
return x;
```

对嵌套作用域内的变量提前重命名：

```ocaml
int x = 2;
{ int x' = 1; }
return x;
```

## 语句命名

带有语句命名的语法：

$$
\begin{align*}
\texttt{NStmt} &::= \langle name, \texttt{SStmt} \rangle \\
\texttt{SStmt} &::= \text{end} \\
&\phantom{::=}| \ \texttt{Stmt}; \texttt{NStmt} \\
\texttt{Stmt} &::= \text{if } \texttt{Expr} \text{ then } \texttt{NStmt} \text{ else } \texttt{NStmt} \\
&\phantom{::=}| \ \text{while } \texttt{Expr} \text{ do } \texttt{NStmt} \\
&\phantom{::=}| \ \text{return } \texttt{Expr} \\
&\phantom{::=}| \ \text{let } x := \texttt{Expr} \\
&\phantom{::=}| \ x := \texttt{Expr}\\
\end{align*}
$$

$$
\begin{align*}
\texttt{BStmt} &::= \text{skip} \\
&\phantom{::=}| \ \text{if } \texttt{Expr} \text{ then } \texttt{BStmt} \text{ else } \texttt{BStmt} \\
&\phantom{::=}| \ \text{while } \texttt{Expr} \text{ do } \texttt{BStmt} \\
&\phantom{::=}| \ \text{return } \texttt{Expr} \\
&\phantom{::=}| \ \text{let } x := \texttt{Expr} \\
&\phantom{::=}| \ x := \texttt{Expr}\\
&\phantom{::=}| \ \left\{ \texttt{BStmt}* \right\} \\
&\phantom{::=}| \ \texttt{Label}\ l: \texttt{BStmt} \quad \leftarrow \text{explicit label} \\
\end{align*}
$$

从语句块到带命名的语句的转换：

$$
\begin{align*}
\textrm{head} &:: [\texttt{BStmt}] \to \langle name:\text{string},\texttt{Stmt}\rangle + \text{end} \\
\textrm{tail} &:: [\texttt{BStmt}] \to [\texttt{BStmt}] \\
\textrm{translate} &:: [\texttt{BStmt}] \to \texttt{NStmt} \\
\end{align*}
$$

$$
\begin{align*}
\text{translate}\ S = \langle name, \left(head; \text{translate} \ \text{tail}\ S\right)\rangle &\quad \text{when}\ \text{head}\ S = \langle name, head \rangle\\
\text{translate}\ S = \langle \varnothing, \text{end}\rangle &\quad \text{when}\ \text{head}\ S = \text{end} \\
\end{align*}
$$

