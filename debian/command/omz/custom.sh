#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

CODE_GO="${CODE_GO:-0}"
CODE_PROTOBUF="${CODE_PROTOBUF:-0}"

APP_DOCKER="${APP_DOCKER:-0}"
APP_GIT="${APP_GIT:-0}"
APP_INCUS="${APP_INCUS:-0}"
APP_VSCODE="${APP_VSCODE:-0}"
APP_YAZI="${APP_YAZI:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_custom() {
    local filename="$1"
    install -m 644 "./custom/$filename" "$ZSH_CUSTOM/$filename"
}

main() {
    [[ $COMMAND_MODERN_CLI != '1' ]] && install_custom '00-nanom.zsh'
    [[ $COMMAND_MODERN_CLI == '1' ]] && install_custom '01-micro.zsh'
    [[ $APP_VSCODE == '1' ]] && install_custom '02-vscode.zsh'
    [[ $CODE_GO == '1' ]] && install_custom '03-go.zsh'
    [[ $CODE_PROTOBUF == '1' ]] && install_custom '04-clang-format.zsh'

    install_custom '05-zsh-autosuggestions.zsh'
    install_custom '06-zsh-syntax-highlighting.zsh'
    install_custom '07-you-should-use.zsh'

    [[ $COMMAND_MODERN_CLI != '1' ]] && install_custom '08-z.zsh'
    [[ $COMMAND_MODERN_CLI == '1' ]] && install_custom '09-atuin.zsh'
    [[ $COMMAND_MODERN_CLI == '1' ]] && install_custom '10-eza.zsh'
    [[ $COMMAND_MODERN_CLI == '1' ]] && install_custom '11-fzf.zsh'
    [[ $COMMAND_MODERN_CLI == '1' ]] && install_custom '12-fzf-tab.zsh'
    [[ $APP_DOCKER == '1' ]] && install_custom '13-docker.zsh'
    [[ $APP_GIT == '1' ]] && install_custom '14-git.zsh'
    [[ $APP_YAZI == '1' ]] && install_custom '15-yazi.zsh'
    [[ $APP_INCUS == '1' ]] && install_custom '98-incus-init.zsh'
    [[ $APP_GIT == '1' ]] && install_custom '99-gh-login.zsh'

    return 0
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
