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
mkdir -p /usr/local/etc/prosody/
mkdir -p /var/db/prosody/custom_plugins

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy over prosody.cfg.lua
< "$TEMPLATEPATH/prosody.cfg.lua.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%email%%${sep}$EMAIL${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
  > /usr/local/etc/prosody/prosody.cfg.lua

# setup prosody
echo -ne '\n\n\n\n\n\n\n\n\n\n\n' | prosodyctl cert generate "$DOMAIN"
echo -ne '\n\n\n\n\n\n\n\n\n\n\n' | prosodyctl cert generate auth."$DOMAIN"

# this information is incorrect
# from http://www.bobeager.uk/pdf/jitsi.pdf
# Users are added to FQDN, not to auth.FQDN
# $ prosodyctl register user FQDN password
#
# tested:
# prosodyctl register focus "$DOMAIN" "$KEYPASSWORD"
#
# produces:
# Error: Account creation/modification not supported.
#
# reverting to original command from https://honeyguide.eu/posts/jitsi-freebsd/
#
# retaining this note because there is a problem with focus and video won't start
# however this is not the issue
prosodyctl register focus auth."$DOMAIN" "$KEYPASSWORD"

# check for valid certificates
echo "checking prosody certs"
prosodyctl check certs || true

# check for valid config
echo "checking prosody config"
prosodyctl check config || true

# enable service
service prosody enable
