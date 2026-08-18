#!/usr/bin/env bash

set -euo pipefail

CODE_GO="${CODE_GO:-0}"
CODE_PYTHON="${CODE_PYTHON:-0}"
CODE_RUST="${CODE_RUST:-0}"

APP_CLAUDE_COPILOT_API="${APP_CLAUDE_COPILOT_API:-0}"
APP_GIT="${APP_GIT:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --app-claude-copilot-api)
                APP_CLAUDE_COPILOT_API=1
                shift # shift once since flags have no values
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
        echo 'curl is required to install Claude Code.' >&2
        return 1
    fi

    curl -fsSL 'https://claude.ai/install.sh' | bash
}

install_plugin() {
    export PATH="$HOME/.local/bin:$PATH"
    claude plugin marketplace add 'anthropics/claude-plugins-official'
    claude plugin install 'claude-code-setup@claude-plugins-official'
    claude plugin install 'claude-md-management@claude-plugins-official'
    claude plugin install 'claude-security@claude-plugins-official'
    claude plugin install 'hookify@claude-plugins-official'

    if [[ $APP_GIT == '1' ]]; then
        claude plugin install 'commit-commands@claude-plugins-official'
    fi

    if [[ $CODE_GO == '1' ]]; then
        export PATH="$HOME/go/bin:/usr/local/go/bin:$PATH"
        go install 'golang.org/x/tools/gopls@latest'
        claude plugin install 'gopls-lsp@claude-plugins-official'
    fi

    if [[ $CODE_PYTHON == '1' ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        uv tool install 'pyright[nodejs]'
        claude plugin install 'pyright-lsp@claude-plugins-official'
    fi

    if [[ $CODE_RUST == '1' ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
        rustup component add rust-analyzer
        claude plugin install 'rust-analyzer-lsp@claude-plugins-official'
    fi

    if ! command -v jq > /dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y jq
    fi

    local tmp
    tmp="$(mktemp)"
    jq 'del(.extraKnownMarketplaces["claude-plugins-official"])
        | if .extraKnownMarketplaces == {} then del(.extraKnownMarketplaces) else . end' \
        "$HOME/.claude/settings.json" > "$tmp"
    cp "$tmp" "$HOME/.claude/settings.json"
}

main() {
    sudo apt-get update
    sudo apt-get install -y bubblewrap socat

    install_claude_code

    if [[ $APP_CLAUDE_COPILOT_API == '1' ]]; then
        bash './copilot_api/main.sh' "$@"
    fi

    install_plugin
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
