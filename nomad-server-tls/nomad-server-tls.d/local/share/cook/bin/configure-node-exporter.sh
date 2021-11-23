#!/bin/sh

set -e

# node exporter needs tls setup
echo "tls_server_config:
  cert_file: /mnt/metricscerts/metrics.crt
  key_file: /mnt/metricscerts/metrics.key
" > /usr/local/etc/node-exporter.yml

# done in cook script before unwrap credentials
## add node_exporter user
#/usr/sbin/pw useradd -n nodeexport -c 'nodeexporter user' -m -s /usr/bin/nologin -h -

# enable node_exporter service
service node_exporter enable
sysrc node_exporter_args="--web.config=/usr/local/etc/node-exporter.yml"
sysrc node_exporter_user=nodeexport
sysrc node_exporter_group=nodeexport

# start node_exporter
# service node_exporter start
# start in main cook script
