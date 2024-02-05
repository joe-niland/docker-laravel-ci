FROM ubuntu:focal



ENV DEBIAN_FRONTEND=noninteractive \
    UCF_FORCE_CONFFNEW=1 \
    NODE_VERSION=18 \
    NODE_SASS_VERSION=6.0.1 \
    PHP_TIMEZONE=Australia\/Sydney \
    PHP_VERSION=8.2 \
    PHP_UNIT_VERSION=10.5

# Install packages
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends software-properties-common && \
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
    pwgen jq openssh-client git rsync zip unzip curl gnupg

# Front-end build
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends make g++ nodejs && \
    # npm install -g --silent n && \
    # n ${NODE_VERSION} && \
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
# Composer

# Get Composer bin from official image
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# User for normal usage
RUN useradd -m build

USER build

# phpunit
RUN composer global require "phpunit/phpunit:~${PHP_UNIT_VERSION}" --prefer-dist --no-interaction && \
    export PATH="$(composer config -g home)/vendor/bin:$PATH"

# Add volumes for the app
VOLUME [ "/app" ]

# Add HEALTHCHECK instruction
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD curl -f http://localhost/ || exit 1
