FROM php:8.2-fpm

ENV user=putssh
ENV uid=1100

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    supervisor \
    nginx \
    build-essential \
    openssl

RUN docker-php-ext-install gd pdo pdo_mysql sockets ftp zip

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -m -G www-data,root -u "$uid" -d "/home/$user" "$user" && \
    mkdir -p "/home/$user/.composer" && \
    chown -R "$user:$user" "/home/$user"

WORKDIR /var/www

# Copy SSL config if needed
COPY ./openssl.cnf /etc/ssl/openssl.cnf

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy and install dependencies
COPY composer.json composer.lock ./
COPY . .
RUN composer install

# Set correct permissions
RUN chown -R "$user:www-data" /var/www && \
    chmod -R 777 /var/www/storage /var/www/bootstrap/cache

# Copy and configure supervisor
COPY ./supervisord.conf /etc/supervisord.conf

# Run supervisor as the main process
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]