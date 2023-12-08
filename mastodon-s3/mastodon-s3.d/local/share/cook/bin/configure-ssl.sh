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

#old## Copy in openssl.conf with local IP
#old#< "$TEMPLATEPATH/openssl.conf.in" \
#old#  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
#old#  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
#old#  > /usr/local/etc/ssl/openssl.conf

# testing highly optimised approach
#old# create private key
#old#/usr/bin/openssl genrsa > /usr/local/etc/ssl/"$DOMAIN".key
#old# create public key
#old#/usr/bin/openssl req -new -x509 -key /usr/local/etc/ssl/"$DOMAIN".key > /usr/local/etc/ssl/fullchain.cer

# better approach provided openssl >= 1.1.1
# fullchain.cer is just the certificate, not a CA and intermediate too
/usr/bin/openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -days 3650 \
  -nodes -keyout /usr/local/etc/ssl/"$DOMAIN".key -out /usr/local/etc/ssl/fullchain.cer -subj "/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN,DNS:*.$DOMAIN,IP:$IP"

# set permissions
chmod 644 /usr/local/etc/ssl/fullchain.cer
