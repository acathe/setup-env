#!/usr/bin/env bash

set -euo pipefail

main() {
    curl -fsSL -o "$HOME/Downloads/VS Code Dark Plus.terminal" \
        'https://raw.githubusercontent.com/lysyi3m/macos-terminal-themes/refs/heads/master/themes/VS%20Code%20Dark%20Plus.terminal'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
