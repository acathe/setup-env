# CLAUDE.md

## 适用环境与文档边界

- 本仓库面向全新且运行环境明确、可预期的目标系统，例如刚完成初始化并首次进入 macOS 的 Mac 设备，或刚安装完成的 Debian 系统。无需为未知的旧环境、跨发行版差异或非目标平台引入过度兼容逻辑；但仍须遵守本文明确列出的 Bash 3.2、CPU 架构及其他具体兼容约束。
- `README.md` 只用于记录公开参数。除说明参数所必需的调用格式和示例外，不得加入架构、实现细节、维护说明、测试流程或其他额外信息；这些内容应记录在 `CLAUDE.md` 中。

在修改本仓库时供 Claude Code 遵循的指南。此文件应聚焦于当前架构、可执行工作流、所有权边界，以及无法通过阅读单个脚本明显发现的
故障模式。

## 项目结构

本仓库由一组 Bash 配置脚本组成。仓库没有统一的构建目标或自动化测试套件；容器流程会在配置过程中构建
Docker 镜像。公共入口点设计为通过 `curl` 管道执行：

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup <macos|debian|container> [flags]
```

根目录的 `main.sh` 只识别 `--branch` 和 `--setup`。它会安装所选平台所需的最低限度 Git 前置依赖，使用
`mktemp -du` 派生 `/tmp/setup_env.*` 克隆路径，将请求的分支浅克隆到该路径，分发到 `<setup>/main.sh`，并原样转发所有其他
参数。之后不会删除该克隆。它是唯一没有 `BASH_SOURCE` 末尾保护条件的脚本：通过管道传入的入口点必须
无条件执行。`README.md` 当前在各平台调用表中遗漏了仅根入口支持的 `--branch` 选项；根解析器仍是该选项的
事实来源。

各配置树拥有独立的分发器，但并非完全独立：`container/dev-container` 使用 `debian/` 作为其 Docker 构建上下文。

- `macos/` 配置终端客户端／跳板机：Homebrew、Starship、Oh My Zsh、SSH 支持，以及可选的 ChatGPT、Ghostty 和 VS Code。它刻意不作为
  开发机配置，不包含 Git 插件，也没有 classic CLI 组件。
- `debian/` 配置主要开发环境。Homebrew、Zsh、Oh My Zsh、Starship 和 classic CLI 基线均无条件执行；Homebrew 最先运行，
  而 classic 层不安装任何工具，只管理平台提供的 less 和 Nano 的配置。其余 command、code 和 app 组件
  均为可选。
- `container/` 分发到 `dev-container`、`copilot-api` 或一次性 `copilot-api-config` 任务。

Debian 的 Homebrew 引导流程与 macOS 的 PATH 保护逻辑一致，并直接调用官方安装器；`--unattended` 只会添加 `NONINTERACTIVE=1`。
配置父脚本随后求值 `/home/linuxbrew/.linuxbrew/bin/brew shellenv bash`，使后代安装器可直接调用 `brew` 及其 formula 二进制文件。
Oh My Zsh 的 `brew` 插件会独立配置交互式 Zsh；此集成不会为非交互式 shell 写入 `.zshenv`。
Go 组件使用 Linuxbrew 的 `go` formula；formula 可执行文件的发现沿用上述 Homebrew PATH 契约，不由 Go 组件重复配置。
启用 `CODE_GO` 时，Debian 的 `00-setup_env.zsh.sh` 会在交互式 Zsh 中前置默认的 `$HOME/go/bin`，以发现 `go install` 产物。

`debian/vscode/` 仅作为参考数据。没有分发器会安装这些文件；`--app-vscode` 会启用 OMZ 插件。`README.md` 当前仍记录手动
安装扩展的方式；根据前述文档边界，此类非参数内容不应继续保留或新增。Debian 的 `00-setup_env.zsh.sh` 会在未启用 modern CLI 时选择
运行 `/usr/bin/nano --modernbindings`（`nano -/`）的 `nanom` wrapper，启用时选择 Micro；启用 `--app-vscode` 后，同一写入器会增加运行时 `TERM_PROGRAM=vscode` 覆盖，将编辑器设为 `code --wait`。
它不会输出 `VISUAL`。应通过 `bash` 调用脚本，而不是依赖可执行位。

根目录 `main.sh` 和 `macos/` 必须保持与 Apple Bash 3.2 兼容；Debian 和容器代码可使用更新的 Bash。

## 检查与安全验证

从仓库根目录运行以下非破坏性检查：

```bash
find . \( -path './.git' -o -path './.claude/worktrees' \) -prune -o \
    -type f -name '*.sh' -exec bash -n {} \;
find . \( -path './.git' -o -path './.claude/worktrees' \) -prune -o -type f -name '*.sh' \
    -exec shellcheck -x --rcfile './.shellcheckrc' {} +
find . \( -path './.git' -o -path './.claude/worktrees' \) -prune -o -type f -name '*.sh' \
    -exec shfmt -d -i 4 -bn -ci -s -sr {} +
git diff --check
git diff --cached --check
```

完整语法扫描使用 `PATH` 中的 Bash，不能证明与 Bash 3.2 兼容。对于根目录或 macOS 的改动，还应在 macOS 上运行以下检查：

```bash
find main.sh macos -type f -name '*.sh' -exec /bin/bash -n {} \;
```

ShellCheck 使用 `-x`，因为 `debian/app/docker.sh` 会动态 source `/etc/os-release`。`.shellcheckrc` 禁用了 `SC2016`；字面量 `jq`/`sed` 程序
和生成的 shell 内容会刻意保留美元符号，供后续解释器处理。

直接运行分发器会执行真实的安装与配置。例如，`bash debian/main.sh --app-tmux` 会运行 `apt`、安装 Oh My Zsh，并
修改当前 home。不要把普通账户用作冒烟测试沙箱。Debian 的 OMZ 安装器还会删除现有的 `.profile`、`.bashrc` 和
`.bash_logout`。针对同一 home 重复生成文件的检查，并不意味着完整平台分发器是幂等的；第三方 OMZ 插件安装器会克隆到
固定目标位置。

受管理的 OMZ Zsh 由带引号的 Bash heredoc 生成，ShellCheck 不会检查其内容。手动验证按以下顺序进行：

1. 创建一次性目录树，将 `HOME` 和 `ZSH_CUSTOM` 显式指向同一棵树，并使用受控的 `PATH`；只修改 `HOME` 不够，因为写入器会沿用
   继承的 `ZSH_CUSTOM`。
2. 使用 Oh My Zsh 模板初始化 `$HOME/.zshrc`，在 `PATH` 中放置 `git` 桩程序；在 Linux 上验证 macOS 时，再为 `plugin.sh` 提供 BSD
   `sed` 垫片。
3. 设置并导出所有组件变量，包括 `APP_VSCODE`；Debian 的 `00-setup_env.zsh.sh` 没有该变量的本地默认值，遗漏会在 `set -u` 下中止并
   留下部分输出。
4. macOS：从 `command/omz/` 调用 `plugin.sh`、`00-setup_env.zsh.sh` 和 `01-update.zsh.sh`。Debian：从同一目录依次调用
   `plugin.sh`、`setup-env.plugin.zsh.sh`、`00-setup_env.zsh.sh`、`01-update.zsh.sh` 和 `99-first_run.zsh.sh`。
5. 对本次实际生成的 `setup-env.plugin.zsh`、`00-setup_env.zsh`、`01-update.zsh` 和 `99-first_run.zsh` 逐一运行 `zsh -n`。

不要调用 `command/omz/main.sh`（会执行真实配置，Debian 上还会运行 `apt`）。若未提供 Homebrew 和 Starship 桩程序，也不要调用
`command/starship.sh`：它会安装真实 formula 并替换 `starship.toml`。不要调用 `update-all-in-one`，它会执行真实的软件包和网络更新。

对于 fzf shell 改动，请在 `zsh -f` 中检查 `${(z)FZF_CTRL_T_OPTS}` 和 `${(z)FZF_ALT_C_OPTS}`。插件顺序改动需要真实的 ZLE／PTY
冒烟测试：普通 Tab 和 `**<Tab>` 必须各自只打开一次 fzf；`fzf_default_completion` 必须为 `fzf-tab-complete`；Ctrl-T 和 Alt-C 必须保持单次调用。

## 分发器契约

平台根入口和真正的嵌套分发器遵循以下数据流：

1. 以便于覆盖的默认值初始化自身拥有的每个标志。导出后代脚本会读取的值，例如
   `export APP_GIT="${APP_GIT:-0}"`。Debian 当前还会导出 `CODE_BASH` 和 `APP_NEOVIM`，尽管只有其根入口读取它们；这些是冗余例外，而非
   跨组件契约。
2. `parse_args()` 消费自身拥有的标志，并将未知参数追加到 `POSITIONAL`。
3. 布尔标志只 shift 一次。值标志使用 `numOfArgs` 保护条件，使缺失值时不会在 `set -u` 下读取未设置的 `$2`。
4. 恢复转发的参数并调用 `main()`。
5. 保持无条件引导组件显式声明的依赖顺序。按 `--command-*`、`--code-*`、`--app-*` 的顺序运行由可选标志控制的组件，
   每组内部按字母排序。
6. 每个可选组件都要安装或保护其所需的每个可执行文件。除非集成关系有明确文档，否则不要让一个可选标志依赖另一个标志。

对于普通可运行组件，导出块、解析器 case、`main()` 保护条件和对应的 `README.md` 表，是同一接口的四个有序视图。
Debian 的 `APP_VSCODE` 是明确的纯集成例外：它有导出、解析器 case 和 README 标志，但没有 Debian 叶脚本或 `main()`
保护条件。OMZ 将它用于插件，以及 `00-setup_env.zsh.sh` 中的 `TERM_PROGRAM=vscode` 编辑器分支。不要为了强求对称而虚构空保护条件。

一个由多个部分组成的可运行关注点应拥有一个目录。`app/claude/main.sh` 是嵌套分发器，因为它拥有子参数。
两个 CLI 入口点都是无解析器的叶脚本：`command/classic_cli/main.sh` 只拥有平台提供的 CLI 工具的无条件配置，而
`command/modern_cli/main.sh` 聚合可选工具和固定的子安装器。

标志会刻意通过导出变量和转发参数向下级联。`00-setup_env.zsh.sh` 读取 `CODE_GO` 以配置用户 Go bin PATH；
`01-update.zsh.sh` 读取拥有专用更新区块的组件标志；Claude app 从 Debian 读取 `CODE_GO`、`CODE_PYTHON`、`CODE_RUST` 和 `APP_GIT`；
tmux 读取 `APP_CLAUDE`；Yazi 读取
`COMMAND_MODERN_CLI` 和 `CODE_MARKDOWN`。OMZ 写入器读取组件标志，是因为它们实际拥有共享 shell 落点。跨组件读取仅在两个关注点都
启用时增加集成行为，因而是有效的。

拥有参数的分发器或叶脚本使用完整、可 source 的末尾保护：

```bash
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}"
    main "$@"
fi
```

不接收参数的叶脚本没有解析器或 `POSITIONAL` 层：

```bash
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
```

通过管道执行的根入口点和 macOS 保留与 Bash 3.2 兼容的空数组恢复形式：

```bash
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"
```

不要将其规范化为 Debian 的 `"${POSITIONAL[@]}"`；Bash 3.2 配合 `set -u` 可能拒绝空数组展开。应匹配所属分发器的既有
写法。

添加组件时，应同步所有适用的导出、解析器、保护条件和 README 条目；列出纯集成标志的所有读取者，并选择匹配的
末尾保护。组件拥有安装和非 shell 配置，共享 shell 输出则通过适当的 OMZ 写入器生成。绝不要直接追加到共享的生成 shell 文件。

## 配置所有权与落点

每个共享配置片段只有一个逻辑所有者，但 `.zshrc` 由多个写入器协同管理。每棵配置树的 `command/omz/main.sh` 都会安装 Oh My Zsh、
准备其模板，然后编排插件和自定义文件写入器。macOS 运行 `plugin.sh`、`00-setup_env.zsh.sh` 和 `01-update.zsh.sh`；Debian 运行
`plugin.sh`、`setup-env.plugin.zsh.sh`、`00-setup_env.zsh.sh`、`01-update.zsh.sh` 和 `99-first_run.zsh.sh`。Debian 安装器还会启用
模板中的用户 bin PATH，`plugin.sh` 拥有插件数组和克隆。只有在写入非空 `setup-env` 插件之后，`setup-env.plugin.zsh.sh` 才会前置
配套的数组条目，从而避免 shell 启动时出现“已启用但缺失”的警告。

| 配置需求方 | 配置所属目标位置 |
| --- | --- |
| `compinit`、Oh My Zsh 库、插件列表 | `.zshrc` |
| Starship prompt 外观 | `$HOME/.config/starship.toml` |
| 在 source 过程中需要此配置的另一个插件 | `$ZSH_CUSTOM/plugins/setup-env/setup-env.plugin.zsh` |
| 别名、集成函数、`compdef`、运行时变量、编辑器选择 | `$ZSH_CUSTOM/00-setup_env.zsh` |
| 用户调用的聚合更新函数 | `$ZSH_CUSTOM/01-update.zsh` |
| 延迟执行的交互式登录或向导 | `$ZSH_CUSTOM/99-first_run.zsh` |
| 非交互式 shell 命令 | `.zshenv` |

决策依据是值被读取的时机，而不是它看起来是否像环境变量。`setup-env` 插件承载 eza 加载时 zstyle；将它们移到
`00-setup_env.zsh` 会悄无声息地为时过晚。相反，`ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets)` 必须保留在 syntax-highlighting 插件之后；
提前移动会阻止该插件安装其 `main` highlighter。

`--code-python` 使用 Linuxbrew 管理 `uv` 和 `py-spy` formula；Debian 系统 `python3` 仍是平台基线，项目使用的 Python 运行时则由 `uv`
安装和管理，不额外安装 Homebrew `python` formula。Python 集成会启用 Oh My Zsh 的 `python` 和 `uv` 插件，但刻意不设置
`PYTHON_AUTO_VRUN`。uv 无需该手动自动激活开关即可发现虚拟环境；不要重新引入它。

由配置流程管理的运行时工具配置以制品形式随仓库提供，而不是由配置 shell 渲染。大多数写入器使用
`install -m 644`，需要创建父目录时再加 `-D`。这包括 bat、Glow、less、micro、Nano、lazygit，以及 Yazi 的 `init.lua` 和
`keymap.toml`；仓库本地 lint 配置和未部署的 VS Code 参考数据不受此规则约束。
copilot-api 设置模板是随仓库提供、由 `jq` 补全的 JSON 制品，直接写入时目录权限为 700，文件权限为 600。外部
例外是 `code/python.sh` 从 BesLogic 的 `main` 分支下载的 Ruff 基线。Starship 和 Yazi 使用生成式配置：`command/starship.sh` 通过
已安装二进制文件的 `nerd-font-symbols` preset 替换 `$HOME/.config/starship.toml`；`app/yazi/yazi.toml.sh` 会创建目标目录，并通过
一次完整渲染替换 `yazi.toml`，因为 previewer 依赖组件标志。重复配置会覆盖这两个文件中的用户修改。此处自行设计的生成文件均采用
完整渲染；仅向上游拥有的文件追加内容，而全局 Git 配置使用 `git config`。

重新运行会覆盖仍有写入器的受管理静态配置，并完整重建 Starship 和 Yazi 的生成配置。删除随仓库提供的制品，不会删除早期版本
已经安装的副本；清理必须显式执行。Starship 迁移同样会保留早期的 `$ZSH_CUSTOM/themes/powerlevel10k` 克隆，且不会删除 Debian
并未管理的 `.p10k.zsh`。官方 Starship 插件会在 Oh My Zsh 的主题阶段前清除陈旧的 `ZSH_THEME`，因此两者均不会生效。当执行到
`yazi.toml.sh` 时，完成的渲染会反映当前集成标志。
Yazi 的 `package.toml` 不同：`ya pkg add` 拥有这份可变运行时清单，因此仓库从不提供、覆盖或垃圾回收它。只
配置与软件包默认值有实质差异的值。`ya pkg add` 会拒绝已列出的依赖。它用完整的
`owner/repository` 标识来源，但按插件名部署，因此替换同名插件的所有者时，必须先对旧来源执行 `ya pkg delete`，再添加新
来源；绝不要直接编辑 `package.toml`。

### 空渲染不会撤回先前输出

`setup-env.plugin.zsh.sh` 和 `99-first_run.zsh.sh` 会在接触当前目标之前捕获 `render_blocks()`。空渲染会成功返回，
但不会写入或删除当前目标。在全新 home 上不会创建制品；在重复配置时，则让早期制品逐字节保持
不变。这是刻意设计的配置契约：禁用标志不等于卸载或垃圾回收。

重命名写入器不会删除早期版本已安装的 `$ZSH_CUSTOM/01-first_run.zsh`。这个已退役文件仍会被 Oh My Zsh 的
自定义 `*.zsh` glob 匹配，并可能与 `99-first_run.zsh` 同时运行。迁移现有 home 时应显式删除它；不要假定当前写入器会
垃圾回收已退役目标。

当 Debian 的 OMZ `plugin.sh` 从 `plugins=(aliases)` 重建数组且未加入 `setup-env` 后，陈旧的 `setup-env.plugin.zsh` 不会生效。但待执行的
`99-first_run.zsh` 并非如此：在它被 source 前关闭 `APP_GIT`，仍会使其被 Oh My Zsh 的自定义 `*.zsh` glob 匹配。被 source 时，它会
先删除自身，再检查命令或启动交互工作，因此失败或取消的提示不会在每个新 shell 中重试。后续配置若产生
非空 first-run 渲染，会重新创建该文件，并允许新流程再次执行一次。

`00-setup_env.zsh.sh` 始终有无条件区段，并重建 `00-setup_env.zsh`；first-run 文件既不读取也不修改它。

`01-update.zsh.sh` 在两个平台上都有无条件区段，并完整重建 `01-update.zsh`；生成的文件被 source 时必须只定义
`update-all-in-one`。Debian 写入器在可选安装器之前运行，并根据导出的配置标志选择区块，而不是在渲染时探测命令
是否可用。因此，禁用组件标志会移除之前的可选更新区块，而不是保留陈旧输出。生成函数中的每个更新模块必须是一个顶层命令；
同一模块的多步操作用 `&&` 连接，模块不得用 `return` 退出聚合函数。这样模块失败只会停止自身，后续模块仍会继续更新。

在 macOS 上，`update-all-in-one` 依次运行 `brew update`、`brew upgrade --greedy` 和 `brew cleanup`，并将 `omz update` 保持为最后一个动作。Homebrew 会覆盖
其 formula 和 cask，因此 `APP_VSCODE` 不需要专用更新区块。

在 Debian 上，APT 负责更新由 APT 安装的工具。无条件 Homebrew 区块会更新 formula metadata、以 `--greedy` 升级所有已安装的 formula 和 cask，并
执行 cleanup；它也覆盖由 Homebrew 管理的 Claude Code、Node、Go，以及 protobuf 组件的 `clang-format` 和 `protobuf`。专用区块覆盖
tealdeer 缓存数据、`uv tool` 安装的工具、rustup 和 Yazi 插件。不要为 Go 恢复专用更新区块、扫描 `$GOBIN`/`$GOPATH/bin`、添加全局 Go
工具更新器或在此更新 `gopls`。

## Oh My Zsh 加载与插件顺序

Oh My Zsh 会先于插件初始化补全和库，随后按 `plugins=()` 顺序 source 插件，再按字母顺序 source `$ZSH_CUSTOM/*.zsh`，最后
加载主题。必须保持以下约束：

- 生成后，`setup-env` 会被前置，并保持为第一个插件。
- `01-update.zsh` 在 `00-setup_env.zsh` 之后、`99-first_run.zsh` 之前加载；source 它时绝不能运行更新。
- 生成后，`99-first_run.zsh` 保持为最后一个由配置流程管理的自定义 Zsh 文件，使延迟交互工作在受管理的运行时
  配置之后启动。
- `zsh-syntax-highlighting` 保持为 `plugins=()` 中的最后一项。
- `fzf-tab` 位于 `zsh-autosuggestions` 和 syntax highlighting 等包装器之前。
- 在本仓库中，`fzf-tab` 也位于 `fzf` 之前。fzf 会将当前 Tab 绑定捕获为 `fzf_default_completion`；颠倒两者会嵌套两个 fzf
  补全界面。
- 第三方克隆插件在 `ohmyzsh-full-autoupdate` 之后加载，后者的更新是同步的。
- 两个平台上，`brew` 都紧跟在 `aliases` 之后，以便在后续插件前建立 Homebrew 环境。它必须位于 `starship` 之前；在 macOS 上，
  它还位于 `command-not-found` 之前，后者的 Homebrew handler 期望 `brew` 已在 `PATH` 中。
- 官方 `starship` 插件会在插件加载阶段清除 `ZSH_THEME` 并初始化 prompt，时机早于自定义 `*.zsh` 文件和主题阶段。不要添加第二次
  `starship init` 或主题写入器。

Atuin 是刻意安排在插件之后的例外。它从 `00-setup_env.zsh` 初始化，以便在 fzf 加载后接管 Ctrl-R 和 Up；软件包提供的 Zsh 与
syntax-highlighting 组合仍可高亮此时新增的 widget。不要为了遵循通用顺序规则而将它提前。

Rust 是另一个刻意安排在插件数组之后的例外。Homebrew 的 keg-only `rustup` formula 将 `cargo`、`rustc` 和其他代理保留在
`$HOMEBREW_PREFIX/opt/rustup/bin`；`00-setup_env.zsh` 必须先将该目录前置到 `PATH`，再 source 官方 `rust` 插件。不要把 `rust`
重新加入 `plugins=()`：该插件会在 source 时检查 `cargo`，因早于 `00-setup_env.zsh` 加载而直接退出。Claude 集成也不得重新添加
上游安装器使用的 `$HOME/.cargo/bin`。

可选插件由提供相应命令的组件控制。启用 modern CLI 时，使用 Oh My Zsh 的 `zoxide` 插件并省略 `z`；未启用时，使用
`z` 并输出 zsh-z 设置。优先使用 Debian 供应商补全，而不是每次 shell 启动都重新生成补全的插件。

不要使用 `\<z\>` 删除插件名。连字符不是单词字符，因此该模式可能匹配 `fancy-ctrl-z` 的尾部、吞掉分隔符，并
将两个名称粘连。如果必须删除，请用空格和括号划定边界。在 macOS 上使用 BSD `sed -i ''`，在 Debian 上使用 GNU `sed -i`。

## Bash 与生成内容约定

仓库中的配置脚本都以 `#!/usr/bin/env bash` 和 `set -euo pipefail` 开头。部署到目标环境作为独立命令的
`debian/command/classic_cli/nanom` 是例外：它不是配置脚本，而是最小 POSIX wrapper，使用 `#!/bin/sh` 并通过
`exec /usr/bin/nano --modernbindings "$@"` 透明替换自身。

字面量使用单引号；只有 shell 必须展开美元符号、命令替换或转义时才使用双引号。`${VAR:-default}` 内的
默认值不加引号，因为外层双引号已经保护了展开：

```bash
BRANCH="${BRANCH:-master}"       # 正确
# BRANCH="${BRANCH:-'master'}"   # 会展开为带有字面引号的值
```

共享的生成 shell 文件具有第二层引号语义：配置流程中的 Bash 使用带引号的 heredoc 分隔符（`cat << 'EOF'`），而正文中的引号和转义
属于生成的 Zsh。带引号的分隔符会阻止在配置时展开 `$PATH`、`$HOME`、`$EDITOR` 和 fzf 占位符。

```bash
cat << 'EOF'
export PATH="$HOME/.local/bin:$PATH"
alias tree="eza --tree"
EOF
```

不要去掉 heredoc 分隔符的引号。fzf 预览字符串刻意包含经过转义的内层引号；扁平化任一层都会改变选项 tokenization。
保留 `-- {}`，使以 `-` 开头的候选项不会被解析为选项。捕获的区块输出使用 `printf '%s\n' "$blocks"`；参数展开
不会重新扫描值中的美元符号。对于追加到 `.zshenv` 等上游拥有的 shell 文件的字面行，使用单引号包裹的 `echo` 参数
仍然正确；不要引入配置时展开。

构造参数列表时使用数组，并引用 `"$@"`。路径、URL 和文件名应加引号；命令名和仓库既有的裸
选项值保持不加引号。

将求值为 false 的 `[[ ... ]] && command` 用作函数最后一条语句，会使函数返回 1。在 `set -e` 下，正常调用随后会中止脚本。任何
可能以可选 AND-list 结尾的函数，都必须使用 `if` 区块或显式 `return 0`；绝不要让成功与否取决于当前恰好排在最后的
调用。

原地 `sed` 编辑以已知上游标记为目标。没有行匹配时 `sed` 仍会成功退出，因此上游模板变化可能使编辑悄无声息地
变成空操作。编辑前验证标记，之后检查或断言结果文件。同样，执行 `ln -sf` 前应检查符号链接来源：即使来源不存在，
命令仍会成功，并产生悬空链接。

GitHub release 资产使用 `releases/latest/download/<asset>`。无版本资产使用一个字面 URL；带版本文件名只通过 `releases/latest`
解析版本来构造名称，拒绝空结果，并仍通过 `latest/download` 下载。`latest` 不是固定版本，两次请求之间可能发生竞争，并明确报出
404。copilot-api 是例外，因为版本是 Git ref 和镜像标签，而不是资产 URL。

可选工具执行前使用 `command -v` 保护条件。网络失败是致命错误，除非该操作被明确标为缓存预热；`tldr --update || true` 刻意
不是致命错误。

## 补全与配置陷阱

`compinit` 会发现名为 `_*` 的文件，然后注册文件第一个 `#compdef` 声明的命令；可执行文件名和符号链接文件名不会
改变该声明。

| 命令 | 软件包提供的补全 | 必需操作 |
| --- | --- | --- |
| `bat` | `_batcat` 声明 `batcat` | 链接二进制文件；在 `compinit` 后运行 `compdef bat=batcat` |
| `fd` | `_fd` 声明 `fd` | 将 `fd` 链接到 `fdfind`；无需 `compdef` |
| `tldr` | `tldr.zsh` 声明 `tldr` | 将其链接为 `$ZSH_CUSTOM/completions/_tldr` |

对于重命名的二进制文件，优先使用可执行符号链接而不是别名；子 shell、fzf 预览、`command -v` 和 Zsh 的 `$commands` 能看到 `PATH`，
但看不到别名。Oh My Zsh 模板在 `.zshrc` 中加入 `~/.local/bin`，这足以用于交互式插件探测，但不适用于非交互式 `zsh -c`；需要
非交互式路径的语言组件会写入 `.zshenv`。

应针对软件包提供的工具验证配置语义，而不是针对当前上游 master。Lazygit 和 micro 会静默忽略未知键，因此语法验证
无法发现失效配置。添加 lazygit 键之前，请检查该软件包版本的迁移列表：可迁移键会使 lazygit 重写
受管理文件。保持 `gui.nerdFontsVersion: "3"` 为字符串，保持 lazygit pager 为 `delta --paging=never`，并将 `MICRO_TRUECOLOR=1` 放在 shell 配置中，而
不是虚构 micro 设置。未知的 bat 或 fzf 选项则会使每次调用都失败；应使用已安装的二进制文件解析这些配置。`BAT_THEME`
会覆盖受管理的 bat 配置，因此不要同时设置两者。

Debian 受管理的 Nano 配置依赖系统 nanorc 加载软件包提供的语法定义；不要添加重复的 include glob。其选项面向 Nano
5.3 或更高版本，并避免会改变文件内容或与终端选择冲突的设置。classic CLI 会复制该制品，但不会安装 Nano。
Debian 仅在未启用 modern CLI 时选择运行 `/usr/bin/nano --modernbindings`（`nano -/`）的 `nanom` wrapper；启用 modern CLI 时改选 Micro。macOS 没有受管理的
Nano 制品，也从不选择 Nano。

新增插件或主题时，需要使用官方或积极维护的来源，默认值应来自官方设置或使用指南。不要因为部分工具使用 One Dark 覆盖，
就推断每个工具都需要该覆盖。

## Classic CLI

只有 Debian 会在统一 OMZ 流程和 Starship 之后无条件运行 `command/classic_cli/main.sh`。它不安装软件包：使用 `install -Dm 644` 将
随仓库提供的 `lesskey` 和 `nanorc` 制品复制到 `$HOME/.config/lesskey` 和 `$HOME/.config/nano/nanorc`，并以 `install -Dm 755` 将
`nanom` wrapper 安装到 `$HOME/.local/bin/nanom`。该 wrapper 仅供 `EDITOR` 调用，不会通过 alias 改变 `nano` 命令；less 和 Nano
来自平台基线。macOS 没有 classic CLI 组件。

## Debian modern CLI

`command/modern_cli/main.sh` 是可选的聚合叶脚本。它批量安装面向用户的现代工具，包括 `jq`、`unzip`、Atuin 和 fzf，然后运行
bat、fd、Micro 和 tealdeer 的固定子脚本。子脚本拥有各软件包专属链接、补全和静态配置；都没有独立标志。
`man-db` 是平台基线：完整的 Debian 主机应当提供它，而 `container/dev-container/Dockerfile` 会显式
安装它。

Atuin 从 Debian 批量安装，没有仓库拥有的配置。全新 home 使用软件包默认值，但早期版本安装的 `~/.config/atuin/config.toml`
会保留到显式删除为止。配置流程不会导入历史记录，也不会配置账户／同步。它的延迟初始化会接管 Ctrl-R 和 Up，而 fzf
保留 Ctrl-T、Alt-C 和 `**` 补全。

fzf 使用软件包提供的 shell 集成默认值，没有仓库拥有的静态配置。`setup-env` 插件不定义 fzf 引导变量。
插件加载后，`00-setup_env.zsh.sh` 从当前 `FZF_DEFAULT_COMMAND` 派生 `FZF_CTRL_T_COMMAND` 和 `FZF_ALT_C_COMMAND`，并添加 bat/eza 预览。
fzf-tab 区块使用五字段 `:completion:*:*:*:*:*` 模式，使其优先级高于 Oh My Zsh 的 menu 默认值，同时恢复颜色、保持 Git checkout 顺序，
并绑定分组导航。Bat 子脚本拥有受管理配置和规范链接；fd 拥有其链接，eza 别名来自早期 zstyle，zoxide
恰好通过其 OMZ 插件初始化一次。

Micro 真彩色保持为 `MICRO_TRUECOLOR=1`，modern CLI 选择 Micro 作为默认编辑器；tealdeer 拥有带保护条件的补全符号链接和一个
非致命缓存预热。Markdown code 组件通过 Linuxbrew 安装 `glow` 和提供 `markdownlint` 命令的 `markdownlint-cli`，拥有 Glow 的受管理配置并启用 TUI
鼠标支持；两个 formula 由无条件 Homebrew 区块统一升级，不需要专用更新区块。zoxide 不拥有静态配置或第二次初始化。

## Yazi 应用

`--app-yazi` 使用 Linuxbrew 安装 `yazi` formula；formula 拥有 `yazi`、`ya` 二进制文件。Yazi 依赖的 `file` 来自 Debian 基线，
`dev-container` 也会显式预装。Git fetcher 和 Git/keymap 插件为无条件安装。启用 modern CLI 时，app 会添加两个 Bat previewer 和官方 `piper`；
启用 Markdown 时，它会添加 Glow previewer 和第三方 `alberti42/faster-piper`，后者要求 Yazi 26.8.15 或更高版本。它会暴露 `$w`、`$h` 和
终端主题 `$t`；Glow 将
`$t` 作为 `dark` 或 `light` 使用，runner 保留 `-- "$1"`。command 和 code 组件会先运行，因此每个条件预览命令此时都已
可用。

安装插件后，`main.sh` 运行 `yazi.toml.sh`；该脚本创建 Yazi 配置目录，并直接写入完整的 `yazi.toml` 渲染。
`init.lua` 和 `keymap.toml` 仍是随仓库提供的制品。每个插件各自调用一次 `ya pkg add`，因此部分失败不会安装引用
缺失插件的配置。
后续成功运行可能在可变的 `package.toml` 中留下已禁用插件，但重新生成的配置不再引用它们。插件安装
先于配置渲染；因为 `ya pkg add` 会拒绝已列出的依赖，普通的重复运行可能在 `yazi.toml.sh` 前退出。不要依赖
重复运行来撤回 previewer。`y()` 包装器保留在 `00-setup_env.zsh.sh` 中；该脚本是 `00-setup_env.zsh` 的唯一写入器，且只有在
`APP_YAZI=1` 时才输出该包装器。

## Git 应用

`--app-git` 通过 Homebrew 安装 `gh`、提供 `delta` 的 `git-delta` 和 `lazygit`，并拥有全局 Git 设置、lazygit 配置、跟随 cwd 的
`lg()` 函数，以及延迟的 `gh auth login`。系统 Git 是仓库引导和安装 Oh My Zsh 所需的前置依赖；Git 叶脚本会保护但不会安装它。
实际写入器仍遵循共享所有权规则：Git 叶脚本写入工具和 Git 配置，`00-setup_env.zsh.sh` 写入 `lg()`，`99-first_run.zsh.sh` 写入一次性
登录区块。不要将 delta 或 lazygit 拆分到 modern CLI 中。

lazygit 配置面向软件包提供的 schema。它将 Nerd Fonts 版本 `"3"` 保持为字符串，并显式使用 `delta --paging=never`；lazygit 不会继承全局
`core.pager=delta`。`lg()` 函数使用 `LAZYGIT_NEW_DIR_FILE`，将父 shell 移动到 lazygit 退出时所在目录。

GitHub 登录通过 `99-first_run.zsh` 延迟执行，以兼容不会启动交互式 Zsh 的无人值守容器构建；其自删除、失败不重试和非空重建语义遵循
“空渲染不会撤回先前输出”一节。

## Claude Code 与 copilot-api

`debian/app/claude/main.sh` 通过 Linuxbrew 的 `claude-code` stable cask 安装 Claude Code，并由 APT 提供 `bubblewrap`、`jq` 和 `socat`。
`update-all-in-one` 通过 Homebrew 更新该 cask，不再调用 `claude update`。如果启用了 `--app-claude-copilot-api`，会先运行该子脚本，因为
它会替换 `~/.claude/settings.json`；通用插件安装在之后进行，以免清除 `enabledPlugins`。

通用官方插件为 `claude-code-setup`、`claude-md-management`、`claude-security` 和 `hookify`；`APP_GIT` 会增加 `commit-commands`。语言
集成始终与对应的语言服务器配对：Go 安装最新 `gopls` 和 `gopls-lsp`，Python 安装隔离的 `pyright[nodejs]` 和 `pyright-lsp`，
Rust 安装 rust-analyzer 和 `rust-analyzer-lsp`。语言组件更早运行并拥有各自的工具链。

脚本会在首次交互式启动前显式添加官方 marketplace。之后，`jq` 仅删除
`extraKnownMarketplaces["claude-plugins-official"]`，并仅在父对象为空时删除父对象。保留 `enabledPlugins`、自定义／copilot marketplace 和
独立 registry 状态。不要将此定点 JSON 清理直接替换为 `claude plugin marketplace remove`：该命令会移除 marketplace 配置，但不会卸载
已安装插件，其作用范围不同于这里只删除受管理 settings 条目。

copilot-api 子脚本会将提供的三个模型值原样写入设置，不查询 `/v1/models`，也不验证可用性。模型值
默认为空；base URL 默认为 `http://localhost:4141`，刻意设置的非机密 token 默认为 `dummy`。

`install_settings()` 将最终的 `ANTHROPIC_*` 值合并到随仓库提供的模板，并以目录权限 700、文件
权限 600 写入 `~/.claude/settings.json`。应将该模板视为 sandbox、permission、language、notification 和 workflow 偏好的事实来源，而不是将每个
值复制到此处。仅对官方文档列出且实际 model/provider/account 支持 1M context 的模型使用 `[1m]`；该后缀不会为任意模型或 gateway 增加
1M 能力。使用非第一方 gateway 时，成功还取决于协议转发能力及后端实际模型/provider。
`CLAUDE_CODE_AUTO_COMPACT_WINDOW` 和 `autoCompactWindow` 都是合法的自动压缩窗口覆盖项；除非需要针对已知 model/provider/gateway
限制校准，否则不要在受管理模板中硬编码。未覆盖时，Claude Code 使用针对当前模型调优的默认窗口；gateway 或自定义 model ID 可能需要
按后端真实限制显式校准。

copilot marketplace 会安装 `agent-inject` 和 `tool-search`。使用这个非第一方 `ANTHROPIC_BASE_URL` 时，应保持原生 `ENABLE_TOOL_SEARCH` 未设置，使
Claude Code 使用其文档说明的预先加载 fallback。仅当 gateway 会转发 `tool_reference` 区块时才将其设为 `true`。两个插件都需要
Node/npm/npx；启用该集成时，子脚本通过 Homebrew 安装 `node` formula。Node 仅服务于此集成，不是独立的 Debian 组件。

## 容器流程

`container/dev-container/main.sh` 对转发的 Debian 标志进行 NUL 编码，再对该字节流进行 base64 编码，并以 `setup_args_b64` 传递。Dockerfile
以只读 bind mount 挂载 Debian 构建上下文，使用 `mapfile -d ''` 解码数组，然后运行：

```bash
bash /mnt/setup/main.sh --unattended "${setup_args[@]}"
```

构建上下文是 `debian/`，因此镜像配置无法使用移到该树之外的文件。Debian 宿主把系统 `python3` 视为平台基线；它独立于
`debian/code/python.sh` 可选安装的 Linuxbrew `uv` 和 `py-spy`。精简的 dev-container 镜像必须在 Dockerfile 的基础包列表显式补齐。launcher 当前假定宿主为提供
`timedatectl` 的 Linux/systemd 环境，并要求 `LANG` 采用 `<locale>.<encoding>` 格式；现有检查只验证其非空。若要支持 macOS 宿主或
`LANG=C`，必须同步更新宿主预检、拆分逻辑和 Dockerfile 的 `localedef` 调用。无人值守模式安装 Oh My Zsh 但不启动它，且会更改
登录 shell；launcher 将主机的 `~/Projects` 挂载到具有特权的持久容器中。

`container/copilot-api/main.sh` 解析最新 release 以获取 Git ref 和镜像标签，从该 ref 构建，可选地通过 `/dev/tty` 运行交互式
认证，然后替换指定名称的服务容器、发布 4141 端口，并将主机的 `~/.copilot-api` 挂载为服务状态。

`container/copilot-api-config` 是包含 `jq` 和 `openssl` 的一次性镜像。它将同一主机目录挂载到 `/root/.copilot-api`，因此尽管容器内路径不同，
仍会修改服务的持久 `config.json`。`--clear-api-keys` 清空整个 `auth.apiKeys` 数组；`--generate-api-keys <N>` 追加
N 个独立生成的 32 字节十六进制密钥；`--add-api-key <v>` 原样追加一个非空固定密钥。旧参数 `--reset-api-key` 和
`--api-keys <N>` 分别是前两个参数的兼容别名。带值参数保持单值语义，重复时最后一个值生效；追加操作不去重。

宿主 launcher 将参数映射到 `CLEAR_API_KEYS`、`API_KEY_GENERATION_COUNT` 和 `API_KEY_TO_ADD`，并传入容器。
容器固定依次按需清空 key、追加随机 key，再追加固定 key；参数出现顺序不会改变该顺序。
该任务假定服务已经生成有效的 `config.json`。

## macOS 特有约束

macOS 的 `command/omz/` 树在安装器和插件写入器之外，还包含 `00-setup_env.zsh.sh` 和无条件的 `01-update.zsh.sh`；它没有
加载时设置写入器或延迟交互组件。`APP_VSCODE=1` 时，`00` 写入器会无条件选择 `code --wait`。
关闭所有标志时，其从 `# zsh-autosuggestions` 到 `ZSHZ_TILDE=1` 的输出，与 Debian 写入器中 Debian Editor 区段之后的内容一致。应保持该共享区块逐字节等同。不要将该共享区块抽离到两棵配置树之外，因为
仅使用 Debian 的 Docker 构建上下文看不到根级文件。

`macos/main.sh` 会在配置 Bash 进程中求值 `/opt/homebrew/bin/brew shellenv`，以便子安装器找到 Homebrew；之后的交互式发现
由 Oh My Zsh 的 `brew` 插件完成。绝对前缀目前是硬性要求——如果 Homebrew 位于其他位置，strict mode 会在子安装器前中止，
因此任何前缀泛化都必须显式更新此调用。

## 变更检查清单

完成变更前：

- 确认每个新标志由正确的分发器拥有；区分可运行组件和纯集成标志，并保持适用接口列表
  有序。
- 确认每个配置片段只有一个逻辑所有者，并根据读取时机放置 shell 设置。
- 检查全新 home，以及在相关标志关闭时重复配置同一 home 的行为。
- 保持 first-run 生命周期：空渲染保留当前待执行任务，source 时在交互前删除它，退役路径有文档说明的
  显式清理方式，非空重新渲染允许再次尝试一次。
- 使用软件包提供的工具验证随仓库提供的配置，包括解析器可能静默忽略的键。
- 运行 Bash 语法检查、ShellCheck、shfmt，以及已暂存／未暂存的空白检查。
- 渲染生成的 Zsh 并运行 `zsh -n`；对于插件顺序或 fzf 改动，使用真实 ZLE 冒烟测试。
