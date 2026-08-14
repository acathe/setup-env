#!/usr/bin/env bash

set -euo pipefail

get_version_id() (
    source '/etc/os-release'
    echo "$VERSION_ID"
)

add_repo() {
    local version_id
    version_id="$(get_version_id)"

    curl -fsSL "https://packages.microsoft.com/config/debian/$version_id/packages-microsoft-prod.deb" -o '/tmp/packages-microsoft-prod.deb'
    sudo dpkg -i '/tmp/packages-microsoft-prod.deb'
}

install_powershell() {
    sudo apt-get update
    sudo apt-get install -y powershell
}

main() {
    sudo apt-get update
    sudo apt-get install -y build-essential

    add_repo
    install_powershell
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
