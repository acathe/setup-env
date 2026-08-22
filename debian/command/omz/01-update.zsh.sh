#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

CODE_PYTHON="${CODE_PYTHON:-0}"
CODE_RUST="${CODE_RUST:-0}"

APP_YAZI="${APP_YAZI:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

render_blocks() {
    cat << 'EOF'
function update-all-in-one() {
    # APT
    sudo apt-get update \
        && sudo apt-get upgrade -y \
        && sudo apt-get autoremove -y \
        && sudo apt-get clean

    # Homebrew
    brew update \
        && brew upgrade --greedy \
        && brew cleanup

    # Oh My Zsh
    omz update
EOF

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        cat << 'EOF'

    # tealdeer
    tldr --update || true
EOF
    fi

    if [[ $CODE_PYTHON == '1' ]]; then
        cat << 'EOF'

    # uv tools
    uv tool upgrade --all
EOF
    fi

    if [[ $CODE_RUST == '1' ]]; then
        cat << 'EOF'

    # Rust
    rustup update
EOF
    fi

    if [[ $APP_YAZI == '1' ]]; then
        cat << 'EOF'

    # Yazi
    ya pkg upgrade
EOF
    fi

    cat << 'EOF'
}
EOF
}

main() {
    mkdir -p "$ZSH_CUSTOM"
    render_blocks > "$ZSH_CUSTOM/01-update.zsh"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
