#!/bin/bash

# Run setup script first
echo "Step 1: Running full-setup.sh..."
chmod +x full-setup.sh
./full-setup.sh

# Wait for 5 seconds to ensure all Laravel setup is complete
echo "Waiting for Laravel setup to complete..."
sleep 5

# Run backend implementation
echo "Step 2: Implementing the Laravel backend..."
chmod +x implement.sh
./implement.sh

# Wait for 5 seconds to ensure backend is setup
echo "Waiting for backend setup to complete..."
sleep 5

# Run frontend implementation
echo "Step 3: Implementing the React frontend..."
chmod +x react-frontend.sh
./react-frontend.sh

# Build assets
echo "Step 4: Building frontend assets..."
docker-compose exec app npm run build

echo "Setup complete! Your application is now running at http://localhost:8000"
echo "Admin dashboard is available at http://localhost:8000/admin"
echo "Login with the following credentials:"
echo "Email: admin@example.com"
echo "Password: password" 