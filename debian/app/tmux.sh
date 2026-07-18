#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt update
    sudo apt install -y tmux

    {
        echo '# Mouse support (optional)'
        echo 'set -g mouse on'
        echo
        echo '# Faster key response'
        echo 'set -sg escape-time 10'
    } > "$HOME/.tmux.conf"

    sed -i '/^plugins=(/s/)/ tmux)/' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
