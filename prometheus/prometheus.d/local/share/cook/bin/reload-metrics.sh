#!/bin/sh
cat /mnt/metricscerts/metricsca.crt /mnt/metricscerts/ca_root.crt \
  >/mnt/metricscerts/ca_chain.crt.tmp
chown prometheus:certaccess /mnt/metricscerts/*
mv /mnt/metricscerts/ca_chain.crt.tmp /mnt/metricscerts/ca_chain.crt

# we need to add hashed certificates for syslog-ng
ln -s /mnt/metricscerts/ca_root.crt hash/$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/metricscerts/ca_root.crt).0
ln -s /mnt/metricscerts/ca_chain.crt hash/$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/metricscerts/ca_chain.crt).0

# set ownership again
chown prometheus:certaccess /mnt/metricscerts/*

# restart services
# if sysylog-ng is enabled, then restart it
service syslog-ng enabled && service syslog-ng restart
service node_exporter restart
service prometheus restart
service alertmanager restart

exit 0
