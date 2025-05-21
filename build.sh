#!/bin/bash

# Create Laravel models
echo "Creating Laravel models..."
docker-compose exec app php artisan make:model Product -m
docker-compose exec app php artisan make:model Order -m
docker-compose exec app php artisan make:model OrderItem -m

# Create Laravel controllers
echo "Creating Laravel controllers..."
docker-compose exec app php artisan make:controller ProductController --api
docker-compose exec app php artisan make:controller OrderController --api
docker-compose exec app php artisan make:controller AuthController

# Create Laravel events and listeners
echo "Creating Laravel events and listeners..."
docker-compose exec app php artisan make:event OrderPlaced
docker-compose exec app php artisan make:listener SendOrderNotification --event=OrderPlaced

# Create Laravel factories and seeders
echo "Creating Laravel factories and seeders..."
docker-compose exec app php artisan make:factory ProductFactory
docker-compose exec app php artisan make:factory OrderFactory
docker-compose exec app php artisan make:seeder ProductSeeder

# Set up React with Vite and Material UI (latest versions)
echo "Setting up React with Vite and Material UI (latest versions)..."
docker-compose exec app npm install @vitejs/plugin-react@latest react@latest react-dom@latest react-router-dom@latest @mui/material@latest @mui/icons-material@latest @emotion/react@latest @emotion/styled@latest axios@latest

# Create base React structure
echo "Creating React directory structure..."
docker-compose exec app mkdir -p resources/js/components
docker-compose exec app mkdir -p resources/js/pages
docker-compose exec app mkdir -p resources/js/contexts

echo "Build script completed!" 