#!/usr/bin/env bash

set -euo pipefail

APP_CLAUDE_BASE_URL="${APP_CLAUDE_BASE_URL:-http://localhost:4141}"
APP_CLAUDE_AUTH_TOKEN="${APP_CLAUDE_AUTH_TOKEN:-dummy}"
APP_CLAUDE_DEFAULT_OPUS_MODEL="${APP_CLAUDE_DEFAULT_OPUS_MODEL:-}"
APP_CLAUDE_DEFAULT_SONNET_MODEL="${APP_CLAUDE_DEFAULT_SONNET_MODEL:-}"
APP_CLAUDE_DEFAULT_HAIKU_MODEL="${APP_CLAUDE_DEFAULT_HAIKU_MODEL:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --app-claude-base-url)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_CLAUDE_BASE_URL="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-claude-auth-token)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_CLAUDE_AUTH_TOKEN="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-claude-default-opus-model)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_CLAUDE_DEFAULT_OPUS_MODEL="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-claude-default-sonnet-model)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_CLAUDE_DEFAULT_SONNET_MODEL="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-claude-default-haiku-model)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_CLAUDE_DEFAULT_HAIKU_MODEL="$2"
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

check_model() {
    local model_id="$1"

    if [[ -z $model_id ]]; then
        return 1
    fi

    local body ids
    body="$(curl -fsS "$APP_CLAUDE_BASE_URL/v1/models")"
    ids="$(jq -r '.data[].claude_model_id' <<< "$body")"
    grep -Fxq -- "$model_id" <<< "$ids"
}

install_settings() {
    mkdir -p "$HOME/.claude"
    chmod 700 "$HOME/.claude"

    jq --arg ANTHROPIC_BASE_URL "$APP_CLAUDE_BASE_URL" \
        --arg ANTHROPIC_AUTH_TOKEN "$APP_CLAUDE_AUTH_TOKEN" \
        --arg ANTHROPIC_DEFAULT_OPUS_MODEL "$APP_CLAUDE_DEFAULT_OPUS_MODEL" \
        --arg ANTHROPIC_DEFAULT_SONNET_MODEL "$APP_CLAUDE_DEFAULT_SONNET_MODEL" \
        --arg ANTHROPIC_DEFAULT_HAIKU_MODEL "$APP_CLAUDE_DEFAULT_HAIKU_MODEL" \
        '.env += $ARGS.named' \
        './settings.json' > "$HOME/.claude/settings.json"

    chmod 600 "$HOME/.claude/settings.json"
}

install_plugins() {
    if ! command -v node > /dev/null 2>&1; then
        curl -fsSL 'https://deb.nodesource.com/setup_lts.x' | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    export PATH="$HOME/.local/bin:$PATH"

    claude plugin marketplace add 'https://github.com/caozhiyuan/copilot-api.git'
    claude plugin install 'agent-inject@copilot-api-marketplace'
    claude plugin install 'tool-search@copilot-api-marketplace'
}

main() {
    if ! command -v jq > /dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y jq
    fi

    if ! check_model "$APP_CLAUDE_DEFAULT_OPUS_MODEL" \
        || ! check_model "$APP_CLAUDE_DEFAULT_SONNET_MODEL" \
        || ! check_model "$APP_CLAUDE_DEFAULT_HAIKU_MODEL"; then

        echo "Models not found in copilot-api /v1/models response." >&2
        return 1
    fi

    install_settings
    install_plugins
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
