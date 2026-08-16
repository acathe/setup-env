#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"
CODE_MARKDOWN="${CODE_MARKDOWN:-0}"

render_yazi_config() {
    if [[ $CODE_MARKDOWN == '1' ]]; then
        cat << 'EOF'
[[plugin.prepend_previewers]]
url = "*.md"
run = 'faster-piper -- CLICOLOR_FORCE=1 glow -s=$t -- "$1"'

EOF
    fi

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        cat << 'EOF'
[[plugin.prepend_previewers]]
mime = "text/*"
run = 'piper -- bat -p --color=always -- "$1"'

[[plugin.prepend_previewers]]
mime = "application/{mbox,javascript,wine-extension-ini}"
run = 'piper -- bat -p --color=always -- "$1"'

EOF
    fi

    cat << 'EOF'
[[plugin.prepend_fetchers]]
url = "*"
run = "git"
group = "git"

[[plugin.prepend_fetchers]]
url = "*/"
run = "git"
group = "git"
EOF
}

main() {
    mkdir -p "$HOME/.config/yazi"
    render_yazi_config > "$HOME/.config/yazi/yazi.toml"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
