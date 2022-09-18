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

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
sep=$'\001'

# Configure PHP FPM
sed -i .orig "s${sep}listen = 127.0.0.1:9000${sep}listen = /var/run/php80-fpm.sock${sep}g" /usr/local/etc/php-fpm.d/www.conf
sed -i .orig "s${sep}pm.max_children = 5${sep}pm.max_children = 10${sep}g" /usr/local/etc/php-fpm.d/www.conf

# this could be simplified
# shellcheck disable=SC2129
echo ";Nomad Nextcloud settings..." >> /usr/local/etc/php-fpm.d/www.conf
echo "listen.owner = www" >> /usr/local/etc/php-fpm.d/www.conf
echo "listen.group = www" >> /usr/local/etc/php-fpm.d/www.conf
echo "listen.mode = 0660" >> /usr/local/etc/php-fpm.d/www.conf
echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /usr/local/etc/php-fpm.d/www.conf
echo "env[TMP] = /tmp" >> /usr/local/etc/php-fpm.d/www.conf
echo "env[TMPDIR] = /tmp" >> /usr/local/etc/php-fpm.d/www.conf
echo "env[TEMP] = /tmp" >> /usr/local/etc/php-fpm.d/www.conf

# Configure PHP
cp -f /usr/local/etc/php.ini-production /usr/local/etc/php.ini
cp -f "$TEMPLATEPATH/99-custom.ini" /usr/local/etc/php/99-custom.ini

# check for presence of copied-in /root/nc-config.php and copy over any existing (with backup)
if [ -s "$TEMPLATEPATH/nc-config.php" ]; then
    if [ -s /usr/local/www/nextcloud/config/config.php ]; then
        cp -f /usr/local/www/nextcloud/config/config.php /usr/local/www/nextcloud/config/config.php.old
    fi
    cp -f "$TEMPLATEPATH/nc-config.php" /usr/local/www/nextcloud/config/config.php
fi
