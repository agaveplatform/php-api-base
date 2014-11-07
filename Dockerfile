######################################################
#
# Agave Apache PHP Base Image
# Tag: agaveapi/php-api-base
#
# This is the base image for Agave's Java APIs. It
# contains Java 7, Tomcat 7, and configs to access
# a linked mysql jndi connection at hostname `mysql`
# on port 3306.
#
# You can also
# use the following commands to start up Agave and its
# dependencies manually.
#
# Start MySQL:
# docker run --name some-mysql -d 										\ # Run detached in background
#						 -e MYSQL_ROOT_PASSWORD=mysecretpassword 	\ # Default mysql root user password.
#						 -e MYSQL_DATABASE=agave-api 							\ # Database name. This should be left constant
#						 -e MYSQL_USER=agaveuser 									\ # User username. This can be random as it will be injected at runtime, but should be constant when persisting data
#						 -e MYSQL_PASSWORD=password 							\ # User password. This can be random as it will be injected at runtime, but should be constant when persisting data
#						 -v `pwd`/mysql:/var/lib/mysql 						\ # MySQL data directory for persisting db between container invocations
#						 mysql:5.6
#
# Start MongoDB:
# docker run --name some-mongo -d 		\ # Run detached in background
#						 -v `pwd`/mongo:/data/db 	\ # Mongo data directory for persisting db between invocations
#						 mongo:2.6
#
# Start Beanstalkd:
# docker run --name some-beanstalkd -d -t 				\ # Run detached in background
#            -p 10022:22             							\ # SSHD, SFTP
#            -p 11300:11300												\ # beanstalkd
#            -v `pwd`/beanstalkd:/data 						\ # Beanstalkd data directory for persisting messages between container invocations
#            agaveapi/beanstalkd
#
# Start Tomcat
# docker run -h docker.example.com -i --rm    	  \
#            -p 8888:80                  			    \ # Apache
#            -p 8444:443                  			  \ # Apache SSL
#            --link some-mysql:mysql              \ # MySQL server
#            --link some-mongo:mongo						  \ # MongoDB server
#            --link some-beanstalkd:beanstalkd    \ # Beanstalkd server
#            --name apache											  \ #
#            -v `pwd`/logs:/var/log/http/         \ # volume mount log directory
#            agaveapi/php-api-base
#
# https://bitbucket.org/taccaci/agave-docker-php-api-base
#
######################################################

FROM php:5.4-apache
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu

COPY php/php.ini /usr/local/lib/
COPY apache/httpd.conf /etc/httpd/conf/httpd.conf
COPY apache/userdir.conf /etc/apache2/mods-available/userdir.conf
COPY apache/apache2.conf /etc/apache2/apache2.conf
COPY apache/apache2.conf.dist /etc/apache2/apache2.conf.dist

RUN echo '<?php phpinfo(); ?>' > /var/www/html/index.php

USER root

RUN apt-get update && apt-get install -y supervisor postfix

ADD supervisor/supervisor.conf /etc/supervisor/supervisord.conf
ADD install.sh /opt/install.sh
ADD postfix/postfix.sh /opt/postfix.sh

RUN touch /var/log/mail.log

VOLUME [ "/var/log/http/logs" ]
EXPOSE 80
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
