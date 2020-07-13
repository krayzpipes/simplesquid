FROM fluentd:latest

USER root

# 'news' group has gid of 13, which is required to read
# log files from 'proxy' user on squid proxy container

RUN adduser fluent news

COPY fluent.conf /fluentd/etc/

USER fluent