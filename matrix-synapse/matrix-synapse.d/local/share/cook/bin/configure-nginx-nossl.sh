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

# copy in custom nginx and set IP to ip address of pot image
< "$TEMPLATEPATH/nginx.nossl.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# enable nginx
service nginx enable || true

