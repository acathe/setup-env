#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y \
        man-db \
        jq \
        unzip \
        atuin \
        eza \
        fzf \
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
    bash './fdfind.sh' "$@"
    bash './micro/main.sh' "$@"
    bash './tldr.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
