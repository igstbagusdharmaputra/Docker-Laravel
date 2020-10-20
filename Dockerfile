FROM alpine:latest

LABEL Maintainer="Solusi" 

ARG uid=1000

RUN apk --no-cache add php7 php7-fpm php7-opcache php7-pdo php7-pdo_mysql php7-json php7-openssl php7-curl php-iconv \
	php7-zlib php7-xml php7-simplexml php7-phar php7-intl php7-dom php7-xmlreader php7-xmlwriter php7-ctype php7-session \
	php7-mbstring php7-gd php7-tokenizer php7-fileinfo php-zip nginx supervisor curl \
	openjdk8-jre libreoffice

RUN	rm /etc/nginx/conf.d/default.conf

RUN cd ~ && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php \
	&& mv composer.phar /usr/local/bin/composer

COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/vhost.conf /etc/nginx/conf.d/default.conf

COPY docker/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY docker/php.ini /etc/php7/conf.d/custom.ini

COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /var/www/html

COPY . /var/www/html

RUN adduser -S -u ${uid} www-data

RUN chown -R www-data.www-data /var/www/html && \
	chown -R www-data.www-data /run && \
	chown -R www-data.www-data /var/lib/nginx && \
	chown -R www-data.www-data /var/log/nginx

USER www-data

WORKDIR /var/www/html

RUN composer install --optimize-autoloader

EXPOSE 4000
EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping