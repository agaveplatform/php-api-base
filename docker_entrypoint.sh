#!/bin/bash

if [[ -f "/app/config/environment.sh" ]]; then
  source /app/config/environment.sh
else
  echo "No environment config present in /app/config/environment.sh. Reading from container environment"
fi

if [[ ! -f "/ssl/server.key" ]]; then
        mkdir -p /ssl
        KEY=/ssl/server.key
        CERT=/ssl/server.crt
        DOMAIN=$(hostname)
        CSR=/ssl/$DOMAIN.csr
        export PASSPHRASE=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16)
        SUBJ="
C=US
ST=Texas
O=University of Texas
localityName=Austin
commonName=$DOMAIN
organizationalUnitName=TACC
emailAddress=admin@$DOMAIN
"
        openssl genrsa -des3 -out $KEY -passout env:PASSPHRASE 2048
        openssl req -new -batch -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key $KEY -out $CSR -passin env:PASSPHRASE
        cp $KEY $KEY.orig
        openssl rsa -in $KEY.orig -out $KEY -passin env:PASSPHRASE
        openssl x509 -req -days 365 -in $CSR -signkey $KEY -out $CERT
fi

#HOSTLINE=$(echo $(ip -f inet addr show eth0 | grep 'inet' | awk '{ print $2 }' | cut -d/ -f1) $(hostname) $(hostname -s))
#echo $HOSTLINE >> /etc/hosts

# link in the ssl certs at runtime to allow for valid certs to be mounted in a volume
ln -s $KEY /etc/ssl/private/server.key
ln -s $CERT /etc/ssl/certs/server.crt

# if a ca bundle is present, load it and update the ssl.conf file
if [[ -e /etc/httpd/ssl/ca-bundle.crt ]]; then
  ln -s /ssl/ca-bundle.crt /etc/pki/tls/certs/server-ca-chain.crt
  set -i 's/#SSLCACertificateFile/SSLCACertificateFile/' /etc/apache2/sites-available/default-ssl.conf
fi

# if a ca cert chain file is present, load it and update the ssl.conf file
if [[ -e /etc/httpd/ssl/ca-chain.crt ]]; then
  ln -s /ssl/ca-chain.crt /etc/pki/tls/certs/server-ca-chain.crt
  set -i 's/#SSLCertificateChainFile/SSLCertificateChainFile/' /etc/apache2/sites-available/default-ssl.conf
fi

#service rsyslog start
exec "$@"
