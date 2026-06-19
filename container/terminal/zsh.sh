#!/usr/bin/env bash

set -euo pipefail

sync_etc_profile() {
    local tmpfile
    tmpfile="$(mktemp)"

    {
        echo '# Sync /etc/profile'
        echo 'emulate sh -c "source /etc/profile"'
        echo ""
        cat "/etc/zsh/zprofile"
    } > "$tmpfile"

    sudo cp "$tmpfile" "/etc/zsh/zprofile"
}

install_build_essential() {
    sudo apt-get update
    sudo apt-get install -y zsh
}

main() {
    sync_etc_profile
    install_build_essential
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
