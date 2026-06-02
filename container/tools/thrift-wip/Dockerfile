ARG from=dev-container/terminal:latest

FROM ${from}

RUN thrift_version="$(curl -s 'https://downloads.apache.org/thrift/' | grep -oP '(?<=href=")[0-9.]+(?=/")' | sort -V | tail -n1)" \
    && curl -fsSL "https://dlcdn.apache.org/thrift/${thrift_version}/thrift-${thrift_version}.tar.gz" -o "/tmp/thrift-${thrift_version}.tar.gz" \
    && tar -C "$HOME/.local/bin" -xzf "/tmp/thrift-${thrift_version}.tar.gz" \
    && rm -f "/tmp/thrift-${thrift_version}.tar.gz"
