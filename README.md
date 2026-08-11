# Setup Env

- [1. MacOS](#1-macos)
- [2. Debian](#2-debian)
- [3. Container](#3-container)

## 1. MacOS

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup macos \
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
| `--app-vscode`  |                                   |

## 2. Debian

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup debian \
        [--flag]
```

| main args          | script args                               |
| ------------------ | ----------------------------------------- |
| `--agent-claude`   | `--agent-claude-copilot-api`              |
|                    | `--agent-claude-anthropic-base-url <v>`   |
|                    | `--agent-claude-anthropic-auth-token <v>` |
| `--app-docker`     |                                           |
| `--app-github`     |                                           |
| `--app-micro`      |                                           |
| `--app-tmux`       |                                           |
| `--app-vscode`     |                                           |
| `--code-bash`      |                                           |
| `--code-go`        |                                           |
| `--code-python`    |                                           |
| `--code-rust`      |                                           |
| `--command-utils`  | `--command-utils-git-user-name <v>`       |
|                    | `--command-utils-git-user-email <v>`      |
| `--tools-node`     |                                           |
| `--tools-protobuf` |                                           |

```bash
xargs -L1 code --install-extension < debian/vscode/extensions.txt
```

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
