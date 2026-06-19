ARG from=dev-container/app:latest

FROM ${from}

COPY ./bash.sh /tmp/setup/bash.sh
RUN bash /tmp/setup/bash.sh \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo find /tmp -mindepth 1 -delete

COPY ./go.sh /tmp/setup/go.sh
RUN bash /tmp/setup/go.sh \
    && sudo find /tmp -mindepth 1 -delete

COPY ./python.sh /tmp/setup/python.sh
RUN bash /tmp/setup/python.sh \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo find /tmp -mindepth 1 -delete

COPY ./rust.sh /tmp/setup/rust.sh
RUN bash /tmp/setup/rust.sh \
    && rm -f "$HOME/.profile" \
    && sudo find /tmp -mindepth 1 -delete