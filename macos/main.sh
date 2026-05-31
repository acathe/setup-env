#!/usr/bin/env bash

set -euo pipefail

main() {
    if [[ ! -d "/Library/Developer/CommandLineTools" ]]; then
        xcode-select --install
    fi

    [[ -f "./terminal/homebrew.sh" ]] \
        && bash "./terminal/homebrew.sh" "$@"

    [[ -f "./terminal/omz.sh" ]] \
        && bash "./terminal/omz.sh" "$@"

    [[ -f "./brew_bundle/Brewfile" ]] \
        && eval "$(/opt/homebrew/bin/brew shellenv)" \
        && brew bundle --file="./brew_bundle/Brewfile"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
