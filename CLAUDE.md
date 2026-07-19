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
temp dir and hands off to `<setup>/main.sh`, forwarding all unrecognized flags. So
the top-level `main.sh` only understands `--branch` and `--setup`; every other flag is
parsed by a downstream script.

## Linting / running

- Lint: `shellcheck **/*.sh` (config in `.shellcheckrc`; `SC2016` disabled because
  single-quoted `jq`/`sed` programs contain `$` that is not a shell expansion).
- No test suite. To exercise a change without a full remote install, run a setup
  script directly, e.g. `bash debian/main.sh --app-tmux` — each script `cd`s to its own
  dir on run, so relative `bash "./app/..."` calls resolve correctly.
- Requires Bash 4+ (`mapfile`, `${VAR%.*}`, `(( ))`). macOS's system Bash 3.2 will not
  run the `container` Dockerfile logic, but the target platforms ship Bash 4+.

## Architecture

Three independent setup trees, selected by `--setup`:

- `macos/` — Xcode CLT check, Homebrew, oh-my-zsh, plus optional apps.
- `debian/` — the richest tree; installs zsh + oh-my-zsh unconditionally, then a
  matrix of optional components.
- `container/` — builds and runs a Docker dev container (`dev-container`) or the
  `copilot-api` image.

### The dispatcher pattern (every `main.sh` and leaf script follows it)

1. Env-var defaults with override: `export FOO="${FOO:-0}"`. `debian/main.sh` uses
   `export` so the flags propagate as env vars into child scripts; leaf scripts read the
   same vars back (e.g. `tmux.sh` and `claude/main.sh` both read `AGENT_CLAUDE`).
2. `parse_args()` walks `$@`, sets vars for known flags, and pushes everything else onto
   `POSITIONAL` so downstream scripts can still see their own flags.
3. Boolean flags (`--app-tmux`) `shift` once; value flags (`--branch <v>`) use the
   `numOfArgs` idiom that guards against a missing trailing value before `shift`ing twice.
4. `main()` runs, gated on the `FOO == "1"` vars. A component's flag is checked in TWO
   places: the parent `main.sh` decides whether to invoke the leaf script, and the leaf
   script re-reads the env var for sub-behavior.
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
opus/sonnet/haiku model ids (preferring the `[1m]` variants via `sort -V | tail -n1`), and
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
