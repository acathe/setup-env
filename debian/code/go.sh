#!/usr/bin/env bash

set -euo pipefail

install_go() {
    brew install go
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    install_go
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
