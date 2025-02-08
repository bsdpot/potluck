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

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
# sep=$'\001'

# Configure php-fpm from template
cp -f "$TEMPLATEPATH/www.conf.in" /usr/local/etc/php-fpm.d/www.conf

# Configure PHP from templates
cp -f /usr/local/etc/php.ini-production /usr/local/etc/php.ini
cp -f "$TEMPLATEPATH/99-custom.ini" /usr/local/etc/php/99-custom.ini

# manually create php log and set owner


# confirm logs exist with correct permissions
if [ -d /var/log/nginx ]; then
    touch /var/log/nginx/php.error.log
    chown www:www /var/log/nginx/php.error.log

    touch /var/log/nginx/php.scripts.log
    chown www:www /var/log/nginx/php.scripts.log

    touch /var/log/nginx/fpm-php.www.log
    chown www:www /var/log/nginx/php.error.log
fi
