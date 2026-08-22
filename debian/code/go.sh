#!/usr/bin/env bash

set -euo pipefail

install_go() {
    brew install go
}

set_env() {
    if [[ -s "$HOME/.zshenv" ]]; then
        echo >> "$HOME/.zshenv"
    fi

    {
        echo '# Go'
        echo 'export PATH="$HOME/go/bin:/home/linuxbrew/.linuxbrew/opt/go/bin:$PATH"'
    } >> "$HOME/.zshenv"
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    install_go
    set_env
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
