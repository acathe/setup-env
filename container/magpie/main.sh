#!/usr/bin/env bash

set -euo pipefail

MAGPIE_ADD_UPDATE_CONFIG="${MAGPIE_ADD_UPDATE_CONFIG:-0}"
MAGPIE_SCRIPT_DIR="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --add-update-config)
                MAGPIE_ADD_UPDATE_CONFIG=1
                shift
                ;;
            *)
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

run() {
    local container_id container_env env_value web_key=""
    container_id="$(docker ps -aq --filter 'name=^/magpie$')" || return

    if [[ -n $container_id ]]; then
        container_env="$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$container_id")" || return
        while IFS= read -r env_value; do
            if [[ $env_value == MAGPIE_WEB_KEY=* ]]; then
                web_key="${env_value#MAGPIE_WEB_KEY=}"
                break
            fi
        done <<< "$container_env"
    fi

    if [[ -z $web_key ]]; then
        web_key="$(openssl rand -hex 16)" || return
    fi

    docker pull 'ghcr.io/yetone/magpie:latest' || return
    if [[ -n $container_id ]]; then
        docker rm -f "$container_id" || return
    fi

    docker run -d \
        --name magpie \
        --restart unless-stopped \
        -p 127.0.0.1:3425:3425 \
        -p 192.168.80.200:3425:3425 \
        -p 192.168.80.200:3430:3430 \
        -e MAGPIE_PUBLIC_URL="http://192.168.80.200:3425" \
        -e MAGPIE_WEB_KEY="$web_key" \
        -v magpie-config:/config \
        ghcr.io/yetone/magpie:latest \
        web --addr 0.0.0.0:3430 --no-open
}

install_update() {
    local zsh_custom="${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}"
    install -Dm 644 "$MAGPIE_SCRIPT_DIR/98-magpie.zsh" \
        "$zsh_custom/plugins/update-all-in-one/custom/98-magpie.zsh"
}

main() {
    run || return
    if [[ $MAGPIE_ADD_UPDATE_CONFIG == 1 ]]; then
        install_update
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$MAGPIE_SCRIPT_DIR"
    parse_args "$@"
    set -- "${POSITIONAL[@]}"
    main "$@"
fi
