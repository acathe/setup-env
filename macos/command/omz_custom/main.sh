#!/usr/bin/env bash

set -euo pipefail

COMMAND_SSH="${COMMAND_SSH:-0}"

APP_VSCODE="${APP_VSCODE:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

download_plugin() {
    git clone 'https://github.com/Pilaton/OhMyZsh-full-autoupdate.git' \
        "$ZSH_CUSTOM/plugins/ohmyzsh-full-autoupdate"
    git clone 'https://github.com/zsh-users/zsh-autosuggestions' \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    git clone 'https://github.com/zsh-users/zsh-syntax-highlighting.git' \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
}

append_plugin() {
    local plugin="$1"
    sed -i '' "/^plugins=(/s/)/ $plugin)/" "$HOME/.zshrc"
}

install_plugin() {
    sed -i '' 's/^plugins=(.*)/plugins=(z sudo brew)/' "$HOME/.zshrc"

    [[ $COMMAND_SSH == '1' ]] && append_plugin 'ssh'
    [[ $APP_VSCODE == '1' ]] && append_plugin 'vscode'

    append_plugin 'ohmyzsh-full-autoupdate'
    append_plugin 'zsh-autosuggestions'
    append_plugin 'zsh-syntax-highlighting'
}

install_theme() {
    git clone --depth=1 'https://github.com/romkatv/powerlevel10k.git' \
        "$ZSH_CUSTOM/themes/powerlevel10k"

    sed -i '' 's|^ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
    brew install --cask 'font-meslo-for-powerlevel10k'
}

main() {
    if ! command -v git > /dev/null 2>&1; then
        echo 'git is not installed.' >&2
        return 1
    fi

    download_plugin
    install_plugin
    install_theme
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
