# Setup Env

A collection of one-shot bash scripts that bootstrap my personal development
environments — macOS workstations, Debian servers, ephemeral dev containers,
and Visual Studio Code — from a single `curl | bash` command.

This repository is opinionated: it installs **my** preferred shell, plugins,
fonts, languages, and editor settings. It is published in the open so it can
be reproduced on any new machine in minutes, and so that others can use it as
a starting point.

**Forks are welcome.** Fork the repo, swap out the packages, plugins, or
extensions that don't fit your workflow, and point the `curl` command at your
own fork's `main.sh` (or use the `--branch` flag to target a custom branch).
Each setup target (`macos`, `debian`, `container`, `vscode`) is a standalone
directory, so cherry-picking the parts you want is straightforward.

## 1. Table of Contents

- [1. Table of Contents](#1-table-of-contents)
- [2. MacOS](#2-macos)
- [3. Debian](#3-debian)
- [4. Container](#4-container)
- [5. VSCode](#5-vscode)
- [6. Acknowledgments](#6-acknowledgments)
  - [6.1. Shell \& terminal](#61-shell--terminal)
  - [6.2. Languages \& toolchains](#62-languages--toolchains)
  - [6.3. Editor](#63-editor)
  - [6.4. Fonts](#64-fonts)
  - [6.5. Container \& OS](#65-container--os)
- [7. License](#7-license)

## 2. MacOS

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --setup macos \
    [<app>...]
```

| Apps         | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| --app-vscode | Install Visual Studio Code with Fira Code font and the zsh vscode plugin. |

**What gets installed (always):**

- Xcode Command Line Tools (if missing).
- [Homebrew](https://brew.sh) package manager.
- [Zsh](https://www.zsh.org) (bundled with macOS) configured as the login shell.
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) framework with the `z`,
  `sudo`, and `brew` plugins enabled.
- Oh My Zsh community plugins:
  [ohmyzsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate),
  [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions),
  [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) Zsh theme with the
  patched MesloLGS NF font (`font-meslo-for-powerlevel10k`).

**What gets installed with `--app-vscode`:**

- [Visual Studio Code](https://code.visualstudio.com) (cask).
- [Fira Code](https://github.com/tonsky/FiraCode) font (cask).
- The Oh My Zsh [`vscode`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vscode)
  plugin is enabled in `~/.zshrc`.

## 3. Debian

```shell
sudo apt-get update \
    && sudo apt-get install -y curl \
    && bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
        --setup debian \
        [<app>...]
```

| Apps         | Description                                                         |
| ------------ | ------------------------------------------------------------------- |
| --app-docker | Install Docker Engine and add the current user to the docker group. |

**What gets installed (always):**

- `git` (via `apt`) if missing.
- `zsh` (via `apt`), with `/etc/zsh/zprofile` patched to source `/etc/profile`
  so login-shell environment variables continue to apply.
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) with the `z` and `sudo`
  plugins enabled.
- Oh My Zsh community plugins:
  [ohmyzsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate),
  [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions),
  [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) Zsh theme.

**What gets installed with `--app-docker`:**

- Docker's official APT repository and signing key.
- [Docker Engine](https://www.docker.com) (`docker-ce`, `docker-ce-cli`,
  `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`).
- The invoking user is added to the `docker` group.

## 4. Container

Build and run a layered Debian-based dev container image that includes a
ready-to-use Zsh shell plus any languages and tools you select.

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --setup container \
    [--user $your_user] \
    --git-user-name $your_name \
    --git-user-email $your_email \
    [<tool>...]
```

`--user` is optional. When omitted, the script falls back to the `USER`
environment variable (which is set by default on most shells), so on a typical
interactive session you can simply leave the flag out. Pass `--user` explicitly
only when you need to override that value (for example, when running from a
context where `USER` is unset or points to the wrong account).

| Tools            | Description                                                     |
| ---------------- | --------------------------------------------------------------- |
| --lang-bash      | Add `shfmt` and `shellcheck` for shell scripting.               |
| --lang-go        | Install the latest Go toolchain from the official release page. |
| --lang-python    | Install Python 3, `uv`, `py-spy`, and a shared Ruff config.     |
| --lang-rust      | Install the Rust toolchain via `rustup`.                        |
| --tools-protobuf | Install `protoc` plus `clang-format`.                           |
| --tools-thrift   | Install the Apache Thrift compiler (`thrift-compiler`).         |

**What gets installed (always):**

The image is assembled in layers — `base` → `terminal` → `lang` → `tools` →
`finish` — each stacked on the previous one.

- **Base layer** (`debian:trixie`):
  - `locales` package with the locale generated from `$LANG` on the host.
  - `sudo` and a passwordless sudo user (`$USER`).
  - `TZ` set from the host's `timedatectl` value.
- **Terminal layer**:
  - `zsh`, `git`, `curl`, `build-essential`.
  - `/etc/zsh/zprofile` patched to also source `/etc/profile`.
  - Global `git config` for `user.name`, `user.email`, and
    `core.editor=code --wait`.
  - [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) with the same plugin set
    used by the macOS and Debian setups (z, sudo, vscode,
    [ohmyzsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate),
    [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions),
    [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)).
  - [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme with a
    pre-baked `~/.p10k.zsh`.
  - Zsh set as the user's default shell; `~/.profile`, `~/.bashrc`, and
    `~/.bash_logout` are removed.
- **Finish layer**: sets `CMD ["sleep", "infinity"]` so the container can be
  used as a long-running dev environment.

The image is started with `docker run -d --privileged --init --shm-size=2g`,
named `dev-container` (overridable via `--container`), and `~/Projects` from
the host is bind-mounted into the container.

**What gets installed with `--lang-*` / `--tools-*` flags:**

- `--lang-bash` — [`shfmt`](https://github.com/mvdan/sh) and
  [`shellcheck`](https://www.shellcheck.net) from APT.
- `--lang-go` — the newest [Go](https://go.dev) tarball from
  `https://go.dev/dl/`, unpacked to `/usr/local/go`; `$PATH` and the
  [`golang`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/golang)
  Oh My Zsh plugin are wired up.
- `--lang-python` — Python 3 from APT, [`uv`](https://github.com/astral-sh/uv)
  installed via the official installer, the
  [`python`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/python)
  Oh My Zsh plugin enabled,
  [BesLogic's Ruff config](https://github.com/BesLogic/Beslogic-Ruff-Config)
  saved to `~/.config/Beslogic/ruff.toml`, and
  [`py-spy`](https://github.com/benfred/py-spy) installed as a `uv` tool.
- `--lang-rust` — [`rustup`](https://rustup.rs) bootstrap, plus the
  [`rust`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/rust) Oh My
  Zsh plugin.
- `--tools-protobuf` — `clang-format` from APT and the latest
  [`protoc`](https://github.com/protocolbuffers/protobuf) release installed
  under `~/.local`.
- `--tools-thrift` — [Apache Thrift](https://thrift.apache.org) compiler from
  APT.

## 5. VSCode

Install all extensions listed in [`vscode/extensions.txt`](./vscode/extensions.txt).
Requires the `code` CLI to be available in `PATH`.

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --setup vscode
```

**What gets installed:**

- All extensions from [`vscode/extensions.txt`](./vscode/extensions.txt),
  installed via `code --install-extension`. This includes language support
  (Python/Pylance, Go, Rust Analyzer, clangd, Bash IDE, CMake Tools), linting
  and formatting (Ruff, markdownlint, code-spell-checker, ErrorLens), Git
  tooling (GitLens), remote development (Remote-SSH, Remote-Containers,
  Docker), Protobuf/Thrift support, a Chinese language pack, and the
  One Dark Pro theme with Material Icon Theme.
- A recommended user settings file is provided at
  [`vscode/settings.json`](./vscode/settings.json) for reference (not applied
  automatically — copy what you want into your own `settings.json`).

## 6. Acknowledgments

This project is a thin orchestration layer on top of many excellent
open-source projects. All credit for the actual tooling goes to:

### 6.1. Shell & terminal

- [Homebrew](https://brew.sh)
- [Zsh](https://www.zsh.org)
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [OhMyZsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

### 6.2. Languages & toolchains

- [Go](https://go.dev)
- [Python](https://www.python.org), with:
  - [uv](https://github.com/astral-sh/uv)
  - [py-spy](https://github.com/benfred/py-spy)
  - [Ruff](https://github.com/astral-sh/ruff)
    ([BesLogic config](https://github.com/BesLogic/Beslogic-Ruff-Config))
- [Rust](https://www.rust-lang.org) / [rustup](https://rustup.rs)
- [shfmt](https://github.com/mvdan/sh) and [ShellCheck](https://www.shellcheck.net)
- [Protocol Buffers](https://github.com/protocolbuffers/protobuf)
- [Apache Thrift](https://thrift.apache.org)

### 6.3. Editor

- [Visual Studio Code](https://code.visualstudio.com)
- All extension authors listed in [`vscode/extensions.txt`](./vscode/extensions.txt).

### 6.4. Fonts

- [Fira Code](https://github.com/tonsky/FiraCode)
- [MesloLGS NF](https://github.com/romkatv/powerlevel10k#fonts) (patched by
  the Powerlevel10k author).

### 6.5. Container & OS

- [Debian](https://www.debian.org)
- [Docker](https://www.docker.com)

## 7. License

Released under the [MIT License](./LICENSE).
