#!/bin/bash
set -e

# MISP Minimal Container Entrypoint
echo "Starting MISP minimal container..."

# Set default values
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

# Wait for database (with timeout)
echo "Waiting for database..."
for i in {1..30}; do
    if nc -z "$MYSQL_HOST" "$MYSQL_PORT" 2>/dev/null; then
        echo "Database is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Database timeout - continuing anyway"
        break
    fi
    sleep 2
done

# Wait for Redis (with timeout)
echo "Waiting for Redis..."
for i in {1..15}; do
    if nc -z "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null; then
        echo "Redis is ready!"
        break
    fi
    if [ $i -eq 15 ]; then
        echo "Redis timeout - continuing anyway"
        break
    fi
    sleep 2
done

# Create basic MISP configuration if not exists
if [ ! -f /var/www/MISP/app/Config/database.php ]; then
    cat > /var/www/MISP/app/Config/database.php << EOF
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
fi

# Create basic config file
if [ ! -f /var/www/MISP/app/Config/config.php ]; then
    cat > /var/www/MISP/app/Config/config.php << EOF
<?php
\$config = array();
\$config['MISP']['baseurl'] = '$MISP_BASEURL';
\$config['MISP']['org'] = '$MISP_ORG_NAME';
\$config['MISP']['email'] = '$MISP_ADMIN_EMAIL';
EOF
fi

# Set permissions
chown -R www-data:www-data /var/www/MISP/app/Config/
chown -R www-data:www-data /var/www/MISP/app/tmp/
chown -R www-data:www-data /var/www/MISP/app/files/

# Start services
echo "Starting MISP services..."
exec "$@"