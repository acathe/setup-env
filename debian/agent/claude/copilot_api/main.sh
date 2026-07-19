#!/usr/bin/env bash

set -euo pipefail

AGENT_CLAUDE_ANTHROPIC_BASE_URL="${AGENT_CLAUDE_ANTHROPIC_BASE_URL:-"http://localhost:4141"}"
AGENT_CLAUDE_ANTHROPIC_AUTH_TOKEN="${AGENT_CLAUDE_ANTHROPIC_AUTH_TOKEN:-"dummy"}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --agent-claude-anthropic-base-url)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    AGENT_CLAUDE_ANTHROPIC_BASE_URL="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --agent-claude-anthropic-auth-token)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    AGENT_CLAUDE_ANTHROPIC_AUTH_TOKEN="$2"
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

fetch_model() {
    local family="$1"

    local body ids
    body="$(curl -fsS "$AGENT_CLAUDE_ANTHROPIC_BASE_URL/v1/models")"
    ids="$(jq -r '.data[].claude_model_id' <<< "$body")"

    local model
    model="$(grep -E "^claude-$family-.*\[1m\]$" <<< "$ids" | sort -V | tail -n1)"

    if [[ -z $model ]]; then
        model="$(grep -E "^claude-$family-" <<< "$ids" | sort -V | tail -n1)"
    fi

    if [[ -z $model ]]; then
        echo "No '$family' model found in copilot-api /v1/models response." >&2
        return 1
    fi

    echo "$model"
}

render_config() {
    local opus="$1" sonnet="$2" haiku="$3"

    jq --arg base_url "$AGENT_CLAUDE_ANTHROPIC_BASE_URL" \
        --arg token "$AGENT_CLAUDE_ANTHROPIC_AUTH_TOKEN" \
        --arg opus "$opus" \
        --arg sonnet "$sonnet" \
        --arg haiku "$haiku" \
        '.env += {
            ANTHROPIC_BASE_URL: $base_url,
            ANTHROPIC_AUTH_TOKEN: $token,
            ANTHROPIC_DEFAULT_OPUS_MODEL: $opus,
            ANTHROPIC_DEFAULT_SONNET_MODEL: $sonnet,
            ANTHROPIC_DEFAULT_HAIKU_MODEL: $haiku
        }' \
        './settings.json' > "$HOME/.claude/settings.json"
}

install_plugins() {
    if ! command -v claude > /dev/null 2>&1; then
        echo "claude not found; cannot install copilot-api plugins." >&2
        return 1
    fi

    claude plugin marketplace add "https://github.com/caozhiyuan/copilot-api.git"
    claude plugin install "agent-inject@copilot-api-marketplace"
}

main() {
    if ! command -v jq > /dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y jq
    fi

    mkdir -p "$HOME/.claude"
    chmod 700 "$HOME/.claude"

    local opus sonnet haiku
    opus="$(fetch_model opus)"
    sonnet="$(fetch_model sonnet)"
    haiku="$(fetch_model haiku)"

    render_config "$opus" "$sonnet" "$haiku"
    chmod 600 "$HOME/.claude/settings.json"

    install_plugins
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
