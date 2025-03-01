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

# copy in custom nats.conf file with 127.0.0.1 instead of localhost
# IP search/replace does nothing here.
# Updated: set to use pot IP
< "$TEMPLATEPATH/nats.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/nats.conf

# enable the service
service nats enable