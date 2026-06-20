#!/usr/bin/env bash

set -euo pipefail

install_python() {
    sudo apt-get update
    sudo apt-get install -y build-essential python3

    sed -i '/^plugins=(/s/)/ python)/' "$HOME/.zshrc"
}

install_uv() {
    export PATH="$HOME/.local/bin:$PATH"
    curl -LsSf https://astral.sh/uv/install.sh | sh

    if [[ -s "$HOME/.zshrc" ]]; then
        echo >> "$HOME/.zshrc"
    fi

    {
        echo '# uv shell completions'
        echo 'eval "$(uv generate-shell-completion zsh)"'
        echo 'eval "$(uvx --generate-shell-completion zsh)"'
    } >> "$HOME/.zshrc"
}

install_tools() {
    export PATH="$HOME/.local/bin:$PATH"

    mkdir -p "$HOME/.config/Beslogic"
    curl -fsSL "https://raw.githubusercontent.com/BesLogic/Beslogic-Ruff-Config/refs/heads/main/ruff.toml" \
        -o "$HOME/.config/Beslogic/ruff.toml"

    uv tool install py-spy
}

main() {
    install_python
    install_uv
    install_tools
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
