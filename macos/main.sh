#!/usr/bin/env bash

set -euo pipefail

main() {
    if [[ ! -d "/Library/Developer/CommandLineTools" ]]; then
        xcode-select --install
    fi

    if [[ -f "./terminal/homebrew.sh" ]]; then
        bash "./terminal/homebrew.sh" "$@"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if [[ -f "./terminal/omz.sh" ]]; then
        bash "./terminal/omz.sh" "$@"
    fi

    if [[ -f "./app/Brewfile" ]]; then
        brew bundle --file="./app/Brewfile"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
