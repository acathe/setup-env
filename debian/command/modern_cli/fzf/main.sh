#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y fzf

    install -Dm 644 './fzfrc' "$HOME/.config/fzf/fzfrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
