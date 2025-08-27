#!/bin/bash
set -e

echo "Starting basic MISP container..."

# Set default values
export MYSQL_HOST=${MYSQL_HOST:-misp-mariadb}
export MYSQL_DATABASE=${MYSQL_DATABASE:-misp}
export MYSQL_USER=${MYSQL_USER:-misp}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-misppassword}

# Basic configuration
if [ ! -f /var/www/html/app/Config/database.php ]; then
    mkdir -p /var/www/html/app/Config
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
        'prefix' => '',
        'encoding' => 'utf8',
    );
}
EOF
fi

# Set permissions
chown -R www-data:www-data /var/www/html/app/Config
chown -R www-data:www-data /var/www/html/app/tmp
chown -R www-data:www-data /var/www/html/app/files

echo "Starting Apache..."
exec "$@"