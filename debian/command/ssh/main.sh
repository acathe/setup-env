#!/usr/bin/env bash

set -euo pipefail

APP_GHOSTTY="${APP_GHOSTTY:-0}"

main() {
    if [[ $APP_GHOSTTY == '1' ]]; then
        sudo install -Dm 644 './90-ghostty-env.conf' \
            '/etc/ssh/sshd_config.d/90-ghostty-env.conf'
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
