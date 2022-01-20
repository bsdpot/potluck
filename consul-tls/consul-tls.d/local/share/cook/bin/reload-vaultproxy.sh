#!/bin/sh
cat /mnt/certs/ca.crt /mnt/certs/ca_root.crt \
  >/mnt/certs/ca_chain.crt.tmp
mv /mnt/certs/ca_chain.crt.tmp /mnt/certs/ca_chain.crt

service nginx reload vaultproxy

exit 0
