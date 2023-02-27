#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

DOMAIN="$DOMAIN"

#cd /usr/local/etc/openldap/private/

mkdir -p /usr/local/etc/openldap/private/

/usr/bin/openssl req -new -x509 -days 3650 \
 -nodes -keyout /usr/local/etc/openldap/private/ca.key \
 -out /usr/local/etc/openldap/ca.crt \
 -subj "/C=CC/ST=Province/L=City/O=None/CN=$DOMAIN"

/usr/bin/openssl req -new -nodes \
 -keyout /usr/local/etc/openldap/private/server.key \
 -out /usr/local/etc/openldap/server.csr \
 -subj "/C=CC/ST=Province/L=City/O=None/CN=$DOMAIN"

/usr/bin/openssl x509 -req -days 3650 \
 -in /usr/local/etc/openldap/server.csr \
 -out /usr/local/etc/openldap/server.crt \
 -CA /usr/local/etc/openldap/ca.crt \
 -CAkey /usr/local/etc/openldap/private/ca.key \
 -CAcreateserial

/usr/bin/openssl req -nodes -new \
 -keyout /usr/local/etc/openldap/private/client.key \
 -out /usr/local/etc/openldap/private/client.csr \
 -subj "/C=CC/ST=Province/L=City/O=None/CN=$DOMAIN"

/usr/bin/openssl x509 -req -days 3650 \
 -in /usr/local/etc/openldap/private/client.csr \
 -out /usr/local/etc/openldap/client.crt \
 -CA /usr/local/etc/openldap/ca.crt \
 -CAkey /usr/local/etc/openldap/private/ca.key

# set file permissions with owner ldap
chown -R ldap:ldap /usr/local/etc/openldap/private/
chown ldap:ldap /usr/local/etc/openldap/ca.crt
chown ldap:ldap /usr/local/etc/openldap/server.crt