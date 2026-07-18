#!/usr/bin/env bash

set -euo pipefail

COPILOT_API_AUTH="${COPILOT_API_AUTH:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --copilot-api-auth)
                COPILOT_API_AUTH=1
                shift
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

get_copilot_api_latest() {
    curl -fsSIL -o /dev/null -w '%{url_effective}' 'https://github.com/caozhiyuan/copilot-api/releases/latest' | sed -E 's#.*/tag/v?([^/]+)$#\1#'
}

build_image() {
    local version
    version="$(get_copilot_api_latest)"
    if [[ -z $version ]]; then
        echo "Failed to determine the latest copilot-api version." >&2
        return 1
    fi

    local image_name="copilot-api:$version"
    docker build \
        -t "$image_name" \
        "https://github.com/caozhiyuan/copilot-api.git#v$version" >&2

    echo "$image_name"
}

auth() {
    local image="$1"
    local data_dir="$2"

    mkdir -p "$data_dir"
    chmod 700 "$data_dir"

    docker run \
        --rm \
        -it \
        -v "$data_dir:/root/.local/share/copilot-api" \
        "$image" \
        --auth
}

main() {
    if ! command -v docker > /dev/null 2>&1; then
        echo "Docker is required to deploy copilot-api." >&2
        return 1
    fi

    if ! command -v curl > /dev/null 2>&1; then
        echo "curl is required to determine the latest copilot-api version." >&2
        return 1
    fi

    local image
    image="$(build_image)"

    local data_dir="$HOME/.copilot-api"

    if [[ $COPILOT_API_AUTH == "1" ]]; then
        auth "$image" "$data_dir"
    fi

    local container="copilot-api"

    if docker container inspect "$container" > /dev/null 2>&1; then
        docker rm -f "$container"
    fi

    docker run \
        -d \
        --name "$container" \
        --restart unless-stopped \
        -p 4141:4141 \
        -v "$data_dir:/root/.local/share/copilot-api" \
        "$image"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
