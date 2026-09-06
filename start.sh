#!/bin/sh
set -e

mkdir -p /run/nginx
mkdir -p /app/database
touch /app/database/database.sqlite
chown -R www-data:www-data /app/database

php artisan migrate --force

php-fpm -D
nginx -g "daemon off;"
