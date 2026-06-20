#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    if [[ -s "$HOME/.zshenv" ]]; then
        echo >> "$HOME/.zshenv"
    fi

    echo "# Rust" >> "$HOME/.zshenv"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    rm -f "$HOME/.profile"

    sed -i '/^plugins=(/s/)/ rust)/' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
