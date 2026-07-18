#!/usr/bin/env bash

set -euo pipefail

main() {
    if ! command -v curl > /dev/null 2>&1; then
        echo "curl is required to install Claude Code." >&2
        return 1
    fi

    curl -fsSL "https://claude.ai/install.sh" | bash
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
