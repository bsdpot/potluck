#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# create local ssl directory
mkdir -p /usr/local/etc/ssl/

# create self-signed cert
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
 -keyout /usr/local/etc/ssl/cert.key \
 -out /usr/local/etc/ssl/cert.crt \
 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"

# set permissions
chmod 644 /usr/local/etc/ssl/cert.crt
chmod 600 /usr/local/etc/ssl/cert.key

