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
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%publicip%%${sep}$PUBLICIP${sep}g" | \
  sed "s${sep}%%privateip%%${sep}$IP${sep}g" \
  > /usr/local/etc/jitsi/videobridge/sip-communicator.properties

# if no image filename been passed in for a file copied-in to
# /usr/local/www/jitsi-meet/image/filename.jpg then default to
# watermark.svg
# if an image has been passed, check for URL passed in
if [ -n "$IMAGE" ]; then
	IMAGE="$IMAGE"
	export IMAGE
	if [ -n "$LINK" ]; then
		LINK="$LINK"
		export LINK
	fi
else
	IMAGE="watermark.svg"
	export IMAGE
fi

# check if resolution has been passed in or set a default of 360
if [ -n "$RESOLUTION" ]; then
	RESOLUTION="$RESOLUTION"
	export RESOLUTION
else
	RESOLUTION="360"
	export RESOLUTION
fi

# copy over config.js
< "$TEMPLATEPATH/config.js.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" | \
  sed "s${sep}%%resolution%%${sep}$RESOLUTION${sep}g" | \
  sed "s${sep}%%image%%${sep}$IMAGE${sep}g" | \
  sed "s${sep}%%link%%${sep}$LINK${sep}g" \
  > /usr/local/www/jitsi-meet/config.js

# copy over interface_config.js
< "$TEMPLATEPATH/interface_config.js.in" \
  sed "s${sep}%%image%%${sep}$IMAGE${sep}g" | \
  sed "s${sep}%%link%%${sep}$LINK${sep}g" \
  > /usr/local/www/jitsi-meet/interface_config.js

# Disabling custom RC file running as root, using default running as user jvb
#disable## make a backup any existing RC file
#disable#if [ -f /usr/local/etc/rc.d/jitsi-videobridge ]; then
#disable#  cp -f /usr/local/etc/rc.d/jitsi-videobridge /usr/local/etc/rc.d/jitsi-videobridge.bak
#disable#  chmod -x /usr/local/etc/rc.d/jitsi-videobridge.bak
#disable#fi
#
#disable### update rc script for jitsi-videobridge
#disable### see https://honeyguide.eu/posts/jitsi-freebsd/
#disable#< "$TEMPLATEPATH/rc-jitsi-videobridge.in" \
#disable#  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
#disable#  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
#disable#  > /usr/local/etc/rc.d/jitsi-videobridge
#
#disable## set execute permission
#disable#chmod +x /usr/local/etc/rc.d/jitsi-videobridge

# copy over manifest.json
cp -f "$TEMPLATEPATH/manifest.json.in" /usr/local/www/jitsi-meet/manifest.json

# enable service
sysrc jitsi_videobridge_flags="--apis=rest,xmpp" || true
sysrc jitsi_videobridge_maxmem="3072m" || true
service jitsi-videobridge enable || true
