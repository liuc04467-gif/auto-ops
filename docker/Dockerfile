# OpsLab - PHP 应用镜像（Nginx + PHP-FPM 单容器）
# 构建：docker build -f docker/Dockerfile -t harbor.opslab.local/ops-app/webapp:<TAG> .
# 技术栈：Nginx 1.25(alpine) + PHP-FPM 8.0，supervisord 托管两个进程，对外 80 端口
# 扩展：pdo_mysql / mysqli / redis / opcache（对齐传统架构 web01/web02 的依赖）

FROM php:8.0-fpm-alpine

# 安装 nginx、supervisor、PHP 扩展编译依赖
RUN apk add --no-cache nginx supervisor $PHPIZE_DEPS \
    && docker-php-ext-install pdo_mysql mysqli opcache \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS \
    && rm -rf /var/cache/apk/*

# 容器内配置（nginx 反代 php-fpm，supervisord 托管两进程）
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf

# 应用代码（构建上下文 = 仓库根）
COPY app/ /var/www/html/

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.max_accelerated_files=20000'; \
        echo 'opcache.validate_timestamps=0'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --retries=5 \
    CMD wget -q -O /dev/null http://127.0.0.1/health || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
