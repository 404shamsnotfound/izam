# Render Deployment Guide for IZAM E-commerce

This document provides instructions for deploying the IZAM E-commerce application to Render using Docker.

## Pre-Deployment Checklist

1. Make sure all unnecessary files are removed (like node_modules, vendor, etc.)
2. Ensure the existing `.env` file is configured for production and SQLite (see render-setup.md)
3. Verify your Dockerfile is configured correctly for production

## Deployment Steps

1. Push your code to a GitHub repository
2. Log in to your Render account
3. Create a new Web Service
4. Connect your GitHub repository
5. Configure the service:
   - Name: izam-ecommerce (or your preferred name)
   - Environment: Docker
   - Branch: main (or your deployment branch)
   - Build Command: leave empty (uses Dockerfile)
   - Start Command: leave empty (uses Dockerfile)

6. Add the following environment variables:
   - `RENDER_EXTERNAL_HOST`: your-app.onrender.com (without https://)
   
7. Click "Create Web Service"

## Post-Deployment

After deployment is complete:

1. Check the logs for any errors
2. Verify the database is created and migrations ran
3. Test the application functionality

For more detailed setup instructions, please refer to the [render-setup.md](render-setup.md) file.

## Troubleshooting

If you encounter any issues during deployment:

1. Check the Render logs
2. Verify environment variables are set correctly
3. Ensure database file permissions are correct
4. Try running the build commands manually through Render's shell

## Architecture Overview

This application uses:
- Laravel backend (PHP)
- React with TypeScript frontend
- SQLite database for simplicity
- Docker containerization

This configuration provides a lightweight and cost-effective deployment that works well with Render's free and starter tiers. 