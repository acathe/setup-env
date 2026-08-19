#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y \
        atuin \
        eza \
        fzf \
        ripgrep \
        zoxide \
        hyperfine \
        btop

    bash './bat/main.sh' "$@"
    bash './fdfind.sh' "$@"
    bash './micro/main.sh' "$@"
    bash './tldr.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
