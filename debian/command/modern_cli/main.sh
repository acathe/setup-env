#!/usr/bin/env bash

set -euo pipefail

install_packages() {
    sudo apt-get update
    sudo apt-get install -y \
        jq \
        unzip \
        glow \
        ripgrep \
        zoxide \
        hyperfine \
        sd \
        btop \
        du-dust \
        duf \
        procs
}

install_binaries() {
    local tmp
    tmp="$(mktemp -d)"

    curl -fsSL -o "$tmp/choose" \
        'https://github.com/theryangeary/choose/releases/latest/download/choose-x86_64-unknown-linux-gnu'
    sudo install -m 755 "$tmp/choose" '/usr/local/bin/choose'
}

main() {
    install_packages
    install_binaries

    bash './bat/main.sh' "$@"
    bash './eza.sh' "$@"
    bash './fdfind.sh' "$@"
    bash './fzf.sh' "$@"
    bash './micro/main.sh' "$@"
    bash './tldr.sh' "$@"
    bash './yazi.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
