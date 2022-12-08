#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# make directories
mkdir -p /usr/local/etc/jitsi/jicofo/

# Set up jicofo
keytool \
  -noprompt \
  -keystore /usr/local/etc/jitsi/jicofo/truststore.jks \
  -storepass "$KEYPASSWORD" \
  -importcert -alias prosody -file "/var/db/prosody/auth.$DOMAIN.crt"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy over jitsi-videobridge.conf
< "$TEMPLATEPATH/jicofo.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
  > /usr/local/etc/jitsi/jicofo/jicofo.conf

# enable service
service jicofo enable
