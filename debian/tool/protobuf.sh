#!/usr/bin/env bash

set -euo pipefail

get_protoc_latest() {
    curl -fsSIL -o /dev/null -w '%{url_effective}' 'https://github.com/protocolbuffers/protobuf/releases/latest' | sed -E 's#.*/tag/v?([^/]+)$#\1#'
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential clang-format unzip

    local version
    version="$(get_protoc_latest)"
    if [[ -z $version ]]; then
        echo "Failed to determine the latest protoc version." >&2
        return 1
    fi

    curl -fsSL "https://github.com/protocolbuffers/protobuf/releases/download/v$version/protoc-$version-linux-x86_64.zip" \
        -o "/tmp/protoc-$version-linux-x86_64.zip"
    unzip "/tmp/protoc-$version-linux-x86_64.zip" -d "$HOME/.local"
    rm -f "$HOME/.local/readme.txt"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
