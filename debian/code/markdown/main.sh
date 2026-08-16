#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    sudo apt-get install -y glow markdownlint

    install -Dm 644 './glow.yml' "$HOME/.config/glow/glow.yml"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
