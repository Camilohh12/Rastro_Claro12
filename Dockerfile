FROM php:8.1-fpm-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    composer \
    postgresql-dev \
    && docker-php-ext-install pdo pdo_pgsql

# Copy application
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create startup script
RUN echo '#!/bin/sh\n\
mkdir -p /run/nginx\n\
php-fpm -D\n\
nginx -g "daemon off;"\n\
' > /start.sh && chmod +x /start.sh

# Permissions
RUN chown -R www-data:www-data /app

EXPOSE 8080

CMD ["/start.sh"]
