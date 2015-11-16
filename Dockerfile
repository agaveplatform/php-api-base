######################################################
#
# Agave Apache PHP Base Image
# Tag: agaveapi/api-base-images
#
# This is the base image for Agave's PHP APIs. It
# builds a minimal image with apache2 + php 5.5 + composer
#
# with support for auto-wiring database connections,
# CORS support, and unified logging to standard out.
#
# https://bitbucket.org/agaveapi/php-api-base
# http://agaveapi.co
#
######################################################

FROM alpine:3.2
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu

ADD tcp/limits.conf /etc/security/limits.conf
ADD tcp/sysctl.conf /etc/sysctl.conf

RUN /usr/sbin/deluser apache && \
    addgroup -g 50 -S apache && \
    adduser -u 1000 -g apache -G apache -S apache && \
    apk --update add apache2-ssl php-apache2 curl php-cli php-json php-phar php-openssl php-mysql php-pdo vim curl gzip tzdata bash && \
    rm -f /var/cache/apk/* && \
    echo "Setting system timezone to America/Chicago..." && \
    ln -snf /usr/share/zoneinfo/America/Chicago /etc/localtime && \
    echo "Installing composer..." && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    mkdir -p /var/www/html && \
    echo "<?php phpinfo(); ?>" > /var/www/html/index.php && \
    chown -R apache:apache /var/www/html && \
    echo "Setting document root to /var/www/html..." && \
    sed -i 's#^DocumentRoot ".*#DocumentRoot "/var/www/html"#g' /etc/apache2/httpd.conf && \
    sed -i 's#^<Directory ".*#<Directory "/var/www/html">#g' /etc/apache2/httpd.conf && \
    sed -i 's#^SSLMutex .*#Mutex sysvsem default#g' /etc/apache2/conf.d/ssl.conf && \
    echo "Enabling htaccess rewrites..." && \
    sed -i 's#AllowOverride none#AllowOverride All#' /etc/apache2/httpd.conf

# RUN curl -sk -O http://download.newrelic.com/php_agent/archive/5.1.0.129/newrelic-php5-5.1.0.129-linux.tar.gz && \
#     gunzip -dc newrelic-php5-5.1.0.129-linux.tar.gz | tar xf - && \
#     cd newrelic-php5-5.1.0.129-linux && \
#     ls && \
#     chmod +x ./newrelic-install && \
#     sysctl -p && \
#     newrelic-install install

ADD php/php.ini /etc/php/php.ini
ADD docker_entrypoint.sh /docker_entrypoint.sh

WORKDIR /var/www/html

VOLUME [ "/var/www/html" ]
VOLUME [ "/var/log/apache2" ]
VOLUME [ "/var/log/newrelic" ]

EXPOSE 80 443

ENTRYPOINT ["/docker_entrypoint.sh"]

CMD ["/usr/sbin/apachectl", "-DFOREGROUND"]
