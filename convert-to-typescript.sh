#!/bin/bash

# Script to convert React components from JavaScript to TypeScript

# Create directory for pages
docker exec -it izam-app bash -c "mkdir -p /var/www/resources/js/pages"

# Convert components
docker exec -it izam-app bash -c "cd /var/www/resources/js/components && for f in *.jsx; do cp \$f \${f%.jsx}.tsx; done"

# Convert pages 
docker exec -it izam-app bash -c "cd /var/www/resources/js/pages && for f in *.jsx; do cp \$f \${f%.jsx}.tsx; done"

# Convert contexts
docker exec -it izam-app bash -c "cd /var/www/resources/js/contexts && for f in *.jsx; do cp \$f \${f%.jsx}.tsx; done"

echo "Files have been converted to TypeScript (.tsx). You will need to:"
echo "1. Add appropriate type definitions to each file"
echo "2. Add interfaces for props and state"
echo "3. Add type annotations to function parameters and return values"
echo "4. Update the app.ts and App.tsx imports to use the new TypeScript files"

echo "See resources/js/contexts/AuthContext.tsx for an example of a properly typed component." 