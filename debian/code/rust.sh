#!/usr/bin/env bash

set -euo pipefail

install_rust() {
    brew install 'rustup'
    rustup default stable
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    install_rust
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
