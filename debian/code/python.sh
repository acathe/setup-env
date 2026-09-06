#!/usr/bin/env bash

set -euo pipefail

main() {
    brew install -q 'uv'
    uv tool install -q 'py-spy'

    mkdir -p "$HOME/.config/Beslogic"
    curl -fsSL 'https://raw.githubusercontent.com/BesLogic/Beslogic-Ruff-Config/refs/heads/main/ruff.toml' \
        -o "$HOME/.config/Beslogic/ruff.toml"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
