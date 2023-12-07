#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

DOMAIN="$DOMAIN"
IP="$IP"

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# create directory for local certificates
mkdir -p /usr/local/etc/ssl/

# Copy in openssl.conf with local IP
< "$TEMPLATEPATH/openssl.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/ssl/openssl.conf

# testing highly optimised approach
#

# create private key
/usr/bin/openssl genrsa > /usr/local/etc/ssl/"$DOMAIN".key

# create public key
/usr/bin/openssl req -new -x509 -key /usr/local/etc/ssl/"$DOMAIN".key > /usr/local/etc/ssl/fullchain.cer

# set permissions
chmod 644 /usr/local/etc/ssl/fullchain.cer