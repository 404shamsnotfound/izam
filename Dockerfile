FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    libzip-dev \
    nginx \
    supervisor \
    sqlite3 \
    libsqlite3-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions including SQLite
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip
RUN docker-php-ext-install pdo_sqlite

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js and npm (for React frontend) - Latest stable
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get update && apt-get install -y nodejs

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Configure nginx
COPY docker/nginx/nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Configure supervisor
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy existing application directory contents
COPY --chown=www:www . /var/www

# Set correct permissions
RUN chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Create SQLite database directory if it doesn't exist
RUN mkdir -p /var/www/database && touch /var/www/database/database.sqlite && chown -R www:www /var/www/database

# Install Composer dependencies
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Install npm dependencies and build assets
RUN npm ci && npm run build

# Create startup script
RUN echo '#!/bin/bash \n\
php artisan migrate --force \n\
php artisan db:seed --force \n\
php artisan config:cache \n\
php artisan route:cache \n\
php artisan view:cache \n\
supervisord -c /etc/supervisor/conf.d/supervisord.conf \n\
' > /var/www/start.sh \
    && chmod +x /var/www/start.sh

# Expose port 8080 for Render
EXPOSE 8080

# Start services
CMD ["/var/www/start.sh"] 