#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

fetch_yazi() {
    local tmp
    tmp="$(mktemp -d)"

    curl -fsSL -o "$tmp/yazi.zip" \
        'https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip'
    unzip -q "$tmp/yazi.zip" -d "$tmp"

    echo "$tmp/yazi-x86_64-unknown-linux-gnu"
}

install_yazi() {
    local dir="$1"

    install -Dm 755 "$dir/yazi" "$HOME/.local/bin/yazi"
    install -Dm 755 "$dir/ya" "$HOME/.local/bin/ya"
}

set_completion() {
    local dir="$1"

    install -Dm 644 "$dir/completions/_yazi" "$ZSH_CUSTOM/completions/_yazi"
    install -Dm 644 "$dir/completions/_ya" "$ZSH_CUSTOM/completions/_ya"
}

main() {
    sudo apt-get update
    sudo apt-get install -y file unzip

    local dir
    dir="$(fetch_yazi)"

    install_yazi "$dir"
    set_completion "$dir"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
