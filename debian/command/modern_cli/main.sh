#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y \
        jq \
        unzip \
        glow \
        eza \
        ripgrep \
        zoxide \
        hyperfine \
        sd \
        btop \
        du-dust \
        duf \
        procs

    bash './atuin/main.sh' "$@"
    bash './bat/main.sh' "$@"
    bash './choose.sh' "$@"
    bash './fdfind.sh' "$@"
    bash './fzf/main.sh' "$@"
    bash './micro/main.sh' "$@"
    bash './tldr.sh' "$@"
    bash './yazi/main.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
