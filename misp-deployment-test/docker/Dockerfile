# MISP Docker Image for RHEL-based On-Premises Deployment
# Based on MISP/misp-docker repository structure
# Optimized for RHEL 9 base image

ARG RHEL_VERSION=9
FROM registry.access.redhat.com/ubi${RHEL_VERSION}/ubi:latest as base

# Build arguments
ARG MISP_BRANCH=v2.4.190
ARG MISP_TAG=v2.4.190
ARG PHP_VER=8.2
ARG PYPI_REDIS_VERSION=5.0.1
ARG PYPI_LIEF_VERSION=0.14.1
ARG PYPI_PYDEEP2_VERSION=0.5.1
ARG PYPI_PYTHON_MAGIC_VERSION=0.4.27
ARG PYPI_MISP_LIB_STIX2_VERSION=3.0.1

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV MISP_BRANCH=${MISP_BRANCH}
ENV MISP_TAG=${MISP_TAG}

# Install RHEL packages and enable repositories
USER root
RUN dnf update -y && \
    dnf install -y epel-release && \
    dnf module enable -y php:${PHP_VER} && \
    dnf install -y \
    # System utilities
    wget curl git unzip vim procps-ng \
    # Web server
    httpd \
    # PHP and extensions
    php php-cli php-fpm php-common php-xml php-mbstring \
    php-pdo php-mysqlnd php-zip php-gd php-opcache \
    php-json php-intl php-bcmath php-ldap php-redis \
    # Python
    python3 python3-pip python3-devel \
    # Build tools
    gcc gcc-c++ make cmake autoconf automake libtool \
    # Libraries
    openssl-devel libxml2-devel libcurl-devel \
    zlib-devel libpng-devel libjpeg-turbo-devel \
    freetype-devel oniguruma-devel \
    # Database client
    mariadb \
    # Other dependencies
    sudo cron logrotate rsyslog supervisor && \
    dnf clean all

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create MISP user and directories
RUN useradd -r -s /bin/bash -d /var/www/MISP -c "MISP User" www-data && \
    mkdir -p /var/www/MISP && \
    chown -R www-data:www-data /var/www/MISP

# Python build stage
FROM base as python-build

WORKDIR /tmp
RUN git clone --depth 1 --branch ${MISP_BRANCH} https://github.com/MISP/MISP.git MISP-${MISP_BRANCH}

# Install Python dependencies
RUN cd MISP-${MISP_BRANCH} && \
    python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install \
    redis==${PYPI_REDIS_VERSION} \
    lief==${PYPI_LIEF_VERSION} \
    pydeep2==${PYPI_PYDEEP2_VERSION} \
    python-magic==${PYPI_PYTHON_MAGIC_VERSION} \
    misp-lib-stix2==${PYPI_MISP_LIB_STIX2_VERSION} && \
    python3 -m pip install -r requirements.txt

# MISP application stage
FROM base as misp-app

# Copy MISP source
COPY --from=python-build /tmp/MISP-${MISP_BRANCH} /var/www/MISP
COPY --from=python-build /usr/local/lib/python3*/site-packages /usr/local/lib/python3.9/site-packages

WORKDIR /var/www/MISP

# Set proper permissions
RUN chown -R www-data:www-data /var/www/MISP && \
    chmod -R 755 /var/www/MISP

# Install PHP dependencies with Composer
USER www-data
RUN composer install --no-dev --optimize-autoloader --no-interaction

USER root

# Configure PHP
RUN cp /etc/php.ini /etc/php.ini.bak && \
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php.ini && \
    sed -i 's/memory_limit = 128M/memory_limit = 2048M/' /etc/php.ini && \
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/' /etc/php.ini && \
    sed -i 's/post_max_size = 8M/post_max_size = 50M/' /etc/php.ini && \
    sed -i 's/max_input_time = 60/max_input_time = 300/' /etc/php.ini && \
    sed -i 's/session.cookie_secure =/session.cookie_secure = 0/' /etc/php.ini

# Configure Apache
COPY docker/apache-misp.conf /etc/httpd/conf.d/misp.conf
RUN sed -i 's/#ServerName www.example.com:80/ServerName localhost:80/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/httpd/conf/httpd.conf

# Create required directories
RUN mkdir -p /var/www/MISP/app/tmp/logs && \
    mkdir -p /var/www/MISP/app/files && \
    mkdir -p /var/www/MISP/app/files/scripts/tmp && \
    chmod -R 775 /var/www/MISP/app/tmp && \
    chmod -R 775 /var/www/MISP/app/files && \
    chown -R www-data:www-data /var/www/MISP/app/tmp && \
    chown -R www-data:www-data /var/www/MISP/app/files

# Copy configuration files
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/supervisord.conf /etc/supervisord.conf
RUN chmod +x /entrypoint.sh

# Create MISP configuration
RUN cp /var/www/MISP/app/Config/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.php && \
    cp /var/www/MISP/app/Config/database.default.php /var/www/MISP/app/Config/database.php && \
    cp /var/www/MISP/app/Config/core.default.php /var/www/MISP/app/Config/core.php && \
    cp /var/www/MISP/app/Config/config.default.php /var/www/MISP/app/Config/config.php && \
    chown -R www-data:www-data /var/www/MISP/app/Config/

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]