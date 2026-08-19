#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

render_blocks() {
    cat << 'EOF'
function update-all-in-one() {
    # Homebrew
    brew update
    brew upgrade --greedy
    brew cleanup

    # Oh My Zsh
    omz update
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
