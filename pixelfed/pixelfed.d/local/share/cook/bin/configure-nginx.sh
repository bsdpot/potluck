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

# copy in custom nginx and set IP to ip address of pot image
< "$TEMPLATEPATH/nginx.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# Configure php-fpm
cp -f "$TEMPLATEPATH/www.conf.in" /usr/local/etc/php-fpm.d/www.conf

# set php.ini and copy over custom file
cp -f /usr/local/etc/php.ini-production /usr/local/etc/php.ini
cp -f "$TEMPLATEPATH/99-custom.ini.in" /usr/local/etc/php/99-custom.ini

# enable nginx
service nginx enable

# configure php-fpm service manually by fixing
# missing /usr/local/etc/rc.d/php-fpm file
if [ ! -f /usr/local/etc/rc.d/php-fpm ]; then
	cp -f "$TEMPLATEPATH/php-fpm.rc.in" /usr/local/etc/rc.d/php-fpm
	chown root:wheel /usr/local/etc/rc.d/php-fpm
	chmod +x /usr/local/etc/rc.d/php-fpm
fi

# enable php-fpm
service php-fpm enable
