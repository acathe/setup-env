#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"
CODE_MARKDOWN="${CODE_MARKDOWN:-0}"

render_yazi_config() {
    if [[ $CODE_MARKDOWN == '1' ]]; then
        echo '[[plugin.prepend_previewers]]'
        echo 'url = "*.md"'
        echo "run = 'faster-piper -- CLICOLOR_FORCE=1 glow -w=\$w -s=dark -- \"\$1\"'"
    fi

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        echo
        echo '[[plugin.prepend_previewers]]'
        echo 'mime = "text/*"'
        echo "run = 'piper -- bat -p --color=always \"\$1\"'"
        echo
        echo '[[plugin.prepend_previewers]]'
        echo 'mime = "application/{mbox,javascript,wine-extension-ini}"'
        echo "run = 'piper -- bat -p --color=always \"\$1\"'"
    fi

    echo
    echo '[[plugin.prepend_fetchers]]'
    echo 'url = "*"'
    echo 'run = "git"'
    echo 'group = "git"'
    echo
    echo '[[plugin.prepend_fetchers]]'
    echo 'url = "*/"'
    echo 'run = "git"'
    echo 'group = "git"'
}

main() {
    mkdir -p "$HOME/.config/yazi"
    render_yazi_config > "$HOME/.config/yazi/yazi.toml"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
