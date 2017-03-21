#!/bin/bash

if [[ -f "/app/config/environment.sh" ]]; then
  source /app/config/environment.sh
else
  echo "No environment config present in /app/config/environment.sh. Reading from container environment"
fi

####################################################################
#
# Apache Configuration
#
# Configure Apache log, debug, and document root settings with
# values provided in the environment.
####################################################################

PHP_ERROR_REPORTING=${PHP_ERROR_REPORTING:-"E_ALL & ~E_DEPRECATED & ~E_NOTICE"}
echo "error_reporting = $PHP_ERROR_REPORTING" >> /etc/php/php.ini

# Set document root for this container
if [[ -z "$DOCUMENT_ROOT" ]]; then
  DOCUMENT_ROOT=/var/www/html
fi
sed -i 's#%DOCUMENT_ROOT%#'$DOCUMENT_ROOT'#g' /etc/apache2/httpd.conf
sed -i 's#%DOCUMENT_ROOT%#'$DOCUMENT_ROOT'#g' /etc/apache2/conf.d/ssl.conf

sed -i 's#%HOSTNAME%#'$HOSTNAME'#g' /etc/apache2/httpd.conf
sed -i 's#%HOSTNAME%#'$HOSTNAME'#g' /etc/apache2/conf.d/ssl.conf

# Enable logging to std out
if [[ -n "$LOG_TARGET_STDOUT" ]]; then
  sed -i 's#logs/error_log#/proc/self/fd/2#g' /etc/apache2/httpd.conf
  sed -i 's#logs/access_log#/proc/self/fd/1#g' /etc/apache2/httpd.conf
  sed -i 's#/var/log/apache2/ssl_access_log#/proc/self/fd/1#g' /etc/apache2/conf.d/ssl.conf
  sed -i 's#/var/log/apache2/ssl_error_log#/proc/self/fd/2#g' /etc/apache2/conf.d/ssl.conf
fi

# Enable toggling the log level at startup
if [[ -n "$LOG_LEVEL_DEBUG" ]]; then
  LOG_LEVEL=debug
elif [[ -n "$LOG_LEVEL_WARN" ]]; then
  LOG_LEVEL=warn
elif [[ -n "$LOG_LEVEL_ERROR" ]]; then
  LOG_LEVEL=error
else
  LOG_LEVEL=info
fi

sed -i 's#%LOG_LEVEL%#'$LOG_LEVEL'#g' /etc/apache2/httpd.conf
sed -i 's#%LOG_LEVEL%#'$LOG_LEVEL'#g' /etc/apache2/conf.d/ssl.conf

####################################################################
#
# MYSQL Configuration
#
# Configure MYSQL connection settings at runtime with any SSL certs
# provided in the environment. This _should_ pick up any linked
# containers by default.
####################################################################

if [[ -z "$MYSQL_HOST" ]]; then
  MYSQL_HOST=mysql
fi

if [[ -n "$MYSQL_PORT_3306_TCP_PORT" ]]; then
  MYSQL_PORT=3306
elif [[ -z "$MYSQL_PORT" ]]; then
  MYSQL_PORT=3306
fi

if [[ -n "$MYSQL_ENV_MYSQL_USERNAME" ]]; then
  MYSQL_USERNAME=$MYSQL_ENV_MYSQL_USERNAME
elif [[ -z "$MYSQL_USERNAME" ]]; then
  MYSQL_USERNAME=agaveuser
fi

if [[ -n "$MYSQL_ENV_MYSQL_PASSWORD" ]]; then
  MYSQL_PASSWORD=$MYSQL_ENV_MYSQL_PASSWORD
elif [[ -z "$MYSQL_PASSWORD" ]]; then
  MYSQL_PASSWORD=password
fi

if [[ -n "$MYSQL_ENV_MYSQL_DATABASE" ]]; then
  MYSQL_DATABASE=$MYSQL_ENV_MYSQL_DATABASE
elif [[ -z "$MYSQL_DATABASE" ]]; then
  MYSQL_DATABASE=agave-api
fi
echo "Updating container mysql connection to ${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}..."

if [[ -n "$NEWRELIC_LICENSE_KEY" ]]; then
  if [[ -e /var/www/html/newrelic.ini ]]; then
    echo "New Relic file already present. Skipping config setup"
  else
    echo "newrelic.license='$NEWRELIC_LICENSE_KEY'" > $DOCUMENT_ROOT/newrelic.ini

    if [[ -n "$NEWRELIC_APP_NAME" ]]; then
      echo "newrelic.appname='$NEWRELIC_APP_NAME'" > $DOCUMENT_ROOT/newrelic.ini
    fi
  fi
fi

####################################################################
#
# SSL Configuration
#
# Configure SSL at runtime with any SSL certs provided in the
# environment
####################################################################

# echo "Creating SSL keys for secure communcation..."
# if [[ -z "$SSL_KEY" ]]; then
# 	export KEY=/etc/ssl/apache2/server.key
# 	export DOMAIN=$(hostname)
# 	export PASSPHRASE=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16)
# 	export SUBJ="
# C=US
# ST=Texas
# O=University of Texas
# localityName=Austin
# commonName=$DOMAIN
# organizationalUnitName=TACC
# emailAddress=admin@$DOMAIN"
# 	openssl genrsa -des3 -out /etc/ssl/apache2/server.key -passout env:PASSPHRASE 2048
# 	openssl req -new -batch -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key $KEY -out /etc/ssl/apache2/$DOMAIN.csr -passin env:PASSPHRASE
# 	cp $KEY $KEY.orig
# 	openssl rsa -in $KEY.orig -out $KEY -passin env:PASSPHRASE
# 	openssl x509 -req -days 365 -in /etc/ssl/apache2/$DOMAIN.csr -signkey $KEY -out /etc/ssl/apache2/server.pem
# fi

if [[ -n "$SSL_CERT" ]]; then
  sed -i 's#^SSLCertificateFile .*#SSLCertificateFile '$SSL_CERT'#g' /etc/apache2/conf.d/ssl.conf
fi

if [[ -n "$SSL_KEY" ]]; then
  sed -i 's#^SSLCertificateKeyFile .*#SSLCertificateKeyFile '$SSL_KEY'#g' /etc/apache2/conf.d/ssl.conf
fi

if [[ -n "$SSL_CA_CHAIN" ]]; then
  sed -i 's#^\#SSLCertificateChainFile .*#SSLCertificateChainFile '$SSL_CA_CHAIN'#g' /etc/apache2/conf.d/ssl.conf
fi

if [[ -n "$SSL_CA_CERT" ]]; then
  sed -i 's#^\#SSLCACertificateFile .*#SSLCACertificateFile '$SSL_CA_CERT'#g' /etc/apache2/conf.d/ssl.conf
fi


####################################################################
#
# Email Configuration
#
# No email server is present in the environment, so we use SSMTP
# to provide an email solution to PHP applications relying on the
# `mail()` function. Here we configure it with settings from the
# runtime environment.
# ####################################################################

if [[ -z "${SMTP_HUB}" ]]; then
  SMTP_HUB='smtp.sendgrid.net:587'
fi
sed -ri -e "s/%%SMTP_HUB%%/$SMTP_HUB/" /etc/ssmtp/ssmtp.conf

if [[ -z "${SMTP_USER}" ]]; then
  SMTP_USER=''
fi
sed -ri -e "s/%%SMTP_USER%%/$SMTP_USER/" /etc/ssmtp/ssmtp.conf

if [[ -z "${SMTP_TLS}" ]]; then
  SMTP_TLS='NO'
else
  SMTP_TLS='YES'
fi
sed -ri -e "s/UseSTARTTLS=$SMTP_TLS/UseSTARTTLS=NO/" /etc/ssmtp/ssmtp.conf

if [[ -z "${SMTP_PASSWORD}" ]]; then
  SMTP_PASSWORD=''
fi
sed -ri -e "s/%%SMTP_PASSWORD%%/$SMTP_PASSWORD/" /etc/ssmtp/ssmtp.conf

if [[ -z "${SMTP_FROM_ADDRESS}" ]]; then
  echo "root:$SMTP_FROM_ADDRESS:$SMTP_HUB" >> /etc/ssmtp/revaliases
  echo "apache:$SMTP_FROM_ADDRESS:$SMTP_HUB" >> /etc/ssmtp/revaliases
  echo "admin:$SMTP_FROM_ADDRESS:$SMTP_HUB" >> /etc/ssmtp/revaliases
fi

####################################################################
#
# Filesystem Configuration
#
# Create any log, temp, or other application specific directories
# needed which may not be present at runtime.
#####################################################################

# create the scratch directory
if [[ -z "$IPLANT_SERVER_TEMP_DIR" ]]; then
	IPLANT_SERVER_TEMP_DIR=/scratch
fi

mkdir -p "$IPLANT_SERVER_TEMP_DIR"

####################################################################
#
# Synchronization and Service Discovery
#
# Make sure the system clock is up to data and provide any discovery
# functions needed to initialize the environment or application.
#####################################################################

# start ntpd because clock skew is astoundingly real
ntpd -d -p pool.ntp.org &

# finally, run the command passed into the container
exec "$@"
