FROM ruby:2.7.0-slim

LABEL maintainer="Fluentd developers <fluentd@googlegroups.com>"
LABEL description="fluentd-ui docker image"
LABEL Vendor="Fluent Organization"

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    ruby-dev \
 && rm -rf /var/lib/apt/lists/*

RUN gem install nokogiri --platform=ruby

RUN gem install --no-document --version 1.2.1 fluentd-ui

COPY *.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9292

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
