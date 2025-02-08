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

# copy in mysqld server.cnf with galera variables included
< "$TEMPLATEPATH/server.cnf.in" \
  sed "s${sep}%%serverid%%${sep}$SERVERID${sep}g" | \
  sed "s${sep}%%galeracluster%%${sep}$GALERACLUSTER${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" \
  > /usr/local/etc/mysql/conf.d/server.cnf

# fix error on startup with new system
#  [Warning] Failed to load slave replication state from table mysql.gtid_slave_pos:
#  1017: Can't find file: './mysql/' (errno: 2 "No such file or directory")
#
# Fix involves passing --disable-log-bin in mysql_install_db_args
#
sed -i '' "s${sep}basedir=/usr/local${sep}basedir=/usr/local --disable-log-bin${sep}" /usr/local/etc/rc.d/mysql-server

# Configure dump cronjob
if [ -n "${DUMPSCHEDULE+x}" ];
then
   echo "${DUMPSCHEDULE}       root   /usr/bin/nice -n 20 /usr/local/bin/mysqldump -u ${DUMPUSER} -v --all-databases --all-tablespaces --routines --events --triggers --single-transaction > ${DUMPFILE} 2>/var/log/dump.log" >> /etc/crontab
fi

# set custom mount in as dbdir
#sysrc mysql_dbdir="/var/db/mysql"

# enable clustering
sysrc mysql_args="--wsrep-on"

# enable the service
service mysql-server enable || true

# We do not know if the database that is mounted from outside has already been run
# with this MariaDB release, so to be sure we upgrade it before we start the service
#if [ -e /var/db/mysql/mysql ]
if [ -e /var/db/mysql/mysql ]; then
    chown -R mysql /var/db/mysql
    chgrp -R mysql /var/db/mysql
    chmod -R ug+rw /var/db/mysql
fi

# If we do not find a database, we will initialise one
if [ ! -e /var/db/mysql/mysql ]; then
    timeout --foreground 120 \
      sh -c 'while ! service mysql-server status; do
        service mysql-server start || true; sleep 5;
      done'
    echo "Performing manual SQL steps to duplicate mysql_secure_installation via automation"
    /usr/local/bin/mysql -sfu root <<EOF
-- set root password
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DBROOTPASS}');
-- delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- delete remote root capabilities
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- drop database 'test'
DROP DATABASE IF EXISTS test;
-- also make sure there are lingering permissions to it
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- make changes immediately
FLUSH PRIVILEGES;
EOF
else
    timeout --foreground 120 \
      sh -c 'while ! service mysql-server status; do
        service mysql-server start || true; sleep 5;
      done'
    /usr/local/bin/mysql_upgrade || true
fi
