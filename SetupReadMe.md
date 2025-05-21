# E-Commerce Application Setup Guide

This document outlines the complete setup process for the IZAM E-commerce application, a full-stack project using Laravel (backend) and React with TypeScript (frontend), containerized with Docker.

## Project Overview

- **Backend**: Laravel PHP framework with RESTful API
- **Frontend**: React with TypeScript and Material UI
- **Database**: SQLite (file-based)
- **Caching**: Database-based with Redis capability
- **Containerization**: Docker with multiple services

## 1. Prerequisites

- Docker and Docker Compose
- Git
- Node.js and npm (for local development)
- Composer (for local development)

## 2. Docker Environment Setup

### 2.1 Docker Compose Configuration

Create a `docker-compose.yml` file with the following services:

```yaml
version: '3'

services:
  # PHP Application
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: izam-app
    restart: unless-stopped
    working_dir: /var/www
    volumes:
      - ./:/var/www
    networks:
      - izam-network
    depends_on:
      - db
      - redis

  # Nginx Service
  nginx:
    image: nginx:alpine
    container_name: izam-nginx
    restart: unless-stopped
    ports:
      - "8000:80"
    volumes:
      - ./:/var/www
      - ./docker/nginx/conf.d:/etc/nginx/conf.d
    networks:
      - izam-network
    depends_on:
      - app

  # Database Service
  db:
    image: mysql:8.0
    container_name: izam-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: izam_ecommerce
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_PASSWORD: secret
      MYSQL_USER: izam_user
      SERVICE_TAGS: dev
      SERVICE_NAME: mysql
    volumes:
      - izam-dbdata:/var/lib/mysql
    networks:
      - izam-network
    ports:
      - "3306:3306"

  # Redis Service
  redis:
    image: redis:alpine
    container_name: izam-redis
    restart: unless-stopped
    networks:
      - izam-network

  # phpMyAdmin
  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: izam-phpmyadmin
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      PMA_HOST: db
      PMA_PORT: 3306
      MYSQL_ROOT_PASSWORD: root_password
    networks:
      - izam-network
    depends_on:
      - db

networks:
  izam-network:
    driver: bridge

volumes:
  izam-dbdata:
    driver: local
```

### 2.2 Dockerfile

Create a `Dockerfile` for PHP:

```dockerfile
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
    libzip-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js and npm (for React frontend) - Latest stable
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get update && apt-get install -y nodejs

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
```

### 2.3 Nginx Configuration

Create Nginx configuration at `docker/nginx/conf.d/app.conf`:

```nginx
server {
    listen 80;
    index index.php index.html;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/public;
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
    location / {
        try_files $uri $uri/ /index.php?$query_string;
        gzip_static on;
    }
}
```

## 3. Laravel Backend Setup

### 3.1 Laravel Installation and Configuration

Laravel project was set up with the following:

1. Configuration of environment variables in `.env` file:
   ```
   APP_NAME=IZAM_Ecommerce
   APP_ENV=production
   APP_KEY=[generated_app_key]
   APP_DEBUG=false
   APP_URL=http://localhost
   
   DB_CONNECTION=sqlite
   
   BROADCAST_DRIVER=log
   CACHE_STORE=database
   FILESYSTEM_DISK=local
   QUEUE_CONNECTION=database
   SESSION_DRIVER=database
   SESSION_LIFETIME=120
   ```

2. Created SQLite database:
   ```bash
   touch database/database.sqlite
   ```

### 3.2 Database Migrations and Models

1. Created required models:
   - Product
   - Order
   - OrderItem
   - User (default Laravel model)

2. Created migrations for tables:
   ```bash
   php artisan make:migration create_products_table
   php artisan make:migration create_orders_table
   php artisan make:migration create_order_items_table
   ```

3. Set up relationships:
   - Order has many OrderItems
   - OrderItem belongs to Order and Product
   - Product has many OrderItems

### 3.3 Repository Pattern Implementation

1. Created repository interfaces:
   ```
   app/Repositories/Interfaces/RepositoryInterface.php
   app/Repositories/Interfaces/ProductRepositoryInterface.php
   app/Repositories/Interfaces/OrderRepositoryInterface.php
   ```

2. Implemented concrete repository classes:
   ```
   app/Repositories/Eloquent/BaseRepository.php
   app/Repositories/Eloquent/ProductRepository.php
   app/Repositories/Eloquent/OrderRepository.php
   ```

3. Registered repositories in service provider:
   ```php
   // app/Providers/RepositoryServiceProvider.php
   $this->app->bind(ProductRepositoryInterface::class, ProductRepository::class);
   $this->app->bind(OrderRepositoryInterface::class, OrderRepository::class);
   ```

### 3.4 API Resources

Created API resource classes for consistent API responses:
```
app/Http/Resources/ProductResource.php
app/Http/Resources/OrderResource.php
```

### 3.5 API Controllers

Implemented RESTful API controllers:
```
app/Http/Controllers/Api/ProductController.php
app/Http/Controllers/Api/OrderController.php
app/Http/Controllers/Api/AuthController.php
```

### 3.6 Authentication with Laravel Sanctum

1. Set up Sanctum for API authentication:
   ```bash
   composer require laravel/sanctum
   php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
   php artisan migrate
   ```

2. Configured API routes with authentication:
   ```php
   // routes/api.php
   Route::middleware('auth:sanctum')->group(function () {
       Route::apiResource('products', ProductController::class);
       Route::apiResource('orders', OrderController::class);
       Route::get('/user', function (Request $request) {
           return $request->user();
       });
   });
   
   Route::post('/login', [AuthController::class, 'login']);
   Route::post('/register', [AuthController::class, 'register']);
   Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
   ```

### 3.7 Database Seeding

Created seeders for testing data:
```
database/seeders/ProductSeeder.php
database/seeders/UserSeeder.php
```

## 4. React Frontend Setup

### 4.1 TypeScript Configuration

1. Set up TypeScript in the React project:
   ```bash
   npm install --save-dev typescript @types/react @types/react-dom
   ```

2. Created `tsconfig.json`:
   ```json
   {
     "compilerOptions": {
       "target": "ES2020",
       "useDefineForClassFields": true,
       "lib": ["ES2020", "DOM", "DOM.Iterable"],
       "module": "ESNext",
       "skipLibCheck": true,
       "moduleResolution": "bundler",
       "allowImportingTsExtensions": true,
       "resolveJsonModule": true,
       "isolatedModules": true,
       "noEmit": true,
       "jsx": "react-jsx",
       "strict": true,
       "noImplicitAny": true,
       "strictNullChecks": true,
       "baseUrl": ".",
       "paths": {
         "@/*": ["resources/js/*"]
       }
     },
     "include": ["resources/js/**/*.ts", "resources/js/**/*.tsx"],
     "references": [{ "path": "./tsconfig.node.json" }]
   }
   ```

### 4.2 Vite Configuration

Updated `vite.config.ts` for proper Docker integration:

```typescript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';
import type { UserConfig } from 'vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.ts'],
            refresh: true,
        }),
        react(),
    ],
    resolve: {
        alias: {
            '@': '/resources/js',
        },
    },
    server: {
        host: '0.0.0.0',
        hmr: {
            host: 'localhost',
        },
        watch: {
            usePolling: true,
        },
    },
} as UserConfig);
```

### 4.3 React Components Structure

Organized components in a logical structure:
```
resources/js/
├── app.ts                # Application entry point
├── App.tsx               # Main App component
├── components/           # Reusable components
│   └── ProtectedRoute.tsx
├── contexts/             # Context providers
│   ├── AuthContext.tsx
│   └── CartContext.tsx
└── pages/                # Main pages
    ├── LoginPage.tsx
    ├── OrderDetailsPage.tsx
    ├── ProductsPage.tsx
    └── RegisterPage.tsx
```

### 4.4 API Integration

1. Set up axios for API calls with authentication:
   ```typescript
   // resources/js/contexts/AuthContext.tsx
   import axios from 'axios';
   
   // Configure axios defaults
   axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
   axios.defaults.withCredentials = true;
   
   // Set authentication token in header
   if (token) {
     axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
   }
   ```

2. Created context providers for shared state:
   - AuthContext for user authentication
   - CartContext for shopping cart management

### 4.5 Material UI Integration

Installed and configured Material UI:
```bash
npm install @mui/material @mui/icons-material @emotion/react @emotion/styled
```

### 4.6 Blade Template Configuration

Updated `resources/views/welcome.blade.php`:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>IZAM E-commerce</title>
    
    <!-- Preload critical resources -->
    @php
    $manifestPath = public_path('build/manifest.json');
    $assets = [];
    
    if (file_exists($manifestPath)) {
        $manifest = json_decode(file_get_contents($manifestPath), true);
        $cssFile = $manifest['resources/css/app.css']['file'] ?? null;
        $jsFile = $manifest['resources/js/app.ts']['file'] ?? null;
        
        if ($cssFile) {
            echo '<link rel="preload" href="/build/'.$cssFile.'" as="style">';
            echo '<link rel="stylesheet" href="/build/'.$cssFile.'">';
        }
        if ($jsFile) echo '<script type="module" src="/build/'.$jsFile.'" defer></script>';
    }
    @endphp
    
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <div id="app"></div>
</body>
</html>
```

## 5. Running the Application

### 5.1 Starting Docker Environment

```bash
docker-compose up -d
```

### 5.2 Installing Dependencies

```bash
docker-compose exec app composer install
docker-compose exec app npm install
```

### 5.3 Database Setup

```bash
docker-compose exec app php artisan migrate --seed
```

### 5.4 Building Frontend Assets

```bash
docker-compose exec app npm run build
```

### 5.5 Accessing the Application

- Main application: http://localhost:8000
- phpMyAdmin (database): http://localhost:8080

## 6. Key Improvements and Fixes

### 6.1 Pagination Fix

Fixed pagination in ProductsPage.tsx to handle both meta.last_page and direct last_page response formats:

```typescript
// Fix pagination by checking for meta.last_page or just last_page
if (response.data.meta && response.data.meta.last_page) {
    setTotalPages(response.data.meta.last_page);
} else if (response.data.last_page) {
    setTotalPages(response.data.last_page);
} else {
    // Fallback to 1 if no pagination info is available
    setTotalPages(1);
}
```

### 6.2 TypeScript Improvements

1. Added type definitions for API responses
2. Fixed type errors in components by adding proper interfaces
3. Used type assertions to resolve compatibility issues

### 6.3 Asset Loading Optimization

Improved asset loading in welcome.blade.php with preload tags and dynamic manifest reading:

```php
if ($cssFile) {
    echo '<link rel="preload" href="/build/'.$cssFile.'" as="style">';
    echo '<link rel="stylesheet" href="/build/'.$cssFile.'">';
}
```

### 6.4 Environment Setup for Deployment

Configured for easy deployment to services like Render:
- Using SQLite for database (file-based)
- Setting APP_ENV to production
- Properly bundling all assets

## 7. Development Tips

### 7.1 Running Frontend in Dev Mode

```bash
docker-compose exec app npm run dev
```

### 7.2 Watching for Changes

React Hot Module Replacement (HMR) is configured for development.

### 7.3 Database Management

- Access database via phpMyAdmin at http://localhost:8080
- Direct SQLite access through database/database.sqlite file

### 7.4 Troubleshooting

- Check Laravel logs: `docker-compose exec app tail -f storage/logs/laravel.log`
- Clear caches: `docker-compose exec app php artisan cache:clear`
- Rebuild assets: `docker-compose exec app npm run build`

## 8. Deployment Considerations

### 8.1 Preparing for Render Deployment

- Ensure all assets are built: `npm run build`
- Set appropriate environment variables
- Configure build commands in render.yaml
- Ensure the storage directory is writable

### 8.2 Environment Variables for Production

Minimum required environment variables:
```
APP_KEY=your-app-key
APP_ENV=production
APP_DEBUG=false
APP_URL=your-render-url
DB_CONNECTION=sqlite
```

## 9. Application Structure

### 9.1 Backend Architecture

```
app/
├── Http/
│   ├── Controllers/
│   │   └── Api/         # API Controllers
│   └── Resources/       # API Resources
├── Models/              # Eloquent Models
├── Repositories/
│   ├── Eloquent/        # Repository Implementations
│   └── Interfaces/      # Repository Interfaces
├── Providers/           # Service Providers
└── Events/              # Event Classes
```

### 9.2 Frontend Architecture

```
resources/js/
├── app.ts               # Entry Point
├── App.tsx              # Main Component
├── components/          # Reusable Components
├── contexts/            # Context Providers
└── pages/               # Page Components
```

## 10. Conclusion

This e-commerce application demonstrates a modern full-stack architecture with Laravel and React. The use of Docker makes development and deployment consistent across environments, while the repository pattern in the backend provides a clean separation of concerns.

The application is ready for deployment to platforms like Render, with SQLite configured for data storage. 