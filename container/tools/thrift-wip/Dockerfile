ARG from=dev-container/terminal:latest

FROM ${from}

ARG thrift_version

RUN curl -fsSL "https://dlcdn.apache.org/thrift/${thrift_version}/thrift-${thrift_version}.tar.gz" -o "/tmp/thrift-${thrift_version}.tar.gz" \
    && tar -C "$HOME/.local/bin" -xzf "/tmp/thrift-${thrift_version}.tar.gz" \
    && rm -f "/tmp/thrift-${thrift_version}.tar.gz"
