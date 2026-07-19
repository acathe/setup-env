#!/usr/bin/env bash

set -euo pipefail

get_nvm_latest() {
    curl -fsSIL -o /dev/null -w '%{url_effective}' 'https://github.com/nvm-sh/nvm/releases/latest' | sed -E 's#.*/tag/v?([^/]+)$#\1#'
}

install_nvm() {
    local version
    version="$(get_nvm_latest)"
    if [[ -z $version ]]; then
        echo "Failed to determine the latest nvm version." >&2
        return 1
    fi

    if [[ -s "$HOME/.zshrc" ]]; then
        echo >> "$HOME/.zshrc"
    fi

    echo -n "# NVM" >> "$HOME/.zshrc"

    # 下载并安装 nvm：
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$version/install.sh" | bash
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    install_nvm

    # shellcheck source=/dev/null
    source "$HOME/.nvm/nvm.sh"
    nvm install node

    # sed -i '/^plugins=(/s/)/ node npm nvm)/' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
