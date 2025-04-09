---
date: 2022-06-11
title: 如何编写一个 GitHub Actions 操作？
tags:
  - GitHub
---
当我们使用 GitHub Actions 的时候，经常会用一些别人写好的操作，像这样：

```yaml
- uses: actions/checkout@v3
  with:
    fetch-depth: 0
```

这里的每一个 `use`，就是一个 GitHub 操作。这篇文章，就是关于编写**自己的** GitHub Actions 操作的笔记。

请注意，这**不是**怎么编写 `.github/workflow/xxx.yml` 或者怎么使用 Actions 的教程。

## Actions 操作是什么？

每一个 Actions 操作，实际上就是一个 GitHub 仓库。和一般的仓库一样，它可以用 `owner/repo@tag` 来表示。

以上面提到的 `actions/checkout@v3` 为例，它表示的是 `actions` 这个用户的名为 `checkout` 的仓库，其中的 tag 为 `v3` 的版本。所以说，我们可以在 `https://github.com/actions/checkout/tree/v3` 这个地方找到它的源码。这和一般的 GitHub 仓库是完全一样的。

当然，并不是随便一个仓库都能成为 Actions 操作。要想让仓库被 GitHub 识别为 Actions 操作，必须在项目根目录下有一个 `action.yml` 文件。这个文件里可以定义操作的一系列元信息，包括作者、名称、图标、启动方式等等。

比如，下面是 `actions/checkout@v3` 的 `action.yml`（中间省略了一部分·）：

```yaml
name: 'Checkout'
description: 'Checkout a Git repository at a particular version'
inputs:
  repository:
    description: 'Repository name with owner. For example, actions/checkout'
    default: ${{ github.repository }}
  # ...(省略)
runs:
  using: node16
  main: dist/index.js
  post: dist/index.js
```

关于这个文件的所有可用字段，可以参考 GitHub 的[文档](https://docs.github.com/cn/actions/creating-actions/metadata-syntax-for-github-actions)。

## Actions 操作的启动方式

`action.yml` 的 `runs` 段制定了操作的启动方式。启动方式可以分为三种：运行 Node.js 脚本，运行 Docker 镜像，运行组合脚本。上面的 `actions/checkout@v3` 采用的是 Node.js 脚本的形式。

### Node.js 脚本

将 `runs.using` 设置为 `node16` 或 `node12`，就可以指定为启动 Node.js 脚本。

用 `main` 字段指定脚本的入口点。启动的方式类似于直接运行 `node main.js`，所以并不会从 `package.json` 中安装依赖。因此，在开发时，一般都会使用打包工具将依赖项打包到一起，输出一个单独的 js 文件，然后将这个文件作为入口点。

`post` 字段可以指定清理工作，这里的内容将会在 workflow 结束时运行。可以看到`actions/checkout@v3` 指定了清理工作，所以我们在 Actions 中引用这个操作之后，会看到在开始运行和结束运行时各有一段它的输出。

`actions/checkout@v3` 将 `main` 和 `post` 设置为同一个脚本，但在两个阶段可以执行不同的工作，是因为它在脚本中通过读取环境变量，能够判断当前的运行阶段。在清理阶段，环境变量 `STATE_isPost` 会被设置，可以据此做出判断。

### Docker 镜像

将 `runs.using` 设置为 `docker`，指定以 `Docker` 镜像启动。

```yaml
runs:
  using: docker
  image: Dockerfile
```

`image` 指定镜像启动需要的 `Dockerfile`，这里指定为项目根目录下的 `Dockerfile` 文件。

在 Dockerfile 中，用 `ENTRYPOINT` 指定启动的脚本。比如这样定义一个用 deno 运行脚本的程序：

```dockerfile
FROM denoland/deno:1.22.2

COPY . /github-stats
WORKDIR /github-stats

RUN ["deno", "cache", "/github-stats/src/action.ts"]

ENTRYPOINT ["deno", "run", "--allow-read=/github/workflow", "/github-stats/src/action.ts"]
```

这里可以看出使用 Docker 的优点：可以自定义运行环境，就能够使用除了 Node.js 以外的环境，也能使用其他的语言。

使用 Docker 唯一的缺点是无法直接文件进行写入，因为在 Docker 容器内进行的文件操作都会在运行结束后消失。解决的办法有两个：一是可以用 `outputs` 代替文件进行输出，二是不使用 `using: docker`，而是自己在 `shell` 脚本中执行启动 docker 的命令。关于这一点的细节将在后文展开。

### 组合脚本

```yaml
runs:
  using: composite
  steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - shell: bash
      run: |
        echo "Start running"
        sudo mkdir -p ./render
```

指定 `using: composite`，然后在 `steps` 中指定一系列步骤。这里的语法和 `.github/workflow/xxx.yml` 是一样的。

## 获取输入

当我们使用 Actions 操作的时候，可以用 `with` 指定一系列输入，比如：

```yaml
- uses: actions/checkout@v3
  with:
    fetch-depth: 0
```

这些输入是在 `action.yml` 的 `inputs` 字段中指定的。

```yaml
inputs:
  token:
    description: GitHub personal access token.
    required: true
  verbose:
    description: Verbose output. Default to 0.
    required: false
    default: '0'
```

像这样，指定两个输入项，名称分别为 `token` 和 `verbose`。前者是必选输入，后者是可选输入。可选输入必须指定一个默认值。

在操作运行时，GitHub 会把输入写入到环境变量中。环境变量的名称带有 `INPUT_` 的前缀。比如上面 `token` 对应的环境变量就是 `INPUT_TOKEN`。

对于 Javascript 环境，GitHub 提供了一些库来从环境变量中读取输入，可以在[这里](https://github.com/actions/toolkit)找到。比如，读取 token 的代码就可以这么写：

```js
import * as core from '@actions/core'
const token = core.getInput('token')
```

因为这些库的本质都是环境变量和输出操作，所以并不局限于 Node.js，在 deno 中也是可用的。

```js
import * as core from 'https://esm.sh/@actions/core@1.8.2'
const token = core.getInput('token')
```

---

下面以一个实际的例子来说明编写操作的方法。以下内容来自于我正在编写的项目：[Wybxc/github-stats](https://github.com/Wybxc/github-stats)。

## 编写 Actions 操作的示例

### 基础结构

项目使用 deno + TypeScript 编写。首先建立基础的文件结构：

```
.
├── action.yml
├── deno.json
├── Dockerfile
├── import_map.json
├── src
│   └── action.ts
├── LICENSE
└── README.md
```

在 `action.yml` 中定义操作元数据：

```yaml
name: GitHub Stats
description: Generate your github readme stats.
author: 'Wybxc'
inputs:
  token:
    description: GitHub personal access token.
    required: true
  verbose:
    description: Verbose output. Default to 0.
    required: false
    default: '0'
  # ...(省略)
runs:
  using: docker
  image: Dockerfile
```

在 Dockerfile 中定义启动步骤：

```dockerfile
FROM denoland/deno:1.22.2

COPY . /github-stats
WORKDIR /github-stats

RUN ["deno", "cache" ,"--import-map=/github-stats/import_map.json", "/github-stats/src/action.ts"]

ENTRYPOINT ["deno", "run" , \
"--import-map=/github-stats/import_map.json", \
"--allow-env", \
"--allow-net", \
"--allow-read=/github/workflow", \
"/github-stats/src/action.ts"]
```

在编写 Dockerfile 时，有一些需要注意的地方。

第一，**路径访问都需要使用绝对路径**。因此，需要用 `COPY . /github-stats` 将文件都挂载到一个固定的路径上。

第二，这里用了 `WORKDIR` 指定当前路径，但其实 GitHub 的文档并不推荐这么做。这里是因为 deno 在不指定的情况下会找不到 import map 报错。**在运行时，GitHub 会将 `WORKDIR` 覆盖为 `/github/workflow`**，因此此处的 `WORKDIR` 并不能指定运行时的当前路径。

第三，`actions/toolkit` 这一系列库会读取环境变量，以及 `/github/workflow` 下的文件，来获取 Actions 在运行时的一些元信息，所以需要在 deno 中把这些权限打开。

第四，**不要用 `USER` 指令切换用户**。因为只有默认的 root 用户才能读取 `/github/workflow` 目录。

### 读取输入

从 Dockerfile 中可以知道，程序的入口点在 `src/action.ts`。

```typescript
import * as core from '@actions/core'
import * as github from '@actions/github'

if (github.context.eventName === 'push' && github.context.payload?.head_commit) {
  if (/\[Skip GitHub Action\]/.test(github.context.payload.head_commit.message)) {
    console.log('Skipped because [Skip GitHub Action] is in commit message')
    Deno.exit(0)
  }
}

const verbose = parseInt(core.getInput('verbose')) || 0
```

这两个 import 语句没有使用 url，而是像 Node.js 一样直接用名称引入，是因为我定义了 `import_map.json`，它可以将名称映射到 url。

```json
{
  "imports": {
    "@actions/core": "https://esm.sh/@actions/core@1.8.2",
    "@actions/github": "https://esm.sh/@actions/github@5.0.3"
  }
}
```

第一段代码是简单的判断，看看触发 Actions 的 commit 消息是否含有 `[Skip GitHub Action]`，如果是，那么直接退出。这是因为程序后面的逻辑需要像 GitHub 提交内容，在提交信息里带上 `[Skip GitHub Action]`，就可以避免反复触发的无限循环。

后面就是读取 `inputs` 中的输入，然后进行解析。因为输入使用环境变量传递，所以只能读取到字符串，需要自行转化类型。

### 提交文件到 GitHub

程序中需要将文件提交到 GitHub。这一步并不是通过文件操作，而是通过 GitHub 的 API 进行的。

`octokit` 是对 GitHub 的 API 进行封装的库。

```typescript
import { Octokit } from 'https://esm.sh/octokit@1.7.2'

const token = core.getInput('token')
if (!token) throw new Error('No token was provided for GitHub repository.')
const octokit = new Octokit({ auth: token })
```

或者通过 `@actions/github` 提供的方法，在 Actions 环境中获取 Octokit 实例：

```typescript
import * as github from '@actions/github'
const octokit = github.getOctokit(token)
```

然后使用 API 推送文件内容。

```typescript
import { encode } from 'https://deno.land/std@0.143.0/encoding/base64.ts'

async function commit({ owner, repo, branch, path, content }) {
  const sha = await queryObjectHash(octokit, { owner, repo, branch, path })
  if (sha === (await gitHashObject(content))) {
    console.log('content is same, skip commit')
    return
  }
  await octokit.rest.repos.createOrUpdateFileContents({
    owner,
    repo,
    path,
    message: `Update ${path} [Skip GitHub Action]`,
    ...(sha ? { sha } : {}),
    content: encode(content),
    branch
  })
}
```

其中通过 sha 来校验文件相等性。`queryObjectHash` 和 `gitHashObject` 是两个辅助函数，分别用于获取远程和本地文件的 SHA Hash。git 计算 SHA-1 的方式并非直接计算，而是先在数据前面一次添加 `'blob '`，文件长度（字符串）和 `'\0'`，所以我封装了一个自己的函数。

```typescript
import { crypto } from 'https://deno.land/std@0.143.0/crypto/mod.ts'

async function queryObjectHash(
  octokit: Octokit,
  { owner, repo, branch, path }: QueryObjectHash
): Promise<string | undefined> {
  const query = await octokit.graphql(
    `
      query {
        repository(owner: "${owner}", name: "${repo}") {
          object(expression: "${branch}:${path}") { ... on Blob { oid } }
        }
      }
        `
  )
  return query.repository?.object?.oid
}

async function gitHashObject(object: Uint8Array | string): Promise<string> {
  const buffer = typeof object === 'string' ? new TextEncoder().encode(object) : object
  const blob = Uint8Array.from([
    ...new TextEncoder().encode('blob '),
    ...new TextEncoder().encode(buffer.length.toString()),
    0,
    ...buffer
  ])
  return await crypto.subtle.digest('SHA-1', blob).then((hash) =>
    Array.from(new Uint8Array(hash))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('')
  )
}
```

### 写入 Actions 输出

由于 Docker 的文件系统虚拟化，输出写入到文件后会丢失。所以，这里采用 GitHub Actions 的 output 功能代替文件输出。

GitHub Actions 的 output 是一系列只包含字符串的键值对，在 Actions 运行时可以写入和获取。

在 `@actions/core` 中，提供了设置输出的方式：

```typescript
import * as core from '@actions/core'

const write = ({ path, content }) => {
  core.setOutput(path, content)
}
```

输出的实质是向标准输出写入一条形如 `::set-output name={name}::{value}` 的内容，所以如果不使用 `@actions/core` 的方法，也可以像这样写入输出：

```typescript
console.log(`::set-output name=${path}::${JSON.stringify(value)}`)
```

写入输出后，就可以在 Actions 的后续步骤获取了，比如捕获输出并写入到文件：

```yaml
steps:
  - uses: actions/checkout@v3

  - uses: Wybxc/github-stats@feature
    id: stats
    with:
      token: ${{ secrets.GHTOKEN }}

  - name: save output
    run: |
      cat <<- EOF > wakatime-stats.svg
      ${{ steps.stats.outputs['wakatime-stats.svg'] }}
      EOF

  - name: show output
    run: cat wakatime-stats.svg
```

这里利用了 shell 的文件分界符功能（`cat <<- EOF`），将 output 里的内容写入文件。

要获取 outputs，需要给运行我们的自定义操作的步骤设置 id，然后就可以在 `${{ steps.stats.outputs[...] }}` 里面找到输出。在 GitHub Actions 中，`${{ }}` 里面的内容可以是 js 表达式。上面的 `${{ steps.stats.outputs['wakatime-stats.svg'] }}` 表示的就是获取 `id` 为 `stats` 的步骤的输出中，`name` 为 `wakatime-stats.svg` 的值。

### 自定义 Docker 启动

另一种绕开 docker 文件系统限制的方式是自己定义 Docker 启动命令。这一部分我自己没有实现，参考的是[这个项目](https://github.com/lowlighter/metrics)。

将 `action.yml` 最后几行改为：

```yaml
runs:
  using: composite
  shell: bash
  env:
      INPUTS: ${{ toJson(inputs) }}
  steps:
    - run: |
      touch .env
      for INPUT in $(echo $INPUTS | jq -r 'to_entries|map("INPUT_\(.key|ascii_upcase)=\(.value|@uri)")|.[]'); do
        echo $INPUT >> .env
      done
      env | grep -E '^(GITHUB|ACTIONS|CI|TZ)' >> .env

      OUTPUT_DIR="/output"
      sudo mkdir -p $OUTPUT_DIR

      docker build -t action_image .

      docker run --init --rm --volume $GITHUB_EVENT_PATH:$GITHUB_EVENT_PATH --volume $OUTPUT_DIR:/output --env-file .env action_image
      rm .env
```

将所有的环境变量收集到 `.env` 文件里。

在启动 Docker 时，通过挂载数据卷将目录映射到容器内的目录，这样就可以在容器内读写外部目录。
