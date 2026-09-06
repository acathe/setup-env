#!/usr/bin/env bash

set -euo pipefail

main() {
    brew install -q 'rustup'
    rustup -q default stable
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
