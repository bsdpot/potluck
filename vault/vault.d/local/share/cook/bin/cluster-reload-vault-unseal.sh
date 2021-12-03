#!/bin/sh
cat /mnt/unsealcerts/ca.crt /mnt/unsealcerts/ca_root.crt \
  >/mnt/unsealcerts/ca_chain.crt.tmp
chown vault /mnt/unsealcerts/*
mv /mnt/unsealcerts/ca_chain.crt.tmp /mnt/unsealcerts/ca_chain.crt

service vault-agent-unseal restart
exit 0
