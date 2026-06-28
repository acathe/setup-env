#!/usr/bin/env bash

set -euo pipefail

get_version_id() (
    source /etc/os-release
    echo "$VERSION_ID"
)

get_dotnet_latest() {
    apt-cache pkgnames dotnet-sdk- \
        | grep -E '^dotnet-sdk-[0-9]+\.[0-9]+$' \
        | sed 's/^dotnet-sdk-//' \
        | sort -V \
        | tail -n 1
}

add_repo() {
    local version_id
    version_id="$(get_version_id)"

    curl -fsSL "https://packages.microsoft.com/config/debian/$version_id/packages-microsoft-prod.deb" -o /tmp/packages-microsoft-prod.deb
    sudo dpkg -i /tmp/packages-microsoft-prod.deb
    rm -f /tmp/packages-microsoft-prod.deb
}

install_dotnet_sdk() {
    sudo apt-get update

    local version
    version="$(get_dotnet_latest)"
    if [[ -z $version ]]; then
        echo "Failed to determine the latest .NET SDK version." >&2
        return 1
    fi

    sudo apt-get install -y "dotnet-sdk-$version"
}

update_workloads() {
    sudo dotnet workload update
}

main() {
    add_repo
    install_dotnet_sdk
    update_workloads
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
