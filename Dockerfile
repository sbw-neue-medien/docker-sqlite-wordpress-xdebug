# Source image
FROM wordpress:php8.5-apache

LABEL org.opencontainers.image.authors="plc@sbw-media.ch"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV WORDPRESS_PREPARE_DIR=/usr/src/wordpress \
    SQLITE_DATABASE_INTEGRATION_VERSION=2.2.23 \
    UPLOADS_INI="/usr/local/etc/php/conf.d/uploads.ini"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    # Install Xdebug
    pecl install xdebug; \
    docker-php-ext-enable xdebug; \
    # Download and extract SQLite integration
    curl -fsSL -o sqlite-database-integration.tar.gz \
        "https://github.com/WordPress/sqlite-database-integration/archive/refs/tags/v${SQLITE_DATABASE_INTEGRATION_VERSION}.tar.gz"; \
    tar -xzf sqlite-database-integration.tar.gz; \
    # Setup SQLite integration
    mkdir -p "${WORDPRESS_PREPARE_DIR}/wp-content/mu-plugins/sqlite-database-integration"; \
    cp -r "sqlite-database-integration-${SQLITE_DATABASE_INTEGRATION_VERSION}"/* \
        "${WORDPRESS_PREPARE_DIR}/wp-content/mu-plugins/sqlite-database-integration/"; \
    # Configure database connection
    mv "${WORDPRESS_PREPARE_DIR}/wp-content/mu-plugins/sqlite-database-integration/db.copy" \
        "${WORDPRESS_PREPARE_DIR}/wp-content/db.php"; \
    sed -i 's#{SQLITE_IMPLEMENTATION_FOLDER_PATH}#/var/www/html/wp-content/mu-plugins/sqlite-database-integration#' \
        "${WORDPRESS_PREPARE_DIR}/wp-content/db.php"; \
    sed -i 's#{SQLITE_PLUGIN}#sqlite-database-integration/load.php#' \
        "${WORDPRESS_PREPARE_DIR}/wp-content/db.php"; \
    # Create database directory with proper permissions
    mkdir -p "${WORDPRESS_PREPARE_DIR}/wp-content/database"; \
    touch "${WORDPRESS_PREPARE_DIR}/wp-content/database/.ht.sqlite"; \
    chmod 640 "${WORDPRESS_PREPARE_DIR}/wp-content/database/.ht.sqlite"; \
    # Cleanup to reduce image size
    rm -rf sqlite-database-integration.tar.gz \
           "sqlite-database-integration-${SQLITE_DATABASE_INTEGRATION_VERSION}"; \
    # Configure PHP upload limits
    { \
        echo "upload_max_filesize = 2048M"; \
        echo "post_max_size = 2048M"; \
        echo "memory_limit = 512M"; \
    } > "${UPLOADS_INI}"
