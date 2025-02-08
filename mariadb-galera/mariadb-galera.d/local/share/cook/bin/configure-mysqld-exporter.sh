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

# setup my.cnf file for exporter user
< "$TEMPLATEPATH/exporter.my.cnf.in" \
  sed "s${sep}%%dbscrapepass%%${sep}${DBSCRAPEPASS}${sep}g" \
  > /usr/local/etc/mysqld_exporter.cnf

# mysqld_exporter runs as user nobody and needs everybody read access to config file
chmod 644 /usr/local/etc/mysqld_exporter.cnf

# enable mysql_exporter service
service mysqld_exporter enable || true
sysrc mysqld_exporter_conffile="/usr/local/etc/mysqld_exporter.cnf"
sysrc mysqld_exporter_args="--log.level=warn"
echo "mysqld_exporter_listen_address=\"$IP:9104\"" >> /etc/rc.conf
