#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# safe(r) separator for sed
# shellcheck disable=SC3003,SC2039
sep=$'\001'

# if persistent storage data directory doesn't exist, create it
# change to /17/ for postgres 17 and elsewhere in this file
if [ ! -d /mnt/postgres/data/16 ]; then
	mkdir -p /mnt/postgres/data/16
	chown -R postgres:postgres /mnt/postgres/
	chmod -R 750 /mnt/postgres/
fi

# enable postgresql
service postgresql enable
sysrc postgresql_data="/mnt/postgres/data/16/"

# modify postgres user homedir to /mnt/postgres/data/16
/usr/sbin/pw usermod -n postgres -d /mnt/postgres/data/16 -s /bin/sh

# initdb step, run only if PG_VERSION file doesn't exist
if [ ! -f /mnt/postgres/data/16/PG_VERSION ]; then
	service postgresql initdb || true
fi

# get the timezone
if [ -f /mnt/postgres/data/16/postgresql.conf ]; then
	MYTIMEZONE=$(grep log_timezone /mnt/postgres/data/16/postgresql.conf | awk -F "= " '{print $2}')
	export MYTIMEZONE
else
	echo "error extracting a timezone value: $MYTIMEZONE"
	exit 1
fi

# copy in custom postgresql.conf with local network access and set timezone
< "$TEMPLATEPATH/postgresql.conf.in" \
  sed "s${sep}%%timezone%%${sep}$MYTIMEZONE${sep}g" \
  > /mnt/postgres/data/16/postgresql.conf

# set permissions
chown postgres:postgres /mnt/postgres/data/16/postgresql.conf

# disabled, no network access required
# # copy in custom pg_hba.conf and set local network access
# < "$TEMPLATEPATH/pg_hba.conf.in" \
#   sed "s${sep}%%ip4network%%${sep}$IP4NETWORK${sep}g" \
#   > /mnt/postgres/data/16/pg_hba.conf
#
# disabled, no network access required
# set permissions
# chown postgres:postgres /mnt/postgres/data/16/pg_hba.conf
