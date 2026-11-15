#!/usr/bin/env bash

set -euo pipefail

main() {
    docker run -d \
        --name magpie \
        --restart unless-stopped \
        -p 127.0.0.1:3425:3425 \
        -p 192.168.80.200:3425:3425 \
        -p 192.168.80.200:3430:3430 \
        -e MAGPIE_PUBLIC_URL="http://192.168.80.200:3425" \
        -e MAGPIE_WEB_KEY="$(openssl rand -hex 16)" \
        -v magpie-config:/config \
        ghcr.io/yetone/magpie:latest \
        web --addr 0.0.0.0:3430 --no-open
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
