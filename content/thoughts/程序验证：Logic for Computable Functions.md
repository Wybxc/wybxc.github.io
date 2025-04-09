---
date: 2024-01-06
---
## 类型系统

LCF 是一种类型化的逻辑系统。

一个 LCF 系统包含基本类型集合 $BT$，其中至少包含一个类型 $\mathtt{bool}$。在此基础上，递归地定义 LCF 的类型系统 $T$：

1. 基本类型 $\tau$ 是 LCF 的类型；
2. 函数类型 $\tau_1,\tau_2,\ldots,\tau_n\to\tau$ 是 LCF 的类型，其中 $\tau_i$ 与 $\tau$ 均为 LCF 的类型。

## λ-基本集

LCF 的 λ-基本集（basis）是如下的三元组：

1. 基本类型集合 $BT$；
2. 自由变量（variable）集合 $V$。自由变量是名称和类型的二元组。类型 $\tau$ 的自由变量集合记作 $V_\tau$，假定对于每个类型 $\tau$，$V_\tau$ 中可用的变量有无限多。
3. 符号（function symbol）集合 $F$。符号也是名称与类型的二元组。$F$ 至少包含：
   1. $\mathrm{TT}$ 与 $\mathrm{FF}$，其类型为 $\mathtt{bool}$，分别表示 true 和 false；
   2. $\mathrm{UU_\tau}$，对每个类型 $\tau$，其类型为 $\tau$，表示该类型的未定义值。当不至于混淆时，可记作 $\mathrm{UU}$。
   3. $\mathrm{ITE}_\tau$，对每个类型 $\tau$，其类型为 $\mathtt{bool},\tau,\tau\to\tau$，表示条件判断。同上记作 $\mathrm{ITE}$。
   4. $\mathrm{MM}_\tau$，对每个类型 $\tau$，其类型为 $(\tau\to\tau)\to\tau$，表示不动点算子。同上记作 $\mathrm{MM}$。

以上记作 $B=(BT, V, F)$。

## 语法

如下递归地定义 LCF 项（term）的语法：

1. 类型为 $\tau$ 的自由变量或符号是类型为 $\tau$ 的项；
2. 如果 $t_1,t_2,\ldots,t_n$ 分别是 $\tau_1,\tau_2,\ldots,\tau_n$ 类型的项，$u$ 是 $\tau_1,\tau_2,\ldots,\tau_n\to\tau$ 类型的项，那么 $u(t_1,t_2,\ldots,t_n)$ 是 $\tau$ 类型的项；
3. 如果 $x_1,x_2,\ldots,x_n$ 是 $\tau_1,\tau_2,\ldots,\tau_n$ 类型的**不同**自由变量，$t$ 是类型 $\tau_1,\tau_2,\ldots,\tau_n\to\sigma$ 的项，那么 $[\lambda x_1,x_2,\ldots,x_n. t]$ 是类型 $\sigma$ 的项。

形如 $t_1\sqsubseteq t_2$ 的式子，其中 $t_1,t_2$ 为 LCF 项，称为 LCF 原子公式（atomic formula）。一列原子公式，形如 $P_1,P_2,\ldots,P_n$，称为 LCF 公式（formula）。空公式也是允许的。若 $P$ 与 $Q$ 是 LCF 公式，那么 $P \vdash Q$ 是一个 LCF 语句（sentence）。

为了简化语法，记：

1. $(e\to t_1,t_2)$ 表示项 $\mathrm{ITE}(e,t_1,t_2)$；
2. $[\mathcal{F}x.t]$ 表示项 $\mathrm{MM}([\lambda x.t])$；
3. $t_1\equiv t_2$ 表示公式 $t_1\sqsubseteq t_2, t_2 \sqsubseteq t_1$。

## 语义

一个 LCF 的解释包含如下要件：

1. $(D_\tau, \sqsubseteq)$，一个完全偏序集（complete partial order, or "cpo"）。每个 LCF 的类型 $\tau$ 可对应到一个域 $D_\tau$。须满足：
   1. 类型 $\mathtt{bool}$ 对应的域为 $D_\mathtt{bool}=\mathrm{Bool}_\omega=\{\mathrm{true},\mathrm{false},\omega\}$，其中 $\omega$ 为 $\mathrm{Bool}_\omega$ 的最小元。
   2. 函数类型 $\tau = (\tau_1,\tau_2,\ldots,\tau_n\to\sigma)$ 对应的域为 $D_\tau=[D_{\tau_1}\times D_{\tau_2}\times\cdots\times D_{\tau_n}\to D_\sigma]$。
2. 一个函数 $\mathscr{F}_0$ 将类型为 $\tau$ 的符号 $f$ 映射到域 $D_\tau$ 的元素，需满足：
   1. $\mathscr{F}_0(\mathrm{TT})=\mathrm{true}$，$\mathscr{F}_0(\mathrm{FF})=\mathrm{false}$；
   2. $\mathscr{F}_0(\mathrm{UU_\tau})=\bot_\tau$，其中 $\bot_\tau$ 为 $D_\tau$ 的最小元；
   3. $\mathscr{F}_0(\mathrm{ITE}_\tau)=f\in [D_{\mathtt{bool}}\times D_{\tau}\times D_{\tau}\to D_\tau]$，其中 $f$ 满足 $f(\mathrm{true}, d_1, d_2) = d_1$，$f(\mathrm{false}, d_1, d_2) = d_2$，$f(\omega, d_1, d_2) = \bot_\tau$；
   4. $\mathscr{F}_0(\mathrm{MM_\tau})=\mu_\tau$，其中 $\mu_\tau$ 是 $D_\tau$ 的不动点算子，即对于任意 $f\in D_\tau\to D_\tau$，有 $f(\mu_\tau(f))=\mu_\tau(f)$。

一个指派（assignment）$\gamma$ 是从自由变量 $x$ 到其对应类型的域 $D_\tau$ 中的元素映射。指派的偏序关系 $\gamma\sqsubseteq\gamma'$ 定义为：对所有自由变量 $x\in V$，满足 $\gamma(x)\sqsubseteq\gamma'(x)$。所有指派组成的集合记作 $\Gamma$。

由 LCF 的一个解释可以确定 LCF 的语义。规定语义函数 $\mathscr{F}$ 将类型 $\tau$ 的项映射到函数 $\Gamma\to D_\tau$（注意 $\mathscr{F}_0$ 与 $\mathscr{F}$ 的区别），有：

1. $\mathscr{F}(x)(\gamma)=\gamma(x)$，若自由变量 $x\in V$；
2. $\mathscr{F}(f)(\gamma)=\mathscr{F}_0(f)$，若符号 $f\in F$；
3. $\mathscr{F}(u(t_1,t_2,\ldots,t_n))(\gamma)=\mathscr{F}(u)(\gamma)(\mathscr{F}(t_1)(\gamma),\mathscr{F}(t_n)(\gamma),\ldots,\mathscr{F}(t_n)(\gamma))$；
4. $\mathscr{F}([\lambda x_1,x_2,\ldots,x_n. t])(\gamma)(d_1,d_2,\ldots,d_n)=\mathscr{F}(t)(\gamma[x_1/d_1][x_2/d_2]\cdots[x_n/d_n])$。

可以扩展语义函数的定义，使之除项以外，还可定义于公式与语句上：

1. 若 $\mathscr{F}(t_1)(\gamma)\sqsubseteq\mathscr{F}(t_2)(\gamma)$，那么 $\mathscr{F}(t_1\sqsubseteq t_2)(\gamma)=\mathrm{true}$，否则 $\mathscr{F}(t_1\sqsubseteq t_2)(\gamma)=\mathrm{false}$；
2. 若 $\mathscr{F}(P_i)(\gamma)=\mathrm{true}$ 对 $i=1,2,\ldots,n$ 均成立，那么 $\mathscr{F}(P_1,P_2,\ldots,P_n)(\gamma)=\mathrm{true}$，否则 $\mathscr{F}(P_1,P_2,\ldots,P_n)(\gamma)=\mathrm{false}$；
3. 若 $\mathscr{F}(P)(\gamma)=\mathrm{true}$ 蕴含 $\mathscr{F}(Q)(\gamma)=\mathrm{true}$，那么 $\mathscr{F}(P\vdash Q)(\gamma)=\mathrm{true}$，否则 $\mathscr{F}(P\vdash Q)(\gamma)=\mathrm{false}$。

如果对任意指派 $\gamma$，$\mathscr{F}(P\vdash Q)(\gamma)=\mathrm{true}$ 均成立，则称 $P \vdash Q$ 是一个逻辑有效的语句，如果此时 $P$ 为空，则称 $Q$ 是一个逻辑有效的公式。
