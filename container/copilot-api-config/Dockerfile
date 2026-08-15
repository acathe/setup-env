FROM debian:trixie

RUN apt-get update \
    && apt-get install -y jq openssl \
    && rm -rf /var/lib/apt/lists/*

COPY config.sh /usr/local/bin/config.sh

CMD ["bash", "/usr/local/bin/config.sh"]
