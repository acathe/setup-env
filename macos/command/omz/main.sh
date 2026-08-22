#!/usr/bin/env bash

set -euo pipefail

install_omz() {
    # Use `RUNZSH='no'` to skip running Zsh and prevent interrupting the script.
    # Ref. https://ohmyz.sh/#install
    RUNZSH='no' sh -c "$(curl -fsSL 'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh')"

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
}

main() {
    install_omz
    bash './install_plugin.sh' "$@"
    bash './plugin.sh' "$@"
    bash './custom.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
