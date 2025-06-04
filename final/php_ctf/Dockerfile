FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    sqlite3 libsqlite3-dev \
    netcat-traditional \
    vim \
    sudo \
    && docker-php-ext-install pdo pdo_sqlite

RUN useradd -m -s /bin/bash letmepasslsa && \
    echo "letmepasslsa:TralaleroTralala" | chpasswd && \
    usermod -aG sudo letmepasslsa && \
    echo "letmepasslsa ALL=(ALL) NOPASSWD: /usr/bin/vim" >> /etc/sudoers


# 建立 log 目錄與權限
RUN mkdir -p /var/log/php && \
    touch /var/log/php/php-fpm.log && \
    chown -R www-data:www-data /var/log/php

RUN sed -i 's|^;*error_log\s*=.*|error_log = /var/log/php/php-fpm.log|' /usr/local/etc/php-fpm.d/www.conf

RUN echo "LSA2{WWW_LSA2_WWW_IS_WWW_COOL_WWW_BT_WWW_IS_WWW_HANDSOME_WWW}" > /root/rootflag.txt && chmod 600 /root/rootflag.txt

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["/entrypoint.sh"]
