#!/bin/sh
cat /mnt/metricscerts/metricsca.crt /mnt/metricscerts/ca_root.crt \
  >/mnt/metricscerts/ca_chain.crt.tmp
chown grafana:certaccess /mnt/metricscerts/*
mv /mnt/metricscerts/ca_chain.crt.tmp /mnt/metricscerts/ca_chain.crt

# we need to add hashed certificates for syslog-ng
ln -s /mnt/metricscerts/ca_root.crt hash/$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/metricscerts/ca_root.crt).0
ln -s /mnt/metricscerts/ca_chain.crt hash/$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/metricscerts/ca_chain.crt).0

# reload/restart services
# if sysylog-ng is enabled, then restart or reload it
if service syslog-ng enabled; then
    if service syslog-ng status; then
        service syslog-ng reload
    else
        service syslog-ng restart
    fi
fi

service node_exporter restart
service grafana restart

exit 0
