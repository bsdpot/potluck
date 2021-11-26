#!/bin/sh
cat /mnt/metricscerts/metricsca.crt /mnt/metricscerts/ca_root.crt \
  >/mnt/metricscerts/ca_chain.crt.tmp
# might be different for loki and prometheus, or need all
chown -R nodeexport /mnt/metricscerts/*
mv /mnt/metricscerts/ca_chain.crt.tmp /mnt/metricscerts/ca_chain.crt

# we need to add hashed certificates for syslog-ng
ln -sf ../ca_root.crt "/mnt/metricscerts/hash/$(/usr/bin/openssl x509 \
  -subject_hash -noout -in /mnt/metricscerts/ca_root.crt).0"
ln -sf ../ca_chain.crt "/mnt/metricscerts/hash/$(/usr/bin/openssl x509 \
  -subject_hash -noout -in /mnt/metricscerts/ca_chain.crt).0"

chown -R nodeexport /mnt/metricscerts/*

# restart services
# if sysylog-ng is enabled, then restart it
checksyslogrc=$(service syslog-ng rcvar | grep -c YES)
if [ "$checksyslogrc" = 1 ]; then
    service syslog-ng restart
fi
service node_exporter restart

exit 0
