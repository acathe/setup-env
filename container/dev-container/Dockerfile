FROM debian:13

SHELL ["/usr/bin/bash", "-c"]
CMD ["sudo", "/usr/sbin/sshd", "-D", "-e"]

ARG lang
ARG encoding
ARG language
ARG tz

ENV LANG=${lang}.${encoding}
ENV LANGUAGE=${language}
ENV TZ=${tz}

RUN apt-get -qq update \
    && apt-get -qq install locales \
    && localedef -i en_US -cf UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && if [[ ${lang}.${encoding} != "en_US.UTF-8" ]]; then localedef -i ${lang} -cf ${encoding} -A /usr/share/locale/locale.alias ${lang}.${encoding}; fi

ARG user
ARG uid
ARG gid
RUN groupadd -g "${gid}" "${user}" \
    && useradd -mu "${uid}" -g "${gid}" -s "$(command -v bash)" "${user}"

RUN apt-get -qq update \
    && apt-get -qq install sudo \
    && echo "${user} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${user}" \
    && chmod 0440 "/etc/sudoers.d/${user}"

RUN apt-get -qq update \
    && apt-get -qq install openssh-server \
    && install -dm 700 -o "${user}" -g "${user}" "/home/${user}/.ssh" \
    && install -dm 755 /run/sshd

RUN apt-get -qq update \
    && apt-get -qq install \
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
