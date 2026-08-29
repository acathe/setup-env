#!/usr/bin/env bash

set -euo pipefail

COPILOT_API_AUTH="${COPILOT_API_AUTH:-0}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

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
    local version="$1"
    if [[ -z $version ]]; then
        echo 'Version is required to build copilot-api image.' >&2
        return 1
    fi

    docker build \
        -t "copilot-api:$version" \
        "https://github.com/caozhiyuan/copilot-api.git#v$version" >&2
}

auth() {
    local image="$1"
    if [[ -z $image ]]; then
        echo 'Image is required to auth copilot-api.' >&2
        return 1
    fi

    sudo install -d -m 700 -o root -g root "$HOME/.copilot-api"
    docker run \
        --rm \
        -it \
        -v "$HOME/.copilot-api:/root/.local/share/copilot-api" \
        "$image" \
        --auth < /dev/tty
}

run_container() {
    local image="$1"
    if [[ -z $image ]]; then
        echo 'Image is required to run copilot-api container.' >&2
        return 1
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
        "$image"
}

install_update() {
    mkdir -p "$ZSH_CUSTOM/plugins/update-all-in-one/custom"
    install -m 644 './98-copilot-api.zsh' \
        "$ZSH_CUSTOM/plugins/update-all-in-one/custom/98-copilot-api.zsh"
}

main() {
    if ! command -v docker > /dev/null 2>&1; then
        echo 'docker and curl are required to deploy copilot-api.' >&2
        return 1
    fi

    local version
    version="$(get_copilot_api_latest)"

    build_image "$version"

    if [[ $COPILOT_API_AUTH == '1' ]]; then
        auth "copilot-api:$version"
    fi

    run_container "copilot-api:$version"
    install_update
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
