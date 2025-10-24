FROM php:8.3-fpm-alpine

# 필요한 패키지 설치
RUN apk add --no-cache \
    git zip unzip bash icu-dev libzip-dev oniguruma-dev curl-dev libpng-dev \
    mariadb-connector-c-dev autoconf g++ make mariadb-client
RUN apk add --no-cache tzdata

ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone

# PHP 확장 설치
RUN docker-php-ext-install pdo pdo_mysql mbstring intl zip gd

# PHP 설정 복사
COPY php.ini /usr/local/etc/php/conf.d/99-custom.ini

# composer 복사
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# 🧹 FPM 설정 정리 (user/group 경고 제거)
RUN sed -i '/^user =/d' /usr/local/etc/php-fpm.d/www.conf \
 && sed -i '/^group =/d' /usr/local/etc/php-fpm.d/www.conf

# 개발용 사용자 추가
RUN addgroup -g 1000 dev && adduser -D -G dev -u 1000 dev \
 && chown -R dev:dev /var/www/html

# 소스 복사
COPY --chown=www-data:www-data . /var/www/html

# entrypoint 복사
COPY --chown=root:root entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# 실행 유저 전환 (root → dev)
USER dev

ENTRYPOINT ["entrypoint.sh"]
