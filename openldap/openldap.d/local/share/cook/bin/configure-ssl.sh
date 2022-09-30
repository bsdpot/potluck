#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

cd /usr/local/etc/openldap/private/

/usr/bin/openssl req -new -x509 -days 3650 \
 -nodes -keyout ca.key \
 -out /usr/local/etc/openldap/ca.crt \
 -subj "/C=CC/ST=Province/L=City/O=None/CN=$DOMAIN"

/usr/bin/openssl req -new -nodes \
 -keyout server.key \
 -out /usr/local/etc/openldap/server.csr \
 -subj "/C=CC/ST=Province/L=City/O=None/CN=$DOMAIN"

/usr/bin/openssl x509 -req -days 3650 \
 -in /usr/local/etc/openldap/server.csr \
 -out /usr/local/etc/openldap/server.crt \
 -CA /usr/local/etc/openldap/ca.crt \
 -CAkey ca.key \
 -CAcreateserial

/usr/bin/openssl req -nodes -new \
 -keyout client.key \
 -out client.csr \
 -subj "/C=CC/ST=Province/L=City/O=None/CN=$DOMAIN"

/usr/bin/openssl x509 -req -days 3650 \
 -in client.csr \
 -out /usr/local/etc/openldap/client.crt \
 -CA /usr/local/etc/openldap/ca.crt \
 -CAkey ca.key
