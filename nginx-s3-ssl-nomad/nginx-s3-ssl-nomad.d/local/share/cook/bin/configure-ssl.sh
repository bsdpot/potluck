#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

DOMAIN="$DOMAIN"

# create directory for local certificates
mkdir -p /usr/local/etc/ssl/

# better approach provided openssl >= 1.1.1
# fullchain.cer is just the certificate, not a CA and intermediate too
/usr/bin/openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -days 3650 \
  -nodes -keyout /usr/local/etc/ssl/"$DOMAIN".key -out /usr/local/etc/ssl/fullchain.cer -subj "/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN,DNS:*.$DOMAIN,IP:127.0.0.1"

# set permissions
chmod 644 /usr/local/etc/ssl/fullchain.cer
