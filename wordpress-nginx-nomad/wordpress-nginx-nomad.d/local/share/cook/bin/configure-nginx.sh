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

# set perms on /usr/local/www/wordpress/*
chown -R www:www /usr/local/www/wordpress

## we don't need this currently so oommenting out
# Fix www group memberships so it works with fuse mounted directories
#pw addgroup -n newwww -g 1001
#pw moduser www -u 1001 -G 80,0,1001

# Configure NGINX
cp -f "$TEMPLATEPATH/nginx.conf" /usr/local/etc/nginx/nginx.conf
