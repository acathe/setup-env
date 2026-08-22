#!/usr/bin/env bash

set -euo pipefail

install_rust() {
    brew install 'rustup'

    local rustup_bin
    rustup_bin="$(brew --prefix rustup)/bin"
    export PATH="$rustup_bin:$PATH"
    rustup default stable

    if [[ -s "$HOME/.zshenv" ]]; then
        echo >> "$HOME/.zshenv"
    fi

    {
        echo '# Rust'
        printf 'export PATH="%s:$PATH"\n' "$rustup_bin"
    } >> "$HOME/.zshenv"
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    install_rust
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
