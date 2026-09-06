FROM php:8.2-fpm-alpine

WORKDIR /app

# Install system dependencies and PHP extensions (Alpine Linux packages)
# NOTE: dom, session, fileinfo, tokenizer, xml are already built into base image
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

# Copy startup script (separate file, more reliable than echo with \n)
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Permissions
RUN chown -R www-data:www-data /app

EXPOSE 8080

CMD ["/start.sh"]
