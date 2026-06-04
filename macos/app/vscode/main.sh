#!/usr/bin/env bash

set -euo pipefail

enable_omz_plugin() {
    if [[ ! -f "$HOME/.zshrc" ]]; then
        echo "oh-my-zsh is not installed." >&2
        return 1
    fi

    # Ref. https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vscode
    sed -i "" '/^plugins=(/s/)/ vscode)/' "$HOME/.zshrc"
}

main() {
    enable_omz_plugin
    brew bundle --file="./Brewfile"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
