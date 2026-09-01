# CLAUDE.md

## 适用环境与文档边界

- 本仓库只面向全新且环境明确的目标系统（macOS、Debian 及仓库定义的容器流程）；无需兼容未知旧环境、非目标发行版或非目标平台，但必须遵守本文明确列出的 Bash 3.2 及其他具体约束。
- `README.md` 保持公开调用和参数简表；当前仍遗漏根入口独有的 `--branch`，仍含手动安装 VS Code 扩展的命令，并以未排除 `--app-claude-auth-token` 的 `(debian-flag)` 代表 dev-container 转发参数。这些是已知文档偏差，不是接口或安全先例；架构、维护、测试和手动安装说明属于本文件。

本文件只记录当前架构、可执行工作流、所有权边界，以及无法从单个脚本直接判断的故障模式。

## 项目结构

本仓库是一组 Bash 配置脚本，没有统一构建目标或自动化测试套件；容器流程会构建 Docker 镜像。公共入口通过管道执行：

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- [--branch <v>] [--setup <macos|debian|container>] [flags]
```

根 `main.sh` 只消费 `--branch` 和默认值为 `macos` 的 `--setup`；macOS 缺少 Command Line Tools 目录时只触发 `xcode-select --install`，Debian／container 未发现 Git 时通过 APT 安装，随后浅克隆请求分支并分发到 `<setup>/main.sh`。macOS 分支不会等待或验证 Command Line Tools 安装完成；其余 token 继续向下转发，克隆不会删除。各层 parser 会重新扫描全部 token，且没有 `--` 终止或 option/value 成组机制；下层参数值若等于上层保留标志（例如 `--add-api-key --branch` 或 `--add-api-key --image`），会被上层消费而无法原样到达目标 parser。根入口是唯一无 `BASH_SOURCE` 末尾保护的配置脚本，必须在 `curl | bash` 中无条件执行，也是 `--branch` 的解析事实来源。

- `macos/` 配置终端客户端／跳板机，不作为开发机配置，也不包含 Git 或 classic CLI 组件。
- `debian/` 配置开发环境；Homebrew、Zsh、Oh My Zsh、Starship 和不安装外部软件包的 classic CLI 基线无条件执行，其余组件可选。
- `container/main.sh` 消费默认值为 `dev-container` 的 `--image`，并直接执行 `./$IMAGE/main.sh`；`dev-container`、`copilot-api` 和一次性 `copilot-api-config` 是公开支持清单，不是 parser allowlist。`dev-container` 使用 `debian/` 作为构建上下文。

下文未带平台前缀的 `command/`、`code/` 和 `app/` 路径，均相对于所讨论的平台树。

Debian 首次安装 Homebrew 前会通过 APT 安装官方前置依赖。根分发器刻意不消费 `--unattended`：`command/homebrew.sh` 用它设置 `NONINTERACTIVE=1`，`command/omz/main.sh` 将它传给安装器并以 `sudo -n` 更改登录 shell。配置父脚本随后求值 `/home/linuxbrew/.linuxbrew/bin/brew shellenv bash`，供后代安装器发现 formula；交互式 Zsh 则由 `brew` 插件配置，不写 `.zshenv`。

Go 沿用该 PATH 契约；`CODE_GO` 和 `CODE_PROTOBUF` 分别让 OMZ `custom.sh` 安装 `$HOME/go/bin` 与 keg-only `clang-format` 的交互式 PATH 片段。

`debian/vscode/` 仅为参考数据，不由分发器安装。Debian 的 `--app-vscode` 只启用 OMZ 集成：在 VS Code 运行时选择 `code --wait`，且不输出 `VISUAL`。编辑器的 Nano／Micro 选择见“补全与配置陷阱”。应通过 `bash` 调用脚本，不依赖可执行位。

根 `main.sh` 和 `macos/` 必须兼容 Apple Bash 3.2；Debian 和容器代码可使用更新的 Bash。

## 检查与安全验证

从仓库根目录运行以下非破坏性检查。以下命令要求 `bash`、`git`、`shellcheck`、`shfmt` 和 `zsh` 已在 `PATH` 中；Debian 的 `--code-bash` 提供 `shellcheck` 和 `shfmt`：

```bash
find . \( -path './.git' -o -path './.claude' \) -prune -o \
    -type f -name '*.sh' -exec bash -n {} \;
sh -n debian/command/classic_cli/nanom
find . \( -path './.git' -o -path './.claude' \) -prune -o -type f -name '*.sh' \
    -exec shellcheck -x --rcfile './.shellcheckrc' {} +
shellcheck -s sh --rcfile './.shellcheckrc' debian/command/classic_cli/nanom
find . \( -path './.git' -o -path './.claude' \) -prune -o -type f -name '*.sh' \
    -exec shfmt -d -i 4 -bn -ci -s -sr {} +
find . \( -path './.git' -o -path './.claude' \) -prune -o -type f -name '*.zsh' \
    -exec zsh -n {} +
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

上述 `zsh -n` 只覆盖仓库制品；OMZ 改动还要验证生成的 `.zshrc`、部署后文件集合和运行时 ZLE：

1. 创建一次性目录树，同时设置 `HOME`、`ZSH_CUSTOM` 和受控 `PATH`；用 Oh My Zsh 模板初始化 `.zshrc`，为 `git` 提供桩程序，在 Linux 上验证 macOS 时再提供 BSD `sed` 垫片。
2. 导出所有组件变量（包括 `APP_VSCODE`），从 `command/omz/` 依次运行 `install_plugin.sh`、`update.sh`、`plugin.sh`、`custom.sh`。
3. 断言 `.zshrc` 只有一个顺序正确的 `plugins=(...)`，且 `$ZSH_CUSTOM` 与更新插件目录中的 basename 集合符合标志。
4. 对部署的 `.zshrc`、custom／更新片段及插件入口运行 `zsh -n`；启用 modern CLI 或 Rust 时还要检查 `pre-eza` 或 `brew-rustup` 插件。
5. 在 `zsh -f` 中用桩验证一次性片段：`99-gh-login.zsh` 先删除自身，再直接执行一次 `gh auth login`。

不要运行会修改真实 home 的 `command/omz/main.sh` 或 `install_omz`。没有 Homebrew／Starship 桩时也不要运行 `command/starship.sh`；其目标文件语义见“配置所有权与落点”。不要直接调用会执行真实更新的 `update-all-in-one`；调度验证必须使用一次性 `ZSH_CUSTOM`，并在 `zsh -f` 中为 `sudo`、`brew`、`tldr`、`uv`、`rustup`、`ya` 和 `omz` 提供函数桩。若测试目录包含 `98-copilot-api.zsh`，还必须桩化 `curl` 和 `bash`，或显式排除该片段。

对于 fzf shell 改动，请在 `zsh -f` 中检查 `${(z)FZF_CTRL_T_OPTS}` 和 `${(z)FZF_ALT_C_OPTS}`。插件顺序改动需要真实的 ZLE／PTY
冒烟测试：普通 Tab 和 `**<Tab>` 必须各自只打开一次 fzf；`fzf_default_completion` 必须为 `fzf-tab-complete`；Ctrl-T 和 Alt-C 必须保持单次调用。

## 分发器契约

平台根入口和真正的嵌套分发器遵循以下数据流：

1. 以可覆盖的默认值初始化自身标志，并导出后代会读取的值。
2. `parse_args()` 逐 token 消费自身标志，将未知 token 追加到 `POSITIONAL`；布尔标志只 shift 一次，值标志用 `numOfArgs` 防止在 `set -u` 下读取缺失的 `$2`，但不会保留下层 option/value 分组。值标志位于参数尾部时会被静默丢弃并保留当前值；未知 token 若最终没有任何下层 parser 消费，也会被静默忽略。
3. 恢复转发 token 并调用 `main()`；每一层都会重新解析，具体值碰撞限制见根入口说明。
4. 无条件基线按显式依赖顺序执行；可选组件按 command、code、app 分组且组内按字母排序。
5. 每个可选组件自行安装或保护其所需命令；除有明确集成契约外，不得依赖另一可选标志。

普通可运行组件的导出块、解析器 case、`main()` 保护条件和 `README.md` 表是同一接口的四个有序视图。Debian `APP_VSCODE` 是纯集成例外：它有导出、解析器和 README 标志，但没有叶脚本或 `main()` 保护；OMZ 用它选择插件和 `02-vscode.zsh`。不要为对称性虚构空保护条件。

标志通过导出变量和转发参数向下级联；跨组件读取只在双方启用时增加集成行为：

| 消费者 | 读取的上游标志 |
| --- | --- |
| Debian OMZ 写入器 | `COMMAND_MODERN_CLI`、`CODE_GO`、`CODE_PROTOBUF`、`CODE_PYTHON`、`CODE_RUST`、`APP_DOCKER`、`APP_GIT`、`APP_TMUX`、`APP_VSCODE`、`APP_YAZI` |
| macOS OMZ 写入器 | `COMMAND_SSH`、`APP_VSCODE` |
| Claude app | `CODE_GO`、`CODE_PYTHON`、`CODE_RUST`、`APP_GIT` |
| Yazi | `COMMAND_MODERN_CLI`、`CODE_MARKDOWN` |
| Debian classic CLI | `COMMAND_MODERN_CLI` |

组件拥有安装及其非 shell 配置；后者可以是整文件、键级、追加式或上游文件 patch，相关组件说明必须明确其所有权形态。共享 shell 配置片段必须由相应 OMZ 写入器生成，不能由叶组件直接追加；当前明确例外是 modern CLI 为满足补全加载时序而直接管理 `$ZSH_CUSTOM/completions` 中的受控链接，以及 `container/copilot-api/main.sh` 在服务启动成功后安装 `98-copilot-api.zsh`。

除根管道入口外，分发器和叶脚本必须可 source，并沿用相邻脚本的 `BASH_SOURCE` 末尾保护；无参数叶脚本不引入解析器或 `POSITIONAL`。根入口和 macOS 还必须保留 Bash 3.2 兼容的空数组恢复形式：

```bash
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"
```

不要将其规范化为 Debian 的 `"${POSITIONAL[@]}"`；Bash 3.2 配合 `set -u` 可能拒绝空数组展开。

添加组件时，同步所有适用的接口视图，列出纯集成标志的读取者，并选择与是否接收参数匹配的末尾保护。

## 配置所有权与落点

每个共享配置片段只有一个逻辑所有者，但 `.zshrc` 由多个写入器协同管理。每棵配置树的 `command/omz/main.sh` 都会安装 Oh My Zsh、
准备其模板，然后依次运行 `install_plugin.sh`、`update.sh`、`plugin.sh` 和 `custom.sh`。Debian 安装器还会启用模板中的用户 bin PATH。
两平台的 `install_plugin.sh` 拥有第三方插件克隆，Debian 版本还按组件标志复制仓库内的 `pre-eza` 和 `brew-rustup` 插件目录；
`update.sh` 拥有 `update-all-in-one` 插件入口和平台更新片段；`container/copilot-api/main.sh` 拥有 `98-copilot-api.zsh`；`plugin.sh` 只拥有插件数组，并仅启用本次安装流程已经物化的条件插件。

| 配置需求方 | 配置所属目标位置 |
| --- | --- |
| `compinit`、Oh My Zsh 库、插件列表 | `.zshrc` |
| Starship prompt 外观 | `$HOME/.config/starship.toml` |
| eza 在 source 过程中需要的 zstyle | `$ZSH_CUSTOM/plugins/pre-eza/pre-eza.plugin.zsh` |
| Rust 插件在 source 前需要的 rustup 代理 PATH | `$ZSH_CUSTOM/plugins/brew-rustup/brew-rustup.plugin.zsh` |
| keg-only `clang-format` 的交互式 PATH | `$ZSH_CUSTOM/04-clang-format.zsh` |
| 别名、集成函数、`compdef`、运行时变量、编辑器选择 | `$ZSH_CUSTOM/<custom basename>` |
| 用户调用的聚合更新函数及其更新片段 | `$ZSH_CUSTOM/plugins/update-all-in-one/` |
| 延迟执行的 GitHub CLI 登录 | `$ZSH_CUSTOM/99-gh-login.zsh` |

`custom.sh` 从各平台的 `command/omz/custom/` 选择静态 Zsh 片段，保留源 basename 安装到 `$ZSH_CUSTOM`，由文件名字典序决定加载顺序；文件名已承担区块标识，正文不重复标题。读取时机决定设置应进入加载前的自定义插件还是加载后的编号 custom 片段，具体顺序约束见“Oh My Zsh 加载与插件顺序”。

`--code-python` 使用 Linuxbrew 管理 `uv` formula，并由 `uv tool` 隔离安装 `py-spy`；Debian 系统 `python3` 仍是平台基线，项目使用的
Python 运行时则由 `uv` 安装和管理，不额外安装 Homebrew `python` formula。Python 集成会启用 Oh My Zsh 的 `python` 和 `uv` 插件，
但刻意不设置 `PYTHON_AUTO_VRUN`。uv 无需该手动自动激活开关即可发现虚拟环境；不要重新引入它。

运行时工具配置默认作为仓库制品部署，而不是由 shell 渲染；文件通常使用 `install -m 644`，Debian 需要同时创建父目录时可使用 GNU `install -D`，macOS 则先 `mkdir -p` 再运行 `install -m`。OMZ 自定义插件是目录制品，`install_plugin.sh` 使用 `cp -R` 部署，以便将来增加辅助文件。Claude 基础设置作为静态 `settings.json` 制品安装，copilot-api 再用 `jq` 更新已部署文件中的动态字段；Python 的 Ruff 基线是从外部 `main` 分支下载的例外。

重新运行会覆盖本次选中的静态制品，但不会删除未选中项或旧副本；关闭标志不等于卸载，清理必须显式执行。追加式上游集成不在此覆盖保证内。生成式配置则各有不同语义：

- Starship 不传 `--force`，只在目标不存在时生成 `starship.toml`，存在即失败。
- Yazi 的配置写入和 `package.toml` 所有权见“Yazi 应用”。

Starship 迁移不会删除旧 Powerlevel10k 克隆或 Debian 不管理的 `.p10k.zsh`；官方 Starship 插件会先清除旧 `ZSH_THEME`，因此它们不会生效。

### 一次性 GitHub 登录

Debian 的 `custom.sh` 只在 `APP_GIT=1` 时安装静态 `99-gh-login.zsh`，因此片段被加载时直接先删除自身，再运行 `gh auth login`，不重复检查命令或认证状态。登录失败或取消后不会在每个新 shell 中重试；单独以 `APP_GIT=1` 重跑 `command/omz/custom.sh` 会再次安装该片段。完整 Debian 流程是否能到达该写入器，仍受固定目标目录的第三方插件克隆非幂等性约束。

### 重复运行与更新

Debian 的 OMZ `plugin.sh` 会从 `plugins=(aliases)` 重建数组；旧 home 中残留的 `setup-env` 插件，以及当前标志未启用的
`pre-eza` 或 `brew-rustup` 目录都不会出现在数组中，因此不会生效。

`custom.sh` 始终安装无条件片段和本次选中的条件片段。受上文不清理规则影响，关闭 `APP_GIT` 后，尚未 source 的残留 `99-gh-login.zsh` 仍会执行一次。

两平台的 `update.sh` 都安装 `update-all-in-one` 入口和平台更新片段；Debian 根据导出标志选择可选片段，而不在安装时探测命令。受通用不清理规则影响，旧的可选更新片段以及已部署的旧 basename 都会保留，重命名片段后重跑可能重复执行，清理必须显式进行。`container/copilot-api/main.sh` 在服务容器成功启动后另行安装 `98-copilot-api.zsh`；该片段固定从 `master` 重新调用根入口，不继承首次部署使用的 `--branch`。

`update-all-in-one.plugin.zsh` 被 source 时只定义 `update-all-in-one`，绝不能运行更新。函数使用 Zsh 默认字典序遍历
`$ZSH_CUSTOM/plugins/update-all-in-one/custom` 中的全部 `*.zsh`，并在当前 Zsh 中逐一 source。仓库的平台片段用数字前缀声明执行顺序，并把运行
`omz update` 的片段固定命名为 `99-oh-my-zsh.zsh`；运行器不要求文件名具有数字前缀。安装 copilot-api updater 后，`98-copilot-api.zsh`
紧邻并位于 `99-oh-my-zsh.zsh` 之前，因此当前仓库制品总是以 `omz update` 收尾。同一模块的多步操作用 `&&` 连接。运行器不会检查每次
`source` 的返回值；默认交互式 Zsh 会继续执行后续片段，最终成功可能掩盖前序失败。`&&` 只保证同一片段内的后续步骤在前一步失败时不执行。

在 macOS 上，平台片段依次运行 `brew update`、`brew upgrade --greedy`、`brew cleanup` 和 `omz update`。Homebrew 会覆盖其
formula 和 cask，因此 `APP_VSCODE` 不需要专用更新片段。

在 Debian 上，APT 负责更新由 APT 安装的工具。无条件 Homebrew 片段会更新 formula metadata、以 `--greedy` 升级所有已安装的 formula 和 cask，并
执行 cleanup；它也覆盖由 Homebrew 管理的 Claude Code、Node、Go，以及 protobuf 组件的 `clang-format` 和 `protobuf`。专用片段更新
tealdeer 缓存数据、包括 `py-spy` 在内的 `uv tool`、rustup 和 Yazi 插件；完整平台流程成功后，对应命令由安装这些片段的组件提供。`update.sh`
先于可选组件运行，因此中途失败可能留下引用尚未安装命令的片段。不要为 Go 恢复专用更新片段、扫描 `$GOBIN`/`$GOPATH/bin`、添加全局
Go 工具更新器或在此更新 `gopls`。

`ohmyzsh-full-autoupdate` 在 shell 初始化期间独立更新带实体 `.git` 目录的 custom 插件和主题。不要调用其私有实现、操作 `.zsh-update` 标签，或把需要权限和交互的系统更新接入启动路径；`update-all-in-one` 也不重复扫描这些仓库，两者只共享官方 `omz update` 边界。

## Oh My Zsh 加载与插件顺序

Oh My Zsh 先初始化补全和库，再按 `plugins=()` 顺序 source 插件、按字典序 source `$ZSH_CUSTOM/*.zsh`，最后加载主题。必须保持：

- modern CLI 的 `pre-eza` 紧邻并位于 `eza` 前，使 source 期间读取的 zstyle 及时生效；不要移到编号 custom 片段。
- custom 片段保留源 basename；`99-gh-login.zsh` 是最后一个受管理片段。`ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets)` 必须留在 syntax-highlighting 加载后的 custom 片段，否则插件无法安装 `main` highlighter。
- `update-all-in-one` 在插件阶段、`ohmyzsh-full-autoupdate` 之前加载；它只定义函数，执行语义见上一节。第三方克隆插件在同步更新它们的 `ohmyzsh-full-autoupdate` 之后加载。
- `zsh-syntax-highlighting` 是 `plugins=()` 最后一项；`fzf-tab` 位于 autosuggestions、syntax highlighting 等包装器之前，也位于 `fzf` 前。fzf 会捕获当时的 Tab 绑定为 `fzf_default_completion`，颠倒后二者会嵌套打开补全界面。
- `brew` 紧跟 `aliases`，位于 `starship` 前。
- 官方 `starship` 插件在 custom 片段和主题之前清除 `ZSH_THEME` 并初始化 prompt；不要添加第二次 `starship init` 或主题写入器。

Atuin 是刻意安排在插件之后的例外。它从 `09-atuin.zsh` 初始化，以便在 fzf 加载后接管 Ctrl-R 和 Up；软件包提供的 Zsh 与
syntax-highlighting 组合仍可高亮此时新增的 widget。不要为了遵循通用顺序规则而将它提前。

Debian 启用 Rust 时必须保持 `brew` → `brew-rustup` → `rust`：前者建立 Homebrew 环境，中间插件前置 keg-only 工具链代理路径，官方 `rust` 插件随后才能在 source 时发现 `cargo`。不要重排，也不要在 Claude 集成中重新添加上游安装器使用的 `$HOME/.cargo/bin`。

可选插件通常由提供相应命令的组件控制。启用 modern CLI 时使用 `zoxide` 并省略 `z`，未启用时使用 `z` 并输出 zsh-z 设置；Homebrew completion 的加载时机见“补全与配置陷阱”。

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

编号 custom 片段和平台 `update-all-in-one` 片段当前均作为仓库内静态 `.zsh` 制品维护，由 `custom.sh` 或 `update.sh` 直接部署；不存在
heredoc、`$blocks` 或 `.zshenv` 生成层。直接编辑这些静态制品，并保留需要在 Zsh source 时展开的 `$PATH`、`$HOME`、`$EDITOR` 和 fzf
占位符。fzf 预览字符串刻意包含
嵌套引号；扁平化任一层都会改变选项 tokenization。保留 `-- {}`，使以 `-` 开头的候选项不会被解析为选项。

将求值为 false 的 `[[ ... ]] && command` 用作函数最后一条语句，会使函数返回 1。在 `set -e` 下，正常调用随后会中止脚本。任何
可能以可选 AND-list 结尾的函数，都必须使用 `if` 区块或显式 `return 0`；绝不要让成功与否取决于当前恰好排在最后的
调用。

原地 `sed` 编辑以已知上游标记为目标。没有行匹配时 `sed` 仍会成功退出，因此上游模板变化可能使编辑悄无声息地
变成空操作。当前两平台 OMZ `plugin.sh`、Debian OMZ 的 PATH 修改和 tmux 配置 patch 都直接执行 `sed -i`，没有前置标记验证或后置断言；这是现有失败语义。新增或修改此类写入器时应验证标记并检查结果。同样，执行 `ln -sf` 前应检查符号链接来源：即使来源不存在，命令仍会成功，并产生悬空链接。

对未由当前组件或明确前置组件保证的外部命令，执行前使用 `command -v`。多数直接网络调用的失败会在 strict mode 下中止；缓存预热 `tldr --update || true` 是显式非致命例外。两平台的 Homebrew／Oh My Zsh 安装器当前都先在 `-c "$(curl -fsSL ...)"` 的命令替换中下载，再分别由 `bash`／`sh` 执行；下载失败可能变成执行空脚本并返回成功，不属于致命保证。交互式 `update-all-in-one` 的跨片段失败语义见其专节。

## 补全与配置陷阱

`compinit` 只发现 `_*` 文件，并按文件首个 `#compdef` 注册命令；可执行文件名或符号链接名不会改变该声明。Oh My Zsh 在 `compinit` 前将 `$ZSH_CUSTOM/completions` 加入 `fpath`，而 `brew` 插件更晚才追加 Homebrew `site-functions`，因此 modern CLI 必须通过动态 `brew --prefix` 提前部署受管理链接。创建每个链接前分别验证来源；后续失败不会回滚已创建链接或中间配置。不要硬编码 Linuxbrew／Cellar 前缀、产生悬空链接，或为此写 `.zshenv`。

应使用软件包实际提供的工具验证配置，而不是针对上游 master。Lazygit 和 Micro 会静默忽略未知键，且迁移可能重写受管理文件；Lazygit 的具体 schema 约束见“Git 应用”。未知的 bat、fzf 或 delta 选项会使调用失败，也必须由已安装二进制逐项解析。

Micro 真彩色只由 `micro.settings.json` 的 `"truecolor": "on"` 管理，不要恢复 `MICRO_TRUECOLOR`。`BAT_THEME` 会覆盖受管理 bat 配置，因此不要同时设置。

Debian 受管理的 Nano 配置依赖系统 nanorc 加载软件包提供的语法定义；不要添加重复的 include glob。其选项面向 Nano
5.3 或更高版本，并避免会改变文件内容或与终端选择冲突的设置。classic CLI 仅在未启用 modern CLI 时复制该制品和 `nanom` wrapper，但不会安装 Nano。
在没有冲突残留片段的新 home 中，Debian 未启用 modern CLI 时安装 `00-nano.zsh`，把 `EDITOR` 设为运行 `/usr/bin/nano --modernbindings`（`nano -/`）的 `nanom` wrapper；启用时安装 `01-micro.zsh` 并选择 Micro。写入器不删除未选中片段；modern → classic 重跑会保留后加载的 `01-micro.zsh`，切换回 `nanom` 必须显式删除旧片段。macOS 没有受管理的 Nano 制品，也从不选择 Nano。

新增插件或主题时，需要使用官方或积极维护的来源，默认值应来自官方设置或使用指南。不要因为部分工具使用 One Dark 覆盖，
就推断每个工具都需要该覆盖。

## Classic CLI

Debian 在 OMZ 和 Starship 后无条件运行 classic CLI；Less 配置始终部署，Nano 配置和 `nanom` 仅在未启用 modern CLI 时部署，且不安装软件包。`nanom` 只供 `EDITOR` 选择，不通过 alias 改变 `nano`；macOS 没有该组件。

## Debian modern CLI

`command/modern_cli/main.sh` 是可选聚合叶脚本，拥有其 formula、Homebrew completion 链接、bat／Micro 静态配置和 Micro `detectindent` 插件；具体工具清单以脚本为准。`man-db` 是 Debian 平台基线，精简的 dev-container 会显式安装。

Atuin 没有仓库原生配置；旧 `~/.config/atuin/config.toml` 会保留，配置流程不导入历史记录或配置账户／同步。其延迟初始化和按键所有权见 OMZ 顺序章节。

fzf 也没有原生配置；formula 提供 shell 集成，受管理片段从 `FZF_DEFAULT_COMMAND` 派生 Ctrl-T／Alt-C 命令并增加预览。`pre-eza` 只负责 eza 加载前的 zstyle。fzf-tab 使用五字段 completion 模式覆盖 OMZ menu 默认值，并保留颜色、Git checkout 顺序和分组导航。

Micro 与编辑器规则见“补全与配置陷阱”。安装阶段不预热 tealdeer 缓存；只有用户调用 `update-all-in-one` 时才非致命地运行 `tldr --update`。Markdown 组件拥有 Glow 配置并启用 TUI 鼠标；formula 更新由通用 Homebrew 片段负责。zoxide 只通过 OMZ 插件初始化一次。

## Yazi 应用

`--app-yazi` 安装拥有 `yazi`／`ya` 的 formula；`file` 来自 Debian 基线，dev-container 会显式补齐。插件清单以脚本为准；modern CLI 和 Markdown 只在其命令已由前序组件提供时增加对应 previewer，并须保持第三方 previewer 与当前 Yazi 版本兼容。

插件在配置写入前由 `ya pkg add` 逐个安装；任一失败都会跳过本次全部配置写入，使新 home 无配置、旧 home 保留旧配置和已成功添加的插件。随后 `yazi.toml.sh` 创建目录并完整渲染 `yazi.toml`，`init.lua` 和 `keymap.toml` 则是静态制品。

`package.toml` 由 `ya` 拥有，仓库不直接编辑或垃圾回收；`ya pkg add` 会拒绝已列出的依赖，替换同名插件的来源时必须先 `ya pkg delete` 旧来源。因此普通重复运行可能在配置渲染前失败；后续成功运行会停止引用已禁用插件，却不删除它们。关闭 `APP_YAZI` 也不会删除已安装的 `15-yazi.zsh` 包装器。

## tmux 应用

`--app-tmux` 安装 tmux formula，并在每次运行时下载、执行未固定版本的 `gpakosz/.tmux` `master/install.sh`，再 patch 上游生成的 `$HOME/.config/tmux/tmux.conf.local`，并无仓库侧查重地追加静态 `tmux.conf`。该制品无条件启用 passthrough、extended keys、Ghostty terminal features 和 OSC 52 集成：`set-clipboard on` 允许 pane 内应用写入终端剪贴板并创建 tmux buffer，`get-clipboard request` 则向最近使用的终端请求剪贴板且不保存读取结果。两者都是 server 级选项，会影响同一 server 下的全部 session；终端允许读取时，远程或不可信 pane 程序也能读写客户端系统剪贴板，当前受管理的 Ghostty 配置会直接允许读取。上游安装器会先把活动配置目录移为时间戳备份再重建，因此正常重跑不会在活动文件中累积该区块，但会保留备份目录，且未固定的上游行为可能变化。OMZ 启用 `copybuffer`、`copyfile` 和 `tmux`；只有 formula 由通用 Homebrew 片段更新，没有 Oh My Tmux 专用更新片段。

## Docker 应用

`--app-docker` 每次覆盖 `/etc/apt/keyrings/docker.asc` 和 `/etc/apt/sources.list.d/docker.list`，并拥有 Docker Engine、CLI、containerd、Buildx、Compose、docker 用户组成员关系和 lazydocker，不部署容器服务。`usermod -aG docker` 只影响新登录会话；运行 `container/` 目标前应重新登录，使当前用户无需 `sudo` 即可访问 Docker daemon。

## Git 应用

`--app-git` 拥有 `gh`、delta 和 lazygit；非空的 `--app-git-user-name`／`--app-git-user-email` 写入 Git global scope，并无条件拥有 `core.pager`、`interactive.diffFilter`、`delta.navigate`、`delta.line-numbers`、`delta.side-by-side`、`delta.syntax-theme` 和 `merge.conflictStyle` 这些 global 键，以及完整的 `$HOME/.config/lazygit/config.yml`，但不拥有整个 `.gitconfig`。系统 Git 依赖根引导器的 Command Line Tools／APT 前置流程；叶脚本不安装或检查。OMZ `custom.sh` 则拥有 `lg()` 和一次性登录片段；其登录生命周期见“一次性 GitHub 登录”。不要把 delta 或 lazygit 移入 modern CLI。

lazygit 配置必须匹配已安装版本的 schema：`gui.nerdFontsVersion` 保持字符串 `"3"`，`gui.filterMode` 为 `fuzzy`；`git.diffRenderers` 依次使用 `delta --paging=never --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"`、`rawGit --color-words` 和默认 raw Git。它不会继承全局 `core.pager=delta`。`lg()` 通过 `LAZYGIT_NEW_DIR_FILE` 将父 shell 切换到退出目录。

## Claude Code 与 copilot-api

`debian/app/claude/main.sh` 通过 Homebrew 安装 `claude-code@latest` cask，并由 APT 提供 sandbox／JSON／socket 依赖；通用 Homebrew 更新片段负责升级，不调用 `claude update`。父脚本每次先以仓库模板替换 `~/.claude/settings.json`；启用 copilot-api 时再运行同目录的 `copilot_api.sh`，定点合并网关设置并安装其插件，之后安装通用插件，以保留两组 `enabledPlugins`。

插件清单以脚本为准。语言集成必须与对应语言服务器成对启用，并依赖更早运行的语言组件提供工具链；Git 插件只在 `APP_GIT=1` 时安装。

脚本会在首次交互式启动前显式添加官方 marketplace。之后，`jq` 仅删除
`extraKnownMarketplaces["claude-plugins-official"]`，并仅在父对象为空时删除父对象。保留 `enabledPlugins`、自定义／copilot marketplace 和
独立 registry 状态。不要将此定点 JSON 清理直接替换为 `claude plugin marketplace remove`：该命令会移除 marketplace 配置，但不会卸载
已安装插件，其作用范围不同于这里只删除受管理 settings 条目。

`copilot_api.sh` 会将提供的三个模型值原样写入设置，不查询 `/v1/models`，也不验证可用性。模型值
默认为空；base URL 默认为 `http://localhost:4141`，刻意设置的非机密 token 默认为 `dummy`。

`install_settings()` 以目录权限 700、文件权限 600 将仓库中的基础模板安装到 `~/.claude/settings.json`；随后，
`copilot_api.sh` 的 `update_settings()` 将最终的 `ANTHROPIC_*` 值合并到这个已部署文件。应将基础模板视为 sandbox、permission、language 和 workflow 偏好的事实来源，而不是将每个值
复制到此处。仅对官方文档列出且实际 model/provider/account 支持 1M context 的模型使用 `[1m]`；该后缀不会为任意模型或 gateway 增加
1M 能力。使用非第一方 gateway 时，成功还取决于协议转发能力及后端实际模型/provider。
`CLAUDE_CODE_AUTO_COMPACT_WINDOW` 和 `autoCompactWindow` 都是合法的自动压缩窗口覆盖项；除非需要针对已知 model/provider/gateway
限制校准，否则不要在受管理模板中硬编码。未覆盖时，Claude Code 使用针对当前模型调优的默认窗口；gateway 或自定义 model ID 可能需要
按后端真实限制显式校准。

copilot marketplace 会安装 `agent-inject` 和 `tool-search`。使用这个非第一方 `ANTHROPIC_BASE_URL` 时，应保持原生 `ENABLE_TOOL_SEARCH` 未设置，使
Claude Code 使用其文档说明的预先加载 fallback。仅当 gateway 会转发 `tool_reference` 区块时才将其设为 `true`。两个插件都需要
Node/npm/npx；启用该集成时，`copilot_api.sh` 通过 Homebrew 安装 `node` formula。Node 仅服务于此集成，不是独立的 Debian 组件。

## 容器流程

`container/dev-container/main.sh` 对转发的 Debian 标志进行 NUL 编码，再对该字节流进行 base64 编码，并以 `setup_args_b64` 传递。Dockerfile
以只读 bind mount 挂载 Debian 构建上下文，使用 `mapfile -d ''` 解码数组，然后运行：

```bash
bash /mnt/setup/main.sh --unattended "${setup_args[@]}"
```

launcher 只检查 Ghostty 标记及构建所需环境变量，不验证 SSH 或 login shell：`TERM_PROGRAM` 必须为 `ghostty`，且 `USER`、`LANG`、`TERM`、`COLORTERM` 和
`TERM_PROGRAM_VERSION` 都必须非空，否则在构建前失败。`TERM`、`COLORTERM`、`TERM_PROGRAM` 和 `TERM_PROGRAM_VERSION` 通过 build ARG 原样写入最终镜像 `ENV`。宿主使用
`infocmp -x "$TERM"` 导出当前条目并以 `terminfo_b64` 传递；镜像在基础 APT 包补齐 `ncurses-bin` 并完成无人值守 setup 后，由当前容器用户
使用 `tic -x` 编译到 `/home/${user}/.terminfo`。APT 和 setup 阶段刻意不注入终端 `ENV`；terminfo 与宿主派生的终端 `ENV` 都位于 setup 后，
避免终端或 Ghostty 版本变化使 APT 和完整 setup 缓存失效。

`setup_args_b64` 和 `terminfo_b64` 都只编码数据，不提供保密性。前者不得承载 `--app-claude-auth-token` 或其他秘密值；否则 Debian 配置会把凭据写入
镜像内的用户设置。后者只承载 `infocmp` 输出。引入 Docker secret 或运行时注入机制前，不要通过 dev-container 的 build ARG 转发秘密参数。

构建上下文是 `debian/`，因此镜像配置无法使用移到该树之外的文件。Debian 宿主把系统 `python3` 视为平台基线；它独立于
`debian/code/python.sh` 可选安装的 Linuxbrew `uv` 和由 `uv tool` 管理的 `py-spy`。精简的 dev-container 镜像必须在 Dockerfile 的基础包列表显式补齐。launcher 当前假定宿主为提供
`timedatectl` 的 Linux/systemd 环境，并要求 `LANG` 采用 `<locale>.<encoding>` 格式；现有检查只验证其非空。若要支持 macOS 宿主或
`LANG=C`，必须同步更新宿主预检、拆分逻辑和 Dockerfile 的 `localedef` 调用。无人值守模式安装 Oh My Zsh 但不启动它，且会更改
登录 shell；dev-container 预期通过 `docker exec` 进入交互式 Zsh，不保证直接执行的非交互命令能发现 Homebrew。launcher 在同名容器已存在时拒绝启动；新容器使用 `--privileged`、`unless-stopped` 和具有 `NOPASSWD:ALL` 的用户，并可写挂载主机的 `~/Projects`，两侧因此属于同一信任边界。Dockerfile 创建用户时不指定数值 UID／GID，launcher 也不与宿主显式对齐，bind mount 可能产生文件所有权差异。

`container/copilot-api/main.sh` 解析最新 release 以获取 Git ref 和镜像标签，从该 ref 构建，可选地通过 `/dev/tty` 运行交互式
认证，然后替换固定名为 `copilot-api` 的服务容器，并将主机的 `~/.copilot-api` 挂载为服务状态。认证会以 `root:root`、0700 创建该目录；服务和配置容器分别把它挂载到各自的 root 状态路径。`-p 4141:4141` 未指定宿主 IP 或协议，会请求按 Docker 默认绑定把宿主 TCP 4141 发布到容器 TCP 4141，通常对全部宿主地址开放；仓库不固定 daemon 的默认绑定或上游应用的监听地址，也不提供 TLS 或网络访问控制。仅允许可信网络访问，或另行使用 API key、防火墙或可信代理。launcher 会先完成版本解析、镜像构建和可选认证，再删除旧容器并运行新容器；
删除旧容器前失败会保留旧服务，但删除后若 `docker run` 失败则没有回滚或 health check，服务会保持停止。

`container/copilot-api-config` 是包含 `jq` 和 `openssl` 的一次性镜像。它将同一主机目录挂载到 `/root/.copilot-api`，因此尽管容器内路径不同，
仍会修改服务的持久 `config.json`。`--clear-api-keys` 清空整个 `auth.apiKeys` 数组；`--generate-api-keys <N>` 追加
N 个独立生成的 32 字节十六进制密钥；`--add-api-key <v>` 将实际到达该 parser 的非空值原样追加为固定密钥。旧参数 `--reset-api-key` 和
`--api-keys <N>` 分别是前两个参数的兼容别名。带值参数在该 parser 内保持单值语义，重复时最后一个值生效；追加操作不去重。祖先 parser 的值碰撞限制见根入口说明。

宿主 launcher 将参数映射到 `CLEAR_API_KEYS`、`API_KEY_GENERATION_COUNT` 和 `API_KEY_TO_ADD`，并传入容器。
容器固定依次按需清空 key、追加随机 key，再追加固定 key；参数出现顺序不会改变该顺序。`--add-api-key` 的值会经过宿主命令行和 Docker 环境变量，可能暴露在 shell 历史、进程参数或 Docker 元数据中，不是秘密注入通道。
该任务假定服务已经生成有效的 `config.json`。

## macOS 特有约束

macOS 沿用“配置所有权与落点”中的 OMZ 写入器顺序，但没有 Debian 的条件 PATH、Atuin、fzf 或一次性登录片段。它只安装 Homebrew／Oh My Zsh 更新片段，以及 VS Code（条件式）、autosuggestions、syntax-highlighting、you-should-use 和 z 的 custom 片段；`APP_VSCODE=1` 时选择 `code --wait`。
macOS 的 `01-zsh-autosuggestions.zsh`、`02-zsh-syntax-highlighting.zsh`、`03-you-should-use.zsh` 和 `04-z.zsh` 必须分别与 Debian 的
`05-zsh-autosuggestions.zsh`、`06-zsh-syntax-highlighting.zsh`、`07-you-should-use.zsh` 和 `08-z.zsh` 逐字节等同。不要将这些共享片段
抽离到两棵配置树之外，因为仅使用 Debian 的 Docker 构建上下文看不到根级文件。

`macos/main.sh` 会在配置 Bash 进程中固定尝试求值 `/opt/homebrew/bin/brew shellenv`，以便子安装器找到 Homebrew；之后的交互式发现
由 Oh My Zsh 的 `brew` 插件完成。该调用没有显式验证结果：路径缺失时内层命令会报错，但外层 `eval` 仍可能返回成功，因此 strict mode 不保证在子安装器前中止。前缀泛化或强制失败都必须同步更新并验证此调用。

## 变更检查清单

完成变更前：

- 按“分发器契约”和“配置所有权与落点”核对接口、所有权、加载时机及重复运行行为。
- 使用实际软件包验证受管理配置，并执行“检查与安全验证”中适用于本次改动的静态、部署后及 ZLE 检查。
- 涉及一次性登录、OMZ 顺序、补全或组件例外时，复核对应专题的专项约束。
