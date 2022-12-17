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

# copy over jicofo.conf
< "$TEMPLATEPATH/jicofo.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" | \
  sed "s${sep}%%secpassword%%${sep}$SECPASSWORD${sep}g" \
  > /usr/local/etc/jitsi/jicofo/jicofo.conf

## Removed ##
## update rc script for jicofo
## see https://honeyguide.eu/posts/jitsi-freebsd/
#< "$TEMPLATEPATH/rc-jicofo.in" \
#  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
#  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" | \
#  sed "s${sep}%%secpassword%%${sep}$SECPASSWORD${sep}g" \
#  > /usr/local/etc/rc.d/jicofo
#
## set execute permissions
#chmod +x /usr/local/etc/rc.d/jicofo
###

# copy over jicofostatus.sh, runs:
# [ curl -s "http://localhost:8080/debug?full=true" | jq . ]
mkdir -p /root/bin
cp -f "$TEMPLATEPATH/jicofostatus.sh.in" /root/bin/jicofostatus.sh
chmod +x /root/bin/jicofostatus.sh

# enable service
sysrc jicofo_env_file="/usr/local/etc/jitsi/jicofo/jicofo.conf"
sysrc jicofo_maxmem="3072m"
service jicofo enable || true