#!/usr/bin/env bash

set -euo pipefail

UNATTENDED="${UNATTENDED:-0}"
CODE_RUST="${CODE_RUST:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --unattended)
                UNATTENDED=1
                shift
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

install_omz() {
    if [[ $UNATTENDED == '1' ]]; then
        sh -c "$(curl -fsSL 'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh')" '' --unattended
        sudo -n usermod -s "$(command -v zsh)" "$USER"
    else
        RUNZSH='no' sh -c "$(curl -fsSL 'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh')"
    fi

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
    sudo apt-get update
    sudo apt-get install -y zsh

    install_omz

    if [[ $CODE_RUST == '1' ]]; then
        install -Dm 644 './brew-rustup.plugin.zsh' \
            "$ZSH_CUSTOM/plugins/brew-rustup/brew-rustup.plugin.zsh"
    fi

    bash './plugin.sh' "$@"
    bash './setup-env.plugin.zsh.sh' "$@"
    bash './00-setup_env.zsh.sh' "$@"
    bash './01-update.zsh.sh' "$@"
    bash './99-first_run.zsh.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
