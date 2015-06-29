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

ENV DEBIAN_FRONTEND noninteractive
RUN pecl install zip && \
    echo '<?php phpinfo(); ?>' > /var/www/html/index.php && \
    apt-get -y update && \
    apt-get -y install libmcrypt-dev libbz2-dev zlib1g-dev mysql-client && \
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
