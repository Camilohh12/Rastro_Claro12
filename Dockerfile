# Stage 1: Build frontend assets with Node
FROM node:18-alpine AS node-build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Stage 2: PHP application
FROM php:8.2-fpm-alpine

WORKDIR /app

# Install system dependencies and PHP extensions (Alpine Linux packages)
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

# Copy built frontend assets from node-build stage
COPY --from=node-build /app/public/build /app/public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy nginx config (Alpine's nginx.conf includes /etc/nginx/http.d/*.conf, not conf.d)
COPY nginx.conf /etc/nginx/http.d/default.conf

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Permissions
RUN chown -R www-data:www-data /app

EXPOSE 8080

CMD ["/start.sh"]
