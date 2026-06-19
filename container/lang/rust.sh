#!/usr/bin/env bash

set -euo pipefail

main() {
    if [[ -s "$HOME/.zshenv" ]]; then
        echo >> "$HOME/.zshenv"
    fi

    echo "# Rust" >> "$HOME/.zshenv"

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    sed -i '/^plugins=(/s/)/ rust)/' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
