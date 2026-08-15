#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

fetch_yazi() {
    curl -fsSL -o '/tmp/yazi.zip' \
        'https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip'
    unzip -qo '/tmp/yazi.zip' -d '/tmp'
}

install_yazi() {
    install -Dm 755 '/tmp/yazi-x86_64-unknown-linux-gnu/yazi' "$HOME/.local/bin/yazi"
    install -Dm 755 '/tmp/yazi-x86_64-unknown-linux-gnu/ya' "$HOME/.local/bin/ya"
}

set_completion() {
    install -Dm 644 '/tmp/yazi-x86_64-unknown-linux-gnu/completions/_yazi' "$ZSH_CUSTOM/completions/_yazi"
    install -Dm 644 '/tmp/yazi-x86_64-unknown-linux-gnu/completions/_ya' "$ZSH_CUSTOM/completions/_ya"
}

main() {
    sudo apt-get update
    sudo apt-get install -y file unzip

    fetch_yazi
    install_yazi
    set_completion
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
