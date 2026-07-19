#!/usr/bin/env bash

set -euo pipefail

AGENT_CLAUDE_COPILOT_API="${AGENT_CLAUDE_COPILOT_API:-0}"
AGENT_CLAUDE_COPILOT_API_HOST="${AGENT_CLAUDE_COPILOT_API_HOST:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --agent-claude-copilot-api)
                AGENT_CLAUDE_COPILOT_API=1
                shift # shift once since flags have no values
                ;;
            --agent-claude-copilot-api-host)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    AGENT_CLAUDE_COPILOT_API_HOST="$2"
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

install_claude_code() {
    if ! command -v curl > /dev/null 2>&1; then
        echo "curl is required to install Claude Code." >&2
        return 1
    fi

    curl -fsSL "https://claude.ai/install.sh" | bash
}

detect_host() {
    local host=""

    # Primary source IP toward the internet, i.e. the host's LAN IP when run on
    # the host itself. Inside a build/container this yields the container's own
    # IP, so pass --agent-claude-copilot-api-host in that case.
    if command -v ip > /dev/null 2>&1; then
        host="$(ip route get 1.1.1.1 2>/dev/null \
            | awk '{for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit }}' || true)"
    fi

    if [[ -z $host ]] && command -v hostname > /dev/null 2>&1; then
        host="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
    fi

    if [[ -z $host ]]; then
        echo "Failed to detect host IP. Pass --agent-claude-copilot-api-host <host>." >&2
        return 1
    fi

    printf '%s' "$host"
}

fetch_models() {
    local host="$1" body

    if ! body="$(curl -fsS "http://$host:4141/v1/models")"; then
        echo "Failed to query copilot-api models at http://$host:4141/v1/models" >&2
        return 1
    fi

    # Emit one model id per line.
    jq -r '.data[]?.id // empty' <<< "$body" || true
}

resolve_model() {
    local family="$1" ids="$2" model

    # Prefer the 1M-context variant; within a family pick the highest version.
    model="$(grep -E "^claude-$family-"'.*\[1m\]$' <<< "$ids" | sort -V | tail -n1 || true)"

    if [[ -z $model ]]; then
        model="$(grep -E "^claude-$family-" <<< "$ids" | sort -V | tail -n1 || true)"
    fi

    if [[ -z $model ]]; then
        echo "No '$family' model found in copilot-api /v1/models response." >&2
        return 1
    fi

    printf '%s' "$model"
}

backup() {
    local config_file="$1"

    if [[ ! -e $config_file ]]; then
        return 0
    fi

    local backup_file
    backup_file="$config_file.backup.$(date -u +%Y%m%dT%H%M%SZ).$$"
    cp -p "$config_file" "$backup_file"

    echo "Backed up $config_file to $backup_file"
}

render_config() {
    local base_url="$1" opus="$2" sonnet="$3" haiku="$4" config_file="$5" tmp

    if ! command -v jq > /dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y jq
    fi

    # Render to a writable temp file; the script dir may be a read-only bind
    # mount during docker build. jq --arg escapes values safely.
    tmp="$(mktemp)"
    jq --arg base_url "$base_url" \
       --arg opus "$opus" \
       --arg sonnet "$sonnet" \
       --arg haiku "$haiku" \
       '.env.ANTHROPIC_BASE_URL = $base_url
        | .env.ANTHROPIC_DEFAULT_OPUS_MODEL = $opus
        | .env.ANTHROPIC_DEFAULT_SONNET_MODEL = $sonnet
        | .env.ANTHROPIC_DEFAULT_HAIKU_MODEL = $haiku' \
       './copilot_api.tmpl.json' > "$tmp"

    mv "$tmp" "$config_file"
}

install_plugins() {
    local claude_bin

    if command -v claude > /dev/null 2>&1; then
        claude_bin="claude"
    elif [[ -x "$HOME/.local/bin/claude" ]]; then
        claude_bin="$HOME/.local/bin/claude"
    else
        echo "claude binary not found; cannot install copilot-api plugins." >&2
        return 1
    fi

    # Plugins recommended by copilot-api.
    if ! "$claude_bin" plugin marketplace add "https://github.com/caozhiyuan/copilot-api.git"; then
        echo "Failed to add copilot-api plugin marketplace." >&2
        return 1
    fi
    if ! "$claude_bin" plugin install "agent-inject@copilot-api-marketplace"; then
        echo "Failed to install agent-inject plugin." >&2
        return 1
    fi
    if ! "$claude_bin" plugin install "tool-search@copilot-api-marketplace"; then
        echo "Failed to install tool-search plugin." >&2
        return 1
    fi
}

main() {
    install_claude_code

    if [[ $AGENT_CLAUDE_COPILOT_API != "1" ]]; then
        return 0
    fi

    local host base_url ids opus sonnet haiku config_dir config_file

    host="${AGENT_CLAUDE_COPILOT_API_HOST:-$(detect_host)}"
    base_url="http://$host:4141"

    if ! command -v jq > /dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y jq
    fi

    ids="$(fetch_models "$host")"
    opus="$(resolve_model opus "$ids")"
    sonnet="$(resolve_model sonnet "$ids")"
    haiku="$(resolve_model haiku "$ids")"

    config_dir="$HOME/.claude"
    mkdir -p "$config_dir"
    chmod 700 "$config_dir"

    config_file="$config_dir/settings.json"
    backup "$config_file"

    render_config "$base_url" "$opus" "$sonnet" "$haiku" "$config_file"
    chmod 600 "$config_file"

    install_plugins
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
