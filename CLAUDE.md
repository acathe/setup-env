# CLAUDE.md

## 适用范围、事实源与文档边界

本仓库只面向全新且环境明确的 macOS、Debian 和仓库定义的容器流程；无需兼容未知旧环境、非目标发行版或非目标平台，但必须遵守本文明确列出的 Bash 3.2 等约束。仓库由 Bash 配置脚本和静态制品组成，没有统一构建目标或自动化测试套件；容器流程会构建 Docker 镜像。

机械清单以对应 dispatcher、叶脚本和静态制品为事实来源；本文只维护跨文件架构、所有权、失败状态、安全边界和无法从单个文件判断的约束。`README.md` 只保留公开调用和参数简表，目前仍含手动安装 VS Code 扩展的命令，并用未排除 `--app-claude-auth-token` 的 `(debian-flag)` 表示 dev-container 转发参数。这些是已知文档偏差，不是接口或安全先例。

## 架构、入口与分发器契约

公共入口通过管道执行：

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- [--setup <macos|debian|container>] [flags]
```

根 `main.sh` 只消费默认值为 `macos` 的 `--setup`，浅克隆远端 HEAD 指向的默认分支后分发到 `<setup>/main.sh`。管道下载的 bootstrap 固定来自调用 URL 中的 `master`；若远端默认分支改变，bootstrap 与 payload 可能来自不同分支。macOS 缺少 Command Line Tools 目录时只触发 `xcode-select --install`，不会等待或验证完成；Debian／container 未发现 Git 时通过 APT 安装。克隆不会自动删除。根入口必须在 `curl | bash` 中无条件执行，是唯一没有 `BASH_SOURCE` 末尾保护的配置脚本，也是根级 `--setup` 的解析事实来源。

- `macos/` 配置终端客户端／跳板机，不作为开发机配置，也不包含 Git 或 classic CLI。
- `debian/` 配置开发环境；Homebrew、Zsh、Oh My Zsh、Starship 和不安装外部软件包的 classic CLI 基线无条件执行，其余组件可选。
- `container/main.sh` 消费默认值为 `dev-container` 的 `--image` 并直接执行 `./$IMAGE/main.sh`；公开支持 `dev-container`、`copilot-api` 和一次性 `copilot-api-config`，但 parser 本身没有 allowlist。dev-container 使用 `debian/` 作为构建上下文。

下文未带平台前缀的 `command/`、`code/` 和 `app/` 路径均相对于所讨论的平台树。

Debian 首次安装 Homebrew 前通过 APT 安装官方前置依赖。根入口刻意不消费 `--unattended`：`debian/command/homebrew.sh` 用它设置 `NONINTERACTIVE=1`，OMZ 安装器将它传给上游并以 `sudo -n` 更改登录 shell。父脚本随后求值 `/home/linuxbrew/.linuxbrew/bin/brew shellenv bash` 供后代安装器发现 formula；交互式 Zsh 由 `brew` 插件配置，不写 `.zshenv`。Go 沿用该 PATH 契约；Go 和 Protobuf 标志分别让 OMZ 安装 `$HOME/go/bin` 与 keg-only `clang-format` 的交互式 PATH 片段。

`debian/vscode/` 仅为参考数据，不由分发器安装。Debian `--app-vscode` 是纯 OMZ 集成：在 VS Code 运行时选择 `code --wait`，且不输出 `VISUAL`。脚本应通过 `bash` 调用，不依赖可执行位。根 `main.sh` 和 `macos/` 必须兼容 Apple Bash 3.2；Debian 和容器代码可使用更新的 Bash。

各层 parser 遵循同一数据流：

1. 以可覆盖默认值初始化并导出后代读取的标志。
2. `parse_args()` 逐 token 扫描；布尔标志 shift 一次，值标志用 `numOfArgs` 避免在 `set -u` 下读取缺失的 `$2`。尾部缺值会被静默丢弃并保留当前值，unknown token 最终无人消费时也会静默忽略。
3. 未知 token 进入 `POSITIONAL` 并向下恢复。parser 没有 `--` 终止或 option/value 成组机制；下层参数值若等于祖先保留标志（如 `--add-api-key --setup` 或 `--add-api-key --image`），会被祖先消费。
4. 无条件基线按依赖顺序执行；可选组件按 command、code、app 分组且组内按字母排序。
5. `command/`、`code/` 和 `app/` 下的每个可选组件自行安装或保护其所需命令；container target 不在此保证内。除明确集成契约外，不得依赖另一可选标志。

普通可运行组件的导出块、parser case、`main()` 保护条件和 README 表应作为同一接口的四个有序视图同步维护；上文列出的 README 偏差不是新增接口的先例。Debian `APP_VSCODE` 是纯集成例外：有导出、parser 和 README 标志，但没有叶脚本或 `main()` 保护；OMZ 用它选择插件和 `02-vscode.zsh`，不要为对称性虚构空保护。

跨组件读取只在双方启用时增加集成行为：

| 消费者 | 读取的上游标志 |
| --- | --- |
| Debian OMZ 写入器 | `COMMAND_MODERN_CLI`、`CODE_GO`、`CODE_PROTOBUF`、`CODE_PYTHON`、`CODE_RUST`、`APP_DOCKER`、`APP_GIT`、`APP_TMUX`、`APP_VSCODE`、`APP_YAZI` |
| macOS OMZ 写入器 | `COMMAND_SSH`、`APP_VSCODE` |
| Claude app | `CODE_GO`、`CODE_PYTHON`、`CODE_RUST`、`APP_GIT` |
| Yazi | `COMMAND_MODERN_CLI`、`CODE_MARKDOWN` |
| Debian classic CLI | `COMMAND_MODERN_CLI` |

组件拥有安装及其非 shell 配置；共享 shell 片段必须由相应 OMZ 写入器生成。明确例外只有 modern CLI 为补全加载时序管理 `$ZSH_CUSTOM/completions` 链接，以及 `container/copilot-api/main.sh` 在服务启动后安装 `98-copilot-api.zsh`。

除根管道入口外，分发器和叶脚本必须可 source，并沿用相邻脚本的 `BASH_SOURCE` 末尾保护；无参数叶脚本不引入 parser 或 `POSITIONAL`。根入口和 macOS 必须保留 Bash 3.2 兼容的空数组恢复形式：

```bash
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"
```

不要规范化为 Debian 的 `"${POSITIONAL[@]}"`；Bash 3.2 配合 `set -u` 可能拒绝空数组展开。

## 检查与安全验证

从仓库根运行以下非破坏性检查；要求 `bash`、`git`、`jq`、`shellcheck`、`shfmt` 和 `zsh` 在 `PATH` 中，Debian `--code-bash` 提供 ShellCheck 和 shfmt：

```bash
find . \( -path './.git' -o -path './.claude' \) -prune -o \
    -type f -name '*.sh' -exec bash -n {} \;
sh -n debian/command/classic_cli/nanom
jq empty debian/app/claude/settings.json \
    debian/command/modern_cli/micro.settings.json
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

PATH 中的 Bash 不能证明 Bash 3.2 兼容；根目录或 macOS 改动还须在 macOS 运行：

```bash
find main.sh macos -type f -name '*.sh' -exec /bin/bash -n {} \;
```

严格 JSON 检查刻意不包含采用 JSONC 的 `debian/vscode/settings.json`。ShellCheck 使用 `-x`，因为 `debian/app/docker.sh` 动态 source `/etc/os-release`；`.shellcheckrc` 禁用 `SC2016`，供字面量 `jq`／`sed` 程序和生成内容保留美元符号。

直接运行 dispatcher 会执行真实安装并修改 home。例如 `bash debian/main.sh --app-tmux` 会运行 APT、安装 OMZ；Debian OMZ 还会删除 `.profile`、`.bashrc` 和 `.bash_logout`。不要用普通账户作为冒烟测试沙箱。第三方插件会 clone 到固定目录，因此一次性 home 中的重复生成测试也不证明完整 dispatcher 幂等。

OMZ 改动除仓库制品的 `zsh -n` 外，还需在一次性 `HOME`、`ZSH_CUSTOM` 和受控 `PATH` 中验证：

1. 用 OMZ 模板初始化 `.zshrc`，桩化 `git`；Linux 模拟 macOS 时增加 BSD `sed` 垫片。
2. 导出全部组件变量（包括 `APP_VSCODE`），从对应平台的 `command/omz/` 依次运行 `install_plugin.sh`、`update.sh`、`plugin.sh`、`custom.sh`，不要运行 `command/omz/main.sh` 或 `install_omz`。
3. 断言只有一个有序 `plugins=(...)`，且 custom、plugin、updater 的 basename 集合符合标志。
4. 对生成 `.zshrc`、custom／updater 及 `pre-eza`、`brew-rustup` 运行 `zsh -n`；验证 `99-gh-login.zsh` 先删自身再只调用一次 `gh auth login`。
5. updater 调度在 `zsh -f` 中桩化 `sudo`、`brew`、`tldr`、`uv`、`rustup`、`ya`、`omz`；存在 `98-copilot-api.zsh` 时再桩化 `curl` 和 `bash`。

没有 Homebrew／Starship 桩时不要运行 `command/starship.sh`，也不要直接调用真实 `update-all-in-one`。fzf 改动须在一次性环境的 `zsh -f` 中检查 `${(z)FZF_CTRL_T_OPTS}` 和 `${(z)FZF_ALT_C_OPTS}`；插件顺序改动还需真实 ZLE／PTY 测试，确保普通 Tab、`**<Tab>`、Ctrl-T 和 Alt-C 各只调用一次，且 `fzf_default_completion=fzf-tab-complete`。

macOS SSH 只能使用一次性 HOME 和 `ssh-keygen`／`ssh-copy-id` 桩，覆盖首次运行、重复运行、私钥存在但 `.pub` 缺失及 `--command-ssh-no-copy-key`；不得连接真实远端。

## 配置所有权、落点与重复运行

每个共享配置片段只有一个逻辑所有者，但 `.zshrc` 由多个写入器协同管理。两平台 `command/omz/main.sh` 均准备模板后依次运行 `install_plugin.sh`、`update.sh`、`plugin.sh` 和 `custom.sh`；Debian 还启用模板中的用户 bin PATH。`install_plugin.sh` 拥有第三方 clone 和仓库内插件目录，`update.sh` 拥有 `update-all-in-one` 入口及平台片段，`plugin.sh` 只拥有插件数组且只启用本次流程已由前置写入器物化的条件插件，`custom.sh` 拥有编号片段。

| 配置需求方 | 配置所属目标位置 |
| --- | --- |
| `compinit`、OMZ 库、插件列表 | `.zshrc` |
| Starship prompt 外观 | `$HOME/.config/starship.toml` |
| eza source 前所需 zstyle | `$ZSH_CUSTOM/plugins/pre-eza/pre-eza.plugin.zsh` |
| Rust source 前所需 rustup 代理 PATH | `$ZSH_CUSTOM/plugins/brew-rustup/brew-rustup.plugin.zsh` |
| keg-only `clang-format` 的交互式 PATH | `$ZSH_CUSTOM/04-clang-format.zsh` |
| 别名、集成函数、`compdef`、运行时变量、编辑器选择 | `$ZSH_CUSTOM/<custom basename>` |
| 聚合更新函数及平台更新片段 | `$ZSH_CUSTOM/plugins/update-all-in-one/` |
| 一次性 GitHub CLI 登录 | `$ZSH_CUSTOM/99-gh-login.zsh` |

`custom.sh` 从平台 `command/omz/custom/` 选择静态 Zsh 制品，保留源 basename 安装，由字典序决定加载顺序；文件名已承担区块标识，正文不重复标题。读取时机决定设置属于加载前插件还是加载后编号片段。

运行时配置默认作为仓库制品部署：整文件、键级、追加式或上游 patch 的所有权必须在组件说明中明确。静态文件通常用 `install -m 644`；Debian 可用 GNU `install -D` 同时建父目录，macOS 必须先 `mkdir -p`。OMZ 自定义插件按目录 `cp -R`，以便容纳辅助文件。Python Ruff 从外部 `main` 下载是例外。Debian `--code-python` 用 Linuxbrew 管理 `uv`、用 `uv tool` 隔离安装 `py-spy`；系统 `python3` 仍是基线，项目运行时由 uv 管理，不额外安装 Homebrew Python，也不设置 `PYTHON_AUTO_VRUN`。

**通用重跑规则：** 重跑只覆盖本次选中的静态制品，不删除未选项、旧副本或旧 basename；关闭标志不等于卸载，清理必须显式执行。生成式 Starship 不传 `--force`，目标已存在时失败；Yazi 有独立的 package 所有权和失败语义。

Debian 仅在 `APP_GIT=1` 时安装 `99-gh-login.zsh`；片段被 source 时先删除自身再直接运行一次 `gh auth login`，失败或取消也不会在新 shell 自动重试。重跑 `custom.sh` 可重新安装；关闭标志后尚未 source 的残留片段仍可能执行一次。完整流程还受固定第三方 clone 目录的非幂等性限制。

`plugin.sh` 从 `plugins=(aliases)` 重建数组，未选插件目录即使残留也不会被启用。两平台 `update.sh` 按导出标志安装片段而不探测命令；旧可选片段和旧 basename 会保留，重命名后可能重复执行。copilot-api 启动成功后另装 `98-copilot-api.zsh`，固定从 `master` 重新调用根入口。

`update-all-in-one.plugin.zsh` 被 source 时只定义函数；调用后按 Zsh 默认字典序 source `custom/*.zsh`。平台以数字前缀声明顺序，`98-copilot-api.zsh` 位于固定的 `99-oh-my-zsh.zsh` 前，当前制品总以 `omz update` 收尾。同一片段多步操作用 `&&`；运行器不检查每次 `source` 返回值，后续成功可能掩盖前序失败。安装 `update.sh` 早于可选组件，中途失败可能留下引用尚未安装命令的片段。

APT 负责更新由 APT 安装的工具，Homebrew 通用 updater 负责 formula／cask；Debian 其他 updater 以 `debian/command/omz/plugins/update-all-in-one/custom/` 为事实来源。Go 没有专用 updater，不得扫描 `$GOBIN`／`$GOPATH/bin` 或在此更新 `gopls`。`ohmyzsh-full-autoupdate` 只在 shell 初始化时更新带实体 `.git` 的 custom 插件和主题；不要调用其私有实现、操作 `.zsh-update` 标签或让 `update-all-in-one` 重复扫描这些仓库，两者只共享官方 `omz update` 边界。

## Shell、OMZ、补全与编辑器

OMZ 先初始化补全和库，再按 `plugins=()` source 插件、按字典序 source `$ZSH_CUSTOM/*.zsh`，最后加载主题。必须保持：

- `pre-eza` 紧邻并位于 `eza` 前，使 source 时读取的 zstyle 生效。
- `update-all-in-one` 位于 `ohmyzsh-full-autoupdate` 前；第三方 clone 插件位于负责同步它们的后者之后。
- `fzf-tab` 位于 fzf、autosuggestions 和 syntax-highlighting 等包装器之前；保留五字段 `:completion:*:*:*:*:*` 的 `menu no` 覆盖以压过 OMZ 默认值。`zsh-syntax-highlighting` 是最后一个插件，否则 Tab 可能嵌套打开补全；brackets highlighter 必须在该插件加载后的 custom 片段中追加。
- `brew` 紧跟 `aliases` 且在 `starship` 前；官方 Starship 插件清除旧 `ZSH_THEME` 并初始化 prompt，不得再运行第二次 `starship init`。
- Atuin 刻意从 `09-atuin.zsh` 在插件之后初始化，以便在 fzf 后接管 Ctrl-R 和 Up；不要按通用插件顺序将它前移。
- Rust 必须保持 `brew → brew-rustup → rust`，让官方插件 source 时发现 cargo；不要在 Claude 集成中重加 `$HOME/.cargo/bin`。
- modern CLI 使用 `zoxide` 并省略 `z`；未启用时使用 `z` 并部署其设置。`99-gh-login.zsh` 是最后一个受管理 custom 片段。

不要用 `\<z\>` 删除插件名：连字符不是单词字符，可能匹配 `fancy-ctrl-z` 尾部并粘连相邻名称。必须以空格和括号限定；macOS 使用 BSD `sed -i ''`，Debian 使用 GNU `sed -i`。

配置脚本使用 `#!/usr/bin/env bash` 和 `set -euo pipefail`。独立命令 `debian/command/classic_cli/nanom` 是 POSIX 例外，以 `#!/bin/sh` 和 `exec /usr/bin/nano --modernbindings "$@"` 透明替换自身。字面量使用单引号；仅在 shell 必须展开时用双引号，`${VAR:-default}` 的默认值不加字面引号。

编号 custom 和 updater 均为仓库静态 `.zsh` 制品；直接编辑并保留在 Zsh source 时展开的 `$PATH`、`$HOME`、`$EDITOR` 和 fzf 占位符。fzf 预览的嵌套引号决定 option tokenization，且必须保留 `-- {}` 防止以 `-` 开头的候选被当作选项。

函数最后一条语句若是求值为 false 的 `[[ ... ]] && command`，会返回 1 并在 `set -e` 调用方中止；改用 `if` 或显式 `return 0`。原地 `sed` 没有匹配仍成功，修改上游模板时须验证标记和结果；`ln -sf` 前须验证来源，避免悬空链接。

对未由当前组件或明确前置组件保证的命令先用 `command -v`。多数网络失败在 strict mode 下中止，`tldr --update || true` 是显式非致命例外。两平台 Homebrew／OMZ 安装器先在命令替换中下载再执行，下载失败可能变成执行空脚本并返回成功，不能视为致命保证。

`compinit` 只发现 `_*` 文件并按首个 `#compdef` 注册命令，链接名不会改变声明。OMZ 在 `compinit` 前加入 `$ZSH_CUSTOM/completions`，而 `brew` 插件更晚才加入 Homebrew `site-functions`；modern CLI 必须通过动态 `brew --prefix` 提前创建受控链接。逐个验证来源；后续失败不会回滚已建链接，不得硬编码 Linuxbrew／Cellar 前缀或产生悬空链接。

配置须用实际安装的软件包验证，而不是针对上游 master；Lazygit 和 Micro 可能静默忽略未知键或迁移文件，未知 bat／fzf／delta 选项则会直接失败。Micro 真彩色只由 `micro.settings.json` 的 `"truecolor": "on"` 管理，不设置 `MICRO_TRUECOLOR`；`BAT_THEME` 会覆盖受管 bat 配置，也不得设置。

Debian Nano 依赖系统 nanorc 加载软件包语法，不增加重复 include glob；选项面向 Nano 5.3+，避免加入会改变文件内容或与终端选择冲突的设置。classic CLI 只在未启用 modern CLI 时部署配置和 `nanom`，但不安装 Nano。新 home 中 classic 选择 `00-nano.zsh`，modern 选择后加载的 `01-micro.zsh`；重跑不删除未选片段，因此 modern → classic 必须显式删除旧 Micro 片段。macOS 不管理 Nano。

## 组件特有契约

### Classic 与 modern CLI

Debian 在 OMZ 和 Starship 后无条件运行 classic CLI：Less 始终部署，Nano 与 `nanom` 仅在非 modern 模式部署，且不以 alias 改变 `nano`。modern CLI 的 formula、补全链接、bat／Micro 配置和 Micro 插件以 `debian/command/modern_cli/main.sh` 为准；`man-db` 是 Debian 基线，精简 dev-container 显式补齐。

Atuin 和 fzf 都没有仓库原生配置：流程不导入 Atuin 历史或账户／同步设置，fzf 由受管 shell 片段派生 Ctrl-T／Alt-C 命令和预览。安装阶段不预热 tealdeer；只有 updater 非致命运行 `tldr --update`。Markdown 组件拥有 Glow 配置，zoxide 只由 OMZ 初始化一次。

### Yazi

`--app-yazi` 的 formula 和插件清单以 `debian/app/yazi/main.sh` 为准，previewer 选择与渲染以 `debian/app/yazi/yazi.toml.sh` 和 `debian/app/yazi/yazi.toml/*.toml` 为准；modern CLI／Markdown previewer 只在对应命令已由前序组件提供时启用，并须与当前 Yazi 版本兼容。`file` 来自 Debian 基线，dev-container 显式补齐。

插件先由 `ya pkg add` 安装；任一失败都会跳过本次全部配置写入，使新 home 无配置，旧 home 保留旧配置和已成功添加的插件。随后 `yazi.toml.sh` 完整渲染 `yazi.toml`，`init.lua` 和 `keymap.toml` 作为静态制品部署。`package.toml` 由 `ya` 拥有；重复 add 会拒绝已列依赖，换源须先 delete。后续成功或关闭标志不会垃圾回收插件或残留 `15-yazi.zsh`。

### tmux 与 Ghostty

`--app-tmux` 每次下载并执行未固定的 `gpakosz/.tmux` `master/install.sh`，patch 上游生成文件后无查重追加 `debian/app/tmux/ghostty.tmux.conf`；该制品无条件启用 passthrough、extended keys 和仅限 `xterm-ghostty` 的 terminal features。上游会把活动配置移为时间戳备份再重建，正常重跑不在活动文件累积区块，但会保留备份且行为可能随上游变化。

Micro 使用内部剪贴板；tmux 制品不设置 `set-clipboard`／`get-clipboard`，Ghostty 制品不放宽 `clipboard-read`。仓库不提供 Micro、tmux 与 Ghostty 间的系统剪贴板联动。

### macOS SSH

`--command-ssh` 在私钥已存在时只跳过 `ssh-keygen`，每次重跑仍无查重追加 `Host` 块；提供 identity file 且未传 `--command-ssh-no-copy-key` 时仍调用 `ssh-copy-id`。未传 `--command-ssh-no-copy-key` 时，私钥存在但 `.pub` 缺失会在追加配置后失败；no-copy 只关闭远端复制，不阻止追加，因此组件整体不幂等。

### Docker

`--app-docker` 覆盖受管 APT key／source，安装 `debian/app/docker.sh` 所列 Docker 工具链和 lazydocker，但不创建或运行应用容器。`usermod -aG docker` 只影响新登录会话；运行 `container/` 目标前须重新登录，使当前用户无需 `sudo` 访问 daemon。

### Git

`--app-git` 的工具和 global key 清单以 `debian/app/git/main.sh` 为准；非空 name／email 写入 global scope，组件只拥有这些键和完整 lazygit 配置，不拥有整个 `.gitconfig`。系统 Git 依赖根引导器的 Command Line Tools／APT；OMZ 拥有 `lg()` 与一次性登录片段，delta 和 lazygit 不属于 modern CLI。

lazygit schema 和 renderer 以 `debian/app/git/lazygit.config.yml` 为事实来源并用安装版本验证。它不会继承全局 `core.pager=delta`；`lg()` 通过 `LAZYGIT_NEW_DIR_FILE` 让父 shell 切换到退出目录。

### Claude Code 与 copilot-api

`debian/app/claude/main.sh` 通过 Homebrew 安装 Claude Code，并由 APT 提供 sandbox／JSON／socket 依赖；通用 Homebrew updater 负责升级，不调用 `claude update`。流程先以 `settings.json` 替换基础设置，启用 copilot-api 时再定点合并 gateway 值并安装其插件，最后安装通用插件，以保留两组 `enabledPlugins`。插件清单以脚本为准；语言插件必须与对应语言服务器成对启用并依赖更早的语言组件，Git 插件只在 `APP_GIT=1` 时安装。

脚本在首次交互启动前添加官方 marketplace；随后 `jq` 仅删除 `extraKnownMarketplaces["claude-plugins-official"]`，仅在父对象为空时删除父对象，并保留 `enabledPlugins`、其他 marketplace 和独立 registry 状态。不要用作用域更广的 marketplace 生命周期命令替换这一定点 JSON 清理，除非已审查 scope、缓存和已安装插件影响。

`copilot_api.sh` 将三个模型值原样写入，不查询 `/v1/models` 或验证可用性；模型默认空，base URL 默认 `http://localhost:4141`，token 默认刻意使用非机密 `dummy`。`install_settings()` 以目录 700、文件 600 部署 `debian/app/claude/settings.json`，合并脚本再写入 `ANTHROPIC_*`；两者分别是静态设置和动态 gateway 值的事实来源。

仅当底层 model、provider、账户和 gateway 实际支持 1M context 时使用 `[1m]`，后缀本身不会赋予能力。非第一方 `ANTHROPIC_BASE_URL` 默认使用预加载 fallback；仅当 gateway 确实转发 `tool_reference` 时才设 `ENABLE_TOOL_SEARCH=true`。copilot marketplace 插件需要 Node，由该集成安装；Node 不是独立 Debian 组件。

## 容器流程与安全边界

### dev-container

`container/dev-container/main.sh` 将转发的 Debian 参数做 NUL 编码后再 base64 编码，以 `setup_args_b64` 传入。Dockerfile 只读 bind mount Debian 构建上下文，以 `mapfile -d ''` 解码数组并运行：

```bash
bash /mnt/setup/main.sh --unattended "${setup_args[@]}"
```

launcher 只检查 Ghostty 标记和构建变量，不验证当前是否为 SSH 或 login shell：它要求 `TERM_PROGRAM=ghostty`，且 `USER`、`LANG`、`TERM`、`COLORTERM`、`TERM_PROGRAM_VERSION` 非空，并以 `infocmp -x "$TERM"` 导出 terminfo。镜像在基础 APT 和完整 setup 后才写入终端 ENV，并由容器用户用 `tic -x` 编译到 `/home/${user}/.terminfo`，从而避免终端变化使 APT／setup 缓存失效。

`setup_args_b64` 和 `terminfo_b64` 只编码数据，不提供保密性。前者不得承载 `--app-claude-auth-token` 或其他秘密，否则会通过 build ARG 进入镜像并可能写入用户设置；引入 Docker secret 或运行时注入前，不得扩展此通道传递凭据。宿主直接传入 `--app-claude-auth-token` 也可能暴露在 shell history 和 process argv 中，并以明文写入 0600 设置文件；文件权限只保护落盘后的访问，不构成秘密注入通道。

构建上下文仅为 `debian/`，镜像配置不能依赖树外文件。系统 `python3` 是基线，独立于可选 uv／py-spy；精简镜像须在 Dockerfile 显式补齐基线包。launcher 假定 Linux/systemd 与 `timedatectl`，并实际要求 `LANG` 为 `<locale>.<encoding>`，现有预检只验证非空；支持 macOS 宿主或 `LANG=C` 时须同步修改预检、拆分逻辑和 `localedef`。

无人值守安装 OMZ 但不启动它，并更改登录 shell；dev-container 可通过 `docker exec` 或 SSH 进入交互式 Zsh，非交互命令不保证发现 Homebrew。同名容器已存在时 launcher 拒绝启动。

launcher 将宿主 `id -u` 和 `id -g` 作为 build args，使容器用户与宿主用户的数值 UID/GID 一致；`~/Projects` bind mount 因而沿用同一所有权。宿主 `$HOME/.ssh/authorized_keys` 被单文件只读挂载到容器用户的标准路径，整个 `.ssh` 和私钥不会进入容器；launcher 不校验该文件，路径缺失时沿用 Docker `--volume` 的默认行为，SSH 公钥登录不会可用。Dockerfile 只创建 0700 `.ssh` 目录，sshd 使用 Debian `openssh-server` 的默认配置和包安装时生成的 host keys，并以前台模式作为主服务；仓库不额外定制认证策略或 host key 生命周期，同一镜像创建的容器会共享 SSH host fingerprint。

launcher 固定将 `0.0.0.0:2222` 发布到容器 TCP 22，因此同一宿主同时只能有一个实例占用该 SSH 端口。新容器使用 `--privileged`、`unless-stopped`、`NOPASSWD:ALL` 并可写挂载宿主 `~/Projects`，SSH 用户可取得容器 root 权限且两侧属于同一高信任边界；必须只允许可信网络访问 TCP 2222，并使用宿主防火墙限制来源。authorized_keys 的只读挂载不改变这一信任边界。

### copilot-api 服务

`container/copilot-api/main.sh` 解析最新 release 得到 Git ref／镜像标签，构建后可通过 `/dev/tty` 认证，再替换固定名服务并挂载主机 `~/.copilot-api`。认证以 `root:root`、0700 创建状态目录，服务和配置容器都映射到各自 root 状态路径。

`-p 4141:4141` 未指定宿主 IP 或协议，通常请求 Docker 在全部宿主地址发布 TCP 4141；仓库不固定 daemon 默认绑定或上游监听地址，也不提供 TLS／网络 ACL。只允许可信网络访问，或另加 API key、防火墙／可信代理。删除旧容器前失败会保留旧服务；删除后若 `docker run` 失败则没有回滚或 health check，服务保持停止。

### copilot-api-config

一次性 config 镜像修改同一主机目录中的服务 `config.json`。`--clear-api-keys` 清空整个数组；`--generate-api-keys <N>` 追加 N 个独立 32 字节十六进制 key；`--add-api-key <v>` 原样追加实际到达 parser 的非空值。`<N>` 当前未经格式或上限验证便进入 Bash 算术上下文；调用方必须只传规范非负十进制值，不得传递不可信输入。`--reset-api-key` 和 `--api-keys <N>` 是前两者的兼容 alias；带值参数重复时最后一个值生效，追加不去重，且仍受祖先保留标志值碰撞限制。

容器固定按清空 → 随机追加 → 固定追加执行，参数出现顺序不改变操作顺序。固定 key 会经过宿主 argv 和 Docker 环境变量，可能暴露在 shell 历史、进程参数或 Docker metadata 中，不是秘密注入通道。任务假定服务已生成有效 `config.json`。

## macOS 特有约束与变更门禁

macOS 没有 Debian 的条件 PATH、Atuin、fzf 或一次性登录片段；`APP_VSCODE=1` 时选择 `code --wait`。macOS 的 `01-zsh-autosuggestions.zsh`、`02-zsh-syntax-highlighting.zsh`、`03-you-should-use.zsh`、`04-z.zsh` 必须分别与 Debian 的 `05-zsh-autosuggestions.zsh`、`06-zsh-syntax-highlighting.zsh`、`07-you-should-use.zsh`、`08-z.zsh` 逐字节相同；不要抽到根目录，因为只使用 Debian 的 Docker 构建上下文无法看到树外文件。

`macos/main.sh` 在配置进程中固定求值 `/opt/homebrew/bin/brew shellenv` 供子安装器发现 Homebrew，交互式发现由 OMZ `brew` 插件负责。路径缺失时内层命令会报错，但外层 `eval` 仍可能成功，strict mode 不保证中止；泛化前缀或改为强制失败须同步更新并验证。

完成变更前：

- 同步适用的接口视图，并按 dispatcher、配置所有权、加载时机和通用重跑规则检查新增／移动组件。
- 用实际安装版本验证受管配置，运行本文件适用的静态、一次性 HOME、ZLE／PTY 或 SSH 专项检查。
- 涉及 OMZ 顺序、补全、一次性登录、container 秘密／网络边界或组件例外时，逐项复核对应契约；不能完成目标平台测试时明确记录限制。
