#!/usr/bin/env bash

set -euo pipefail

install_python() {
    sudo apt-get update
    sudo apt-get install -y python3

    export PATH="$HOME/.local/bin:$PATH"
    curl -LsSf 'https://astral.sh/uv/install.sh' | sh
}

install_tools() {
    export PATH="$HOME/.local/bin:$PATH"
    uv tool install py-spy

    mkdir -p "$HOME/.config/Beslogic"
    curl -fsSL 'https://raw.githubusercontent.com/BesLogic/Beslogic-Ruff-Config/refs/heads/main/ruff.toml' \
        -o "$HOME/.config/Beslogic/ruff.toml"
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    install_python
    install_tools
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
