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
# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# pre-configure phpldapadmin configuration
< "$TEMPLATEPATH/phpldapadmin.config.php.in" \
 sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
 sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
 sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
 sed "s${sep}%%genericusername%%${sep}$USERNAME${sep}g" \
> /usr/local/www/phpldapadmin/config/config.php

# update apache24 index.html
cp -f "$TEMPLATEPATH/index.html.in" /usr/local/www/apache24/data/index.html
