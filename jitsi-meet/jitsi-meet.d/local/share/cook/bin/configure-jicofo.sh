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

# copy over jicofo.conf
< "$TEMPLATEPATH/jicofo.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
  > /usr/local/etc/jitsi/jicofo/jicofo.conf

# Disable updating the RC file, the default should work fine but runs as user jicofo
#disable## make a backup any existing RC file
#disable#if [ -f /usr/local/etc/rc.d/jicofo ]; then
#disable#  cp -f /usr/local/etc/rc.d/jicofo /usr/local/etc/rc.d/jicofo.bak
#disable#  chmod -x /usr/local/etc/rc.d/jicofo.bak
#disable#fi
#
#disable### update rc script for jicofo
#disable### see https://honeyguide.eu/posts/jitsi-freebsd/
#disable### also need -Djavax.net.ssl.trustStorePassword=changeit
#disable#< "$TEMPLATEPATH/rc-jicofo.in" \
#disable#  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
#disable#  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
#disable#  > /usr/local/etc/rc.d/jicofo
#
## set execute permissions
#disable#chmod +x /usr/local/etc/rc.d/jicofo

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