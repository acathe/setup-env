#!/usr/bin/env bash

set -euo pipefail

main() {
    xargs -L 1 code --force --install-extension < "./extensions.txt"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
