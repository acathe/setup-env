#!/usr/bin/env bash

set -euo pipefail

install_omz() {
    RUNZSH='no' sh -c "$(curl -fsSL 'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh')"

    sed -i '\|^# export PATH=$HOME/bin|s/^# //' "$HOME/.zshrc"

    if [[ -s "$HOME/.zshrc.pre-oh-my-zsh" ]]; then
        local tmpfile
        tmpfile="$(mktemp)"
        cp "$HOME/.zshrc" "$tmpfile"

        {
            cat "$HOME/.zshrc.pre-oh-my-zsh"
            echo
            cat "$tmpfile"
        } > "$HOME/.zshrc"
    fi

    rm -f "$HOME/.zshrc.pre-oh-my-zsh"
    rm -f "$HOME/.shell.pre-oh-my-zsh"
    rm -f "$HOME/.profile"
    rm -f "$HOME/.bashrc"
    rm -f "$HOME/.bash_logout"
}

main() {
    sudo apt-get -qq update
    sudo apt-get -qq install zsh

    install_omz

    bash './install_plugin.sh' "$@"
    bash './update.sh' "$@"
    bash './plugin.sh' "$@"
    bash './custom.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
