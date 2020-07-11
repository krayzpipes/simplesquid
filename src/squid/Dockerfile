FROM ubuntu:20.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y squid apache2-utils

COPY entrypoint.sh /app/entrypoint.sh
COPY squid.conf /etc/squid/squid.conf

RUN chmod 755 /app/entrypoint.sh

EXPOSE 3128/tcp

ENTRYPOINT ["/app/entrypoint.sh"]

VOLUME ["/var/log/squid"]