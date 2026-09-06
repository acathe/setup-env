#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo install -Dm 644 './90-ghostty-env.conf' \
        '/etc/ssh/sshd_config.d/90-ghostty-env.conf'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
