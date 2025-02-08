#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

#htpasswd -b -c /usr/local/etc/backuppc/htpasswd backuppc "$PASSWORD"
htpasswd -b -c /usr/local/etc/backuppc/htpasswd admin "$PASSWORD"
#ln -s /usr/local/www/cgi-bin/BackupPC_Admin /usr/local/www/cgi-bin/backuppc.pl

# update httpd.conf to point to backuppc
[ -w /usr/local/etc/apache24/httpd.conf ] && sed -i '' "s|/usr/local/www/apache24/data|/usr/local/www/backuppc|" /usr/local/etc/apache24/httpd.conf

# enable apache24
service apache24 enable
