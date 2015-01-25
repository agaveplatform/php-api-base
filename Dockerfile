######################################################
#
# Agave Apache PHP Base Image
# Tag: agaveapi/php-api-base
#
# This is the base image for Agave's PHP APIs. It
# extends the standard docker php:5.5-apache image
# with
#
# You can also
# use the following commands to start up Agave and its
# dependencies manually.
#
# Start data volume
# docker run --name mydata agaveapi/api-data-volume echo "Data volume for my APIs"
#
# Start mysql
# docker run --name mysql -d            \ # Run detached in background
#						 --volumes-from mydata      \ # Persist to data volume
#            -v /var/lib/mysql 					\ # Persistent just the db directory
#						 agaveapi/mysql-dev
#
# Start MongoDB:
# docker run --name mongo -d       \ # Run detached in background
#						 --volumes-from mydata \ # Persist to data volume
#            -v /data/db 	         \ # Persistent db directory
#						 agaveapi/mongo-dev
#
# Start beanstalkd:
# docker run --name beanstalkd -d          \ # Run detached in background
#						 --volumes-from mydata         \ # Persist to data volume
#						 -v /var/lib/beanstalkd/binlog \ # Persistent db directory
#						 agaveapi/beanstalkd
#
# Start PHP
# docker run --name my-php-api -d         \ # Run detached in background
#            -e "SERVICE_NAME=my-php-api" \ # Pass in service name for logging
#            -p 80:80                     \ # HTTP
#            --link mysql:mysql           \ # MySQL server
#            --link mongo:mongo						\ # MongoDB server
#            --link beanstalkd:beanstalkd \ # Beanstalkd server
#            --volumes-from mydata        \ # Persistent data volume
#            -v /agave/logs/my-php-api:/var/log/supervisor \ # Persistent log dir
#            agaveapi/php-api-base
#
# https://bitbucket.org/taccaci/agave-docker-php-api-base
#
######################################################

FROM php:5.5-apache
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu

RUN pecl install zip
COPY php/php.ini /usr/local/lib/
COPY apache/httpd.conf /etc/httpd/conf/httpd.conf
COPY apache/userdir.conf /etc/apache2/mods-available/userdir.conf
COPY apache/apache2.conf /etc/apache2/apache2.conf
COPY apache/apache2.conf.dist /etc/apache2/apache2.conf.dist

ENV DEBIAN_FRONTEND noninteractive
RUN echo '<?php phpinfo(); ?>' > /var/www/html/index.php && \
    apt-get update && \
    apt-get -y install libmcrypt-dev libbz2-dev zlib1g-dev supervisor postfix && \
    docker-php-ext-install zip mcrypt pdo_mysql mysql && \
    touch /var/log/mail.log && \
    a2enmod rewrite

ADD supervisor/supervisor.conf /etc/supervisor/supervisord.conf
ADD install.sh /opt/install.sh
ADD postfix/postfix.sh /opt/postfix.sh

VOLUME [ "/var/www/html" ]
VOLUME [ "/var/log/supervisor" ]
EXPOSE 80
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
