ARG from=dev-container/base:latest

FROM ${from}

ARG user

COPY ./zsh.sh /tmp/setup/zsh.sh
COPY ./omz.sh /tmp/setup/omz.sh
COPY ./.p10k.zsh /tmp/setup/.p10k.zsh

RUN bash /tmp/setup/zsh.sh \
    && bash /tmp/setup/omz.sh \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo find /tmp -mindepth 1 -delete

SHELL ["/usr/bin/zsh", "-c"]
