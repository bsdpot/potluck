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

# eliminate a log error
touch /usr/local/etc/jitsi/jicofo/sip-communicator.properties
chown jicofo:jicofo /usr/local/etc/jitsi/jicofo/sip-communicator.properties

# copy over jicofostatus.sh, runs:
# [ curl -s "http://localhost:8080/debug?full=true" | jq . ]
mkdir -p /root/bin
cp -f "$TEMPLATEPATH/jicofostatus.sh.in" /root/bin/jicofostatus.sh
chmod +x /root/bin/jicofostatus.sh

# enable service
sysrc jicofo_maxmem="3072m"
service jicofo enable || true
