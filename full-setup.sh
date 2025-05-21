#!/bin/bash

# Clear everything in the container
docker-compose exec app rm -rf /var/www/*

# Create Laravel project
docker-compose exec app composer create-project --prefer-dist laravel/laravel .

# Install dependencies
docker-compose exec app composer require laravel/sanctum predis/predis

# Update Laravel Sanctum config
docker-compose exec app php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# Set environment variables
docker-compose exec app cp .env.example .env
docker-compose exec app sed -i 's/DB_HOST=127.0.0.1/DB_HOST=db/g' .env
docker-compose exec app sed -i 's/DB_DATABASE=laravel/DB_DATABASE=izam_ecommerce/g' .env
docker-compose exec app sed -i 's/DB_USERNAME=root/DB_USERNAME=izam_user/g' .env
docker-compose exec app sed -i 's/DB_PASSWORD=/DB_PASSWORD=secret/g' .env
docker-compose exec app sed -i 's/REDIS_HOST=127.0.0.1/REDIS_HOST=redis/g' .env
docker-compose exec app sed -i 's/CACHE_DRIVER=file/CACHE_DRIVER=redis/g' .env
docker-compose exec app sed -i 's/SESSION_DRIVER=file/SESSION_DRIVER=redis/g' .env
docker-compose exec app sed -i 's/QUEUE_CONNECTION=sync/QUEUE_CONNECTION=redis/g' .env

# Generate key
docker-compose exec app php artisan key:generate

# Create models and migrations
docker-compose exec app php artisan make:model Product -m
docker-compose exec app php artisan make:model Order -m
docker-compose exec app php artisan make:model OrderItem -m

# Create controllers
docker-compose exec app php artisan make:controller Api/ProductController --api
docker-compose exec app php artisan make:controller Api/OrderController --api
docker-compose exec app php artisan make:controller Api/AuthController

# Create events and listeners
docker-compose exec app php artisan make:event OrderPlaced
docker-compose exec app php artisan make:listener SendOrderNotification --event=OrderPlaced

# Create factory and seeders
docker-compose exec app php artisan make:factory ProductFactory
docker-compose exec app php artisan make:seeder ProductSeeder

# Run migrations
docker-compose exec app php artisan migrate

# Install React and related packages
docker-compose exec app npm install
docker-compose exec app npm install @vitejs/plugin-react react react-dom react-router-dom @mui/material @mui/icons-material @emotion/react @emotion/styled axios

# Update vite.config.js for React
docker-compose exec app sed -i 's|plugins: \[\],|plugins: [require("@vitejs/plugin-react")],|g' vite.config.js
docker-compose exec app sed -i "s|input: \['resources/css/app.css', 'resources/js/app.js'\],|input: ['resources/css/app.css', 'resources/js/app.js'], refresh: true,|g" vite.config.js

# Create React directory structure
docker-compose exec app mkdir -p resources/js/components
docker-compose exec app mkdir -p resources/js/pages
docker-compose exec app mkdir -p resources/js/contexts
docker-compose exec app mkdir -p resources/js/hooks

# Set permissions
docker-compose exec app chown -R www:www /var/www

echo "Setup completed successfully! The application is now available at http://localhost:8000" 