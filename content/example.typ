#import "../template.typ": *
#show: post.with(
  title: "Hello World",
  date: datetime(year: 2022, month: 1, day: 1),
)

= H1

== H2

=== H3

#lorem(50)

#lorem(50)

*Bold*

_Italic_

`Code`

```typc
#lorem(50)
```

#footnote[Footnote]

#link("https://example.com")

- List 1
- List 2
- List 3

1. List 1
2. List 2
3. List 3

#table(
  columns: (1fr, 1fr),
  [1], [2],
  [3], [4],
)

Math:

$
  sum_(i=1)^n i^2 = ((n^2+n)(2n+1))/6
$

#lorem(50)
Inline math: $limits(sum)_(i=1)^n i^2 = (n^2+n)(2n+1)/6$
#lorem(20)
$sum_(i=1)^n i^2 = (n^2+n)(2n+1)/6$
#lorem(20)

#quote(block: true, attribution: "Someone")[
  #lorem(50)
]
