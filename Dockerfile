FROM php:8.2-fpm-alpine

WORKDIR /app

# Install system dependencies and PHP extensions (Alpine Linux packages)
# NOTE: dom, session, fileinfo, tokenizer, xml are already built into php:8.1-fpm-alpine
RUN apk add --no-cache \
    nginx \
    postgresql-dev \
    libpng-dev \
    jpeg-dev \
    freetype-dev \
    libxml2-dev \
    icu-dev \
    libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_pgsql \
    pdo_mysql \
    gd \
    bcmath \
    intl \
    zip

# Copy composer binary directly from the official composer image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy application
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create startup script (creates SQLite file, runs migrations, then starts services)
RUN echo '#!/bin/sh\n\
mkdir -p /run/nginx\n\
mkdir -p /app/database\n\
touch /app/database/database.sqlite\n\
chown -R www-data:www-data /app/database\n\
php artisan migrate --force\n\
php-fpm -D\n\
nginx -g "daemon off;"\n\
' > /start.sh && chmod +x /start.sh

# Permissions
RUN chown -R www-data:www-data /app

EXPOSE 8080

CMD ["/start.sh"]