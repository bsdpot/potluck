#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# setup my.cnf file for exporter user
< "$TEMPLATEPATH/exporter.my.cnf.in" \
  sed "s${sep}%%dbscrapepass%%${sep}${DBSCRAPEPASS}${sep}g" \
  > /usr/local/etc/mysqld_exporter.cnf

# if no exporter user exists, create it
if [ $(echo "SELECT COUNT(*) FROM mysql.user WHERE user = 'exporter'" | /usr/local/bin/mysql -uroot -p"${DBROOTPASS}" | tail -n1) -gt 0 ]
then
    echo "Not creating exporter user as already exists"
else
    echo "Creating exporter user"
    # setup mysql exporter user
    /usr/local/bin/mysql -uroot -p"${DBROOTPASS}" -e "CREATE USER 'exporter'@'localhost' IDENTIFIED BY '${DBSCRAPEPASS}' WITH MAX_USER_CONNECTIONS 3;"
    # and grant required permissions
    /usr/local/bin/mysql -uroot -p"${DBROOTPASS}" -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';"
fi

# enable mysql_exporter service
service mysqld_exporter enable
sysrc mysqld_exporter_conffile="/usr/local/etc/mysqld_exporter.cnf"
sysrc mysqld_exporter_args="--log.level=warn"
echo "mysqld_exporter_listen_address=\"$IP:9104\"" >> /etc/rc.conf
