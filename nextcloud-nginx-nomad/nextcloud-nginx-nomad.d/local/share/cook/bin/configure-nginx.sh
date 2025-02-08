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

# set perms on /usr/local/www/nextcloud/*
chown -R www:www /usr/local/www/nextcloud

# set perms on DATADIR
chown -R www:www "${DATADIR}"

# Configure NGINX
cp -f "$TEMPLATEPATH/nginx.conf" /usr/local/etc/nginx/nginx.conf

# update mime.types file
# we want to include the following
#  application/javascript js mjs;
#
cp -f "$TEMPLATEPATH/mime.types.in" /usr/local/etc/nginx/mime.types
