#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

CODE_PYTHON="${CODE_PYTHON:-0}"
CODE_RUST="${CODE_RUST:-0}"

APP_YAZI="${APP_YAZI:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_update() {
    local update="$1"
    install -m 644 "./plugins/update-all-in-one/custom/$update" \
        "$ZSH_CUSTOM/plugins/update-all-in-one/custom/$update"
}

main() {
    mkdir -p "$ZSH_CUSTOM/plugins/update-all-in-one/custom"

    install -m 644 './plugins/update-all-in-one/update-all-in-one.plugin.zsh' \
        "$ZSH_CUSTOM/plugins/update-all-in-one/update-all-in-one.plugin.zsh"
    install_update '00-apt.zsh'
    install_update '01-homebrew.zsh'
    [[ $COMMAND_MODERN_CLI == '1' ]] && install_update '02-tealdeer.zsh'
    [[ $CODE_PYTHON == '1' ]] && install_update '03-uv-tools.zsh'
    [[ $CODE_RUST == '1' ]] && install_update '04-rust.zsh'
    [[ $APP_YAZI == '1' ]] && install_update '05-yazi.zsh'
    install_update '06-oh-my-zsh.zsh'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
