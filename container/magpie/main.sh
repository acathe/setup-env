#!/usr/bin/env bash

set -euo pipefail

docker run -d --name magpie --restart unless-stopped -p 127.0.0.1:3425:3425 -p 127.0.0.1:3430:3430 -e MAGPIE_WEB_KEY="$(openssl rand -hex 16)" -v magpie-config:/config ghcr.io/yetone/magpie:latest web --addr 0.0.0.0:3430 --no-open
