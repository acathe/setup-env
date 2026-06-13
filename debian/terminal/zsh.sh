#!/usr/bin/env bash

set -euo pipefail

install_zsh() {
    sudo apt-get update
    sudo apt-get install -y zsh
}

sync_etc_profile() {
    local tmpfile
    tmpfile="$(mktemp)"

    {
        echo "# Sync /etc/profile."
        echo 'emulate sh -c "source /etc/profile"'
        echo ""
        cat "/etc/zsh/zprofile"
    } > "$tmpfile"

    sudo cp "$tmpfile" "/etc/zsh/zprofile"
}

main() {
    install_zsh
    sync_etc_profile
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
