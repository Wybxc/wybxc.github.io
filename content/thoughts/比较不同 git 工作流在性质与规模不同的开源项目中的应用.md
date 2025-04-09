---
date: 2022-12-29
---
## Git

> 版本控制是一种记录一个或若干文件内容变化，以便将来查阅特定版本修订情况的系统。——Pro Git

> Linux 内核开源项目有着为数众多的参与者。 绝大多数的 Linux 内核维护工作都花在了提交补丁和保存归档的繁琐事务上（1991－2002年间）。 到 2002 年，整个项目组开始启用一个专有的分布式版本控制系统 BitKeeper 来管理和维护代码。
>
>
> 到了 2005 年，开发 BitKeeper 的商业公司同 Linux 内核开源社区的合作关系结束，他们收回了 Linux 内核社区免费使用 BitKeeper 的权力。 这就迫使 Linux 开源社区（特别是 Linux 的缔造者 Linus Torvalds）基于使用 BitKeeper 时的经验教训，开发出自己的版本系统。 他们对新的系统制订了若干目标：
>
> - 速度
> - 简单的设计
> - 对非线性开发模式的强力支持（允许成千上万个并行开发的分支）
> - 完全分布式
> - 有能力高效管理类似 Linux 内核一样的超大规模项目（速度和数据量）
>
> 自诞生于 2005 年以来，Git 日臻成熟完善，在高度易用的同时，仍然保留着初期设定的目标。 它的速度飞快，极其适合管理大项目，有着令人难以置信的非线性分支管理系统。
>
> ——Pro Git

## 分布式工作流（**Distributed Workflows）**

[Git - 分布式工作流程 (git-scm.com)](https://git-scm.com/book/zh/v2/%E5%88%86%E5%B8%83%E5%BC%8F-Git-%E5%88%86%E5%B8%83%E5%BC%8F%E5%B7%A5%E4%BD%9C%E6%B5%81%E7%A8%8B#ch05-distributed-git)：三种分布式工作流——****集中式工作流、集成管理者工作流、主管与副主管工作流****

大部分 GitHub 项目介于前两者之间：一个或几个项目创建者/所有者拥有直接 Push 到官方仓库的权限，采用集中式工作流；除此之外的开发者通过 fork 和 pull request 参与项目，采用集成管理者工作流。

Pull requests 的原理：官方项目将提起 pr 的项目视为一个远程项目，从中 pull 一个分支到“本地”（相对于官方项目而言，实际上还位于 GitHub 的服务器中），然后合并这个分支。这个 pr 分支以“fork者用户名/分支名”命名。

## 分支开发工作流（Branching Model）

与分布式工作流的区别：分支开发工作流针对于“官方项目”的分支组织形式

- Gitflow：[Gitflow Workflow | Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) 主要针对采用集中式工作流的项目；最早提出的工作流之一；有CLI 支持（https://github.com/nvie/gitflow）；比较复杂
- Trunk-based development：[Trunk-based Development | Atlassian](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development) 开发者创建多个短生命周期的特性分支（主题分支），功能稳定后合并到主分支（trunk）中。

Gitflow 的问题：过于复杂；开发周期长；不适应社区型分布式协作

例如：pull requests 的 pr 分支天然充当特性分支的作用，合并 pr 简化了从 fork 项目到 feature 分支再到 main 分支的两次合并。

Trunk-based 更契合自动化测试持续集成，因为不同分支的 CI 可以并行

两者的结合：官方项目保留 master/main 分支和 develop/nightly 分支，后者用于合并其他人提出的 pr，一段时间测试稳定后合并到主分支

## 开源项目的种类

- 个人项目：项目所有者与主要维护者为一个人，其他人可以通过 PR 参与到项目中
- 社区项目：项目所有者为一个组织，主要维护者为一个或几个人，除主要维护者以外的人（包括组织成员与非组织成员）通过 PR 参与
- 公司项目：项目所有者为公司组织，主要维护者为公司中的一个团队，不接受或有限地接受外部人员的 PR

可能存在的区分点：主要维护者如何参与到开发？

- 直接向 main/dev 分支提交：适用于项目早期原型验证时，此时项目功能变化剧烈，不具有语义化版本更新的条件，稳定前需要主要维护者确定项目的总体架构，开源社区参与度较小
- 在官方仓库创建 feature 分支并采用 trunk-based 开发：社区项目常见的开发方式
- 持有自己的 fork，自己提交 PR 自己合并：可以及时公开工作进度，便于成员间对新功能进行交流，缺点是解决合并冲突的工作流程比较繁琐

对外部人员的 PR 的接受程度？

- 项目早期：一般不接受较大变更的 PR，事实上此时由于项目尚未定型，外部人员也难以提出有效的 PR
- 小型项目对 PR 一般比较宽松，主要维护者与贡献者直接交流，对 PR 进行源码审查之后决定是否合并
- 中大型项目一般会约定一套贡献流程，贡献者需要按照流程进行操作，确保 PR 可以通过 CI 后，由主要维护者进行 review，决定是否合并。
- 一部分公司仅将仓库作为代码托管，不接受外部人员的 PR。但目前越来越多的公司项目开始按照公司主导的社区项目运营，与中大型开源项目类似地接受 PR。

## GitHub 的历史

- 2007年10月开始开发，2008年上线
- 2009年10月新增 issues 功能
- 2018年10月上线 GitHub Actions

## 例子

- https://github.com/tauri-apps/tauri https://github.com/Textualize/rich https://github.com/nektos/act 典型的 trunk-based
