######################################################
#
# Agave Apache PHP Base Image
# Tag: agaveapi/php-api-base
#
# This is the base image for Agave's PHP APIs. It
# extends the standard docker php:5.5-apache image
# with support for auto-wiring database connections,
# CORS support, and unified logging to standard out.
#
# https://bitbucket.org/taccaci/agave-docker-php-api-base
# http://agaveapi.co
#
######################################################

FROM php:5.5-apache
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm
RUN pecl install zip && \
    echo '<?php phpinfo(); ?>' > /var/www/html/index.php && \
    apt-get -y update && \
    apt-get -y install libmcrypt-dev libbz2-dev zlib1g-dev mysql-client nano && \
    docker-php-ext-install zip mcrypt pdo_mysql mbstring mysql && \
    a2enmod rewrite && \
    a2enmod ssl && \
    cp /usr/share/zoneinfo/America/Chicago /etc/localtime

ADD php/php.ini /usr/local/lib/
ADD apache/000-default.conf /etc/apache2/sites-available/000-default.conf
ADD docker_entrypoint.sh /docker_entrypoint.sh

VOLUME [ "/var/www/html" ]
VOLUME [ "/var/log/apache2" ]

EXPOSE 80 443

ENTRYPOINT ["/docker_entrypoint.sh"]

CMD ["apache2", "-DFOREGROUND"]
