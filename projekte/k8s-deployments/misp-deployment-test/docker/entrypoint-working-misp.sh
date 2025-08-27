#!/bin/bash
set -e

echo "Starting Working MISP Container..."

# Environment variables
export MYSQL_HOST=${MYSQL_HOST:-misp-mariadb}
export MYSQL_PORT=${MYSQL_PORT:-3306}
export MYSQL_DATABASE=${MYSQL_DATABASE:-misp}
export MYSQL_USER=${MYSQL_USER:-misp}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-misppassword}
export MISP_BASEURL=${MISP_BASEURL:-http://rhostesk8s001.labwi.sva.de}

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

echo "Configuring MISP..."

# Configure database
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

# Configure MISP settings
cat > /var/www/MISP/app/Config/config.php << EOF
<?php
\$config = array();
\$config['MISP']['baseurl'] = '$MISP_BASEURL';
\$config['MISP']['org'] = 'Test Organization';
\$config['MISP']['email'] = 'admin@misp.local';
\$config['MISP']['disable_emailing'] = true;
\$config['MISP']['background_jobs'] = false;
\$config['MISP']['cached_attachments'] = false;
\$config['MISP']['default_event_distribution'] = '1';
\$config['MISP']['default_attribute_distribution'] = 'event';
\$config['MISP']['tagging'] = true;
\$config['MISP']['title_text'] = 'MISP Test Instance';
\$config['MISP']['attachments_dir'] = '/var/www/MISP/app/files';
EOF

# Set proper permissions
chown -R www-data:www-data /var/www/MISP/app/Config
chown -R www-data:www-data /var/www/MISP/app/tmp
chown -R www-data:www-data /var/www/MISP/app/files
chmod -R 755 /var/www/MISP/app/tmp
chmod -R 755 /var/www/MISP/app/files

echo "MISP configuration complete!"
echo "Starting Apache..."

exec "$@"