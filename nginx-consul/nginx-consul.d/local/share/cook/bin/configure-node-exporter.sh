#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e

# add node_exporter user
/usr/sbin/pw useradd -n nodeexport -c 'nodeexporter user' \
  -m -s /usr/bin/nologin -h -

# enable node_exporter service
service node_exporter enable
sysrc node_exporter_args="--log.level=warn"
sysrc node_exporter_user=nodeexport
sysrc node_exporter_group=nodeexport
sysrc node_exporter_listen_address="127.0.0.1:9100"
