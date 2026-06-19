ARG from=dev-container/terminal:latest

FROM ${from}

COPY ./python.sh /tmp/setup/python.sh

RUN bash /tmp/setup/python.sh \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo find /tmp -mindepth 1 -delete
