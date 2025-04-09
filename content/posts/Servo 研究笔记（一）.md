---
title: Servo 研究笔记（一）
date: 2023-05-08
tags:
  - Rust
  - Servo
  - 浏览器
---
> 本文旨在分享本人在研究 servo 引擎时所得到的理解，但其中可能存在不准确或遗漏之处。

## Servo 的架构

Servo 中的每个页面称为一个“系列”（constellation[^1]），它封装了会话历史，了解帧树（frame tree）中的所有帧，并且是每个包含帧的管线（pipeline）的所有者[^2]。

_TODO：frame tree 是什么？_

Servo 的页面渲染分为四个步骤：脚本执行、布局、渲染、合成，由系列发起的管线执行[^3]。

- 脚本执行阶段[^4]负责创建和管理 DOM，并执行 JavaScript 引擎。它接收来自多个来源的事件，包括导航事件，并相应地路由它们。当脚本需要布局信息时，它会向布局任务发送请求。
- 布局阶段[^5]对 DOM 进行快照，计算样式并构建主要的布局数据结构——流树（flow tree[^6]）。流树用于计算节点的布局，并从中构建显示列表（display list[^7]），该列表被发送到渲染任务中。
- 渲染阶段[^8]接收显示列表，并将可见部分渲染到一个或多个图块中。渲染任务可能会并行处理。
- 合成阶段[^9]将来自渲染器的图块合成并发送到屏幕上进行显示。作为 UI 线程，合成器也是 UI 事件的第一个接收者，这些事件通常会立即发送到内容进行处理。某些事件（例如滚动事件）最初可能由合成器处理以获得响应。

_TODO：原文中“路由”（routes them as necessary）是什么意思？_

_TODO：脚本会使用布局的信息，是否说明这两个阶段是交错进行的？_

Servo 中的 DOM 和显示列表是两个核心的数据结构。

DOM 以树形结构实现，具有版本化节点，使用写时复制和垃圾回收机制进行管理。DOM 节点的生命周期由 JavaScript 垃圾回收器进行管理，JavaScript 可以直接访问节点，无需借助 XPCOM 或类似机制。

_TODO：这是否意味着无法剥离 Script 而只执行其他三个阶段？_

显示列表是布局任务创建的一系列有序的高级绘图命令集合，按照 z\-index 排序。Servo 的显示列表是不可变的，因此多个渲染器可以并发共享访问。

```text
         +---------------+
    +----+ Constellation |
    |    +---------------+
    |
    | Content                                 +---------------+  tile
    |                                     +-->+ Render Thread +--------+
    v                                     |   +---------------+        |
+---+----+  DOM  +--------+  display list |                            |   +------------+
| Script +------>+ Layout +---------------+                            +-->+ Compositor |
+--------+       +--------+               |                            |   +------------+
                                          |   +---------------+  tile  |
                                          +-->+ Render Thread +--------+
                                              +---------------+
```

## 构建系统

Servo 有自己的构建系统 Mach。Mach 由 Python 编写，负责处理平台和环境依赖，解析用户配置，然后生成 cargo 命令并调用[^10]。

更准确地说，Mach 是一个编写命令行程序的辅助库[^11]，是为 servo 的构建系统[^12]编写的。

Servo 是作为一系列 library 构建的[^13]，其提供 API，窗口前端[^14]调用这些库，提供显示和用户交互。

我在 Windows 上试图编译 Servo 时失败了（_mozjs_sys 的环境问题，果然 C\+\+ 混沌邪恶_），遂转在 Ubuntu 上编译。

运行 `./mach build -d` 可以编译一个图形界面的 demo 浏览器程序，编译完成后可以用 `./mach run <URL>` 测试运行。

自己测试的结果（commit 0cffe55）如下：

<table data-draft-node="block" data-draft-type="table" data-size="normal"><tbody><tr><th>网站</th><th>结果</th></tr><tr><td>百度</td><td>失败（控制台可见 js 输出，网页显示为白屏）</td></tr><tr><td>谷歌</td><td>失败（网络问题）</td></tr><tr><td>Python http.server</td><td>成功</td></tr><tr><td>rustdoc</td><td>失败（js 执行出错）</td></tr></tbody></table>可见 servo 对 js 的支持不是很好。

## API

使用 `./mach build -dv` 可以看到 mach 构建的 cargo 命令：

```bash
rustup run --install nightly-2023-02-01 cargo build --manifest-path /home/wybxc/servo/ports/winit/Cargo.toml --features media-gstreamer native-bluetooth egl layout-2013 --timings -v
```

可以看出，默认构建的是 winit 前端[^15]。接下来，就可以参考这个 crate 中使用 servo API 的方式，分析 servo API 的构成和作用。

## 参考

[^1]: https://github\.com/servo/servo/blob/master/components/constellation/lib\.rs
[^2]: https://github\.com/servo/servo/blob/master/docs/glossary\.md
[^3]: https://github\.com/servo/servo/wiki/Design
[^4]: https://github\.com/servo/servo/blob/master/components/script/script_thread\.rs
[^5]: https://github\.com/servo/servo/blob/master/components/layout_thread/lib\.rs
[^6]: https://github\.com/servo/servo/blob/master/components/layout/flow\.rs
[^7]: https://github\.com/servo/servo/blob/master/components/gfx/display_list/mod\.rs
[^8]: https://github\.com/servo/servo/blob/master/components/gfx/paint_task\.rs
[^9]: https://github\.com/servo/servo/blob/master/components/compositing/compositor\.rs
[^10]: https://github\.com/servo/servo/blob/master/python/mach_bootstrap\.py
[^11]: https://github\.com/servo/servo/tree/master/python/mach
[^12]: https://github\.com/servo/servo/tree/master/python/servo
[^13]: https://github\.com/servo/servo/tree/master/components
[^14]: https://github\.com/servo/servo/tree/master/ports
[^15]: https://github\.com/servo/servo/tree/master/ports/winit
