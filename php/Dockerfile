FROM php:8.3-fpm-alpine

RUN apk add --no-cache \
    git zip unzip bash icu-dev libzip-dev oniguruma-dev curl-dev libpng-dev \
    mariadb-connector-c-dev autoconf g++ make \
    mariadb-client

RUN docker-php-ext-install pdo pdo_mysql mbstring intl zip gd

COPY php.ini /usr/local/etc/php/conf.d/99-custom.ini

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN addgroup -g 1000 dev && adduser -D -G dev -u 1000 dev \
    && chown -R dev:dev /var/www/html
USER dev

# 앱 소스 (www-data 권한)
COPY --chown=www-data:www-data . /var/www/html

# entrypoint.sh 는 root 권한으로 복사
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]