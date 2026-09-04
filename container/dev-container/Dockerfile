FROM debian:13

ARG lang
ARG encoding
ARG language
ARG tz

ENV LANG=${lang}.${encoding}
ENV LANGUAGE=${language}
ENV TZ=${tz}

SHELL ["/usr/bin/bash", "-c"]

ARG user
ARG uid
ARG gid
RUN groupadd -g "${gid}" "${user}" \
    && useradd -m -u "${uid}" -g "${gid}" -s "$(command -v bash)" "${user}"

RUN apt-get update \
    && apt-get install -y locales \
    && localedef -i ${lang} -c -f ${encoding} -A /usr/share/locale/locale.alias ${lang}.${encoding} \
    && rm -rf /var/lib/apt/lists/* /tmp/*

RUN apt-get update \
    && apt-get install -y sudo \
    && echo "${user} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${user}" \
    && chmod 0440 "/etc/sudoers.d/${user}" \
    && rm -rf /var/lib/apt/lists/* /tmp/*

RUN apt-get update \
    && apt-get install -y openssh-server \
    && install -d -m 700 -o "${user}" -g "${user}" "/home/${user}/.ssh" \
    && install -d -m 755 /run/sshd \
    && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /home/${user}
USER ${user}
ENV USER=${user}

RUN sudo apt-get update \
    && sudo apt-get install -y \
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
    xz-utils \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

ARG term=xterm-256color
ARG colorterm=truecolor
ARG term_program=""
ARG term_program_version=""

ENV TERM=${term}
ENV COLORTERM=${colorterm}
ENV TERM_PROGRAM=${term_program}
ENV TERM_PROGRAM_VERSION=${term_program_version}

ARG terminfo_b64=""
RUN mkdir -p "/home/${user}/.terminfo" \
    && printf '%s' "$terminfo_b64" | base64 -d > /tmp/terminfo.src \
    && tic -x -o "/home/${user}/.terminfo" /tmp/terminfo.src \
    && rm /tmp/terminfo.src

ARG setup_args_b64=""
RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    mapfile -d '' -t setup_args < <(printf '%s' "$setup_args_b64" | base64 -d) \
    && bash /mnt/setup/main.sh --unattended "${setup_args[@]}" \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

CMD ["sudo", "/usr/sbin/sshd", "-D", "-e"]
