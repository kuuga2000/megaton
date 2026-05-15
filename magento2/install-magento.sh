#!/bin/sh
set -e

APP_DIR=${APP_DIR:-/var/www/html}
MAGENTO_BASE_URL=${MAGENTO_BASE_URL:-http://localhost:8081/}
MAGENTO_PUBLIC_KEY=${MAGENTO_PUBLIC_KEY:-}
MAGENTO_PRIVATE_KEY=${MAGENTO_PRIVATE_KEY:-}
MAGENTO_DB_HOST=${MAGENTO_DB_HOST:-db}
MAGENTO_DB_NAME=${MAGENTO_DB_NAME:-magento}
MAGENTO_DB_USER=${MAGENTO_DB_USER:-magento}
MAGENTO_DB_PASSWORD=${MAGENTO_DB_PASSWORD:-magento123}
OPENSEARCH_HOST=${OPENSEARCH_HOST:-search}
OPENSEARCH_PORT=${OPENSEARCH_PORT:-9200}
RABBITMQ_HOST=${RABBITMQ_HOST:-rabbitmq}
RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
RABBITMQ_USER=${RABBITMQ_USER:-magento}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-magento123}
VALKEY_HOST=${VALKEY_HOST:-valkey}
VALKEY_PORT=${VALKEY_PORT:-6379}

cd "$APP_DIR"

if [ -f auth.json ]; then
  export COMPOSER_AUTH="$(cat auth.json)"
elif [ -n "$MAGENTO_PUBLIC_KEY" ] && [ -n "$MAGENTO_PRIVATE_KEY" ]; then
  cat > auth.json <<EOF
{
  "http-basic": {
    "repo.magento.com": {
      "username": "${MAGENTO_PUBLIC_KEY}",
      "password": "${MAGENTO_PRIVATE_KEY}"
    }
  }
}
EOF
  export COMPOSER_AUTH="$(cat auth.json)"
else
  echo "ERROR: Set MAGENTO_PUBLIC_KEY and MAGENTO_PRIVATE_KEY in megaton/.env."
  exit 1
fi

if [ ! -f composer.json ]; then
  rm -rf /tmp/magento
  composer create-project --repository=https://repo.magento.com/ magento/project-community-edition=2.4.9 /tmp/magento
  cp -a /tmp/magento/. "$APP_DIR"/
  rm -rf /tmp/magento
fi

if [ ! -f bin/magento ]; then
  echo "Magento install failed or bin/magento is missing."
  exit 1
fi

if [ -f app/etc/env.php ]; then
  echo "Magento already appears installed in $APP_DIR."
  exit 0
fi

until mysqladmin ping -h"$MAGENTO_DB_HOST" -u"$MAGENTO_DB_USER" -p"$MAGENTO_DB_PASSWORD" --silent; do
  echo "Waiting for MariaDB..."
  sleep 3
done

until curl -fsS "http://${OPENSEARCH_HOST}:${OPENSEARCH_PORT}" >/dev/null; do
  echo "Waiting for OpenSearch..."
  sleep 3
done

php bin/magento setup:install \
    --base-url="$MAGENTO_BASE_URL" \
    --db-host="$MAGENTO_DB_HOST" \
    --db-name="$MAGENTO_DB_NAME" \
    --db-user="$MAGENTO_DB_USER" \
    --db-password="$MAGENTO_DB_PASSWORD" \
    --admin-firstname=Admin \
    --admin-lastname=User \
    --admin-email=admin@example.com \
    --admin-user=admin \
    --admin-password=Admin123! \
    --language=en_US \
    --currency=USD \
    --timezone=America/Los_Angeles \
    --search-engine=opensearch \
    --opensearch-host="$OPENSEARCH_HOST" \
    --opensearch-port="$OPENSEARCH_PORT" \
    --amqp-host="$RABBITMQ_HOST" \
    --amqp-port="$RABBITMQ_PORT" \
    --amqp-user="$RABBITMQ_USER" \
    --amqp-password="$RABBITMQ_PASSWORD" \
    --cache-backend=redis \
    --cache-backend-redis-server="$VALKEY_HOST" \
    --cache-backend-redis-port="$VALKEY_PORT" \
    --page-cache=redis \
    --page-cache-redis-server="$VALKEY_HOST" \
    --page-cache-redis-port="$VALKEY_PORT" \
    --session-save=redis \
    --session-save-redis-host="$VALKEY_HOST" \
    --session-save-redis-port="$VALKEY_PORT" \
    --backend-frontname=admin

php bin/magento deploy:mode:set developer
php bin/magento cache:flush
