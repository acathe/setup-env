# CLAUDE.md

Guidance for Claude Code when changing this repository. Keep this file focused on current architecture, executable workflows, ownership boundaries, and
failure modes that are not obvious from reading one script.

## Project shape

This repository is a collection of Bash provisioning scripts. There is no repository-wide build target or automated test suite; container flows build
Docker images as part of provisioning. The public entry point is designed to be piped from `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup <macos|debian|container> [flags]
```

The root `main.sh` understands only `--branch` and `--setup`. It installs the selected platform's minimum Git prerequisite, derives a
`/tmp/setup_env.*` clone path with `mktemp -du`, shallow-clones the requested branch there, dispatches to `<setup>/main.sh`, and forwards every other
argument unchanged. It does not remove the clone afterwards. It is the one script with no `BASH_SOURCE` footer guard: a piped entry point must execute
unconditionally. `README.md` currently omits the root-only `--branch` option from its platform invocation tables; the root parser remains the source of
truth for that option.

The setup trees have separate dispatchers, but are not fully independent: `container/dev-container` consumes `debian/` as its Docker build context.

- `macos/` provisions a terminal client / jump box: Homebrew, Oh My Zsh, SSH support, and optional VS Code. It is deliberately not a development-machine
  profile, omits the Git plugin, and has no classic CLI component.
- `debian/` provisions the main development environment. Zsh, Oh My Zsh, and the classic CLI baseline are unconditional; the classic layer installs no tools
  and only manages configuration for platform-provided less and Nano. Remaining command, code, and app components are optional.
- `container/` dispatches to `dev-container`, `copilot-api`, or the one-shot `copilot-api-config` task.

`debian/vscode/` is reference data only. No dispatcher installs those files; `--app-vscode` enables the OMZ plugin, while `README.md` documents manual
extension installation. Debian's `00-setup_env.zsh.sh` selects `nano -/` without modern CLI and Micro with modern CLI; when `--app-vscode` is enabled, the
same writer adds a runtime `TERM_PROGRAM=vscode` override to `code --wait`. It does not emit `VISUAL`. Invoke scripts through `bash` rather than executable
bits.

Root `main.sh` and `macos/` must remain compatible with Apple's Bash 3.2; Debian and container code may use newer Bash. Debian components that download Go
or protoc assets currently select `amd64`/`x86_64`; do not claim arm64 support without updating both.

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

ShellCheck uses `-x` because `debian/app/docker.sh` dynamically sources `/etc/os-release`. `.shellcheckrc` disables `SC2016`; literal `jq`/`sed` programs
and generated shell content intentionally preserve dollar signs for a later interpreter.

A direct dispatcher run performs real installation and configuration. For example, `bash debian/main.sh --app-tmux` runs `apt`, installs Oh My Zsh, and
modifies the current home. Do not use a normal account as a smoke-test sandbox. Debian's OMZ installer also removes existing `.profile`, `.bashrc`, and
`.bash_logout`. Generated-file repeated-home checks do not imply that full platform dispatchers are idempotent; OMZ plugin and theme installers clone into
fixed destinations.

The managed OMZ Zsh files are emitted from quoted Bash heredocs and are invisible to ShellCheck. Render `setup-env.plugin.zsh.sh`, `00-setup_env.zsh.sh`,
and `99-first_run.zsh.sh` in a clean environment with `HOME` and `ZSH_CUSTOM` explicitly pointing into one throwaway tree and a controlled `PATH`; changing
`HOME` alone is insufficient because the writers honor inherited `ZSH_CUSTOM`. Then run `zsh -n` on their outputs. Seed `$HOME/.zshrc` from the Oh My Zsh
template and put a stub `git` on `PATH`. On Linux when testing macOS, also provide a BSD-`sed` shim and a stub `brew`, because the theme installer invokes
both. Set and export component variables inside the same harness, including `APP_VSCODE`: Debian's `00-setup_env.zsh.sh` reads it without a local default and
writes directly to its target, so omitting it aborts under `set -u` after leaving partial output. Invoke `plugin.sh` and `theme.sh` from the platform's
`command/omz/` directory before running the writers through `command/omz_custom/main.sh`. Do not invoke `command/omz/main.sh` for a render check: the
installer entry point performs real setup and, on Debian, runs `apt`.

For fzf shell changes, inspect `${(z)FZF_CTRL_T_OPTS}` and `${(z)FZF_ALT_C_OPTS}` in `zsh -f`. Plugin-order changes require a real ZLE / PTY
smoke test: ordinary Tab and `**<Tab>` must each open fzf once; `fzf_default_completion` must be `fzf-tab-complete`; Ctrl-T and Alt-C must remain single calls.

## Dispatcher contract

Platform roots and true nested dispatchers follow this data flow:

1. Initialize every owned flag with an override-friendly default. Export values read by descendant scripts, such as
   `export APP_GIT="${APP_GIT:-0}"`. Debian currently also exports `CODE_BASH`, `CODE_PROTOBUF`, and `APP_NEOVIM` even though only its root reads them; these
   are redundant exceptions, not cross-component contracts.
2. `parse_args()` consumes flags it owns and appends unknown arguments to `POSITIONAL`.
3. Boolean flags shift once. Value flags use the `numOfArgs` guard so a missing value cannot read an unset `$2` under `set -u`.
4. Restore the forwarded arguments and call `main()`.
5. Preserve the explicit dependency order of unconditional bootstrap components. Run optional flag-gated components in `--command-*`, `--code-*`, then
   `--app-*` order, alphabetically within each group.
6. Each optional component installs or guards every executable it requires. Do not make one optional flag depend on another except for an explicitly
   documented integration.

For a normal runnable component, the export block, parser cases, `main()` gates, and corresponding `README.md` table are four ordered views of the same
interface. Debian `APP_VSCODE` is the explicit integration-only exception: it has an export, parser case, and README flag but no Debian leaf or `main()`
gate. OMZ uses it for the plugin and for the `TERM_PROGRAM=vscode` editor branch in `00-setup_env.zsh.sh`. Do not invent an empty gate to force symmetry.

A multi-part runnable concern owns a directory. `app/claude/main.sh` is a nested dispatcher because it owns child arguments.
Both CLI entry points are no-parser leaves: `command/classic_cli/main.sh` owns only unconditional configuration for platform-provided CLI tools, while
`command/modern_cli/main.sh` aggregates optional tools and fixed child installers.

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

Each shared configuration fragment has one logical owner, but `.zshrc` has coordinated writers. Each setup tree's `command/omz/main.sh` installs Oh My Zsh,
prepares its template, then orchestrates `plugin.sh` and `theme.sh`; Debian's installer also activates the template's user-bin PATH. `plugin.sh` owns the
plugin array and clones, while `theme.sh` owns the theme. `command/omz_custom/main.sh` only orchestrates the writers. After writing a non-empty `setup-env`
plugin, `setup-env.plugin.zsh.sh` prepends the coupled array entry only afterwards, avoiding an enabled-but-missing warning
at shell startup.

| Configuration needed by | Owned destination |
| --- | --- |
| `compinit`, Oh My Zsh libraries, plugin list, theme | `.zshrc` |
| another plugin while it is being sourced | `$ZSH_CUSTOM/plugins/setup-env/setup-env.plugin.zsh` |
| aliases, functions, `compdef`, runtime variables, editor selection | `$ZSH_CUSTOM/00-setup_env.zsh` |
| a deferred interactive login or wizard | `$ZSH_CUSTOM/99-first_run.zsh` |
| non-interactive shell commands | `.zshenv` |

The decision is based on when a value is read, not whether it looks like an environment variable. The `setup-env` plugin carries eza load-time zstyles and
`PYTHON_AUTO_VRUN`; moving those to `00-setup_env.zsh` is silently too late. Conversely, `ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets)` must remain after the
syntax-highlighting plugin; moving it early prevents that plugin from installing its `main` highlighter.

Provisioning-managed runtime tool configuration is shipped as an artifact rather than rendered by the provisioning shell. Most writers use
`install -m 644`, plus `-D` when the parent directory must be created. This includes bat, Glow, less, micro, Nano, lazygit, and Yazi's `init.lua` and
`keymap.toml`; repo-local lint config and undeployed VS Code reference data are outside this rule.
The copilot-api settings template is a shipped JSON artifact completed by `jq`, written directly with directory mode 700 and file mode 600. The external
exception is the Ruff baseline downloaded from BesLogic's `main` branch by `code/python.sh`. Yazi's `yazi.toml` is the generated exception:
`app/yazi/yazi.toml.sh` creates its target directory and replaces the target from one complete render because previewers depend on component flags. Generated
files invented here are complete renders; append only to upstream-owned files, while global Git configuration uses `git config`.

A rerun overwrites managed static configs that still have writers. Removing a shipped artifact does not delete a copy installed by an earlier revision;
cleanup must be explicit. When execution reaches `yazi.toml.sh`, it fully rerenders `yazi.toml`, so the completed render reflects the current integration
flags.
Yazi's `package.toml` is different: `ya pkg add` owns that mutable runtime manifest, so the repository never ships, overwrites, or garbage-collects it. Only
configure values that materially differ from packaged defaults. `ya pkg add` rejects an already-listed dependency. It identifies sources by full
`owner/repository` but deploys by plugin name, so replacing an owner for the same plugin requires `ya pkg delete` for the old source before adding the new
one; never edit `package.toml` directly.

### Empty renders do not retract prior output

`setup-env.plugin.zsh.sh` and `99-first_run.zsh.sh` capture `render_blocks()` before touching their current targets. An empty render returns successfully
without writing or deleting the current target. On a fresh home this creates no artifact; on a repeated setup it leaves an earlier artifact byte-for-byte
unchanged. This is an intentional provisioning contract: disabling a flag is not uninstall or garbage collection.

Renaming the writer does not remove an installed `$ZSH_CUSTOM/01-first_run.zsh` from an earlier revision. That retired file remains matched by Oh My Zsh's
custom `*.zsh` glob and can run alongside `99-first_run.zsh`. Remove it explicitly when migrating an existing home; do not assume a current writer
garbage-collects a retired target.

A stale `setup-env.plugin.zsh` is inert after Debian's OMZ `plugin.sh` rebuilds the array from `plugins=(aliases)` without adding `setup-env`. A pending
`99-first_run.zsh` is not inert: turning off `APP_GIT` before it has been sourced leaves it matched by Oh My Zsh's custom `*.zsh` glob. When sourced, it
removes itself before checking commands or launching interactive work, so a failed or canceled prompt is not retried in every new shell. A later setup with
a non-empty first-run render recreates the file and permits the new sequence once again.

`00-setup_env.zsh.sh` always has an unconditional section and rebuilds `00-setup_env.zsh`; the first-run file neither reads nor modifies it.

## Oh My Zsh load and plugin order

Oh My Zsh initializes completion and libraries before plugins, sources plugins in `plugins=()` order, then sources `$ZSH_CUSTOM/*.zsh` alphabetically, and
loads the theme last. Preserve these constraints:

- When generated, `setup-env` is prepended and remains the first plugin.
- When generated, `99-first_run.zsh` remains the last provisioning-managed custom Zsh file so deferred interactive work starts after managed runtime
  configuration.
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

Shared generated shell files follow a second quoting layer: provisioning Bash uses a quoted heredoc delimiter (`cat << 'EOF'`), while quotes and escapes in
the body belong to generated Zsh. The quoted delimiter prevents setup-time expansion of `$PATH`, `$HOME`, `$EDITOR`, and fzf placeholders.

```bash
cat << 'EOF'
export PATH="$PATH:/usr/local/go/bin"
alias tree="eza --tree"
EOF
```

Do not unquote the heredoc delimiter. fzf preview strings intentionally contain escaped inner quotes; flattening either layer changes option tokenization.
Preserve `-- {}` so a candidate beginning with `-` is not parsed as an option. Captured block output uses `printf '%s\n' "$blocks"`; parameter expansion
does not rescan dollar signs inside the value. For literal lines appended to upstream-owned shell files such as `.zshenv`, a single-quoted `echo` argument
remains correct; do not introduce setup-time expansion.

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

Prefer executable symlinks over aliases for renamed binaries; child shells, fzf previews, `command -v`, and Zsh's `$commands` see `PATH`, not aliases. Oh My
Zsh's template adds `~/.local/bin` in `.zshrc`, which is sufficient for interactive plugin probes but not non-interactive `zsh -c`; language components
needing non-interactive paths write `.zshenv`.

Validate config semantics against the packaged tool, not current upstream master. Lazygit and micro silently ignore unknown keys, so syntax validation
cannot detect dead configuration. Before adding a lazygit key, inspect that packaged version's migration list: a migratable key makes lazygit rewrite the
managed file. Keep `gui.nerdFontsVersion: "3"` as a string, lazygit's pager at `delta --paging=never`, and `MICRO_TRUECOLOR=1` in shell configuration rather
than inventing a micro setting. Unknown bat or fzf options instead make every invocation fail; parse those configs with installed binaries. `BAT_THEME`
would override the managed bat config, so do not set both.

Debian's managed Nano config relies on the system nanorc to load packaged syntax definitions; do not add duplicate include globs. Its options target Nano
5.3 or newer and avoid settings that alter file contents or conflict with terminal selection. The classic CLI copies the artifact but does not install Nano.
Debian selects `nano -/` only without modern CLI; modern CLI selects Micro instead. macOS has no managed Nano artifact and never selects Nano.

Plugin or theme additions need an official or actively maintained source, and defaults should come from official setup or usage guidance. Do not infer that
every tool needs a One Dark override from the tools that have one.

## Classic CLI

Only Debian runs `command/classic_cli/main.sh`, unconditionally after its OMZ custom writers. It installs no packages and only copies the shipped `lesskey`
and `nanorc` artifacts to `$HOME/.config/lesskey` and `$HOME/.config/nano/nanorc` with `install -Dm 644`; less and Nano come from the platform baseline.
macOS has no classic CLI component.

## Debian modern CLI

`command/modern_cli/main.sh` is an optional aggregate leaf. It bulk-installs user-facing modern tools, including `jq`, `unzip`, Atuin, and fzf, then runs the
fixed children for bat, fd, Micro, and tealdeer. Children own package-specific links, completions, and static configuration; none has an independent flag.
`man-db` is a platform baseline: a full Debian host is expected to provide it, while `container/dev-container/Dockerfile` installs it
explicitly.

Atuin is bulk-installed from Debian and has no repository-owned config. Fresh homes use packaged defaults, but a `~/.config/atuin/config.toml` installed by
an older revision remains until explicitly deleted. Setup does not import history or configure account/sync. Its late init takes Ctrl-R and Up while fzf
retains Ctrl-T, Alt-C, and `**` completion.

fzf uses packaged shell-integration defaults and has no repository-owned static config. The `setup-env` plugin does not define fzf bootstrap variables.
After plugin load, `00-setup_env.zsh.sh` derives `FZF_CTRL_T_COMMAND` and `FZF_ALT_C_COMMAND` from the current `FZF_DEFAULT_COMMAND` and adds bat/eza previews.
The fzf-tab block uses the five-field `:completion:*:*:*:*:*` pattern to outrank Oh My Zsh's menu default, restore colors, preserve Git checkout ordering,
and bind group navigation. The Bat child owns its managed config and canonical link; fd owns its link, eza aliases come from early zstyles, and zoxide
initializes exactly once through its OMZ plugin.

Micro true color remains `MICRO_TRUECOLOR=1`, and modern CLI selects Micro as the default editor; tealdeer owns the guarded completion symlink and a
non-fatal cache warm-up. The Markdown code component owns Glow's managed config and enables TUI mouse support; zoxide owns no static config or second init.

## Yazi application

`--app-yazi` adds Yazi's official signed stable APT repository, then installs `file` and `yazi`; the package owns the `yazi` and `ya` binaries and Bash
completions. Git fetchers and the Git/keymap plugins are unconditional. With modern CLI enabled, the app adds the two Bat previewers and official `piper`;
with Markdown enabled, it adds the Glow previewer and third-party `alberti42/faster-piper`, which requires Yazi 26.8.15 or newer. It exposes `$w`, `$h`, and
terminal-theme `$t`; Glow consumes
`$t` as `dark` or `light`, and the runner preserves `-- "$1"`. Command and code components run first, so each conditional preview command is already
available.

After plugin installation, `main.sh` runs `yazi.toml.sh`; that script creates the Yazi config directory and directly writes the complete `yazi.toml` render.
`init.lua` and `keymap.toml` remain shipped artifacts. Each plugin has its own `ya pkg add` invocation, so a partial failure cannot install config that
references a missing plugin.
A later successful run may leave disabled plugins in the mutable `package.toml`, but the regenerated config no longer references them. Plugin installation
precedes config rendering; because `ya pkg add` rejects an already-listed dependency, an ordinary rerun can exit before `yazi.toml.sh`. Do not rely on a
rerun to retract a previewer. The `y()` wrapper remains in `00-setup_env.zsh.sh`, the sole writer of `00-setup_env.zsh`, and is emitted only when
`APP_YAZI=1`.

## Git application

`--app-git` owns the complete Git concern: GitHub CLI repository setup, `gh`, delta, lazygit, global Git settings, lazygit config, the `lg()` cwd-following
function, and deferred `gh auth login`. Physical writers still follow the shared ownership rules: the Git leaf writes tool and Git config,
`00-setup_env.zsh.sh` writes `lg()`, and `99-first_run.zsh.sh` writes the one-shot login block. Do not split delta or lazygit into modern CLI.

The lazygit config targets the packaged schema. It keeps Nerd Fonts version `"3"` as a string and explicitly uses `delta --paging=never`; global
`core.pager=delta` is not inherited by lazygit. The `lg()` function uses `LAZYGIT_NEW_DIR_FILE` to move the parent shell to lazygit's exit directory.

GitHub login is deferred because unattended container builds have no interactive Zsh startup. The block removes its own file before checking command
availability or current auth status and invoking `gh auth login`, so a failure or cancellation is not retried automatically. A later non-empty render
recreates the file and permits one new attempt.

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
value here. Append `[1m]` only when the underlying model supports 1M context; with an LLM gateway, the gateway decides whether the request succeeds. Do not add
`CLAUDE_CODE_AUTO_COMPACT_WINDOW` or `autoCompactWindow` to the managed template. Absent runtime or higher-priority managed overrides, Claude Code uses its
model/provider-specific default auto-compaction window.

The copilot marketplace installs `agent-inject` and `tool-search`. With this non-first-party `ANTHROPIC_BASE_URL`, keep native `ENABLE_TOOL_SEARCH` unset so
Claude Code uses its documented upfront-loading fallback. Set it to `true` only if the gateway forwards `tool_reference` blocks. Both plugins need
Node/npm/npx. Bootstrap NodeSource LTS only when `node` is absent; an existing incompatible runtime is left for plugin installation to report. Node is
private to this integration, not a standalone Debian component.

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
N independently generated 32-byte hex keys. The task assumes the service has already produced a valid `config.json`. Before changing API keys,
`copilot-api-config` also forces `useResponsesApiWebSocket=false` on every run.

## macOS-specific constraints

The macOS OMZ custom tree has only `00-setup_env.zsh.sh`; it has no load-time settings or deferred interactive component. With `APP_VSCODE=1`, that writer
selects `code --wait` unconditionally. With all flags off, its output from `# zsh-autosuggestions` through `ZSHZ_TILDE=1` matches the Debian writer after
Debian's Editor section. Keep that shared block byte-equivalent. Do not hoist it outside each tree because the Debian-only Docker build context cannot see a
root-level file.

`macos/main.sh` evaluates `/opt/homebrew/bin/brew shellenv` in the provisioning Bash process so child installers can find Homebrew; interactive discovery
later comes from the Oh My Zsh `brew` plugin. The absolute prefix is a current hard requirement—strict mode aborts before child installers if Homebrew is
elsewhere, so any prefix generalization must update this call explicitly.

## Change checklist

Before finishing a change:

- Confirm the correct dispatcher owns every new flag; distinguish runnable components from integration-only flags and keep applicable interface lists
  ordered.
- Confirm each configuration fragment has one logical owner and place shell settings by read time.
- Check behavior on a fresh home and a repeated home with relevant flags disabled.
- Preserve the first-run lifecycle: empty renders retain a pending current task, sourcing deletes it before interaction, retired paths have documented
  explicit cleanup, and a non-empty rerender permits one new attempt.
- Validate shipped config against the packaged tool, including keys parsers may silently ignore.
- Run Bash syntax, ShellCheck, shfmt, and staged/unstaged whitespace checks.
- Render generated Zsh and run `zsh -n`; use a real ZLE smoke test for plugin-order or fzf changes.
- Do not run an installer smoke test on the host merely to prove dispatch; these scripts perform real package installation and modify the home directory.
