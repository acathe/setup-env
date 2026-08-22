#!/usr/bin/env bash

set -euo pipefail

APP_VSCODE="${APP_VSCODE:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_custom() {
    local filename="$1"
    install -m 644 "./custom/$filename" "$ZSH_CUSTOM/$filename"
}

main() {
    [[ $APP_VSCODE == '1' ]] && install_custom '00-vscode.zsh'
    install_custom '01-zsh-autosuggestions.zsh'
    install_custom '02-zsh-syntax-highlighting.zsh'
    install_custom '03-you-should-use.zsh'
    install_custom '04-z.zsh'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
