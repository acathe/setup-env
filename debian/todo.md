# Debian TODO

只记 debian 树尚未落地的事项。已定论的结论与**已否决**清单（不加的插件、不做补全的工具）都在
`CLAUDE.md`，条目一旦落地就从这里移走。

调研基准：`~/.oh-my-zsh` @ `b37dd49`（2026-07-23），系统 Debian 13 trixie。

## 总览

- [ ] 1 修 `--command-modern-cli` 下的三处插件顺序回退
- [ ] 2 `z` 与 `zoxide` 互斥
- [ ] 3 eza 的 zstyle 落 `setup-env` 插件
- [ ] 4 fzf / fzf-tab / magic-enter 的配置落 `00-setup_env.zsh`
- [ ] 5 atuin 的 zsh 补全落 fpath
- [ ] 6 引入 atuin 接管 `^R` 与 `↑`
- [ ] 7 CLAUDE.md 同步（随 1–4 落地）
- [ ] 8 yazi 的推荐配置、插件与 One Dark flavor

1–6 里 1–4 只动 `command/omz_custom/`，5–6 只动 `command/modern_cli/main.sh`，互不冲突，且全部
gate 在 `--command-modern-cli`，默认安装路径不受影响。7 是随 1–4 一起改的文档债。8 独立收拢
`command/modern_cli/yazi/`，只额外改它在 `modern_cli/main.sh` 的调用路径和落地后的 `CLAUDE.md` 说明。

### Modern CLI 工具配置

- [ ] `jq`
- [ ] `unzip`
- [x] `glow`
- [ ] `eza`
- [ ] `ripgrep`
- [ ] `zoxide`
- [ ] `fzf`
- [ ] `hyperfine`
- [ ] `sd`
- [ ] `btop`
- [ ] `dust`
- [ ] `duf`
- [ ] `procs`
- [ ] `choose`
- [x] `bat`
- [x] `fd`
- [x] `micro`
- [x] `tldr`
- [ ] `yazi`

---

## 1 · `--command-modern-cli` 下的三处插件顺序回退

**文件**：`debian/command/omz_custom/main.sh` 的 `install_plugin()`

**现状** `fzf` 混在中段的 `COMMAND_MODERN_CLI` 那批里（`:50`），`fzf-tab` 追加在函数最末
（`:69`）—— 即 `zsh-autosuggestions` / `zsh-syntax-highlighting` 之后。`append_plugin()` 是纯尾部
追加，数组顺序就是调用顺序，所以这三条同时违反 `CLAUDE.md`「omz plugin ordering」的：

| # | 违反 | 上游依据 |
| --- | --- | --- |
| 1 | `zsh-syntax-highlighting` 不是最后一个 | 上游 INSTALL.md 硬要求 |
| 2 | `fzf-tab` 落在包装 ZLE widget 的插件之后 | fzf-tab README 第 2 条 |
| 3 | `fzf` 在 `fzf-tab` 之前 | fzf 的 `completion.zsh` 把当时的 `^I` 绑定存为 `fzf_default_completion`，作非 `**` 触发时的回退 |

第 3 条反了的后果不是「不生效」而是**套娃**：fzf-tab 成为最外层 widget，它调用 orig widget 取
补全列表时会真的运行交互式的 `fzf-completion`，弹出两层 fzf。

**改法** 从中段 gate 块删掉 `append_plugin 'fzf'`（`eza` / `zoxide` 留原位 —— omz 内置、纯别名、
不碰 ZLE，位置自由），尾部改成：

```bash
    append_plugin 'ohmyzsh-full-autoupdate'
    append_plugin 'you-should-use'
    [[ $COMMAND_MODERN_CLI == '1' ]] && append_plugin 'fzf-tab'
    [[ $COMMAND_MODERN_CLI == '1' ]] && append_plugin 'fzf'
    append_plugin 'zsh-autosuggestions'
    append_plugin 'zsh-syntax-highlighting' # 上游要求最后

    return 0
```

同时满足约束 4：四个 clone 插件全部排在 `ohmyzsh-full-autoupdate` 之后。末条虽已是无条件语句，
`return 0` 仍保留 —— 理由见 `CLAUDE.md` 的 `set -e` 一节，靠「最后一行碰巧无条件」会被下一次编辑
悄悄弄坏。

**全 flag 开启后的目标数组**：

```zsh
plugins=(setup-env aliases colored-man-pages dirhistory extract fancy-ctrl-z magic-enter safe-paste
         sudo universalarchive eza zoxide docker docker-compose git tmux vscode golang python uv
         rust ohmyzsh-full-autoupdate you-should-use fzf-tab fzf zsh-autosuggestions
         zsh-syntax-highlighting)
```

（实际是一行；`z` 已被第 2 节移除。中段工具插件的相对顺序无约束。）

---

## 2 · `z` 与 `zoxide` 互斥

**文件**：`main.sh` 的 `install_plugin()`、`custom_env.sh` 的 `render_blocks()`

**现状** `main.sh:47` 无条件 `append_plugin 'z'`，`custom_env.sh` 的 `# z` 块（`ZSHZ_CASE` /
`ZSHZ_TILDE`）同样无条件。而 `zoxide` 插件跑的是 `zoxide init --cmd z`，开
`--command-modern-cli` 时它接管同一个命令名，zsh-z 的 1108 行代码和它的 `chpwd` / `precmd` hook
纯属白跑。

**改法** 两处一起条件化：

```bash
[[ $COMMAND_MODERN_CLI != '1' ]] && append_plugin 'z'
```

`custom_env.sh` 里把 `# z` 整块（含前导空行）包进 `if [[ $COMMAND_MODERN_CLI != '1' ]]; then … fi`
—— 用 `if` 不用 `[[ ]] &&`，理由见 `CLAUDE.md` 的 `set -e` 一节。

**不影响两树一致性**：`CLAUDE.md` 要求「debian 全 flag 关闭时两边生成的 `00-setup_env.zsh` 应
`cmp` 相等」。`COMMAND_MODERN_CLI` 默认为 0，`# z` 块照常输出，该不变式仍成立。只是 debian 的
「无条件段」从此有一条是反向 gate 的，需要在 `CLAUDE.md` 补一句（见第 7 节）。

---

## 3 · eza 的 zstyle → `setup-env` 插件

**文件**：`pre_plugin.sh` 的 `render_blocks()`

**现状** 只有 `CODE_PYTHON` 一块，eza 一条 zstyle 也没设，`ll` 只是裸 `eza -l`。

**改法** 照现有 `CODE_PYTHON` 段的写法加一个 gate 块：

```bash
        if [[ $COMMAND_MODERN_CLI == '1' ]]; then
            echo '# eza'
            echo 'zstyle ":omz:plugins:eza" "dirs-first" yes'
            echo 'zstyle ":omz:plugins:eza" "git-status" yes'
            echo 'zstyle ":omz:plugins:eza" "header" yes'
            echo 'zstyle ":omz:plugins:eza" "icons" yes'
            echo 'zstyle ":omz:plugins:eza" "time-style" "relative"'
        fi
```

**为什么是 `setup-env` 而不是 `00-setup_env.zsh`** `eza.plugin.zsh` 顶层直接调 `_configure_eza`，
zstyle 在**加载期**就被读走拼成 `_EZA_HEAD` / `_EZA_TAIL` 再生成别名；`00-setup_env.zsh` 在
`oh-my-zsh.sh` l.209 加载，晚于 l.203 的插件循环，写那里就晚了。这正是 `setup-env` 插件
（`plugins=()` 首位）存在的理由。

**生成侧引号** 按约定「`echo` 单引号、内容双引号」写。zsh 在这里对 `"…"` 与 `'…'` 等价（内容
无可展开成分），所以不必把外层翻成双引号，也就用不上 `'\''`。

**备注** `git-status` 会让大仓库里的 `ll` 变慢，`icons` 需要 Nerd Font —— 两条都可按需去掉。

---

## 4 · fzf / fzf-tab / magic-enter 的配置 → `00-setup_env.zsh`

**文件**：`custom_env.sh` 已有的 `COMMAND_MODERN_CLI`（`# Modern CLI tools`）块

三者的变量都是**运行期**读，落 `00-setup_env.zsh`（l.209，在全部插件之后）正合适 —— 这也正是
这个文件能覆盖插件已设值的原因。追加在现有 `compdef bat=batcat` / `alias tree` / `function y()`
之后即可，不新开 gate 块。

```zsh
# ── fzf ──
# 软链之后 $+commands[fd] 为真，插件会自行设 FZF_DEFAULT_COMMAND；这里显式覆盖以补上 --follow，
# 并补齐插件不设的两项 —— fzf 0.60 的 ^T / Alt-C 默认走内置 walker，它不读 .gitignore
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline --cycle"
export FZF_CTRL_T_OPTS="--preview \"bat --color=always --style=numbers --line-range=:200 {}\" --preview-window=right,60%,wrap"
export FZF_ALT_C_OPTS="--preview \"eza --tree --level=2 --color=always --icons {}\""

# ── fzf-tab ──
zstyle ":completion:*:*:*:*:*" menu no
zstyle ":completion:*:descriptions" format "[%d]"
zstyle ":completion:*" list-colors ${(s.:.)LS_COLORS}
zstyle ":completion:*:git-checkout:*" sort false
zstyle ":fzf-tab:complete:cd:*" fzf-preview "eza -1 --color=always --icons $realpath"
zstyle ":fzf-tab:*" switch-group "<" ">"
zstyle ":fzf-tab:*" fzf-flags --height=40% --layout=reverse --border --cycle

# ── magic-enter ──
MAGIC_ENTER_OTHER_COMMAND="eza -lah --git --icons"
```

五个要点：

- **`FZF_CTRL_T_OPTS` 里的 `bat` 不需要再 gate 一层**。bat 与 fzf 同属 `--command-modern-cli`，
  开了这个 flag 就一定有 `bat`，不存在跨 flag 依赖。
- **`menu no` 必须写成五级 pattern**。zstyle 按 pattern 具体度决胜，omz `lib/completion.zsh:14`
  设的是五级的 `zstyle ':completion:*:*:*:*:*' menu select`，比 fzf-tab README 里单级的
  `':completion:*'` 更具体，照抄 README 无效。fzf-tab 靠它才拿得到 unambiguous prefix。
- **`list-colors` 是覆盖不是新增**。`lib/completion.zsh:31` 把它设成了空串。
- **`FZF_DEFAULT_COMMAND` 的覆盖成立**。`fzf.plugin.zsh:266` 的赋值有 `[[ -z … ]]` 守卫且发生在
  l.203，我们在 l.209 重设，晚者胜。
- **`MAGIC_ENTER_OTHER_COMMAND` 是修语义错配，不是审美偏好**。默认值 `ls -lh .` 装了 eza 后经
  别名变成 `eza -g -l -h .`，而 eza 的 `-h` 是 `--header` 不是 human-readable。不装 eza 时默认值
  没问题，装了才需要改。插件在 `:4` 用 `: ${VAR:="ls -lh ."}` 设默认，widget 在 `:19` 于运行期读
  该变量 —— 我们在 l.209 的赋值晚于插件的 l.203，覆盖成立。

**两层引号写法**（已实测）：`FZF_*_OPTS` 的值内含 `--preview "…"` 一层引号，是仓库里第一处需要
两层的生成行。写成 `echo 'export FZF_CTRL_T_OPTS="--preview \"bat …\" …"'` —— 外层 bash 单引号把
`\"` 原样吐出，zsh 的 `"…"` 再把 `\"` 还原成 `"`，`${(z)…}` 切词后 `--preview` 的参数正是一个整词。
既守住「`echo` 单引号」的约定，也不必动用 `'\''`。

选定内联界面，不用 `ftb-tmux-popup`。写入前按「与上游默认值有无实质差异」再过滤一遍 ——
无条件段当初就是这样筛掉 `PYTHON_VENV_NAME` 与 `DIRHISTORY_SIZE` 的。

---

## 5 · 手装二进制的补全落 fpath

**文件**：`debian/command/modern_cli/main.sh` 的 `install_binaries()`

`/usr/local/share/zsh/site-functions/` 是 Debian 默认 fpath 的**第一位**
（`zsh -f -c 'print -l $fpath'` 实测），专门留给本地安装的软件。omz 用的是**不带 `-C`** 的
`compinit -i -d "$ZSH_COMPDUMP"`（`oh-my-zsh.sh:127`），每次启动都重扫 fpath，所以文件落盘后
**下次开 shell 自动生效**：不用删 `.zcompdump`，`.zshrc` 一个字不改。

之所以在安装期写文件、而不是像 omz 插件那样每次启动生成：我们是 setup 脚本，能在安装时介入 ——
shell 启动零开销，也省掉 `autoload -Uz _xxx; _comps[xxx]=_xxx` 那段（插件必须写那段，是因为它
加载时 `compinit` 已经跑完了）。代价是工具升级后补全不会自动更新，重跑 setup 即可，而这些补全
一年也变不了几次。

atuin 的二进制装在 `/usr/local/bin`，补全就走这里（yazi / tldr 那两半装在 `$HOME`，补全走
`$ZSH_CUSTOM/completions/`，已落地）：

- **atuin** —— tarball 里只有二进制 + README/CHANGELOG/LICENSE，装完自己生成（依赖第 6 节）：

  ```bash
  atuin gen-completions --shell zsh | sudo tee '/usr/local/share/zsh/site-functions/_atuin' > /dev/null
  ```

其余工具**不做**（含 apt 装的那批为什么无需处理）见 `CLAUDE.md` 的 debian 否决清单。

---

## 6 · 引入 atuin 接管 `^R` 与 `↑`

**文件**：`debian/command/modern_cli/main.sh`（安装）+ `custom_env.sh` 的 `COMMAND_MODERN_CLI` 块
（集成）

Debian 13 无 atuin 包（`apt-cache policy atuin` 为空），取 release tarball 装到 `/usr/local/bin`，
与现有 choose 同套路：

```
https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-gnu.tar.gz
```

（解压后的子目录名落地时确认，参照 `debian/command/modern_cli/yazi.sh` 的写法。）

集成只有一行，追加在 `custom_env.sh` 的 `# Modern CLI tools` 块里：

```zsh
eval "$(atuin init zsh --disable-ai)"
```

### 要点

- **接管 `^R` 与 `↑`**：源码 `crates/atuin/src/command/client/init/zsh.rs` 默认绑 `^r`
  （emacs/viins）、`/`（vicmd）、`^[[A` / `^[OA`（↑）、`k`（vicmd）。因为 eval 在 l.209、晚于
  l.203 的插件循环，天然覆盖 fzf 的 `^R` 与 omz 的 `up-line-or-beginning-search`。
  **fzf 插件保留**，仍提供 `^T` 文件、`Alt-C` 目录、`**` 触发补全、`FZF_DEFAULT_COMMAND`。
- **`--disable-ai` 必加**：官方构建默认把空行开头的 `?` 绑给 Atuin AI（`atuin ai inline`，需要
  Atuin 账号 + 联网）。
- **一处非显然的顺序依赖**：`atuin.zsh` 会把 `atuin` **前置**进 `ZSH_AUTOSUGGEST_STRATEGY`，而
  该变量由 `custom_env.sh` 的无条件段设为 `(history completion)`。无条件段在文件里排在
  `COMMAND_MODERN_CLI` 块之前，方向正好是「先赋值、后前置」。**反过来就会被覆盖** —— 这条 eval
  不能挪到无条件段之前。
  > ⚠️ 上游 [zsh-autosuggestions#797](https://github.com/zsh-users/zsh-autosuggestions/issues/797)
  > 「Conflict with atuin and completion strategies」未关闭。落地时先验证两者共存是否正常，
  > 必要时把 `completion` 从策略数组里去掉。
- **默认纯本地**：不 `atuin register` 就不同步。写 `~/.config/atuin/config.toml`：

  ```toml
  update_check = false
  ```

  （源码里默认值是 `cfg!(feature = "check-update")`，官方构建为 true，会在启动后台联网查版本。）
  落地时决定是整文件 `>` 还是仅在缺失时创建 —— 该文件用户可能自己改过。
- **`enter_accept` 默认 false**（已核对 `settings.rs:1434`）：TUI 里回车只回填命令行、不直接执行。
  保持默认。
- 装完跑 `atuin import auto || true`，从既有 `~/.zsh_history` 导入；全新环境里没历史也无害。
- **已知短板**：atuin 不接管 `~/.zsh_history`，它另存 SQLite
  （`~/.local/share/atuin/history.db`）；dev-container 每次重建库为空（除非挂卷或开 sync）。
  每条命令有 preexec / precmd 两次子进程开销。

---

## 7 · CLAUDE.md 同步

不是独立工作，是上面几节落地后必须一起改的文档债，列出来免得漏：

- **随第 1、2 节**：删掉「omz plugin ordering」里
  「The debian tree violates 1–3 whenever `--command-modern-cli` is on」那句现状陈述，连同它指向
  本文 §1、§2 的那半句。
- **随第 2 节**：在 `00-setup_env.zsh` 一节补一句 —— debian 的「无条件段」有一条 `# z` 是反向
  gate 的，`cmp` 不变式仍成立（`COMMAND_MODERN_CLI` 默认 0）。
- **随第 3 节**：更新「Only `PYTHON_AUTO_VRUN` is in the first row today」及其后指向本文 §3 的
  eza 那句。
- **随第 4 节**：新记两条 —— zstyle 按具体度决胜、覆盖 omz 的 `menu select` 必须同为五级 pattern；
  `FZF_*_OPTS` 那种两层引号的生成写法（`echo '… "… \"…\" …"'`）。

---

## 8 · yazi 的推荐配置、插件与 One Dark flavor

**文件**：把 `debian/command/modern_cli/yazi.sh` 收成 `debian/command/modern_cli/yazi/main.sh`，同目录新增
`yazi.toml`、`keymap.toml`、`theme.toml`、`init.lua`、`package.toml`；同步
`debian/command/modern_cli/main.sh` 的调用路径和 `CLAUDE.md` 里所有 `modern_cli/yazi.sh` 现状描述。

**现状** 只从 `releases/latest` zip 安装 `yazi` / `ya` 与 `_yazi` / `_ya`，再安装 MIME 检测所需的
`file`；没有托管任何 yazi 配置、插件或 flavor。`00-setup_env.zsh` 已有的 `y()` cwd-following 包装保持
原样，它是 shell 集成，不属于这次配置迁移。

### 先锁住稳定版兼容边界

截至 2026-08-10，`releases/latest` 是
[`v26.5.6`](https://github.com/sxyazi/yazi/releases/tag/v26.5.6)（2026-05-05 18:30:21 UTC，tag
`aa526434f00bb44e2e902d9a4ac5f810da1018b9`）。官方
[`yazi-rs/plugins`](https://github.com/yazi-rs/plugins/tree/0be29a913ad61c6d119abfaaf253e96e6af5db67)
没有 tag / release，当前 HEAD `0be29a9` 的提交标题就是 `support nightly fetcher API`，根 README 也只笼统
保证多数插件与 yazi HEAD 同步。**不能**让稳定版 core 配插件 HEAD：插件可选的 `@since` 只声明最低
版本，不是上限或配对矩阵；未发布的
[`f42a0df`](https://github.com/sxyazi/yazi/commit/f42a0df4df829b3c774e8f6dd03e10353269a23b)
已经把 fetcher 从 stable 的 bool / bool-array 返回改成 coroutine 逐文件 yield，正是 stable core + plugins
HEAD 会撞上的 breaking。以稳定版发布前 plugins 仓库最后一个 revision
[`ac82af3`](https://github.com/yazi-rs/plugins/tree/ac82af3e10f9a32cecd9f87ac64b3f9de7c7aea7)
作为起始验证点；它只是 release-date snapshot，不是官方配对，实际落地后仍逐个跑 smoke test。

`package.toml` 同时是 manifest 和 lock：每项有 `use`、Git `rev` 与部署内容 `hash`，应随仓库提交，
使新环境能用 `ya pkg install` 恢复（维护者也明确这是
[设计目标](https://github.com/sxyazi/yazi/issues/3758#issuecomment-4053209725)）。用 `ya pkg` 在临时
`YAZI_CONFIG_HOME` 生成它，不凭空手算 hash；提交前把验证过的 revision 写成 `rev = "=<commit>"`。
普通 `rev` 已能复现 install，但显式 upgrade 会推进；这里的 `=` 是有意 hard pin，防止用户全局
`ya pkg upgrade` 把 v26.5.6 配套插件推到 nightly。

安装机只运行 `ya pkg install`：`ya pkg add` 对 manifest 里已有的依赖直接报 `already exists`，本身不是
可重复部署命令；也不自动运行 `upgrade`，不用会丢弃用户本地插件修改的 `install --discard`。`install`
对同一个干净 lock **内容收敛但不是无副作用 no-op**：每次仍会 fetch、checkout、重新部署、重算 hash，并
重写 `package.toml`。该文件会被强类型重新序列化，不能放需要保留的注释、自定义字段或手调排版。

维护升级时先在临时副本去掉目标项 `rev` 的前导 `=`，再运行 `ya pkg upgrade`、审查 rev / hash / API diff，
验证后重新加 `=` 并与 core / 配置迁移一起提交。`install` 只遍历 manifest，**不会 prune**：删除依赖时要在
旧条目仍存在时先执行 `ya pkg delete <id>`，或在部署新 manifest 前显式删除该 package-owned 目录，不能只
删静态清单条目。官方语义见 [`ya pkg`](https://yazi-rs.github.io/docs/cli/#pm)；稳定版实现见
[`install.rs`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-cli/src/package/install.rs#L7-L24)、
[`upgrade.rs`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-cli/src/package/upgrade.rs#L5-L8)、
[`package.rs`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-cli/src/package/package.rs#L40-L55)、
[`hash.rs`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-cli/src/package/hash.rs#L8-L55) 与
[`deploy.rs`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-cli/src/package/deploy.rs#L11-L39)。
`hash` 是非密码学 XxHash3-128 本地修改指纹，不是版本号，也不是供应链完整性校验。

这仍不是完整版本锁定：现有二进制渠道有意跟随 `releases/latest`，而 `package.toml` 只锁插件与 flavor。
保留这个仓库既定下载 URL，但 `main.sh` 必须在临时目录下载完成后、覆盖任何现有文件之前读取
`"$dir/yazi" --version`，只接受静态 lock 已验证的 core（首个映射是 v26.5.6 → plugins `ac82af3` +
onedark `3735edb`）；未知版本 fail closed，打印“先原子更新 core 版本门、package rev / hash、配置 API 与
smoke test”，不能安装二进制、补全、配置或 packages，也不能悄悄切回 HEAD。这样 future `latest` 会响亮
要求维护，而不是留下新 core + 旧 lock 的半升级环境。

### 目标落点

```text
debian/command/modern_cli/yazi/
├── main.sh
├── init.lua
├── keymap.toml
├── package.toml
├── theme.toml
└── yazi.toml
```

`main.sh` 在现有二进制与补全安装之后，用 `install -Dm 644` 部署五个静态 artifact 到
`~/.config/yazi/`，再运行 `ya pkg install`。三个配置 TOML（不含 package manifest）都只写对上游
preset 的最小 overlay；数组不能靠
“同名自动合并”的猜测，键位、open rules、fetchers / previewers 一律用官方 `prepend_*` / `append_*`
入口，避免覆盖默认数组（稳定版依据：[`keymap`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-config/src/keymap/rules.rs#L11-L52)、
[`open`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-config/src/open/open.rs#L13-L60)、
[`plugin`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-config/src/plugin/plugin.rs#L11-L68)）。
`init.lua` 没有 TOML 的 merge 语义，每进程启动同步执行一次，托管即整文件所有权；这里只初始化下面的
插件，不复制上游 Lua preset（见 [`standard.rs`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-plugin/src/standard.rs#L11-L72)）。

这里沿用仓库对 bat / micro / lazygit 的既定所有权：五个文件是 setup-env 的版本化 artifact，重跑时
**有意覆盖**，让配置迁移能落到已有机器；不采用“仅在缺失时创建”，否则第一次安装后的内容永久陈旧。
边界在 package 目录：`plugins/*.yazi` / `flavors/*.yazi` 由 `ya pkg` 管，若 hash 发现用户改过就响亮中止；
禁止 `--discard` 正是为了不越过这条边界。

#### `yazi.toml`

只设三项确实偏离 v26.5.6 默认值、且适合开发目录的基础行为：自然排序、显示 size linemode、默认显示
点文件；`sort_dir_first = true` 已是默认值，不重述。

```toml
[mgr]
sort_by = "natural"
linemode = "size"
show_hidden = true
```

再注册两类官方插件，必须使用与稳定 revision 同期 README 的字段。`git.yazi` 的状态标记通过
`Linemode:children_add()` 追加，不会吃掉上面的 size linemode；v26.5.6 已高于 README 注释的
v26.1.22 分界，所以两条都不带旧 `id = "git"`：

```toml
[[plugin.prepend_fetchers]]
url = "*"
run = "git"
group = "git"

[[plugin.prepend_fetchers]]
url = "*/"
run = "git"
group = "git"

[[plugin.prepend_previewers]]
url = "*.md"
run = 'piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark "$1"'
```

Markdown 预览直接复用 `--command-modern-cli` 已安装的 `glow`，不新增依赖。这里的 `-s=dark` 是
Glow 内置主题，与下面的 Yazi One Dark flavor 无关；`CLICOLOR_FORCE=1` 能保留非 TTY 的 ANSI 色彩，但
Glow 2.x 会把其中的 RGB 细节量化为 256 色，验收只要求可读、不要求 TrueColor 一致。不要再写
editor / opener：Yazi 默认文本 opener 已读取 `EDITOR=micro`（VS Code 分支也经同一个环境变量生效）。也不配置
fd、rg、fzf、zoxide：core 自己识别 `fd` / `fdfind`，默认 keymap 已有 `z` → fzf、`Z` → zoxide。

#### `keymap.toml` 与 `init.lua`

只占两个当前默认行为能被严格增强的键：`l` 对目录 enter、对文件 open；`T` 在窄 SSH / tmux 界面隐藏或
恢复 preview pane。两项都用 prepend，不复制整份默认 keymap。

```toml
[[mgr.prepend_keymap]]
on = "l"
run = "plugin smart-enter"
desc = "Enter the child directory, or open the file"

[[mgr.prepend_keymap]]
on = "T"
run = "plugin toggle-pane min-preview"
desc = "Show or hide the preview pane"
```

`smart-enter` 保持默认 `open_multi = false`，避免一次误开全部 selected 文件。`init.lua` 只需：

```lua
require("git"):setup {
    order = 1500,
}
```

`git.yazi` 的默认 status signs 含 Nerd Font 私用区字符：复用第 3 节 `icons` 的字体前提；若实机不是
Nerd Font v3，就在 `require("git"):setup()` 之前按该 revision README 覆盖为 ASCII signs，不能留下方框。

目标官方插件共四个，全部预定 pin 到同一个稳定版同期 revision，并以本项 smoke test 作为落地门槛：

| package | 作用 | 上游依据 |
| --- | --- | --- |
| `yazi-rs/plugins:git` | 当前列表显示 Git 状态；`git` 已是整个 setup 的硬前置 | [`git.yazi`](https://github.com/yazi-rs/plugins/tree/ac82af3e10f9a32cecd9f87ac64b3f9de7c7aea7/git.yazi) |
| `yazi-rs/plugins:smart-enter` | 一个 `l` 同时覆盖 enter / open | [`smart-enter.yazi`](https://github.com/yazi-rs/plugins/tree/ac82af3e10f9a32cecd9f87ac64b3f9de7c7aea7/smart-enter.yazi) |
| `yazi-rs/plugins:piper` | 把现有 glow 用作 Markdown previewer | [`piper.yazi`](https://github.com/yazi-rs/plugins/tree/ac82af3e10f9a32cecd9f87ac64b3f9de7c7aea7/piper.yazi) |
| `yazi-rs/plugins:toggle-pane` | 窄终端隐藏 / 恢复 preview pane | [`toggle-pane.yazi`](https://github.com/yazi-rs/plugins/tree/ac82af3e10f9a32cecd9f87ac64b3f9de7c7aea7/toggle-pane.yazi) |

#### `theme.toml`

官方 flavors 仓库在
[`be0b21d`](https://github.com/yazi-rs/flavors/tree/be0b21d0873092a63946cc2678dd700aac945902)
只有 Dracula 与四个 Catppuccin，**没有** One Dark，不能写不存在的 `yazi-rs/flavors:onedark`。为了与
micro `one-dark`、bat / delta `TwoDark` 和 VS Code One Dark Pro 保持一致，采用第三方
[`damjee/onedark`](https://github.com/damjee/onedark.yazi/tree/3735edba144b17e3eb08fde9ffdaaf99f8ea9542)：
它是 MIT、只有静态 `flavor.toml` / `tmtheme.xml`，`3735edb` 已使用当前 `[mgr]` / `[tabs]` / `[cmp]` /
`[spot]` schema，并已在 yazi v26.5.6 下通过 `ya pkg add` + `yazi --debug` 解析。pin 这个 revision 与
生成的 hash，`theme.toml` 只写：

```toml
[flavor]
dark = "onedark"
light = "onedark"
```

这个 flavor 只有暗色方案；同时设置 `dark` / `light` 是有意让 Yazi 在两种终端检测结果下都保持仓库统一的
One Dark，不是在声称它支持浅色。只写 `dark` 会让 light 模式退回内置浅色 preset，与 micro / bat /
delta / VS Code 的固定暗色配置不一致。

启用 flavor 后，v26.5.6 的最终
[`Theme::reshape()`](https://github.com/sxyazi/yazi/blob/aa526434f00bb44e2e902d9a4ac5f810da1018b9/yazi-config/src/theme/theme.rs#L232-L246)
会把 `mgr.syntect_theme` 强制指向该 flavor 自带的 `tmtheme.xml`，这是“preset → flavor → 用户
theme overlay”顺序的明确例外；此处正好需要 One Dark 的代码预览主题，所以不再尝试从用户 `theme.toml`
覆盖它。

这是明确的第三方信任边界：每次升级都重新审计完整静态 diff；若该 flavor 停更或引入可执行 Lua，就退回
Yazi 默认主题，而不是静默换成不一致的 Dracula / Catppuccin。不要选仍使用旧 `[manager]` schema 的
`AugustDG/onedark`，也不要复活历史 [`BennyOe/onedark`](https://github.com/BennyOe/onedark.yazi/tree/668d71d967857392012684c7dd111605cfa36d1a)：
它已因 outdated / unmaintained 被
[官方目录移除](https://github.com/yazi-rs/flavors/commit/4296a380570399e3c36aec054f37aa48f35cf6b1)，
且还是 v0.2.4–v0.3.3 时代的旧 schema。

### 明确不做

- **不装整仓库插件**。`full-border` 浪费窄终端宽度；`smart-filter` / `smart-paste` 收益不足以再占默认键；
  `vcs-files` 与 lazygit / 普通 Git 工作流重叠；`diff` 同样重叠且 headless 环境没有它需要的剪贴板 helper；
  `mount`、`mactag`、clipboard 类功能依赖桌面 / 平台服务；`zoom` 等媒体插件会引入 ImageMagick。
- **不默认装 `mime-ext`**。它用扩展名准确率换速度，而现有 `file(1)` 路径没有已知瓶颈；只有实测远程
  大目录 MIME 成为热点后再考虑。
- **不硬编码图片 adapter，也不伪造 `TERM` / `TERM_PROGRAM`**。Yazi 按真实终端 / display 能力选择；
  无原生协议时本机 `yazi --debug` 会落到 Chafa，但最小 Debian 13 上安装 `chafa` 即使
  `--no-install-recommends` 仍新增 45 个包。当前取舍是允许该路径没有图片预览，不为它拉入 Cairo、Pango、
  字体与图像编解码栈；通过真实 SSH / tmux 会话跑 `yazi --debug` 验证降级即可。
- **不复制默认 preset**。尤其不重写完整 keymap、open rules、spotters、preloaders、fetchers 或
  previewers；这些正是 core 升级最容易漂移的数组。

### 本项验证

1. `shellcheck debian/command/modern_cli/yazi/main.sh`；五个 artifact 的 mode 都是 0644，目标目录由
   `install -D` 创建。
2. 用下载目录里的 stub `yazi --version` 分别返回 v26.5.6 与一个未知 future 版本：前者进入对应 lock，
   后者在覆盖二进制 / 补全、复制配置、`ya pkg install` 和任何 package 目录写入之前非零退出，并打印原子
   升级提示。
3. 一次性 `YAZI_CONFIG_HOME` 下部署文件并运行 `ya pkg install`、`yazi --debug`：无 TOML / Lua / flavor
   解析错误，四个插件与一个 flavor 的实际 revision / hash 等于 `package.toml`。
4. 再跑一次 `ya pkg install` 和 setup：允许 fetch / redeploy / manifest 重写，但最终 use / rev / hash、
   配置内容与已部署包内容收敛，不重复追加、不产生 HEAD 漂移（比内容，不拿 mtime 当幂等标准）。再用一个
   临时待删除依赖验证显式 `ya pkg delete` / 目录迁移，证明只删 manifest 条目确实不会被 `install` prune。
5. 实机检查：点文件可见，`file2` 排在 `file10` 前，size 与 Git 状态同时出现；`l` 能 enter / open，
   `T` 能隐藏 / 恢复 preview；Markdown 由 Glow 内置 `dark` 正常渲染，非 TTY 下允许 ANSI/256 色降级；
   Yazi UI 与代码预览仍由 flavor 保持 One Dark。
6. 从目录内用 `y` 启动并退出后仍能带 shell 切换 cwd；无图片协议、无 `chafa`、非 Git 目录和没有
   Markdown 文件时都安静退化，不影响普通浏览 / 打开文件。

---

## 验证

### 离线渲染

方法见 `CLAUDE.md` 的「Linting / running」—— 拿一个一次性 `HOME` + stub `git`，不装任何东西：

```bash
APP_GIT=1 COMMAND_MODERN_CLI=1 CODE_PYTHON=1 HOME=$T bash debian/command/omz_custom/main.sh

grep '^plugins=' "$T/.zshrc"
# setup-env 首位、fzf-tab 在 fzf 前、二者都在 zsh-autosuggestions 前、
# zsh-syntax-highlighting 末位、无 z

cat "$T/.oh-my-zsh/custom/plugins/setup-env/setup-env.plugin.zsh"   # eza zstyle + PYTHON_AUTO_VRUN
zsh -n "$T/.oh-my-zsh/custom/"{00-setup_env.zsh,01-first_run.zsh}
zsh -n "$T/.oh-my-zsh/custom/plugins/setup-env/setup-env.plugin.zsh"
```

全 flag 关闭时，debian 与 macos 生成的 `00-setup_env.zsh` 应 `cmp` 相等，且
`plugins/setup-env/` 与 `01-first_run.zsh` 都不该生成。

### 实机

```zsh
bindkey '^R'                # → atuin-search
bindkey '^[[A'              # → atuin-up-search
bindkey '^T'                # → fzf-file-widget（fzf 仍在）
echo $FZF_DEFAULT_COMMAND   # → fd --type f --hidden --follow --exclude .git
ls -l ~/.local/bin/{fd,bat} # → fdfind / batcat
yazi --version              # → 本次 package.toml 验证过的稳定版
ya pkg list                 # → 4 plugins + onedark flavor，revision 均被锁定
```

- 启动无 stderr（重点看 uv / rust / docker 的异步补全生成）。
- `<TAB>` 走 fzf-tab，有 `[...]` 分组标题与文件配色，`<` `>` 能切组。
- `cd <TAB>` 出 eza 目录预览；`vim **<TAB>` 走 fzf —— 证明回退链方向正确，且没有套娃出两层 fzf。
- `^T` 有 bat 预览，且在带 `.gitignore` 的仓库里不列 `node_modules`。
- `ll` 有表头、git 状态列、图标、相对时间；目录排在前。
- 空命令行回车：git 仓库出 `git status -u .`，其他目录出 `eza -lah --git --icons`。
- `fd <TAB>` / `bat <TAB>` / `atuin <TAB>` 均有补全（`yazi <TAB>` / `ya <TAB>` 由
  `command/modern_cli/yazi/main.sh` 装的 `_yazi` / `_ya` 提供）。
- yazi 同时显示 size 与 Git 状态，`l` / `T` 和 glow Markdown 预览生效；无 `chafa` 时普通文件浏览、
  One Dark flavor 与 `y()` cwd-following 仍正常，启动日志没有插件 API 错误。
- `atuin stats` 有数据（跑过几条命令后）；空命令行敲 `?` 不触发 AI，就是一个普通字符。
- `^R` 打开 atuin TUI；tmux 里应为 popup 形式（tmux ≥ 3.2，Debian 13 是 3.5a）。
- 未开 `--command-modern-cli` 时：`z` 仍在数组里，无 fzf-tab / atuin 相关报错。
