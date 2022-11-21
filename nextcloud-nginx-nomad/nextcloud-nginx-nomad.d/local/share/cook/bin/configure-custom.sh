#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
# sep=$'\001'

# check for presence of copied-in /root/nc-config.php and copy over any existing (with backup)
# nc-config.php to fall away in future in favour of following three files for multifile config
if [ -s /root/nc-config.php ]; then
    if [ -s /usr/local/www/nextcloud/config/config.php ]; then
        cp -f /usr/local/www/nextcloud/config/config.php /usr/local/www/nextcloud/config/config.php.old
    fi
    cp -f /root/nc-config.php /usr/local/www/nextcloud/config/config.php
    chown www:www /usr/local/www/nextcloud/config/config.php
fi

# check for copied-in minio.config.php and if exists copy across to nextcloud config dir
if [ -s /root/objectstore.config.php ]; then
    cp -f /root/objectstore.config.php /usr/local/www/nextcloud/config/objectstore.config.php
    chown www:www /usr/local/www/nextcloud/config/objectstore.config.php
fi

# check for copied in mysql.config.php and if exists copy across to nextcloud config dir
if [ -s /root/mysql.config.php ]; then
    cp -f /root/mysql.config.php /usr/local/www/nextcloud/config/mysql.config.php
    chown www:www /usr/local/www/nextcloud/config/mysql.config.php
fi

# check for copied in custom.config.php and if exists copy across to nextcloud config dir
# this file would include things previously in nc-config.php from legacy setup
if [ -s /root/custom.config.php ]; then
    cp -f /root/custom.config.php /usr/local/www/nextcloud/config/custom.config.php
    chown www:www /usr/local/www/nextcloud/config/custom.config.php
fi
