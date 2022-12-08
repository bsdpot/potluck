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
mkdir -p /var/db/prosody/

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
prosodyctl register focus auth."$DOMAIN" "$KEYPASSWORD"

# enable service
service prosody enable
