#!/usr/bin/env bash

set -euo pipefail

main() {
    if [[ -f "./terminal/zsh.sh" ]]; then
        bash "./terminal/zsh.sh" "$@"
    fi

    if [[ -f "./terminal/omz.sh" ]]; then
        bash "./terminal/omz.sh" "$@"
    fi

    if [[ -f "./app/docker.sh" ]]; then
        bash "./app/docker.sh" "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
