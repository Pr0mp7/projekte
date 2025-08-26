#!/bin/bash

# Offline MISP Build Script
# Uses pre-downloaded components to avoid network issues

set -e

echo "=== Offline MISP Build ==="
echo "This build uses pre-downloaded components to avoid network issues"

# Create a Dockerfile that uses local components
cat > docker/Dockerfile.offline << 'EOF'
# Offline MISP Build - No network access required
FROM php:8.2-apache

# Copy pre-downloaded MISP source
COPY misp-source/ /var/www/html/

# Install only packages that are likely cached
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libzip-dev \
    libxml2-dev \
    && docker-php-ext-install pdo_mysql zip gd xml \
    && apt-get clean

# Copy pre-downloaded composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Basic Apache configuration
RUN a2enmod rewrite headers \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Create basic structure
RUN mkdir -p /var/www/html/app/tmp/logs \
             /var/www/html/app/files \
             /var/www/html/app/Config \
    && chown -R www-data:www-data /var/www/html

# Copy entrypoint
COPY docker/entrypoint-offline.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]  
CMD ["apache2-foreground"]
EOF

echo "Downloading MISP source code..."
if [ ! -d "misp-source" ]; then
    # Try to download on host (where internet works)
    if curl -L https://github.com/MISP/MISP/archive/v2.4.190.tar.gz -o misp.tar.gz; then
        tar -xzf misp.tar.gz
        mv MISP-2.4.190 misp-source
        rm misp.tar.gz
        echo "✓ MISP source downloaded"
    else
        echo "✗ Failed to download MISP source"
        echo "Please download manually:"
        echo "  wget https://github.com/MISP/MISP/archive/v2.4.190.tar.gz"
        echo "  tar -xzf v2.4.190.tar.gz" 
        echo "  mv MISP-2.4.190 misp-source"
        exit 1
    fi
fi

# Create offline entrypoint
cat > docker/entrypoint-offline.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting offline MISP container..."

# Basic configuration without external dependencies
export MYSQL_HOST=${MYSQL_HOST:-misp-mariadb}
export MYSQL_DATABASE=${MYSQL_DATABASE:-misp}
export MYSQL_USER=${MYSQL_USER:-misp}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-misppassword}

# Create basic config if needed
if [ ! -f /var/www/html/app/Config/database.php ]; then
    cat > /var/www/html/app/Config/database.php << EOL
<?php
class DATABASE_CONFIG {
    public \$default = array(
        'datasource' => 'Database/Mysql',
        'persistent' => false,
        'host' => '$MYSQL_HOST',
        'login' => '$MYSQL_USER',
        'password' => '$MYSQL_PASSWORD', 
        'database' => '$MYSQL_DATABASE',
        'prefix' => '',
        'encoding' => 'utf8',
    );
}
EOL
fi

chown -R www-data:www-data /var/www/html/app/Config
exec "$@"
EOF

chmod +x docker/entrypoint-offline.sh

echo "Building offline MISP container..."
docker build -f docker/Dockerfile.offline -t misp-offline:latest .

if [ $? -eq 0 ]; then
    echo "✓ Offline build successful!"
    echo "Image: misp-offline:latest"
    echo ""
    echo "To run:"
    echo "  docker run -d -p 8080:80 --name misp-test misp-offline:latest"
else
    echo "✗ Offline build failed"
    exit 1
fi