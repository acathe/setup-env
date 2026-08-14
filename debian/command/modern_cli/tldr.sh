#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

set_completion() {
    local completion='/usr/share/zsh/vendor-completions/tldr.zsh'
    if [[ ! -f $completion ]]; then
        echo "$completion does not exist." >&2
        return 1
    fi

    mkdir -p "$ZSH_CUSTOM/completions"
    ln -sf "$completion" "$ZSH_CUSTOM/completions/_tldr"
}

main() {
    sudo apt-get update
    sudo apt-get install -y tealdeer

    tldr --update || true # 预热 tealdeer 离线缓存，网络失败不致命
    set_completion
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
