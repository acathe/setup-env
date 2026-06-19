ARG from=dev-container/terminal:latest

FROM ${from}

COPY ./go.sh /tmp/setup/go.sh

RUN bash /tmp/setup/go.sh \
    && sudo find /tmp -mindepth 1 -delete
