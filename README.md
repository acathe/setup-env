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

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup debian \
        [--flag]
```

| main args              | script args                |
| ---------------------- | -------------------------- |
| `--command-modern-cli` |                            |
| `--command-ssh`        |                            |
| `--code-bash`          |                            |
| `--code-go`            |                            |
| `--code-markdown`      |                            |
| `--code-protobuf`      |                            |
| `--code-python`        |                            |
| `--code-rust`          |                            |
| `--app-claude`         |                            |
| `--app-docker`         |                            |
| `--app-ghostty`        |                            |
| `--app-git`            | `--app-git-user-name <v>`  |
|                        | `--app-git-user-email <v>` |
| `--app-tmux`           |                            |
| `--app-vscode`         |                            |
| `--app-yazi`           |                            |

```bash
xargs -L1 code --install-extension < debian/vscode/extensions.txt
```

```bash
curl -fsSL https://raw.githubusercontent.com/acathe/setup-env/master/main.sh \
    | bash -s -- --setup container \
        --image magpie
```

| main args        | script args |
| ---------------- | ----------- |
| `--image magpie` |             |
