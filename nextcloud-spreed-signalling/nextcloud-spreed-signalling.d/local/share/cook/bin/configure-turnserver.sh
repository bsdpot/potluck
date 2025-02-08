#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy over turnserver.conf
< "$TEMPLATEPATH/turnserver.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%privateip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%publicip%%${sep}$PUBLICIP${sep}g" | \
  sed "s${sep}%%keypassword%%${sep}$KEYPASSWORD${sep}g" | \
  sed "s${sep}%%turnpassword%%${sep}$HASHTURNPASSWORD${sep}g" \
  > /usr/local/etc/turnserver.conf

# enable service
service turnserver enable || true