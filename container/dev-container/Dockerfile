FROM debian:13

SHELL ["/usr/bin/bash", "-c"]
CMD ["sleep", "infinity"]

ARG lang
ARG encoding
ARG language
ARG tz

ENV LANG=${lang}.${encoding}
ENV LANGUAGE=${language}
ENV TZ=${tz}

RUN apt-get update \
    && apt-get install -y locales \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && if [[ ${lang}.${encoding} != "en_US.UTF-8" ]]; then localedef -i ${lang} -c -f ${encoding} -A /usr/share/locale/locale.alias ${lang}.${encoding}; fi

ARG user
RUN useradd -m -s "$(command -v bash)" "${user}"

RUN apt-get update \
    && apt-get install -y sudo \
    && echo "${user} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${user}" \
    && chmod 0440 "/etc/sudoers.d/${user}"

RUN apt-get update \
    && apt-get install -y \
    bzip2 \
    ca-certificates \
    curl \
    file \
    git \
    iproute2 \
    iputils-ping \
    less \
    lsof \
    man-db \
    nano \
    ncurses-bin \
    netcat-openbsd \
    procps \
    psmisc \
    python3 \
    vim-tiny \
    xz-utils

WORKDIR /home/${user}
USER ${user}
ENV USER=${user}

ARG term=xterm-256color
ARG colorterm=truecolor
ARG term_program
ARG term_program_version

ENV TERM=${term}
ENV COLORTERM=${colorterm}
ENV TERM_PROGRAM=${term_program}
ENV TERM_PROGRAM_VERSION=${term_program_version}

ARG terminfo_b64
RUN mkdir -p "/home/${user}/.terminfo" \
    && printf '%s' "$terminfo_b64" | base64 -d > /tmp/terminfo.src \
    && tic -x -o "/home/${user}/.terminfo" /tmp/terminfo.src \
    && rm -rf /tmp/*

ARG setup_args_b64
RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    mapfile -d '' -t setup_args < <(printf '%s' "$setup_args_b64" | base64 -d) \
    && bash /mnt/setup/main.sh --unattended "${setup_args[@]}" \
    && rm -rf /tmp/*
