#!/usr/bin/env bash

set -euo pipefail

get_go_latest() {
    curl -fsSL 'https://go.dev/dl/?mode=json' | grep -o 'go.*.linux-amd64.tar.gz' | head -n 1 | tr -d '\r\n'
}

install_go() {
    local version
    version="$(get_go_latest)"
    if [[ -z $version ]]; then
        echo "Failed to determine the latest Go version." >&2
        return 1
    fi

    curl -fsSL "https://go.dev/dl/$version" -o "/tmp/$version"
    sudo tar -C "/usr/local" -xzf "/tmp/$version"
}

setup_env() {
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
    sudo apt-get update
    sudo apt-get install -y build-essential

    install_go
    setup_env
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
