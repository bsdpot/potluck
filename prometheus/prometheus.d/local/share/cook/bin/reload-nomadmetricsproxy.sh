#!/bin/sh
cat /mnt/nomadcerts/ca.crt /mnt/nomadcerts/ca_root.crt \
  >/mnt/nomadcerts/ca_chain.crt.tmp
mv /mnt/nomadcerts/ca_chain.crt.tmp /mnt/nomadcerts/ca_chain.crt

service nginx reload nomadmetricsproxy
exit 0
