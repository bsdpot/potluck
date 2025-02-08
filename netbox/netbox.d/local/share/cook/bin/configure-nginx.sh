#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# ensure this exists, won't if private cert option used
mkdir -p /usr/local/www/acmetmp/

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in custom nginx and set IP to ip address of pot image
< "$TEMPLATEPATH/nginx.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# enable nginx
service nginx enable
