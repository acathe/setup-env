#!/usr/bin/env bash

set -euo pipefail

main() {
    bash './setup-env.plugin.zsh.sh' "$@"
    bash './00-setup_env.zsh.sh' "$@"
    bash './01-update.zsh.sh' "$@"
    bash './99-first_run.zsh.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
