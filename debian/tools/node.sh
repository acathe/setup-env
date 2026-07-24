#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    # NodeSource LTS 官方源（版本比 Debian 自带更新，nodejs 自带 npm）。
    # 系统级安装：node 落到 /usr/bin、对任何进程可见——Claude Code 的 node
    # plugin（如 copilot-api agent-inject 的 hooks）由非交互进程直接以裸
    # `node` 拉起，必须在系统 PATH 里，故不用 nvm。
    curl -fsSL "https://deb.nodesource.com/setup_lts.x" | sudo -E bash -
    sudo apt-get install -y nodejs
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
