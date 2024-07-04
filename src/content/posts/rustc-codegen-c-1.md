---
title: Rustc Codegen C, part 1
pubDate: 2024-06-30
tags: ["rust", "rustc"]
---

For OSPP 2024, I applied for and was accepted to participate in the project ["C codegen backend for rustc"](https://blog.rust-lang.org/2024/05/07/OSPP-2024.html). This is an exciting opportunity for me to engage with a community-driven open-source project for the first time.

The project involves developing a "backend" for rustc that translates Rust MIR to C code. This aims to enhance platform compatibility and potentially speed up compilation for rapid prototype development. The original concept was discussed on [Zulip](https://rust-lang.zulipchat.com/#narrow/stream/122651-general/topic/rustc_codegen_c).

Before diving in, conducting a survey on the topic is essential. Rust has more advanced features than C, which can make translating Rust MIR to C code challenging. Here, I outline some potential difficulties as an early overview of the project.

This blog post is basically an expanded version on my OSPP application, including details I initially missed.

## Data Layout

Rust offers more complex data structures compared to C. Its [default memory model](https://doc.rust-lang.org/nomicon/repr-rust.html), `#[repr(Rust)]`, provides no stability guarantees, allowing Rust to optimize memory usage by rearranging fields for better efficiency.

Rust also has `#[repr(C)]`, which mirrors C's layout rules. Since Rust's default layout is unspecified, we can use `#[repr(C)]` for everything, which might fit our needs for the C codegen backend.

However, `#[repr(C)]` isn't exactly the same as directly translating to C structures. For example, Rust has Zero Sized Types (ZSTs), which have no equivalent in C since every C type must have a minimum size of 1.

```rust
struct ZeroSizedType;
#[repr(C)]
struct Example {
    field1: u32,
    zst: ZeroSizedType, 
}
// The size of `Example` is 4 bytes in Rust
```

```c
struct ZeroSizedType {};

struct Example {
    int field1;
    ZeroSizedType zst;
};
// The size of `Example` is 8 bytes in C
```

Another issue is niche optimization. In Rust, `Option<Box<T>>` has the same size as `Box<T>` by using the null pointer "niche" to represent `None`. This optimization isn't straightforward to implement in C [^1].

## Unwinding

When a panic occurs in Rust, the program may unwind the stack to report errors and perform cleanup. A related concept in C is the `setjmp` and `longjmp` functions, which pass through the calling stack and are often used to implement execption mechanism.

When a program panics, capturing a backtrace for debugging is a common practice. However, implementing this in a C backend is challenging due to platform-specific differences in calling stack structures.

Of course there is a simple option to exit: use `panic=abort`. This approach avoids unwinding by immediately terminating the program without performing any cleanup or backtrace. This method can be a practical choice during the early stages of development.

## Undefined Behaivor

The domain of undefined behavior [differs between Rust and C](https://www.youtube.com/watch?v=DG-VLezRkYQ). There are instances where Rust code is well-defined but may lead to undefined behavior in C, and vice versa. The C codegen backend must ensure that the generated C code is free from undefined behavior.

### Aliasing and type punning

Strict aliasing rules in C can lead to various undefined behaviors when type punning is involved. Casting a pointer to a different type and accessing memory through the new type can cause issues.

It's interesting that aliasing rules in Rust is less strict than C. The key rule in Rust is to coexist harmoniously with the borrow checker: a mutable reference must never be aliased by other pointers or references. Rust allows type punning as long as the data layouts of the source and destination types are guaranteed to match.

The C codegen backend must ensure that all type punning is handled correctly to avoid undefined behavior. This can be achieved by using unions or `memcpy` to safely copy memory between different types.

### Out-of-bounds pointer arithmetic

Storing an invalid pointer in C results in undefined behavior. This occurs because,  on certain platforms, pointers are stored in special registers, leading to potential CPU malfunctions. The only exception is a pointer just one position past an array, which can be used to indicate the end of a dynamic array, even though it may point to an invalid memory location.

In Rust, you can perform arbitrary arithmetic on pointers and freely create invalid pointers, provided you do not dereference them. However, Rust does not allow references to invalid pointees, adhering to the same requirements as C pointers. Therefore, Rust references can be considered analogous to real C pointers, while Rust pointers can be treated similarly to `size_t` in C.

## Some topics that may not become difficult

In this part I will discuss some topics that I used to think it difficult, but actually not that hard to handle.

### Integer overflow

Signed integer overflow is undefined behavior in C. Therefore, the C code generation backend must properly handle integer overflow cases to avoid this undefined behavior.

However, Rust MIR explicitly marks out safe integer operations. These operations can be implemented by calling specific functions, such as[^2]:

```c
int checked_add(int a, int b, int *err) {
    if (b > 0 && a > INT_MAX - b) {
        *err = 1;
        return INT_MAX;
    } else if (b < 0 && a < INT_MIN - b) {
        *err = 1;
        return INT_MIN;
    } else {
        *err = 0;
        return a + b;
    }
}
```

### Drop check

Rust has an affine type system that automatically releases resources when they are no longer needed. Generally, the behavior of these automatic drops can be determined syntactically. However, there are instances where the drop behavior is more complex and requires additional runtime analysis.

But drop checks are not needed to manage manually in code generation. This is because the analysis related to drop checking occurs before the MIR generation. Consequently, all necessary details about drop checks are explicitly handled in the MIR.

[^1]: Is niche optimization a MUST in Rust? As far as I know, there's no formal specification on this. However, according to [this PR](https://github.com/rust-lang/rust/pull/60300), niche-optimized values are considered FFI-safe, and many crates rely on this feature. Ignoring it would likely be problematic.
[^2]: The result type might be better defined as `struct { int err; int result; }`, which simulates `Option<i32>` in Rust.
