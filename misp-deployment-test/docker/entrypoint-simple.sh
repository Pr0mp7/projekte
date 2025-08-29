#!/bin/bash
set -e

echo "Starting Simple MISP Container..."

# Environment variables with defaults
export MYSQL_HOST=${MYSQL_HOST:-misp-mariadb}
export MYSQL_PORT=${MYSQL_PORT:-3306}
export MYSQL_DATABASE=${MYSQL_DATABASE:-misp}
export MYSQL_USER=${MYSQL_USER:-misp}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-misppassword}
export REDIS_HOST=${REDIS_HOST:-misp-redis-master}
export REDIS_PORT=${REDIS_PORT:-6379}
export MISP_BASEURL=${MISP_BASEURL:-http://misp.local}
export MISP_ADMIN_EMAIL=${MISP_ADMIN_EMAIL:-admin@misp.local}
export MISP_ORG_NAME=${MISP_ORG_NAME:-"Test Organization"}

echo "Waiting for database connection..."
for i in {1..30}; do
    if nc -z "$MYSQL_HOST" "$MYSQL_PORT" 2>/dev/null; then
        echo "Database is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Database timeout - continuing anyway"
        break
    fi
    echo "Waiting for database... (attempt $i/30)"
    sleep 2
done

echo "Waiting for Redis connection..."
for i in {1..15}; do
    if nc -z "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null; then
        echo "Redis is ready!"
        break
    fi
    if [ $i -eq 15 ]; then
        echo "Redis timeout - continuing anyway"
        break
    fi
    echo "Waiting for Redis... (attempt $i/15)"
    sleep 2
done

# Configure database connection
echo "Configuring database connection..."
cat > /var/www/html/app/Config/database.php << EOF
<?php
class DATABASE_CONFIG {
    public \$default = array(
        'datasource' => 'Database/Mysql',
        'persistent' => false,
        'host' => '$MYSQL_HOST',
        'login' => '$MYSQL_USER',
        'password' => '$MYSQL_PASSWORD',
        'database' => '$MYSQL_DATABASE',
        'port' => $MYSQL_PORT,
        'prefix' => '',
        'encoding' => 'utf8',
    );
}
EOF

# Configure Redis if bootstrap file exists
if [ -f /var/www/html/app/Config/bootstrap.php ]; then
    echo "Configuring Redis connection..."
    sed -i "s/'host' => 'localhost'/'host' => '$REDIS_HOST'/" /var/www/html/app/Config/bootstrap.php || true
    sed -i "s/'port' => 6379/'port' => $REDIS_PORT/" /var/www/html/app/Config/bootstrap.php || true
fi

# Basic MISP configuration
echo "Creating MISP configuration..."
cat > /var/www/html/app/Config/config.php << EOF
<?php
\$config = array();
\$config['MISP']['baseurl'] = '$MISP_BASEURL';
\$config['MISP']['org'] = '$MISP_ORG_NAME';
\$config['MISP']['email'] = '$MISP_ADMIN_EMAIL';
\$config['MISP']['disable_emailing'] = true;
\$config['MISP']['background_jobs'] = false;
\$config['MISP']['cached_attachments'] = false;
\$config['MISP']['default_event_distribution'] = '1';
\$config['MISP']['default_attribute_distribution'] = 'event';
\$config['MISP']['tagging'] = true;
\$config['MISP']['title_text'] = 'MISP Test';
\$config['MISP']['attachments_dir'] = '/var/www/html/app/files';
EOF

# Set proper permissions
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/html/app/Config/
chown -R www-data:www-data /var/www/html/app/tmp/
chown -R www-data:www-data /var/www/html/app/files/
chmod -R 755 /var/www/html/app/tmp/
chmod -R 755 /var/www/html/app/files/

echo "MISP container initialization complete!"
echo "Starting Apache..."

# Start Apache
exec "$@"