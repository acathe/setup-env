#!/usr/bin/env bash

set -euo pipefail

install_homebrew() {
    if command -v brew > /dev/null 2>&1; then
        echo "Homebrew is already installed."
        return 0
    fi

    if ! command -v curl > /dev/null 2>&1; then
        echo "curl is not installed." >&2
        return 1
    fi

    # Ref. https://brew.sh/zh-cn/
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

set_env() {
    if [[ ! -d "/opt/homebrew" ]]; then
        echo "Homebrew is not installed." >&2
        return 1
    fi

    if [[ -s "$HOME/.zprofile" ]]; then
        echo >> "$HOME/.zprofile"
    fi

    {
        echo "# Homebrew"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    } >> "$HOME/.zprofile"
}

main() {
    install_homebrew
    set_env
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
