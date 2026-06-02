# Setup Env

- [1. MacOS](#1-macos)
- [2. Debian](#2-debian)
- [3. Container](#3-container)

## 1. MacOS

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- --setup macos
```

## 2. Debian

```shell
sudo apt update \
&& sudo apt install -y curl \
&& bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- --setup debian
```

## 3. Container

```shell
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh")" -- --git-user-name $your_name --git-user-email $your_email --[tools]
```

| Tools          |
| -------------- |
| --dev-bash     |
| --dev-go       |
| --dev-python   |
| --dev-rust     |
| --dev-protobuf |
