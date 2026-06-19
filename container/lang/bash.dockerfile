ARG from=dev-container/terminal:latest

FROM ${from}

COPY ./bash.sh /tmp/setup/bash.sh

RUN bash /tmp/setup/bash.sh \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo find /tmp -mindepth 1 -delete
