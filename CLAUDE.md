# CLAUDE.md

## 适用范围、事实源与文档边界

仅面向全新、明确的 macOS／Debian／仓库容器环境，不扩展旧环境或非目标平台兼容；保留 Bash 3.2 等明示约束。Bash 脚本＋静态制品，无统一构建／测试套件；容器流程构建 Docker 镜像。

dispatcher、叶脚本、制品是参数／安装／配置事实源；本文仅记跨文件契约、所有权、失败与安全边界。README 只放调用／参数；现有手装 VS Code 扩展、未排除 `--app-claude-auth-token` 的 dev-container `(debian-flag)` 是已知偏差，非接口／安全先例。

## 架构、入口与分发器契约

- 根 `main.sh` 仅消费 `--setup`（默认 `macos`），浅克隆默认分支后分发 `<setup>/main.sh`；bootstrap URL 固定 `master`，payload 可能异分支，克隆不清理。仅此入口在 `curl | bash` 中无条件执行，无 `BASH_SOURCE` 保护。
- `macos/` 是终端客户端／跳板机，不配开发环境、Git 或 classic CLI；根入口缺 Command Line Tools 目录时只触发 `xcode-select --install`，不等待／验证。
- `debian/` 是开发环境，基线为 Homebrew → Zsh → OMZ → Starship → classic CLI，其余可选。Debian／container 缺 Git 时由根入口经 APT 安装。
- `container/main.sh` 消费 `--image`（默认 `dev-container`），直接执行 `./$IMAGE/main.sh`，无 allowlist；公开目标为 `dev-container`、`copilot-api`、一次性 `copilot-api-config`。

无平台前缀的路径相对于各平台树。Debian 首装 Homebrew 用 APT 补依赖；根不消费 `--unattended`：Homebrew 设 `NONINTERACTIVE=1`，OMZ 透传并以 `sudo -n` 改登录 shell。安装子进程 PATH 由父脚本求值 `/home/linuxbrew/.linuxbrew/bin/brew shellenv bash` 提供；交互式 PATH 归 OMZ `brew`，不写 `.zshenv`。

parser／接口契约：

1. 以可覆盖默认值初始化并导出标志，逐 token 扫描；值参数用 `numOfArgs` 保护 `$2`，缺值保留当前值。未知项经 `POSITIONAL` 下传，最终无人消费的项静默忽略。
2. 无 `--` 终止或 option/value 成组；下层值等于祖先标志（`--setup`／`--image`）时会被祖先消费。
3. 基线按依赖顺序，可选组件按 command → code → app、组内字母序执行；导出、parser、`main()` 保护、README 表须同序同步。可选组件须自行安装／保护依赖，除明确集成外不依赖另一可选标志；container target 例外。
4. Debian `APP_VSCODE`／`APP_GHOSTTY` 只有导出、parser、README，无 app 叶脚本／空保护。VS Code 插件和 `02-vscode.zsh` 归 OMZ，仅在 VS Code 内选 `code -w`，不设 `VISUAL`；`debian/vscode/` 仅参考。Ghostty 只显式集成，不探测终端、不装应用、不自动启用 SSH／Claude／tmux。

可选集成须双方启用；基线可按标志选择配置。读取关系如下（列组件名，对应导出标志见 dispatcher）：

| 消费者 | 读取的组件标志 |
| --- | --- |
| Debian OMZ | modern CLI、Go、Protobuf、Python、Rust、Docker、Git、tmux、VS Code、Yazi |
| macOS OMZ | SSH、VS Code |
| Debian SSH | Ghostty |
| Debian tmux | Claude、Ghostty |
| Claude | Go、Python、Rust、Ghostty、Git |
| Yazi | modern CLI、Markdown |
| Debian classic CLI | modern CLI |

用 `bash` 调用，不依赖可执行位。根／macOS 兼容 Bash 3.2，Debian／容器可用新版；除根外均须可 source 并保留 `BASH_SOURCE` 末尾保护，无参数叶脚本不加 parser／`POSITIONAL`。根／macOS 的空数组恢复不可换成 Debian 的 `"${POSITIONAL[@]}"`（3.2＋`set -u` 可能拒绝空数组）：

```bash
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"
```

## 检查与安全验证

从仓库根运行以下非破坏性检查；要求 `bash`、`cmp`、`git`、`jq`、`shellcheck`、`shfmt` 和 `zsh` 在 `PATH` 中，Debian `--code-bash` 提供 ShellCheck 和 shfmt：

```bash
bash -e <<'CHECKS'
find . \( -path './.git' -o -path './.claude' \) -prune -o \
    -type f -name '*.sh' \
    -exec bash -c 'for file in "$@"; do bash -n "$file" || exit; done' _ {} +
sh -n debian/command/classic_cli/nanom
jq empty debian/app/claude/settings.json \
    debian/command/modern_cli/micro.settings.json
find . \( -path './.git' -o -path './.claude' \) -prune -o -type f -name '*.sh' \
    -exec shellcheck -x --rcfile './.shellcheckrc' {} +
shellcheck -s sh --rcfile './.shellcheckrc' debian/command/classic_cli/nanom
find . \( -path './.git' -o -path './.claude' \) -prune -o -type f -name '*.sh' \
    -exec shfmt -d -i 4 -bn -ci -s -sr {} +
find . \( -path './.git' -o -path './.claude' \) -prune -o -type f -name '*.zsh' \
    -exec bash -c 'for file in "$@"; do zsh -n "$file" || exit; done' _ {} +
cmp macos/command/omz/custom/01-zsh-autosuggestions.zsh debian/command/omz/custom/05-zsh-autosuggestions.zsh
cmp macos/command/omz/custom/02-zsh-syntax-highlighting.zsh debian/command/omz/custom/06-zsh-syntax-highlighting.zsh
cmp macos/command/omz/custom/03-you-should-use.zsh debian/command/omz/custom/07-you-should-use.zsh
cmp macos/command/omz/custom/04-z.zsh debian/command/omz/custom/08-z.zsh
git diff --check
git diff --cached --check
CHECKS
```

PATH 中的 Bash 不能证明 Bash 3.2 兼容；根目录或 macOS 改动还须在 macOS 运行：

```bash
find main.sh macos -type f -name '*.sh' \
    -exec /bin/bash -c 'for file in "$@"; do /bin/bash -n "$file" || exit; done' _ {} +
```

JSONC `debian/vscode/settings.json` 不做严格 JSON 检查；ShellCheck `-x` 用于 Docker 动态 source `/etc/os-release`，`.shellcheckrc` 禁用 `SC2016` 以保留字面量美元符号。

禁止用普通账户运行 dispatcher 作冒烟测试：它会真实安装并修改 home，Debian OMZ 还删除 `.profile`、`.bashrc`、`.bash_logout`。一次性 home 的重复生成测试不证明完整流程幂等（第三方 clone 目录固定）。

OMZ 改动还须一次性 `HOME`／`ZSH_CUSTOM`、受控 `PATH`：

1. OMZ 模板建 `.zshrc`，桩化 `git`；Linux 模拟 macOS 加 BSD `sed` 垫片。
2. 导出全部组件变量（含 `APP_VSCODE`），在平台 `command/omz/` 按下节顺序运行四写入器，不运行 `main.sh`／`install_omz`。
3. 断言唯一有序的 `plugins=(...)`、符合标志的 custom／plugin／updater basename 集合。
4. 生成的 `.zshrc`、custom／updater、`pre-eza`、`brew-rustup` 均做 `zsh -n`；桩化 `gh`，验证 `99-gh-login.zsh` 先删自身、仅一次 `gh auth login`，禁真实认证。
5. `zsh -f` 中桩化 `sudo`、`brew`、`tldr`、`uv`、`rustup`、`ya`、`omz` 测 updater；含 `98-copilot-api.zsh` 时加 `curl`／`bash` 桩。

无 Homebrew／Starship 桩不得运行 `command/starship.sh`，不得直接调用真实 `update-all-in-one`。fzf 改动在一次性 `zsh -f` 检查 `${(z)FZF_CTRL_T_OPTS}`／`${(z)FZF_ALT_C_OPTS}`；插件顺序改动再做真实 ZLE／PTY，验证 Tab、`**<Tab>`、Ctrl-T、Alt-C 各调用一次且 `fzf_default_completion=fzf-tab-complete`。

macOS SSH 仅用一次性 HOME 和 `ssh-keygen`／`ssh-copy-id` 桩，覆盖首次／重复运行、私钥已有但 `.pub` 缺失、`--command-ssh-no-copy-key`；禁止连接真实远端。

## 配置所有权、落点与重复运行

安装与非 shell 配置归组件，shell 配置归 OMZ；仅 modern CLI 补全链接、copilot-api 服务启动后的 `98-copilot-api.zsh` 例外。`.zshrc` 多写入器协作，其余片段单一所有者。

两平台 OMZ 准备模板（Debian 另启用户 bin PATH），依次运行 `install_plugin.sh`（第三方 clone／仓库插件）、`update.sh`（聚合 updater 及平台片段）、`plugin.sh`（仅插件数组，条件插件须本次前置物化）、`custom.sh`（平台 `command/omz/custom/` 静态制品，保留 basename）。

落点（插件／片段相对于 `$ZSH_CUSTOM`）：

| 内容 | 落点 |
| --- | --- |
| `compinit`、OMZ 库、插件数组 | `.zshrc` |
| Starship 外观 | `$HOME/.config/starship.toml` |
| eza source 前的 zstyle／Rust source 前的代理 PATH | `plugins/pre-eza/`／`plugins/brew-rustup/` |
| Go 的 `$HOME/go/bin`／Protobuf 的 keg-only `clang-format` PATH | `03-go.zsh`／`04-clang-format.zsh` |
| 别名、集成函数、`compdef`、运行时变量、编辑器 | `<custom basename>` |
| 聚合更新函数与片段 | `plugins/update-all-in-one/` |
| 一次性 GitHub CLI 登录 | `99-gh-login.zsh` |

加载前设置用插件，加载后用编号 custom（字典序，正文不重复标题）。默认部署静态制品，注明整文件／键级／追加／patch 所有权；通常 `install -m 644`，Debian 可 `-D`，macOS 先 `mkdir -p`，OMZ 插件目录用 `cp -R`；Ruff 从外部 `main` 下载例外。

Debian Python：Linuxbrew 装 `uv`，`uv tool` 隔离 `py-spy`；项目运行时归 uv，系统 `python3` 为基线，不另装 Homebrew Python／设 `PYTHON_AUTO_VRUN`。

**重跑：** 仅覆盖所选制品，未选项／旧副本／basename 留存；关标志不卸载，清理须显式。插件数组从 `plugins=(aliases)` 重建，残留插件不启用；custom／updater 仍可能执行，改名可能重复运行。固定 clone 目录不幂等；Starship 不用 `--force`、目标已有即失败；Yazi 另见 package 契约。

Debian `APP_GIT=1` 才装 `99-gh-login.zsh`；source 先删自身再直接 `gh auth login`，失败／取消不重试。`custom.sh` 重跑可重装；关标志后的未执行残留仍可登录一次。

两平台 `update.sh` 装基础片段，Debian 按标志增选，均不探测命令；早于可选安装，失败可留引用未装命令的片段。聚合插件 source 仅定义函数，调用才按字典序 source `custom/*.zsh`；`98-copilot-api.zsh` 从 `master` 调根入口，排在末尾 `99-oh-my-zsh.zsh` 的 `omz update` 前。片段多步用 `&&`；运行器不查逐项返回值，后续成功可掩盖失败。

APT／Homebrew 各管自身安装工具的更新，其他 updater 见 `debian/command/omz/plugins/update-all-in-one/custom/`。Go 无专用 updater，不扫描 `$GOBIN`／`$GOPATH/bin`、不更新 `gopls`。`ohmyzsh-full-autoupdate` 仅在 shell 初始化更新带实体 `.git` 的 custom 插件／主题；聚合 updater 不重复扫描、不调其私有实现／改 `.zsh-update`，只共享官方 `omz update`。

## Shell、OMZ、补全与编辑器

OMZ 加载顺序：补全／库 → `plugins=()` → 字典序 `$ZSH_CUSTOM/*.zsh` → 主题。必须保持：

- `pre-eza` 紧邻 `eza` 前，使 source 时读取的 zstyle 生效。
- `update-all-in-one` → `ohmyzsh-full-autoupdate` → 第三方 clone 插件，后者由 autoupdate 同步。
- `fzf-tab` 早于 fzf、autosuggestions、syntax-highlighting 等包装器；五字段 `:completion:*:*:*:*:*` 的 `menu no` 须压过 OMZ 默认值。`zsh-syntax-highlighting` 必须是最后一个插件以免 Tab 嵌套；brackets highlighter 在其后的 custom 中追加。
- `brew` 紧跟 `aliases` 且早于 `starship`；官方 Starship 插件清 `ZSH_THEME` 并初始化，不再调用 `starship init`。
- Atuin 从 `09-atuin.zsh` 在插件后初始化，以便在 fzf 后接管 Ctrl-R／Up，不得前移。
- Rust 为 `brew → brew-rustup → rust`，source 时须能发现 cargo；Claude 不重加 `$HOME/.cargo/bin`。
- modern CLI 用 `zoxide`（仅由 OMZ 初始化一次）而非 `z`；未启用时用 `z` 并部署其设置。`99-gh-login.zsh` 是最后一个受管理 custom。

禁用 `\<z\>` 删插件名，会误匹配 `fancy-ctrl-z` 并粘连相邻名称；须以空格／括号界定。macOS 用 BSD `sed -i ''`，Debian 用 GNU `sed -i`。

脚本用 `#!/usr/bin/env bash`、`set -euo pipefail`；`debian/command/classic_cli/nanom` 是 POSIX 例外，以 `#!/bin/sh` 和 `exec /usr/bin/nano -/ "$@"` 替换自身。字面量单引号，需展开才用双引号；`${VAR:-default}` 默认值不加字面引号。

直接编辑静态 `.zsh`，保留 source 时展开的 `$PATH`／`$HOME`／`$EDITOR` 和 fzf 占位符；预览嵌套引号影响分词，保留 `-- {}` 防止候选被当作选项。

末尾 false 的 `[[ ... ]] && command` 会让函数返回 1 并触发 `set -e`，用 `if`／`return 0`。模板 patch 须验标记与结果（`sed` 无匹配仍成功），`ln -sf` 前须验证来源。未由本组件／明确前置保证的命令先 `command -v`。两平台 Homebrew／OMZ 的“命令替换下载后执行”可能将下载失败变成成功的空脚本，不把 strict mode 当作此处的致命保证。

`compinit` 仅发现 `_*`，依首个 `#compdef` 注册，改链接名不改声明。OMZ 在 `compinit` 前加 custom completions，`brew` 更晚才加 Homebrew `site-functions`；modern CLI 须以动态 `brew --prefix` 提前建 `$ZSH_CUSTOM/completions` 链接，逐一验证来源，失败不回滚。禁止硬编码 Linuxbrew／Cellar 或建悬空链接。

受管配置用实际安装版本验证，不以 master 代替：Lazygit／Micro 可静默忽略未知键或迁移文件，bat／fzf／delta 未知选项会失败。Micro 真彩色仅设 `micro.settings.json` 的 `"truecolor": "on"`，不设 `MICRO_TRUECOLOR`；不设覆盖 bat 配置的 `BAT_THEME`。

## 组件特有契约

### Classic 与 modern CLI

Classic 不装软件；Less 总部署，Nano 配置／`nanom` 仅非 modern，不 alias `nano`。modern 清单见 `debian/command/modern_cli/main.sh`。Nano 用系统 nanorc 语法，不加重复 include、改内容或冲突终端选择的设置；`minibar` 需 5.5+，`nanom` 的 `-/` 需 8.0+。classic=`00-nano.zsh`，modern=`01-micro.zsh`；切回 classic 须删旧 Micro 片段。macOS 不管 Nano。

Atuin 无历史／账户／同步导入；fzf 的 Ctrl-T／Alt-C 命令和预览归 shell 片段，两者无仓库原生配置。tealdeer 不预热，仅 updater 跑 `tldr -uq`，不吞失败；Glow 配置归 Markdown。

### Yazi

modern CLI／Markdown previewer 须前序组件已供命令；渲染见 `debian/app/yazi/yazi.toml.sh` 及其模板，按安装版验证。

`ya pkg add` 全成功才写配置：失败则新 home 无配置，旧 home 留旧配置，已加插件不回滚。`yazi.toml` 全量渲染，`init.lua`／`keymap.toml` 静态部署；`package.toml` 归 `ya`，重复 add 拒绝，换源先 delete，不垃圾回收插件。

### tmux 与 Ghostty

每次执行上游未固定的 `master/install.sh`，patch 后按 `APP_CLAUDE`／`APP_GHOSTTY` 独立追加片段；均开则 Claude → Ghostty，无查重。Claude 管通用 passthrough／extended keys／`xterm*` extkeys，Ghostty 仅 `xterm-ghostty` terminal features。上游重建前将活动配置作时间戳备份；正常重跑不累积活动区块，但留备份，行为随上游。

Micro 仅内部剪贴板；tmux 不设 `set-clipboard`／`get-clipboard`，Ghostty 不放宽 `clipboard-read`，无三者系统剪贴板联动。

### Debian SSH

`--command-ssh` 默认关；与 `--app-ghostty` 均启用才由 SSH 部署 `90-ghostty-env.conf`。不装／重载服务，生效靠 sshd 加载；关标志不移除 drop-in。

### macOS SSH

私钥已有只跳过 `ssh-keygen`，仍无查重追加 `Host`。指定 identity 且未传 `--command-ssh-no-copy-key` 时仍调用 `ssh-copy-id`，此时若已有私钥缺 `.pub`，会在追加后失败。no-copy 仅关远端复制，不阻止追加，整体不幂等。

### Docker

覆盖受管 APT key／source，安装 Docker 工具链／lazydocker，不创建或运行应用容器。`usermod -aG docker` 只影响新登录；运行容器目标前须重新登录，以无 `sudo` 访问 daemon。

### Git

仅拥有指定 global keys（name／email 非空才写）和全量 lazygit 配置，非整份 `.gitconfig`。delta／lazygit 归 Git 而非 modern CLI；`lg()`／一次性登录归 OMZ。lazygit 不继承 `core.pager=delta`；`lg()` 用 `LAZYGIT_NEW_DIR_FILE` 让父 shell 切到退出目录。

### Claude Code 与 copilot-api

Homebrew 安装／更新 Claude（不用 `claude update`），APT 供 sandbox／JSON／socket 依赖。流程：**静态设置 → Ghostty 通知 → copilot-api gateway／插件 → 通用插件**；条件步骤仅在集成启用时执行，保留两组 `enabledPlugins`。语言插件须与对应语言服务器成对启用，并依赖前序语言组件；Git 插件须 `APP_GIT=1`。

`install_settings()` 以目录 700／文件 600 覆盖设置；`main.sh` 仅 `APP_GHOSTTY=1` 设 `preferredNotifChannel=ghostty`，`copilot_api.sh` 合并 `ANTHROPIC_*`。基线无通知键；重装丢自定义 JSON，关 Ghostty 后重装去该键，不单独卸载。

首次交互前加官方 marketplace；随后 `jq` 仅删 `extraKnownMarketplaces["claude-plugins-official"]`，父对象仅为空才删，保留 `enabledPlugins`、其他 marketplace、独立 registry。未经 scope／缓存／已装插件影响审查，不改用 marketplace 生命周期命令。

`copilot_api.sh` 原样写三模型，无 `/v1/models`／可用性验证；默认模型空、URL=`http://localhost:4141`、token=`dummy`（刻意非机密）。`[1m]` 须 model、provider、账户、gateway 实际支持 1M；非第一方 `ANTHROPIC_BASE_URL` 默认预加载 fallback，仅 gateway 转发 `tool_reference` 才设 `ENABLE_TOOL_SEARCH=true`。copilot marketplace 的 Node 由集成安装，非独立 Debian 组件。

## 容器流程与安全边界

### dev-container

launcher 将 Debian 参数按 NUL 分隔后 base64 编码为 `setup_args_b64`；Dockerfile 只读 bind mount `debian/`，用 `mapfile -d ''` 恢复数组并执行 `bash /mnt/setup/main.sh --unattended "${setup_args[@]}"`。镜像不得依赖树外文件，须显式补齐基线包（含 `python3`、`man-db`、`file`）；系统 Python 不依赖可选 uv／py-spy。

Ghostty 预检不启用 Debian 集成：须显式传 `--app-ghostty`，SSH 还须 `--command-ssh`。容器内默认 `http://localhost:4141` 指 dev-container 自身；访问宿主／独立 gateway 须转发 `--app-claude-base-url <容器可达的 URL>`，launcher 不设 host networking／宿主别名。

预检只认 `TERM_PROGRAM=ghostty` 及 `USER`、`LANG`、`TERM`、`COLORTERM`、`TERM_PROGRAM_VERSION` 非空，不验证 SSH／login shell。`infocmp -x "$TERM"` 导出 terminfo；基础 APT 后、setup 前写终端 ENV，并由容器用户用 `tic -x` 编译到 `/home/${user}/.terminfo`，终端参数变化不影响基础 APT 缓存，但影响后续 setup 缓存。

宿主假定 Linux/systemd／`timedatectl`；`LANG` 实需 `<locale>.<encoding>`，但只检查非空，支持 macOS／`LANG=C` 须连同预检、拆分、`localedef` 修改。OMZ 无人值守安装不启动但改登录 shell；预期用 `docker exec` 进交互式 Zsh，非交互命令不保证 Homebrew PATH。同名容器已存在即拒绝启动。

**编码不保密：** `setup_args_b64`／`terminfo_b64` 不是秘密通道，前者禁止传 `--app-claude-auth-token` 或其他凭据（操作约束，非自动拦截）。引入 Docker secret／运行时注入前不得扩展此通道；build ARG 会进入镜像，并可能写入设置。宿主直接传 token 也可能暴露于 history／argv，0600 仅限制明文文件落盘后的访问。

新容器用 `--privileged`、`unless-stopped`、`NOPASSWD:ALL`，可写挂宿主 `~/Projects`，与宿主同一信任边界；数值 UID/GID 未对齐，bind mount 可能产生所有权差异。

### copilot-api 服务

`container/copilot-api/main.sh` 从最新 release 取 ref／镜像标签，构建后可通过 `/dev/tty` 认证，再替换固定名服务、挂载 `~/.copilot-api`。认证以 `root:root`／0700 创建状态目录，服务及配置容器各映到 root 状态路径。

`-p 4141:4141` 通常在全部宿主地址发布 TCP 4141，非仅回环；daemon 默认绑定／上游监听未固定，仓库无 TLS／ACL。仅允许可信网络，或加 API key、防火墙／可信代理。删除旧容器前失败保留原服务；删除后 `docker run` 失败无回滚／health check，服务停止。

### copilot-api-config

一次性镜像修改同一宿主目录的有效 `config.json`；操作固定为清空 → 随机追加 → 固定追加，与参数顺序无关。`--clear-api-keys` 清空数组，`--generate-api-keys <N>` 加 N 个独立 32 字节十六进制 key，`--add-api-key <v>` 原样追加到达 parser 的非空值；兼容 alias 见其 `main.sh`。

值参数重复取末值、追加不去重，仍受祖先标志碰撞限制。`<N>` 未验格式／上限即进入 Bash 算术，只能由可信调用方传规范非负十进制值。固定 key 经宿主 argv／Docker 环境变量，可暴露于 history、进程参数及 Docker metadata，不是秘密注入通道。

## macOS 特有约束与变更门禁

macOS 无 Debian 专属 PATH、Atuin、fzf 或一次性登录片段；`APP_VSCODE=1` 直接选 `code -w`。检查块四组 `cmp` 制品须逐字节一致；Docker 上下文仅 `debian/`，不得移至根目录共享。

`macos/main.sh` 固定求值 `/opt/homebrew/bin/brew shellenv` 供安装子进程使用，交互发现归 OMZ `brew`。路径缺失时内层报错，外层 `eval` 仍可成功；泛化前缀或改失败传播须同步更新并验证。

完成前同步适用接口视图，复核所有权、加载顺序、重跑及组件／容器例外；按“检查与安全验证”及实际安装版完成适用验证，明确记录无法完成的目标平台测试。
