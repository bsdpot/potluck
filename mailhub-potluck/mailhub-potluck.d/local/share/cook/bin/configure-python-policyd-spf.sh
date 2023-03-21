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

# make directories if they don't exist
mkdir -p /usr/local/etc/python-policyd-spf

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# setup a default policyd-spf.conf where the HELO_reject is set to False and add whitelist
< "$TEMPLATEPATH/policyd-spf.conf.in" \
  sed "s${sep}%%postnetworks%%${sep}$POSTNETWORKS${sep}g" \
  > /usr/local/etc/python-policyd-spf/policyd-spf.conf
