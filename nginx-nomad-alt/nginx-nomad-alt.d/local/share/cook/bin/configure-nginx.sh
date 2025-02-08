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

# make sure /usr/local/www/stdwebsite exists
mkdir -p /usr/local/www/stdwebsite

# set www owner on files
chown -R www:www /usr/local/www/stdwebsite

# copy in custom nginx and set IP to ip address of pot image
< "$TEMPLATEPATH/nginx.conf.in" \
  sed "s${sep}%%servername%%${sep}$SERVERNAME${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# enable nginx
service nginx enable || true
