# Render Deployment Setup

## Environment Configuration

Before uploading to Render, modify the existing `.env` file in the root of your project with the following content (adjust as needed):

```
APP_NAME="IZAM Ecommerce"
APP_ENV=production
APP_KEY=base64:M8RQLcO/i8QNnV/L3e9xDLboubEdx7Ei6TiM/yvrEgU=
APP_DEBUG=false
APP_URL=${RENDER_EXTERNAL_URL}
APP_LOCALE=en
APP_FALLBACK_LOCALE=en

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=cookie
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

VITE_APP_NAME="${APP_NAME}"

SANCTUM_STATEFUL_DOMAINS=${RENDER_EXTERNAL_HOST}
SESSION_DOMAIN=${RENDER_EXTERNAL_HOST}
```

## Render Configuration

1. In the Render dashboard, create a new Web Service.
2. Connect your GitHub repository.
3. Set the following:
   - **Environment**: Docker
   - **Build Command**: (leave empty, will use Dockerfile)
   - **Start Command**: (leave empty, will use Dockerfile)

4. Add the following environment variables:
   - `RENDER_EXTERNAL_URL`: Will be set automatically by Render
   - `RENDER_EXTERNAL_HOST`: The domain of your Render app without protocol (e.g., your-app.onrender.com)

5. Create the SQLite database:
   ```
   touch database/database.sqlite
   ```

6. Run the following commands during deployment:
   ```
   php artisan migrate --force
   php artisan db:seed
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   npm run build
   ```

## Post-Deployment Steps

1. Ensure the storage directory is writable:
   ```
   chmod -R 777 storage
   ```

2. Check logs if any issues arise:
   ```
   php artisan logs:tail
   ``` 