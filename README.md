# Setup Env

- [1. macOS](#1-macos)
- [2. Debian / Container](#2-debian--container)
- [3. Agent](#3-agent)
- [4. VSCode](#4-vscode)
- [5. 其他](#5-其他)

个人开发环境的一组一次性 Bash 安装脚本。入口脚本会从 GitHub 拉取本仓库，然后按目标系统执行对应目录下的安装逻辑；VS Code 扩展列表可单独安装。

入口目标：

- `macos`: macOS 工作站
- `debian`: Debian 主机，或通过 `--container` 构建 Debian 开发容器
- `agent`: AI gateway (copilot-api)

## 1. macOS

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
  --setup macos \
  [--app-vscode] \
  [--app-ssh ...]
```

默认安装/配置：

- Xcode Command Line Tools
- Homebrew
- Oh My Zsh，启用 `z`、`sudo`、`brew`
- Oh My Zsh 插件：`ohmyzsh-full-autoupdate`、`zsh-autosuggestions`、`zsh-syntax-highlighting`
- Powerlevel10k 和 MesloLGS NF 字体

可选参数：

| 参数 | 作用 |
| --- | --- |
| `--app-vscode` | 通过 Homebrew 安装 Visual Studio Code 和 Fira Code，并启用 Oh My Zsh `vscode` 插件。 |
| `--app-ssh` | 写入 `~/.ssh/config`，可按需生成密钥并复制公钥到远端。 |
| `--app-ssh-host <alias>` | SSH Host 别名。 |
| `--app-ssh-hostname <host>` | SSH HostName。 |
| `--app-ssh-user <user>` | SSH 用户，默认当前用户。 |
| `--app-ssh-identity-file <name>` | 在 `~/.ssh/` 下生成/使用的密钥文件名。 |
| `--app-ssh-comment <text>` | 生成密钥时写入的注释。 |
| `--app-ssh-no-copy-key` | 不执行 `ssh-copy-id`。 |

## 2. Debian / Container

Debian 主机：

```shell
sudo apt-get update \
  && sudo apt-get install -y curl \
  && bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --setup debian \
    [flags...]
```

Debian 开发容器：

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
  --setup debian \
  --container dev-container \
  [--image-tag latest] \
  [flags...]
```

默认安装/配置：

- `zsh`
- `/etc/zsh/zprofile` source `/etc/profile`
- Oh My Zsh，启用 `z`、`sudo`
- Oh My Zsh 插件：`ohmyzsh-full-autoupdate`、`zsh-autosuggestions`、`zsh-syntax-highlighting`
- Powerlevel10k

容器模式额外行为：基于 `debian:trixie` 构建 `dev-container:<tag>`，创建与宿主 `$USER` 同名的免密 sudo 用户，复用宿主 `LANG`/`LANGUAGE`/时区，安装 `git` 和 `curl`，启动长期运行容器，并把宿主 `~/Projects` 挂载到容器同路径下。

可选参数：

| 参数 | 作用 |
| --- | --- |
| `--app-docker` | 安装 Docker Engine、Buildx、Compose，并把当前用户加入 `docker` 组。 |
| `--app-git` | 配置全局 Git 用户信息，并启用 Oh My Zsh `git` 插件。 |
| `--app-git-user-name <name>` | `git config --global user.name`。 |
| `--app-git-user-email <email>` | `git config --global user.email`。 |
| `--app-vscode` | 配置 `code --wait` 为 Git 编辑器，并启用 Oh My Zsh `vscode` 插件。 |
| `--lang-bash` | 安装 `build-essential`、`shfmt`、`shellcheck`。 |
| `--lang-csharp` | 通过微软 APT 源安装最新 .NET SDK，并更新 .NET workload。 |
| `--lang-go` | 安装最新 Go linux-amd64 工具链，写入 Go PATH，并启用 Oh My Zsh `golang` 插件。 |
| `--lang-powershell` | 通过微软 APT 源安装 PowerShell。 |
| `--lang-python` | 安装 Python 3、uv、uv 补全、BesLogic Ruff 配置和 `py-spy`。 |
| `--lang-rust` | 通过 rustup 安装 Rust，并启用 Oh My Zsh `rust` 插件。 |
| `--tool-protobuf` | 安装 `clang-format` 和最新 `protoc` 到 `~/.local`。 |

## 3. Agent

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
  --setup agent \
  [flags...]
```

可选参数：

| 参数 | 作用 |
| --- | --- |
| `--gateway-copilot-api` | 构建最新版 copilot-api，并复用 `~/.copilot-api` 中的授权启动服务。 |
| `--gateway-copilot-api-auth` | 删除原授权并重新授权，需搭配 `--gateway-copilot-api`。 |

Gateway 监听 `http://localhost:4141`。

## 4. VSCode

安装 [vscode/extensions.txt](vscode/extensions.txt) 中列出的扩展。需要 `code` 命令已在 `PATH` 中。

```shell
curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/vscode/extensions.txt" \
  | xargs -L 1 code --force --install-extension
```

[vscode/settings.json](vscode/settings.json) 是参考配置，不会自动写入用户设置。

## 5. 其他

可用 `--branch <branch>` 指定入口脚本拉取的分支；默认分支是 `master`。
