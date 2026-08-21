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
    if ! command -v curl > /dev/null 2>&1; then
        echo 'curl is not installed.' >&2
        return 1
    fi

    install_omz
    bash './plugin.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
