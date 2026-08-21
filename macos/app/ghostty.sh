#!/usr/bin/env bash

set -euo pipefail

main() {
    brew install --cask 'ghostty'

    mkdir -p "$HOME/.config/ghostty"
    install -m 644 './config.ghostty' "$HOME/.config/ghostty/config.ghostty"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
