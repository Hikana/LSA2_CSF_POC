#!/bin/bash
set -e

DB_PATH="/var/www/html/users.db"

mkdir -p /var/log/php
touch /var/log/php/php-fpm.log
chown -R www-data:www-data /var/log/php

touch /var/log/bash.log
chmod 666 /var/log/bash.log

export PROMPT_COMMAND='history -a; history 1 >> /var/log/bash.log'


if [ ! -f "$DB_PATH" ]; then
  echo "⚠️ users.db 不存在，正在初始化..."
  php /var/www/html/init_db.php || {
    echo "❌ 初始化失敗！"
    exit 1
  }
else
  echo "✅ users.db 已存在，略過初始化"
fi

rm -rf /var/www/html/static/uploads/*

# 安全設定 uploads 權限
chown -R www-data:www-data /var/www/html/static/uploads
chmod -R 755 /var/www/html/static/uploads


# ✅ 不再用 gosu 降權，讓 php-fpm 自己去切換 worker
exec php-fpm -F

