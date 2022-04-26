ARG PHP_IMAGE_VER="8.0.14-fpm-alpine"

FROM caddy:alpine AS caddy-deps

FROM php:$PHP_IMAGE_VER
LABEL maintainer="Jetsung Chan <jetsungchan@gmail.com>"
RUN set -eux ;\
    apk update && \
    apk add --no-cache --virtual \
        ca-certificates \
        mailcap \
        supervisor \
        gd-dev \
        freetype-dev \
        icu-dev \
        libmemcached-dev \
        oniguruma-dev \
        libxml2-dev \
        autoconf \
        gcc \
        g++ \
        make \
        ;\
    rm /var/cache/apk/* \
        ;\
    (printf "no" | pecl install redis) \
        ;\
    pecl install igbinary \
        redis \
        memcached

RUN docker-php-ext-install pdo_mysql \
        mysqli \
        exif \
        opcache \
        intl \
        shmop \
        sysvsem \
        mbstring \
        soap \
        bcmath \
        ;\
    docker-php-ext-enable redis \
        igbinary \
        memcached \
        shmop \
        sysvsem \
        ;\   
    docker-php-ext-configure gd \
        --enable-gd \
        --with-freetype \
        --with-jpeg \
        ;\
    NUMPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
        ;\
    docker-php-ext-install -j${NUMPROC} gd ;\
    docker-php-source delete ;\
    apk del m4 \
        autoconf \
        binutils \
        libgomp \
        libatomic \
        libgphobos \
        gmp \
        isl22 \
        mpfr4 \
        mpc1 \
        gcc \
        musl-dev \
        libc-dev \
        g++ \
        make

EXPOSE 80 443
WORKDIR /app/
VOLUME ["/etc/caddy", "/var/www/html"]
COPY --from=caddy-deps /usr/bin/caddy /usr/bin/caddy

COPY ./files/Caddyfile /etc/caddy/
COPY ./files/index.php /var/www/html/
COPY ./files/supervisord.conf /etc/
COPY ./supervisord /etc/supervisord/
COPY ./entry.sh /app/entry.sh
RUN chmod +x /app/entry.sh
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENTRYPOINT ["/app/entry.sh"]
CMD ["-D"]
