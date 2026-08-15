#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y fzf
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
