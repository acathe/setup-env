#!/usr/bin/env bash

set -euo pipefail

main() {
    if ! command -v docker > /dev/null 2>&1; then
        echo 'docker is not installed.' >&2
        return 1
    fi

    docker pull 'portainer/portainer-ce:lts'
    docker volume create 'portainer_data' > /dev/null

    if docker container inspect 'portainer' > /dev/null 2>&1; then
        docker container rm -f 'portainer'
    fi

    docker run \
        -d \
        --name 'portainer' \
        --restart 'unless-stopped' \
        -p '9443:9443' \
        -v '/var/run/docker.sock:/var/run/docker.sock' \
        -v 'portainer_data:/data' \
        'portainer/portainer-ce:lts'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
