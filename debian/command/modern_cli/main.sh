#!/usr/bin/env bash

set -euo pipefail

install_binaries() {
    local tmp
    tmp="$(mktemp -d)"

    curl -fsSL -o "$tmp/yazi.zip" \
        'https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip'
    unzip -q "$tmp/yazi.zip" -d "$tmp"
    sudo install -m 755 "$tmp/yazi-x86_64-unknown-linux-gnu/yazi" '/usr/local/bin/yazi'
    sudo install -m 755 "$tmp/yazi-x86_64-unknown-linux-gnu/ya" '/usr/local/bin/ya'

    curl -fsSL -o "$tmp/choose" \
        'https://github.com/theryangeary/choose/releases/latest/download/choose-x86_64-unknown-linux-gnu'
    sudo install -m 755 "$tmp/choose" '/usr/local/bin/choose'
}

main() {
    sudo apt-get update
    sudo apt-get install -y \
        jq \
        unzip \
        glow \
        eza \
        ripgrep \
        zoxide \
        fzf \
        tealdeer \
        hyperfine \
        sd \
        btop \
        du-dust \
        duf \
        procs

    tldr --update || true

    install_binaries

    bash './bat/main.sh' "$@"
    bash './fdfind.sh' "$@"
    bash './micro/main.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
