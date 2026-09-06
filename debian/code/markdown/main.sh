#!/usr/bin/env bash

set -euo pipefail

main() {
    brew install -q 'glow' 'markdownlint-cli'

    install -Dm 644 './glow.yml' "$HOME/.config/glow/glow.yml"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
