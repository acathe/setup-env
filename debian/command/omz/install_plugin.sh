#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

CODE_RUST="${CODE_RUST:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_community_plugin() {
    local repo="$1" plugin="$2"
    git clone "https://github.com/$repo" "$ZSH_CUSTOM/plugins/$plugin"
}

install_custom_plugin() {
    local plugin="$1"
    cp -R "./plugins/$plugin" "$ZSH_CUSTOM/plugins/"
}

main() {
    mkdir -p "$ZSH_CUSTOM/plugins"

    install_community_plugin 'Pilaton/OhMyZsh-full-autoupdate' 'ohmyzsh-full-autoupdate'
    install_community_plugin 'MichaelAquilina/zsh-you-should-use' 'you-should-use'
    install_community_plugin 'zsh-users/zsh-autosuggestions' 'zsh-autosuggestions'
    install_community_plugin 'zsh-users/zsh-syntax-highlighting' 'zsh-syntax-highlighting'
    [[ $COMMAND_MODERN_CLI == '1' ]] && install_community_plugin 'Aloxaf/fzf-tab' 'fzf-tab'

    [[ $CODE_RUST == '1' ]] && install_custom_plugin 'brew-rustup'
    [[ $COMMAND_MODERN_CLI == '1' ]] && install_custom_plugin 'pre-eza'

    return 0
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
