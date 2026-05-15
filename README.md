# Megaton Magento Docker Stack

All runtime requirements are installed in Docker images/containers only. You do not need local PHP, Composer, nginx, MariaDB, OpenSearch, RabbitMQ, Valkey, or New Relic installed on your machine.

## Services

- Magento/PHP-FPM: PHP 8.5 with Composer 2.9.3 and New Relic PHP agent 12.7.0+
- nginx: 1.28
- OpenSearch: 3
- MariaDB: 11.8
- RabbitMQ: 4.2
- Valkey: 9
- New Relic daemon sidecar

## Run

```sh
docker compose up -d
```

nginx is exposed at:

```text
http://localhost:8081
```

Port `8081` is used because `8080` was already allocated on this machine.

## Install Magento 2.4.9

Magento packages require Marketplace access keys from repo.magento.com. Run the installer inside Docker:

```sh
MAGENTO_PUBLIC_KEY=your_public_key \
MAGENTO_PRIVATE_KEY=your_private_key \
docker compose run --rm phpfpm sh /var/www/html/install-magento.sh
```

Magento source will be created in `magento2/app` by the PHP container. Composer also runs inside the PHP container.

## Useful Checks

```sh
docker compose ps
docker compose exec phpfpm php -v
docker compose exec phpfpm composer --version
docker compose exec phpfpm curl http://search:9200
docker compose exec valkey valkey-cli ping
```
# megaton
