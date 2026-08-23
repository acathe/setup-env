# Setup Env

- [1. MacOS](#1-macos)
- [2. Debian](#2-debian)
- [3. Container](#3-container)

## 1. MacOS

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- [--setup macos] \
        [--flag]
```

| main args       | script args                       |
| --------------- | --------------------------------- |
| `--command-ssh` | `--command-ssh-host <v>`          |
|                 | `--command-ssh-hostname <v>`      |
|                 | `--command-ssh-user <v>`          |
|                 | `--command-ssh-identity-file <v>` |
|                 | `--command-ssh-comment <v>`       |
|                 | `--command-ssh-no-copy-key`       |
| `--app-chatgpt` |                                   |
| `--app-ghostty` |                                   |
| `--app-vscode`  |                                   |

## 2. Debian

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup debian \
        [--flag]
```

| main args              | script args                             |
| ---------------------- | --------------------------------------- |
| `--command-modern-cli` |                                         |
| `--code-bash`          |                                         |
| `--code-go`            |                                         |
| `--code-markdown`      |                                         |
| `--code-protobuf`      |                                         |
| `--code-python`        |                                         |
| `--code-rust`          |                                         |
| `--app-claude`         | `--app-claude-copilot-api`              |
|                        | `--app-claude-base-url <v>`             |
|                        | `--app-claude-auth-token <v>`           |
|                        | `--app-claude-default-opus-model <v>`   |
|                        | `--app-claude-default-sonnet-model <v>` |
|                        | `--app-claude-default-haiku-model <v>`  |
| `--app-docker`         |                                         |
| `--app-git`            | `--app-git-user-name <v>`               |
|                        | `--app-git-user-email <v>`              |
| `--app-neovim`         |                                         |
| `--app-tmux`           |                                         |
| `--app-vscode`         |                                         |
| `--app-yazi`           |                                         |

```bash
xargs -L1 code --install-extension < debian/vscode/extensions.txt
```

## 3. Container

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup container \
        [--flag]
```

| main args                    | script args                    |
| ---------------------------- | ------------------------------ |
| `--image dev-container`      | `--container <v>`              |
|                              | `--image-tag <v>`              |
|                              | `(debian-flag)`                |
| `--image copilot-api`        | `--copilot-api-auth`           |
| `--image copilot-api-config` | `--clear-api-keys`             |
|                              | `--generate-api-keys <N>`      |
|                              | `--add-api-key <v>`            |
