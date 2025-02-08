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

# copy in custom configuration files

# proxy.conf
< "$TEMPLATEPATH/proxy.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/ncs/proxy.conf

# IP is not used in this file but port might be set in future here
< "$TEMPLATEPATH/gnatsd.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/ncs/gnatsd.conf

# this is the main configuration file
< "$TEMPLATEPATH/server.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%hashkey%%${sep}$HASHKEY${sep}g" | \
  sed "s${sep}%%blockkey%%${sep}$BLOCKKEY${sep}g" | \
  sed "s${sep}%%nextcloudurl%%${sep}$NEXTCLOUDURL${sep}g" | \
  sed "s${sep}%%sharedsecret%%${sep}$SHAREDSECRET${sep}g" \
  > /usr/local/etc/ncs/server.conf

# enable the service
service ncs_signaling enable
