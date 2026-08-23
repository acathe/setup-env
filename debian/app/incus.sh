#!/usr/bin/env bash

set -euo pipefail

add_repo() {
    sudo mkdir -p '/etc/apt/keyrings'
    sudo curl -fsSL 'https://pkgs.zabbly.com/key.asc' \
        -o '/etc/apt/keyrings/zabbly.asc'

    sudo sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc

EOF'
}

install_incus() {
    sudo apt-get update
    sudo apt-get install -y incus incus-ui-canonical
}

add_group() {
    sudo usermod -aG incus-admin "$USER"
}

main() {
    add_repo
    install_incus
    add_group
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
