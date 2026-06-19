#!/usr/bin/env bash

set -euo pipefail

get_go_version() {
    curl -fsSL 'https://go.dev/dl/?mode=json' | grep -o 'go.*.linux-amd64.tar.gz' | head -n 1 | tr -d '\r\n'
}

install_go() {
    local go_version
    go_version="$(get_go_version)"

    curl -fsSL "https://go.dev/dl/$go_version" -o "/tmp/$go_version"
    sudo tar -C "/usr/local" -xzf "/tmp/$go_version"
}

config_zsh() {
    if [[ -s "$HOME/.zshrc" ]]; then
        echo >> "$HOME/.zshrc"
    fi

    {
        echo '# Go'
        echo 'export PATH="$PATH:/usr/local/go/bin"'
        echo 'export PATH="$HOME/go/bin:$PATH"'
    } >> "$HOME/.zshrc"

    sed -i '/^plugins=(/s/)/ golang)/' "$HOME/.zshrc"
}

main() {
    install_go
    config_zsh
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
