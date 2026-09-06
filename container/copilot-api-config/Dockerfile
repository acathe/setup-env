FROM debian:13

RUN apt-get -qq update \
    && apt-get -qq install jq openssl \
    && rm -rf /var/lib/apt/lists/*

COPY config.sh /usr/local/bin/config.sh

CMD ["bash", "/usr/local/bin/config.sh"]
