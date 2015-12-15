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
    apk --update add apache2-ssl php-apache2 curl php-cli php-json php-phar php-openssl php-mysql php-pdo php-zip php-curl php-mysqli php-gd php-iconv php-zlib vim curl gzip tzdata bash && \
    rm -f /var/cache/apk/* && \
    echo "Setting system timezone to America/Chicago..." && \
    ln -snf /usr/share/zoneinfo/America/Chicago /etc/localtime && \
    echo "Setting up ntpd..." && \
    echo $(setup-ntp -c busybox  2>&1) && \
    ntpd -d -p pool.ntp.org && \
    echo "Installing composer..." && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    mkdir -p /var/www/html && \
    echo "<?php phpinfo(); ?>" > /var/www/html/index.php && \
    chown -R apache:apache /var/www/html && \
    echo "Setting document root to /var/www/html..." && \
    sed -i 's#/var/www/localhost/htdocs#/var/www/html#g' /etc/apache2/httpd.conf && \
    sed -i 's#^LogFormat "%h#LogFormat "[%{UNIQUE_ID}i] %h#g' /etc/apache2/httpd.conf && \
    sed -i 's#LogLevel warn#LogLevel info#g' /etc/apache2/httpd.conf && \
    sed -i 's#^ErrorLog logs/error.log#ErrorLog /proc/self/fd/2#g' /etc/apache2/httpd.conf && \
    sed -i 's#^CustomLog logs/access.log combined#CustomLog /proc/self/fd/1 combined#g' /etc/apache2/httpd.conf && \
    sed -i 's#^SSLMutex .*#Mutex sysvsem default#g' /etc/apache2/conf.d/ssl.conf && \
    sed -i 's#^ErrorLog logs/ssl_error.log#ErrorLog /proc/self/fd/2#g' /etc/apache2/conf.d/ssl.conf && \
    sed -i 's#^TransferLog logs/ssl_access.log#TransferLog /proc/self/fd/1#g' /etc/apache2/conf.d/ssl.conf && \
    sed -i 's#^CustomLog logs/ssl_request.log#CustomLog /proc/self/fd/1#g' /etc/apache2/conf.d/ssl.conf && \
    sed -i 's#LogLevel warn#LogLevel info#g' /etc/apache2/conf.d/ssl.conf

# Uncomment for bind util with host, dig, etc ~140MB
#RUN apk add -U alpine-sdk linux-headers \
    # && curl ftp://ftp.isc.org/isc/bind9/9.10.2/bind-9.10.2.tar.gz|tar -xzv \
    # && cd bind-9.10.2 \
    # && CFLAGS="-static" ./configure --without-openssl --disable-symtable \
    # && make \
    # && cp ./bin/dig/dig /usr/bin/ \
    # && apk del build-base alpine-sdk linux-headers \
    # && rm -rf bind-9.10.2 \
    # && rm /var/cache/apk/*

# Uncomment for newrelic support...should install logrotate as well or disable logging.
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
VOLUME [ "/var/log/newrelic" ]

EXPOSE 80 443

ENTRYPOINT ["/docker_entrypoint.sh"]

CMD ["/usr/sbin/apachectl", "-DFOREGROUND"]
