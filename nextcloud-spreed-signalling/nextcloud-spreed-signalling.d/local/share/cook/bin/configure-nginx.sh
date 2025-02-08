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
< "$TEMPLATEPATH/nginx.conf.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# make directories
mkdir -p /usr/local/www/spreed

# copy default index.html
cp "$TEMPLATEPATH/index.html.in" /usr/local/www/spreed/index.html

# enable nginx
if [ -f "/usr/local/etc/ssl/${DOMAIN}.key" ]; then
    service nginx enable || true
else
    echo "Cannot enable nginx. Missing /usr/local/etc/ssl/${DOMAIN}.key"
    exit 1
fi
