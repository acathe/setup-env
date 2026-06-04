#!/usr/bin/env bash

set -euo pipefail

main() {
    bash "./terminal/zsh.sh" "$@"
    bash "./terminal/omz.sh" "$@"
    bash "./app/docker.sh" "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
