#!/usr/bin/env bash

set -euo pipefail

main() {
    bash './00-setup_env.zsh.sh' "$@"
    bash './01-update.zsh.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
