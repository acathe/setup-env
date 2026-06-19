#!/usr/bin/env bash

set -euo pipefail

get_protoc_version() {
    curl -fsSIL -o /dev/null -w '%{url_effective}' 'https://github.com/protocolbuffers/protobuf/releases/latest' | sed -E 's#.*/tag/v?([^/]+)$#\1#'
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential clang-format unzip

    local protoc_version
    protoc_version="$(get_protoc_version)"

    curl -fsSL "https://github.com/protocolbuffers/protobuf/releases/download/v${protoc_version}/protoc-${protoc_version}-linux-x86_64.zip" \
        -o "/tmp/protoc-${protoc_version}-linux-x86_64.zip"
    unzip "/tmp/protoc-${protoc_version}-linux-x86_64.zip" -d "$HOME/.local"
    rm -f "$HOME/.local/readme.txt"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
