---
date: 2025-04-09
---
## Higher-order unification

Calculate a unifier (replacement for **schematic variables**) for two higher-order terms, e.g.

> Rule: `?P => ?Q => ?P /\ ?Q`
>
> Goal: `(a > b) /\ (b > c)`
>
> Unifier: `?P = a > b, ?Q = b > c`
>
> New goal: `a > b` and `b > c`

## Backward Proof

Intuition for backward proof:
$$
\frac{
A\Rightarrow B\quad 
(H\Rightarrow B')\Rightarrow C \quad
B'\theta=B\theta
}{
(H\Rightarrow A)\Rightarrow C
}
$$
Full rule:
$$
\frac{
A\Rightarrow B\quad 
\left(\forall \vec{x}. \vec{H} \ \vec{x} \Rightarrow B'\right) \Rightarrow C \quad
\left(\lambda \vec{x}. B\ \vec{x}\right)\theta = B' \theta
}{
\left(\forall \vec{x}. \vec{H} \ \vec{x}\Rightarrow A\ \vec{x}\right)\theta \Rightarrow C\theta
}
$$

## Forward Proof

Isabelle itself does not support forward proof by solely using higher-order unification.

The `of` / `OF` methods can instantiate schematic variables in a term / a proven  theorem.
$$
\frac{
A=\left(H\Rightarrow B'\Rightarrow C\right) \quad
B'\theta=B\theta
}{
A \ \texttt{OF}\ B=\left(H\Rightarrow C\right)\theta
}
$$

## With Hoare Logic?

Enhanced sequence rule:
$$
\frac{\{P\} \ C_1 \ \{Q\} \quad \{Q'\}\ C_2 \{R\} \quad Q\theta=R\theta }{\{P\theta\} \ C_1;C_2 \ \{R\theta\}}
$$
