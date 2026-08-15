#!/usr/bin/env bash

set -euo pipefail

main() {
    if ! command -v docker > /dev/null 2>&1; then
        echo 'Docker is not installed.' >&2
        return 1
    fi

    docker build \
        -t 'copilot-api-config:latest' \
        '.'

    docker run \
        --rm \
        -v "$HOME/.copilot-api:/root/.copilot-api" \
        'copilot-api-config:latest'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
