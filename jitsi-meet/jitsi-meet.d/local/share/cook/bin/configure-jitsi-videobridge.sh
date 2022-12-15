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
mkdir -p /usr/local/etc/jitsi/videobridge/
mkdir -p /usr/local/www/jitsi-meet

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy over jitsi-videobridge.conf
< "$TEMPLATEPATH/jitsi-videobridge.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
  > /usr/local/etc/jitsi/videobridge/jitsi-videobridge.conf

# copy over sip-communicator.properties
< "$TEMPLATEPATH/sip-communicator.properties.in" \
  sed "s${sep}%%publicip%%${sep}$PUBLICIP${sep}g" | \
  sed "s${sep}%%privateip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
  > /usr/local/etc/jitsi/videobridge/sip-communicator.properties

# copy over config.js
< "$TEMPLATEPATH/config.js.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
  > /usr/local/www/jitsi-meet/config.js

# update rc script for jitsi-videobridge
# see https://honeyguide.eu/posts/jitsi-freebsd/
< "$TEMPLATEPATH/rc-jitsi-videobridge.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
  > /usr/local/etc/rc.d/jitsi-videobridge

# copy over manifest.json
cp -f "$TEMPLATEPATH/manifest.json.in" /usr/local/www/jitsi-meet/manifest.json

# enable service
sysrc jitsi_videobridge_flags="--apis=rest,xmpp"
service jitsi-videobridge enable
