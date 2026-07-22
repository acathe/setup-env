#!/usr/bin/env bash

set -euo pipefail

APP_VSCODE="${APP_VSCODE:-0}"

main() {
    sudo apt-get update
    sudo apt-get install -y micro

    micro -plugin install detectindent
    micro -plugin install filemanager

    mkdir -p "$HOME/.config/micro"
    cp ./settings.json "$HOME/.config/micro/settings.json"

    {
        echo ''
        echo '# Editor'
        echo 'export EDITOR=micro'
        if [[ $APP_VSCODE == "1" ]]; then
            echo 'if [[ "$TERM_PROGRAM" == "vscode" ]]; then'
            echo '  export EDITOR="code --wait"'
            echo 'fi'
        fi
        echo 'export VISUAL="$EDITOR"'
    } >> "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
