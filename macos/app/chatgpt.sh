#!/usr/bin/env bash

set -euo pipefail

main() {
    brew install -q --cask 'chatgpt'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
