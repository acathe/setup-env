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

ARG user
RUN apt-get update \
    && apt-get install -y locales sudo \
    && localedef -i ${lang} -c -f ${encoding} -A /usr/share/locale/locale.alias ${lang}.${encoding} \
    && useradd -m -s "$(command -v bash)" "${user}" \
    && echo "${user} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${user}" \
    && chmod 0440 "/etc/sudoers.d/${user}" \
    && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /home/${user}
USER ${user}
ENV USER=${user}

RUN sudo apt-get update \
    && sudo apt-get install -y git curl \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

ARG setup_args_b64=""
RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    mapfile -d '' -t setup_args < <(printf '%s' "$setup_args_b64" | base64 -d) \
    && bash /mnt/setup/setup.sh --unattended "${setup_args[@]}" \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

CMD ["sleep", "infinity"]
