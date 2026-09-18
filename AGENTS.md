# AGENTS.md

## 适用范围、事实源与文档边界

仅支持全新、明确的 macOS／Debian／仓库容器环境，不扩展旧环境或非目标平台。Bash＋静态制品，无统一构建／测试套件。

事实源为 dispatcher／叶脚本／制品；README 仅调用／参数，本文仅跨文件契约、所有权、失败与安全边界。README 手装 VS Code 扩展、dev-container `(debian-flag)` 未排除 `--app-claude-auth-token` 是已知偏差，不作先例。

## 架构、入口与分发器契约

- 根 `main.sh` 仅消费 `--setup`，浅克隆默认分支再分发；bootstrap 固定 `master`，payload 可异分支，克隆不清理。仅根无 `BASH_SOURCE` 保护，供 `curl | bash` 无条件执行。
- `macos/` 仅客户端／跳板机，不配开发环境／Git／classic CLI；根按目录判断 Command Line Tools，缺则触发 `xcode-select --install`，不等待／验证。
- `debian/` 基线为 Homebrew → Zsh → OMZ → Starship → classic CLI，其余可选；根为 Debian／container 经 APT 补 Git。
- `container/main.sh` 仅消费 `--image`，直接执行目标，无 allowlist。

无平台前缀的路径相对于平台树。Debian 首装 Homebrew 用 APT 补依赖；`--unattended` 根不消费，Homebrew 设 `NONINTERACTIVE=1`，OMZ 透传并 `sudo -n` 改登录 shell。安装 PATH 由 dispatcher 求值 `brew shellenv bash` 提供，交互 PATH 归 OMZ `brew`，不写 `.zshenv`。

parser／接口契约：

1. 导出可覆盖默认值，逐 token 扫描；值参数以 `numOfArgs` 保护 `$2`，缺值保留当前值。未知项经 `POSITIONAL` 下传，最终静默忽略。
2. 无 `--` 终止或 option/value 成组；下层值若等于祖先标志（`--setup`／`--image`），会被祖先消费。
3. 基线按依赖；可选按 command → code → app、组内字母序，导出／parser／`main()` 保护／README 表同序同步。除明确集成／container target，可选组件须自行安装／保护依赖。
4. Debian `APP_VSCODE`／`APP_GHOSTTY` 仅集成开关，无 app 叶脚本／空保护。VS Code 插件／编辑器归 OMZ，仅 VS Code 内选 `code -w`，不设 `VISUAL`；`debian/vscode/` 仅参考。Ghostty 不装应用、不探测终端、不自动启用 SSH／Claude／tmux。

可选集成须双方启用；基线可按标志配置。读取关系（标志名见 dispatcher）：

| 消费者 | 读取的组件标志 |
| --- | --- |
| Debian OMZ | modern CLI、Go、Protobuf、Python、Rust、Docker、Git、tmux、VS Code、Yazi |
| macOS OMZ | SSH、VS Code |
| Debian SSH | Ghostty |
| Debian tmux | Claude、Ghostty |
| Claude | Go、Python、Rust、Ghostty、Git |
| Yazi | modern CLI、Markdown |
| Debian classic CLI | modern CLI |

用 `bash` 调用，不依赖可执行位；根／macOS 兼容 Bash 3.2，Debian／容器可用新版。除根外可 source、有末尾 `BASH_SOURCE` 保护；无参数叶脚本不加 parser／`POSITIONAL`。根／macOS 保留以下空数组恢复（3.2＋`set -u` 不保证支持直接 `"${POSITIONAL[@]}"`）：

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
5. `zsh -f` 中桩化 `sudo`、`brew`、`tldr`、`uv`、`rustup`、`ya`、`omz` 测 updater；含 `98-copilot-api.zsh` 时加 `curl`／`bash` 桩，验证仅传 `--setup container --image copilot-api`，依赖默认启动，不启用可选操作。

无 Homebrew／Starship 桩不得运行 `command/starship.sh`，不得直接调用真实 `update-all-in-one`。fzf 改动在一次性 `zsh -f` 检查 `${(z)FZF_CTRL_T_OPTS}`／`${(z)FZF_ALT_C_OPTS}`；插件顺序改动再做真实 ZLE／PTY，验证 Tab、`**<Tab>`、Ctrl-T、Alt-C 各调用一次且 `fzf_default_completion=fzf-tab-complete`。

macOS SSH 仅用一次性 HOME 和 `ssh-keygen`／`ssh-copy-id` 桩，覆盖首次／重复运行、私钥已有但 `.pub` 缺失、`--command-ssh-no-copy-key`；禁止连接真实远端。

## 配置所有权、落点与重复运行

安装／非 shell 配置归组件，shell 配置归 OMZ；仅 modern CLI 补全链接、copilot-api 按开关安装的 `98-copilot-api.zsh` 例外。`.zshrc` 多写入器协作，其余片段单一所有者。

OMZ 从模板建 `.zshrc`（Debian 另启用户 bin PATH），依次执行 `install_plugin.sh` → `update.sh` → `plugin.sh` → `custom.sh`；职责见两平台 `command/omz/`。`plugin.sh` 仅重建插件数组，条件插件须本次前置物化。

`compinit`／库／插件数组归 `.zshrc`；加载前设置用插件，之后用编号 custom（保留 basename／字典序，正文不重复标题）。Starship 外观单独管理，不写 `.zshrc`。

静态部署须注明整文件／键级／追加／patch 所有权：`install -m 644`（Debian 可 `-D`，macOS 先 `mkdir -p`），插件目录 `cp -R`；Ruff 外部 `main` 下载例外。

Debian Python 项目运行时归 uv，系统 `python3` 为基线；不另装 Homebrew Python／设 `PYTHON_AUTO_VRUN`。

**重跑：** 只覆盖所选制品，关标志不卸载／清理。插件数组从 `plugins=(aliases)` 重建，残留插件不启用，但旧 custom／updater 仍可执行，改名可能重复运行。固定 clone 非幂等；Starship 不用 `--force`、已有目标即失败；Yazi 见下文。

Debian 仅 `APP_GIT=1` 装 `99-gh-login.zsh`（最后一个受管 custom）；source 先自删再 `gh auth login`，失败／取消不重试。`custom.sh` 重跑可重装，关标志后的残留仍可触发。

`update.sh` 先于可选安装，按基线／Debian 标志部署，不探测命令；失败可留未满足的命令引用。聚合插件 source 只定义函数，调用才按字典序 source 片段；多步用 `&&`，运行器不查逐项返回值，后续成功可掩盖失败。`98-copilot-api.zsh` 从 `master` 调根入口选择 copilot-api，依赖默认启动，下载 Compose 并启动服务、不重装自身，在末尾 `99-oh-my-zsh.zsh` 前。

APT／Homebrew 各更新自身工具，其他 updater 见 `debian/command/omz/plugins/update-all-in-one/custom/`。Go 无专用 updater，不扫描 Go bin／更新 `gopls`。`ohmyzsh-full-autoupdate` 仅初始化时更新带实体 `.git` 的 custom 插件／主题；聚合更新不重复扫描、不调私有实现／改 `.zsh-update`，仅共享 `omz update`。

## Shell、OMZ、补全与编辑器

OMZ 加载顺序：补全／库 → `plugins=()` → 字典序 `$ZSH_CUSTOM/*.zsh` → 主题。必须保持：

- `pre-eza` 紧邻 `eza` 前，使 source 时的 zstyle 生效。
- `update-all-in-one` → `ohmyzsh-full-autoupdate` → 第三方 clone 插件。
- `fzf-tab` 早于 fzf／autosuggestions／syntax-highlighting 等包装器；五字段 `:completion:*:*:*:*:*` 的 `menu no` 压过 OMZ 默认。`zsh-syntax-highlighting` 须为最后一个插件以免 Tab 嵌套；brackets highlighter 随后在 custom 追加。
- `brew` 紧跟 `aliases`、早于 `starship`；只由官方 Starship 插件清 `ZSH_THEME` 并初始化，不重复 `starship init`。
- Atuin 由 `09-atuin.zsh` 在插件后初始化，在 fzf 后接管 Ctrl-R／Up，不得前移。
- Rust 保持 `brew → brew-rustup → rust`，source 时可发现 cargo；Claude 不重加 `$HOME/.cargo/bin`。
- modern CLI 用 `zoxide`，仅由 OMZ 初始化一次；否则用 `z` 并部署其设置。

删插件名须以空格／括号界定，禁用会误匹配 `fancy-ctrl-z` 并粘连名称的 `\<z\>`。macOS 用 BSD `sed -i ''`，Debian 用 GNU `sed -i`。

Bash 用 `#!/usr/bin/env bash`／`set -euo pipefail`，仅 `nanom` 为 POSIX sh。字面量单引号，需展开才双引号；`${VAR:-default}` 默认值不加字面引号。

直接编辑静态 `.zsh`，保留 source 时展开的 `$PATH`／`$HOME`／`$EDITOR`、fzf 占位符与分词所需的嵌套引号；候选前保留 `-- {}`。

函数末尾 false 的 `[[ ... ]] && command` 会触发 `set -e`，改用 `if`／`return 0`。模板 patch 验标记及结果（`sed` 无匹配仍成功）；`ln -sf` 前验来源；无明确依赖保证的命令先 `command -v`。Homebrew／OMZ 的“命令替换下载后执行”可能将下载失败变成成功的空脚本，strict mode 不保证此处致命失败。

`compinit` 仅发现 `_*`，按首个 `#compdef` 注册，改链接名不改声明。OMZ 在 `compinit` 前加 custom completions，`brew` 更晚才加 Homebrew `site-functions`；modern CLI 须用动态 `brew --prefix` 提前建 `$ZSH_CUSTOM/completions` 链接，逐一验来源，失败不回滚。禁硬编码 Linuxbrew／Cellar 或建悬空链接。

受管配置须用实际安装版验证，不以 master 代替（未知键可被静默忽略）；Micro 真彩色／bat 主题归静态配置，不设 `MICRO_TRUECOLOR`／`BAT_THEME`。

## 组件特有契约

### Classic 与 modern CLI

Classic 不装软件：Less 总部署，Nano／`nanom` 仅非 modern；不 alias `nano`、重复 include、改系统 nanorc 语法或终端选择。`minibar` ≥5.5，`nanom -/` ≥8.0。切回 classic 须删旧 `01-micro.zsh`，否则覆盖 `00-nano.zsh`。

Atuin 不导入历史／账户／同步；fzf 的 Ctrl-T／Alt-C 命令与预览归 shell 片段，两者无仓库原生配置。tealdeer 仅 updater 跑 `tldr -uq`，不预热、不吞单片段失败；Glow 归 Markdown。

### Yazi

previewer 依赖前序 modern CLI／Markdown。包全装成功后才全量写受管配置（见 `debian/app/yazi/main.sh`），失败留旧配置、已加包不回滚。`package.toml` 归 `ya`；重复 add 拒绝，换源先 delete，不垃圾回收。

### tmux 与 Ghostty

每次执行未固定的上游 `master/install.sh`，备份／重建随上游；本仓库 patch 后按标志独立、无查重追加 Claude → Ghostty。两份片段分别管理通用键盘／passthrough、Ghostty terminal features，见 `debian/app/tmux/`。

Micro 仅内部剪贴板；tmux 不设 `set-clipboard`／`get-clipboard`，Ghostty 不放宽 `clipboard-read`，无三者系统剪贴板联动。

### Debian SSH

SSH 与 Ghostty 同开时部署 `90-ghostty-env.conf`；不安装／重载 sshd。

### macOS SSH

已有私钥只跳过生成，仍无查重追加 `Host`；指定 identity 且未禁复制时，缺 `.pub` 会在追加后失败。`--command-ssh-no-copy-key` 只关远端复制，不阻止本地追加，整体非幂等。

### Docker

仅覆盖受管 APT key／source 并安装工具，不创建／运行应用容器。加 docker 组仅新登录生效；容器目标须重新登录后无 `sudo` 访问 daemon。

### Git

只写指定 global keys（name／email 非空才写）及整份 lazygit 配置，不覆盖整份 `.gitconfig`。delta／lazygit 归 Git，`lg()`／一次性登录归 OMZ；lazygit 不继承 `core.pager=delta`。

### Claude Code 与 copilot-api

Claude 由 Homebrew 安装／更新（不调 `claude update`），APT 供运行依赖。`debian/app/claude/main.sh` 顺序：**覆盖 settings → 条件 Ghostty 通知 → 条件 copilot-api gateway／插件 → 通用插件**，保留两组 `enabledPlugins`。语言插件与对应语言服务器成对启用，并依赖前序语言组件；Git 插件须 `APP_GIT=1`。

settings 全量覆盖（目录 700／文件 600），重装丢自定义；通知键仅 Ghostty 开时添加，关后重装去键，不单独卸载。`copilot_api.sh` 合并 `ANTHROPIC_*`。

首次交互前加官方 marketplace，再用 `jq` 仅删 settings 的 `extraKnownMarketplaces["claude-plugins-official"]`（空父对象才删）；保留 `enabledPlugins`、其他 marketplace／独立 registry。未经 scope／缓存／已装插件影响审查，不换生命周期命令。

模型原样写入，不查 `/v1/models`／可用性；默认值见 `copilot_api.sh`（`dummy` 非机密）。`[1m]` 须 model／provider／账户／gateway 实际支持 1M。非第一方 `ANTHROPIC_BASE_URL` 默认预加载 fallback，仅 gateway 转发 `tool_reference` 时可设 `ENABLE_TOOL_SEARCH=true`。copilot marketplace 的 Node 由集成安装，非独立 Debian 组件。

## 容器流程与安全边界

### dev-container

传参与构建见 `container/dev-container/`：Debian 参数以 NUL＋base64 传递，还原数组后加 `--unattended` 执行。仅只读挂载 `debian/`，不得依赖树外文件；镜像显式提供基线包，不靠可选 uv／py-spy 提供系统 Python，清单见 Dockerfile。

Ghostty 预检不启用集成，开关仍须显式传入；不验证 SSH／login shell。默认 `localhost:4141` 指容器自身，gateway 须用 `--app-claude-base-url` 传容器可达的 URL；无 host networking／宿主别名。

宿主假定 Linux/systemd／`timedatectl`；预检仅认 `TERM_PROGRAM=ghostty` 和变量非空。`LANG` 实需 `<locale>.<encoding>`，扩平台／支持 `LANG=C` 须同步改预检、拆分、`localedef`。terminfo 由容器用户编译；终端 ENV 在基础 APT 后、setup 前，不影响基础 APT 缓存。

OMZ 无人值守仅改登录 shell、不启动；预期 `docker exec` 进交互 Zsh，非交互不保证 Homebrew PATH。同名容器拒绝启动。

**编码不保密：** `setup_args_b64`／`terminfo_b64` 非秘密通道；禁止经前者传 `--app-claude-auth-token` 或其他凭据（未自动拦截）。引入 Docker secret／运行时注入前不得扩展此通道；build ARG 会进入镜像且可能写入设置，宿主 argv／history 也可泄露，0600 只限制落盘后的访问。

容器用 `--privileged`／`unless-stopped`／`NOPASSWD:ALL`，可写挂载宿主 `~/Projects`，与宿主同信任边界；未对齐数值 UID/GID，可能产生所有权差异。

### copilot-api 服务

部署／认证见 `container/copilot-api/main.sh`。每次执行入口时，将上游 `dev` 的原始 Compose 文件全量下载覆盖到 `/tmp/copilot-api/docker-compose.yaml`，不本地构建、不清理目录。Compose 步骤通过 `-f` 指定该绝对路径，不切换工作目录。未被环境变量／YAML 顶层 `name` 覆盖时，项目名由 Compose 文件所在目录得 `copilot-api`；固定目录和项目不隔离并发调用。

入口每次执行都创建数据目录并设 `COPILOT_API_DATA_DIR`，使服务及配置容器继续共享宿主 `~/.copilot-data`，数据不落在 `/tmp`。服务／认证映到 `/data`，上游以 root `data-init` 初始化／修复受管状态权限，再以非 root `bun` 运行；仓库不额外实现旧环境迁移。上游 `XDG_CACHE_HOME=/data/cache` 持久化 device ID。配置容器仍以 root 映到 `/root/.copilot-data`，原位写入已有配置、保留所有者及权限。

清配置、添加 key、登录及 updater 安装默认关闭，启动服务无开关；入口先创建数据目录并下载 Compose，再按 可选清配置 → 可选添加非空 key → 可选登录 → 启动 → 可选安装 updater 执行。`--clear-config`／`COPILOT_API_CLAER_CONFIG=1` 仅删除 `$COPILOT_API_DATA_DIR/config.json`，不存在时不报错，不清理其他数据；已删除配置不回滚。不显式执行 `docker compose pull`，镜像拉取由各 Compose 命令按上游 YAML 策略处理，不保证组合调用只拉取一次。updater 安装独立选择，仅整文件部署片段、不安装聚合插件本体。无参数／仅 updater 也会准备服务工作及数据目录、下载 Compose 并启动服务。

不手动删除容器。下载失败可能留下不完整 YAML，任一步失败均中断后续步骤；拉取／密钥添加／登录失败不启动服务，`up -d` 可能部分完成，无回滚、不等待健康状态。只读配置、健康检查、日志轮转及拉取策略均归上游 YAML。

上游默认监听宿主 `127.0.0.1:4141`，但入口固定 `COPILOT_API_BIND=0.0.0.0` 且不接受同名环境覆盖，服务默认对宿主所有 IPv4 接口开放；`COPILOT_API_PORT` 可覆盖端口。须配 API key、防火墙／可信代理。添加的 API key 经宿主 argv／导出环境及容器命令参数，可暴露于 history、进程及 Docker metadata，不是秘密通道。继承上游的 token／代理环境变量透传，Docker metadata 可见，不是秘密通道。

### copilot-api-config

一次性容器修改共享目录的有效 `config.json`，实现见 `container/copilot-api-config/`。固定顺序：API key 清空 → 随机追加 → 固定追加 → 模型映射 → 小模型；前步失败中止，已写入不回滚。映射仅 key／value 均非空时按键覆盖，保留其他配置、不验模型。

`--small-model` 仅非空时统一覆盖 `smallModel`／`alphaSearchModel`／`messageApiWebSearchModel`；`extraPrompts`／`modelReasoningEfforts` 仅在 `gpt-5-mini` 源键存在且目标模型键缺失时复制其值，保留目标已有设置、源键及其他配置。上游会补回缺失的源键，它们仅为按模型索引的设置、不触发模型调用。空值不改配置，不初始化配置、不验证模型能力、不重启服务。

重复值取末值，模型映射取最后一组完整值；API key 不去重。`<N>` 未验格式／上限即进入 Bash 算术，只限可信调用方的规范非负十进制。固定 key 经宿主 argv／Docker 环境变量，可暴露于 history、进程及 metadata，不是秘密通道。

## macOS 特有约束与变更门禁

macOS 不带 Debian 专属 PATH／Atuin／fzf／一次性登录片段；`APP_VSCODE=1` 直接选 `code -w`。

`macos/main.sh` 固定求值 `/opt/homebrew/bin/brew shellenv` 供子进程使用，交互 PATH 归 OMZ `brew`；缺路径时内层报错，外层 `eval` 仍可成功。泛化前缀／改失败传播须同步验证。

完成前按上述契约同步接口、运行适用检查；列明未完成的安装版／目标平台验证。
