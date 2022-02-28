#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# Get postgres consul service token
POSTGRES_SERVICE_TOKEN="$(cat /mnt/patronicerts/postgres_service.token)"

# create /usr/local/etc/patroni/
mkdir -p /usr/local/etc/patroni/

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# read credentials that were unwrapped
ADMPASS=$(cat /mnt/patronicerts/admin.pass)
EXPPASS=$(cat /mnt/patronicerts/exporter.pass)
REPPASS=$(cat /mnt/patronicerts/replicator.pass)
SUPPASS=$(cat /mnt/patronicerts/superuser.pass)

# setup patroni.yml by updating variables
< "$TEMPLATEPATH/patroni.yml.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%servicetag%%${sep}$SERVICETAG${sep}g" \
  > /usr/local/etc/patroni/patroni.yml
chmod 600 /usr/local/etc/patroni/patroni.yml
echo "s${sep}%%admpass%%${sep}$ADMPASS${sep}g" | sed -i '' -f - \
  /usr/local/etc/patroni/patroni.yml
echo "s${sep}%%exppass%%${sep}$EXPPASS${sep}g" | sed -i '' -f - \
  /usr/local/etc/patroni/patroni.yml
echo "s${sep}%%reppass%%${sep}$REPPASS${sep}g" | sed -i '' -f - \
  /usr/local/etc/patroni/patroni.yml
echo "s${sep}%%suppass%%${sep}$SUPPASS${sep}g" | sed -i '' -f - \
  /usr/local/etc/patroni/patroni.yml
echo "s${sep}%%consultoken%%${sep}$POSTGRES_SERVICE_TOKEN${sep}g" | \
  sed -i '' -f - /usr/local/etc/patroni/patroni.yml
chown postgres /usr/local/etc/patroni/patroni.yml

# copy patroni startup script to /usr/local/etc/rc.d/
cp "$TEMPLATEPATH/patroni.rc.in" /usr/local/etc/rc.d/patroni

# enable postgresql
service postgresql enable
sysrc postgresql_data="/mnt/postgres/data/"

# enable patroni
service patroni enable

# if persistent storage data directory doesn't exist, create it
if [ ! -d /mnt/postgres/data ]; then
    mkdir -p /mnt/postgres/data
    chown -R postgres:postgres /mnt/postgres/
    chmod -R 750 /mnt/postgres/
fi

# modify postgres user homedir to /mnt/postgres/data
/usr/sbin/pw usermod -n postgres -d /mnt/postgres/data -s /bin/sh
