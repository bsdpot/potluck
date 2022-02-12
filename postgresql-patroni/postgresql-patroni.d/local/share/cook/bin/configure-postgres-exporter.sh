#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# read credentials that were unwrapped, escape ":"
EXPPASS=$(cat /mnt/postgrescerts/exporter.pass | sed 's|:|\\:|g')
PGPASSFILE=/mnt/postgrescerts/exporter.pgpass

(
  umask 177
  echo "*:*:postgres:postgres_exporter:$EXPPASS" >$PGPASSFILE
  chown nodeexport $PGPASSFILE
)

service postgres_exporter enable
sysrc postgres_exporter_args="--log.level=warn"
sysrc postgres_exporter_user="nodeexport"
sysrc postgres_exporter_group="nodeexport"
sysrc postgres_exporter_pg_host="$IP"
sysrc postgres_exporter_pg_user="postgres_exporter"
sysrc postgres_exporter_listen_address="127.0.0.1:9187"
sysrc postgres_exporter_env="PGSSLROOTCERT=/mnt/postgrescerts/ca_root.crt\
 PGPASSFILE=$PGPASSFILE"
