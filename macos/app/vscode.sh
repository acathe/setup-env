#!/usr/bin/env bash

set -euo pipefail

main() {
    brew install -q --cask 'visual-studio-code'
    brew install -q --cask 'font-jetbrains-maple-mono'
    brew install -q --cask 'font-jetbrains-mono-nerd-font'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
