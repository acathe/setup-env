ARG from=dev-container/terminal:latest

FROM ${from}

ARG protoc_version

RUN sudo apt-get update \
    && sudo apt-get install -y clang-format unzip \
    && sudo rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/protocolbuffers/protobuf/releases/download/v${protoc_version}/protoc-${protoc_version}-linux-x86_64.zip" -o "/tmp/protoc-${protoc_version}-linux-x86_64.zip" \
    && unzip "/tmp/protoc-${protoc_version}-linux-x86_64.zip" -d "$HOME/.local" \
    && rm -f "$HOME/.local/readme.txt" "/tmp/protoc-${protoc_version}-linux-x86_64.zip"
