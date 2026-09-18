#!/usr/bin/env bash

set -euo pipefail

COPILOT_API_CLAER_CONFIG="${COPILOT_API_CLAER_CONFIG:-0}"
COPILOT_API_ADD_API_KEY="${COPILOT_API_ADD_API_KEY:-}"
COPILOT_API_AUTH="${COPILOT_API_AUTH:-0}"
COPILOT_API_ADD_UPDATE_CONFIG="${COPILOT_API_ADD_UPDATE_CONFIG:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --clear-config)
                COPILOT_API_CLAER_CONFIG=1
                shift
                ;;
            --add-api-key)
                numOfArgs=1
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COPILOT_API_ADD_API_KEY="$2"
                    shift $((numOfArgs + 1))
                fi
                ;;
            --auth)
                COPILOT_API_AUTH=1
                shift
                ;;
            --add-update-config)
                COPILOT_API_ADD_UPDATE_CONFIG=1
                shift
                ;;
            *)
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

get_compose_file() {
    mkdir -p '/tmp/copilot-api'
    curl -fsSL 'https://raw.githubusercontent.com/caozhiyuan/copilot-api/dev/docker-compose.yaml' \
        -o '/tmp/copilot-api/docker-compose.yaml'
}

clear_config() {
    rm -f "$COPILOT_API_DATA_DIR/config.json"
}

add_api_key() {
    local api_key="$1"

    docker compose -f '/tmp/copilot-api/docker-compose.yaml' \
        run --rm 'copilot-api' --auth keys --add "$api_key"
}

auth() {
    docker compose -f '/tmp/copilot-api/docker-compose.yaml' \
        run --rm 'copilot-api' --auth login < /dev/tty
}

run() {
    export COPILOT_API_BIND='0.0.0.0'
    docker compose -f '/tmp/copilot-api/docker-compose.yaml' up -d
}

install_update() {
    install -Dm 644 './98-copilot-api.zsh' \
        "$ZSH_CUSTOM/plugins/update-all-in-one/custom/98-copilot-api.zsh"
}

main() {
    mkdir -p "$HOME/.copilot-data"
    export COPILOT_API_DATA_DIR="$HOME/.copilot-data"

    get_compose_file

    if [[ $COPILOT_API_CLAER_CONFIG == '1' ]]; then
        clear_config
    fi

    if [[ -n $COPILOT_API_ADD_API_KEY ]]; then
        add_api_key "$COPILOT_API_ADD_API_KEY"
    fi

    if [[ $COPILOT_API_AUTH == '1' ]]; then
        auth
    fi

    run

    if [[ $COPILOT_API_ADD_UPDATE_CONFIG == '1' ]]; then
        install_update
    fi

    return 0
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}"
    main "$@"
fi
