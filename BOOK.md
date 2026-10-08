# Megaton Build Notes

This file records the Docker-only setup history for learning and future reference.

## Goal

Build Magento 2.4.9 requirements inside Docker only, without installing PHP, Composer, nginx, database, search, queue, cache, or New Relic directly on the local machine.

## Main Commands Used

Validate Docker Compose:

```sh
docker compose -f megaton/docker-compose.yml config
```

Build all images:

```sh
docker compose -f megaton/docker-compose.yml build
```

Rebuild only PHP-FPM after Dockerfile fixes:

```sh
docker compose -f megaton/docker-compose.yml build phpfpm
```

Start the stack:

```sh
docker compose -f megaton/docker-compose.yml up -d
```

Apply compose changes and remove old orphan containers:

```sh
docker compose -f megaton/docker-compose.yml up -d --remove-orphans
```

Check running containers:

```sh
docker compose -f megaton/docker-compose.yml ps
```

Check PHP version inside Docker:

```sh
docker compose -f megaton/docker-compose.yml exec -T phpfpm php -v
```

Check Composer version inside Docker:

```sh
docker compose -f megaton/docker-compose.yml exec -T phpfpm composer --version
```

Check OpenSearch from the PHP container:

```sh
docker compose -f megaton/docker-compose.yml exec -T phpfpm curl -fsS http://search:9200
```

Check Valkey:

```sh
docker compose -f megaton/docker-compose.yml exec -T valkey valkey-cli ping
```

Check RabbitMQ version:

```sh
docker compose -f megaton/docker-compose.yml exec -T rabbitmq rabbitmqctl version
```

Check MariaDB version:

```sh
docker compose -f megaton/docker-compose.yml exec -T db mariadb --version
```

Check nginx version:

```sh
docker compose -f megaton/docker-compose.yml exec -T nginx nginx -v
```

From inside the project folder, the shorter form is:

```sh
cd /home/guosong/dev/megaton
docker compose build
docker compose up -d
docker compose ps
```

## Final Docker Services

- `phpfpm`: PHP 8.5.6, Composer 2.9.3, Magento PHP extensions, Redis extension, New Relic PHP agent
- `nginx`: nginx 1.28.3
- `db`: MariaDB 11.8.6
- `search`: OpenSearch 3.6.0
- `rabbitmq`: RabbitMQ 4.2.6
- `valkey`: Valkey 9
- `newrelic`: New Relic daemon sidecar

ActiveMQ Artemis was removed because RabbitMQ 4.2 should be the only message queue service.

## Important Build Fixes

### PHP OPcache

The first PHP build tried to compile `opcache` with:

```Dockerfile
docker-php-ext-install ... opcache
```

That failed on PHP 8.5 with:

```text
cp: cannot stat 'modules/*': No such file or directory
```

The fix was to remove `opcache` from `docker-php-ext-install`, because `php:8.5-fpm` already includes Zend OPcache.

The successful rebuild command was:

```sh
cd /home/guosong/dev/megaton
docker compose build phpfpm
```

### Composer Image Was Not Enough

One attempt used the official Composer image directly:

```sh
docker run --rm -it \
  -v "$PWD":/app \
  -w /app \
  composer:2.9.3 \
  composer create-project magento/project-community-edition=2.4.9 .
```

That downloaded Magento, but dependency resolution failed because the plain Composer image did not have Magento PHP extensions:

```text
ext-bcmath missing
ext-intl missing
```

The fix was to run Composer inside our `phpfpm` image instead. That image includes Magento extensions such as `bcmath`, `intl`, `ftp`, `gd`, `pdo_mysql`, `soap`, `sockets`, `xsl`, `zip`, and `redis`.

### New Relic Download

The first New Relic install step had an over-escaped regex, so the detected version was empty and Docker tried to download:

```text
newrelic-php5--linux.tar.gz
```

The fix was to use the release listing correctly. The build detected:

```text
12.7.0.36
```

New Relic PHP agent was then installed inside the PHP image.

### nginx Port

Port `8080` was already used on the host machine, so nginx could not start:

```text
Bind for 0.0.0.0:8080 failed: port is already allocated
```

The host port was changed to:

```text
8081
```

Magento base URL was also updated to:

```text
http://localhost:8081/
```

### OpenSearch 3

OpenSearch 3 required security startup settings. Without them it exited and asked for:

```text
OPENSEARCH_INITIAL_ADMIN_PASSWORD
```

The final compose config uses:

```yaml
DISABLE_SECURITY_PLUGIN: "true"
OPENSEARCH_INITIAL_ADMIN_PASSWORD: MegatonAdmin123!
```

There was also one duplicate security setting error, fixed by removing `plugins.security.disabled=true` when `DISABLE_SECURITY_PLUGIN=true` was already present.

## Magento Install Command

Magento itself requires Adobe Commerce Marketplace keys. Install Magento inside Docker with:

```sh
cd /home/guosong/dev/megaton
docker compose run --rm phpfpm sh /var/www/html/install-magento.sh
```

Composer runs inside the `phpfpm` Docker container. It is not installed locally.

The helper command from the Magento folder is:

```sh
cd /home/guosong/dev/megaton/magento2
bash install.sh
```

`install.sh` changes back to `/home/guosong/dev/megaton` and runs the Docker Compose installer. The real Magento keys are read from `/home/guosong/dev/megaton/.env`; do not print or commit them.

Magento source is created directly in:

```text
/home/guosong/dev/megaton/magento2
```

nginx serves:

```text
/home/guosong/dev/megaton/magento2/pub
```

## After Install Fixes

### Missing Interceptor Class

The first browser load showed:

```text
ReflectionException: Class "Magento\Framework\App\Http\Interceptor" does not exist
```

Magento needed generated dependency-injection code. The fix was run inside Docker:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm sh -lc 'php bin/magento deploy:mode:show; rm -rf generated/code/* generated/metadata/* var/cache/* var/page_cache/* var/view_preprocessed/*; php bin/magento setup:di:compile; php bin/magento cache:flush; chown -R www-data:www-data generated var pub/static pub/media app/etc'
```

What this did:

- `deploy:mode:show` confirmed Magento was in developer mode.
- `rm -rf generated/... var/...` removed stale generated code and cache files.
- `setup:di:compile` generated factories, proxies, interceptors, and dependency injection metadata.
- `cache:flush` cleared Magento cache.
- `chown` made generated/cache/static folders writable by the container user.

The important success line was:

```text
Generated code and dependency injection configuration successfully.
```

### 502 Bad Gateway

After restarting nginx and PHP-FPM:

```sh
cd /home/guosong/dev/megaton
docker compose restart phpfpm nginx
```

the browser showed:

```text
502 Bad Gateway
```

The containers were checked with:

```sh
docker compose ps
docker compose logs --tail=120 phpfpm
docker compose logs --tail=80 nginx
```

PHP-FPM was running. The nginx log showed the real problem:

```text
upstream sent too big header while reading response header from upstream
```

Magento response headers/cookies were larger than nginx's default FastCGI buffers. The fix was to add these lines inside the PHP location in `nginx/default.conf`:

```nginx
fastcgi_buffer_size 128k;
fastcgi_buffers 4 256k;
fastcgi_busy_buffers_size 256k;
```

Then nginx was restarted:

```sh
docker compose restart nginx
```

### Broken UI / Missing CSS and JS

After the page loaded, the UI looked unstyled. nginx logs showed missing static files:

```text
open() "/var/www/html/pub/static/version.../frontend/Magento/luma/en_US/css/styles-m.css" failed (2: No such file or directory)
```

Two fixes were needed.

First, `nginx/default.conf` needed Magento static routing. The `/static/` location strips the `version...` part and falls back to `static.php`:

```nginx
location ^~ /static/ {
    expires max;
    access_log off;

    location ~ ^/static/version {
        rewrite ^/static/(version\d*/)?(.*)$ /static/$2 last;
    }

    location ~* \.(ico|jpg|jpeg|png|gif|svg|svgz|webp|avif|js|css|eot|ttf|otf|woff|woff2|html|json)$ {
        add_header Cache-Control "public";
        add_header X-Frame-Options "SAMEORIGIN";
        expires +1y;
        try_files $uri $uri/ /static.php?resource=$uri;
    }

    try_files $uri $uri/ /static.php?resource=$uri;
}
```

Second, static content was deployed inside Docker:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm sh -lc 'php bin/magento setup:static-content:deploy -f en_US; php bin/magento cache:flush'
docker compose restart nginx
```

The asset test was:

```sh
docker compose exec nginx wget -S -O /dev/null http://127.0.0.1/static/version1778836364/frontend/Magento/luma/en_US/css/styles-m.css
```

It returned:

```text
HTTP/1.1 200 OK
Content-Type: text/css
```

### Remove `index.php` From URLs

Magento links first appeared with `index.php` in the path, for example:

```text
http://localhost:8081/index.php/customer/account/create/
```

The Magento rewrite setting was enabled inside Docker:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm sh -lc 'php bin/magento config:set web/seo/use_rewrites 1; php bin/magento cache:flush'
```

nginx already routes clean URLs internally through:

```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```

To redirect old `index.php` URLs to clean URLs, this rule was added to `nginx/default.conf`:

```nginx
location ~ ^/index\.php/(.*)$ {
    return 301 /$1$is_args$args;
}
```

Then nginx was restarted:

```sh
docker compose restart nginx
```

The redirect was checked with:

```sh
docker compose exec nginx wget -S -O /dev/null http://127.0.0.1/index.php/customer/account/create/
```

The important result was:

```text
HTTP/1.1 301 Moved Permanently
Location: http://127.0.0.1/customer/account/create/
```

### Fix Wrong HTTPS Redirect

After clean URLs worked, this URL:

```text
http://localhost:8081/customer/account/create/
```

redirected incorrectly to:

```text
https://localhost/customer/account/create/
```

The URL settings were checked with:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm sh -lc 'php bin/magento config:show web/unsecure/base_url; php bin/magento config:show web/secure/base_url; php bin/magento config:show web/secure/use_in_frontend; php bin/magento config:show web/secure/use_in_adminhtml; php bin/magento config:show web/url/redirect_to_base'
```

Only the unsecure base URL was set, so the secure/local redirect behavior was corrected explicitly:

```sh
docker compose exec phpfpm sh -lc 'php bin/magento config:set web/unsecure/base_url http://localhost:8081/; php bin/magento config:set web/secure/base_url http://localhost:8081/; php bin/magento config:set web/secure/use_in_frontend 0; php bin/magento config:set web/secure/use_in_adminhtml 0; php bin/magento config:set web/url/redirect_to_base 0; php bin/magento cache:flush'
```

The customer create page was then tested from nginx:

```sh
docker compose exec nginx wget -S -O /dev/null http://127.0.0.1/customer/account/create/
```

The important result was:

```text
HTTP/1.1 200 OK
```

### Product Images 404

Sample product images did not show. A product image URL like this returned 404:

```text
http://localhost:8081/media/catalog/product/cache/207e23213cf636ccdef205098cf3c8a3/w/s/ws08-blue_main_1.jpg
```

The original image existed:

```text
pub/media/catalog/product/w/s/ws08-blue_main_1.jpg
```

but the specific cached resized image did not exist yet. Magento normally generates missing cached media through `get.php`, so nginx needed a `/media/` fallback.

The file check was:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm sh -lc 'ls -l pub/media/catalog/product/cache/207e23213cf636ccdef205098cf3c8a3/w/s/ws08-blue_main_1.jpg; find pub/media/catalog/product -path "*ws08-blue*" -maxdepth 8 -type f | head -20'
```

The failing URL was tested with:

```sh
docker compose exec nginx wget -S -O /dev/null http://127.0.0.1/media/catalog/product/cache/207e23213cf636ccdef205098cf3c8a3/w/s/ws08-blue_main_1.jpg
```

The fix was to add this `/media/` block to `nginx/default.conf`:

```nginx
location ^~ /media/ {
    try_files $uri $uri/ /get.php$is_args$args;

    location ~ ^/media/customer/ {
        deny all;
    }

    location ~* \.(ico|jpg|jpeg|png|gif|svg|svgz|webp|avif|js|css|eot|ttf|otf|woff|woff2)$ {
        add_header Cache-Control "public";
        add_header X-Frame-Options "SAMEORIGIN";
        expires +1y;
        try_files $uri $uri/ /get.php$is_args$args;
    }
}
```

Then nginx was restarted:

```sh
docker compose restart nginx
```

The same image URL then returned:

```text
HTTP/1.1 200 OK
Content-Type: image/jpeg
```

### Disable Admin Two-Factor Authentication Locally

The Magento admin showed a Two-Factor Authentication screen:

```text
Failed to send the message. Please contact the administrator
You need to configure Two-Factor Authorization in order to proceed to your store's admin area
```

This happened because Magento tried to send a 2FA setup email, but the local Docker stack did not have a mail service configured.

First, the enabled 2FA modules were checked:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm sh -lc 'php bin/magento module:status | grep -i TwoFactor || true'
```

The result showed:

```text
Magento_TwoFactorAuth
Magento_AdminAdobeImsTwoFactorAuth
```

For local development, those modules were disabled:

```sh
docker compose exec phpfpm sh -lc 'php bin/magento module:disable Magento_TwoFactorAuth Magento_AdminAdobeImsTwoFactorAuth; php bin/magento setup:upgrade; php bin/magento cache:flush'
```

Because disabling modules cleared generated classes and static files, Magento code and assets were regenerated:

```sh
docker compose exec phpfpm sh -lc 'php bin/magento setup:di:compile; php bin/magento setup:static-content:deploy -f en_US; php bin/magento cache:flush'
```

Finally, runtime folder ownership was restored:

```sh
docker compose exec -u root phpfpm sh -lc 'chown -R www-data:www-data var generated pub/static pub/media; chown -R 1000:1000 app/code app/design 2>/dev/null || true'
```

After this, the admin login no longer required the email-based 2FA setup step.

## After Magento Code Changes

Magento source files live on the host in:

```text
/home/guosong/dev/megaton/magento2
```

The same folder is mounted inside Docker as:

```text
/var/www/html
```

After normal Magento code or configuration changes, flush cache:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm php bin/magento cache:flush
```

For module changes, database schema changes, dependency injection changes, new classes, plugins, preferences, observers, or constructor changes, also run:

```sh
docker compose exec phpfpm php bin/magento setup:upgrade
docker compose exec phpfpm php bin/magento setup:di:compile
docker compose exec phpfpm php bin/magento cache:flush
```

If frontend CSS, JavaScript, layout, or theme static assets look stale, redeploy static content:

```sh
docker compose exec phpfpm php bin/magento setup:static-content:deploy -f en_US
docker compose exec phpfpm php bin/magento cache:flush
```

## Verified Versions

```text
PHP: 8.5.6
Composer: 2.9.3
New Relic PHP agent: 12.7.0.36
nginx: 1.28.3
MariaDB: 11.8.6
OpenSearch: 3.6.0
RabbitMQ: 4.2.6
Valkey: 9
```

## Current URL

```text
http://localhost:8081
```
