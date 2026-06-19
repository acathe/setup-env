ARG from=dev-container/terminal:latest

FROM ${from}

COPY ./protobuf.sh /tmp/setup/protobuf.sh

RUN bash /tmp/setup/protobuf.sh \
    && rm -f "$HOME/.local/readme.txt" \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo find /tmp -mindepth 1 -delete
