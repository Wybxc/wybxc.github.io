---
title: Pretty Printer in Rustc
pubDate: 2024-07-28
tags: ["rust", "rustc"]
---

Pretty printing is a programming technique used to format and display data structures, such as code, data, and configuration files, in a more readable and aesthetically pleasing way. This technique is especially useful during development, as it helps developers easily grasp the hierarchy and structure of code and data.

The main task of pretty printing involves managing line breaks and indentation. When data output is too lengthy to fit on a single line, pretty printing breaks it into multiple lines. It then determines the appropriate indentation for the subsequent lines, ensuring that the structure remains clear and easy to follow.

In this post, we'll explore the pretty printing algorithm used in [rustc](https://doc.rust-lang.org/nightly/nightly-rustc/rustc_ast_pretty/pp/index.html), the Rust compiler, and utilized by the [prettyplease](https://crates.io/crates/prettyplease) crate. This approach is based on Derek C. Oppen's paper, ["Pretty Printing"](http://i.stanford.edu/pub/cstr/reports/cs/tr/79/770/CS-TR-79-770.pdf). While Oppen's pretty printer is less flexible than the widely used [Wadler's pretty printer](https://homepages.inf.ed.ac.uk/wadler/papers/prettier/prettier.pdf), it offers advantages in terms of speed and memory efficiency.

## Oppen's Pretty Printer

Here's a brief overview of the algorithm from the paper.

The algorithm reads from a token stream, consisting of:

1. **Words:** Plain strings printed as they are.
2. **Breakable Spaces:** Indicate potential line breaks. If no break occurs, these render as zero or more spaces.
3. **Delimiters:** Represented by `[` and `]`, indicating the hierarchical structure of logically contiguous blocks.

Each token has an associated "size," calculated as follows:

1. The size of a string is its length.
2. The size of a `]` is 0[^1].
3. The size of a breakable space or a `[` is determined by the total size from it (including its own space) to the next break point (or EOF)[^2]. If there is an entire delimited block between them, that block is treated as a single unit. Inner breakable spaces within the block do not affect the size calculation for the outer elements.

For example:

```json
"fn" "foo" _ "(" [ "x" ":" _ "i32" ] ")" "->" _ "i32" _ "{" [ "return" _ "x" _ ] "}"
 2     3  11  1  2  1   1 11   3   0  1   2   4   3  12  1  6     6    2  1  2 0  1
           |     |         |                  |       |     |          |     |
           |     +---------+                  +-------+     |          +-----+-------
           |               +------------------+       |     +----------+
           +----------------------------------+       +------------------------------
```

To calculate the size, the algorithm uses a FIFO buffer to store "lookahead" information. During the "scan" process, tokens are added to the end of the buffer until there is enough information to calculate the size of the first element. Once the size is determined, the foremost elements are removed from the buffer and sent to the "print" process.

The "print" process is straightforward: it receives a token and its calculated size, then attempts to layout the token on the current line. If it encounters a breakable space and there's not enough space remaining on the line, it breaks the line and indents the text, according to the extra information carried by the delimited and space tokens.

A key optimization in the algorithm is that once the size of a `[` exceeds the remaining space on the line, it will never fit. Thus, its size can be set to infinity, and it can be quickly removed from the buffer. This ensures the buffer never holds more than $O(m)$ elements, where $m$ is the line width.

## Using the Pretty Printer

The implementation of the pretty printer is found in the [rustc_ast_pretty](https://doc.rust-lang.org/nightly/nightly-rustc/rustc_ast_pretty/pp/index.html) crate. The interface looks like this:

```rust
trait Printer {
    fn new() -> Self;
    fn scan_string(&mut self, string: Cow<'static, str>);
    fn scan_begin(&mut self, token: BeginToken);
    fn scan_end(&mut self);
    fn scan_break(&mut self, token: BreakToken);
    fn eof(self) -> String;
}
```

This corresponds directly with the algorithm: create a printer, invoke the `scan_*` methods to feed tokens into it, and finally call `eof` to get the result.

However, the `scan_*` methods are private in rustc's implementation. Instead, a higher-level facade is provided:

```rust
trait Printer {
    fn new() -> Self;
    
    fn word<S: Into<Cow<'static, str>>>(&mut self, wrd: S);
    
    fn ibox(&mut self, indent: isize);
    fn cbox(&mut self, indent: isize);
    fn visual_align(&mut self);
    fn end(&mut self);

    fn break_offset(&mut self, n: usize, off: isize);
	fn space(&mut self);
    fn zerobreak(&mut self);
    fn hardbreak(&mut self);
    
    fn eof(self) -> String;
}
```

The `word` method is equivalent to `scan_string`.

`ibox`, `cbox`, and `visual_align` are specialized versions of `scan_begin`, introducing different behaviors when a block breaks.

- **Consistent Breaking:** After the first break, no attempt is made to fit subsequent breaks on the same line.
- **Inconsistent Breaking:** Subsequent breaks may be fit together on the same line.
- **Visual Aligning:** A variant of consistent breaking where content is aligned at the same indentation.

For example,

```
foo(hello, there, good, friends)
```

breaking inconsistently to become

```
foo(hello, there,
  good, friends);
```

whereas a consistent breaking would yield:

```
foo(hello,
  there,
  good,
  friends);
```

And the result of visual aligning is:

```
foo(hello,
    there,
    good,
    friends);
```

The `end` method matches `scan_end`.

The `break_offset` function internally calls `scan_break`, creating a breakable space with a specified width and indentation offset. The functions `space`, `zerobreak`, and `hardbreak` are shorthand for specific `break_offset` behaviors.

- `space` is a shortcut for `break_offset(1, 0)`, which renders a single breakable space.
- `zerobreak` is equivalent to `break_offset(0, 0)`, which renders nothing but creates a breakable point.
- `hardbreak` corresponds to `break_offset(INFINITY, 0)`, which cannot fit within a line and thus always forces a line break.

## Examples

The `cbox_delim` function demonstrates an idiomatic use of the pretty printer: creating a `cbox` and wrapping it with delimiters, useful for laying out code blocks with several statements.

```rust
fn cbox_delim(
    pp: &mut Printer,
    indent: isize,
    delim: (&'static str, &'static str),
    padding: usize,
    op: impl FnOnce(&mut Printer),
) {
    pp.word(delim.0);
    pp.break_offset(padding, indent);
    
    pp.cbox(indent);
    op(pp);
    pp.break_offset(padding, -indent);
    pp.end();
    
    pp.word(delim.1);
}

fn separated<T>(
    pp: &mut Printer,
    sep: &'static str,
    elements: &[T],
    mut op: impl FnMut(&mut Printer, &T),
) {
    if let Some((first, rest)) = elements.split_first() {
        op(pp, first);
        for elt in rest {
            pp.word(sep);
            pp.space();
            op(pp, elt);
        }
    }
}

cbox_delim(pp, INDENT, ("{", "}"), 1, |pp| {
    separated(pp, ";", statements, |pp, stmt| {
       print_stmt(pp, stmt);
    });
});
```

For more examples, check out my [rustc_codegen_c](https://github.com/Wybxc/rustc_codegen_c/blob/master/crates/rustc_codegen_c_ast/src/pretty.rs) project.



[^1]: In the current implementation in rustc, the size of a `]` is set to 1, which is technically incorrect but doesn't affect the outcome since only the sign matters.

[^2]: According to the original paper, the size of a `]` should be the total size of its delimited block. The size of a space should include its own length plus the size of the next block. The implementation in rustc differs from it... I don't know why.
