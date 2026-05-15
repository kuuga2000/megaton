ARG PHP_VERSION=8.5
ARG COMPOSER_VERSION=2.9.3

FROM composer:${COMPOSER_VERSION} AS composer

FROM php:${PHP_VERSION}-fpm AS php-extensions

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      curl \
      git \
      libfreetype6-dev \
      libicu-dev \
      libjpeg62-turbo-dev \
      libonig-dev \
      libpng-dev \
      libxml2-dev \
      libxslt1-dev \
      libzip-dev \
      mariadb-client \
      unzip \
      zip; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
      bcmath \
      ftp \
      gd \
      intl \
      pdo_mysql \
      soap \
      sockets \
      xsl \
      zip; \
    pecl install redis; \
    docker-php-ext-enable redis; \
    rm -rf /var/lib/apt/lists/*

FROM php-extensions

ARG NEW_RELIC_AGENT_VERSION=latest

COPY --from=composer /usr/bin/composer /usr/local/bin/composer

RUN set -eux; \
    cd /tmp; \
    if [ "${NEW_RELIC_AGENT_VERSION}" = "latest" ]; then \
      NEW_RELIC_AGENT_VERSION="$(curl -fsSL https://download.newrelic.com/php_agent/release/ | grep -oE 'newrelic-php5-[0-9]+(\.[0-9]+){3}-linux\.tar\.gz' | head -n 1 | sed -E 's/newrelic-php5-([0-9.]+)-linux\.tar\.gz/\1/')"; \
    fi; \
    curl -fsSLo newrelic-php-agent.tar.gz "https://download.newrelic.com/php_agent/release/newrelic-php5-${NEW_RELIC_AGENT_VERSION}-linux.tar.gz"; \
    tar -xzf newrelic-php-agent.tar.gz; \
    NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 "newrelic-php5-${NEW_RELIC_AGENT_VERSION}-linux/newrelic-install" install; \
    rm -rf /tmp/newrelic-php*; \
    sed -i \
      -e 's/newrelic.license =.*/newrelic.license = "${NEW_RELIC_LICENSE_KEY}"/' \
      -e 's/newrelic.appname =.*/newrelic.appname = "Megaton"/' \
      -e 's/;newrelic.daemon.address =.*/newrelic.daemon.address = "newrelic:31339"/' \
      /usr/local/etc/php/conf.d/newrelic.ini

RUN { \
      echo 'memory_limit=2G'; \
      echo 'max_execution_time=1800'; \
      echo 'realpath_cache_size=10M'; \
      echo 'realpath_cache_ttl=7200'; \
      echo 'opcache.enable=1'; \
      echo 'opcache.enable_cli=1'; \
      echo 'opcache.memory_consumption=512'; \
      echo 'opcache.interned_strings_buffer=16'; \
      echo 'opcache.max_accelerated_files=100000'; \
    } > /usr/local/etc/php/conf.d/magento.ini

WORKDIR /var/www/html

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]
