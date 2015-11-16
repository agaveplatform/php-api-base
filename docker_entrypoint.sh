#!/bin/bash

if [[ -f "/app/config/environment.sh" ]]; then
  source /app/config/environment.sh
else
  echo "No environment config present in /app/config/environment.sh. Reading from container environment"
fi

PHP_ERROR_REPORTING=${PHP_ERROR_REPORTING:-"E_ALL & ~E_DEPRECATED & ~E_NOTICE"}
echo "error_reporting = $PHP_ERROR_REPORTING" >> /etc/php/php.ini

if [[ -n "$DOCUMENT_ROOT" ]]; then
  sed -i 's#^DocumentRoot ".*#DocumentRoot "'$DOCUMENT_ROOT'"#g' /etc/apache2/httpd.conf
  sed -i 's#^<Directory ".*#<Directory "'$DOCUMENT_ROOT'">#g' /etc/apache2/httpd.conf
else
  DOCUMENT_ROOT=/var/www/html
fi

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

# if [[ -e /etc/apache2/conf.d/ssl.conf.bak ]]; then
#   cp /etc/apache2/conf.d/ssl.conf.bak /etc/apache2/conf.d/ssl.conf
# else
#   cp /etc/apache2/conf.d/ssl.conf /etc/apache2/conf.d/ssl.conf.bak
# fi

#export SSL_CERT=we_done_switched_the_ssl_cert
if [[ -n "$SSL_CERT" ]]; then
  sed -i 's#^SSLCertificateFile .*#SSLCertificateFile '$SSL_CERT'#g' /etc/apache2/conf.d/ssl.conf
fi
#grep "we_done_switched_the_ssl_cert" /etc/apache2/conf.d/ssl.conf

# export SSL_KEY=we_done_switched_the_ssl_key
if [[ -n "$SSL_KEY" ]]; then
  sed -i 's#^SSLCertificateKeyFile .*#SSLCertificateKeyFile '$SSL_KEY'#g' /etc/apache2/conf.d/ssl.conf
fi
# grep "we_done_switched_the_ssl_key" /etc/apache2/conf.d/ssl.conf

# export SSL_CA_CHAIN=we_done_switched_the_cert_chain
if [[ -n "$SSL_CA_CHAIN" ]]; then
  sed -i 's#^\#SSLCertificateChainFile .*#SSLCertificateChainFile '$SSL_CA_CHAIN'#g' /etc/apache2/conf.d/ssl.conf
fi
# grep "we_done_switched_the_cert_chain" /etc/apache2/conf.d/ssl.conf

# export SSL_CA_CERT=we_done_switched_the_ca_cert
if [[ -n "$SSL_CA_CERT" ]]; then
  sed -i 's#^\#SSLCACertificateFile .*#SSLCACertificateFile '$SSL_CA_CERT'#g' /etc/apache2/conf.d/ssl.conf
fi
# grep "we_done_switched_the_ca_cert" /etc/apache2/conf.d/ssl.conf

exec "$@"
