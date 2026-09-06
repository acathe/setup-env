#!/usr/bin/env bash

set -euo pipefail

main() {
    brew install -q 'shfmt' 'shellcheck'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
