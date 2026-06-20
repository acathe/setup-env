#!/usr/bin/env bash

set -euo pipefail

main() {
    git config --global core.editor "code --wait"

    sed -i '/^plugins=(/s/)/ vscode)/' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
