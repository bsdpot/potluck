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

# make web directory and set permissions
mkdir -p /usr/local/www/dmarc-report

# set ownership and permissions on web directory
chown www:www /usr/local/www/dmarc-report
chmod 755 /usr/local/www/dmarc-report

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in custom nginx.conf and set IP to ip address of pot image
< "$TEMPLATEPATH/nginx.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# copy in standard html
# remove this and replace with website files in future
cp -f "$TEMPLATEPATH/index.html.in" /usr/local/www/dmarc-report/index.html

# enable nginx
service nginx enable
