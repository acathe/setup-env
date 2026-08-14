# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Bash scripts that provision development environments. There is no build step — the
entry point is `main.sh`, which is designed to be piped straight from `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup <macos|debian|container> [flags]
```

`main.sh` shallow-clones the repo (branch from `--branch`, default `master`) into a
temp dir and hands off to `<setup>/main.sh` (default `macos`), forwarding all unrecognized
flags — the top-level `main.sh` itself understands only `--branch` and `--setup`.

## Linting / running

- Lint: `shellcheck **/*.sh` (config in `.shellcheckrc`; `SC2016` disabled because
  single-quoted `jq`/`sed` programs contain `$` that is not a shell expansion).
- The files `omz_custom/pre_plugin.sh`, `omz_custom/custom_env.sh` and `omz_custom/first_run.sh` write
  into `$ZSH_CUSTOM` are zsh, not bash — they come from `echo` blocks and heredocs inside a bash
  script, so `shellcheck` never inspects their contents. Render them (see below) and check with
  `zsh -n`.
- No test suite. To exercise a change without the full remote install, run a dispatcher
  directly, e.g. `bash debian/main.sh --app-tmux` — note it still does real `apt` installs
  and always runs `command/omz.sh` then `command/omz_custom/main.sh` first.
- To check a `plugins=()` change, or anything `pre_plugin.sh` / `custom_env.sh` / `first_run.sh`
  generates, without installing anything: run `command/omz_custom/main.sh` against a throwaway
  `HOME` with a stub `git` (and, for macos, a `sed` shim mapping BSD `-i ''` to GNU `-i`) on
  `PATH`, after copying `~/.oh-my-zsh/templates/zshrc.zsh-template` to `$HOME/.zshrc`. Every step
  is just `git clone` + `sed` + plain file writes, so the four artefacts come out exact; component
  flags are read from the environment, so `APP_GIT=1 command/omz_custom/main.sh` renders the gated
  blocks too. Re-running the same `HOME` with every flag back off is the other half: `plugins=`
  loses `setup-env`, `01-first_run.zsh` disappears, and the plugin file stays behind unreferenced
  (see "Empty output is no output" and "Only `first_run.sh` deletes"). For load order, source the
  rendered files in `oh-my-zsh.sh`'s own order (`setup-env` → the other plugins →
  `00-setup_env.zsh`) under `zsh -f`: `chpwd_functions[(r)auto_vrun]` proves `PYTHON_AUTO_VRUN`
  landed early enough (source the real `plugins/python/python.plugin.zsh` after it), and
  `ZSH_HIGHLIGHT_HIGHLIGHTERS` coming out `(main brackets)` rather than `(brackets)` proves
  `00-setup_env.zsh` landed late enough. For `01-first_run.zsh`, run omz's l.209 loop
  (`for f ("$ZSH_CUSTOM"/*.zsh(N)); do source $f; done`) in two separate `zsh -f` invocations: it
  fires on the first, is silent on the second, and `00-setup_env.zsh` does not grow again.

## Architecture

Three independent setup trees, selected by `--setup`:

- `macos/` — Xcode CLT check, Homebrew, oh-my-zsh, plus optional apps. Positioned as a
  *terminal client / jump box*, not a dev machine: its omz plugin list is picked around the
  ssh-to-remote workflow (connect, manage keys, move files) and deliberately omits `git`.
- `debian/` — the richest tree; installs zsh + oh-my-zsh unconditionally, then a
  matrix of optional components. `--command-modern-cli` is a nested dispatcher, the same shape as
  `--app-claude`: `command/modern_cli/main.sh` installs the bulk of the CLI tools itself, downloads
  yazi / `ya` and `choose`, then runs four sub-scripts — `modern_cli/bat/`,
  `modern_cli/fdfind.sh`, `modern_cli/micro/` and `modern_cli/tldr.sh` — each still installing its
  own packages and owning whatever config that tool needs, none of them carrying a flag of its own.
  One component is shaped unusually: `--app-git`
  deliberately spans all three layers of a single concern instead of being split by kind: it
  installs the tooling (`gh` from the official apt repo, `git-delta`, `lazygit`), writes the global
  git config, owns the `gh auth login` block in `01-first_run.zsh`, and owns
  `~/.config/lazygit/config.yml`. That is why `git-delta` / `lazygit` are absent from
  `--command-modern-cli`'s package list, and why the delta pager config is unconditional — the
  script that writes it is the one that installed delta, so no cross-flag read is needed.
  That last drop point is why the component lives in `debian/app/git/` (`main.sh` + `config.yml`)
  rather than as a flat `app/git.sh`: it is the `debian/command/modern_cli/micro/` shape,
  `install -Dm 644 './config.yml' "$HOME/.config/lazygit/config.yml"` and all. A shipped template
  rather than an `echo` block because it is six lines of static YAML with no interpolation. It owns
  only the Nerd Fonts version, side-panel width and delta pager; `nerdFontsVersion: "3"` must stay a
  string because the unquoted integer fails the unmarshal. Five things about lazygit are worth
  knowing before touching that file.

  **lazygit has no plugin system.** The entire extension surface is that one config file:
  `customCommands`, the `git.paging` pager, the `os.*` command hooks, `services` for self-hosted
  PR URLs, and `keybinding.*`. There is no official theme gallery either — each colour scheme's own
  org ships a port that sets nothing but the `gui.theme` keys. This file deliberately has no
  `gui.theme`, so lazygit is not part of the tree's One Dark baseline; adding one would be a separate
  `--app-git` change against the 0.50.0 schema, not something to infer from the other tools.

  **The file is written against Debian's version, 0.50.0, and the pager keys have moved twice
  since.** trixie ships 0.50.0 (upstream 2025-05-03) while upstream is at 0.63.1 (2026-07-15):
  `git.paging` (object) → `git.pagers` (array, 0.63.1) → `git.diffRenderers` (master, unreleased).
  Copying master's `Custom_Pagers.md` produces config that does nothing here. Changing the install
  channel means rewriting that whole block.

  **Unknown keys are silently ignored — the same trap as micro's `truecolor`.**
  `app_config.go:202` is a bare `yaml.Unmarshal(content, base)` with no `KnownFields(true)`, on
  master too. A key from a newer version's docs neither errors nor gets stripped; it is invisible
  dead config that only a version check finds — the YAML *syntax* check cannot see it either.

  **lazygit rewrites this file itself.** `app_config.go:221`'s `migrateUserConfig()` writes the
  file back when it finds a key it can migrate. None of 0.50.0's five migratable keys is one we
  write, so it never fires — **but that is a constraint on adding keys: check the migration list
  first.** If it ever does fire, a re-run's `install -Dm 644` puts the template back. Note also
  that `state.yml` in the same directory is lazygit's own state file; only `config.yml` is ours.

  **delta reaches lazygit only through this file.** `git.paging.useConfig` defaults to `false`, so
  `core.pager delta` in the gitconfig is invisible to lazygit — without the `pager` line it renders
  git's own diff colouring. `--paging=never` is required (delta's default `paging = auto` wraps
  less around it and breaks lazygit's rendering). Everything else delta needs is *inherited*: it
  reads the global `[delta]` section on its own, so `setup_git()` configures both callers at once.
  The cost is that `side-by-side` comes along, and delta 0.18.2 has no `--no-side-by-side`
  (`--side-by-side=false` is a hard error); hence `gui.sidePanelWidth: 0.2` against the 0.3333
  default, widening the main panel to fit two columns.

  Vetted rejections for that file, recorded so they don't get re-proposed:
  - `os.editPreset` — redundant. `guessDefaultEditor()` (`file.go:149-169`) reads `core.editor`,
    then `$GIT_EDITOR` / `$VISUAL` / `$EDITOR`, and takes everything up to the first space, so
    `custom_env.sh`'s `EDITOR=micro` and its `EDITOR="code --wait"` both land correctly with
    nothing written.
  - `update.method: never` — dead. `updates.go:166` skips the check outright when
    `GetBuildSource() != "buildBinary"`, and `lazygit --version` reports `build source='debian'`.
  - `git.paging.colorArg: always` — already the default (`lazygit --config`), even though the
    official docs list it next to `pager`.
  - `gui.nerdFontsVersion: "2"` — the wrong lever for a v2 font.
    `patchFileIconsForNerdFontsV2()` substitutes only **3** codepoints, so it repairs almost
    nothing. The version to set is `"3"`, and what decides whether that works is the terminal font:
    p10k-media's bundled `MesloLGS NF` is Nerd Fonts **v2.3.3** (not rebuilt since 2023-04-03) and
    covers 270/324 of lazygit's icons, against 321/328 for Nerd Fonts v3.4.0's own `Meslo.zip`.
    `~/.p10k.zsh` declaring `POWERLEVEL9K_MODE=nerdfont-v3` is the signal that the v3 font is the
    one installed — also the prerequisite behind `debian/todo.md`'s eza `icons` item.

  `modern_cli/bat/` installs the `bat` package, makes the `~/.local/bin/bat` symlink over Debian's
  `batcat`, and ships `~/.config/bat/config`. The symlinked name needs one `compdef bat=batcat`
  line, which `custom_env.sh` writes — see the `compinit` discussion under Conventions for why that
  line is required and an alias would not have been. Four things about `bat/config` are worth
  knowing before touching it. Its two lines are verbatim the two options bat's own
  `--generate-config-file` template leaves commented out, so it diffs cleanly against upstream. Its
  format is a shell word-split per line, so — unlike micro's JSON — it takes `#` comments,
  whole-line *or* trailing, which is what lets it carry the managed-by header; that same splitting
  makes `--theme="TwoDark"`'s quotes decorative rather than load-bearing, the opposite of
  `git/config.yml`'s. Where micro and lazygit silently ignore an unknown key, bat **hard-errors**
  on one — the file's words are prepended to argv, so clap rejects it and *every* `bat` run fails
  until it is removed. And it must be the **only** place bat's theme is set: `BAT_THEME` in the
  environment outranks the config file (verified in both directions). delta is unaffected either
  way — its theme comes from gitconfig (`delta.syntax-theme`), not from `BAT_THEME`.

  With `bat/config` the rule is uniform across the repo: **a tool's own config file is always a
  shipped artifact, never an `echo` block.** `micro/settings.json`, `git/config.yml` and
  `bat/config` land through the same `install -Dm 644`, and `copilot_api/settings.json` is that
  plus `jq` interpolation; what is left to `echo` is only the files this repo invented
  (`00-setup_env.zsh`, `01-first_run.zsh`, `setup-env.plugin.zsh`) and the appends into files an
  upstream installer or the shell already made (`tmux.conf.local`, `.zshenv`, the ssh config) —
  plus the git config, which goes through `git config --global` and has no file to ship.

  `modern_cli/fdfind.sh` is that same arrangement for `fd` minus the config file: it installs
  `fd-find` and makes the `~/.local/bin/fd` symlink over Debian's `fdfind`, and extracting it is
  what removed `link_binaries()` from `main.sh` — `fd` was its only entry. Unlike bat it needs no
  `compdef` line, because Debian's `_fd` declares `#compdef fd` and the symlinked name is therefore
  already registered.

  `glow` deliberately stays in `modern_cli/main.sh`'s bulk apt list rather than becoming a directory
  component: setup-env owns no Glow config. Trixie ships Glow 2.0.0 with Glamour 0.8.0; the generated
  `~/.config/glow/glow.yml` already selects `style: "auto"`, `mouse: false`, `pager: false` and
  `width: 80`, and none needs a repo-wide override. The non-default switches are not general
  improvements either. `--all` only expands the TUI's Markdown search to the dotfiles,
  `node_modules` and `GOPATH` it normally ignores; TUI line numbers count rendered display lines,
  not source lines; and preserved newlines are consumed by the TUI pager's Glamour path, useful for
  poetry or hand-laid-out notes but harmful to normal Markdown reflow. Keep all three opt-in.

  Glow has no plugin API. Glamour 0.8.0's built-in top-level styles are `auto`, `ascii`, `dark`,
  `dracula`, `tokyo-night`, `light`, `notty` and `pink`; One Dark is not one of them. As of
  2026-08-10 the organised community themes are other palettes, while the One Dark files found are
  unmaintained or lack a reusable licence, so this tree ships no Glow stylesheet. That also leaves
  no reason for a Glow alias, helper function, completion artifact or global `GLOW_*` /
  `GLAMOUR_*` setting; the later omz-plugin rejection remains the shell-side half of this choice.

  Paging stays opt-in too. `glow -p` sends the rendered document to `$PAGER`, falling back to
  `less -r`; `PAGER='less -R' glow -p FILE.md` is the safer one-shot form because `-R` passes ANSI
  colour sequences without allowing every control character. Do not export `PAGER='less -R'`:
  pager options belong in `$LESS` (the `APP_TMUX` block already owns this tree's `LESS` value), and
  a global `$PAGER` changes unrelated programs. Glow parses Markdown, not roff or Git patches, so it
  is not a `MANPAGER`, Git pager or replacement for delta either.

  `modern_cli/tldr.sh` is the smallest: it installs `tealdeer` (leaving
  `~/.config/tealdeer/config.toml` unseeded at its defaults), warms the offline page cache with
  `tldr --update || true` (a network failure is not fatal — the cache fills on first use), and
  symlinks Debian's `/usr/share/zsh/vendor-completions/tldr.zsh` into `$ZSH_CUSTOM/completions/`
  under the name `_tldr` — the only reason that completion ever loads, for which see the `compinit`
  discussion under Conventions. A symlink rather than `install -Dm 644` because the source is a
  packaged file that apt will upgrade in place; the `[[ -f $completion ]]` guard ahead of it is
  there because `ln -sf` against a missing source does not fail, it leaves a dangling link — the
  exact silent-no-op failure mode the symlink exists to undo.
- `container/` — builds and runs a Docker dev container (`dev-container`) or the
  `copilot-api` image.

`windows-wip/` is **not** a setup tree — it is a staging area for scripts awaiting Windows
adaptation. No `--setup` value reaches it and nothing runs it; `windows-wip/code/{csharp,powershell}.sh`
are still the Debian `apt` versions they were before being moved out of `debian/code/`.

`debian/vscode/` and `windows-wip/vscode/` are reference data, not dispatcher components — no
script installs them (`--app-vscode` on debian only adds the omz `vscode` plugin in
`command/omz_custom/main.sh` and the `EDITOR="code --wait"` branch in
`command/omz_custom/custom_env.sh`).
`windows-wip/vscode/` holds only the C#/PowerShell delta on top of `debian/vscode/`; `README.md`
documents the manual `code --install-extension` step and the `files.readonlyInclude` merge caveat.

`debian/todo.md` is the debian tree's pending-work list, carrying only what is still undone, each
item with its current state, the fix, and the upstream citation behind it. Everything already
settled lives in this file instead; the two are meant to be read together, and an item that lands
here should leave `debian/todo.md`.

### The dispatcher pattern

1. Env-var defaults with override: `export FOO="${FOO:-0}"`. The platform roots `debian/main.sh`
   and `macos/main.sh` export their flag vars so leaf scripts can read them.
2. `parse_args()` walks `$@`, sets vars for known flags, and pushes everything else onto
   `POSITIONAL` so downstream scripts can still see their own flags.
3. Boolean flags (`--app-tmux`) `shift` once; value flags (`--branch <v>`) use the
   `numOfArgs` idiom that guards against a missing trailing value before `shift`ing twice.
4. `main()` runs each enabled component's leaf script, gated on `FOO == '1'`, in a fixed group
   order: **`--command-*` → `--code-*` → `--tools-*` → `--app-*`**, alphabetical within each group.
   The grouping is dependency-shaped — a language toolchain (`--code-*`) can be a prerequisite for
   an app, never the reverse — and the `export` block and `parse_args()`'s cases repeat it, so the
   file reads top-to-bottom in the order it runs. Every gate runs exactly one script; a component
   made of several scripts nests them under its own directory and lets its `main.sh` run them
   (`--command-modern-cli`, `--app-claude`). Exporting is a deliberate cross-cutting mechanism: a
   leaf can read *another* component's flag to add integration config only when both are enabled —
   e.g. `tmux.sh` reads `APP_CLAUDE` (Claude Code passthrough / extended-keys when `--app-tmux` +
   `--app-claude`). That env read is intentional, not a missing `parse_args`. The
   `command/omz_custom/` scripts read component flags for a different reason: they *own* drop
   points that every component writes through, so they gate their `append_plugin` calls and their
   generated blocks instead of letting the component touch `plugins=()` or the file.
5. Standard footer guard so scripts are both runnable and sourceable:

   ```bash
   if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
       cd "$(dirname "${BASH_SOURCE[0]}")"
       parse_args "$@"
       set -- "${POSITIONAL[@]}"   # restore positional params
       main "$@"
   fi
   ```

**When adding a new component**, mirror this pattern: add the `export FOO=...` default and
`--flag` case to the relevant `main.sh` — in its group's slot — add the gated
`bash './path/foo.sh' "$@"` call, write the leaf script with the same footer, and document the flag
in `README.md`'s table. Four lists then have to stay in that same order: `main()`'s gates, the
`export` block, `parse_args()`'s cases, and the README table.
Runtime shell config the component needs goes to `command/omz_custom/custom_env.sh` — a block
gated on the new flag, never a `>>` into `00-setup_env.zsh` from the component's own script
(see Conventions); config a plugin reads *while loading* goes to
`command/omz_custom/pre_plugin.sh` instead, same rule. If it also wants an omz plugin, that goes
in `command/omz_custom/main.sh` — an `append_plugin` call in `install_plugin()` gated on the new
flag, plus a `git clone` in `download_plugin()` if it is third-party — never a `sed` on
`plugins=()` from the component's own script. If it needs a one-off
*interactive* step the unattended install cannot perform (a login prompt, a wizard), that goes in
`command/omz_custom/first_run.sh` — a block gated on the new flag, same ownership rule. In
`pre_plugin.sh` and `first_run.sh` the gated block is the *whole* addition; there is no second
condition to keep in step (see "Empty output is no output").

### Nesting

Flags cascade through nested dispatchers. `--app-claude` (in `debian/main.sh`) invokes
`debian/app/claude/main.sh`, whose own `--app-claude-copilot-api` then invokes
`debian/app/claude/copilot_api/main.sh`, which parses the base URL, auth token and three default
model value flags. `README.md` groups flags as "main args" vs "script args" to reflect which
dispatcher owns them.

### Container flow

`container/dev-container/main.sh` base64-encodes the forwarded setup flags
(`setup_args_b64`) and passes them as a Docker build-arg. The `Dockerfile` decodes them and
runs `debian/main.sh --unattended <flags>` inside the image (build context is `../../debian`).
So container flags are really debian flags — `--unattended` (see `command/omz.sh`) makes oh-my-zsh
install non-interactively and switches the login shell.

### Claude Code LSP integration

`debian/app/claude/main.sh` reads `CODE_GO`, `CODE_PYTHON` and `CODE_RUST` from the Debian
dispatcher instead of parsing `--code-*` again. This is a clean one-shot flow and assumes
`--app-claude` is paired with at least one of those language flags. The language components run
first and own their toolchains; the Claude component then owns both the server and plugin halves of
its LSP integration.

`install_lsp()` exposes `~/.local/bin` for the newly installed `claude`, then explicitly adds
`claude-plugins-official` because automatic registration does not happen until the first interactive
Claude launch. Each language stays in one block: Go adds `~/go/bin` and `/usr/local/go/bin`, installs
latest `gopls`, then `gopls-lsp`; Python adds `~/.local/bin`, installs the isolated
`pyright[nodejs]` uv tool, then `pyright-lsp`; Rust adds `~/.cargo/bin`, installs the
`rust-analyzer` rustup component, then `rust-analyzer-lsp`.

The explicit marketplace add writes `extraKnownMarketplaces`, while plugin install writes
`enabledPlugins`. After all plugins are installed, the script uses `jq` and a mode-600 temporary file
to remove only the official marketplace declaration (and the empty parent map), preserving
`enabledPlugins`, copilot/custom marketplaces and the separate registry/cache files. This deliberately
relies on Claude Code 2.1.232 continuing to recognize its internal official registry; never replace
that cleanup with `marketplace remove`, which would uninstall the plugins.

`install_lsp()` runs after the optional copilot-api child because `install_settings()` replaces
`~/.claude/settings.json`; registering or cleaning LSP state earlier would let that template erase the
final `enabledPlugins` entries.

### copilot-api integration

`copilot_api/main.sh` validates the requested models, installs the completed `settings.json` as
`~/.claude/settings.json`, then installs the copilot-api plugins. The caller must supply the Opus,
Sonnet and Haiku default models through their value flags or corresponding
`APP_CLAUDE_DEFAULT_*_MODEL` variables. `check_model()` requests
`$APP_CLAUDE_BASE_URL/v1/models` for each model, uses `jq` only to extract the `claude_model_id`
values, then checks for an exact line match. `main()` owns the empty/missing-model error; there is
no generation, family or fallback selection.

`install_settings()` passes those three models plus `APP_CLAUDE_BASE_URL` (default
`http://localhost:4141`) and `APP_CLAUDE_AUTH_TOKEN` to `jq` under their final `ANTHROPIC_*` key
names, merges `$ARGS.named` into the shipped template, writes it directly to the target, and sets
the target directory and file to modes 700 and 600 respectively. A model's
`[1m]` suffix already tells Claude Code to use its extended context window, so the template
deliberately leaves `CLAUDE_CODE_AUTO_COMPACT_WINDOW` unset and lets Claude Code keep its own
output and compaction reserves. It configures automatic teammate mode, the large workflow size
guideline and fullscreen TUI. The server must already be reachable at `APP_CLAUDE_BASE_URL`.

The installed marketplace supplies both `agent-inject` and `tool-search`. `tool-search` provides
the GPT Responses deferred-tool MCP bridge; Claude Code's native `ENABLE_TOOL_SEARCH` must stay
unset because it can withhold the full tool definitions the gateway needs. Both plugins use Node,
npm and npx, but `install_plugins()` deliberately keeps the old lightweight bootstrap: it checks
only whether `node` exists and installs NodeSource LTS when it does not, leaving plugin installation
to report an incomplete or incompatible existing runtime. Node remains this integration's private
dependency — there is no standalone `--tools-node` component or `debian/tools/node.sh` — and
`build-essential` remains unnecessary for the prebuilt package and plugins.

## Conventions

- Every script starts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- **Quoting: `'…'` for literals, `"…"` only where something expands.** A double quote in this
  repo is a claim that the string contains a `$`, a `` ` ``, or an escape — so `append_plugin 'z'`,
  `[[ $CODE_GO == '1' ]]`, `bash './code/go.sh' "$@"`, `curl -fsSL 'https://…'`, `echo 'Docker is
  not installed.' >&2`. Three corollaries, each of which has already bitten:

  1. **`${VAR:-default}` takes a bare default**, not a quoted one. The surrounding double quotes
     already suppress splitting, and `"${BRANCH:-'master'}"` expands to a literal `'master'`,
     quotes and all — a silent bug, not a style choice.
  2. Bare words stay bare where the repo never quoted them: `> /dev/null`, command names, apt /
     brew formula names, option values (`--restart unless-stopped`, `-p 4141:4141`), and
     `git config --global delta.navigate true`. Paths, URLs, filenames, cask names and container
     names do get quoted.
  3. Single quotes cannot contain a single quote — not even with `\'`, since bash has no escape
     inside `'…'`; the quote has to be broken (`'\''`). The next rule is what keeps that out of
     this repo entirely.
- **Generated content: the `echo` is single-quoted, the content inside it is double-quoted.**
  Every line written into `00-setup_env.zsh`, `.zshenv`, `.zshrc` or `tmux.conf.local` goes out as
  `echo '…'`, so bash emits it verbatim and nothing can expand at setup time. Quoting *within* the
  generated line — read later by zsh or tmux, not by bash — is then free to be `"…"`:

  ```bash
  echo 'export YSU_MESSAGE_POSITION="after"'
  echo 'alias tree="eza --tree"'
  echo 'export PATH="$PATH:/usr/local/go/bin"'      # $PATH survives to .zshenv
  echo '    IFS= read -r -d "" cwd < "$tmp"'        # zsh reads "" as the NUL delimiter
  echo 'set -as terminal-features "xterm*:extkeys"' # tmux.conf.local
  ```

  Never flip the outer pair to double in order to put single quotes inside — that is how
  `export PATH="$PATH:…"` silently becomes the build machine's literal `PATH`. And never stack
  `'\''`: with the content double-quoted there is no single quote left to escape. The only `echo`s
  that legitimately open with `"` are the ones whose *own* text interpolates a variable
  (`echo "Host $COMMAND_SSH_HOST"`, `echo "Unsupported setup: $SETUP" >&2`) — plus
  `omz_custom`'s `echo "$blocks"`, which replays lines that were emitted by single-quoted `echo`s
  inside a `$( … )` and captured verbatim. Parameter expansion is not re-scanned, so a `$` sitting
  in `$blocks` reaches the file as text exactly as it would have from the original `echo '…'`.
- Prefer `command -v foo` guards before use; install missing deps with
  `sudo apt-get update && sudo apt-get install -y foo` (debian) inline.
- **Every GitHub release download goes through `releases/latest/download/<asset>`.** A tag never
  appears in a URL. What decides whether any version resolution happens at all is the *asset
  filename*. `choose-x86_64-unknown-linux-gnu` and `yazi-x86_64-unknown-linux-gnu.zip` carry no
  version, so `command/modern_cli/main.sh` downloads both directly from pure literal URLs —
  single-quoted, per the quoting rule — with no helper at all. `protoc-35.1-linux-x86_64.zip`
  embeds one, so `tools/protobuf.sh` still resolves it, but only to
  build the *filename*, never a `/releases/download/v<tag>/` path. `get_protoc_latest()` is that
  resolver: `curl -fsSIL -o /dev/null -w '%{url_effective}'` on `/releases/latest` piped through one
  `sed -E 's#.*/tag/v?([^/]+)$#\1#'` (the `v?` strips the tag prefix the asset name does not want),
  followed at the call site by an `if [[ -z $version ]]` guard, since a network failure yields an
  empty string rather than a non-zero exit and `set -e` cannot catch it. **Resolving a version only
  to write it straight back into the URL path is the tell that the step is dead weight** — that was
  the older yazi path in `command/modern_cli/main.sh`, with the bare number never used for anything.

  Two things this does *not* buy. It does not pin a version — `latest` is `latest` either way, so a
  re-run picks up whatever shipped since. And `latest` plus an explicit version in the asset name
  has a race: if upstream publishes between the resolve and the download the old filename 404s —
  loud, not silent, since `curl -f` exits non-zero and `set -e` aborts before anything is installed.

  `container/copilot-api/main.sh`'s `get_copilot_api_latest()` is the same helper but sits outside
  this rule: it has no asset URL to write. `$version` is a git ref for `docker build`
  (`…/copilot-api.git#v$version`) and the tag of the image it then runs.
- Config edits are done in-place with `sed -i` against known upstream markers (e.g.
  toggling commented lines in `.zshrc` / `tmux.conf.local`, or inserting into `plugins=(...)`).
  These depend on the exact upstream file format — verify the marker still exists upstream
  when a `sed` edit silently no-ops.
- **omz plugin ownership**. Every `plugins=()` and `ZSH_THEME=` edit in a tree lives under
  `command/omz_custom/` and nowhere else. The directory name maps to `$ZSH_CUSTOM`
  (`~/.oh-my-zsh/custom/`) because everything it produces lands there: the `plugins/*` and
  `themes/*` clones, `00-setup_env.zsh`, `01-first_run.zsh`, and the self-authored
  `plugins/setup-env/` plugin. `command/omz.sh` installs oh-my-zsh itself (and, on debian, the
  `zsh` package) and does nothing else.

  Inside the directory the split is by **landing point**, one file each. `main.sh` owns `.zshrc` —
  both edits it makes (`plugins=()` and `ZSH_THEME=`) and the clones those edits need — and then
  calls the env scripts in the order zsh will load what they write: `pre_plugin.sh` (debian only)
  owns `plugins/setup-env/setup-env.plugin.zsh`, `custom_env.sh` owns `00-setup_env.zsh`, and
  `first_run.sh` (debian only) owns `01-first_run.zsh`. Those three are identical in shape — two
  functions and no more. `render_blocks()` holds every `echo` and every gate, and only writes to
  stdout; `main()` decides where that goes and whether it goes anywhere at all: one line for
  `custom_env.sh` (`render_blocks > "$ZSH_CUSTOM/00-setup_env.zsh"`), capture-test-write-or-skip
  for the other two, with `first_run.sh` additionally removing a file an earlier run left (see
  "Empty output is no output" and "Only `first_run.sh` deletes" below). The one exception to
  "`main.sh` owns `.zshrc`" falls out of that: `pre_plugin.sh` also owns the single word
  `setup-env` inside `plugins=()`, because the plugin file and its array entry have to appear
  together. There are **no per-plugin leaf scripts** — `main.sh` is four functions on both trees
  and that is the whole design:

  | function | what it does |
  | --- | --- |
  | `download_plugin()` | every `git clone` for the third-party plugins, one block |
  | `install_plugin()` | resets `plugins=()`, then one `append_plugin` call per plugin |
  | `append_plugin()` | one `sed` appending a name before the closing `)` |
  | `install_theme()` | clones powerlevel10k and points `ZSH_THEME=` at it (on macos, plus the Meslo cask) |

  `install_plugin()` resets the array to `plugins=(aliases)` on both trees — `setup-env` is not
  named here, `pre_plugin.sh` prepends it afterwards if it wrote a plugin at all — then calls
  `append_plugin` once per remaining plugin (`colored-man-pages` first on debian, `brew` on macos),
  each optional one gated on its component's exported flag: `docker`/`docker-compose` on
  `APP_DOCKER`, `python`/`uv` on `CODE_PYTHON`, `eza`/`zoxide`/`fzf`/`fzf-tab` on
  `COMMAND_MODERN_CLI`, and so on; on macos `ssh` on `COMMAND_SSH`, whose `~/.ssh/config` is
  written later by `command/ssh.sh`. Leaving an optional plugin ungated hides that dependency and
  leaves a silently no-op plugin behind whenever the component is off.

  The installing component (`code/go.sh`, `app/docker.sh`, `command/modern_cli/main.sh`, …) keeps its
  installs and its non-zsh config but must not touch `plugins=()` — nor `00-setup_env.zsh` or
  `01-first_run.zsh`, which follow the same rule for the same reason. `omz_custom` runs second in
  the tree, so a plugin name reaches `.zshrc` *before* its tool is installed — harmless, since
  nothing reads the array until a shell starts, which is after setup ends.
- **omz plugin ordering** (debian and macos trees alike). `append_plugin()` appends before the
  closing `)`, so **array order is exactly the call order in `main.sh`'s `install_plugin()`** — no
  anchors, no insert-before tricks. Reordering the array means reordering those calls. The single
  exception is `setup-env`, prepended by `pre_plugin.sh` afterwards.

  **`setup-env` must be first** — the one constraint this repo imposes on itself rather than
  inheriting from upstream. It is the plugin `pre_plugin.sh` writes, and its entire job is to
  set variables the *other* plugins read while they are being sourced (`PYTHON_AUTO_VRUN` today).
  `oh-my-zsh.sh:203` is a plain `for plugin ($plugins)`, so first-in-the-array means
  first-sourced. Demote it and whatever it sets silently stops taking effect for every plugin
  ahead of it. What pins it is `pre_plugin.sh`'s own `sed` — a *prepend* into the array
  (`/^plugins=(/s/(/(setup-env /`) run right after it writes the plugin file. An `append_plugin`
  call in `install_plugin()` could not do this: the name has to be able to stay out of the array
  entirely, and only the script that decides whether the plugin exists knows that.

  The remaining constraints all come from upstream, not from this repo:

  1. `zsh-syntax-highlighting` must be **last** (upstream INSTALL.md).
  2. `fzf-tab` must load **before** anything that wraps ZLE widgets — i.e. before
     `zsh-autosuggestions` and `zsh-syntax-highlighting` (fzf-tab README).
  3. `fzf` must load **after** `fzf-tab`. fzf's `completion.zsh` saves whatever `^I` is bound to
     at that moment as `fzf_default_completion` and calls it when the `**` trigger is absent.
     Reversed, fzf-tab becomes the outer widget and its "call the original to get the completion
     list" step runs the interactive `fzf-completion`, nesting two fzf UIs.
  4. Cloned (third-party) plugins must load **after** `ohmyzsh-full-autoupdate`. It runs
     `git -C "$packageDir" pull` **synchronously** (`ohmyzsh-full-autoupdate.plugin.zsh:170` — no
     `&` / `&|`) while omz is sourcing the array in order, so plugins after it pick up the freshly
     pulled code on the *same* shell start; ones before it load stale code and only see the update
     next time.
  5. Anything that replaces or binds a ZLE widget (`safe-paste` → `bracketed-paste`,
     `magic-enter` → `accept-line`, `fancy-ctrl-z` → `^Z`, `dirhistory` → Alt-arrows) must load
     before `zsh-syntax-highlighting`. In practice they all sit near the front already.
  6. macos only: `brew` must stay ahead of `command-not-found` — the Homebrew handler the latter
     sources bails on `command -v brew`. That carries more weight than it looks: `homebrew.sh`
     deliberately does **not** write `eval "$(brew shellenv)"` into `.zprofile` (upstream's
     `install.sh` only *prints* that instruction), so the `brew` plugin is the only thing putting
     brew on `PATH` in an interactive shell — the one gap being `zsh -l -c '…'`, which nothing here
     uses. Unrelated and still required: `macos/main.sh`'s own `eval` line, which runs in the
     setup-time *bash* process so child scripts can find brew — no zsh plugin can reach that.

  **The debian tree violates 1–3 whenever `--command-modern-cli` is on**, and appends `z` (zsh-z)
  unconditionally even though `zoxide` then takes over the same command name. macos satisfies all
  six today. Both are pending the `--command-modern-cli` rework — `debian/todo.md` §1 and §2 hold
  the analysis, the fix and the target array.

  Should *removing* a name from the array ever be needed again: delimit on spaces and parens
  (`s/(z /(/; s/ z / /; s/ z)/)/`), never `\<z\>`. `-` is not a word constituent, so `\<z\>` also
  matches the tail of `fancy-ctrl-z` and eats the separator behind it, fusing two entries into
  `fancy-ctrl-magic-enter` — omz then reports `plugin not found` on every start while both real
  plugins silently vanish. Any name ending in `-<single letter>` hits this. (BSD sed has no
  `\<`/`\>` anyway, so macos could never have used them; there `sed -i` must also be written
  `sed -i ''`.)
- **Three drop points for the shell config this repo owns:
  `$ZSH_CUSTOM/plugins/setup-env/setup-env.plugin.zsh`, `$ZSH_CUSTOM/00-setup_env.zsh` and
  `$ZSH_CUSTOM/01-first_run.zsh`** — one script each, as above. The first two differ only in
  *when* they load, and that is the whole basis for deciding where a given setting goes. The test
  is **when the variable is read, not what it is**. The third sits on a different axis — not
  *when* it loads but *how often* it runs: once, ever.

  `oh-my-zsh.sh`'s own order: plugin dirs join `fpath` (l.92) → `compinit` (l.127) → `lib/*.zsh`
  (l.197) → **plugins sourced in `plugins=()` order (l.203)** → **`$ZSH_CUSTOM/*.zsh` in
  alphabetical order (l.209)** → theme (l.214). So:

  | config | goes to |
  | --- | --- |
  | anything a plugin reads *while loading* | `$ZSH_CUSTOM/plugins/setup-env/setup-env.plugin.zsh` |
  | aliases, functions, `compdef`, env vars read at runtime | `$ZSH_CUSTOM/00-setup_env.zsh` |
  | a one-off interactive step (login prompt, wizard) | `$ZSH_CUSTOM/01-first_run.zsh` |
  | `plugins=()`, `ZSH_THEME=`, anything `compinit` or `lib/*.zsh` reads | `.zshrc` |
  | `PATH` and anything a non-interactive shell needs | `.zshenv` (see `code/go.sh`, `code/rust.sh`) |

  `compdef` is in row two rather than row four because `compinit` runs at l.127, well before
  l.209 — `custom_env.sh`'s `COMMAND_MODERN_CLI` block writes `compdef bat=batcat` there. Two rules
  govern that line and the symlinks around it: **`compinit` looks at a file only if its name
  matches `_*`**, and **it registers by the name on that file's `#compdef` first line, not by the
  file name and not by whether the command exists.** Debian's three packagers diverged along both
  axes: `bat` ships `_batcat` declaring `#compdef batcat` (`PROJECT_EXECUTABLE=batcat`, matching
  the binary it actually ships); `fd-find` ships `_fd` declaring `#compdef fd` though its binary is
  `fdfind` (Debian #936036, fixed 2019, since regressed, no open bug); `tealdeer` ships a perfectly
  valid `#compdef tldr` in a file named `tldr.zsh`, which `_*` never globs, so `_comps[tldr]` is
  empty with no error, no clue, and no Debian bug against `src=rust-tealdeer`. Net effect: `fd`
  catches a completion that was dangling on a name Debian never installed — free; `bat` creates a
  name nobody registered — hence the one `compdef` line; `tldr` needs neither, because
  `modern_cli/tldr.sh` fixes it at the source. If Debian ever fixes fd properly, add the
  mirror-image `compdef fd=fdfind`; do **not** add it pre-emptively, since `compdef name=service`
  on an unregistered service prints `compdef: unknown command or service: fdfind` on every start
  (it does leave `_comps[fd]` intact).

  Two ways of avoiding that `compdef` line were vetted and rejected. **Doing for bat what
  `modern_cli/tldr.sh` does for tldr cannot work** — tldr's defect is its *file name*, bat's is its
  *content*: symlinking `_batcat` to `_bat` yields `_comps[batcat]=_bat` with `_comps[bat]` still
  empty (verified on trixie / bat 0.25.0), and `batcat --completion zsh` prints the same
  `#compdef batcat` because `PROJECT_EXECUTABLE` is baked in at build time. **A hand-written `_bat`
  shim works but is the worse mechanism** — a missing `_batcat` is loud on every shell start under
  `compdef` and a silent no-op at the first `<TAB>` under the shim, and it buys only file-placement
  tidiness against the mechanism zsh provides for exactly this.

  An alias would *not* have needed the `bat` line: zsh expands aliases into `words` before
  completion dispatch, so `alias bat=batcat` inherits `_batcat` for free — and by the same
  mechanism `alias fd=fdfind` **destroys** the `_fd` completion it would otherwise get. The symlink
  wins on the other axis: an alias is shell-local state, so `(( $+commands[fd] ))` (which
  `fzf.plugin.zsh:267` uses to pick `FZF_DEFAULT_COMMAND`) is false under it and no `$SHELL -c`
  child — fzf's `--preview` above all — can see it, while `PATH` is exported and inherited by
  every child.

  `~/.local/bin` is the one `PATH` entry the repo does *not* write itself: `command/omz.sh:44`
  uncomments omz's own template line (`export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH`,
  `.zshrc` l.2), and `omz.sh` runs first in the tree — so any later component can drop a binary
  there and have it resolve. `modern_cli/fdfind.sh`'s `fd` symlink, `modern_cli/bat/main.sh`'s `bat`
  symlink and `tools/protobuf.sh`'s `protoc` all rely on this, and it is why none of those placements
  needs `sudo`. Being in `.zshrc` it is interactive-only — enough for the
  `(( $+commands[fd] ))` probes plugins do while `.zshrc` is still being sourced (l.2 precedes the
  `source $ZSH/oh-my-zsh.sh` at l.75), but a non-interactive `zsh -c` will not see it.

  Only `PYTHON_AUTO_VRUN` is in the first row today — `python.plugin.zsh:103` decides at load
  time whether to register the `chpwd` hook, and the plugin's own README says to set it "before
  sourcing oh-my-zsh". `zstyle ':omz:plugins:eza' …` belongs there too (`eza.plugin.zsh:9-54`
  builds its aliases at load time) and is pending — `debian/todo.md` §3.

  Row four earns its second clause from where the first row sits. `setup-env` is sourced at l.203
  — **after** `compinit` (l.127) and **after** `lib/*.zsh` (l.197) — so anything those two read is
  out of its reach and can only come from `.zshrc` itself: `ZSH_DISABLE_COMPFIX`, `ZSH_COMPDUMP`,
  `CASE_SENSITIVE` / `HYPHEN_INSENSITIVE` (`lib/completion.zsh:17,20`, with l.26 `unset`ting them
  right after, so a late assignment leaves no trace at all), `HIST_STAMPS`,
  `DISABLE_MAGIC_FUNCTIONS`, `DISABLE_LS_COLORS`, `DISABLE_AUTO_TITLE`. Nothing this repo writes
  today falls in that class — worth knowing only before adding one.

  The reverse direction has a trap worth knowing before moving anything into `setup-env`: a value
  living in an associative array that the plugin itself declares cannot be set early at all.
  `colored-man-pages` creates `less_termcap` with `typeset -AHg`; assigning `less_termcap[so]`
  before that runs is not merely ineffective — zsh treats the undeclared name as an ordinary
  array and errors out on `so` as a subscript. Such values can only come from
  `00-setup_env.zsh`.

  What goes in either file is filtered once more by intent: **only settings that differ materially
  from the upstream default get written at all.** A line restating a default, or one whose effect
  the default already covers, is noise that reads like a deliberate choice — `PYTHON_VENV_NAME`
  was dropped because `PYTHON_VENV_NAMES` already defaults to `venv .venv`. Documentation is the
  second filter: `DIRHISTORY_SIZE` was dropped because the dirhistory README never mentions the
  variable and states the 30-entry limit as fact.

  **`plugins/setup-env/`** is a plugin this repo authors rather than clones, and it reaches the
  shell through the mechanism already in place for every other plugin: a name in `plugins=()`.
  No zsh-side dispatcher — being first in the array *is* the ordering guarantee. The layout is
  upstream's: `is_plugin()` (`oh-my-zsh.sh:81`) only recognises `plugins/<name>/<name>.plugin.zsh`
  (or `_<name>`), and a missing file makes l.96 print `[oh-my-zsh] plugin 'setup-env' not found`
  on every start — which is why the file and the array entry are written by the same script, in
  that order, and by nothing else. Two things it does *not* interact with, both worth
  knowing: `ohmyzsh-full-autoupdate` finds its update targets with
  `find -L "$custom" -type d -name ".git"` (`ohmyzsh-full-autoupdate.plugin.zsh:151`), so a
  non-repo directory is skipped; and l.92 is `fpath=("$ZSH_CUSTOM/plugins/$plugin" $fpath)` —
  a *prepend*, so the later a plugin sits in the array the earlier its dir sits in `fpath`.
  First-in-array means last in completion priority. Irrelevant for a plugin that ships no
  completions, but don't expect to override someone's `_foo` from here. macos has no load-time
  settings today, so its tree has no `setup-env` plugin and no `pre_plugin.sh` at all.

  **Empty output is no output.** `pre_plugin.sh` and `first_run.sh` both capture their
  `render_blocks()` into a variable before writing anything, and on an empty render they write
  nothing at all — no plugin and no `plugins=()` entry for the first, no `01-first_run.zsh` for the
  second. Rendering first is what makes the test the *content* rather than a restated list of
  flags, so a component added to one of these files can never desync from the condition that
  decides whether the file exists. `custom_env.sh` is deliberately not in this scheme — its
  unconditional section means `00-setup_env.zsh` is always wanted, so there is nothing to filter.

  **Only `first_run.sh` deletes**, and the asymmetry is deliberate. An `01-first_run.zsh` left over
  from an earlier run would fire again: `custom_env.sh` rewrites `00-setup_env.zsh` with `>` every
  run, so the `SETUP_ENV_FIRST_RUN=0` sentinel is gone and the guard at the top of the stale file
  reads `${SETUP_ENV_FIRST_RUN:-1}` — a second `gh auth login` for a component the user just turned
  off. Hence the `rm -f`. A stale `setup-env.plugin.zsh` has no such effect: `install_plugin()`
  resets the array wholesale every run, and omz's two loops (l.90 for `fpath`, l.203 for sourcing)
  only ever walk `$plugins`, so the file is simply never read. Deleting there would be tidiness,
  not correctness, and would need a second `sed` to pull the name out of the array on top. **Do not
  add one back** without a reason that survives this paragraph.

  **`00-setup_env.zsh`** is `custom_env.sh`'s `render_blocks()` redirected into place by its
  `main()` — the only write to that file anywhere in the tree, so a re-run rebuilds it instead of
  accumulating duplicate blocks, and no component can append behind its back. The unconditional
  section comes first, then one gated block per component, each headed by a `#` title, in the
  order those components run in `debian/main.sh`: `COMMAND_MODERN_CLI` — one gate holding the
  dispatcher integrations in one place (`# Modern CLI tools`; `# bat`, only `compdef bat=batcat`
  because everything else bat needs lives in `~/.config/bat/config`; `# Editor` then `# Micro`,
  with the `EDITOR="code --wait"` branch nested one level deeper on `APP_VSCODE`; `# yazi`, the
  existing `y()` wrapper for the binary installed inline by `modern_cli/main.sh` — `fdfind.sh` and
  `tldr.sh` contribute nothing) — then `APP_DOCKER` (`# Docker`, the
  `lzd` alias), `APP_GIT` (`# Git`, the `lg()` wrapper) and `APP_TMUX` (`# tmux mouse scroll`).
  Block titles name the *component*, not the tool, wherever the two differ — `# Git` rather than
  `# lazygit` — matching `# Editor` / `# Micro` above them. Intra-file order is cosmetic — the
  whole file lands at l.209, after every plugin, which is exactly what lets a value here override
  one a plugin set — but following the dispatcher keeps it predictable. The `00-` prefix is load
  order, not decoration: omz sources `$ZSH_CUSTOM/*.zsh` alphabetically, so a second file must
  pick its number the same way.

  `lg` and `lzd` are the short commands lazygit's and lazydocker's own READMEs suggest, and both
  names were checked clear before being taken — nothing this tree installs or enables defines
  either. Of the two forms lazygit's README offers, the `lg()` function from *Changing Directory On
  Exit* is the one written, not the one-line `alias lg='lazygit'` from *Usage* — same shape as the
  `y()` wrapper two blocks up, and it works on Debian's 0.50.0 without pre-creating `~/.lazygit/`
  (`CreateFileWithContent` starts with `os.MkdirAll`, `oscommands/os.go:173`). Two consequences
  worth knowing: the function's `export` leaves `LAZYGIT_NEW_DIR_FILE` in the environment of every
  later child process — harmless, since a bare `lazygit` then just writes that file too and nothing
  reads it; and the cd is **not** limited to the switch-repos case the README describes.
  `gui.go:882` writes the file on *every* quit, `q` recording `os.Getwd()` and `shift+Q` recording
  `gui.InitialDir`, so running `lg` from a subdirectory and quitting with `q` lands the shell at
  the repo root — `shift+Q` is the way back. (Verified against 0.50.0 under a pty.)

  The `# Micro` block's `MICRO_TRUECOLOR=1` is the only way to get true color out of micro on
  Debian, and it belongs there rather than in `micro/settings.json`: trixie ships micro 2.0.14,
  whose option list (`micro -options`, and the v2.0.14 tag's own `runtime/help/options.md`) has no
  `truecolor` key at all — upstream added one later, and even there it is the enum
  `"auto"`/`"on"`/`"off"`, not a boolean. **micro silently ignores unknown keys in `settings.json`**
  — a bogus option neither errors nor gets stripped when micro rewrites the file — so a wrong key
  there is invisible dead config, and only a version check finds it. It matters because `one-dark`
  is a hex colorscheme like every non-`-tc` scheme micro ships: without the variable micro emits
  zero 24-bit sequences even under `COLORTERM=truecolor`, degrading the whole palette to 256-color
  approximations — exactly what stops it matching VS Code's `One Dark Pro`.

  Every variable in the unconditional section would in fact *work* from `setup-env` too — each is
  either guarded by `(( ! ${+VAR} ))` or read at runtime. It sits after the plugins because that is
  where upstream puts it: zsh-autosuggestions' README points Oh My Zsh users at "a file in the
  `$ZSH_CUSTOM` directory" for exactly these variables, and zsh-syntax-highlighting's docs write
  the highlighter list with `+=`, which presumes the plugin already ran. (you-should-use and zsh-z
  never mention placement.)

  That `+=` makes one line **positionally locked** rather than merely conveniently placed:
  `ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets)` is the upstream form and only works after the plugin
  loads. Run it earlier and the array goes from empty to `(brackets)`, so the plugin's closing
  `[[ $#ZSH_HIGHLIGHT_HIGHLIGHTERS -eq 0 ]] && …=(main)` never fires and `main` — the entire body
  of syntax highlighting — silently vanishes. Never move that line into `setup-env`; if it ever
  has to go there, switch it back to an explicit `=(main brackets)`.

  Both trees' `custom_env.sh` carry the same unconditional section verbatim — keep them in sync
  (`diff` the two files; with every debian flag off the two generated `00-setup_env.zsh` should
  `cmp` equal, which is the check worth running). They cannot be hoisted into one shared file:
  `container/dev-container/main.sh` builds with `../../debian` as the docker context, so anything
  outside `debian/` never reaches the image.

  **`01-first_run.zsh`** exists because the container path can never be interactive: the
  `Dockerfile` runs `debian/main.sh --unattended` under *bash*, and `.zshrc` is not sourced at
  build time at all. Anything needing a TTY — `gh auth login`'s device flow is the motivating case
  — has to be deferred to the first interactive shell, which is what powerlevel10k does with its
  own configuration wizard. `first_run.sh` captures `render_blocks()` into a variable first and
  writes the file in one `{ echo … } >` block only when that came out non-empty: the guard, the
  sentinel write, then the rendered blocks.

  ```zsh
  [[ ${SETUP_ENV_FIRST_RUN:-1} == 0 ]] && return

  {
      echo
      echo "# first run"
      echo "SETUP_ENV_FIRST_RUN=0"
  } >> "$ZSH_CUSTOM/00-setup_env.zsh"
  ```

  `00-setup_env.zsh` sorts before `01-first_run.zsh`, so on every later shell the sentinel is
  already set when the guard reads it, and the `return` — which exits only the sourced file, not
  omz's `for` loop at l.209 — skips everything below. **The sentinel is written before the blocks
  run, not after**: were it last, a hung or aborted prompt would keep it from landing and *every*
  new shell would re-prompt — five tmux panes, five `gh auth login`s. The cost is that a Ctrl-C'd
  step is not retried and the user runs it by hand. Each block still carries its own guard
  (`gh auth status` before `gh auth login`) so a shell that already has credentials, or a mounted
  `~/.config/gh`, is left alone.

  Re-running setup resets both `00-setup_env.zsh` and `01-first_run.zsh` (`custom_env.sh`'s and
  `first_run.sh`'s `main()` both use `>`), so the sentinel disappears and first-run fires once more
  with whatever component set the new flags produced. That is the intent, not a leak. Turning
  every first-run component *off* and re-running is the other half of it: the render comes out
  empty, so `first_run.sh` deletes the file rather than rewriting it, and nothing fires at all. One
  ordering worth knowing: the file is sourced at l.209 and the theme at l.214, so on a fresh
  machine the first-run prompts come *before* p10k's own configuration wizard.

  macos has no component needing an interactive first step, so its tree has no `first_run.sh` and
  no `01-first_run.zsh` — the same reasoning that leaves it without a `setup-env` plugin. It does
  have `custom_env.sh`: `00-setup_env.zsh` is needed on both trees, macos's copy just holds the
  unconditional section and no gated blocks.
- **`set -e` and trailing `[[ … ]] && cmd`.** A function whose *last* statement is a false
  conditional AND-list returns 1, and at the call site `set -e` takes that as a failure and exits
  — the guard inside the list only protects the `[[ … ]]` itself, not the function's exit status.
  `install_plugin()` ends on `[[ $COMMAND_MODERN_CLI == '1' ]] && append_plugin 'fzf-tab'`, so
  without a trailing `return 0` the entire default install path (`COMMAND_MODERN_CLI=0`) dies
  right there, taking `install_theme`, the three env scripts and `debian/main.sh` down with it.
  Hence the explicit `return 0`. It hides nothing: any genuine failure inside the function already
  exits the script at the failing command, never reaching the `return`. Prefer it to "make sure
  the last line happens to be unconditional", which the next edit quietly breaks. The same
  reasoning is why the gated blocks in `custom_env.sh` / `pre_plugin.sh` / `first_run.sh` are `if`
  blocks — an `if` whose condition is false still returns 0, so a trailing gated block cannot make
  `render_blocks()` return 1.
- **omz plugin selection (debian tree)** — vetted rejections, recorded so they don't get
  re-proposed. The governing criterion first: **a tool whose Debian package already ships
  `_<tool>` into `/usr/share/zsh/vendor-completions/` gets no omz plugin.** That directory is on
  the default `fpath`, so the completion is already live; the omz plugins for these tools exist to
  cover tarball / `go install` / conda installs that no packager touched, and they pay for it by
  running a generator on every shell start. Verified present on Debian 13 trixie: `_batcat`
  `_delta` `_dust` `_eza` `_fd` `_gh` `_procs` `_rg`. Whether a packager bothered is the only
  variable — it does not follow from how the tool was installed. The `_` in that criterion is
  load-bearing: tealdeer's `tldr.zsh` is in the same directory and is perfectly valid, yet never
  loads (see the `compinit` discussion above).
  - `gh` — `dpkg -S` confirms `_gh` comes from the `gh` package itself, and `app/git/main.sh`
    installs from the official apt repo. The plugin would regenerate the same thing asynchronously
    on every start.
  - `procs` — the plugin runs `procs --gen-completion-out zsh`, which Debian's 0.14.10 rejects
    (`error: unexpected argument '--gen-completion-out' found`), and it redirects with `>|`, so
    the failed run truncates the completion file to empty. `_procs` ships with the package anyway.
  - `bat` — no omz plugin exists, and none is wanted: `_batcat` ships with the package. The one
    `compdef bat=batcat` line the symlinked name needs is covered in the `compinit` discussion
    above.
  - `bat-extras` (`eth-p/bat-extras`, a third-party suite, not sharkdp's) — **not installed at
    all**, a tool rejection rather than a plugin one. No Debian package exists, so it would mean a
    `build.sh` install path this repo has no precedent for; 1.6k★ but semi-dormant (last commit
    2025-02-22, last release `v2024.08.24`); and four of its six scripts are dead weight here —
    only `batgrep` and `batpipe` would work, the rest needing man-db, entr or prettier, or
    overlapping delta from `--app-git`.
  - bat as the man pager (`export MANPAGER="bat -plman"`, which bat's README does recommend) —
    collides head-on with the unconditionally installed `colored-man-pages`, which wraps `man` with
    `PAGER=less` plus `LESS_TERMCAP_*`; `man` prefers `MANPAGER`, so setting it would leave the
    plugin a silent no-op. Moot anyway until something installs man-db.
  - `tldr` — binds exactly one key sequence: `Esc`, then `t`·`l`·`d`·`r`, rewriting the buffer to
    `tldr <first word>`. A four-character sequence never becomes muscle memory, and that widget is
    the plugin's *entire* content — it ships no completion, so it was never a candidate for the
    criterion above.
  - `debian` — 37 apt aliases, and it shadows `as` `ad` `au` `ai` `ap` `ac` `di` and other very
    short command names; it also prefers aptitude, which is not installed by default. `apt` is
    already short enough.
  - `node` — six lines total, whose only function `node-docs` opens a browser through
    `open_command` (xdg-open). Unusable headless or over ssh.
  - `npm` — node is installed as a runtime only (the `agent-inject` plugin that
    `--app-claude-copilot-api` installs runs on node); npm is never driven by hand.
  - `lazygit` `lazydocker` `btop` `duf`, and yazi — pure TUI or single-shot display; type the name
    and press enter. An omz plugin would add no useful shell integration at this layer.
  - `jq` `sd` `hyperfine` `choose` `glow` — no omz plugin exists; `jsontools`' functionality is
    fully covered by jq. `choose` ships no completion upstream, and `glow` has one usage worth
    completing (`glow <file>`).
  - `pip` — the tree installs uv.
  - `command-not-found` — on Debian this needs the `command-not-found` package plus the apt-file
    database, which is large. (macos keeps the plugin; there the handler is Homebrew's own.)
  - `history` — four `history | grep` aliases (`h` / `hl` / `hs` / `hsi`), covered by fzf's `^R`.
  - `zsh-completions` — 7.8k★ and active, but Debian already ships completions for nearly
    everything this tree installs; the overlap is high.
  - `zsh-autopair` — 626★, two years without a commit.
  - `forgit` — 5k★, but its `ga` / `gd` / `gco` aliases shadow the `git` plugin's, and it overlaps
    the already-installed lazygit.
  - `zsh-autocomplete` — 6.7k★, but its live completion menu conflicts head-on with fzf-tab and
    zsh-autosuggestions.
  - `fast-syntax-highlighting` — more accurate and faster, but its maintenance is less stable than
    zsh-syntax-highlighting's; not worth the swap.

  Two installed plugins need no configuration at all, checked so nobody goes looking for it: the
  `git` plugin's source has no tunable variable, and `zoxide`'s only one is `ZOXIDE_CMD_OVERRIDE`,
  whose default `z` is exactly what is wanted.
- **omz plugin selection (macos tree)** — vetted rejections, recorded so they don't get
  re-proposed:
  - `ssh-agent` — `_start_agent()` reuses an agent only when `~/.ssh/environment-$SHORT_HOST`
    already exists; otherwise it unconditionally runs `ssh-agent -s` and overwrites
    `SSH_AUTH_SOCK`, bypassing the launchd-managed agent and its Keychain integration, so
    passphrases saved via `UseKeychain yes` stop working. Use `AddKeysToAgent` / `UseKeychain`
    in `~/.ssh/config` instead.
  - `rsync` — since macOS 15.4 `/usr/bin/rsync` is openrsync, which accepts only a subset of
    GNU rsync's options; the plugin's `-avz --progress -h` aliases are not guaranteed to work.
  - `git` — the tree is a terminal client, not a dev machine; 197 aliases of dead weight.
  - `alias-finder` — superseded by `you-should-use`, which *is* installed (`brew` alone defines 36
    aliases and `macos` 19, and y-s-u's three `preexec` + one `precmd` hooks are pure-zsh
    assoc-array lookups that fork nothing). `alias-finder`'s manual mode is what y-s-u does
    automatically, and its `autoload` mode forks ~15 processes per command.
  - `copybuffer` — would take `^O` away from zsh's native `accept-line-and-down-history`.
    `copypath` / `copyfile` bind no keys and are kept.
