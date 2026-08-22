#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

CODE_GO="${CODE_GO:-0}"
CODE_PROTOBUF="${CODE_PROTOBUF:-0}"
CODE_PYTHON="${CODE_PYTHON:-0}"
CODE_RUST="${CODE_RUST:-0}"

APP_YAZI="${APP_YAZI:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

render_blocks() {
    cat << 'EOF'
function update-all-in-one() {
    # APT
    sudo apt-get update \
        && sudo apt-get upgrade -y \
        && sudo apt-get autoremove -y \
        && sudo apt-get clean

    # Homebrew
    brew update \
        && brew upgrade --greedy \
        && brew cleanup

    # Oh My Zsh
    omz update
EOF

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        cat << 'EOF'

    # tealdeer
    tldr --update || true
EOF
    fi

    if [[ $CODE_GO == '1' ]]; then
        cat << 'EOF'

    # Go
    local go_version go_tmp \
        && go_version="$(curl -fsSL 'https://go.dev/dl/?mode=json' \
            | jq -r 'first(.[] | select(.stable)).files[]
                     | select(.os == "linux" and .arch == "amd64" and .kind == "archive")
                     | .filename' \
            | head -n 1)" \
        && if [[ -z $go_version ]]; then
            echo 'Failed to determine the latest Go version.' >&2
            false
        else
            go_tmp="$(mktemp)" \
                && curl -fsSL "https://go.dev/dl/$go_version" -o "$go_tmp" \
                && sudo rm -rf '/usr/local/go' \
                && sudo tar -C '/usr/local' -xzf "$go_tmp"
        fi
EOF
    fi

    if [[ $CODE_PROTOBUF == '1' ]]; then
        cat << 'EOF'

    # protoc
    local protoc_version protoc_tmp \
        && protoc_version="$(curl -fsSIL -o /dev/null -w '%{url_effective}' \
            'https://github.com/protocolbuffers/protobuf/releases/latest' \
            | sed -E 's#.*/tag/v?([^/]+)$#\1#')" \
        && if [[ -z $protoc_version ]]; then
            echo 'Failed to determine the latest protoc version.' >&2
            false
        else
            protoc_tmp="$(mktemp)" \
                && curl -fsSL "https://github.com/protocolbuffers/protobuf/releases/latest/download/protoc-$protoc_version-linux-x86_64.zip" \
                    -o "$protoc_tmp" \
                && unzip -o "$protoc_tmp" -d "$HOME/.local" \
                && rm -f "$HOME/.local/readme.txt"
        fi
EOF
    fi

    if [[ $CODE_PYTHON == '1' ]]; then
        cat << 'EOF'

    # uv
    uv self update \
        && uv tool upgrade --all
EOF
    fi

    if [[ $CODE_RUST == '1' ]]; then
        cat << 'EOF'

    # Rust
    rustup update
EOF
    fi

    if [[ $APP_YAZI == '1' ]]; then
        cat << 'EOF'

    # Yazi
    ya pkg upgrade
EOF
    fi

    cat << 'EOF'
}
EOF
}

main() {
    mkdir -p "$ZSH_CUSTOM"
    render_blocks > "$ZSH_CUSTOM/01-update.zsh"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
