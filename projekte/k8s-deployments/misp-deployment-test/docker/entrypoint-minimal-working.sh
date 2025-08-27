#!/bin/bash
set -e

echo "Starting Minimal Working MISP Container..."

# Environment variables
export MYSQL_HOST=${MYSQL_HOST:-misp-mariadb}
export MYSQL_PORT=${MYSQL_PORT:-3306}
export MYSQL_DATABASE=${MYSQL_DATABASE:-misp}
export MYSQL_USER=${MYSQL_USER:-misp}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-misppassword}

echo "Creating basic MISP configuration..."

# Create basic database config
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
        'port' => $MYSQL_PORT,
        'prefix' => '',
        'encoding' => 'utf8',
    );
}
EOF

# Create basic MISP config
cat > /var/www/html/app/Config/config.php << 'EOF'
<?php
$config = array();
$config['MISP']['baseurl'] = getenv('MISP_BASEURL') ?: 'http://localhost';
$config['MISP']['org'] = 'Test Organization';
$config['MISP']['email'] = 'admin@misp.local';
$config['MISP']['disable_emailing'] = true;
$config['MISP']['background_jobs'] = false;
$config['MISP']['cached_attachments'] = false;
EOF

# Create a simple index.php for testing if MISP doesn't work
cat > /var/www/html/index.php << 'EOF'
<?php
phpinfo();
echo "<h1>MISP Container is Running!</h1>";
echo "<p>Database host: " . getenv('MYSQL_HOST') . "</p>";
if (class_exists('PDO')) {
    echo "<p>✓ PDO available</p>";
} else {
    echo "<p>✗ PDO not available</p>";
}
if (extension_loaded('pdo_mysql')) {
    echo "<p>✓ MySQL PDO extension loaded</p>";
} else {
    echo "<p>✗ MySQL PDO extension not loaded</p>";
}
EOF

# Set permissions
chown -R www-data:www-data /var/www/html/app/Config
chown -R www-data:www-data /var/www/html/app/tmp
chown -R www-data:www-data /var/www/html/app/files
chown www-data:www-data /var/www/html/index.php

echo "Minimal MISP container ready!"
exec "$@"