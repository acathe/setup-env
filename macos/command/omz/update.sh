#!/usr/bin/env bash

set -euo pipefail

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
    install_update '00-homebrew.zsh'
    install_update '01-oh-my-zsh.zsh'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
