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

# set custom plugins directory (not in use)
mkdir -p /var/db/prosody/custom_plugins
chown -R prosody:prosody /var/db/prosody/custom_plugins

# custom logging
mkdir -p /var/log/prosody
touch /var/log/prosody/prosody.log
touch /var/log/prosody/prosody.err
chown -R prosody:prosody /var/log/prosody

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy over prosody.cfg.lua
< "$TEMPLATEPATH/prosody.cfg.lua.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%email%%${sep}$EMAIL${sep}g" | \
  sed "s${sep}%%turnpassword%%${sep}$HASHTURNPASSWORD${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" \
  > /usr/local/etc/prosody/prosody.cfg.lua

# setup prosody
# shellcheck disable=SC2039
echo -ne '\n\n\n\n\n\n\n\n\n\n\n' | prosodyctl cert generate "$DOMAIN" || true
# shellcheck disable=SC2039
echo -ne '\n\n\n\n\n\n\n\n\n\n\n' | prosodyctl cert generate auth."$DOMAIN" || true

# disabling as prosody localhost virtualhost disabled
# shellcheck disable=SC2039
#echo -ne '\n\n\n\n\n\n\n\n\n\n\n' | prosodyctl cert generate localhost || true

# Set up truststore
keytool \
  -noprompt \
  -storetype jks  \
  -keystore /usr/local/etc/jitsi/jicofo/truststore.jks \
  -storepass "$KEYPASSWORD" \
  -importcert -alias prosody \
  -file "/var/db/prosody/auth.$DOMAIN.crt" || true

# set permissions on truststore
chown jicofo:jicofo /usr/local/etc/jitsi/jicofo/truststore.jks

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
prosodyctl register jvb auth."$DOMAIN" "$KEYPASSWORD" || true
prosodyctl register focus auth."$DOMAIN" "$KEYPASSWORD" || true

# adding extra step from
# https://youtu.be/LJOpSDcwWIA
# docs
# https://modules.prosody.im/mod_roster_command.html
#prosodyctl mod_roster_command subscribe focus."$DOMAIN" focus@auth."$DOMAIN" || true
# with password
prosodyctl mod_roster_command subscribe focus."$DOMAIN" focus@auth."$DOMAIN" "$KEYPASSWORD" || true

# check for valid certificates
echo "checking prosody certs"
prosodyctl check certs || true

# check for valid config
echo "checking prosody config"
prosodyctl check config || true

# enable service
service prosody enable || true
