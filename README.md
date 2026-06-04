# Setup Env

- [1. MacOS](#1-macos)
- [2. Debian](#2-debian)
- [3. Container](#3-container)

## 1. MacOS

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --setup macos \
    [<app>...]
```

| Apps         | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| --app-vscode | Install Visual Studio Code with Fira Code font and the zsh vscode plugin. |

## 2. Debian

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

## 3. Container

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- \
    --git-user-name $your_name \
    --git-user-email $your_email \
    [<tool>...]
```

| Tools            |
| ---------------- |
| --lang-bash      |
| --lang-go        |
| --lang-python    |
| --lang-rust      |
| --tools-protobuf |
| --tools-thrift   |
