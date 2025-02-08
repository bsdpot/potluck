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
sep=$'\001'

# enable postgresql
service postgresql enable
sysrc postgresql_data="/mnt/postgres/data/"

# if persistent storage data directory doesn't exist, create it
if [ ! -d /mnt/postgres/data ]; then
	mkdir -p /mnt/postgres/data
	chown -R postgres:postgres /mnt/postgres/
	chmod -R 750 /mnt/postgres/
fi

# modify postgres user homedir to /mnt/postgres/data
/usr/sbin/pw usermod -n postgres -d /mnt/postgres/data -s /bin/sh

# initdb step, run only if PG_VERSION file doesn't exist
if [ ! -f /mnt/postgres/data/PG_VERSION ]; then
	service postgresql initdb || true
fi

# get the timezone, not this needs an update for postgresql16
# change to [ ... | awk -F "= " '{print $2}']
if [ -f /mnt/postgres/data/postgresql.conf ]; then
	MYTIMEZONE=$(grep log_timezone /mnt/postgres/data/postgresql.conf | awk -F\' '{print $2}')
else
	echo "error extracting a timezone value: $MYTIMEZONE"
	exit 1
fi

# copy in custom postgresql.conf with network access on 0.0.0.0
# and set timezone
< "$TEMPLATEPATH/postgresql.conf.in" \
  sed "s${sep}%%timezone%%${sep}$MYTIMEZONE${sep}g" \
  > /mnt/postgres/data/postgresql.conf

# set permissions
chown postgres:postgres /mnt/postgres/data/postgresql.conf

# copy in custom pg_hba.conf and set local network access
< "$TEMPLATEPATH/pg_hba.conf.in" \
  sed "s${sep}%%ip4network%%${sep}$IP4NETWORK${sep}g" \
  > /mnt/postgres/data/pg_hba.conf

# set permissions
chown postgres:postgres /mnt/postgres/data/pg_hba.conf
