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

# make necessary directories second time, related to altnetwork testing
mkdir -p /mnt/smokeping/data
mkdir -p /mnt/smokeping/imagecache
mkdir -p /mnt/smokeping/run
chown -R smokeping:smokeping /mnt/smokeping

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# Custom file
# shellcheck disable=SC2039
if [ -f /root/config.in ]; then
	cp -f /root/config.in /usr/local/etc/smokeping/config
else
	< "$TEMPLATEPATH/config.in" \
	  sed "s${sep}%%email%%${sep}$EMAIL${sep}g" | \
	  sed "s${sep}%%alertemail%%${sep}$ALERTEMAIL${sep}g" | \
	  sed "s${sep}%%mailhost%%${sep}$MAILHOST${sep}g" | \
	  sed "s${sep}%%hostname%%${sep}$HOSTNAME${sep}g" \
	> /usr/local/etc/smokeping/config
fi

# enable the service
service smokeping enable
