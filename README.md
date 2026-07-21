# Setup Env

- [1. MacOS](#1-macos)
- [2. Debian](#2-debian)
- [3. Container](#3-container)
- [4. VSCode](#4-vscode)

## 1. MacOS

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup macos \
        [--flag]
```

| main args      | script args                   |
| -------------- | ----------------------------- |
| `--app-vscode` |                               |
| `--app-ssh`    | `--app-ssh-host <v>`          |
|                | `--app-ssh-hostname <v>`      |
|                | `--app-ssh-user <v>`          |
|                | `--app-ssh-identity-file <v>` |
|                | `--app-ssh-comment <v>`       |
|                | `--app-ssh-no-copy-key`       |

## 2. Debian

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup debian \
        [--flag]
```

| main args           | script args                               |
| ------------------- | ----------------------------------------- |
| `--agent-claude`    | `--agent-claude-copilot-api`              |
|                     | `--agent-claude-anthropic-base-url <v>`   |
|                     | `--agent-claude-anthropic-auth-token <v>` |
| `--app-docker`      |                                           |
| `--app-github`      |                                           |
| `--app-micro`       |                                           |
| `--app-tmux`        |                                           |
| `--app-vscode`      |                                           |
| `--code-bash`       |                                           |
| `--code-csharp`     |                                           |
| `--code-go`         |                                           |
| `--code-powershell` |                                           |
| `--code-python`     |                                           |
| `--code-rust`       |                                           |
| `--command-utils`   | `--command-utils-git-user-name <v>`       |
|                     | `--command-utils-git-user-email <v>`      |
| `--tools-node`      |                                           |
| `--tools-protobuf`  |                                           |

## 3. Container

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup container \
        [--flag]
```

| main args               | script args          |
| ----------------------- | -------------------- |
| `--image dev-container` | `--container <v>`    |
|                         | `--image-tag <v>`    |
|                         | `(debian-flag)`      |
| `--image copilot-api`   | `--copilot-api-auth` |

## 4. VSCode

```bash
xargs -L1 code --install-extension < vscode/extensions.txt
```
