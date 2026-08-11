#!/usr/bin/env bash

set -euo pipefail

main() {
    if command -v brew > /dev/null 2>&1; then
        echo 'Homebrew is already installed.'
        return 0
    fi

    if ! command -v curl > /dev/null 2>&1; then
        echo 'curl is not installed.' >&2
        return 1
    fi

    # Ref. https://brew.sh/zh-cn/
    /bin/bash -c "$(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh')"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
