#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y \
        jq \
        unzip \
        glow \
        ripgrep \
        zoxide \
        hyperfine \
        sd \
        btop \
        du-dust \
        duf \
        procs

    bash './bat/main.sh' "$@"
    bash './choose.sh' "$@"
    bash './eza.sh' "$@"
    bash './fdfind.sh' "$@"
    bash './fzf.sh' "$@"
    bash './micro/main.sh' "$@"
    bash './tldr.sh' "$@"
    bash './yazi.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
