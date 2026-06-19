ARG from=dev-container/terminal:latest

FROM ${from}

COPY ./rust.sh /tmp/setup/rust.sh

RUN bash /tmp/setup/rust.sh \
    && rm -f "$HOME/.profile" \
    && sudo find /tmp -mindepth 1 -delete
