#!/bin/bash
set -e

# MISP Container Entrypoint Script
echo "Starting MISP container initialization..."

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
export MISP_ADMIN_PASSWORD=${MISP_ADMIN_PASSWORD:-admin123}
export MISP_ORG_NAME=${MISP_ORG_NAME:-"Test Organization"}

# Wait for database
echo "Waiting for database connection..."
while ! mysqladmin ping -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
    echo "Waiting for database..."
    sleep 2
done
echo "Database is ready!"

# Wait for Redis
echo "Waiting for Redis connection..."
while ! timeout 1 bash -c "echo > /dev/tcp/$REDIS_HOST/$REDIS_PORT" 2>/dev/null; do
    echo "Waiting for Redis..."
    sleep 2
done
echo "Redis is ready!"

# Configure database connection
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

# Configure Redis connection
sed -i "s/'host' => 'localhost'/'host' => '$REDIS_HOST'/" /var/www/MISP/app/Config/bootstrap.php
sed -i "s/'port' => 6379/'port' => $REDIS_PORT/" /var/www/MISP/app/Config/bootstrap.php

# Set MISP configuration
cat > /var/www/MISP/app/Config/config.php << EOF
<?php
\$config = array();
\$config['MISP']['baseurl'] = '$MISP_BASEURL';
\$config['MISP']['org'] = '$MISP_ORG_NAME';
\$config['MISP']['showorg'] = true;
\$config['MISP']['background_jobs'] = true;
\$config['MISP']['cached_attachments'] = false;
\$config['MISP']['email'] = '$MISP_ADMIN_EMAIL';
\$config['MISP']['disable_emailing'] = false;
\$config['MISP']['default_event_distribution'] = '1';
\$config['MISP']['default_attribute_distribution'] = 'event';
\$config['MISP']['tagging'] = true;
\$config['MISP']['full_tags_on_event_index'] = true;
\$config['MISP']['welcome_text_top'] = 'MISP Test Instance';
\$config['MISP']['welcome_text_bottom'] = 'Welcome to your MISP test deployment';
\$config['MISP']['attachments_dir'] = '/var/www/MISP/app/files';
\$config['MISP']['download_attachments_on_load'] = true;
\$config['MISP']['title_text'] = 'MISP Test';
\$config['MISP']['terms_download'] = false;
\$config['MISP']['showorgalternate'] = false;
\$config['MISP']['event_view_filter_fields'] = 'id, uuid, value, comment, type, category, Tag.name';
EOF

# Set proper permissions
chown -R www-data:www-data /var/www/MISP/app/Config/
chown -R www-data:www-data /var/www/MISP/app/tmp/
chown -R www-data:www-data /var/www/MISP/app/files/

# Initialize database if needed
cd /var/www/MISP
if ! mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES;" | grep -q "users"; then
    echo "Initializing MISP database..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < /var/www/MISP/INSTALL/MYSQL.sql
    
    # Create admin user
    sudo -u www-data php /var/www/MISP/app/Console/cake user init_db_setup
    sudo -u www-data php /var/www/MISP/app/Console/cake admin setSetting "MISP.baseurl" "$MISP_BASEURL"
    sudo -u www-data php /var/www/MISP/app/Console/cake admin setSetting "MISP.org" "$MISP_ORG_NAME"
    echo "Database initialized!"
fi

# Start services
echo "Starting MISP services..."
exec "$@"