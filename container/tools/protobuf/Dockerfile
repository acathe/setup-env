ARG from=dev-container/terminal:latest

FROM ${from}

RUN sudo apt-get update \
    && sudo apt-get install -y clang-format unzip \
    && sudo rm -rf /var/lib/apt/lists/*

RUN protoc_version="$(curl -fsSIL -o /dev/null -w '%{url_effective}' 'https://github.com/protocolbuffers/protobuf/releases/latest' | sed -E 's#.*/tag/v?([^/]+)$#\1#')" \
    && curl -fsSL "https://github.com/protocolbuffers/protobuf/releases/download/v${protoc_version}/protoc-${protoc_version}-linux-x86_64.zip" -o "/tmp/protoc-${protoc_version}-linux-x86_64.zip" \
    && unzip "/tmp/protoc-${protoc_version}-linux-x86_64.zip" -d "$HOME/.local" \
    && rm -f "$HOME/.local/readme.txt" "/tmp/protoc-${protoc_version}-linux-x86_64.zip"
