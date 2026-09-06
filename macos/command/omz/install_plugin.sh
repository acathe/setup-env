#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_community_plugin() {
    local repo="$1" plugin="$2"
    git clone -q "https://github.com/$repo" "$ZSH_CUSTOM/plugins/$plugin"
}

main() {
    mkdir -p "$ZSH_CUSTOM/plugins"

    install_community_plugin 'Pilaton/OhMyZsh-full-autoupdate' 'ohmyzsh-full-autoupdate'
    install_community_plugin 'MichaelAquilina/zsh-you-should-use' 'you-should-use'
    install_community_plugin 'zsh-users/zsh-autosuggestions' 'zsh-autosuggestions'
    install_community_plugin 'zsh-users/zsh-syntax-highlighting' 'zsh-syntax-highlighting'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
