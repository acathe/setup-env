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

main() {
    if ! command -v docker > /dev/null 2>&1; then
        echo 'Docker is required to deploy copilot-api.' >&2
        return 1
    fi

    if ! command -v curl > /dev/null 2>&1; then
        echo 'curl is required to determine the latest copilot-api version.' >&2
        return 1
    fi

    local version
    version="$(get_copilot_api_latest)"
    if [[ -z $version ]]; then
        echo 'Failed to determine the latest copilot-api version.' >&2
        return 1
    fi

    docker build \
        -t "copilot-api:$version" \
        "https://github.com/caozhiyuan/copilot-api.git#v$version" >&2

    if [[ $COPILOT_API_AUTH == '1' ]]; then
        mkdir -p "$HOME/.copilot-api"
        chmod 700 "$HOME/.copilot-api"

        docker run \
            --rm \
            -it \
            -v "$HOME/.copilot-api:/root/.local/share/copilot-api" \
            "copilot-api:$version" \
            --auth
    fi

    if docker container inspect 'copilot-api' > /dev/null 2>&1; then
        docker rm -f 'copilot-api'
    fi

    docker run \
        -d \
        --name 'copilot-api' \
        --restart unless-stopped \
        -p 4141:4141 \
        -v "$HOME/.copilot-api:/root/.local/share/copilot-api" \
        "copilot-api:$version"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
