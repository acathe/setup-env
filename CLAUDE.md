# CLAUDE.md

Guidance for Claude Code when changing this repository. Keep this file focused on current architecture, executable workflows, ownership boundaries, and
failure modes that are not obvious from reading one script.

## Project shape

This repository is a collection of Bash provisioning scripts. There is no build step and no test suite. The public entry point is designed to be piped from
`curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup <macos|debian|container> [flags]
```

The root `main.sh` understands only `--branch` and `--setup`. It installs the selected platform's minimum Git prerequisite, derives a
`/tmp/setup_env.*` clone path with `mktemp -du`, shallow-clones the requested branch there, dispatches to `<setup>/main.sh`, and forwards every other
argument unchanged. It does not remove the clone afterwards. It is the one script with no `BASH_SOURCE` footer guard: a piped entry point must execute
unconditionally.

The setup trees are independent:

- `macos/` provisions a terminal client / jump box: Homebrew, Oh My Zsh, SSH support, and optional VS Code. It is deliberately not a development-machine
  profile and omits the Git plugin.
- `debian/` provisions the main development environment. Zsh and Oh My Zsh are unconditional; command, code, and app components are optional.
- `container/` dispatches to `dev-container`, `copilot-api`, or the one-shot `copilot-api-config` task.

`debian/vscode/` is reference data only. No dispatcher installs those files; `--app-vscode` enables the OMZ plugin, while `README.md` documents manual
extension installation. Its editor branch exists only with modern CLI and selects `code --wait` only when `TERM_PROGRAM=vscode`; otherwise the managed
editor remains micro. Invoke scripts through `bash` rather than executable bits.

## Checks and safe validation

Run the non-destructive checks from the repository root:

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

ShellCheck uses `-x` because `debian/app/docker.sh` dynamically sources `/etc/os-release`. `.shellcheckrc` disables `SC2016`; single-quoted `jq`, `sed`, and
generated-shell programs contain dollar signs that must not expand in the provisioning shell.

A direct dispatcher run performs real installation and configuration. For example, `bash debian/main.sh --app-tmux` runs `apt`, installs Oh My Zsh, and
modifies the current home. Do not use a normal account as a smoke-test sandbox.

Generated Zsh is embedded in Bash `echo` blocks and is invisible to ShellCheck. Render `setup-env.plugin.zsh.sh`, `00-setup_env.zsh.sh`, and
`01-first_run.zsh.sh` in a clean environment with `HOME` and `ZSH_CUSTOM` explicitly pointing into one throwaway tree and a controlled `PATH`; changing
`HOME` alone is insufficient because the writers honor inherited `ZSH_CUSTOM`. Then run `zsh -n` on their outputs. Seed `$HOME/.zshrc` from the Oh My Zsh
template and put a stub `git` on
`PATH`. On Linux when testing macOS, also provide a BSD-`sed` shim and a stub `brew`, because the theme installer invokes both. Set component variables
inside the same harness; for a broad Debian render, use `COMMAND_MODERN_CLI=1 CODE_PYTHON=1 APP_GIT=1 APP_YAZI=1 bash debian/command/omz_custom/main.sh`.

For fzf changes, run `FZF_DEFAULT_OPTS_FILE=debian/command/modern_cli/fzf/fzfrc FZF_DEFAULT_OPTS= fzf --version`.
Then inspect `${(z)FZF_CTRL_T_OPTS}` and `${(z)FZF_ALT_C_OPTS}` in `zsh -f`. Plugin-order changes require a real ZLE / PTY smoke test:
ordinary Tab and `**<Tab>` must each open fzf once; `fzf_default_completion` must be `fzf-tab-complete`; Ctrl-T and Alt-C must remain single calls.

## Dispatcher contract

Platform roots and true nested dispatchers follow this data flow:

1. Initialize every owned flag with an override-friendly default. Export only values read by descendant scripts, such as
   `export APP_GIT="${APP_GIT:-0}"`.
2. `parse_args()` consumes flags it owns and appends unknown arguments to `POSITIONAL`.
3. Boolean flags shift once. Value flags use the `numOfArgs` guard so a missing value cannot read an unset `$2` under `set -u`.
4. Restore the forwarded arguments and call `main()`.
5. Run components in `--command-*`, `--code-*`, then `--app-*` order, alphabetically inside each group.

For a normal runnable component, the export block, parser cases, `main()` gates, and corresponding `README.md` table are four ordered views of the same
interface. Debian `APP_VSCODE` is the explicit integration-only exception: it has an export, parser case, and README flag but no Debian leaf or `main()`
gate. OMZ uses it for the plugin and, only inside the modern-CLI editor block with runtime `TERM_PROGRAM=vscode`, for `code --wait`. Do not invent an empty
gate to force symmetry.

A multi-part runnable concern owns a directory. `app/claude/main.sh` is a nested dispatcher because it owns child arguments; `command/modern_cli/main.sh` is
an aggregate leaf with no parser.

Flags intentionally cascade through exported variables and forwarded arguments. The Claude app reads `CODE_GO`, `CODE_PYTHON`, `CODE_RUST`, and `APP_GIT`
from Debian; tmux reads `APP_CLAUDE`; Yazi reads `COMMAND_MODERN_CLI` and `CODE_MARKDOWN`. OMZ writers read component flags because they physically own
shared shell landing points. Cross-component reads are valid when they add integration only if both concerns are enabled.

An argument-owning dispatcher or leaf uses the full sourceable footer:

```bash
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}"
    main "$@"
fi
```

A leaf with no arguments has no parser or `POSITIONAL` layer:

```bash
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
```

The piped root entry point and macOS retain the Bash 3.2-safe empty-array restoration form:

```bash
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"
```

Do not normalize it to Debian's `"${POSITIONAL[@]}"`; Bash 3.2 plus `set -u` can reject an empty array expansion. Match the owning dispatcher's existing
idiom.

When adding a component, synchronize every applicable export, parser, gate, and README entry; list all readers for an integration-only flag and choose the
matching footer. The component owns installation and non-shell config, while shared shell output goes through the appropriate OMZ writer. Never append
directly to a shared generated shell file.

## Configuration ownership and landing points

Each shared configuration fragment has one logical owner, but `.zshrc` has coordinated writers. Each setup tree's `command/omz.sh` installs Oh My Zsh and
prepares its template; Debian's also activates the template's user-bin PATH. `command/omz_custom/main.sh` owns the plugin array, clones, and theme. After
writing a non-empty `setup-env` plugin, `setup-env.plugin.zsh.sh` prepends the coupled array entry only afterwards, avoiding an enabled-but-missing warning
at shell startup.

| Configuration needed by | Owned destination |
| --- | --- |
| `compinit`, Oh My Zsh libraries, plugin list, theme | `.zshrc` |
| another plugin while it is being sourced | `$ZSH_CUSTOM/plugins/setup-env/setup-env.plugin.zsh` |
| aliases, functions, `compdef`, runtime variables | `$ZSH_CUSTOM/00-setup_env.zsh` |
| a deferred interactive login or wizard | `$ZSH_CUSTOM/01-first_run.zsh` |
| non-interactive shell commands | `.zshenv` |

The decision is based on when a value is read, not whether it looks like an environment variable. The `setup-env` plugin carries eza load-time zstyles, fzf
bootstrap variables, and `PYTHON_AUTO_VRUN`; moving those to `00-setup_env.zsh` is silently too late. Conversely, `ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets)`
must remain after the syntax-highlighting plugin; moving it early prevents that plugin from installing its `main` highlighter.

Provisioning-managed runtime tool configuration is shipped as an artifact and installed with `install -Dm 644`, not generated with `echo`. This includes
Atuin, bat, fzf, micro, lazygit, and Yazi's `init.lua` and `keymap.toml`; repo-local lint config and undeployed VS Code reference data are outside this rule.
The copilot-api settings template is a shipped JSON artifact completed by `jq`, written directly with directory mode 700 and file mode 600. The external
exception is the Ruff baseline downloaded from BesLogic's `main` branch by `code/python.sh`. Yazi's `yazi.toml` is the generated exception:
`app/yazi/yazi.toml.sh` creates its target directory and redirects the complete `echo` render into the target because previewers depend on component flags.
Otherwise, `echo` is reserved for files invented here and appends to upstream-owned files; global Git configuration uses `git config`.

A rerun overwrites managed static configs. When Yazi runs, it also fully rerenders `yazi.toml`, so disabling an integration flag retracts that previewer.
Yazi's `package.toml` is different: `ya pkg add` owns that mutable runtime manifest, so the repository never ships, overwrites, or garbage-collects it. Only
configure values that materially differ from packaged defaults.

### Empty renders do not retract prior output

`setup-env.plugin.zsh.sh` and `01-first_run.zsh.sh` capture `render_blocks()` before touching a target. An empty render returns successfully without
writing or deleting. On a fresh home this creates no artifact; on a repeated setup it leaves an earlier artifact byte-for-byte unchanged. This is an
intentional provisioning contract: disabling a flag is not uninstall or garbage collection.

A stale `setup-env.plugin.zsh` is inert after `install_plugin()` rebuilds the array from `plugins=(aliases)` without adding `setup-env`. A stale
`01-first_run.zsh` is not inert: it remains matched by Oh My Zsh's custom `*.zsh` glob. Because `00-setup_env.zsh.sh` rebuilds `00-setup_env.zsh`, the
previous sentinel disappears and the old first-run file can execute again. Its GitHub block still checks for `gh` and existing authentication, but
turning off `APP_GIT` does not remove the file. Delete `$ZSH_CUSTOM/01-first_run.zsh` explicitly when retiring that step. Do not add automatic deletion
unless the non-retraction contract is deliberately changed.

`00-setup_env.zsh.sh` always has an unconditional section and rebuilds `00-setup_env.zsh`. `01-first_run.zsh.sh` appends its sentinel there before
launching interactive work, so a canceled prompt is not retried in every new shell. A later setup with a non-empty first-run render rewrites both files and
permits the new sequence once again.

## Oh My Zsh load and plugin order

Oh My Zsh initializes completion and libraries before plugins, sources plugins in `plugins=()` order, then sources `$ZSH_CUSTOM/*.zsh` alphabetically, and
loads the theme last. Preserve these constraints:

- When generated, `setup-env` is prepended and remains the first plugin.
- `zsh-syntax-highlighting` remains last.
- `fzf-tab` precedes wrappers such as `zsh-autosuggestions` and syntax highlighting.
- In this repository, `fzf-tab` also precedes `fzf`. fzf captures the current Tab binding as `fzf_default_completion`; reversing them nests two fzf
  completion interfaces.
- Third-party cloned plugins load after `ohmyzsh-full-autoupdate`, whose update is synchronous.
- On macOS, `brew` precedes `command-not-found`, whose Homebrew handler expects `brew` on `PATH`.

Atuin is a deliberate post-plugin exception. It initializes from `00-setup_env.zsh` so it can take Ctrl-R and Up after fzf loads; the packaged Zsh and
syntax-highlighting combination still highlights widgets added at that point. Do not move it early to follow a generic ordering rule.

Optional plugins are gated on the component providing their command. With modern CLI enabled, use Oh My Zsh's `zoxide` plugin and omit `z`; without it, use
`z` and emit zsh-z settings. Prefer Debian vendor completions over plugins that regenerate completion on every shell start.

Do not remove a plugin name with `\<z\>`. A hyphen is not a word character, so that pattern can match the tail of `fancy-ctrl-z`, consume a separator, and
fuse two names. If removal is required, delimit with spaces and parentheses. Use BSD `sed -i ''` on macOS and GNU `sed -i` on Debian.

## Bash and generated-content conventions

Every script starts with `#!/usr/bin/env bash` and `set -euo pipefail`.

Use single quotes for literals and double quotes only when the shell must expand a dollar sign, command substitution, or escape. Defaults inside
`${VAR:-default}` are bare because the enclosing double quotes already protect the expansion:

```bash
BRANCH="${BRANCH:-master}"       # correct
# BRANCH="${BRANCH:-'master'}"   # expands to the literal quotes
```

Generated shell content follows a second quoting layer: the provisioning Bash `echo` is single-quoted, while quotes needed by generated Zsh are double
quotes inside that literal. This prevents setup-time expansion of `$PATH`, `$HOME`, `$EDITOR`, and fzf placeholders.

```bash
echo 'export PATH="$PATH:/usr/local/go/bin"'
echo 'alias tree="eza --tree"'
```

Do not flip the outer quotes to double quotes. fzf preview strings intentionally contain escaped inner quotes; flattening either layer changes option
tokenization. Preserve `-- {}` so a candidate beginning with `-` is not parsed as an option. `echo "$blocks"` only replays captured text; parameter
expansion does not rescan dollar signs inside the value.

Use arrays for constructed argument lists and quote `"$@"`. Paths, URLs, and filenames are quoted; command names and the repository's established bare
option values remain bare.

A false `[[ ... ]] && command` used as a function's final statement makes the function return 1. Under `set -e`, a normal call then aborts the script. Any
function that could end in an optional AND-list must use an `if` block or explicit `return 0`; never make success depend on whichever call currently happens
to be last.

In-place `sed` edits target known upstream markers. `sed` exits successfully when no line matches, so an upstream template change can turn the edit into a
silent no-op. Verify the marker before editing and inspect or assert the resulting file. Likewise, guard a symlink source before `ln -sf`: a missing source
still produces a successful command and a dangling link.

GitHub release assets use `releases/latest/download/<asset>`. An unversioned asset uses one literal URL; a versioned filename resolves `releases/latest`
only to construct that name, rejects an empty result, and still downloads through `latest/download`. `latest` is not a pin and its two-request form can race
to a loud 404. copilot-api is the exception because the version is a Git ref and image tag rather than an asset URL.

Use `command -v` guards before optional tools. A network failure is fatal unless the operation is explicitly a cache warm-up; `tldr --update || true` is
intentionally non-fatal.

## Completion and configuration traps

`compinit` discovers files named `_*`, then registers the command declared by the file's first `#compdef`; the executable name and symlink filename do not
change that declaration.

| Command | Packaged completion | Required action |
| --- | --- | --- |
| `bat` | `_batcat` declares `batcat` | link the binary; run `compdef bat=batcat` after `compinit` |
| `fd` | `_fd` declares `fd` | link `fd` to `fdfind`; no `compdef` |
| `tldr` | `tldr.zsh` declares `tldr` | link it as `$ZSH_CUSTOM/completions/_tldr` |
| `yazi`, `ya` | release zip provides `_yazi`, `_ya` | install under custom completions unchanged |

Prefer executable symlinks over aliases for renamed binaries; child shells, fzf previews, `command -v`, and Zsh's `$commands` see `PATH`, not aliases. Oh My
Zsh's template adds `~/.local/bin` in `.zshrc`, which is sufficient for interactive plugin probes but not non-interactive `zsh -c`; language components
needing non-interactive paths write `.zshenv`.

Validate config semantics against the packaged tool, not current upstream master. Lazygit and micro silently ignore unknown keys, so syntax validation
cannot detect dead configuration. Before adding a lazygit key, inspect that packaged version's migration list: a migratable key makes lazygit rewrite the
managed file. Keep `gui.nerdFontsVersion: "3"` as a string, lazygit's pager at `delta --paging=never`, and `MICRO_TRUECOLOR=1` in shell configuration rather
than inventing a micro setting. Unknown bat or fzf options instead make every invocation fail; parse those configs with installed binaries. `BAT_THEME`
would override the managed bat config, so do not set both.

Plugin or theme additions need an official or actively maintained source, and defaults should come from official setup or usage guidance. Do not infer that
every tool needs a One Dark override from the tools that have one.

## Debian modern CLI

`command/modern_cli/main.sh` bulk-installs shared tools, then runs the fixed children: Atuin, bat, choose, fd, fzf, micro, and tldr. Children own packages,
binary links, completions, and static config; none has an independent flag.

Atuin uses Debian's package/completion and a two-setting config. Setup does not import history or configure account/sync. Its late init takes Ctrl-R and Up
while fzf retains Ctrl-T, Alt-C, and `**` completion.

fzf bootstrap and runtime settings stay split. Before plugin load, `setup-env.plugin.zsh.sh` exports the opts-file path plus `FZF_DEFAULT_COMMAND`,
`FZF_CTRL_T_COMMAND`, and `FZF_ALT_C_COMMAND` separately: fzf does not reuse the default for widgets, and its generated Zsh uses empty values to decide
whether Ctrl-T / Alt-C exist. `00-setup_env.zsh.sh` later adds bat/eza previews. `fzfrc` contains only reverse layout, border, and cycle because fzf-tab can
still see it—do not add global preview, popup/tmux mode, or fixed height. The fzf-tab block uses the five-field `:completion:*:*:*:*:*` pattern to outrank
Oh My Zsh's menu default, restore colors, preserve Git checkout ordering, and bind group navigation. The Bat child owns its managed config and canonical
link;
fd owns its link, eza aliases come from early zstyles, and zoxide initializes exactly once through its OMZ plugin.

Micro true color remains `MICRO_TRUECOLOR=1`; tealdeer owns the guarded completion symlink and a non-fatal cache warm-up; choose installs the unversioned
latest asset. Glow has no managed config and is installed by the Markdown code component; zoxide owns no static config or second init.

## Yazi application

`--app-yazi` uses the unversioned GNU release zip, installs `file` and `unzip`, then installs its binaries/completions. Git fetchers and the Git/keymap
plugins are unconditional. With modern CLI enabled, the app adds the two Bat previewers and official `piper`; with Markdown enabled, it adds the Glow
previewer and third-party `alberti42/faster-piper`. That plugin exposes `$w` and `$h` but not `$t`, so the runner uses its documented `dracula` style and
preserves `-- "$1"`. Command and code components run first, so each conditional preview command is already available.

After plugin installation, `main.sh` runs `yazi.toml.sh`; that script creates the Yazi config directory and directly writes the complete `yazi.toml` render.
`init.lua` and `keymap.toml` remain shipped artifacts. Each plugin has its own `ya pkg add` invocation, so a partial failure cannot install config that
references a missing plugin.
A later run may leave disabled plugins in the mutable `package.toml`, but the regenerated config no longer references them. The `y()` wrapper remains in
`00-setup_env.zsh.sh`, the sole writer of `00-setup_env.zsh`, and is emitted only when `APP_YAZI=1`.

## Git application

`--app-git` owns the complete Git concern: GitHub CLI repository setup, `gh`, delta, lazygit, global Git settings, lazygit config, the `lg()` cwd-following
function, and deferred `gh auth login`. Physical writers still follow the shared ownership rules: the Git leaf writes tool and Git config,
`00-setup_env.zsh.sh` writes `lg()`, and `01-first_run.zsh.sh` writes the login block. Do not split delta or lazygit into modern CLI.

The lazygit config targets the packaged schema. It keeps Nerd Fonts version `"3"` and narrows the side panel for side-by-side delta. It explicitly uses
`delta --paging=never`; global `core.pager=delta` is not inherited by lazygit. The `lg()` function uses `LAZYGIT_NEW_DIR_FILE` to move the parent shell
to lazygit's exit directory.

GitHub login is deferred because unattended container builds have no interactive Zsh startup. The block checks both command availability and current auth
status before invoking `gh auth login`.

## Claude Code and copilot-api

`debian/app/claude/main.sh` installs Claude Code from the official installer. If `--app-claude-copilot-api` is enabled, it runs that child first because the
child replaces `~/.claude/settings.json`; common plugin installation happens afterwards so `enabledPlugins` is not erased.

The common official plugins are `claude-code-setup`, `claude-md-management`, `claude-security`, and `hookify`; `APP_GIT` adds `commit-commands`. Language
integrations stay paired with their servers: Go installs latest `gopls` plus `gopls-lsp`, Python installs isolated `pyright[nodejs]` plus `pyright-lsp`, and
Rust installs rust-analyzer plus `rust-analyzer-lsp`. Language components run earlier and own their toolchains.

The script explicitly adds the official marketplace before first interactive launch. Afterwards, `jq` removes only
`extraKnownMarketplaces["claude-plugins-official"]` and removes the parent object only if empty. Preserve `enabledPlugins`, custom/copilot marketplaces, and
separate registry state. Never replace this cleanup with `claude plugin marketplace remove`, which uninstalls plugins.

The copilot-api child writes the three model values into settings as supplied without querying `/v1/models` or validating availability. The model values
default to empty; the base URL defaults to `http://localhost:4141`, and the intentionally non-secret token defaults to `dummy`.

`install_settings()` merges the final `ANTHROPIC_*` values into the shipped template and writes `~/.claude/settings.json` with directory mode 700 and file
mode 600. Treat that template as the source of truth for sandbox, permission, language, notification, and workflow preferences rather than copying each
value here. For model IDs carrying the `[1m]` suffix, keep `CLAUDE_CODE_AUTO_COMPACT_WINDOW` unset: the suffix selects extended context, while Claude Code
retains control of its output and compaction reserves.

The copilot marketplace installs `agent-inject` and `tool-search`. Keep native `ENABLE_TOOL_SEARCH` unset because withholding full tool definitions breaks
the gateway's deferred tool bridge. Both plugins need Node/npm/npx. Bootstrap NodeSource LTS only when `node` is absent; an existing incompatible runtime is
left for plugin installation to report. Node is private to this integration, not a standalone Debian component.

## Container flows

`container/dev-container/main.sh` NUL-encodes forwarded Debian flags, base64-encodes that byte stream, and passes it as `setup_args_b64`. The Dockerfile
read-only bind-mounts the Debian build context, decodes the array with `mapfile -d ''`, and runs:

```bash
bash /mnt/setup/main.sh --unattended "${setup_args[@]}"
```

The build context is `debian/`, so image setup cannot consume files hoisted outside that tree. Unattended mode installs Oh My Zsh without launching it and
changes the login shell; the launcher mounts host `~/Projects` into a privileged persistent container.

`container/copilot-api/main.sh` resolves the latest release to obtain a Git ref and image tag, builds from that ref, optionally runs interactive
authentication through `/dev/tty`, then replaces the named service container, publishes port 4141, and mounts host `~/.copilot-api` as service state.

`container/copilot-api-config` is a one-shot image containing `jq` and `openssl`. It mounts the same host directory at `/root/.copilot-api`, so it mutates
the service's persistent `config.json` despite the different in-container path. `--reset-api-key` clears `auth.apiKeys` first; `--api-keys <N>` then appends
N independently generated 32-byte hex keys. The task assumes the service has already produced a valid `config.json`.

## macOS-specific constraints

The macOS tree has no `setup-env.plugin.zsh.sh` or `01-first_run.zsh.sh`; it has no load-time settings or deferred interactive component. Its
`00-setup_env.zsh.sh` contains the same unconditional block as Debian with all flags off. Keep those blocks byte-equivalent, but do not hoist them outside
each tree because the Debian-only Docker build context cannot see a shared root file.

`macos/main.sh` evaluates `/opt/homebrew/bin/brew shellenv` in the provisioning Bash process so child installers can find Homebrew; interactive discovery
later comes from the Oh My Zsh `brew` plugin. The absolute prefix is a current hard requirement—strict mode aborts before child installers if Homebrew is
elsewhere, so any prefix generalization must update this call explicitly.

## Change checklist

Before finishing a change:

- Confirm the correct dispatcher owns every new flag; distinguish runnable components from integration-only flags and keep applicable interface lists
  ordered.
- Confirm each configuration fragment has one logical owner and place shell settings by read time.
- Check behavior on a fresh home and a repeated home with relevant flags disabled.
- Preserve first-run non-retraction unless changing it intentionally and documenting cleanup.
- Validate shipped config against the packaged tool, including keys parsers may silently ignore.
- Run Bash syntax, ShellCheck, shfmt, and staged/unstaged whitespace checks.
- Render generated Zsh and run `zsh -n`; use a real ZLE smoke test for plugin-order or fzf changes.
- Do not run an installer smoke test on the host merely to prove dispatch; these scripts perform real package installation and modify the home directory.
