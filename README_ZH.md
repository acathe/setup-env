# Setup Env

一组一键式 bash 脚本，可通过单条 `curl | bash` 命令自动配置我个人的开发环境
——包括 macOS 工作站、Debian 服务器、临时开发容器以及 Visual Studio Code。

本仓库是高度个性化的：它安装的是**我**偏好的 shell、插件、字体、编程语言和
编辑器设置。之所以开源发布，是为了能在任意新机器上几分钟内完成复现，也方便
其他人将其作为起点。

**欢迎 Fork。** Fork 本仓库后，替换掉那些不符合你工作流的软件包、插件或扩展，
然后将 `curl` 命令指向你自己 fork 的 `main.sh`（或使用 `--branch` 参数指向自
定义分支）。每个安装目标（`macos`、`debian`、`container`、`vscode`）都是独立
的目录，因此可以轻松挑选你需要的部分。

## 1. 目录

- [1. 目录](#1-目录)
- [2. MacOS](#2-macos)
- [3. Debian](#3-debian)
- [4. Container](#4-container)
- [5. VSCode](#5-vscode)
- [6. 致谢](#6-致谢)
  - [6.1. Shell 与终端](#61-shell-与终端)
  - [6.2. 编程语言与工具链](#62-编程语言与工具链)
  - [6.3. 编辑器](#63-编辑器)
  - [6.4. 字体](#64-字体)
  - [6.5. 容器与操作系统](#65-容器与操作系统)
- [7. 许可证](#7-许可证)

## 2. MacOS

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --setup macos \
    [<app>...]
```

| Apps         | 说明                                                               |
| ------------ | ------------------------------------------------------------------ |
| --app-vscode | 安装 Visual Studio Code，并配置 Fira Code 字体和 zsh vscode 插件。 |

**默认始终安装的内容：**

- Xcode Command Line Tools（如缺失）。
- [Homebrew](https://brew.sh) 包管理器。
- [Zsh](https://www.zsh.org)（macOS 自带）配置为登录 shell。
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) 框架，并启用 `z`、`sudo`
  和 `brew` 插件。
- Oh My Zsh 社区插件：
  [ohmyzsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate)、
  [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)、
  [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)。
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) Zsh 主题，以及
  打了补丁的 MesloLGS NF 字体（`font-meslo-for-powerlevel10k`）。

**使用 `--app-vscode` 时额外安装的内容：**

- [Visual Studio Code](https://code.visualstudio.com)（cask）。
- [Fira Code](https://github.com/tonsky/FiraCode) 字体（cask）。
- 在 `~/.zshrc` 中启用 Oh My Zsh 的
  [`vscode`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vscode) 插件。

## 3. Debian

```shell
sudo apt-get update \
    && sudo apt-get install -y curl \
    && bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
        --setup debian \
        [<app>...]
```

| Apps         | 说明                                                 |
| ------------ | ---------------------------------------------------- |
| --app-docker | 安装 Docker Engine，并将当前用户加入 docker 用户组。 |

**默认始终安装的内容：**

- `git`（通过 `apt`）（如缺失）。
- `zsh`（通过 `apt`），并修改 `/etc/zsh/zprofile` 以 source `/etc/profile`，
  确保登录 shell 的环境变量继续生效。
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)，并启用 `z` 和 `sudo` 插件。
- Oh My Zsh 社区插件：
  [ohmyzsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate)、
  [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)、
  [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)。
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) Zsh 主题。

**使用 `--app-docker` 时额外安装的内容：**

- Docker 官方 APT 仓库及签名密钥。
- [Docker Engine](https://www.docker.com)（`docker-ce`、`docker-ce-cli`、
  `containerd.io`、`docker-buildx-plugin`、`docker-compose-plugin`）。
- 调用者用户被加入 `docker` 用户组。

## 4. Container

构建并运行一个分层的 Debian 开发容器镜像，内置开箱即用的 Zsh shell 以及你
选择的语言和工具。

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --setup container \
    [--user $your_user] \
    --git-user-name $your_name \
    --git-user-email $your_email \
    [<tool>...]
```

`--user` 是可选的。未指定时，脚本会回退到读取 `USER` 环境变量（在绝大多数
交互式 shell 中默认就有），因此在常规交互场景下可以直接省略该参数。仅当需要
覆盖该值时（例如在 `USER` 未设置或指向了错误账户的环境中运行）才需要显式
传入 `--user`。

| Tools            | 说明                                                 |
| ---------------- | ---------------------------------------------------- |
| --lang-bash      | 添加 `shfmt` 和 `shellcheck` 用于 shell 脚本开发。   |
| --lang-go        | 从官方发布页安装最新的 Go 工具链。                   |
| --lang-python    | 安装 Python 3、`uv`、`py-spy` 以及共享的 Ruff 配置。 |
| --lang-rust      | 通过 `rustup` 安装 Rust 工具链。                     |
| --tools-protobuf | 安装 `protoc` 以及 `clang-format`。                  |
| --tools-thrift   | 安装 Apache Thrift 编译器（`thrift-compiler`）。     |

**默认始终安装的内容：**

镜像按层组装 —— `base` → `terminal` → `lang` → `tools` → `finish` ——
每一层都构建在前一层之上。

- **Base 层**（`debian:trixie`）：
  - 安装 `locales` 包，并根据宿主机的 `$LANG` 生成对应 locale。
  - 安装 `sudo` 并创建一个免密 sudo 用户（`$USER`）。
  - 根据宿主机的 `timedatectl` 设置 `TZ`。
- **Terminal 层**：
  - `zsh`、`git`、`curl`、`build-essential`。
  - 修改 `/etc/zsh/zprofile` 以同时 source `/etc/profile`。
  - 全局 `git config` 设置 `user.name`、`user.email` 以及
    `core.editor=code --wait`。
  - [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)，使用与 macOS 和 Debian
    安装相同的插件集（z、sudo、vscode、
    [ohmyzsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate)、
    [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)、
    [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)）。
  - [Powerlevel10k](https://github.com/romkatv/powerlevel10k) 主题，附带预设的
    `~/.p10k.zsh`。
  - 将 Zsh 设为用户的默认 shell；并删除 `~/.profile`、`~/.bashrc` 与
    `~/.bash_logout`。
- **Finish 层**：设置 `CMD ["sleep", "infinity"]`，使容器可作为长期运行的开发
  环境使用。

镜像通过 `docker run -d --privileged --init --shm-size=2g` 启动，命名为
`dev-container`（可通过 `--container` 覆盖），并将宿主机的 `~/Projects`
目录绑定挂载到容器内。

**使用 `--lang-*` / `--tools-*` 参数时额外安装的内容：**

- `--lang-bash` —— 从 APT 安装 [`shfmt`](https://github.com/mvdan/sh) 和
  [`shellcheck`](https://www.shellcheck.net)。
- `--lang-go` —— 从 `https://go.dev/dl/` 下载最新 [Go](https://go.dev) tarball
  并解压到 `/usr/local/go`；配置 `$PATH` 以及启用 Oh My Zsh 的
  [`golang`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/golang) 插件。
- `--lang-python` —— 从 APT 安装 Python 3；通过官方安装器安装
  [`uv`](https://github.com/astral-sh/uv)；启用 Oh My Zsh 的
  [`python`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/python) 插件；
  将 [BesLogic 的 Ruff 配置](https://github.com/BesLogic/Beslogic-Ruff-Config)
  保存到 `~/.config/Beslogic/ruff.toml`；并通过 `uv` 工具安装
  [`py-spy`](https://github.com/benfred/py-spy)。
- `--lang-rust` —— 引导 [`rustup`](https://rustup.rs)，并启用 Oh My Zsh 的
  [`rust`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/rust) 插件。
- `--tools-protobuf` —— 从 APT 安装 `clang-format`，并将最新版的
  [`protoc`](https://github.com/protocolbuffers/protobuf) 安装到 `~/.local`。
- `--tools-thrift` —— 从 APT 安装 [Apache Thrift](https://thrift.apache.org)
  编译器。

## 5. VSCode

安装 [`vscode/extensions.txt`](./vscode/extensions.txt) 中列出的所有扩展。
需要 `code` 命令行工具在 `PATH` 中可用。

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --setup vscode
```

**安装内容：**

- 通过 `code --install-extension` 安装 [`vscode/extensions.txt`](./vscode/extensions.txt)
  中的所有扩展。包括语言支持（Python/Pylance、Go、Rust Analyzer、clangd、
  Bash IDE、CMake Tools）、代码检查与格式化（Ruff、markdownlint、
  code-spell-checker、ErrorLens）、Git 工具（GitLens）、远程开发
  （Remote-SSH、Remote-Containers、Docker）、Protobuf/Thrift 支持、中文语言
  包，以及 One Dark Pro 主题与 Material Icon Theme 图标主题。
- 推荐的用户设置文件位于
  [`vscode/settings.json`](./vscode/settings.json)，仅供参考（不会自动应用
  —— 请将你需要的内容复制到自己的 `settings.json` 中）。

## 6. 致谢

本项目只是众多优秀开源项目之上的一层薄薄的编排层。所有工具本身的功劳归属于：

### 6.1. Shell 与终端

- [Homebrew](https://brew.sh)
- [Zsh](https://www.zsh.org)
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [OhMyZsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

### 6.2. 编程语言与工具链

- [Go](https://go.dev)
- [Python](https://www.python.org)，包括：
  - [uv](https://github.com/astral-sh/uv)
  - [py-spy](https://github.com/benfred/py-spy)
  - [Ruff](https://github.com/astral-sh/ruff)
    （[BesLogic 配置](https://github.com/BesLogic/Beslogic-Ruff-Config)）
- [Rust](https://www.rust-lang.org) / [rustup](https://rustup.rs)
- [shfmt](https://github.com/mvdan/sh) 与 [ShellCheck](https://www.shellcheck.net)
- [Protocol Buffers](https://github.com/protocolbuffers/protobuf)
- [Apache Thrift](https://thrift.apache.org)

### 6.3. 编辑器

- [Visual Studio Code](https://code.visualstudio.com)
- [`vscode/extensions.txt`](./vscode/extensions.txt) 中列出的所有扩展作者。

### 6.4. 字体

- [Fira Code](https://github.com/tonsky/FiraCode)
- [MesloLGS NF](https://github.com/romkatv/powerlevel10k#fonts)（由
  Powerlevel10k 作者打补丁）。

### 6.5. 容器与操作系统

- [Debian](https://www.debian.org)
- [Docker](https://www.docker.com)

## 7. 许可证

基于 [MIT License](./LICENSE) 发布。
