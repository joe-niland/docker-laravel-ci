ARG PHP_BASE_VERSION=8.2

FROM php:${PHP_BASE_VERSION}-cli-bookworm

# redeclare for new stage
ARG PHP_BASE_VERSION

ENV PHP_BASE_VERSION=${PHP_BASE_VERSION}
ENV DEBIAN_FRONTEND=noninteractive \
    UCF_FORCE_CONFFNEW=1

RUN echo "Using PHP base version: ${PHP_BASE_VERSION}"

# Install base packages
RUN apt-get -qq update && \
    # curl -sSL https://packages.sury.org/php/README.txt | bash -x && \
    apt-get -qq install -y --no-install-recommends software-properties-common gpg-agent lsb-release ca-certificates curl && \
    # curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb && \
    # dpkg -i /tmp/debsuryorg-archive-keyring.deb && \
    # sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' && \
    # add-apt-repository -y ppa:ondrej/php && \
    apt-get -qq update && \
    # apt-get -qq -y upgrade -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" && \
    apt-get -qq -y -o Dpkg::Options::="--force-confold" install --no-install-recommends \
    # docker
    iptables openssl pigz xz-utils uidmap dbus-user-session

# Install deps for extensions; install tools
RUN apt-get -qq -y -o Dpkg::Options::="--force-confold" install --no-install-recommends \
    # php
    libpng-dev \
    libzip-dev \
    # php8.1-zip \
    # php$PHP_VERSION-cli php$PHP_VERSION-common php$PHP_VERSION-apc \
    # php$PHP_VERSION-gd php$PHP_VERSION-xml php$PHP_VERSION-mbstring php$PHP_VERSION-curl php$PHP_VERSION-dev \
    # php$PHP_VERSION-sybase php$PHP_VERSION-gmp \
    # php$PHP_VERSION-mysql php$PHP_VERSION-gettext php$PHP_VERSION-zip \
    # SQL Server deps
    freetds-common libsybdb5 unixodbc-dev \
    # MySQL deps and cli \
    mariadb-client \
    # PgSQL cli \
    postgresql-client libpq-dev \
    # utils
    pwgen jq openssh-client git rsync zip unzip curl gnupg gettext-base  \
    iputils-ping netcat-openbsd dnsutils \
    # gd
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev

RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg

# Install SQL Server drivers
RUN if [ "${PHP_BASE_VERSION}" = "7.3" ] || [ "${PHP_BASE_VERSION}" = "7.4" ]; then \
        docker-php-ext-install -j$(nproc) sybase_ct; \
    else \
        # Microsoft SQL Server Drivers
        # Add Microsoft GPG key
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
        # Add Microsoft repository
        curl -sSL https://packages.microsoft.com/config/debian/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
        # Update package lists and install driver
        apt-get update -qq && \
        ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 && \
        # Install PHP extensions
        pecl install sqlsrv pdo_sqlsrv && \
        docker-php-ext-enable sqlsrv pdo_sqlsrv && \
        # Clean up
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

RUN docker-php-ext-install -j$(nproc) \
    zip pdo_mysql pdo_pgsql gd bcmath

ENV NODE_VERSION=20 \
    NODE_SASS_VERSION=1.72.0

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends make g++ nodejs && \
    # npm install -g --silent n && \
    # n ${NODE_VERSION} && \
    PATH="$PATH" && \
    # sass and Sentry CLI
    npm -g i --unsafe-perm --quiet sass@$NODE_SASS_VERSION @sentry/cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip &&  ./aws/install && rm -rf ./aws awscliv2.zip
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Update CLI PHP to use $PHP_VERSION
RUN ln -sfn /usr/bin/php${PHP_BASE_VERSION} /etc/alternatives/php

# # Set PHP timezone
# ENV PHP_TIMEZONE=Australia\/Sydney

# RUN sed -i "s?;date.timezone =?date.timezone = ${PHP_TIMEZONE}?g" /etc/php/${PHP_BASE_VERSION}/cli/php.ini

# Composer

# Get Composer bin from official image
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# RUN mkdir -p /home/build/.composer

# User for normal usage
RUN useradd -m build

USER build

# phpunit
ENV PHP_UNIT_VERSION=10.5
RUN composer global require "phpunit/phpunit:~${PHP_UNIT_VERSION}" --prefer-dist --no-interaction && \
    export PATH="$(composer config -g home)/vendor/bin:$PATH"

# Add volumes for the app
VOLUME [ "/app" ]

# Add HEALTHCHECK instruction
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD curl -f http://localhost/ || exit 1
