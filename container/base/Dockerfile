FROM debian:trixie

ARG lang
ARG encoding
ARG language
ARG tz
ARG term=xterm-256color

ENV LANG=${lang}.${encoding}
ENV LANGUAGE=${language}
ENV TZ=${tz}
ENV TERM=${term}

SHELL ["/usr/bin/bash", "-c"]

RUN apt-get update \
    && apt-get install -y locales \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i ${lang} -c -f ${encoding} -A /usr/share/locale/locale.alias ${lang}.${encoding}

ARG user
RUN apt-get update \
    && apt-get install -y sudo \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s "$(command -v bash)" "${user}" \
    && echo "${user} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${user}" \
    && chmod 0440 "/etc/sudoers.d/${user}"

WORKDIR /home/${user}
USER ${user}

RUN sudo apt-get update \
    && sudo apt-get install -y zsh git curl \
    && sudo rm -rf /var/lib/apt/lists/*
