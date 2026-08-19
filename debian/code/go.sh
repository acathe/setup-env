#!/usr/bin/env bash

set -euo pipefail

get_go_latest() {
    curl -fsSL 'https://go.dev/dl/?mode=json' \
        | jq -r 'first(.[] | select(.stable)).files[]
                 | select(.os == "linux" and .arch == "amd64" and .kind == "archive")
                 | .filename' \
        | head -n 1
}

install_go() {
    if ! command -v jq > /dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y jq
    fi

    local version
    version="$(get_go_latest)"
    if [[ -z $version ]]; then
        echo 'Failed to determine the latest Go version.' >&2
        return 1
    fi

    local tmp
    tmp="$(mktemp)"
    curl -fsSL "https://go.dev/dl/$version" -o "$tmp"
    sudo tar -C '/usr/local' -xzf "$tmp"
}

set_env() {
    if [[ -s "$HOME/.zshenv" ]]; then
        echo >> "$HOME/.zshenv"
    fi

    {
        echo '# Go'
        echo 'export PATH="$PATH:/usr/local/go/bin"'
        echo 'export PATH="$HOME/go/bin:$PATH"'
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
