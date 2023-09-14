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

# enable postgres_exporter service
service postgres_exporter enable || true
sysrc postgres_exporter_args="--log.level=warn"
sysrc postgres_exporter_user="nodeexport"
sysrc postgres_exporter_group="nodeexport"
sysrc postgres_exporter_pg_host="127.0.0.1"
sysrc postgres_exporter_pg_user="postgres_exporter"
echo "postgres_exporter_listen_address=\"$IP:9187\"" >> /etc/rc.conf
