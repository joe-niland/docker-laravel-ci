FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive \
    UCF_FORCE_CONFFNEW=1 \
    NODE_VERSION=14 \
    NODE_SASS_VERSION=6.0.1 \
    PHP_TIMEZONE=Australia\/Sydney \
    PHP_VERSION=8.2

# Install packages
RUN apt-get -qq update && apt-get -qq install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php && \
    apt-get -qq update && \
    apt-get -qq -y upgrade -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" && \
    apt-get -qq -y -o Dpkg::Options::="--force-confold" install --no-install-recommends \
    # docker
    ca-certificates iptables openssl pigz xz-utils uidmap dbus-user-session \
    # php
    libpng-dev \
    php$PHP_VERSION-cli php$PHP_VERSION-common php$PHP_VERSION-apc \
    php$PHP_VERSION-gd php$PHP_VERSION-xml php$PHP_VERSION-mbstring php$PHP_VERSION-curl php$PHP_VERSION-dev \
    php$PHP_VERSION-sybase php$PHP_VERSION-gmp \
    php$PHP_VERSION-mysql php$PHP_VERSION-gettext php$PHP_VERSION-zip \
    # SQL Server
    freetds-common libsybdb5 \
    # MySQL cli \
    mysql-client \
    # PgSQL cli \
    postgresql-client \
    # utils
    pwgen jq openssh-client git rsync zip unzip curl

# Front-end build
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash && \ 
    # apt-get update && \
    apt-get install -y nodejs && \
    npm install -g --silent n && \
    n ${NODE_VERSION} && \
    PATH="$PATH" && \
    # Node-sass and Sentry CLI
    npm -g i --unsafe-perm --quiet node-sass@$NODE_SASS_VERSION @sentry/cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip &&  ./aws/install && rm -rf ./aws awscliv2.zip
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Update CLI PHP to use $PHP_VERSION
RUN ln -sfn /usr/bin/php$PHP_VERSION /etc/alternatives/php

# Set PHP timezone
RUN sed -i "s?;date.timezone =?date.timezone = ${PHP_TIMEZONE}?g" /etc/php/$PHP_VERSION/cli/php.ini

# Get Composer bin from official image
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# phpunit
RUN composer global require "phpunit/phpunit:~9.5" --prefer-dist --no-interaction && \
    export PATH="$(composer config -g home)/vendor/bin:$PATH"

# Add volumes for the app
VOLUME [ "/app" ]

# Docker

ENV DOCKER_TLS_CERTDIR=/certs
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client

# Get docker executables from official dind image
COPY --from=docker:20.10.23-dind /usr/local/bin/ /usr/local/bin/
COPY --from=docker:20.10.23-dind /usr/libexec/docker/cli-plugins /usr/libexec/docker/cli-plugins

COPY dockerd-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []
