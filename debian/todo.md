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

1–6 里 1–4 只动 `command/omz_custom/`，5–6 只动 `command/modern_cli/main.sh`，互不冲突，且全部
gate 在 `--command-modern-cli`，默认安装路径不受影响。7 是随 1–4 一起改的文档债。

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

atuin 的二进制装在 `/usr/local/bin`，补全就走这里（tldr 的补全装在
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

（解压后的子目录名落地时确认。）

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
```

- 启动无 stderr（重点看 uv / rust / docker 的异步补全生成）。
- `<TAB>` 走 fzf-tab，有 `[...]` 分组标题与文件配色，`<` `>` 能切组。
- `cd <TAB>` 出 eza 目录预览；`vim **<TAB>` 走 fzf —— 证明回退链方向正确，且没有套娃出两层 fzf。
- `^T` 有 bat 预览，且在带 `.gitignore` 的仓库里不列 `node_modules`。
- `ll` 有表头、git 状态列、图标、相对时间；目录排在前。
- 空命令行回车：git 仓库出 `git status -u .`，其他目录出 `eza -lah --git --icons`。
- `fd <TAB>` / `bat <TAB>` / `atuin <TAB>` 均有补全。
- `atuin stats` 有数据（跑过几条命令后）；空命令行敲 `?` 不触发 AI，就是一个普通字符。
- `^R` 打开 atuin TUI；tmux 里应为 popup 形式（tmux ≥ 3.2，Debian 13 是 3.5a）。
- 未开 `--command-modern-cli` 时：`z` 仍在数组里，无 fzf-tab / atuin 相关报错。
