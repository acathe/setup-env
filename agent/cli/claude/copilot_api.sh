#!/usr/bin/env bash

set -euo pipefail

CLI_COPILOT_API_HOST="${CLI_COPILOT_API_HOST:-"localhost"}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --cli-copilot-api-host)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    CLI_COPILOT_API_HOST="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

backup() {
    local config_file="$1"

    if [[ ! -e $config_file ]]; then
        return
    fi

    local backup_file
    backup_file="$config_file.backup.$(date -u +%Y%m%dT%H%M%SZ).$$"
    cp -p "$config_file" "$backup_file"

    echo "Backed up $config_file to $backup_file"
}

render_config() {
    local host="$1"

    cp './copilot_api.tmpl.json' './copilot_api.json'

    sed "s/{{COPILOT_API_HOST}}/$host/g" './copilot_api.json' > './copilot_api.json.tmp' \
        && mv './copilot_api.json.tmp' './copilot_api.json'
}

main() {
    local config_dir="$HOME/.claude"
    mkdir -p "$config_dir"
    chmod 700 "$config_dir"

    local config_file="$config_dir/settings.json"
    backup "$config_file"

    render_config "$CLI_COPILOT_API_HOST"

    mv './copilot_api.json' "$config_file"
    chmod 600 "$config_file"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
