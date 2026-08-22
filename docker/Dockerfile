# OpsLab - PHP application Dockerfile
# Multi-stage build: builder → runtime
#
# Stage 1: Builder (compile PHP extensions)
FROM php:8.0-fpm-alpine AS builder

RUN docker-php-ext-install pdo_mysql mysqli && \
    docker-php-ext-enable opcache

# Stage 2: Runtime (slim image)
FROM php:8.0-fpm-alpine AS runtime

COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copy application code
COPY . /var/www/html

RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/health || exit 1

# Image size optimization:
# - Alpine base: ~40MB (vs Debian ~150MB)
# - Multi-stage: no build tools in runtime
# - .dockerignore: exclude tests, docs, .git
