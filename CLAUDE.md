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
- No test suite. To exercise a change without the full remote install, run a dispatcher
  directly, e.g. `bash debian/main.sh --app-tmux` — note it still does real `apt` installs
  and always runs `command/zsh.sh` + `command/omz.sh` first.
- To check the macOS plugin array without installing anything, run
  `macos/command/omz_custom/main.sh` against a throwaway `HOME` with stub `git` and `brew`
  commands plus a shim mapping BSD `sed -i ''` to the host sed. Render
  `00-setup_env.zsh` there and check it with `zsh -n`.

## Architecture

Three independent setup trees, selected by `--setup`:

- `macos/` — Xcode CLT check, Homebrew, oh-my-zsh, plus optional apps. Positioned as a
  *terminal client / jump box*, not a dev machine: its plugin list is built around the
  ssh-to-remote workflow and deliberately omits `git`. `command/omz.sh` installs oh-my-zsh,
  while `command/omz_custom/main.sh` owns plugins and the theme.
- `debian/` — the richest tree; installs zsh + oh-my-zsh unconditionally, then a
  matrix of optional components.
- `container/` — builds and runs a Docker dev container (`dev-container`) or the
  `copilot-api` image.

`windows-wip/` is **not** a setup tree — it is a staging area for scripts awaiting Windows
adaptation. No `--setup` value reaches it and nothing runs it; `windows-wip/code/{csharp,powershell}.sh`
are still the Debian `apt` versions they were before being moved out of `debian/code/`.

### The dispatcher pattern

1. Env-var defaults with override: `export FOO="${FOO:-0}"`. The platform roots `debian/main.sh`
   and `macos/main.sh` export their flag vars so leaf scripts can read them.
2. `parse_args()` walks `$@`, sets vars for known flags, and pushes everything else onto
   `POSITIONAL` so downstream scripts can still see their own flags.
3. Boolean flags (`--app-tmux`) `shift` once; value flags (`--branch <v>`) use the
   `numOfArgs` idiom that guards against a missing trailing value before `shift`ing twice.
4. `main()` runs each enabled component's leaf script, gated on `FOO == "1"`. Exporting is a
   deliberate cross-cutting mechanism: a leaf can read *another* component's flag to add
   integration config only when both are enabled — e.g. `tmux.sh` reads `AGENT_CLAUDE` (adds
   Claude Code passthrough / extended-keys when `--app-tmux` + `--agent-claude`); `micro/main.sh`
   reads `APP_VSCODE`. Those env reads are intentional — not a missing `parse_args` to add.
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
`--flag` case to the relevant `main.sh`, add the gated `bash "./path/foo.sh" "$@"` call,
write the leaf script with the same footer, and document the flag in `README.md`'s table.

### Nesting

Flags cascade through nested dispatchers. `--agent-claude` (in `debian/main.sh`) invokes
`debian/agent/claude/main.sh`, whose own `--agent-claude-copilot-api` then invokes
`debian/agent/claude/copilot_api/main.sh`, which parses `--agent-claude-anthropic-*`.
`README.md` groups flags as "main args" vs "script args" to reflect which dispatcher owns them.

### Container flow

`container/dev-container/main.sh` base64-encodes the forwarded setup flags
(`setup_args_b64`) and passes them as a Docker build-arg. The `Dockerfile` decodes them and
runs `debian/main.sh --unattended <flags>` inside the image (build context is `../../debian`).
So container flags are really debian flags — `--unattended` (see `omz.sh`) makes oh-my-zsh
install non-interactively and switches the login shell.

### copilot-api integration

`copilot_api/main.sh` queries a running copilot-api server (`/v1/models`), picks the newest
opus/sonnet/haiku model ids (preferring `[1m]` variants, newest picked by `sort -V`), and
renders `~/.claude/settings.json` from the `settings.json` template using `jq`, then installs
the Claude plugin marketplace/plugin. It expects the copilot-api server to already be reachable
at `AGENT_CLAUDE_ANTHROPIC_BASE_URL` (default `http://localhost:4141`).

## Conventions

- Every script starts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Prefer `command -v foo` guards before use; install missing deps with
  `sudo apt-get update && sudo apt-get install -y foo` (debian) inline.
- Config edits are done in-place with `sed -i` against known upstream markers (e.g.
  toggling commented lines in `.zshrc` / `tmux.conf.local`, or appending to `plugins=(...)`).
  These depend on the exact upstream file format — verify the marker still exists upstream
  when a `sed` edit silently no-ops.
- **macOS omz ownership.** `macos/command/omz_custom/main.sh` is the only writer of
  `plugins=()` and `ZSH_THEME=`. It owns every third-party clone through `download_plugin()`,
  rebuilds the array through `install_plugin()` / `append_plugin()`, and installs the theme
  through `install_theme()`. The optional `ssh` and `vscode` plugins are gated there from the
  exported component flags; `macos/command/ssh.sh` and `macos/app/vscode.sh` keep their non-zsh
  setup and do not edit `.zshrc`. `custom_env.sh` is the only writer of
  `$ZSH_CUSTOM/00-setup_env.zsh`; macOS needs neither `pre_plugin.sh` nor `first_run.sh`.
- **macOS plugin ordering.** Array order is the `append_plugin()` call order:
  `aliases`, `brew`, `colored-man-pages`, `command-not-found`, `copyfile`, `copypath`,
  `dirhistory`, `extract`, `fancy-ctrl-z`, `macos`, `magic-enter`, `safe-paste`, `sudo`,
  `universalarchive`, `z`, optional `ssh`, optional `vscode`, `ohmyzsh-full-autoupdate`,
  `you-should-use`, `zsh-autosuggestions`, `zsh-syntax-highlighting`. Keep `brew` before
  `command-not-found`, autoupdate before the other cloned plugins, and syntax highlighting last.
- **macOS custom environment.** `custom_env.sh` rewrites `00-setup_env.zsh` on every run with
  the autosuggestions, syntax-highlighting, you-should-use and zsh-z settings. Oh My Zsh loads
  this file after plugins, which is required for the upstream
  `ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets)` form to preserve the default `main` highlighter.
- **macOS Homebrew PATH.** `macos/command/homebrew.sh` installs Homebrew but does not write
  `.zprofile`. The `eval "$(/opt/homebrew/bin/brew shellenv)"` in `macos/main.sh` serves the
  setup-time bash process; the omz `brew` plugin serves interactive zsh.
- **macOS plugin selection.** Do not add `ssh-agent`: it replaces the launchd-managed agent and
  breaks Keychain integration. GNU-rsync aliases are unsafe with macOS openrsync; `git` is dead
  weight on this terminal-client tree; `alias-finder` is superseded by `you-should-use`; and
  `copybuffer` would take `^O` from zsh's native `accept-line-and-down-history`.
- The rewritten macOS scripts use single quotes for literals and double quotes only where shell
  expansion is required. Generated zsh lines remain single-quoted at setup time so values such
  as `$ZSH_CUSTOM` are not expanded early.
