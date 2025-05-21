#!/bin/bash

# Create docker/nginx/conf.d directory if it doesn't exist
mkdir -p docker/nginx/conf.d

# Build and start Docker containers
echo "Starting Docker containers..."
docker-compose up -d

# Create a new Laravel project (latest version)
echo "Creating a new Laravel project (latest version)..."
docker-compose exec app composer create-project --prefer-dist laravel/laravel .

# Set proper file permissions
echo "Setting file permissions..."
docker-compose exec app chown -R www:www /var/www

# Install Laravel Sanctum for authentication
echo "Installing Laravel Sanctum..."
docker-compose exec app composer require laravel/sanctum

# Install Laravel caching package
echo "Installing Laravel cache dependencies..."
docker-compose exec app composer require predis/predis

# Run Laravel migrations
echo "Running migrations..."
docker-compose exec app php artisan migrate

# Install latest NPM dependencies and set up React
echo "Setting up React frontend with latest versions..."
docker-compose exec app npm install

echo "Setup completed successfully!" 