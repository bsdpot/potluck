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

< "$TEMPLATEPATH/supervisord.conf.in" \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" \
  > /usr/local/etc/supervisord.conf

# enable supervisord
service supervisord enable

# start supervisord
service supervisord start || true
