#!/bin/sh
cat /mnt/certs/ca.crt /mnt/certs/ca_root.crt \
  >/mnt/certs/ca_chain.crt.tmp
chown vault /mnt/certs/*
mv /mnt/certs/ca_chain.crt.tmp /mnt/certs/ca_chain.crt

service vault reload
service nginx reload vaultproxy
exit 0
