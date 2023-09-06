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
#sep=$'\001'

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
